---
name: upgrade-issue
description: Investigate the impact and effort of a dependency or platform change before committing to it: upgrading a framework, language runtime, database or SDK version, replacing a library or external service, or reacting to a dependency or service that reached EOL, was deprecated or archived. Reads upgrade guides and vendor docs, checks every dependency's compatibility from real package metadata, traces what the code actually uses, runs a baseline, then writes a labelled findings list and effort table with explicit assumptions, saved via issue-docs. Any language or stack. Defaults to Vietnamese, accepts a `lang` override. Use for: "upgrade-issue", "nâng version X lên Y ảnh hưởng gì / mất bao lâu", "điều tra ảnh hưởng và effort", "影響範囲と工数", "verUp", "migrate sang", "thay thư viện/dịch vụ", "X sắp EOL", "gem/package bị deprecated/archived", or an issue asking for upgrade impact or cost of a version bump, even if the skill is not named. Not for new-feature estimates (feature-discuss) or bug fixes (fix-issue).
---

# Upgrade Issue

Purpose: give the user (and later their leader) a trustworthy answer to "what breaks and how long will it take" for a version upgrade, a library/service replacement, or an EOL/deprecation response. The answer is only useful if every claim says how sure it is, so labelling confidence is the core of this skill, not decoration.

Does not perform the upgrade. A spike (Step 6) is a throwaway experiment on a local branch, never committed or pushed.

**Language:** Vietnamese by default. If ARGUMENTS gives a language (`lang: en`, `en`, `english`), use that. Saved files follow the language of the most recent files under `specs/issues/`; if those are mixed, follow `lang`, else Vietnamese. Keep identifiers, versions and `file:line` as-is.

## Step 0: Frame the change

1. Find the issue: issue number from ARGUMENTS or the branch name, then `specs/issues/<n>-*/`. If the folder or `issue.md` is missing and the issue is on GitHub, fetch it with `github-issues-to-md` first.
2. Write down for yourself: **from** (current versions), **to** (target; "latest" means look up the actual latest release today), **kind** (upgrade / replacement / EOL response), and what the requester wants back (impact only, impact + effort, rough is OK or a firm number).
3. If the issue already has an `investigate.md` and you are re-running, do not read the old file unless the user asks; it would anchor the result. Read the related issues under `specs/issues/` (a previous upgrade of the same component, issues on the same topic) and carry over the traps they recorded. Treat any Status or conclusion text already in `issue.md` as unverified: do not copy it, re-check what you rely on.
4. If the target is ambiguous (e.g. "latest 8.x" vs "8.1"), pick the reading the issue text supports and state it; ask only if the choice changes the work materially.

## Step 1: Current state (from the repo, not memory)

- Versions from the lockfile and version files (`Gemfile.lock`, `package-lock.json`, `.ruby-version`, `.tool-versions`, `go.mod`, `pubspec.lock`, Dockerfile, CI config). Note where they disagree (e.g. CI uses an older runtime than local).
- Config that the change touches (framework defaults/load_defaults, storage, auth, asset pipeline, DB adapter, initializers, monkey patches).
- Size signals that drive effort: lines of app code, number of endpoints/screens/controllers, test count.
- Base the investigation on the committed default branch. If the working tree has uncommitted changes, say they were excluded — they are often local environment tweaks, not part of the app. When a version or line number is quoted from the working tree instead of the commit, say so, and say which one the baseline run used.

**Managed or vendor-hosted service** (Azure, RDS, Cloud SQL, a hosted SDK...): ask the user early where it runs and which settings the servers use (hosting, version, tier, replicas, high availability, server parameters). The vendor's own upgrade procedure and limits then become part of Step 2, and a DB change gets a standard checklist: auth plugin, server parameters, replicas, drift between the live schema and the schema file, other clients of the same database.

**Servers can differ from the repo.** Production/staging config is sometimes edited on the server or injected at deploy time. Whenever a finding depends on a runtime setting (which storage service, which env flag, which DB version), ask the user what the servers actually use instead of trusting the repo file. A wrong assumption here can turn a "low impact" item into a data-loss risk.

