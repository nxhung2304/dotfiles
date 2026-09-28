---
name: bug-report-writer
description: Rewrite or refine a bug investigation report / technical report before sending to a leader, reviewer, or team channel. Use this whenever the user drafts or pastes a bug report, investigation summary, root-cause analysis, or "báo cáo điều tra bug" and wants it improved, checked for gaps, or restructured before reporting. Also trigger when the user asks "báo cáo này đã đủ chưa", "còn thiếu gì không", "sửa lại báo cáo", or wants to prepare a report to leader/PM/reviewer about a technical issue. The skill adapts the number of sections to the size/severity of the issue — small issues get a short report, large/high-impact issues get a fuller report — rather than forcing every report into a fixed template.
---

# Bug Report Writer

Help write or rewrite a bug/technical investigation report before it's sent to a leader, reviewer, or team, so the report is deep enough that the reader doesn't have to ask basic follow-up questions (what the root cause is based on, what was cross-checked, how the consequences were handled).

**Core principle: do NOT force a rigid 6-7 section template onto every report.** The number of sections depends on the size/severity of the issue. A small, isolated bug that hasn't affected anyone needs only 3-4 lines. A bug affecting real user data across multiple systems needs the full set of sections.

**Language:**
- Default: match the language of the input report/draft
- If ARGUMENTS specifies a language (e.g. `lang: en`, `lang: vi`), write the output in that language instead

## Process

### Step 1 — Assess the scope of the issue

Before writing, ask yourself (or the user, if unclear):

1. **Is there concrete evidence of the root cause yet**, or is it still a guess?
2. **Is there an equivalent system/version to cross-check against** (e.g. iOS vs Android, old version vs new, Cordova vs Flutter)?
3. **Has the issue already affected real users/data**, or was it only caught during dev/test?
4. **Severity/scope of impact** — one user or many, does it cause crashes/data loss/cost?
5. **Is there anything the writer isn't sure about** that should be flagged as a hypothesis rather than a conclusion?

The answers to these 5 questions determine how many sections the report needs in step 2. If the user already provided enough information in the draft, infer the answers instead of asking again. Only ask when it genuinely can't be inferred (e.g. unclear whether real users were affected yet).

### Step 2 — Choose the sections needed (conditional checklist)

| Section | Always included? | Condition to add |
|---|---|---|
| **Symptom** | Always | — |
| **Root cause** | Always | If code evidence exists → cite it concretely (file/function/logic). If uncertain → mark clearly as a hypothesis, don't state it as a firm conclusion. |
| **Cross-check with related systems** | Only if an equivalent system/version exists | Skip if there's nothing to compare against. |
| **Solution — prevention** | Always | — |
| **Solution — remediation** | Only if the issue has already affected real data/users | Skip if the bug never ran in production or left no lasting consequence. |
| **Impact & Severity** | Only if the issue is significant enough (affects many users, or the leader needs to prioritize P0/P1/P2) | Skip for small, isolated bugs. |
| **Effort estimate** | Only if a fix needs to be planned (a code fix is attached) | Skip if the report is just informational, with no fix direction yet. |
| **Open questions** | Only if something is still uncertain | Skip this section if everything is clear and backed by evidence. |

**Shortening rule:** if applying the table above leaves only 2 sections (Symptom + Root cause), merge them into one short paragraph instead of separate headings — a small report should read as one flowing block, no need for heavy headings.

**Expansion rule:** for a large issue (many users, data loss, multiple teams/systems involved), add extra sections beyond the table if the context demands it (e.g. security risk, compliance impact) — the table above is a floor, not a hard limit.

### Step 3 — Write/rewrite the report

- For **Root cause**: never write "this is a bug because of X" without citing the actual code or logic. If the user provides a related issue/PR link, cross-check directly: "where issue #X was fixed, and why the currently broken spot falls outside that fix's scope."
- For **Cross-check**: state the similarities/differences explicitly, don't just list the two systems.
- For **Remediation**: always answer "so what happens to users who were already affected?" — this is nearly always the leader/PM's first question if the bug already ran in production.
- Keep the tone concise, and preserve the exact technical terms used in the original draft (don't rename variables, functions, or issue names).
- Match the output language to the source draft's language by default, unless `lang` overrides it.

### Step 4 — Final check before delivering

Check yourself against 3 questions:
- Is there any conclusion stated without supporting evidence? → if so, downgrade it to a hypothesis or add evidence.
- Is there an "obvious" question the reader (leader) would ask that the report doesn't answer? (e.g. "what about existing users", "why isn't Android affected")
- Does the number of sections match the scope of the issue? (a small report that's too long, or a large report that's too thin, both need rework)

## Length examples by scope

**Small bug, root cause already clear, hasn't affected anyone:**
> Symptom: [X]. Root cause: [code Y causing Z]. Already fixed in PR #N, no further action needed for current users.

(3 sentences, no headings needed.)

**Large bug affecting real user data, with a system to cross-check against:**
> Full set of sections: Symptom → Root cause (with code evidence) → Cross-check (e.g. Cordova vs Flutter) → Prevention → Remediation → Effort estimate → Open questions.
