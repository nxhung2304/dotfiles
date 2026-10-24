#!/usr/bin/env python3
"""Báo cáo hiệu quả theo task (GitHub issue) và theo skill.
Dùng: python3 ai_report.py [--days 30] [--project tên] [--gh] [--csv out.csv] [--html out.html]"""
import argparse, csv, html, json, os, sqlite3, subprocess, time
from collections import defaultdict

DB = os.path.expanduser(os.environ.get("AI_METRICS_DB", "~/.ai-metrics/metrics.db"))
IDLE_CAP = 600  # giây: khoảng nghỉ dài hơn coi là idle (tmux treo), không tính
MIN_TASKS_PER_SKILL = 5
UNASSIGNED_TASK = "(chưa gắn)"
HTML_STYLE = """
:root{--page:#f9f9f7;--card:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--muted:#898781;--grid:#e1e0d9;--ring:rgba(11,11,11,.10);--s1:#2a78d6;--s2:#eb6834;--good:#0ca30c;--warning:#fab219;--serious:#ec835a}
@media (prefers-color-scheme:dark){:root{--page:#0d0d0d;--card:#1a1a19;--ink:#f0efec;--ink2:#c3c2b7;--grid:#2c2c2a;--ring:rgba(255,255,255,.10);--s1:#3987e5;--s2:#d95926}}
*{box-sizing:border-box}
body{margin:0;background:var(--page);color:var(--ink);font:15px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:960px;margin:0 auto;padding:28px 16px 56px}
h1{font-size:26px;margin:0 0 4px}
h2{font-size:18px;margin:0 0 2px}
.sub{color:var(--ink2);margin:0}
.card{background:var(--card);border:1px solid var(--ring);border-radius:14px;padding:20px;margin-top:20px}
.summary{font-size:17px;line-height:1.65}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;margin-top:20px}
.tile{background:var(--card);border:1px solid var(--ring);border-radius:14px;padding:16px}
.tile-value{font-size:34px;font-weight:700;line-height:1.1}
.tile-label{font-weight:600;margin-top:6px}
.tile-hint{color:var(--ink2);font-size:13px}
.how{color:var(--ink2);font-size:13px;margin:0 0 14px}
.row{display:grid;grid-template-columns:120px 1fr auto;gap:12px;align-items:center;padding:5px 6px;border-radius:8px}
.row:hover{background:color-mix(in srgb,var(--ink) 5%,transparent)}
.row-label{font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.track{display:flex;height:22px;border-left:1px solid var(--grid)}
.bar{height:100%;min-width:2px;border-radius:0 4px 4px 0;animation:grow .8s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--i,0)*70ms)}
.bar+.bar{margin-left:2px}
.bar.s1{background:var(--s1)}
.bar.s2{background:var(--s2)}
.bar:hover,.bar:focus-visible{filter:brightness(1.15);outline:2px solid var(--ink2);outline-offset:1px}
@keyframes grow{from{width:0}}
.row-value{font-variant-numeric:tabular-nums;font-weight:600;min-width:64px;text-align:right}
.legend{display:flex;gap:16px;flex-wrap:wrap;margin:0 0 10px;font-size:13px;color:var(--ink2)}
.swatch{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:6px}
.swatch.s1{background:var(--s1)}
.swatch.s2{background:var(--s2)}
.quality-row{display:grid;grid-template-columns:120px 1fr;gap:12px;align-items:center;padding:8px 6px;border-bottom:1px solid var(--grid)}
.chips{display:flex;gap:8px;flex-wrap:wrap}
.chip{display:inline-flex;gap:6px;align-items:center;padding:3px 10px 3px 4px;border-radius:999px;border:1px solid var(--ring);font-size:13px}
.chip i{font-style:normal;font-weight:700;width:18px;height:18px;border-radius:50%;display:inline-grid;place-items:center;font-size:12px;color:#0b0b0b}
.chip.good i{background:var(--good);color:#fff}
.chip.warning i{background:var(--warning)}
.chip.serious i{background:var(--serious)}
.faded{opacity:.55}
.note{color:var(--ink2);font-size:13px;margin:10px 0 0}
details{margin-top:20px}
summary{cursor:pointer;font-weight:600}
dl{margin:12px 0 0}
dt{font-weight:600;margin-top:10px}
dd{margin:2px 0 0;color:var(--ink2)}
.wrap{overflow-x:auto}
table{border-collapse:collapse;min-width:100%;font-size:13px}
th,td{padding:6px 10px;border-bottom:1px solid var(--grid);text-align:left;white-space:nowrap}
th{color:var(--muted)}
#tip{position:fixed;left:0;top:0;pointer-events:none;background:var(--ink);color:var(--card);padding:6px 10px;border-radius:8px;font-size:13px;max-width:260px;opacity:0;transition:opacity .12s;z-index:9}
@media (max-width:560px){.row{grid-template-columns:1fr auto}.row-label{grid-column:1/-1}.quality-row{grid-template-columns:1fr}}
@media (prefers-reduced-motion:reduce){.bar{animation:none}}
"""
HTML_SCRIPT = """
const tip=document.getElementById('tip');
function moveTip(x,y){tip.style.left=Math.max(8,Math.min(x+14,innerWidth-tip.offsetWidth-8))+'px';tip.style.top=(y+14)+'px'}
function showTip(el,x,y){tip.textContent=el.dataset.tip;tip.style.opacity=1;moveTip(x,y)}
document.querySelectorAll('[data-tip]').forEach(el=>{
  el.addEventListener('mouseenter',e=>showTip(el,e.clientX,e.clientY));
  el.addEventListener('mousemove',e=>moveTip(e.clientX,e.clientY));
  el.addEventListener('mouseleave',()=>{tip.style.opacity=0});
  el.addEventListener('focus',()=>{const r=el.getBoundingClientRect();showTip(el,r.left,r.bottom)});
  el.addEventListener('blur',()=>{tip.style.opacity=0});
});
"""
GLOSSARY = [
    ("Task", "Một nhóm việc, thường là một GitHub issue (ví dụ #42). \"Chưa gắn task\" nghĩa là không nhận ra được issue nào."),
    ("Lượt nhắn", "Mỗi lần bạn gửi một yêu cầu cho Claude. Làm xong một việc mà phải nhắn nhiều lượt nghĩa là AI chưa hiểu ngay."),
    ("Xong ngay lần đầu", "Task không có lượt nào bạn phải sửa lại và không lần nào bạn bấm Esc để dừng Claude."),
    ("Phải sửa", "Lượt nhắn có từ như \"sai\", \"làm lại\", \"wrong\", \"revert\". Đây chỉ là cách đoán qua từ khoá, có thể nhầm."),
    ("Bị ngắt", "Bạn bấm Esc giữa chừng, rồi nhắn tiếp trước khi Claude làm xong."),
    ("Claude chạy / Bạn kiểm tra", "Thời gian Claude làm việc, so với thời gian bạn đọc và kiểm tra kết quả. Mỗi khoảng nghỉ chỉ tính tối đa 10 phút."),
    ("Token", "Đơn vị tính khối lượng chữ AI đọc và viết, cũng là đơn vị tính chi phí. Số liệu gồm cả bộ nhớ đệm (cache)."),
    ("Skill", "Bộ hướng dẫn có sẵn Claude dùng cho một loại việc (ví dụ commit, review). Cần ít nhất 5 task mỗi skill mới so sánh được."),
]

