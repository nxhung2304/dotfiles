---
name: report
model: claude-sonnet-5-5
description: Write, rewrite, or tighten any message meant for someone else to read — leader, PM, reviewer, customer, team channel — so it is plain, jargon-light, short but complete, and sized to the scope of the task. Covers bug investigation reports, estimates and task proposals, status updates/recaps, and decision or trade-off asks. Use whenever the user wants to report or explain something to another person ("báo leader", "gửi leader", "nói với leader", "báo cáo", "report", "estimate", "báo estimate", "ước lượng", "đề xuất", "kế hoạch", "tóm tắt gửi team", "status", "recap", "giải thích cho leader hiểu", "nói sao cho dễ hiểu / thuyết phục"), pastes a draft and asks "đủ chưa", "còn thiếu gì", "sửa lại", "ngắn gọn hơn", "dễ hiểu hơn", "ít kỹ thuật hơn", or when a technical discussion ends and the user asks to summarize it for someone else. Adapts structure and length to the task instead of forcing a fixed template.
---

# Report

Turn technical work into a message the reader understands on the first read, can act on without follow-up questions, and finds short. The reader usually does not read the code.

**Language:** match the user's language (default: the draft's or the conversation's language). `lang: en` / `lang: vi` in ARGUMENTS overrides it.

## Core rules (every report type)

1. **Plain language.** Describe what happens in everyday words ("the screen only says 'failed', not what actually went wrong"), not code terms. Any unavoidable technical term gets a few-word explanation the first time. Short sentences, natural tone, like a person talking to a colleague.
2. **Name things by feature, not by code.** Say "login", "payment", "data upload" — not file, class, or function names. Drop counts and ratios unless they change the reader's decision.
3. **Concrete over abstract.** "Most cases aren't handled yet" is vague; "handled: A, B, C — not handled: X, Y, Z" is clear. When the reader can't picture what a phrase refers to, replace it with a short have/lack list in feature terms.
4. **Short but complete.** Every line must answer a question the reader would ask; cut everything else. Prefer labelled one-liners (`Vấn đề:` / `Giải pháp:` / `Rủi ro:`) over paragraphs. Shortening means compressing wording, never dropping an idea the reader needs.
5. **Verified or labelled.** Before writing a claim (feasible / not feasible, root cause, "SDK doesn't support X"), check the code, SDK, or docs. If it can't be checked, write it as a guess. An estimate is always an estimate.
6. **Paste-ready output.** Give the report as one block the user can paste as-is. Notes meant only for the user (sources, file references, which numbers are guesses) go after a `---` separator, in one or two lines. Keep hedging and code references out of the paste-ready block.
7. **Default to the shortest form.** Write only the conclusion and the point the reader must act on. No background, old-logic recap, recommendation or extra questions unless the user asks for them or the reader cannot answer without them.
8. **Never ask what is already decided.** Before including a question, check the spec/decision notes and the conversation; drop any point already confirmed.
9. **Iterate in place.** When the user asks for a change (shorter, clearer, less technical, add X), return the full updated block, not a diff, so it stays paste-ready.

## Step 1 — Identify the type and the scope

Pick the type (a report can mix them, e.g. bug + estimate for the fix):

| Type | The reader wants to know |
|---|---|
| **Bug investigation** | What broke, why, is it fixed, who was affected |
| **Estimate / proposal** | What's wrong, what we'll do, how long, what could go wrong, what they must decide |
| **Status / recap** | Where things stand, what's next, anything blocked |
| **Decision / trade-off ask** | The options, the cost of each, what you recommend, what you need from them |
| **Confirmation ask** | Which behaviour is wanted — the current one or the alternative |

Size it by scope:

| Scope | Signals | Shape |
|---|---|---|
| **Small** | One change, low risk, nothing to decide | 2–5 lines, no headings |
| **Medium** | A few parts, some risk, or one decision | Labelled sections, one line each where possible |
| **Large** | Several steps or systems, real user impact, or several decisions | One block per step, then Total / Recommendation / Confirm |

Infer the type and scope from the conversation. Ask only when it genuinely blocks the report (e.g. unknown whether real users were affected).

## Step 2 — Sections by type (include only what applies)

### Bug investigation

| Section | Include when |
|---|---|
| **Symptom** | Always |
| **Root cause** | Always. With evidence → explain the mechanism in plain words, at most one short code reference as backing. Without evidence → mark as a hypothesis. |
| **Cross-check** | An equivalent system/version exists (another platform, an older version, a similar module). State the actual difference, don't just list both. |
| **Prevention** | Always |
| **Remediation** | The bug already affected real users/data — answer "what happens to users already affected?" |
| **Impact & severity** | Many users, or the reader must set priority |
| **Effort estimate** | A fix must be planned — use the estimate rules below |
| **Open questions** | Something is still uncertain |

If only Symptom + Root cause remain, merge them into one short paragraph.

### Estimate / proposal

One block per step (a single block if the task is small):

