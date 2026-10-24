#!/usr/bin/env python3
"""Báo cáo hiệu quả theo task (GitHub issue) và theo skill.
Dùng: python3 ai_report.py [--days 30] [--project tên] [--gh] [--csv out.csv] [--html out.html] [--json out.json]"""
import argparse, csv, glob, html, json, os, re, sqlite3, subprocess, time, urllib.parse
from collections import defaultdict

DB = os.path.expanduser(os.environ.get("AI_METRICS_DB", "~/.ai-metrics/metrics.db"))
REVIEW_DIR = os.path.expanduser(os.environ.get("AI_METRICS_REVIEW_DIR", "~/.ai-metrics/reviews"))
TRANSCRIPT_GLOB = os.path.expanduser("~/.claude/projects/*/{session_id}.jsonl")
IDLE_CAP = 600  # giây: khoảng nghỉ dài hơn coi là idle (tmux treo), không tính
MIN_TASKS_PER_SKILL = 5
TREND_WEEKS = 8
WEEK_SECONDS = 7 * 86400
COSTLY_TASK_COUNT = 3
UNASSIGNED_TASK = "(chưa gắn)"
INLINE_MARKUP_RE = re.compile(r"\*\*(.+?)\*\*|`([^`]+)`")
TREND_METRICS = [
    ("first_pass_pct", "Xong ngay lần đầu", lambda v: f"{v:.0f}%", True),
    ("correction_pct", "Phải sửa lại", lambda v: f"{v:.0f}%", False),
    ("interrupt_pct", "Bị ngắt giữa chừng", lambda v: f"{v:.0f}%", False),
    ("tokens_k_per_task", "Token mỗi task", lambda v: format_tokens(round(v)), False),
]
HTML_STYLE = """
:root{--bg:#f6f5f1;--surface:#ffffff;--ink:#141413;--ink2:#5c5b57;--muted:#6f6d67;--line:#e7e5df;--track:#eeece6;--primary:#2a78d6;
--good:#0ca30c;--good-text:#006300;--warn:#fab219;--bad:#d03b3b;--neutral:#8d8b85;
--r-lg:16px;--r-md:10px;--s1:4px;--s2:8px;--s3:12px;--s4:16px;--s5:24px;--s6:32px}
@media (prefers-color-scheme:dark){:root{--bg:#0f0f0e;--surface:#1a1a19;--ink:#f0efec;--ink2:#c3c2b7;--muted:#8d8b85;--line:#2c2c2a;--track:#2c2c2a;--primary:#3987e5;--good-text:#0ca30c}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:720px;margin:0 auto;padding:var(--s5) var(--s4) 64px}
header{display:flex;align-items:center;justify-content:space-between;gap:var(--s3)}
.eyebrow{font-size:12px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
select{font:inherit;font-size:14px;font-weight:600;min-height:40px;padding:6px 30px 6px 14px;border-radius:999px;border:1px solid var(--line);background:var(--surface);color:var(--ink);cursor:pointer}
h1{font-size:28px;line-height:1.2;margin:var(--s5) 0 var(--s1)}
.facts{color:var(--ink2);font-size:14px;margin:0}
.hero{display:flex;gap:var(--s5);align-items:center;margin-top:var(--s5);padding:var(--s5);background:var(--surface);border:1px solid var(--line);border-radius:var(--r-lg)}
.ring{flex:none;width:128px;height:128px;border-radius:50%;display:grid;place-items:center;background:conic-gradient(var(--primary) calc(var(--p)*1%),var(--track) 0);animation:fill 1.1s cubic-bezier(.2,.8,.2,1) both}
.ring span{width:104px;height:104px;border-radius:50%;background:var(--surface);display:grid;place-content:center;text-align:center}
.ring b{font-size:40px;line-height:1;font-weight:700}
.ring small{font-size:12px;color:var(--muted)}
@property --p{syntax:'<number>';inherits:false;initial-value:0}
@keyframes fill{from{--p:0}}
.hero-state{display:flex;flex-wrap:wrap;align-items:baseline;gap:var(--s3)}
.state-word{font-size:26px;font-weight:800;letter-spacing:-.01em}
.state-word.good{color:var(--good-text)}.state-word.bad{color:var(--bad)}.state-word.warn,.state-word.neutral{color:var(--ink)}
.hero-delta{font-size:14px;color:var(--ink2)}
.up{color:var(--good-text);font-weight:700}.down{color:var(--bad);font-weight:700}
.summary{margin:var(--s3) 0 0;padding:0;list-style:none;font-size:15px;display:grid;gap:var(--s2)}
.summary li{display:flex;gap:var(--s3);align-items:baseline}
.list{margin-top:var(--s4);background:var(--surface);border:1px solid var(--line);border-radius:var(--r-lg);overflow:hidden}
.row{border-top:1px solid var(--line)}
.row:first-child{border-top:0}
.row>summary,.row-static{list-style:none;cursor:pointer;padding:var(--s4) var(--s5);display:block}
.row-static{cursor:default}
.row>summary::-webkit-details-marker{display:none}
.row>summary:focus-visible,select:focus-visible{outline:2px solid var(--primary);outline-offset:-2px}
.lead{flex:none;display:inline-block;min-width:64px;text-align:center;font-size:11px;font-weight:700;letter-spacing:.05em;text-transform:uppercase;padding:3px 8px;border-radius:6px;background:var(--track);color:var(--ink2);margin-right:var(--s2);vertical-align:1px}
.summary .lead{margin-right:0}
.lead.good{background:color-mix(in srgb,var(--good) 15%,transparent);color:var(--good-text)}
.lead.bad{background:color-mix(in srgb,var(--bad) 13%,transparent);color:var(--bad)}
a.file{color:var(--primary);font:600 13px ui-monospace,SFMono-Regular,Menlo,monospace;text-decoration:underline dotted;text-underline-offset:3px}
code{font:13px ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--track);padding:1px 5px;border-radius:4px}
.clip{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.row>summary:hover{background:color-mix(in srgb,var(--ink) 3%,transparent)}
.row-head{display:flex;align-items:center;gap:var(--s3)}
.row-title{font-size:16px;font-weight:700;flex:1}
.chev{width:8px;height:8px;border-right:2px solid var(--muted);border-bottom:2px solid var(--muted);transform:rotate(-45deg);transition:transform .2s;margin-left:var(--s1)}
.row[open] .chev{transform:rotate(45deg)}
.row-insight{display:flex;align-items:center;gap:var(--s3);margin-top:6px;color:var(--ink2);font-size:14px}
.pill{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:12px;font-weight:700;letter-spacing:.03em;text-transform:uppercase;background:var(--track);color:var(--ink)}
.pill i{width:8px;height:8px;border-radius:50%;background:var(--neutral)}
.pill.good i{background:var(--good)}.pill.warn i{background:var(--warn)}.pill.bad i{background:var(--bad)}
.segments{display:inline-flex;gap:3px;flex:none}
.segments span{width:14px;height:8px;border-radius:2px;background:var(--track)}
.segments span.on{background:var(--primary)}
.mini-spark{width:72px;height:22px;flex:none;overflow:visible}
.mini-spark polyline{fill:none;stroke:var(--primary);stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
.mini-spark circle{fill:var(--primary)}
.row-detail{padding:0 var(--s5) var(--s5)}
.metrics{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:var(--s3)}
.metric{padding:var(--s3);border-radius:var(--r-md);background:var(--bg)}
.metric-label{font-size:13px;color:var(--ink2)}
.metric-value{font-size:24px;font-weight:700;line-height:1.25}
.delta{font-size:12px;color:var(--ink2)}
.good{color:var(--good-text);font-weight:700}.bad{color:var(--bad);font-weight:700}
.spark{display:block;width:100%;height:34px;margin-top:6px;overflow:visible}
.spark polyline{fill:none;stroke:var(--primary);stroke-width:2;stroke-linejoin:round;stroke-linecap:round}
.spark circle{fill:var(--primary);stroke:var(--bg);stroke-width:2}
.spark circle.selected{r:6;stroke:var(--ink)}
.bar-row{display:grid;grid-template-columns:minmax(0,1fr) 1.4fr auto;gap:var(--s3);align-items:center;padding:6px 0}
.bar-name{font-size:14px;font-weight:600}
.bar-track{position:relative;height:10px;background:var(--track);border-radius:0 4px 4px 0}
.bar{height:100%;background:var(--primary);border-radius:0 4px 4px 0;animation:grow .8s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--i,0)*80ms)}
.bar-prev{position:absolute;top:-4px;width:2px;height:18px;background:var(--ink2)}
.bar-value{min-width:40px;white-space:nowrap;font-weight:700;text-align:right;font-variant-numeric:tabular-nums;font-size:14px}
.weak .bar-name{color:var(--bad)}
@keyframes grow{from{width:0}}
.quote{margin:var(--s3) 0 0;padding:var(--s2) var(--s3);border-left:3px solid var(--bad);background:var(--bg);border-radius:0 8px 8px 0;font-size:13px}
.note{color:var(--muted);font-size:12px;margin:var(--s2) 0 0}
.task{padding-top:var(--s3)}
.task+.task{margin-top:var(--s3);border-top:1px solid var(--line)}
.bullets{margin:2px 0 0;padding-left:18px;font-size:14px}
.bullets li{margin:2px 0}
.actions{margin:var(--s3) 0 0;padding:0;list-style:none;counter-reset:a;display:grid;gap:var(--s3)}
.actions li{counter-increment:a;display:flex;gap:var(--s3);align-items:flex-start;font-size:15px}
.actions li::before{content:counter(a);flex:none;width:26px;height:26px;border-radius:50%;background:var(--primary);color:#fff;display:grid;place-items:center;font-weight:700;font-size:13px}
.empty{color:var(--ink2);font-size:14px;margin:0}
.empty code{background:var(--track);padding:1px 6px;border-radius:4px}
#tip{position:fixed;left:0;top:0;pointer-events:none;background:var(--ink);color:var(--surface);padding:6px 10px;border-radius:8px;font-size:13px;max-width:300px;opacity:0;transition:opacity .12s;z-index:9}
@media (max-width:520px){.hero{flex-direction:column;align-items:flex-start}.metrics{grid-template-columns:1fr}.row>summary,.row-static,.row-detail{padding-left:var(--s4);padding-right:var(--s4)}}
@media (prefers-reduced-motion:reduce){.bar,.ring{animation:none}.chev{transition:none}}
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
const picker=document.getElementById('week-picker');
function showWeek(){document.querySelectorAll('.week').forEach(w=>{w.hidden=w.dataset.week!==picker.value})}
picker.addEventListener('change',showWeek);
showWeek();
"""

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

