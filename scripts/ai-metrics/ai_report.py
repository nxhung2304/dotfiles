#!/usr/bin/env python3
"""Báo cáo hiệu quả theo task (GitHub issue) và theo skill.
Dùng: python3 ai_report.py [--days 30] [--project tên] [--gh] [--csv out.csv] [--html out.html] [--json out.json]"""
import argparse, csv, glob, html, json, os, re, sqlite3, subprocess, time, urllib.parse
from collections import Counter, defaultdict

DB = os.path.expanduser(os.environ.get("AI_METRICS_DB", "~/.ai-metrics/metrics.db"))
REVIEW_DIR = os.path.expanduser(os.environ.get("AI_METRICS_REVIEW_DIR", "~/.ai-metrics/reviews"))
TRANSCRIPT_GLOB = os.path.expanduser("~/.claude/projects/*/{session_id}.jsonl")
IDLE_CAP = 600  # giây: khoảng nghỉ dài hơn coi là idle (tmux treo), không tính
MIN_TASKS_PER_SKILL = 5
TREND_WEEKS = 8
WEEK_SECONDS = 7 * 86400
COSTLY_TASK_COUNT = 3
PROJECT_MIN_TASKS = 2
UNASSIGNED_TASK = "(chưa gắn)"
IGNORED_SKILLS = ("ai-score", "ai-improve")
NOT_IGNORED_TURN = " AND id NOT IN (SELECT turn_id FROM skills WHERE skill IN (?, ?))"
INLINE_MARKUP_RE = re.compile(r"\*\*(.+?)\*\*|`([^`]+)`")
TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "template")
def read_template(name):
    with open(os.path.join(TEMPLATE_DIR, name), encoding="utf-8") as f:
        return f.read()
HTML_STYLE = read_template("report.css")
HTML_SCRIPT = read_template("report.js")

def sh(args, cwd=None):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""

def task_label(task):
    if task == UNASSIGNED_TASK:
        return "Chưa gắn task"
    return f"Task #{task}" if str(task).isdigit() else str(task)

def percent(rate):
    return f"{round(rate * 100)}%"

def format_tokens(thousands):
    return f"{thousands / 1000:.1f}M" if thousands >= 1000 else f"{thousands}k"

def empty_stats():
    return dict(turns=0, corrections=0, interrupts=0, human_s=0.0, tokens=0)

def task_stats():
    return dict(empty_stats(), skills=set())

def summarize_week(week):
    if not week["turns"]:
        return None
    tasks = week["tasks"]
    task_count = len(tasks)
    return dict(
        task_count=task_count, turns=week["turns"],
        first_pass_pct=100 * sum(1 for t in tasks.values() if t["corrections"] + t["interrupts"] == 0) / task_count,
        correction_pct=100 * week["corrections"] / week["turns"],
        interrupt_pct=100 * week["interrupts"] / week["turns"],
        tokens_k_per_task=week["tokens"] / 1000 / task_count,
        review_min_per_task=week["human_s"] / 60 / task_count,
        tasks=[dict(project=proj, task=task, **stats) for (proj, task), stats in tasks.items()])

def current_week_start(now):
    local = time.localtime(now)
    return time.mktime((local.tm_year, local.tm_mon, local.tm_mday - local.tm_wday, 0, 0, 0, 0, 0, -1))

