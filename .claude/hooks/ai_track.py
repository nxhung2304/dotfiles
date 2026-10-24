#!/usr/bin/env python3
"""Hook ghi log hiệu quả dùng Claude Code. Một script cho mọi event.
Đọc JSON từ stdin, ghi vào ~/.ai-metrics/metrics.db. Luôn exit 0, không in gì ra stdout."""
import json, os, re, sqlite3, subprocess, sys, time

DB = os.path.expanduser(os.environ.get("AI_METRICS_DB", "~/.ai-metrics/metrics.db"))
SPECS_RE = re.compile(r"(?:^|/)specs/([^/\s'\"]+)/")
ISSUE_RE = re.compile(r"(?:#|issue[-_ ]?|specs/)(\d+)", re.I)
BRANCH_NUM_RE = re.compile(r"(?:^|[/_-])(\d+)(?:[/_-]|$)")
CORRECTION_RE = re.compile(
    r"\b(sai|nhầm|sửa lại|làm lại|chưa đúng|không đúng|không phải|revert|undo|"
    r"wrong|not what|that's not|redo|rollback)\b", re.I)

SCHEMA = """
CREATE TABLE IF NOT EXISTS turns(
  id INTEGER PRIMARY KEY, session_id TEXT, project TEXT, cwd TEXT, branch TEXT,
  task TEXT, task_source TEXT, prompt_ts REAL, stop_ts REAL, prompt_len INT,
  is_correction INT DEFAULT 0, tool_calls INT DEFAULT 0, tool_failures INT DEFAULT 0,
  tok_in INT DEFAULT 0, tok_out INT DEFAULT 0, tok_cache_read INT DEFAULT 0, tok_cache_write INT DEFAULT 0);
CREATE TABLE IF NOT EXISTS skills(turn_id INT, skill TEXT);
CREATE TABLE IF NOT EXISTS session_tokens(session_id TEXT PRIMARY KEY, tok_in INT, tok_out INT, tok_cache_read INT, tok_cache_write INT);
CREATE INDEX IF NOT EXISTS idx_turns_session ON turns(session_id, id);
"""

def git(cwd, *args):
    try:
        return subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=2).stdout.strip()
    except Exception:
        return ""

def task_from_text(text):
    """Tìm task: ưu tiên thư mục specs/<folder>, sau đó #123 / issue-123."""
    m = SPECS_RE.search(text or "")
    if m:
        return m.group(1)
    m = ISSUE_RE.search(text or "")
    return m.group(1) if m else None

def normalize(task):
    """specs/123-login-fix -> 123 (để khớp với branch và #123)."""
    m = re.match(r"(?:issue[-_]?)?(\d+)", task or "", re.I)
    return m.group(1) if m else task

def current_turn(db, sid):
    return db.execute("SELECT id, task, task_source FROM turns WHERE session_id=? ORDER BY id DESC LIMIT 1", (sid,)).fetchone()

def on_prompt(db, d):
    sid, cwd, prompt = d.get("session_id"), d.get("cwd", ""), d.get("prompt", "")
    top = git(cwd, "rev-parse", "--show-toplevel") or cwd
    branch = git(cwd, "rev-parse", "--abbrev-ref", "HEAD")
    task, src = task_from_text(prompt), "prompt"
    if not task and branch:
        m = BRANCH_NUM_RE.search(branch)
        if m:
            task, src = m.group(1), "branch"
    if not task:  # kế thừa task của turn trước trong cùng session
        prev = current_turn(db, sid)
        if prev and prev[1]:
            task, src = prev[1], "inherit"
    db.execute("INSERT INTO turns(session_id, project, cwd, branch, task, task_source, prompt_ts, prompt_len, is_correction)"
               " VALUES(?,?,?,?,?,?,?,?,?)",
               (sid, os.path.basename(top), top, branch, normalize(task), src if task else None,
                time.time(), len(prompt), 1 if CORRECTION_RE.search(prompt) else 0))

def on_tool(db, d, failed):
    row = current_turn(db, d.get("session_id"))
    if not row:
        return
    tid, task, src = row
    db.execute(f"UPDATE turns SET tool_calls=tool_calls+1{', tool_failures=tool_failures+1' if failed else ''} WHERE id=?", (tid,))
    inp = d.get("tool_input") or {}
    blob = json.dumps(inp, ensure_ascii=False)
    # Skill: qua tool Skill hoặc đọc file .../skills/<tên>/SKILL.md
    skill = None
    if d.get("tool_name") == "Skill":
        skill = inp.get("skill") or inp.get("name") or inp.get("command")
    else:
        m = re.search(r"skills/([^/\"]+)/SKILL\.md", blob)
        if m:
            skill = m.group(1)
    if skill:
        db.execute("INSERT INTO skills(turn_id, skill) VALUES(?,?)", (tid, skill))
    # Claude đụng vào specs/<issue>/ => tín hiệu task mạnh nhất, ghi đè task suy đoán
    t = SPECS_RE.search(blob)
    if t and src in (None, "inherit", "branch"):
        db.execute("UPDATE turns SET task=?, task_source='specs' WHERE id=?", (normalize(t.group(1)), tid))

def transcript_usage(path):
    seen = {}
    try:
        with open(os.path.expanduser(path), encoding="utf-8") as f:
            for line in f:
                try:
                    e = json.loads(line)
                except Exception:
                    continue
                msg = e.get("message") or {}
                u = msg.get("usage")
                if e.get("type") == "assistant" and u:
                    seen[msg.get("id") or e.get("uuid")] = u  # dedupe theo message id
    except Exception:
        return None
    keys = ["input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"]
    return [sum(int(u.get(k) or 0) for u in seen.values()) for k in keys]

def on_stop(db, d):
    sid = d.get("session_id")
    row = current_turn(db, sid)
    if not row:
        return
    vals = [0, 0, 0, 0]
    tot = transcript_usage(d.get("transcript_path", ""))
    if tot:
        prev = db.execute("SELECT tok_in, tok_out, tok_cache_read, tok_cache_write FROM session_tokens WHERE session_id=?", (sid,)).fetchone()
        vals = [max(0, a - b) for a, b in zip(tot, prev or [0, 0, 0, 0])]
        db.execute("INSERT OR REPLACE INTO session_tokens VALUES(?,?,?,?,?)", (sid, *tot))
    db.execute("UPDATE turns SET stop_ts=?, tok_in=tok_in+?, tok_out=tok_out+?, tok_cache_read=tok_cache_read+?,"
               " tok_cache_write=tok_cache_write+? WHERE id=?", (time.time(), *vals, row[0]))

def main():
    try:
        d = json.load(sys.stdin)
        os.makedirs(os.path.dirname(DB), exist_ok=True)
        db = sqlite3.connect(DB, timeout=5)
        db.executescript(SCHEMA)
        ev = d.get("hook_event_name")
        if ev == "UserPromptSubmit":
            on_prompt(db, d)
        elif ev == "PostToolUse":
            on_tool(db, d, False)
        elif ev == "PostToolUseFailure":
            on_tool(db, d, True)
        elif ev == "Stop":
            on_stop(db, d)
        db.commit()
    except Exception as e:  # không bao giờ làm hỏng phiên Claude Code
        try:
            with open(os.path.expanduser("~/.ai-metrics/errors.log"), "a") as f:
                f.write(f"{time.ctime()} {e!r}\n")
        except Exception:
            pass
    sys.exit(0)

if __name__ == "__main__":
    main()