## Step 2: Official changes along the path

- Read the official upgrade guide, release notes and CHANGELOGs for every step between from and to. Prefer primary sources: the project's own guide/repo, the language's maintenance page, the package registry API.
- When the service is run by a vendor, find the vendor's own docs with WebSearch (their upgrade guide, version policy, limits) and read them. The upstream project's docs alone are not enough, because the vendor often changes defaults, support dates and the upgrade steps.
- Every EOL or support date needs the URL it came from. A date recalled from memory is labelled "guess".
- Do not call anything the "biggest risk" until you have read the vendor's docs for it.
- Find the required path: many frameworks expect one minor at a time, and the runtime may need bumping in the middle (e.g. framework N+1 needs a newer language than the current one). Write the proposed order of runtime and framework bumps, and mark untested pairs as assumptions.
- Record support status (EOL dates) of the current and target versions — this is usually the "why" for the leader.
- For a replacement there is no upgrade guide: use B's migration guide or README, and say which steps come from it.
- Pull out only the breaking changes that can plausibly hit this app, then check each against the code in Step 4.

Research subagents are fine for this fan-out (official docs in one, dependency metadata in another, run in parallel). Ask them for a URL and a short exact quote per claim. Treat what they return as "read once" until you re-check the claims that matter (Step 5).

## Step 3: Dependency compatibility

**Replacement** (swap library or service A for B): the key check is B's own constraints on the current runtime and framework, read per release from the registry metadata (e.g. required language version, framework range). If no release of B runs on the current runtime, that is a blocker: name the runtime/framework bump it forces and treat it as a prerequisite (Step 7). Only B, A and their transitive dependencies matter; list the dependencies that disappear.

For an upgrade, check every direct dependency in the lockfile:
- Latest version and whether it supports the target (constraints on the framework/runtime from the registry metadata or gemspec/package.json — not from blog posts).
- Maintenance status (active, stale, archived, retired) and the recommended replacement if dead.
- Breaking changes between the locked version and the one you would move to, only the ones that need app changes.

A dependency that caps the target (e.g. `< 8.0`, `grape < 1.3`) is a blocker until Step 4 shows whether the app really needs it.

## Step 4: Trace what the code actually uses

"The package is in the manifest" proves nothing (Gemfile, package.json, go.mod, pubspec.yaml, pom.xml...). For each blocker and each breaking change:
- Grep the real API names (methods, helpers, config keys, constants), not only the library name, and follow callers up to a live entry point (route, screen, job, initializer).
- Look for vendored or monkey-patched code that the change makes obsolete or that will conflict, and for things configured but selected by no environment.
- Look for the opposite case too: is the thing configured but never mounted/called? A dependency that is configured but unused is removed, not upgraded, which can collapse a "biggest risk" into half a day.
- Note exact `file:line` for every place that must change; this becomes the input for implement.md later.
- If a call path cannot be traced (dynamic dispatch, another repo), write "guess — callers not traced".

## Step 5: Baseline and second check

- Run the test suite on the current versions and record the result (runs, failures). If the current version cannot be run here, or the run is denied, write "not run", the reason, and who could run it; do not fill the gap with a guess. Say whether the run used the working tree or the commit. For a stateful dependency (database, queue, cache, search), run it isolated: separate instance and data name, never the user's shared one. Read the project's own config first to see how it connects (host/port/socket, env vars); if it cannot be pointed at a different port, use a socket, and keep socket paths short (unix limit is about 104 characters). If the baseline is skipped on the user's instruction, write "skipped by instruction". If a command is denied, stop, do not retry variants, and clean up anything you started (processes, sockets, temp data). Turn on the runtime's deprecation warnings when cheap (e.g. `RUBYOPT=-W:deprecated`, `NODE_OPTIONS=--trace-deprecation`) and group warnings by source — app code vs each dependency.
- Run the framework's own consistency checks if they exist (e.g. autoloader check). A check that already fails today is a finding, labelled as pre-existing.
- Re-check independently every claim that drives a decision, a big effort line or a support date: query the registry/gemspec yourself, open the upstream source at the target tag, or read the CHANGELOG line. Use the `fact-check` skill for claims that need outside evidence. Only then label it Confirmed.

