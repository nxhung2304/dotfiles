---
name: ai-profile
description: Learns how the user works with AI from their own prompts in past Claude Code sessions (what they correct, approve, reject, decide, how they phrase requests) and keeps a local profile at ~/.ai-metrics/profile/profile.json plus a readable profile.md. Proposes traits and rules only; the user approves each one before the orchestrator may use it. Use when the user says "ai-profile", "học hành vi của tôi", "cập nhật profile", "viết rule mô tả tôi", or after several sessions of new data.
allowed-tools: Read, Write, Bash(python3:*), Bash(mkdir:*), Bash(ls:*)
---

# AI profile

Build and maintain a profile of the user's working behaviour from real evidence. It feeds the `ai-orchestrate` skill, which acts on the user's behalf while they are away. A wrong trait makes the orchestrator decide wrongly, so every trait needs a quote and the user's approval.

**Language:** write `rule` and `profile.md` in Vietnamese unless ARGUMENTS say `lang: en`.

**Privacy:** transcripts contain project code and data. Read them locally only. Never send their content to any external tool, MCP server or web service. Never put code, secrets, tokens or personal data in the profile.

## Files

- `~/.ai-metrics/profile/profile.json` — source of truth (schema below)
- `~/.ai-metrics/profile/profile.md` — human-readable view, regenerated from `profile.json` after each run

```json
{
  "updated": "YYYY-MM-DD",
  "analyzed_until": "YYYY-MM-DD",
  "traits": [
    {
      "id": "short-kebab-id",
      "category": "decision-style | review-habits | communication | risk-tolerance | workflow",
      "rule": "one sentence an agent can follow, e.g. what to do when X",
      "evidence": [{"quote": "verbatim user line", "source": "transcript path + time"}],
      "occurrences": 3,
      "contradicted_by": [],
      "status": "proposed | approved | rejected",
      "first_seen": "YYYY-MM-DD",
      "last_seen": "YYYY-MM-DD"
    }
  ]
}
```

## Steps

1. Load the existing `profile.json` if it exists (create `~/.ai-metrics/profile/` if needed). Keep every trait's `status` exactly as it is. Never change a status to `approved` yourself.

2. Export the data since `analyzed_until` (first run: the last 4 weeks; ARGUMENTS may pass `weeks: N`):
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_report.py --days <N> --json ~/.ai-metrics/profile/input.json
   ```
   Read `input.json` for `tasks[].sessions[].transcript` and `cwd`.

3. Condense the transcripts before reading them (never read raw `.jsonl`):
   ```bash
   python3 ~/dotfiles/scripts/ai-metrics/ai_transcript.py <transcript paths...>
   ```
   Ignore sessions that used `ai-score`, `ai-improve`, `ai-profile` or `ai-orchestrate`, or whose work is building `~/dotfiles/scripts/ai-metrics/`.

4. Look only at what the user wrote and did, not at what the AI wrote. Signals worth extracting:
   - corrections ("sai", "làm lại", "không phải") and what the AI had just done
   - approvals and rejections of a plan, option or diff, and the reason given
   - decisions the user made when offered choices (which option, how fast, how much detail)
   - recurring requests and constraints they restate in several sessions
   - how they react to long output, questions, or the AI acting without asking
   - what they never delegate (e.g. always want to see the plan before code)

5. Turn signals into traits:
   - A trait needs at least 2 independent occurrences (different sessions) and 1 verbatim quote. One occurrence: record it with `occurrences: 1` and `status: proposed`, flagged as weak in `profile.md`.
   - If new evidence contradicts an existing trait, add it to `contradicted_by` and do not delete the trait. The user decides.
   - A trait with `status: rejected` is never proposed again. Do not recreate it under another id.
   - Describe behaviour, not personality labels. Prefer "wants to see a plan before any code is written" over "careful person".
   - `rule` is written so an agent acting for the user can follow it without more context.

6. Write `profile.json`, set `analyzed_until` to today, then regenerate `profile.md`: approved traits first (the rules the orchestrator will use), then proposed traits with their evidence, then rejected ids only as a list.

7. Reply with: the number of new, strengthened and contradicted traits, and the proposed traits that need approval (id, rule, one quote each). Ask the user to approve or reject by id. When they answer, update only those statuses.

## Rules

- Fewer than 3 sessions of data: say the profile is not reliable yet and propose nothing above `occurrences: 1`.
- This profile describes how the user works so the orchestrator can match it. It is not a score. Do not judge or rank the user.
- Do not infer traits from sparse or single-session behaviour and present them as established.
