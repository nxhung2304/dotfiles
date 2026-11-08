#!/usr/bin/env python3
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

WHITELISTED_PROJECTS = []

RIGHTS_ROOT = Path.home() / "Dev" / "rights"
PROTECTED_BRANCHES = {"main", "master", "develop"}
ALL_BRANCHES = "<all branches>"
ALLOW_EXIT_CODE = 0
BLOCK_EXIT_CODE = 2
GIT_TIMEOUT_SECONDS = 2

SHELL_OPERATOR_CHARS = set("();<>|&")
COMMAND_PREFIXES = {"command", "sudo", "env"}
ENV_ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
UNPARSABLE_REMOTE_WRITE_RE = re.compile(r"\bgit\b[^\n]*\bpush\b|\bgh\s+(pr|issue|api)\b")
GIT_OPTIONS_WITH_VALUE = {"-c", "--git-dir", "--work-tree", "--namespace"}
PUSH_OPTIONS_WITH_VALUE = {"-o", "--push-option", "--repo", "--receive-pack", "--exec"}
PUSH_EVERYTHING_FLAGS = {"--all", "--mirror", "--branches"}

GH_ALLOWED_ACTIONS = {
    "pr": {"create", "edit", "comment", "close", "reopen", "ready"},
    "issue": {"create", "edit", "comment", "close", "reopen"},
}
GH_WRITE_ACTIONS = {
    "pr": GH_ALLOWED_ACTIONS["pr"] | {"merge", "review", "lock", "unlock", "update-branch"},
    "issue": GH_ALLOWED_ACTIONS["issue"] | {"delete", "transfer", "lock", "unlock", "pin", "unpin", "develop"},
}
GH_REPO_FLAGS = {"-R", "--repo"}
GH_API_METHOD_FLAGS = {"-X", "--method"}
GH_API_SHORT_METHOD_PREFIX = "-X"
GH_API_WRITE_METHODS = {"POST", "PUT", "PATCH", "DELETE"}
GH_API_FIELD_FLAGS = {"-f", "-F", "--field", "--raw-field", "--input"}
GH_API_FIELD_FLAG_PREFIXES = ("--field=", "--raw-field=", "--input=")
GH_API_REPO_RE = re.compile(r"repos/[^/]+/([^/?\s]+)")

GITHUB_MCP_TOOL_RE = re.compile(r"^mcp__.*github.*__(?P<action>\w+)$", re.IGNORECASE)
GITHUB_MCP_READ_RE = re.compile(r"^(get_|list_|search_)|_read$|^actions_(get|list)$|^run_secret_scanning$")
GITHUB_MCP_BRANCH_WRITES = {"push_files", "create_or_update_file", "delete_file"}
GITHUB_MCP_ALLOWED_WRITES = GITHUB_MCP_BRANCH_WRITES | {
    "create_branch",
    "create_pull_request",
    "update_pull_request",
    "update_pull_request_branch",
    "issue_write",
    "sub_issue_write",
    "add_issue_comment",
    "update_issue_comment",
    "add_reply_to_pull_request_comment",
    "request_copilot_review",
}


class RemoteWriteBlocked(Exception):
    pass


def resolve_path(path_text, base_dir):
    return (Path(base_dir) / Path(path_text).expanduser()).resolve()


def has_value_after(args, index):
    return index + 1 < len(args)


def find_rights_project_by_path(path):
    try:
        relative = Path(path).expanduser().resolve().relative_to(RIGHTS_ROOT.resolve())
    except ValueError:
        return None

    return relative.parts[0] if relative.parts else None


def find_rights_project_by_repo_name(repo_name):
    candidate = RIGHTS_ROOT / repo_name.split("/")[-1]

    return candidate.name if candidate.is_dir() else None


def find_target_project(repo_name, working_dir):
    if repo_name:
        return find_rights_project_by_repo_name(repo_name)

    return find_rights_project_by_path(working_dir)


def require_whitelisted(project, action):
    if project in WHITELISTED_PROJECTS:
        return

    raise RemoteWriteBlocked(
        f"'{action}' is blocked for {RIGHTS_ROOT / project}: the project is not in WHITELISTED_PROJECTS "
        f"of {Path(__file__).name}. Write the content to a file and give the user the command to run."
    )


