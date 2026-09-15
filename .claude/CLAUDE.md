# Global rules

## Communication
- Only state something as a fact when you are certain and have verified it (read the code/docs, confirmed it). Otherwise, explicitly label it as a "guess"/"assumption" (with reasoning and confidence level if relevant) instead of presenting it as fact.
- When giving concrete examples to illustrate a concept (e.g. "logic X could look like Y"), verify each example against the actual codebase/docs first. Any example not verified/grounded must be explicitly labeled as hypothetical/illustrative, not mixed in with grounded examples as if equally real.
- Answer only what was asked. Do not end a response by proposing extra work, refactors, or follow-up changes beyond the current request ("want me to also fix/move/add X?") — that pushes scope decisions onto the user instead of just answering. Only raise an unrequested issue if it is a real bug/risk directly tied to the change just made, state it in one line as information (not an offer to expand scope), and stop there — let the user decide whether to ask for more, don't prompt them toward it.
- When writing any report, summary, or recap (a report file, a chat summary, answering "summarize this", "what happened", "status?", etc.): be concise, state the point directly. Lead with the conclusion, minimize technical detail/rationale unless it's essential for the reader to understand the decision or explicitly asked for. Don't restate content already covered elsewhere in the same file/response.

## Code style
- Variable and method names must be self-explanatory and contextually appropriate — a reader should understand their purpose immediately without needing extra explanation.
- Do not add comments when writing or modifying code. Well-named code is the explanation; a comment restating what the code already says is noise. This includes doc comments, section headers, and inline notes.
- The only exception is a comment that records a non-obvious *reason* a reader could not recover from the code — a trap that already caused a bug, a workaround for a framework/library behaviour, or a deliberate choice that looks wrong. Even then: **ask me first and wait for my approval before adding it.** Describe the comment you propose and why, then let me decide.
- Never delete or rewrite existing comments unless I ask for it.