## Step 6: Spike (optional, timeboxed)

Offer a spike when the estimate will be reported upward or when one area dominates the uncertainty. Recommend the step that best calibrates the estimate (often the first framework minor, or the riskiest dependency) and get the user's go-ahead before starting.

Rules:
- Isolate it: a git worktree inside the project's ignored folder (e.g. `.claude/worktrees/<name>`) on a local branch from the committed base, plus a separate test database. Never touch the user's working tree or shared test DB.
- If the committed base does not build on this machine, copy the user's local environment tweaks (lockfile pins for native gems, test config) into the worktree and list them — they are environment needs, not upgrade work.
- Do not share writable state with the user's working copy (symlinked dependency folders, shared databases) when any step may install or migrate; give the experiment its own copy, or skip that step and say so.
- First get the baseline green in the worktree, then do the step, then rerun tests and checks.
- Log a timestamp at each phase boundary (start, environment ready, baseline green, step done) and note any pause waiting for the user or a permission prompt. Report hands-on time and waiting time separately — elapsed time between two timestamps is not work time.
- Do not commit or push. If a command is denied, skip that part, say what was not verified, and move on rather than retrying variants of it.
- One spike step is one data point. Say what it does and does not calibrate.

## Step 7: Effort table

- State the assumption first: who does the work and how (one developer, manual vs AI-assisted such as Claude Code), and what is included (code, regression testing, deploy). An estimate without this line will be misread.
- One row per area (runtime bump, each framework step group, each major dependency family, replacements, frontend/assets, regression testing, deploy/infra). Give a range per row and a total.
- Testing on real environments and deploy work rarely shrink with AI assistance; code changes driven by upgrade guides and failing tests usually do. If the user wants one number for the leader, use the variant they choose and keep the other in investigate.md.
- Work that the change depends on but is out of scope (e.g. the runtime or framework bump a replacement forces) goes in its own row, kept out of the total and marked "prerequisite, not included", with a rough size if it can be given.
- Label the whole table as an estimate unless a spike measured part of it.

## Step 8: Save and report

1. Save via `issue-docs` into `investigate.md` (create or update). If there is no issue folder, `issue-docs` still saves under `specs/issues/`; if the repo has no `specs/`, write one file and state its full path. Use these sections so the confidence of every line is visible:
   - Summary (feasible or not, required runtime bump, path, main risks, estimate with its assumption)
   - Decisions (what the user has chosen)
   - Current state — Confirmed
   - Confirmed (checked twice: source + code or upstream)
   - Per docs (read once, not re-checked)
   - Unconfirmed (needs a trial run)
   - Cannot confirm (needs info from outside the repo — say what and from whom)
   - Spike (if run): steps, result, time split, what it does not cover
   - Effort table
   - Open questions
2. Keep investigate.md short enough for the leader to read in a few minutes: one line per finding, details only where they change a decision.
3. Do not create implement.md until the user settles the decisions that shape the plan.
4. Text for the leader goes through the `report` skill (written to a file with a `pbcopy` command), never drafted here.
5. Chat reply: conclusion (feasible? blocked by a prerequisite? required runtime bump? estimate range with its assumption), the questions only the user or server owners can answer, and at most two next steps (typically: a spike on the riskiest area, the leader report).

## Pitfalls seen before

- Calling a dependency the "top risk" before checking whether the app uses it.
- Trusting the repo's production config when the server overrides it.
- Reporting wall-clock spike time as effort when part of it was waiting.
- Leaving out whether the estimate assumes AI assistance.
- Copying a research agent's table as fact; re-check what the decision rests on.
- Data migrations that backfill from current config (e.g. a column filled with "the service configured right now") — run with the wrong config, they silently corrupt every existing row. Call out the deploy order.