def require_unprotected_branches(project, target_branches, protected_branches):
    if ALL_BRANCHES in target_branches:
        raise RemoteWriteBlocked(
            f"Pushing all branches is blocked for {project}: push one feature branch and open a PR."
        )

    protected_targets = sorted(set(target_branches) & protected_branches)
    if protected_targets:
        raise RemoteWriteBlocked(
            f"Direct push to {', '.join(protected_targets)} is blocked for {project}: "
            "push a feature branch and open a PR."
        )


def run_git(repo_path, *args):
    result = subprocess.run(
        ["git", "-C", str(repo_path), *args], capture_output=True, text=True, timeout=GIT_TIMEOUT_SECONDS
    )

    return result.stdout.strip() if result.returncode == 0 else ""


def load_protected_branches(repo_path):
    default_ref = run_git(repo_path, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    default_branch = default_ref.split("/", 1)[-1] if default_ref else None

    return PROTECTED_BRANCHES | ({default_branch} if default_branch else set())


def read_current_branch(repo_path):
    branch = run_git(repo_path, "rev-parse", "--abbrev-ref", "HEAD")
    is_detached_or_unknown = not branch or branch == "HEAD"
    if is_detached_or_unknown:
        raise RemoteWriteBlocked(f"Cannot determine the current branch in {repo_path}; push blocked to be safe.")

    return branch


def read_push_branch(repo_path):
    push_ref = run_git(repo_path, "rev-parse", "--abbrev-ref", "@{push}")

    return push_ref.split("/", 1)[-1] if push_ref else read_current_branch(repo_path)


def parse_refspec_destination(refspec, repo_path):
    destination = refspec.lstrip("+").split(":")[-1]
    if destination in ("", "HEAD"):
        return read_current_branch(repo_path)

    return destination.removeprefix("refs/heads/")


def collect_push_target_branches(push_args, repo_path):
    positional_args = []
    should_skip_option_value = False
    for arg in push_args:
        if should_skip_option_value:
            should_skip_option_value = False
        elif arg in PUSH_EVERYTHING_FLAGS:
            return [ALL_BRANCHES]
        elif arg in PUSH_OPTIONS_WITH_VALUE:
            should_skip_option_value = True
        elif not arg.startswith("-"):
            positional_args.append(arg)

    refspecs = positional_args[1:]
    if not refspecs:
        return [read_push_branch(repo_path)]

    return [parse_refspec_destination(refspec, repo_path) for refspec in refspecs]


def check_git_command(args, working_dir):
    repo_path, index = working_dir, 0
    while index < len(args) and args[index].startswith("-"):
        is_directory_option = args[index] == "-C" and has_value_after(args, index)
        if is_directory_option:
            repo_path = resolve_path(args[index + 1], repo_path)
            index += 2
        else:
            index += 2 if args[index] in GIT_OPTIONS_WITH_VALUE else 1

    is_push = index < len(args) and args[index] == "push"
    if not is_push:
        return

    project = find_rights_project_by_path(repo_path)
    if project is None:
        return

    require_whitelisted(project, "git push")
    target_branches = collect_push_target_branches(args[index + 1 :], repo_path)
    require_unprotected_branches(project, target_branches, load_protected_branches(repo_path))


def read_gh_repo_flag(args):
    for index, arg in enumerate(args):
        is_repo_flag_with_value = arg in GH_REPO_FLAGS and has_value_after(args, index)
        if is_repo_flag_with_value:
            return args[index + 1]
        if arg.startswith("--repo="):
            return arg.split("=", 1)[1]

    return None


def read_gh_api_method(args):
    for index, arg in enumerate(args):
        is_method_flag_with_value = arg in GH_API_METHOD_FLAGS and has_value_after(args, index)
        is_joined_short_method = arg.startswith(GH_API_SHORT_METHOD_PREFIX) and arg != GH_API_SHORT_METHOD_PREFIX
        if is_method_flag_with_value:
            return args[index + 1]
        if arg.startswith("--method="):
            return arg.split("=", 1)[1]
        if is_joined_short_method:
            return arg.removeprefix(GH_API_SHORT_METHOD_PREFIX)

    return None


def is_gh_api_write(args):
    method = read_gh_api_method(args)
    if method:
        return method.upper() in GH_API_WRITE_METHODS

    for arg in args:
        is_field_flag = arg in GH_API_FIELD_FLAGS or arg.startswith(GH_API_FIELD_FLAG_PREFIXES)
        if is_field_flag:
            return True

    return False


def find_gh_api_endpoint_repo(args):
    for arg in args:
        repo_match = GH_API_REPO_RE.search(arg)
        is_concrete_repo = repo_match is not None and not repo_match.group(1).startswith("{")
        if is_concrete_repo:
            return repo_match.group(1)

    return None


def check_gh_api(args, working_dir):
    if not is_gh_api_write(args):
        return

    repo_name = find_gh_api_endpoint_repo(args) or read_gh_repo_flag(args)
    project = find_target_project(repo_name, working_dir)
    if project is not None:
        raise RemoteWriteBlocked(
            f"'gh api' writes are blocked for {project}: use 'gh pr' / 'gh issue' or ask the user."
        )


def check_gh_command(args, working_dir):
    if not args:
        return

    group = args[0]
    if group == "api":
        check_gh_api(args[1:], working_dir)
        return

    action = args[1] if len(args) > 1 else ""
    if action not in GH_WRITE_ACTIONS.get(group, set()):
        return

    project = find_target_project(read_gh_repo_flag(args), working_dir)
    if project is None:
        return

    require_whitelisted(project, f"gh {group} {action}")
    if action not in GH_ALLOWED_ACTIONS[group]:
        raise RemoteWriteBlocked(f"'gh {group} {action}' is never allowed for {project}: ask the user to do it.")


def split_shell_segments(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    segments, current_segment = [], []
    for token in lexer:
        is_shell_operator = bool(token) and set(token) <= SHELL_OPERATOR_CHARS
        if is_shell_operator:
            segments.append(current_segment)
            current_segment = []
        else:
            current_segment.append(token)

    segments.append(current_segment)

    return [segment for segment in segments if segment]


def strip_command_prefix(tokens):
    index = 0
    while index < len(tokens):
        is_prefix_token = ENV_ASSIGNMENT_RE.match(tokens[index]) or tokens[index] in COMMAND_PREFIXES
        if not is_prefix_token:
            break
        index += 1

    return tokens[index:]


def check_unparsable_command(command, working_dir):
    is_in_rights_dir = find_rights_project_by_path(working_dir) is not None
    is_rights_related = is_in_rights_dir or str(RIGHTS_ROOT) in command
    looks_like_remote_write = UNPARSABLE_REMOTE_WRITE_RE.search(command) is not None
    if is_rights_related and looks_like_remote_write:
        raise RemoteWriteBlocked(
            "Could not parse this command that looks like a remote write in a rights repo; blocked."
        )


def check_bash_command(command, working_dir):
    try:
        segments = split_shell_segments(command)
    except ValueError:
        check_unparsable_command(command, working_dir)
        return

    for segment in segments:
        tokens = strip_command_prefix(segment)
        if not tokens:
            continue

        program, args = tokens[0], tokens[1:]
        if program == "cd" and args:
            working_dir = resolve_path(args[0], working_dir)
        elif program == "git":
            check_git_command(args, working_dir)
        elif program == "gh":
            check_gh_command(args, working_dir)


def check_github_mcp_tool(action, tool_input, working_dir):
    if GITHUB_MCP_READ_RE.search(action):
        return

    project = find_target_project(tool_input.get("repo"), working_dir)
    if project is None:
        return

    require_whitelisted(project, action)
    if action not in GITHUB_MCP_ALLOWED_WRITES:
        raise RemoteWriteBlocked(f"'{action}' is never allowed for {project}: ask the user to do it.")

    if action not in GITHUB_MCP_BRANCH_WRITES:
        return

    branch = tool_input.get("branch")
    if not branch:
        raise RemoteWriteBlocked(f"'{action}' on {project} needs an explicit feature branch.")

    require_unprotected_branches(project, [branch], load_protected_branches(RIGHTS_ROOT / project))


def check_tool_call(hook_input):
    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input") or {}
    working_dir = Path(hook_input.get("cwd") or Path.cwd())
    if tool_name == "Bash":
        check_bash_command(tool_input.get("command", ""), working_dir)
        return

    mcp_match = GITHUB_MCP_TOOL_RE.match(tool_name)
    if mcp_match:
        check_github_mcp_tool(mcp_match.group("action"), tool_input, working_dir)


def main():
    try:
        check_tool_call(json.load(sys.stdin))
    except RemoteWriteBlocked as blocked:
        print(blocked, file=sys.stderr)
        sys.exit(BLOCK_EXIT_CODE)
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        print(f"guard_remote_write could not check this call ({error}); blocked to be safe.", file=sys.stderr)
        sys.exit(BLOCK_EXIT_CODE)

    sys.exit(ALLOW_EXIT_CODE)


if __name__ == "__main__":
    main()
