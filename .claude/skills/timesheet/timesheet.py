#!/usr/bin/env python3
from __future__ import annotations

import argparse
import bisect
import glob
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, replace
from datetime import datetime

DEFAULT_IDLE_MINUTES = 30
SECONDS_PER_HOUR = 3600
SECONDS_PER_MINUTE = 60
DATE_FORMAT = "%Y-%m-%d"
ROUNDING_STEP_HOURS = 0.05
TRANSCRIPTS_ROOT = os.path.expanduser("~/.claude/projects")
SPECS_ISSUES_DIR = os.path.join("specs", "issues")
UNASSIGNED = "none"

PHASES = ("plan", "implement", "review", "fix_spec", "fix_code")
WORK_PHASES = ("plan", "implement")
REVIEW_PHASES = ("review", "fix_spec", "fix_code")
PLAN_SKILLS = frozenset({
    "feature-discuss", "generate-issues", "github-issues-to-md", "implement-prepare",
    "issue-docs", "risk-issue", "review-specs", "fix-issue", "create-issue",
    "plan-design", "ui-ux-workflow", "plan-story", "plan-prd",
})
REVIEW_SKILLS = frozenset({"review-issue", "review-branch", "code-review", "security-review"})

ISSUE_MENTION_PATTERN = re.compile(
    r"(?:(?<![\w#&])#|\bissues?[ /#-]?|github\.com/[^/\s]+/[^/\s]+/issues/)([1-9]\d{0,3})(?![0-9a-fA-F])",
    re.IGNORECASE,
)
SPEC_PATH_PATTERN = re.compile(r"specs/issues/([\w.-]+?)(?:/|\.md|\")")
SPEC_ISSUE_LINK_PATTERN = re.compile(r"GitHub Issue:\s*#(\d+)|github\.com/[^/\s]+/[^/\s]+/issues/(\d+)")
COMMAND_NAME_PATTERN = re.compile(r"<command-name>/?([\w:-]+)</command-name>")
REFLOG_CHECKOUT_PATTERN = re.compile(r"HEAD@\{(\d+)\}: checkout: moving from \S+ to (\S+)")
BRANCH_ISSUE_PATTERN = re.compile(r"#(\d+)")
LEADING_NUMBER_PATTERN = re.compile(r"^([1-9]\d*)-")
REMOVED_WORKTREE_ISSUE_PATTERN = re.compile(r"--(\d+)-")
WORK_BRANCH_PATTERN = re.compile(
    r"\b(?:feature|fix|bugfix|hotfix|chore|docs|refactor)"
    r"[/-][A-Za-z0-9]+-+#?([1-9]\d{0,3})-"
)
PULL_REQUEST_LIMIT = "500"


@dataclass(frozen=True)
class ActivityPoint:
    timestamp: float
    issue: str
    skill: str | None
    edited_paths: tuple


@dataclass
class SessionState:
    issue: str | None = None
    issue_signal_time: float = 0.0
    skill: str | None = None

    def link_issue(self, issue, timestamp):
        self.issue, self.issue_signal_time = issue, timestamp


@dataclass(frozen=True)
class IssueLookup:
    spec_to_issue: dict
    pull_request_to_issue: dict

    def resolve(self, number):
        return self.pull_request_to_issue.get(number, number)


def parse_arguments():
    parser = argparse.ArgumentParser(description="Estimate hours per GitHub issue from Claude Code transcripts")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--issue", action="append", default=[])
    parser.add_argument("--since", help="YYYY-MM-DD, local time")
    parser.add_argument("--idle-minutes", type=float, default=DEFAULT_IDLE_MINUTES)
    parser.add_argument("--json", action="store_true")

    return parser.parse_args()


def transcripts_dir_for(repo_path):
    mangled_name = re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(repo_path))

    return os.path.join(TRANSCRIPTS_ROOT, mangled_name)


def iso_to_epoch(iso_text):
    return datetime.fromisoformat(iso_text.replace("Z", "+00:00")).timestamp()


