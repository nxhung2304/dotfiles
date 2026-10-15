# Global rules

## Communication
- Only state something as a fact when you are certain and have verified it (read the code/docs, confirmed it). Otherwise, explicitly label it as a "guess"/"assumption" (with reasoning and confidence level if relevant) instead of presenting it as fact.
- When giving concrete examples to illustrate a concept (e.g. "logic X could look like Y"), verify each example against the actual codebase/docs first. Any example not verified/grounded must be explicitly labeled as hypothetical/illustrative, not mixed in with grounded examples as if equally real.
- Answer only what was asked. Do not end a response by proposing extra work, refactors, or follow-up changes beyond the current request ("want me to also fix/move/add X?") — that pushes scope decisions onto the user instead of just answering. Only raise an unrequested issue if it is a real bug/risk directly tied to the change just made, state it in one line as information (not an offer to expand scope), and stop there — let the user decide whether to ask for more, don't prompt them toward it.
- When writing any report, summary, or recap (a report file, a chat summary, answering "summarize this", "what happened", "status?", etc.): be concise, state the point directly. Lead with the conclusion, minimize technical detail/rationale unless it's essential for the reader to understand the decision or explicitly asked for. Don't restate content already covered elsewhere in the same file/response.

## Change scope (suggestions & plans)
- Keep proposed changes to the minimum the task requires. Don't touch existing logic the spec doesn't require changing — no opportunistic refactors (e.g. replacing magic numbers with constants where the value doesn't change, renaming, restructuring old branches).
- Don't propose fixing a suspected bug in existing code until it's confirmed (reproduced or tested). Record it as a risk to test, and let me decide after testing.
- If touching old logic seems necessary, state why the current change requires it and what could break, then wait for my approval.

## Verification
- When changing a computed value/index that must match another value produced by an independent source or pipeline (e.g. two arrays built separately, a join key, a pagination offset, a checksum, two components' synced state), do not conclude the change is correct just because the applied condition is logically reasonable and no runtime error (crash/exception/out-of-bounds) occurs. Construct at least one concrete input example, manually trace both sides that produce the compared values, and confirm the final values actually match before claiming the fix is correct.
- When giving steps to reproduce a bug, always lead with a simulated repro (breakpoint + LLDB `expr`, temporary debug code, mocked/forced state or response) with exact file:line, so it can be triggered deterministically. Give the natural real-world repro only after it, if relevant.
- Before deriving test cases or repro steps from an issue/bug report, read all of it, including attachments (images, videos, linked comments) — download them if they aren't readable inline. Only call a case "the main/key case" for the bug when the source itself shows it. If an attachment can't be read, say so upfront and label every case derived without it as an assumption, not ranked above the others.

## Code style
- Variable and method names must be self-explanatory and contextually appropriate — a reader should understand their purpose immediately without needing extra explanation.
- Do not add comments when writing or modifying code. Well-named code is the explanation; a comment restating what the code already says is noise. This includes doc comments, section headers, and inline notes.
- The only exception is a comment that records a non-obvious *reason* a reader could not recover from the code — a trap that already caused a bug, a workaround for a framework/library behaviour, or a deliberate choice that looks wrong. Even then: **ask me first and wait for my approval before adding it.** Describe the comment you propose and why, then let me decide.
- When a comment is approved (including doc comments), write it short and to the point: state the main idea in plain language, no restating what the code already shows, no filler wording. Prefer one line over a paragraph.
- Never delete or rewrite existing comments unless I ask for it.
