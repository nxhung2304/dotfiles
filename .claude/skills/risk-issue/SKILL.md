---
name: risk-issue
model: claude-opus-5-5
description: Find architectural risks that an issue's spec/plan (implement.md, plan, design note) fails to mention, by checking its decisions against the actual code — concurrency and queue blocking, timeout/cancellation, state divergence between components, silent failures, partial state and retry, contract gaps, competing flows, compatibility and merge order, black-box dependency behaviour, testability, production observability. Works for any project, language or framework. Reports risks only, no fixes. Defaults to Vietnamese output, accepts a `lang` override. Use whenever the user says "risk-issue", asks what risks a spec/plan is missing ("implement.md thiếu rủi ro gì", "còn rủi ro kiến trúc nào", "check rủi ro", "spec này có lỗ hổng gì", "what could go wrong with this plan"), or wants a plan stress-tested against the codebase before coding — even if they don't say "risk" explicitly.
---

# Risk Issue

Purpose: before coding, find the design-level risks a spec does not mention, so the author can decide about them while they are still cheap. This is not a code review of a diff and not a completeness review of the spec's wording — it asks "if we build exactly this, what breaks, and does the spec know?"

Does not write code, does not edit the spec, does not propose fixes unless the user asks. Prints the report in chat only.

**Language:** Vietnamese by default. If ARGUMENTS gives a language (`lang: en`, `en`, `english`), use that. Keep code identifiers, error codes and `file:line` as-is.

## STEP 0: Find the spec

1. If ARGUMENTS contains a path, use it.
2. Otherwise take the issue number from the branch: `git branch --show-current`, regex `#(\d+)`, then `specs/issues/<n>-*/implement.md` (fall back to `plan.md` / `issue.md` in that folder).
3. If nothing is found, ask the user for the path. Do not guess between several candidates.

## STEP 1: Read the spec and everything it links

Read the spec in full, then the docs it links that hold decisions (investigation notes, issue, sibling specs for other platforms). Decisions often live outside the spec itself — e.g. an "agreed"/"Đã chốt" list in an investigation file.

Write down for yourself:
- **Decisions** — every concrete design choice (D1, D2, …): what runs where, what waits for what, what happens on error/timeout, what is removed, what the contract with callers is.
- **Already-listed risks** — everything in the spec's risk / open-questions / test-risk sections.

A risk counts as already listed only if the spec states both the cause **and** its consequence. If the spec names the cause but stops short of the consequence that matters (e.g. "on timeout, the caller gets TIMEOUT" without noticing the queue stays blocked), it is still missing — report it and say which part the spec already covers.

## STEP 2: Read the code the design touches

Read the real code, not just the spec's description of it — specs often describe code from memory and line numbers drift. Cover:
- the functions/classes the spec changes,
- their callers and every other entry point into the same resource (other methods, delegates/callbacks, background jobs, lifecycle hooks),
- the concurrency model actually in force (actors, threads, executors, event loop, locks, isolation annotations),
- existing guards elsewhere in the same component (e.g. "reject while syncing") that the new flow does or does not share.

If part of the system is in another repo or not readable, say so and treat risks there as "possible", not confirmed.

## STEP 3: Walk the checklist

Check every category. Each one must end with exactly one verdict:
- **Missing** — a confirmed risk the spec does not cover (needs evidence).
- **Possible** — suspected, cannot verify (state confidence + what would confirm it).
- **Not a risk** — checked and safe (state the evidence).
- **Not applicable** — the design has nothing this category could apply to (one-line reason).

Never invent or stretch a finding to fill a category. "Not a risk" and "Not applicable" are valid, expected outcomes.