def sh(args, cwd=None):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""

def task_label(task):
    if task == UNASSIGNED_TASK:
        return "Chưa gắn task"
    return f"Task #{task}" if task.isdigit() else task

def percent(rate):
    return f"{round(rate * 100)}%"

def format_tokens(thousands):
    return f"{thousands / 1000:.1f}M" if thousands >= 1000 else f"{thousands}k"

def tooltip_attrs(text):
    return f'tabindex="0" data-tip="{html.escape(text, quote=True)}"'

def bar_row_label(label):
    return f'<div class="row-label" title="{html.escape(label, quote=True)}">{html.escape(label)}</div>'

def single_bar_row(index, label, value, max_value, value_text, tip, extra_class=""):
    width = 100 * value / max_value if max_value else 0
    return (f'<div class="row {extra_class}">{bar_row_label(label)}'
            f'<div class="track"><div class="bar s1" style="width:{width:.1f}%;--i:{index}" {tooltip_attrs(tip)}></div></div>'
            f'<div class="row-value">{html.escape(value_text)}</div></div>')

def stacked_bar_row(index, label, parts, max_total, total_text):
    segments = ""
    for series_class, value, tip in parts:
        if value > 0:
            segments += f'<div class="bar {series_class}" style="width:{100 * value / max_total:.1f}%;--i:{index}" {tooltip_attrs(tip)}></div>'
    return (f'<div class="row">{bar_row_label(label)}<div class="track">{segments}</div>'
            f'<div class="row-value">{html.escape(total_text)}</div></div>')

