---
name: implement-code
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, Bash
description: Execute the Implementation Checklist.
---

- Read the spec → extract all keywords from the Checklist
- **Call rule-lookup ONCE** at the start with the full set of keywords — cache the result, reuse it for the whole session (do not call it again per item)
- Work through the Checklist items in order, sequentially
- If it's UI/color related: call the **design-checker** subagent
- After each major item: call the **code-reviewer** subagent to verify
- Do not over-engineer, do not write code outside the spec

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can continue to the next step.
Return: { files_changed, checklist_items_completed }