def weekly_stats(db, project, now):
    q = ("SELECT session_id, project, task, prompt_ts, stop_ts, is_correction, tok_in+tok_cache_read+tok_cache_write+tok_out"
         " FROM turns WHERE prompt_ts>=?")
    params = [now - (TREND_WEEKS + 1) * WEEK_SECONDS]
    if project:
        q += " AND project=?"; params.append(project)
    rows = db.execute(q + " ORDER BY session_id, id", params).fetchall()
    weeks = [dict(empty_stats(), tasks=defaultdict(empty_stats)) for _ in range(TREND_WEEKS + 1)]
    for i, (sid, proj, task, p_ts, s_ts, corr, tokens) in enumerate(rows):
        weeks_ago = int((now - p_ts) // WEEK_SECONDS)
        if weeks_ago > TREND_WEEKS:
            continue
        week = weeks[weeks_ago]
        nxt = rows[i + 1] if i + 1 < len(rows) and rows[i + 1][0] == sid else None
        interrupted = 1 if not s_ts and nxt else 0
        human_s = min(max(0, nxt[3] - s_ts), IDLE_CAP) if s_ts and nxt else 0
        for target in (week, week["tasks"][(proj, task or UNASSIGNED_TASK)]):
            target["turns"] += 1; target["corrections"] += corr; target["interrupts"] += interrupted
            target["tokens"] += tokens; target["human_s"] += human_s
    return [summarize_week(week) for week in weeks]

def week_windows(now):
    windows = []
    for weeks_ago in range(TREND_WEEKS):
        start, end = now - (weeks_ago + 1) * WEEK_SECONDS, now - weeks_ago * WEEK_SECONDS
        name = "Tuần này" if weeks_ago == 0 else "Tuần trước" if weeks_ago == 1 else f"{weeks_ago} tuần trước"
        span = f'{time.strftime("%d/%m", time.localtime(start))}–{time.strftime("%d/%m", time.localtime(end))}'
        windows.append(dict(weeks_ago=weeks_ago, start=start, end=end, name=name, span=span))
    return windows

def task_context(db, project, task, since):
    condition, params = ("task IS NULL", [project, since]) if task == UNASSIGNED_TASK else ("task=?", [project, since, task])
    found = db.execute(f"SELECT session_id, cwd FROM turns WHERE project=? AND prompt_ts>=? AND {condition} GROUP BY session_id", params).fetchall()
    sessions = [dict(session_id=sid, transcript=next(iter(glob.glob(TRANSCRIPT_GLOB.format(session_id=sid))), None)) for sid, _ in found]
    return dict(cwd=found[0][1] if found else "", sessions=sessions)

def costly_tasks(task_rows):
    assigned = [r for r in task_rows if r["task"] != UNASSIGNED_TASK]
    return sorted(assigned, key=lambda r: (-r["turns"], -r["you_min"]))[:COSTLY_TASK_COUNT]

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
               if reviewed_at > window["start"] and (window["weeks_ago"] == 0 or reviewed_at <= window["end"])]
    return matched[-1] if matched else None