def quality_chips(row):
    if row["first_pass"]:
        return [("good", "✓", "Xong ngay lần đầu")]
    chips = []
    if row["correction_rate"]:
        chips.append(("warning", "✎", f"Phải sửa {percent(row['correction_rate'])} số lượt"))
    if row["interrupt_rate"]:
        chips.append(("serious", "✕", f"Bị ngắt {percent(row['interrupt_rate'])} số lượt"))
    return chips

def quality_row(row):
    chips = "".join(f'<span class="chip {kind}"><i>{icon}</i>{html.escape(text)}</span>' for kind, icon, text in quality_chips(row))
    return f'<div class="quality-row">{bar_row_label(task_label(row["task"]))}<div class="chips">{chips}</div></div>'

def tile(value, label, hint):
    return (f'<div class="tile"><div class="tile-value">{html.escape(value)}</div>'
            f'<div class="tile-label">{html.escape(label)}</div><div class="tile-hint">{html.escape(hint)}</div></div>')

def chart_card(title, how_to_read, body, legend=""):
    return f'<section class="card"><h2>{title}</h2><p class="how">{how_to_read}</p>{legend}{body}</section>'

def skill_card(skill_rows):
    rows = ""
    for index, (name, stats) in enumerate(skill_rows):
        if not stats:
            continue
        task_count, avg_turns, correction_rate, interrupt_rate, first_pass_text = stats
        first_pass_percent = int(first_pass_text.rstrip("%"))
        enough_data = task_count >= MIN_TASKS_PER_SKILL
        label = "Không dùng skill" if name == "(không skill)" else name
        value_text = f"{first_pass_percent}%" if enough_data else f"{first_pass_percent}% (ít dữ liệu)"
        tip = f"{label}: {task_count} task, trung bình {avg_turns} lượt, phải sửa {percent(correction_rate)}, bị ngắt {percent(interrupt_rate)}"
        rows += single_bar_row(index, label, first_pass_percent, 100, value_text, tip, "" if enough_data else "faded")
    note = f'<p class="note">Mờ = chưa đủ dữ liệu (cần ít nhất {MIN_TASKS_PER_SKILL} task mỗi skill) nên chưa kết luận được.</p>'
    return chart_card("Skill có giúp ích không?",
                      "Thanh dài = tỉ lệ task xong ngay lần đầu khi dùng skill đó. Dòng \"Không dùng skill\" (nếu có) là mốc so sánh.",
                      rows + note)

def data_table(task_cols, task_rows):
    head = "".join(f"<th>{html.escape(c)}</th>" for c in task_cols)
    body = "".join("<tr>" + "".join(f"<td>{html.escape(str(r[c]))}</td>" for c in task_cols) + "</tr>" for r in task_rows)
    return f'<div class="wrap"><table><tr>{head}</tr>{body}</table></div>'