1. **Concurrency, ordering, queues, thread model** — can two calls overlap? Is there a serial queue/chain, and if one item never finishes, does everything behind it wait forever? Is ordering last-writer-wins and is that the intended outcome? Which thread/actor/event loop does each wait happen on, and if that is the main/UI thread, what does the user see (frozen UI, ANR, dropped input)?
2. **Timeout and cancellation** — when the timeout fires, does the underlying operation actually stop, or keep running? If it keeps running, what state does it leave, and who learns about it? Does the timeout include time spent waiting in a queue? Can the timeout mechanism itself block (e.g. a structured task group that waits for children it cannot cancel)?
3. **State divergence** — after success, failure, timeout or late completion, do all parties (UI/app, plugin/service, device/server, persisted flags) agree on the state? Is there any in-memory flag that can be stale after restart?
4. **Silent failure** — any path where an error is only logged, swallowed, or turned into a default value, so the caller believes it succeeded?
5. **Partial state and retry** — if a multi-step operation fails midway, what state is left? Is retrying safe (idempotent) for every external party it touches (device, server, payment, notification), so a retry never applies an action twice? Does the retry path actually re-send what is needed?
6. **Contract completeness** — does every branch produce exactly one result (never zero, never two)? Does every failure have a defined error code, including failures of verification/read-back steps? Do all platforms/implementations honour the same contract? Do the callers keep that information, or does a wrapper on the caller side catch the error and rethrow it as a plain string/default, losing the code?
7. **Competing flows** — other features touching the same resource (sync, cleanup, delete, pairing, background refresh) without the same guard or queue.
8. **Compatibility and rollout** — callers on older versions, platforms implemented at different times, merge order between repos, behaviour change for existing users, data already stored in an old format (persisted flags, DB rows, files) and the deploy order between data migration and code.
9. **Black-box dependency behaviour** — does the design rely on behaviour of a closed SDK, library, hardware or external service that the code cannot show (does it honour cancellation, can it hang, is a repeated call safe, how long does it take)? Name the cheapest experiment that would settle it (temporary probe code, a debug button, forced state) — such results often change the design.
10. **Testability and environment** — which parts of the design cannot currently be built, run or tested (platform not building, missing device/account, no staging)? Shipping them untested is a risk in itself, and may force a scope split.
11. **Observability in production** — if this fails on a user's device or in production, do the logs that will actually exist there (release build, log level, persisted logs) show which branch ran and why?

## STEP 4: Combine decisions in pairs

This step is required because the most serious risks usually come from two individually reasonable decisions interacting, and a category checklist alone will not surface them. Example of the shape: "on timeout, do not cancel the operation" + "each command waits for the previous one" ⇒ one hung operation blocks every later command until restart.

For each pair of decisions that share a resource, a queue, a timeline or a caller, ask: if both hold at once, what is the worst realistic sequence of events? You do not need to enumerate every pair mechanically — focus on pairs that interact — but do this deliberately rather than relying on the checklist.

## STEP 5: Verify each finding

- **Confirmed** risks need evidence: a `file:line` in the code, or a quote of the spec decision(s) that produce it. Re-check line numbers against the current code.
- If a risk depends on behaviour you cannot verify (third-party SDK, hardware, another repo), put it under "possible" with a confidence level and what would confirm it.
- Record a verdict for every category, including the ones that turned out safe or not applicable, with the evidence or reason. This tells the reader what has been ruled out.
- For each Missing or Possible finding, note how it can be tested, and mark it when testing needs simulation code (forced error, artificial delay, fake hang). These tests are a large hidden part of the effort, so the reader needs to see them to estimate.
- Drop anything that is really an implementation nit, naming or style issue. Those belong to code review.

## STEP 6: Report

Lead with the answer. One short paragraph per finding: what happens, why (which decisions / code), and — if the spec partly covers it — what part is already there. Order by severity: permanent breakage or data/state corruption first, then wrong state visible to the user, then degraded behaviour.

Use this structure (translate the headings to the output language):

```
**Missing from the spec**
1. **<short title>** (most severe). <what happens>. <cause: decisions Dx + Dy / file:line>. <what the spec already says, if anything>. Test: <how; "needs simulation" if so>.
2. ...

**Possible risks (guess)**
- **<short title>** — confidence <low/medium/high>. <why suspected, file:line>. <what would confirm it>. Test: <how; "needs simulation" if so>.

**Checked: not a risk / not applicable**
- **<category>**: not a risk — <why it is safe, file:line>.
- **<category>**: not applicable — <one-line reason>.
```

Every one of the 11 categories must appear in the report under exactly one of these sections; one line each for the last section. If nothing is missing, say so plainly and still list every category checked. Do not end with offers to fix, edit the spec, or do more work — the user decides next steps.