def export_json(path, db, days, since, task_rows, skill_rows, weeks, windows):
    costly_keys = {(r["project"], r["task"]) for r in costly_tasks(task_rows)}
    tasks = [dict(r, costly=(r["project"], r["task"]) in costly_keys, **task_context(db, r["project"], r["task"], since)) for r in task_rows]
    trend = [dict(week=w["span"], metrics={k: v for k, v in m.items() if k != "tasks"} if m else None)
             for w, m in reversed(list(zip(windows, weeks)))]
    data = dict(generated_at=time.strftime("%Y-%m-%d %H:%M"), days=days, rubric=os.path.join(os.path.dirname(os.path.abspath(__file__)), "rubric.md"),
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
        tone = {"mạnh": "good", "yếu": "bad"}.get(lead.group(1).strip().lower(), "")
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

def spark_points(values, width, height, pad):
    points = [(i, v) for i, v in enumerate(values) if v is not None]
    if len(points) < 2:
        return []
    low, high = min(v for _, v in points), max(v for _, v in points)
    span = (high - low) or 1
    return [(i, v, pad + i * (width - 2 * pad) / (len(values) - 1), height - pad - (v - low) * (height - 2 * pad) / span) for i, v in points]

def sparkline(values, labels, selected, formatter):
    coords = spark_points(values, 200, 34, 6)
    if not coords:
        return ""
    line = " ".join(f"{x:.1f},{y:.1f}" for _, _, x, y in coords)
    dots = "".join(f'<circle class="{"selected" if i == selected else ""}" cx="{x:.1f}" cy="{y:.1f}" r="4" {tooltip_attrs(f"{labels[i]}: {formatter(v)}")}/>'
                   for i, v, x, y in coords)
    return f'<svg class="spark" viewBox="0 0 200 34" role="img" aria-label="Xu hướng"><polyline points="{line}"/>{dots}</svg>'

def mini_sparkline(values):
    coords = spark_points(values, 72, 22, 3)
    if not coords:
        return ""
    line = " ".join(f"{x:.1f},{y:.1f}" for _, _, x, y in coords)
    _, _, last_x, last_y = coords[-1]
    return f'<svg class="mini-spark" viewBox="0 0 72 22" aria-hidden="true"><polyline points="{line}"/><circle cx="{last_x:.1f}" cy="{last_y:.1f}" r="3"/></svg>'

def segments(score):
    return '<span class="segments" aria-hidden="true">' + "".join(f'<span class="{"on" if i < round(score) else ""}"></span>' for i in range(5)) + "</span>"

def delta_html(current, previous, formatter, higher_is_better):
    if previous is None:
        return '<div class="delta">Chưa có tuần trước để so</div>'
    if abs(current - previous) < 1e-9:
        return f'<div class="delta">= Không đổi ({formatter(previous)})</div>'
    improved = (current > previous) == higher_is_better
    arrow = "▲" if current > previous else "▼"
    return (f'<div class="delta"><span class="{"good" if improved else "bad"}">{arrow} {"Tốt hơn" if improved else "Kém hơn"}</span>'
            f' · trước đó {html.escape(formatter(previous))}</div>')

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

def metric_changes(week, previous_week):
    return [(label, (week[key] - previous_week[key]) * (1 if higher_is_better else -1))
            for key, label, _, higher_is_better in TREND_METRICS]

def row(title, status, insight, detail):
    return (f'<details class="row"><summary><div class="row-head"><span class="row-title">{title}</span>{status}<span class="chev"></span></div>'
            f'<div class="row-insight">{insight}</div></summary><div class="row-detail">{detail}</div></details>')

def progress_row(weeks, windows, weeks_ago):
    week, previous_week = weeks[weeks_ago], weeks[weeks_ago + 1]
    if not week:
        return row("Có tiến bộ không?", pill("neutral", "Chưa có dữ liệu"), "Tuần này chưa có lượt nhắn nào.", "")
    oldest_first = list(reversed(range(TREND_WEEKS)))
    labels = [windows[k]["span"] for k in oldest_first]
    first_pass = [weeks[k]["first_pass_pct"] if weeks[k] else None for k in oldest_first]
    if previous_week:
        changes = metric_changes(week, previous_week)
        better = sum(1 for _, change in changes if change > 1e-9)
        worse = sum(1 for _, change in changes if change < -1e-9)
        status = pill("good", "Tiến bộ") if better > worse else pill("bad", "Đi xuống") if worse > better else pill("warn", "Đi ngang")
        insight = f"{better}/{len(changes)} chỉ số tốt hơn tuần trước"
    else:
        status = pill("neutral", "Chưa đủ dữ liệu")
        insight = f"Xong ngay lần đầu {week['first_pass_pct']:.0f}% · cần thêm 1 tuần để so"
    metrics = ""
    for key, label, formatter, higher_is_better in TREND_METRICS:
        previous = previous_week[key] if previous_week else None
        values = [weeks[k][key] if weeks[k] else None for k in oldest_first]
        metrics += (f'<div class="metric"><div class="metric-label">{html.escape(label)}</div>'
                    f'<div class="metric-value">{html.escape(formatter(week[key]))}</div>'
                    f'{delta_html(week[key], previous, formatter, higher_is_better)}'
                    f'{sparkline(values, labels, oldest_first.index(weeks_ago), formatter)}</div>')
    return row("Có tiến bộ không?", status, mini_sparkline(first_pass) + f'<span class="clip">{html.escape(insight)}</span>', f'<div class="metrics">{metrics}</div>')

def skills_row(review, previous_review):
    ordered = sorted(scored(review), key=lambda s: s["score"])
    if not ordered:
        return row("Kỹ năng nào yếu?", pill("neutral", "Chưa chấm"), "Chạy /ai-review để AI chấm điểm.", "")
    weakest = ordered[0]
    kind, word = score_state(weakest["score"])
    previous_scores = {s["criterion"]: s["score"] for s in scored(previous_review)}
    bars = ""
    for index, s in enumerate(ordered):
        previous_score = previous_scores.get(s["criterion"])
        tip = f'“{s.get("evidence", "")}”' + (f" · tuần trước {previous_score:g}/5" if previous_score is not None else "")
        bars += bar_row(index, str(s.get("name", "")), s["score"], 5, f'{s["score"]:g}/5', tip, previous_score, "weak" if s is weakest else "")
    quote = f'<p class="quote">“{html.escape(str(weakest.get("evidence", "")))}”</p>'
    unscored = [str(s.get("name", "")) for s in review["scores"] if s not in ordered]
    notes = ""
    if previous_scores:
        notes += '<p class="note">Vạch đứng = tuần trước. Di chuột vào thanh để xem bằng chứng.</p>'
    if unscored:
        notes += f'<p class="note">Chưa chấm được: {html.escape(", ".join(unscored))}.</p>'
    insight = segments(weakest["score"]) + f'<span class="clip">{html.escape(str(weakest.get("name", "")))} · {weakest["score"]:g}/5</span>'
    return row("Kỹ năng nào yếu?", pill(kind, word), insight, bars + quote + notes)

def costly_row(week, review):
    assigned = [t for t in (week or {}).get("tasks", []) if t["task"] != UNASSIGNED_TASK]
    top = sorted(assigned, key=lambda t: (-t["turns"], -t["human_s"]))[:COSTLY_TASK_COUNT]
    if not top:
        return row("Vì sao task tốn công?", pill("neutral", "Chưa gắn issue"), "Nhắc #số-issue trong prompt để theo dõi theo task.", "")
    causes = {(str(c.get("project")), str(c.get("task"))): c for c in (review or {}).get("costly_tasks", [])}
    max_turns = max(t["turns"] for t in top)
    detail = ""
    for index, t in enumerate(top):
        tip = f'Phải sửa {percent(t["corrections"] / t["turns"])} · bị ngắt {percent(t["interrupts"] / t["turns"])} · token {format_tokens(round(t["tokens"] / 1000))}'
        found = causes.get((str(t["project"]), str(t["task"])))
        cause = bullet_list(found.get("cause", ""), "bullets") if found else '<p class="note">Chưa phân tích nguyên nhân.</p>'
        turns_text = f'{t["turns"]} lượt'
        detail += f'<div class="task">{bar_row(index, task_label(t["task"]), t["turns"], max_turns, turns_text, tip)}{cause}</div>'
    first = top[0]
    first_cause = causes.get((str(first["project"]), str(first["task"])), {}).get("cause")
    first_line = (first_cause[0] if isinstance(first_cause, list) and first_cause else first_cause) or "chưa phân tích nguyên nhân"
    insight = f'<span class="clip">{html.escape(task_label(first["task"]))} · {first["turns"]} lượt · {rich_text(first_line)}</span>'
    return row("Vì sao task tốn công?", pill("neutral", f"{len(top)} task"), insight, detail)

def actions_row(review):
    actions = (review or {}).get("actions") or []
    body = ('<ol class="actions">' + "".join(f"<li><span>{rich_text(a)}</span></li>" for a in actions) + "</ol>") if actions \
        else '<div class="row-insight">Chạy /ai-review để có gợi ý.</div>'
    return f'<div class="row row-static"><div class="row-head"><span class="row-title">Tuần tới làm gì?</span></div>{body}</div>'

def hero(review, previous_review):
    average, previous_average = average_score(review), average_score(previous_review)
    kind, word = score_state(average)
    ring_value = f"{average:.1f}" if average is not None else "—"
    ring = f'<div class="ring" style="--p:{100 * (average or 0) / 5:.0f}"><span><b>{ring_value}</b><small>điểm / 5</small></span></div>'
    if average is None:
        delta = "Chạy /ai-review để có điểm tuần này."
    elif previous_average is None:
        delta = "Chưa có điểm tuần trước để so."
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
        facts = f'{week["task_count"]} task · {week["turns"]} lượt nhắn' if week else "Không có lượt nhắn nào"
        options += f'<option value="{k}">{html.escape(window["name"])} · {window["span"]}</option>'
        blocks += (f'<div class="week" data-week="{k}"><h1>{html.escape(window["span"])}</h1><p class="facts">{html.escape(window["name"])} · {html.escape(facts)}</p>'
                   + hero(review, previous_review)
                   + '<div class="list">' + progress_row(weeks, windows, k) + skills_row(review, previous_review)
                   + costly_row(week, review) + actions_row(review) + "</div></div>")
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
    ap.add_argument("--project")
    ap.add_argument("--gh", action="store_true", help="hỏi trạng thái issue qua gh CLI")
    ap.add_argument("--csv")
    ap.add_argument("--html")
    ap.add_argument("--json", help="xuất dữ liệu cho skill ai-review")
    a = ap.parse_args()

    db = sqlite3.connect(DB)
    now = time.time()
    since = now - a.days * 86400
    q = "SELECT id, session_id, project, cwd, task, prompt_ts, stop_ts, is_correction, tool_calls, tool_failures, tok_in+tok_cache_read+tok_cache_write, tok_out FROM turns WHERE prompt_ts>=?"
    params = [since]
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
        windows = week_windows(now)
        if a.json:
            export_json(a.json, db, a.days, since, out, skill_rows, weeks, windows)
            print(f"Đã ghi {a.json}")
        if a.html:
            write_html(a.html, weeks, windows)
            print(f"Đã ghi {a.html}")

if __name__ == "__main__":
    main()