def write_html(path, task_cols, task_rows, skill_rows, days):
    if not task_rows:
        body = '<section class="card"><p class="summary">Chưa có dữ liệu trong khoảng thời gian này.</p></section>'
    else:
        task_count = len(task_rows)
        total_turns = sum(r["turns"] for r in task_rows)
        first_pass_tasks = sum(1 for r in task_rows if r["first_pass"])
        claude_total = round(sum(r["claude_min"] for r in task_rows), 1)
        you_total = round(sum(r["you_min"] for r in task_rows), 1)
        token_total_k = sum(r["tok_in_k"] + r["tok_out_k"] for r in task_rows)
        busiest = max(task_rows, key=lambda r: r["turns"])
        summary = (f"Trong {days} ngày qua bạn làm <b>{task_count}</b> nhóm việc với Claude, tổng cộng <b>{total_turns}</b> lượt nhắn. "
                   f"<b>{first_pass_tasks}/{task_count}</b> nhóm việc xong ngay lần đầu, không cần sửa. "
                   f"Claude chạy {claude_total:g} phút, bạn dành {you_total:g} phút để kiểm tra. "
                   f"Tốn công nhất: {html.escape(task_label(busiest['task']))} ({busiest['turns']} lượt nhắn).")
        tiles = "".join([
            tile(f"{round(100 * first_pass_tasks / task_count)}%", "Task xong ngay lần đầu", "AI làm đúng, bạn không phải sửa hay ngắt"),
            tile(f"{total_turns / task_count:.1f}", "Lượt nhắn trung bình mỗi task", "Càng ít càng tốt: AI hiểu ý nhanh"),
            tile(f"{you_total:g} phút", "Thời gian bạn kiểm tra", f"So với Claude chạy {claude_total:g} phút"),
            tile(format_tokens(token_total_k), "Token đã dùng", "Khối lượng chữ AI đọc và viết, gồm cả cache"),
        ])
        max_turns = max(r["turns"] for r in task_rows)
        turns_rows = "".join(
            single_bar_row(i, task_label(r["task"]), r["turns"], max_turns, f"{r['turns']} lượt",
                           f"{task_label(r['task'])}: {r['turns']} lượt nhắn")
            for i, r in enumerate(task_rows))
        max_minutes = max(r["claude_min"] + r["you_min"] for r in task_rows) or 1
        time_rows = "".join(
            stacked_bar_row(i, task_label(r["task"]), [
                ("s1", r["claude_min"], f"{task_label(r['task'])}: Claude chạy {r['claude_min']:g} phút"),
                ("s2", r["you_min"], f"{task_label(r['task'])}: bạn kiểm tra {r['you_min']:g} phút"),
            ], max_minutes, f"{r['claude_min'] + r['you_min']:.1f} phút")
            for i, r in enumerate(task_rows))
        time_legend = ('<div class="legend"><span><span class="swatch s1"></span>Claude chạy</span>'
                       '<span><span class="swatch s2"></span>Bạn đọc và kiểm tra</span></div>')
        max_tokens = max(r["tok_in_k"] + r["tok_out_k"] for r in task_rows) or 1
        token_rows = "".join(
            single_bar_row(i, task_label(r["task"]), r["tok_in_k"] + r["tok_out_k"], max_tokens,
                           format_tokens(r["tok_in_k"] + r["tok_out_k"]),
                           f"{task_label(r['task'])}: AI đọc {format_tokens(r['tok_in_k'])}, viết {format_tokens(r['tok_out_k'])}")
            for i, r in enumerate(task_rows))
        glossary = "".join(f"<dt>{html.escape(term)}</dt><dd>{html.escape(meaning)}</dd>" for term, meaning in GLOSSARY)
        body = (f'<section class="card summary">{summary}</section><div class="tiles">{tiles}</div>'
                + chart_card("Mỗi task tốn bao nhiêu lượt nhắn?", "Thanh càng dài = bạn phải nhắn càng nhiều lần mới xong việc.", turns_rows)
                + chart_card("Thời gian: Claude làm và bạn kiểm tra", "Phần cam dài = bạn mất nhiều thời gian đọc và kiểm tra kết quả.", time_rows, time_legend)
                + chart_card("Chất lượng từng task", "Xanh = trơn tru. Vàng, cam = có lúc phải sửa hoặc dừng Claude giữa chừng.",
                             "".join(quality_row(r) for r in task_rows))
                + chart_card("Token: task nào tốn nhất?", "Thanh càng dài = AI đọc và viết càng nhiều chữ, tốn chi phí hơn.", token_rows)
                + skill_card(skill_rows)
                + f'<details class="card"><summary>Cách đọc các thuật ngữ</summary><dl>{glossary}</dl></details>'
                + f'<details class="card"><summary>Bảng số liệu chi tiết</summary>{data_table(task_cols, task_rows)}</details>')
    page = (f'<!doctype html><html lang="vi"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>Báo cáo dùng AI</title><style>{HTML_STYLE}</style></head><body><main>'
            f'<h1>Bạn dùng AI hiệu quả đến đâu?</h1><p class="sub">Dữ liệu {days} ngày gần nhất. Di chuột vào thanh màu để xem chi tiết.</p>'
            f'{body}</main><div id="tip" role="tooltip"></div><script>{HTML_SCRIPT}</script></body></html>')
    with open(path, "w", encoding="utf-8") as f:
        f.write(page)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--project")
    ap.add_argument("--gh", action="store_true", help="hỏi trạng thái issue qua gh CLI")
    ap.add_argument("--csv")
    ap.add_argument("--html")
    a = ap.parse_args()

    db = sqlite3.connect(DB)
    q = "SELECT id, session_id, project, cwd, task, prompt_ts, stop_ts, is_correction, tool_calls, tool_failures, tok_in+tok_cache_read+tok_cache_write, tok_out FROM turns WHERE prompt_ts>=?"
    params = [time.time() - a.days * 86400]
    if a.project:
        q += " AND project=?"; params.append(a.project)
    rows = db.execute(q + " ORDER BY session_id, id", params).fetchall()
    skills = defaultdict(set)
    for tid, s in db.execute("SELECT turn_id, skill FROM skills"):
        skills[tid].add(s)

    T = defaultdict(lambda: dict(turns=0, interrupts=0, corrections=0, tools=0, fails=0,
                                 claude_s=0.0, human_s=0.0, tok_in=0, tok_out=0, skills=set(), cwd="", first=None, last=None))
    for i, r in enumerate(rows):
        tid, sid, proj, cwd, task, p_ts, s_ts, corr, tools, fails, tin, tout = r
        t = T[(proj, task or "(chưa gắn)")]
        nxt = rows[i + 1] if i + 1 < len(rows) and rows[i + 1][1] == sid else None
        t["turns"] += 1; t["corrections"] += corr; t["tools"] += tools; t["fails"] += fails
        t["tok_in"] += tin; t["tok_out"] += tout; t["skills"] |= skills[tid]; t["cwd"] = cwd
        t["first"] = min(filter(None, [t["first"], p_ts])); t["last"] = max(filter(None, [t["last"], s_ts or p_ts]))
        if s_ts:
            t["claude_s"] += s_ts - p_ts
            if nxt:
                t["human_s"] += min(max(0, nxt[5] - s_ts), IDLE_CAP)
        elif nxt:  # có prompt mới mà turn trước không có Stop => bị Esc
            t["interrupts"] += 1

    out = []
    for (proj, task), t in sorted(T.items(), key=lambda kv: -kv[1]["last"]):
        state, commits = "", ""
        if task.isdigit():
            log = sh(["git", "log", "--all", "--oneline", "-E", f"--grep=#{task}\\b"], cwd=t["cwd"]) if t["cwd"] else ""
            commits = len(log.splitlines())
            if a.gh:
                j = sh(["gh", "issue", "view", task, "--json", "state"], cwd=t["cwd"])
                state = json.loads(j).get("state", "") if j.startswith("{") else ""
        n = t["turns"]
        out.append(dict(project=proj, task=task, turns=n,
                        first_pass="✓" if t["corrections"] == 0 and t["interrupts"] == 0 else "",
                        correction_rate=round(t["corrections"] / n, 2), interrupt_rate=round(t["interrupts"] / n, 2),
                        tool_fail_rate=round(t["fails"] / t["tools"], 2) if t["tools"] else 0,
                        claude_min=round(t["claude_s"] / 60, 1), you_min=round(t["human_s"] / 60, 1),
                        tok_in_k=round(t["tok_in"] / 1000), tok_out_k=round(t["tok_out"] / 1000),
                        commits=commits, issue_state=state, skills=",".join(sorted(t["skills"]))))

    cols = ["project", "task", "turns", "first_pass", "correction_rate", "interrupt_rate", "tool_fail_rate",
            "claude_min", "you_min", "tok_in_k", "tok_out_k", "commits", "issue_state", "skills"]
    if a.csv:
        with open(a.csv, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, cols); w.writeheader(); w.writerows(out)
        print(f"Đã ghi {a.csv}")
    print("\n== THEO TASK ==")
    widths = {c: max(len(c), *(len(str(r[c])) for r in out)) if out else len(c) for c in cols}
    print("  ".join(c.ljust(widths[c]) for c in cols))
    for r in out:
        print("  ".join(str(r[c]).ljust(widths[c]) for c in cols))

    # So sánh skill: task có skill vs task không dùng skill nào
    real = [r for r in out if r["task"] != "(chưa gắn)"]
    def agg(rs):
        if not rs: return None
        k = len(rs)
        return (k, round(sum(r["turns"] for r in rs) / k, 1),
                round(sum(r["correction_rate"] for r in rs) / k, 2),
                round(sum(r["interrupt_rate"] for r in rs) / k, 2),
                f"{round(100 * sum(1 for r in rs if r['first_pass']) / k)}%")
    print("\n== THEO SKILL ==  (số task, turn TB/task, tỉ lệ sửa, tỉ lệ ngắt, đúng ngay lần đầu)")
    base = agg([r for r in real if not r["skills"]])
    print(f"{'(không skill)':28} {base}")
    skill_rows = [("(không skill)", base)]
    for s in sorted({s for r in real for s in r['skills'].split(',') if s}):
        stats = agg([r for r in real if s in r['skills'].split(',')])
        print(f"{s:28} {stats}")
        skill_rows.append((s, stats))

    if a.html:
        write_html(a.html, cols, out, skill_rows, a.days)
        print(f"Đã ghi {a.html}")

if __name__ == "__main__":
    main()
