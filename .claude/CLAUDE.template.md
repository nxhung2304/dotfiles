# Claude Code Project Setup

> **Copy file này vào project root** và custom theo nhu cầu.

---

## Quick Commands

| Command | Description |
|---------|-------------|
| `/implement #[issue]` | Implement issue từ `specs/story/[issue]-*.md` |
| `/review-code #[issue]` | Review code cho issue đã implement |
| `/review-specs` | Review specification file |
| `/generate-issues` | Tạo issues từ `specs/story.md` |

---

## Subagent Usage Strategy

**Main agent KHÔNG glob/read toàn bộ `code-rules/` hoặc `specs/rules/`** để save tokens.

Luôn dùng **rule-lookup subagent** để tra cứu rules theo task context:
- Core rules (core.md) → always loaded
- Language-specific rules → load on-demand
- Project rules (specs/rules/) → load khi cần

---

## Project Structure

```
project-root/
├── CLAUDE.md              ← File này
├── specs/
│   ├── story/            ← Issue specifications
│   ├── rules/            ← Project-specific rules
│   └── comments/         ← Review feedback
├── lib/                  ← Flutter/Dart source
└── test/                 ← Tests
```

---

## Token Saving Best Practices

1. **Use rule-lookup for targeted rules** → Don't glob entire `code-rules/`
2. **Specify exact files** → Don't use broad patterns like `lib/**/*.dart`
3. **Limit scope** → Focus on specific feature/issue at a time
4. **Review incrementally** → Review per issue, not entire codebase

---

## Workflow Example

### Implementing Issue #12

```bash
# User calls:
/implement 12

# Flow:
1. implement-prepare → git pull, create branch, validate approved
2. implement-code → do checklist, call rule-lookup per item
3. implement-quality → flutter analyze, flutter test, fix errors
4. implement-finalize → commit, push, create PR
```

### Reviewing Code

```bash
# User calls:
/review-code 12

# Flow:
1. Read spec: specs/story/12-*.md
2. Call rule-lookup → get relevant rules ONLY
3. Scan changed files via git diff
4. Review against supplied rules
5. Write feedback to specs/comments/12-code-review.md
```

---

## Rules Locations

| Category | Path | When to Load |
|----------|------|--------------|
| Core | `~/.claude/code-rules/core.md` | Always |
| General | `~/.claude/code-rules/general/*` | Via rule-lookup |
| Project | `specs/rules/*` | Via rule-lookup |

---

## Subagent Reference

| Agent | Purpose | Tools |
|-------|---------|-------|
| rule-lookup | Tra cứu rules theo task context | Read, Grep |
| code-reviewer | Review code (read-only) | Read, Grep, Glob, git diff |
| error-fixer | Fix flutter analyze/test errors | Read, Edit, Write, flutter commands |
| design-checker | Sync colors/tokens from HTML specs | Read, Grep, Edit, Write |

---

## Customization

Edit phần sau theo project của bạn:

- **Project type**: Flutter/Dart, Rails, Node.js...
- **Branch pattern**: `feature/{name}-#{number}-{slug}` hoặc custom
- **Specs location**: `specs/story/` hoặc `docs/specs/`
- **Rules location**: `specs/rules/` hoặc `.claude-rules/`

---

## Hooks (Optional)

Add to `.claude/settings.json` cho notifications:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "terminal-notifier -title 'Claude Code' -message 'Task done' -sound default"
      }]
    }]
  }
}
```

---

## Troubleshooting

**Issue**: "Rules not found"
- **Fix**: Check `specs/rules/` exists, run `ls specs/rules/`

**Issue**: "High token usage"
- **Fix**: Ensure using `rule-lookup`, not globbing entire `code-rules/`

**Issue**: "Branch not found"
- **Fix**: Check branch pattern matches your naming convention