def read_spec_issue_numbers(repo_path):
    specs_dir = os.path.join(repo_path, SPECS_ISSUES_DIR)
    if not os.path.isdir(specs_dir):
        return {}

    spec_to_issue = {}
    for entry in os.listdir(specs_dir):
        spec_name = entry.removesuffix(".md")
        issue = issue_linked_in_spec(os.path.join(specs_dir, spec_name))
        if not issue:
            number_match = LEADING_NUMBER_PATTERN.match(spec_name)
            issue = number_match.group(1) if number_match else None
        if issue:
            spec_to_issue.setdefault(spec_name, issue)

    return spec_to_issue


def issue_linked_in_spec(spec_path_without_extension):
    candidate_files = [spec_path_without_extension + ".md"]
    candidate_files += glob.glob(os.path.join(spec_path_without_extension, "*.md"))
    for file_path in candidate_files:
        if not os.path.isfile(file_path):
            continue
        with open(file_path, encoding="utf-8") as spec_file:
            link_match = SPEC_ISSUE_LINK_PATTERN.search(spec_file.read())
        if link_match:
            return link_match.group(1) or link_match.group(2)

    return None


def read_pull_request_issues(repo_path):
    try:
        pull_requests_json = subprocess.run(
            ["gh", "pr", "list", "--state", "all", "--limit", PULL_REQUEST_LIMIT,
             "--json", "number,headRefName,closingIssuesReferences"],
            cwd=repo_path, capture_output=True, text=True, check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        print("Could not read pull requests with gh; PR numbers are counted as issues", file=sys.stderr)
        return {}

    pull_request_to_issue = {}
    for pull_request in json.loads(pull_requests_json):
        closed_issues = [str(issue["number"]) for issue in pull_request["closingIssuesReferences"]]
        issue = closed_issues[0] if closed_issues else issue_in_branch(pull_request["headRefName"])
        if issue:
            pull_request_to_issue[str(pull_request["number"])] = issue

    return pull_request_to_issue


def run_git(repo_path, *git_arguments):
    return subprocess.run(
        ["git", "-C", repo_path, *git_arguments],
        capture_output=True, text=True, check=True,
    ).stdout


def issue_in_branch(branch_name):
    branch_issue = BRANCH_ISSUE_PATTERN.search(branch_name or "")

    return branch_issue.group(1) if branch_issue else None


def list_worktrees(repo_path):
    worktrees = []
    for block in run_git(repo_path, "worktree", "list", "--porcelain").split("\n\n"):
        path_match = re.search(r"^worktree (.+)$", block, re.MULTILINE)
        branch_match = re.search(r"^branch refs/heads/(.+)$", block, re.MULTILINE)
        if path_match:
            worktrees.append((path_match.group(1), branch_match.group(1) if branch_match else None))

    return worktrees


def read_branch_switches(worktree_path, current_branch):
    switches = [(0, issue_in_branch(current_branch))]
    for line in run_git(worktree_path, "reflog", "--date=unix").splitlines():
        checkout_match = REFLOG_CHECKOUT_PATTERN.search(line)
        if checkout_match:
            switches.append((int(checkout_match.group(1)), issue_in_branch(checkout_match.group(2))))

    return sorted(switches)


def transcript_sources(repo_path):
    worktrees = list_worktrees(repo_path)
    main_transcripts_dir = transcripts_dir_for(worktrees[0][0])
    live_switches = {
        transcripts_dir_for(path): read_branch_switches(path, branch) for path, branch in worktrees
    }
    sources = []
    for transcripts_dir in glob.glob(main_transcripts_dir + "*"):
        removed_worktree_issue = REMOVED_WORKTREE_ISSUE_PATTERN.search(os.path.basename(transcripts_dir))
        fallback_switches = [(0, removed_worktree_issue.group(1) if removed_worktree_issue else None)]
        sources.append((transcripts_dir, live_switches.get(transcripts_dir, fallback_switches)))

    return sorted(sources)


def branch_issue_at(switches, timestamp):
    index = bisect.bisect_right([switch[0] for switch in switches], timestamp) - 1
    if index < 0:
        return None, 0.0

    return switches[index][1], float(switches[index][0])


def load_events(file_path, malformed_counter):
    events = []
    with open(file_path, encoding="utf-8") as transcript:
        for line in transcript:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                malformed_counter[file_path] += 1
                continue
            if "timestamp" in event:
                events.append(event)

    return sorted(events, key=lambda event: event["timestamp"])


def apply_user_prompt(state, content, timestamp, issue_lookup):
    state.skill = None
    command_match = COMMAND_NAME_PATTERN.search(content)
    if command_match:
        state.skill = command_match.group(1)
    mentions = ISSUE_MENTION_PATTERN.findall(content)
    if mentions:
        state.link_issue(issue_lookup.resolve(mentions[-1]), timestamp)


def apply_tool_calls(state, content, timestamp, issue_lookup):
    edited_paths = []
    for block in content:
        if block.get("type") != "tool_use":
            continue
        tool_input = block.get("input", {})
        if block.get("name") == "Skill":
            state.skill = tool_input.get("skill", state.skill)
        if block.get("name") in ("Edit", "Write"):
            edited_paths.append(tool_input.get("file_path", ""))
        tool_input_text = json.dumps(tool_input, ensure_ascii=False)
        for spec_name in SPEC_PATH_PATTERN.findall(tool_input_text):
            if spec_name in issue_lookup.spec_to_issue:
                state.link_issue(issue_lookup.spec_to_issue[spec_name], timestamp)
        branch_issues = WORK_BRANCH_PATTERN.findall(tool_input_text)
        if branch_issues:
            state.link_issue(branch_issues[-1], timestamp)

    return tuple(edited_paths)


def current_issue(state, switches, timestamp):
    branch_issue, switched_at = branch_issue_at(switches, timestamp)
    if state.issue and state.issue_signal_time >= switched_at:
        return state.issue

    return branch_issue or state.issue or UNASSIGNED


def session_points(events, switches, issue_lookup):
    state = SessionState()
    points = []
    first_signal_index = None
    for event in events:
        timestamp = iso_to_epoch(event["timestamp"])
        content = (event.get("message") or {}).get("content")
        edited_paths = ()
        if event["type"] == "user" and isinstance(content, str):
            apply_user_prompt(state, content, timestamp, issue_lookup)
        if event["type"] == "assistant" and isinstance(content, list):
            edited_paths = apply_tool_calls(state, content, timestamp, issue_lookup)
        is_first_signal = state.issue is not None and first_signal_index is None
        if is_first_signal:
            first_signal_index = len(points)
        points.append(ActivityPoint(timestamp, current_issue(state, switches, timestamp), state.skill, edited_paths))

    return assign_session_start_to_first_issue(points, first_signal_index)


def assign_session_start_to_first_issue(points, first_signal_index):
    if not first_signal_index:
        return points

    first_issue = points[first_signal_index].issue
    session_start = [replace(point, issue=first_issue) for point in points[:first_signal_index]]

    return session_start + points[first_signal_index:]


def subagent_points(events, parent_points):
    if not events or not parent_points:
        return []

    start = iso_to_epoch(events[0]["timestamp"])
    parent_index = max(bisect.bisect_right([point.timestamp for point in parent_points], start) - 1, 0)
    parent = parent_points[parent_index]

    return [ActivityPoint(iso_to_epoch(event["timestamp"]), parent.issue, parent.skill, ()) for event in events]


def collect_points(repo_path, malformed_counter):
    sources = transcript_sources(repo_path)
    if not sources:
        sys.exit(f"No Claude Code transcripts found for {repo_path} under {TRANSCRIPTS_ROOT}")

    issue_lookup = IssueLookup(read_spec_issue_numbers(repo_path), read_pull_request_issues(repo_path))
    points_by_source = []
    for transcripts_dir, switches in sources:
        source_points = collect_dir_points(transcripts_dir, switches, issue_lookup, malformed_counter)
        points_by_source.append(sorted(source_points, key=lambda point: point.timestamp))

    return points_by_source


def collect_dir_points(transcripts_dir, switches, issue_lookup, malformed_counter):
    all_points = []
    for session_file in glob.glob(os.path.join(transcripts_dir, "*.jsonl")):
        main_events = [event for event in load_events(session_file, malformed_counter) if not event.get("isSidechain")]
        points = session_points(main_events, switches, issue_lookup)
        all_points += points
        session_dir = session_file.removesuffix(".jsonl")
        for subagent_file in glob.glob(os.path.join(session_dir, "subagents", "*.jsonl")):
            all_points += subagent_points(load_events(subagent_file, malformed_counter), points)

    return all_points


def classify_phase(point, reviewed_issues, last_fix_phase):
    if point.skill in REVIEW_SKILLS:
        reviewed_issues.add(point.issue)
        return "review"
    if point.skill in PLAN_SKILLS:
        return "plan"
    if point.issue not in reviewed_issues:
        return "implement"
    if point.edited_paths:
        is_spec_only = all("/specs/" in path for path in point.edited_paths)
        last_fix_phase[point.issue] = "fix_spec" if is_spec_only else "fix_code"

    return last_fix_phase.get(point.issue, "fix_code")


def classify_phases_in_time_order(points_by_source):
    reviewed_issues = set()
    last_fix_phase = {}
    all_points = [point for points in points_by_source for point in points]
    all_points.sort(key=lambda point: point.timestamp)

    return {id(point): classify_phase(point, reviewed_issues, last_fix_phase) for point in all_points}


def accumulate_hours(points_by_source, idle_seconds, since_epoch):
    hours = defaultdict(lambda: defaultdict(float))
    active_days = defaultdict(set)
    phase_by_point = classify_phases_in_time_order(points_by_source)
    for points in points_by_source:
        for point, next_point in zip(points, points[1:]):
            phase = phase_by_point[id(point)]
            gap_seconds = next_point.timestamp - point.timestamp
            if gap_seconds > idle_seconds or point.timestamp < since_epoch:
                continue
            hours[point.issue][phase] += gap_seconds / SECONDS_PER_HOUR
            active_days[point.issue].add(datetime.fromtimestamp(point.timestamp).strftime(DATE_FORMAT))

    return hours, active_days


def round_hours(value):
    return round(round(value / ROUNDING_STEP_HOURS) * ROUNDING_STEP_HOURS, 2)


def build_rows(hours, active_days, wanted_issues):
    rows = []
    for issue, phase_hours in hours.items():
        if wanted_issues and issue not in wanted_issues:
            continue
        row = {"issue": issue, "days": sorted(active_days[issue])}
        row.update({phase: round_hours(phase_hours.get(phase, 0.0)) for phase in PHASES})
        row["work_hours"] = round_hours(sum(phase_hours.get(phase, 0.0) for phase in WORK_PHASES))
        row["review_hours"] = round_hours(sum(phase_hours.get(phase, 0.0) for phase in REVIEW_PHASES))
        row["total"] = round(row["work_hours"] + row["review_hours"], 2)
        if row["total"] > 0:
            rows.append(row)

    return sorted(rows, key=issue_sort_key)


def issue_sort_key(row):
    issue_number = int(row["issue"]) if row["issue"].isdigit() else 0

    return row["issue"] == UNASSIGNED, issue_number


def print_table(rows):
    hour_columns = [*PHASES, "work_hours", "review_hours", "total"]
    print("\t".join(["issue", *hour_columns, "days"]))
    for row in rows:
        days = f"{row['days'][0]}..{row['days'][-1]}" if row["days"] else ""
        hour_values = [str(row[column]) for column in hour_columns]
        print("\t".join([row["issue"], *hour_values, days]))


def main():
    arguments = parse_arguments()
    since_epoch = datetime.strptime(arguments.since, DATE_FORMAT).timestamp() if arguments.since else 0.0
    malformed_counter = defaultdict(int)
    points_by_source = collect_points(arguments.repo, malformed_counter)
    hours, active_days = accumulate_hours(points_by_source, arguments.idle_minutes * SECONDS_PER_MINUTE, since_epoch)
    rows = build_rows(hours, active_days, set(arguments.issue))
    if malformed_counter:
        print(f"Skipped {sum(malformed_counter.values())} unreadable transcript lines", file=sys.stderr)

    if arguments.json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
    else:
        print_table(rows)


if __name__ == "__main__":
    main()
