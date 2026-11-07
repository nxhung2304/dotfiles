---
name: plan-design
model: claude-opus-5-5
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(mkdir -p *), Bash(open *), Bash(rm -r specs/designs/explore), Write, Edit, WebSearch, WebFetch
description: Step 4 of the plan-* flow. Sets the project's visual design once — shows 3 clearly different style directions as HTML demos built on a real screen from the PRD, iterates on the user's feedback until they settle on one, then writes the shared design files every later screen must follow. For an app that already has built screens and a theme, it mirrors the current style from code instead of proposing new ones and lists mismatches with existing wireframes. Output files: specs/designs/tokens.css, components.css, components.html and specs/rules/design.md. Use when the user says "plan-design", "chốt design", "chốt style", "chọn style cho dự án", "bảng màu dự án", "design system cho dự án", or starts screen design on a project that has no specs/rules/design.md yet.
---

# Plan Design

Flow: plan-idea → plan-prd → plan-stack → **plan-design** → plan-story → generate-issues

Decides how the whole project looks, once. Later screens (`ui-ux-workflow`) only reuse what this step writes.

## Output files

| File | Holds |
| :--- | :--- |
| `specs/designs/tokens.css` | Every value: colors (light + dark), font, type scale, spacing, radius, shadow. The only place a raw value may appear. |
| `specs/designs/components.css` | Component classes (button, input, card, ...) built only from `var(--...)` in `tokens.css`. |
| `specs/designs/components.html` | Showcase of every component and its states; links both CSS files. |
| `specs/rules/design.md` | Style, "Always" / "Never" rules, component usage, decision log (template: `assets/design.template.md`). |

## Steps

1. **Read context.** `specs/prd.md`, `specs/techstack.md`, `specs/idea.md`, `specs/story.md`, `CLAUDE.md`. `specs/prd.md` is required only for a new project (no app code yet); if it is missing there, stop and say: run `/plan-prd` first.
   - If the product has no user interface (CLI, API only, library), say so and end with `Next: /plan-story`.
   - If `specs/rules/design.md` already exists, ask whether to update it or restart; never overwrite without asking.
   - If the app already has built screens styled by a theme in code (Tailwind config, CSS variables, `AppColors`, `ThemeData`, ...), use **Existing app** below instead of steps 2–7, unless the user asks for a new look.
   - If the repo has a theme but few or no built screens, read it; one of the 3 directions must be "keep the current look, cleaned up".
2. **Ask only what is missing**, at most 2–3 questions: the feeling the product should give, existing brand (logo, color, font), display language, light/dark needs. Then restate the brief in 2–3 sentences and wait for the user to confirm.
3. **Optional references.** For style direction only, 1–2 targeted queries (see `~/.claude/skills/ui-ux-workflow/references/sources.md`). Learn patterns, never copy another product's design.
4. **Build 3 demos** in `specs/designs/explore/style-a.html`, `style-b.html`, `style-c.html`:
   - All 3 show the same content: the screen for the PRD's most important job, with real content in the display language (no lorem ipsum), plus a component strip (primary/secondary/disabled button, input with error, card, list item, empty state, error message).
   - Each is self-contained (its own `:root` tokens, inline CSS/JS) and has a light/dark toggle.
   - Interactive where possible, with plain inline JS: buttons and links work, tabs and navigation switch views, modals and menus open and close, inputs show their error state, a control toggles loading / empty / error so every state can be seen.
   - The 3 must differ clearly in color, typography and density, not just hue. Name each direction in 2–4 words and say in one line why it fits the brief.
   - Avoid generic defaults: no default purple/blue gradient, no large rounded cards for everything, no emoji as icons.
   - Run `open` on each file so the user sees them, then ask: which direction, or which parts of which (e.g. colors from A, type from B)?