- **Vấn đề / Problem** — what exists vs. what's missing, in feature terms (core rule 3).
- **Giải pháp / Solution** — one or two sentences covering the whole idea of the step.
- **Ước lượng / Estimate** — the step total in the heading; one line splitting it into parts in hours (e.g. "code A 2–3h, B 1h, test 2–3h").
- **Rủi ro / Risk** — only real ones; "Thấp" is a valid answer.

Then, once for the whole report:

- **Tổng / Total** — the sum, plus the assumptions behind it: AI-assisted or not, test included, how testing is done.
- **Đề xuất / Recommendation** — which step to do first and why, in one or two sentences. Name the step that alone delivers most of the value, and any step that depends on another.
- **Cần xác nhận / To confirm** — only questions whose answer changes scope or estimate, each with its effect ("if not needed, step 3 drops ~3h").

Estimate rules:
- Split each step into parts with hours so the reader sees where the time goes; a bare "1–1.5 days" is not convincing.
- Separate coding time from testing time. If the user works with an AI assistant, coding shrinks but testing in a real environment doesn't; state which applies.
- Prefer simulated tests (unit tests, mocked state or responses, forced events, emulators, local environments) and keep real-environment runs for what can't be faked. Say so in the total.
- Check the arithmetic: parts sum to each step, steps sum to the total.
- Split steps by the value each delivers, so the reader can approve them one at a time.
- Before claiming something can or can't be done, check the code, SDK, or docs (core rule 5).

### Status / recap

Conclusion first → done → in progress → blocked (and what unblocks it) → next. Add risks only if they affect the plan.

### Decision / trade-off ask

Context in one line → options (a table when there are two or more) with the cost of each → your recommendation and why → exactly what you need from the reader.

### Confirmation ask

Shape, in this order (omit a part only when it doesn't apply):
1. **Addressee + ask** — `@<name>` if given, then who confirms (e.g. "Nhờ chị xác nhận với bên khách hàng:").
2. **Context** — only the rule the reader needs to answer, as a short condition list (e.g. "X only shows On when: - A - B"). No history, no old bug.
3. **Current behaviour** — one sentence, marked as already implemented.
4. **Question** — "<trigger>, thì <current behaviour> như hiện tại, hay <alternative>?" Always offer the current behaviour and one concrete alternative; never an open or yes/no question.

Wording rules:
- Describe user actions with the exact on-screen labels in their original language (e.g. "chọn この機能を使う rồi nhấn 設定する"), and point to a screenshot when one is attached ("như ảnh đính kèm").
- Other keywords: English with the original in parentheses, e.g. "Always (常に許可)"; repeat the original only on first use.
- Several undecided points → number them, each with its own current/alternative question.
- No recommendation, no file/code names, no technical reason unless the user asks.

## Step 3 — Self-check before delivering

Read it as the recipient and fix whatever triggers one of these questions:
- "Cái này là gì?" — a vague phrase → make it concrete (have/lack, feature names).
- "Sao lâu vậy?" — an estimate without a breakdown → add the parts in hours.
- "Rồi làm gì tiếp / anh cần quyết gì?" — missing recommendation or confirm question.
- "Chắc chưa?" — a claim not verified → verify it or mark it as a guess.
- Any file name, function name, or count the reader doesn't need → remove.
- Length doesn't match scope → shorten a small one, add what's missing to a large one.

## Shape examples

**Small bug, root cause clear, nobody affected:**
> Symptom: [X]. Cause: [Y, in plain words]. Fixed in PR #N; no action needed for current users.

**Confirmation ask:**
> @[name]
> Nhờ chị xác nhận với bên Nhật:
>
> Mục Current location (現在地取得) chỉ hiện On (オン) khi đủ 2 điều kiện:
> - Quyền vị trí là Always (常に許可)
> - Người dùng bật On trong app: chọn この機能を使う rồi nhấn 設定する (như ảnh đính kèm)
>
> Khi quyền vị trí chuyển sang Always, app tự bật On (em đã implement). Sau đó nếu người dùng chọn Off trong app (chọn 設定せず使う rồi nhấn 設定する) thì giữ Off (オフ) như hiện tại, hay app tự bật lại On?

**Medium decision ask:**
> We need to pick how to handle [X]. A: keep the current approach — no extra work, but it breaks down at [limit]. B: [change] — 1 day, removes the limit. I recommend B, because [next step] will push past that limit. Need your OK to go with B.

**Large estimate (shape only):**
> **Step 1: [what the reader gets]** (1–1.25 days)
> - Problem: currently saved: A, B. Not saved: X, Y, Z.
> - Solution: [one or two sentences].
> - Estimate: part A 2–3h, part B 1h, part C 2h, simulated test 2–3h.
> - Risk: [one line].
>
> **Step 2 …**
>
> **Total:** 3–3.5 days (AI-assisted, mostly simulated tests, one final run in a real environment).
> **Recommendation:** do all steps in order; merge step 1 first so the team can use it right away.
> **To confirm:** [only questions that change scope or estimate].