def weekly_stats(db, project, now):
    q = ("SELECT id, session_id, project, task, prompt_ts, stop_ts, is_correction, tok_in+tok_cache_read+tok_cache_write+tok_out"
         " FROM turns WHERE prompt_ts>=?" + NOT_IGNORED_TURN)
    this_week_start = current_week_start(now)
    params = [this_week_start - TREND_WEEKS * WEEK_SECONDS, *IGNORED_SKILLS]
    if project:
        q += " AND project=?"; params.append(project)
    rows = db.execute(q + " ORDER BY session_id, id", params).fetchall()
    weeks = [dict(empty_stats(), tasks=defaultdict(task_stats)) for _ in range(TREND_WEEKS + 1)]
    skills_by_turn = defaultdict(set)
    for turn_id, skill in db.execute("SELECT turn_id, skill FROM skills"):
        skills_by_turn[turn_id].add(skill)
    for i, (turn_id, sid, proj, task, p_ts, s_ts, corr, tokens) in enumerate(rows):
        weeks_ago = max(0, -int((p_ts - this_week_start) // WEEK_SECONDS))
        if weeks_ago > TREND_WEEKS:
            continue
        week = weeks[weeks_ago]
        nxt = rows[i + 1] if i + 1 < len(rows) and rows[i + 1][1] == sid else None
        interrupted = 1 if not s_ts and nxt else 0
        human_s = min(max(0, nxt[4] - s_ts), IDLE_CAP) if s_ts and nxt else 0
        task_target = week["tasks"][(proj, task or UNASSIGNED_TASK)]
        task_target["skills"] |= skills_by_turn[turn_id]
        for target in (week, task_target):
            target["turns"] += 1; target["corrections"] += corr; target["interrupts"] += interrupted
            target["tokens"] += tokens; target["human_s"] += human_s
    return [summarize_week(week) for week in weeks]

def week_windows(now):
    windows = []
    for weeks_ago in range(TREND_WEEKS):
        start = current_week_start(now) - weeks_ago * WEEK_SECONDS
        end = start + WEEK_SECONDS
        sunday = start + 6 * 86400 + 12 * 3600
        name = "Tuần này" if weeks_ago == 0 else "Tuần trước" if weeks_ago == 1 else f"{weeks_ago} tuần trước"
        span = f'{time.strftime("%d/%m", time.localtime(start))}–{time.strftime("%d/%m", time.localtime(sunday))}'
        windows.append(dict(weeks_ago=weeks_ago, start=start, end=end, name=name, span=span,
                            week_start=time.strftime("%Y-%m-%d", time.localtime(start + 12 * 3600))))
    return windows

def task_context(db, project, task, since, until):
    condition, params = ("task IS NULL", [project, since, until]) if task == UNASSIGNED_TASK else ("task=?", [project, since, until, task])
    found = db.execute(f"SELECT session_id, cwd FROM turns WHERE project=? AND prompt_ts>=? AND prompt_ts<? AND {condition} GROUP BY session_id", params).fetchall()
    sessions = [dict(session_id=sid, transcript=next(iter(glob.glob(TRANSCRIPT_GLOB.format(session_id=sid))), None)) for sid, _ in found]
    return dict(cwd=found[0][1] if found else "", sessions=sessions)

def costly_tasks(task_rows):
    by_project = defaultdict(list)
    for r in task_rows:
        if r["task"] != UNASSIGNED_TASK:
            by_project[r["project"]].append(r)
    costly = []
    for project_tasks in by_project.values():
        if len(project_tasks) >= PROJECT_MIN_TASKS:
            costly += sorted(project_tasks, key=lambda r: (-r["turns"], -r["you_min"]))[:COSTLY_TASK_COUNT]
    return costly

def load_reviews():
    reviews = []
    for path in sorted(glob.glob(os.path.join(REVIEW_DIR, "*.json"))):
        try:
            with open(path, encoding="utf-8") as f:
                review = json.load(f)
            reviewed_at = time.mktime(time.strptime(review["date"], "%Y-%m-%d")) + 12 * 3600
        except Exception:
            continue
        reviews.append((reviewed_at, review))
    return reviews

def review_for_window(reviews, window):
    matched = [review for reviewed_at, review in reviews
               if (review.get("week_start") == window["week_start"] if review.get("week_start") else window["start"] <= reviewed_at < window["end"])]
    return matched[-1] if matched else None

def export_json(path, db, days, since, until, week_start, task_rows, skill_rows, weeks, windows):
    costly_keys = {(r["project"], r["task"]) for r in costly_tasks(task_rows)}
    tasks = [dict(r, costly=(r["project"], r["task"]) in costly_keys, **task_context(db, r["project"], r["task"], since, until)) for r in task_rows]
    trend = [dict(week=w["span"], metrics={k: v for k, v in m.items() if k != "tasks"} if m else None)
             for w, m in reversed(list(zip(windows, weeks)))]
    data = dict(generated_at=time.strftime("%Y-%m-%d %H:%M"), days=days, week_start=week_start, rubric=os.path.join(os.path.dirname(os.path.abspath(__file__)), "rubric.md"),
                review_dir=REVIEW_DIR, trend=trend, tasks=tasks, skills=[dict(skill=name, stats=stats) for name, stats in skill_rows])
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def file_link(token):
    expanded = os.path.expanduser(token)
    if os.path.isabs(expanded) and os.path.exists(expanded):
        return (f'<a class="file" href="ai-reveal://{urllib.parse.quote(expanded)}" title="Mở trong Finder: {html.escape(expanded, quote=True)}">'
                f'{html.escape(token)}</a>')
    return f"<code>{html.escape(token)}</code>"

def rich_text(text):
    text = str(text)
    parts, position = [], 0
    lead = re.match(r"^([^:*`\"]{1,14}):\s+", text)
    if lead:
        tone = {"mạnh": "good", "yếu": "bad", "làm gì": "good", "vì sao": "bad"}.get(lead.group(1).strip().lower(), "")
        parts.append(f'<span class="lead {tone}">{html.escape(lead.group(1))}</span><span>')
        position = lead.end()
        text = text[:position] + text[position:position + 1].upper() + text[position + 1:]
    for match in INLINE_MARKUP_RE.finditer(text, position):
        parts.append(html.escape(text[position:match.start()]))
        parts.append(html.escape(match.group(1)) if match.group(1) else file_link(match.group(2)))
        position = match.end()
    parts.append(html.escape(text[position:]))
    if lead:
        parts.append("</span>")
    return "".join(parts)

def bullet_list(value, css_class):
    items = value if isinstance(value, list) else re.split(r"(?<=[.;])\s+", str(value).strip())
    items = [str(item).strip().rstrip(";") for item in items if str(item).strip()]
    return f'<ul class="{css_class}">' + "".join(f"<li>{rich_text(item)}</li>" for item in items) + "</ul>"

def tooltip_attrs(text):
    return f'tabindex="0" data-tip="{html.escape(text, quote=True)}"'

def empty(text):
    return f'<p class="empty">{text}</p>'

def pill(kind, text):
    return f'<span class="pill {kind}"><i></i>{html.escape(text)}</span>'

def bar_row(index, name, value, max_value, value_text, tip, previous_value=None, extra_class=""):
    previous_mark = ""
    if previous_value is not None:
        previous_mark = f'<span class="bar-prev" style="left:calc({100 * previous_value / max_value:.0f}% - 1px)"></span>'
    return (f'<div class="bar-row {extra_class}"><div class="bar-name">{html.escape(name)}</div>'
            f'<div class="bar-track"><div class="bar" style="width:{100 * value / max_value:.0f}%;--i:{index}" {tooltip_attrs(tip)}></div>{previous_mark}</div>'
            f'<div class="bar-value">{html.escape(value_text)}</div></div>')

def segments(score):
    return '<span class="segments" aria-hidden="true">' + "".join(f'<span class="{"on" if i < round(score) else ""}"></span>' for i in range(5)) + "</span>"

def scored(review):
    return [s for s in (review or {}).get("scores", []) if isinstance(s.get("score"), (int, float))]

def average_score(review):
    scores = scored(review)
    return sum(s["score"] for s in scores) / len(scores) if scores else None

def score_state(score):
    if score is None:
        return "neutral", "Chưa chấm"
    if score >= 4:
        return "good", "Tốt"
    if score >= 3:
        return "neutral", "Ổn"
    return "bad", "Cần chú ý"

def tag(kind):
    text = "Số liệu" if kind == "data" else "AI nhận định"
    return f'<span class="tag {kind}">{text}</span>'

def row(title, status, insight, detail, kind=""):
    return (f'<details class="row"><summary><div class="row-head"><span class="row-title">{title}</span>{tag(kind) if kind else ""}{status}<span class="chev"></span></div>'
            f'<div class="row-insight">{insight}</div></summary><div class="row-detail">{detail}</div></details>')

def progress_row(review, previous_review):
    ordered = sorted(scored(review), key=lambda s: s["score"])
    if not ordered:
        return row("Có tiến bộ không?", pill("neutral", "Chưa chấm"), "Chạy /ai-score để AI chấm điểm.", "")
    weakest = ordered[0]
    previous_scores = {s.get("name"): s["score"] for s in scored(previous_review)}
    changes = [s["score"] - previous_scores[s.get("name")] for s in ordered if s.get("name") in previous_scores]
    up, down = sum(1 for c in changes if c > 0), sum(1 for c in changes if c < 0)
    if not changes:
        status, change_text = pill("neutral", "Chưa có tuần trước"), ""
    else:
        status = pill("good", "Tiến bộ") if up > down else pill("bad", "Đi xuống") if down > up else pill("warn", "Đi ngang")
        change_text = f" · {up} tiêu chí tăng, {down} giảm so với tuần trước"
    bars = ""
    for index, s in enumerate(ordered):
        previous_score = previous_scores.get(s.get("name"))
        tip = f'“{s.get("evidence", "")}”' + (f" · tuần trước {previous_score:g}/5" if previous_score is not None else "")
        bars += bar_row(index, str(s.get("name", "")), s["score"], 5, f'{s["score"]:g}/5', tip, previous_score, "weak" if s is weakest else "")
    quote = f'<p class="quote">“{html.escape(str(weakest.get("evidence", "")))}”</p>'
    unscored = [str(s.get("name", "")) for s in review["scores"] if s not in ordered]
    notes = ""
    if previous_scores:
        notes += '<p class="note">Vạch đứng = tuần trước. Di chuột vào thanh để xem bằng chứng.</p>'
    if unscored:
        notes += f'<p class="note">Chưa chấm được: {html.escape(", ".join(unscored))}.</p>'
    insight = segments(weakest["score"]) + f'<span class="clip">Yếu nhất: {html.escape(str(weakest.get("name", "")))} · {weakest["score"]:g}/5{html.escape(change_text)}</span>'
    return row("Có tiến bộ không?", status, insight, bars + quote + notes, "ai")

def as_list(value):
    items = value if isinstance(value, list) else [value]
    return [str(item).strip() for item in items if str(item).strip()]

def task_findings(found, show_first_solution=True):
    if not found:
        return '<p class="note">Chưa phân tích nguyên nhân.</p>'
    causes, solutions = as_list(found.get("cause")), as_list(found.get("solution"))
    html_out = ""
    if causes:
        html_out += f'<p class="finding">{rich_text("Vì sao: " + causes[0])}</p>'
    if solutions and show_first_solution:
        html_out += f'<p class="finding fix">{rich_text("Làm gì: " + solutions[0])}</p>'
    extras = ""
    if causes[1:]:
        extras += bullet_list(causes[1:], "bullets")
    if solutions[1:]:
        extras += bullet_list(solutions[1:], "bullets")
    quotes = ([found["evidence"]] if found.get("evidence") else []) + as_list(found.get("excerpts"))
    for quote in quotes:
        extras += f'<p class="quote">“{html.escape(str(quote))}”</p>'
    if extras:
        html_out += f'<details class="more"><summary>Chi tiết</summary>{extras}</details>'
    return html_out

def costly_row(week, review):
    assigned = [t for t in (week or {}).get("tasks", []) if t["task"] != UNASSIGNED_TASK]
    top = sorted(assigned, key=lambda t: (-t["turns"], -t["human_s"]))[:COSTLY_TASK_COUNT]
    if not top:
        return row("Các task tốn công", pill("neutral", "Chưa gắn issue"), "Nhắc #số-issue trong prompt để theo dõi theo task.", "")
    causes = {(str(c.get("project")), str(c.get("task"))): c for c in (review or {}).get("costly_tasks", [])}
    max_turns = max(t["turns"] for t in top)
    detail = ""
    for index, t in enumerate(top):
        tip = f'Phải sửa {percent(t["corrections"] / t["turns"])} · bị ngắt {percent(t["interrupts"] / t["turns"])} · token {format_tokens(round(t["tokens"] / 1000))}'
        found = causes.get((str(t["project"]), str(t["task"])))
        label = str(found.get("title") or "").strip() if found else ""
        label = label or task_label(t["task"])
        turns_text = f'{t["turns"]} lượt'
        detail += f'<div class="task">{bar_row(index, label, t["turns"], max_turns, turns_text, tip)}{task_findings(found)}</div>'
    first = top[0]
    first_cause = causes.get((str(first["project"]), str(first["task"])), {}).get("cause")
    first_line = (first_cause[0] if isinstance(first_cause, list) and first_cause else first_cause) or "chưa phân tích nguyên nhân"
    first_label = str(causes.get((str(first["project"]), str(first["task"])), {}).get("title") or "").strip() or task_label(first["task"])
    insight = f'<span class="clip">{html.escape(first_label)} · {first["turns"]} lượt · {rich_text(first_line)}</span>'
    return row("Các task tốn công", pill("neutral", f"{len(top)} task"), insight, detail, "ai")

def actions_row(review):
    actions = (review or {}).get("actions") or []
    date = html.escape(str((review or {}).get("date", "")), quote=True)
    if actions:
        items = "".join(f'<li><label><input type="checkbox" data-key="{date}-{i}"><span>{rich_text(a)}</span></label></li>' for i, a in enumerate(actions))
        body = f'<ol class="actions">{items}</ol><p class="note" data-progress data-total="{len(actions)}"></p>'
    else:
        body = '<div class="row-insight">Chạy /ai-score để có gợi ý.</div>'
    return f'<div class="row row-static"><div class="row-head"><span class="row-title">Tuần tới làm gì?</span>{tag("ai")}</div>{body}</div>'

def stats_strip(week):
    if not week:
        return ""
    cards = [("Task", str(week["task_count"])), ("Lượt nhắn", str(week["turns"])),
             ("Token mỗi task", format_tokens(round(week["tokens_k_per_task"])))]
    return '<div class="stats">' + "".join(f'<div class="stat"><b>{html.escape(v)}</b><span>{html.escape(l)}</span></div>' for l, v in cards) + "</div>"

def project_summary(tasks):
    count = len(tasks)
    return dict(task_count=count, turns=sum(t["turns"] for t in tasks),
                first_pass_pct=100 * sum(1 for t in tasks if t["corrections"] + t["interrupts"] == 0) / count,
                tokens_k_per_task=sum(t["tokens"] for t in tasks) / 1000 / count)

def project_weakness_row(review, project, task_count):
    if task_count < PROJECT_MIN_TASKS:
        return row("Điểm yếu lặp lại", pill("neutral", "Chưa đủ dữ liệu"), f"Dưới {PROJECT_MIN_TASKS} task, chưa đủ để rút điểm yếu.", "", "ai")
    found = next((p for p in (review or {}).get("projects", []) if str(p.get("project")) == project), None)
    weaknesses = as_list(found.get("weaknesses")) if found else []
    if not weaknesses:
        return row("Điểm yếu lặp lại", pill("neutral", "Chưa phân tích"), "Chạy /ai-score để có nhận định cho dự án này.", "", "ai")
    return row("Điểm yếu lặp lại", pill("warn", f"{len(weaknesses)} điểm"), f'<span class="clip">{rich_text(weaknesses[0])}</span>', bullet_list(weaknesses, "bullets"), "ai")

def project_skills_row(tasks):
    counts = Counter(skill for t in tasks for skill in t["skills"])
    if not counts:
        return row("Skill đã dùng", pill("neutral", "Chưa dùng"), "Chưa task nào trong dự án dùng skill.", "", "data")
    max_count = max(counts.values())
    bars = "".join(bar_row(i, skill, count, max_count, f"{count} task", f"{count}/{len(tasks)} task trong dự án")
                   for i, (skill, count) in enumerate(counts.most_common()))
    used_tasks = sum(1 for t in tasks if t["skills"])
    return row("Skill đã dùng", pill("neutral", f"{len(counts)} skill"), f"{used_tasks}/{len(tasks)} task có dùng skill", bars, "data")

def project_task_row(task, found, project_tokens):
    label = str(found.get("title") or "").strip() if found else ""
    label = label or task_label(task["task"])
    causes = as_list(found.get("cause")) if found else []
    solutions = as_list(found.get("solution")) if found else []
    token_share = f'chiếm {percent(task["tokens"] / project_tokens)} token dự án' if project_tokens else ""
    cause_line = rich_text(causes[0]) if causes else "chưa phân tích nguyên nhân"
    cause_text = f'{html.escape(token_share)} · {cause_line}' if token_share else cause_line
    insight = f'<span class="stack"><span class="clip">{cause_text}</span>'
    if solutions:
        insight += f'<span class="clip">{rich_text("Làm gì: " + solutions[0])}</span>'
    insight += '</span>'
    skills_used = ", ".join(sorted(task["skills"])) or "không dùng skill nào"
    facts = f'<p class="note">Skill đã dùng: {html.escape(skills_used)}.</p>'
    if found and found.get("suggested_skill"):
        facts += f'<p class="note">Skill nên dùng: {html.escape(str(found["suggested_skill"]))}.</p>'
    if found and "specs" in found:
        specs = as_list(found.get("specs"))
        facts += f'<p class="note">Spec: {html.escape(", ".join(specs)) if specs else "chưa có file spec"}.</p>'
    return row(html.escape(label), pill("neutral", f'{task["turns"]} lượt'), insight, task_findings(found, show_first_solution=False) + facts)

def project_pane(index, project, tasks, causes, review):
    ordered = sorted(tasks, key=lambda t: (-t["turns"], -t["human_s"]))
    project_tokens = sum(t["tokens"] for t in tasks)
    task_rows = "".join(project_task_row(t, causes.get((project, str(t["task"]))), project_tokens) for t in ordered)
    overview_rows = project_weakness_row(review, project, len(tasks)) + project_skills_row(tasks)
    note = '<p class="note">Điểm kỹ năng chỉ tính chung, chưa tách theo dự án.</p>'
    return (f'<div class="pane" data-pane="p{index}" hidden><h2 class="pane-title">{html.escape(project)}</h2>{stats_strip(project_summary(tasks))}{note}'
            f'<div class="list">{overview_rows}</div><h3 class="section-title">Task của dự án</h3><div class="list">{task_rows}</div></div>')

def project_sidebar(projects):
    buttons = '<button type="button" data-target="overview" aria-current="true">Tổng quan</button>'
    for i, (project, tasks) in enumerate(projects):
        buttons += f'<button type="button" data-target="p{i}" aria-current="false"><span class="clip">{html.escape(project)}</span><small>{sum(t["turns"] for t in tasks)}</small></button>'
    return f'<nav class="side" aria-label="Dự án">{buttons}</nav>'

def hero(review, previous_review):
    average, previous_average = average_score(review), average_score(previous_review)
    kind, word = score_state(average)
    ring_value = f"{average:.1f}" if average is not None else "—"
    ring = f'<div class="ring" style="--p:{100 * (average or 0) / 5:.0f}"><span><b>{ring_value}</b><small>điểm / 5</small></span></div>'
    if average is None:
        delta = "Chạy /ai-score để có điểm tuần này."
    elif previous_average is None:
        delta = ""
    else:
        change = average - previous_average
        arrow = f'<span class="{"up" if change > 0 else "down"}">{"▲" if change > 0 else "▼"} {abs(change):.1f}</span>' if abs(change) >= 0.05 else "= Không đổi"
        delta = f"{arrow} so với tuần trước ({previous_average:.1f})"
    summary = (review or {}).get("summary")
    summary_html = bullet_list(summary, "summary") if summary else ""
    return (f'<section class="hero">{ring}<div><div class="hero-state"><span class="state-word {kind}">{html.escape(word)}</span>'
            f'<span class="hero-delta">{delta}</span></div>{summary_html}</div></section>')

def write_html(path, weeks, windows):
    reviews = load_reviews()
    options, blocks = "", ""
    for window in windows:
        k = window["weeks_ago"]
        review = review_for_window(reviews, window)
        previous_review = review_for_window(reviews, windows[k + 1]) if k + 1 < TREND_WEEKS else None
        if not weeks[k] and not review:
            continue
        week = weeks[k]
        has_previous = (k + 1 < TREND_WEEKS and weeks[k + 1]) or previous_review
        notice = "" if has_previous else '<p class="notice">Chưa có tuần trước để so sánh. Xu hướng sẽ hiện từ tuần sau.</p>'
        facts = "" if week else " · Không có lượt nhắn nào"
        options += f'<option value="{k}">{html.escape(window["name"])} · {window["span"]}</option>'
        by_project = {}
        for t in (week or {}).get("tasks", []):
            by_project.setdefault(str(t["project"]), []).append(t)
        projects = sorted(by_project.items(), key=lambda kv: -sum(t["turns"] for t in kv[1]))
        causes = {(str(c.get("project")), str(c.get("task"))): c for c in (review or {}).get("costly_tasks", [])}
        overview = (hero(review, previous_review) + stats_strip(week) + notice
                    + '<div class="list">' + progress_row(review, previous_review)
                    + costly_row(week, review) + actions_row(review) + "</div>")
        panes = "".join(project_pane(i, project, tasks, causes, review) for i, (project, tasks) in enumerate(projects))
        blocks += (f'<div class="week" data-week="{k}"><h1>{html.escape(window["span"])}</h1><p class="facts">{html.escape(window["name"])}{html.escape(facts)}</p>'
                   f'<div class="layout">{project_sidebar(projects) if projects else ""}<div class="panes"><div class="pane" data-pane="overview">{overview}</div>{panes}</div></div></div>')
    if not options:
        options = '<option value="0">Tuần này</option>'
        blocks = f'<div class="week" data-week="0"><h1>Chưa có dữ liệu</h1>{empty("Hook chưa ghi được lượt nhắn nào.")}</div>'
    page = (f'<!doctype html><html lang="vi"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>Báo cáo dùng AI</title><style>{HTML_STYLE}</style></head><body><main>'
            f'<header><span class="eyebrow">Báo cáo dùng AI</span><select id="week-picker" aria-label="Chọn tuần">{options}</select></header>'
            f'{blocks}</main><div id="tip" role="tooltip"></div><script>{HTML_SCRIPT}</script></body></html>')
    with open(path, "w", encoding="utf-8") as f:
        f.write(page)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--weeks-ago", type=int, help="chỉ lấy tuần lịch (thứ 2–CN) cách đây N tuần, 0 là tuần này; thay cho --days")
    ap.add_argument("--project")
    ap.add_argument("--gh", action="store_true", help="hỏi trạng thái issue qua gh CLI")
    ap.add_argument("--csv")
    ap.add_argument("--html")
    ap.add_argument("--json", help="xuất dữ liệu cho skill ai-score")
    a = ap.parse_args()

    db = sqlite3.connect(DB)
    now = time.time()
    windows = week_windows(now)
    if a.weeks_ago is not None:
        window = windows[a.weeks_ago]
        since, until, week_start = window["start"], window["end"], window["week_start"]
    else:
        since, until, week_start = now - a.days * 86400, now + 1, None
    q = "SELECT id, session_id, project, cwd, task, prompt_ts, stop_ts, is_correction, tool_calls, tool_failures, tok_in+tok_cache_read+tok_cache_write, tok_out FROM turns WHERE prompt_ts>=? AND prompt_ts<?" + NOT_IGNORED_TURN
    params = [since, until, *IGNORED_SKILLS]
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

    if a.html or a.json:
        weeks = weekly_stats(db, a.project, now)
        if a.json:
            export_json(a.json, db, a.days, since, until, week_start, out, skill_rows, weeks, windows)
            print(f"Đã ghi {a.json}")
        if a.html:
            write_html(a.html, weeks, windows)
            print(f"Đã ghi {a.html}")

if __name__ == "__main__":
    main()