5. **Iterate.** Each round, edit only what the user commented on, in the chosen demo file, and reopen it. Note each round's decision for the log. After 3 rounds without convergence, go back to step 2 and re-check the brief instead of tuning values.
6. **Finalize** when the user says the direction is settled:
   - Draft the 4 output files from the chosen demo (templates: `assets/tokens.template.css`, `assets/design.template.md`). `components.html` covers every component the PRD screens need, not only the demo strip, each with default, hover, focus, disabled and error states where relevant, in light and dark, and interactive components (modal, menu, tabs, toast) actually work.
   - Self-check: `components.css` and `components.html` contain no hex/rgb/px value that is not a `var(--...)` from `tokens.css` (except 0 and 1px borders); contrast ≥ 4.5:1 for text, touch targets ≥ 44×44px.
   - Show the drafts and wait for approval before writing (`mkdir -p specs/designs specs/rules`). Open `components.html` after writing.
7. **Clean up.** Delete `specs/designs/explore/` (`rm -r specs/designs/explore`) so later screens cannot copy a rejected direction. The chosen direction and why are kept in the decision log of `design.md`.

## Existing app

The running app is the source of truth; the design files mirror it. No demos, no new style.

1. **Collect the current style from code**: theme and color files, fonts, radius, spacing, shared widgets/components and the screens that use them. Also read existing wireframes (`specs/designs/**`) and any design notes in `CLAUDE.md` or `specs/designs/*.md`. If `CLAUDE.md` states which side wins (app or wireframe), follow it.
2. **List mismatches** between the app and every existing wireframe or note, old or recent (e.g. a wireframe font the app does not use), each with file:line on both sides. Do not change app code or existing wireframes; the list goes into `design.md` under open questions.
3. **Draft the 4 output files** from the app's values:
   - `tokens.css`: every color, font, radius and spacing the app names in code or uses in 2+ places, named after the code's names (e.g. `AppColors.inkSoft` → `--ink-soft`).
   - No font declared in code: `--font-family` is the platform's system font stack; `design.md` calls it "platform default font".
   - Values the app shows but code does not set (framework defaults such as Material 3 text styles or SnackBar/NavigationBar colors): put them in `tokens.css` so components stay on tokens, and list each under "Giả định" in `design.md` with where the value came from and how to confirm it (run the app, framework docs).
   - Features the app does not have (e.g. dark mode) are left out and listed as open questions, not invented.
   - `components.css` + `components.html`: the app's shared widgets/components and their states, as interactive HTML.
   - `design.md`: in "File design của dự án", state that app code is the source and `tokens.css` must be updated in the same change when the app style changes.
   - Same self-check as step 6 of Steps, except that a one-off number copied literally from a widget's code (used once, not named in code) may stay as a raw value in `components.css`.
4. **Show the drafts, the mismatch list and the files that should switch to linking `tokens.css`** (existing wireframe CSS), wait for approval, then write and open `components.html`. Rewriting old wireframes is a separate step the user decides on.

## Rules

- Style decisions only. No feature or screen-flow changes; if the brief conflicts with the PRD, report it and send the user back to `plan-prd`.
- One source per value: tokens live only in `tokens.css`; `design.md` points to files and never repeats values.
- Present UI for review only as HTML files opened with `open`, never as screenshots or PNG. To review several screens at once, create an `index.html` in that group's folder with one iframe per screen (about 390px wide for mobile), each labelled with the screen name and still clickable, and open that page.
- Drafts live in the session's scratchpad directory until approved; only approved files are written under `specs/`. Demo files in `specs/designs/explore/` are the exception, since the user opens them during step 4–5.
- Flutter project: after writing, ask the `design-checker` agent to compare `tokens.css` with `AppColors`. On a mismatch, the side that is not the source is the one to update (the agent only proposes): new design → `AppColors` follows `tokens.css`; existing app → `tokens.css` follows `AppColors`.

## Done

Report the files written, the chosen direction (or "mirrored from the existing app"), the mismatches found and the open questions. Last line: `Next: /plan-story`
