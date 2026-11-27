const test = require("node:test");
const assert = require("node:assert/strict");
const { parseSpec, resolveDependencyToken, splitDependencyTokens } = require("../specs");

function buildSpecContent({ title, issue, dependsOn, priority, review = "Approved", pr = "Draft" }) {
  return [
    "## **Status:**",
    `- Review: ${review}`,
    `- PR: ${pr}`,
    "",
    "## Metadata",
    `- **Title:** ${title}`,
    issue ? `- **GitHub Issue:** #${issue}` : null,
    priority ? `- **Priority:** ${priority}` : null,
    dependsOn ? `- **Depends on:** ${dependsOn}` : null,
    "",
    "---",
    "",
    "- **High Priority:** body text that is not metadata",
  ]
    .filter((line) => line !== null)
    .join("\n");
}

const specs = [
  parseSpec("017-email-password-auth-api.md", buildSpecContent({ title: "Email/Password Auth — Core API" })),
  parseSpec("017-shared-ui-app.md", buildSpecContent({ title: "Shared UI — AppLoading", issue: 49 })),
  parseSpec("018-home-dashboard-screen.md", buildSpecContent({ title: "Home Dashboard — Screen Shell", issue: 51 })),
  parseSpec("024-apply-new-design-to-app.md", buildSpecContent({ title: "Apply the new design", issue: 78 })),
];

test("parseSpec reads only the header fields", () => {
  const spec = parseSpec("026-dark.md", buildSpecContent({ title: "Dark mode", issue: 80, priority: "High", review: "Pending" }));
  assert.equal(spec.title, "Dark mode");
  assert.deepEqual(spec.githubIssues, [80]);
  assert.equal(spec.priority, "P1");
  assert.equal(spec.isApproved, false);
  assert.equal(spec.number, "026");
});

test("parseSpec treats the old Merged and Completed status formats as done", () => {
  assert.equal(parseSpec("001-a.md", "## **Status:** Merged\n\n## Metadata\n- **Title:** A\n---").isMarkedDone, true);
  assert.equal(parseSpec("002-b.md", "## **Status:**\n- ✅ Completed\n\n## Metadata\n- **Title:** B\n---").isMarkedDone, true);
  assert.equal(parseSpec("003-c.md", buildSpecContent({ title: "C", pr: "Draft" })).isMarkedDone, false);
});

test("parseSpec defaults priority to P2 when missing", () => {
  assert.equal(parseSpec("001-a.md", buildSpecContent({ title: "A" })).priority, "P2");
});

test("splitDependencyTokens keeps commas inside parentheses", () => {
  assert.deepEqual(splitDependencyTokens("#016 (Login, Google), #017 (Auth API)"), ["#016 (Login, Google)", "#017 (Auth API)"]);
  assert.deepEqual(splitDependencyTokens("—"), []);
});

test("resolveDependencyToken handles the three formats", () => {
  assert.deepEqual(resolveDependencyToken("018-home-dashboard-screen", specs), { specId: "018-home-dashboard-screen" });
  assert.deepEqual(resolveDependencyToken("#78", specs), { specId: "024-apply-new-design-to-app" });
  assert.deepEqual(resolveDependencyToken("#017 (Email/Password Auth API)", specs), { specId: "017-email-password-auth-api" });
});

test("resolveDependencyToken reports duplicate spec numbers without a title hint", () => {
  const resolution = resolveDependencyToken("#017", specs);
  assert.equal(resolution.unresolvedToken, "#017");
  assert.match(resolution.reason, /^ambiguous/);
});

test("toGithubWebUrl handles https and ssh remotes", () => {
  const { toGithubWebUrl } = require("../repo-url");
  assert.equal(toGithubWebUrl("https://github.com/rights-s/app.git\n"), "https://github.com/rights-s/app");
  assert.equal(toGithubWebUrl("git@github.com:nxhung2304/dotfiles.git"), "https://github.com/nxhung2304/dotfiles");
  assert.equal(toGithubWebUrl("https://gitlab.com/a/b"), null);
});

test("loadSpecs reads folder issue docs only when no file spec has the same name", () => {
  const fs = require("node:fs");
  const os = require("node:os");
  const path = require("node:path");
  const { loadSpecs } = require("../specs");
  const rootDir = fs.mkdtempSync(path.join(os.tmpdir(), "board-specs-"));
  const specsDir = path.join(rootDir, "specs", "issues");
  fs.mkdirSync(path.join(specsDir, "023-with-file"), { recursive: true });
  fs.mkdirSync(path.join(specsDir, "87-folder-only"), { recursive: true });
  fs.writeFileSync(path.join(specsDir, "023-with-file.md"), buildSpecContent({ title: "File spec" }));
  fs.writeFileSync(path.join(specsDir, "023-with-file", "testcases.md"), "x");
  fs.writeFileSync(path.join(specsDir, "87-folder-only", "issue.md"), buildSpecContent({ title: "Folder spec", issue: 87 }));
  const loaded = loadSpecs(rootDir);
  fs.rmSync(rootDir, { recursive: true });
  assert.deepEqual(loaded.map((spec) => [spec.id, spec.isFolderSpec]), [["023-with-file", false], ["87-folder-only", true]]);
});

test("resolveDependencyToken reads PR references", () => {
  assert.deepEqual(resolveDependencyToken("PR #73 (OT Request) merged first", specs), { pullRequestNumber: 73 });
});

test("parseSpec treats 'Not approved' and 'Unapproved' as not approved", () => {
  for (const review of ["Not approved", "Unapproved", "not approved yet"]) {
    assert.equal(parseSpec("026-dark.md", buildSpecContent({ title: "Dark mode", review })).isApproved, false, review);
  }
  assert.equal(parseSpec("026-dark.md", buildSpecContent({ title: "Dark mode", review: "Approved by lead" })).isApproved, true);
});

test("parseSpec marks done only on a positive merged or completed status", () => {
  const readIsMarkedDone = (pr, review = "Approved") => parseSpec("026-dark.md", buildSpecContent({ title: "Dark mode", pr, review })).isMarkedDone;
  assert.equal(readIsMarkedDone("not yet merged"), false);
  assert.equal(readIsMarkedDone("chưa merged"), false);
  assert.equal(readIsMarkedDone("Draft", "Review completed"), false);
  assert.equal(readIsMarkedDone("Merged"), true);
});

function buildNotesSpec({ metadataLines = [], noteLines = [] }) {
  return ["## Metadata", "- **Title:** t", ...metadataLines, "", "---", "", "## Notes", ...noteLines].join("\n");
}

test("parseSpec reads Depends on from a Notes bullet without a colon", () => {
  const spec = parseSpec("122-leave.md", buildNotesSpec({ noteLines: ["- Depends on #121."] }));
  assert.equal(spec.rawDependsOn, "#121");
  assert.deepEqual(splitDependencyTokens(spec.rawDependsOn), ["#121"]);
});

test("parseSpec reads Depends on from a Notes bullet with a colon", () => {
  const spec = parseSpec("122-leave.md", buildNotesSpec({ noteLines: ["- Depends on: #121, 120-base"] }));
  assert.deepEqual(splitDependencyTokens(spec.rawDependsOn), ["#121", "120-base"]);
});

test("parseSpec keeps the Metadata Depends on when the Notes also have one", () => {
  const spec = parseSpec("122-leave.md", buildNotesSpec({ metadataLines: ["- **Depends on:** #121"], noteLines: ["- Depends on #130."] }));
  assert.equal(spec.rawDependsOn, "#121");
});

test("parseSpec treats a Notes Depends on none as no dependency, and no text as null", () => {
  const withNone = parseSpec("122-leave.md", buildNotesSpec({ noteLines: ["- Depends on none."] }));
  assert.deepEqual(splitDependencyTokens(withNone.rawDependsOn), []);
  assert.equal(parseSpec("122-leave.md", buildNotesSpec({ noteLines: ["- Nothing else to say."] })).rawDependsOn, null);
});

test("parseSpec ignores a prose line that only starts with Depends on", () => {
  const spec = parseSpec("122-leave.md", buildNotesSpec({ noteLines: ["- Depends on the backend team for the API."] }));
  assert.equal(spec.rawDependsOn, null);
});

test("parseSpec reads Conflicts with from the Metadata or from a Notes bullet", () => {
  const fromMetadata = parseSpec("123-create.md", buildNotesSpec({ metadataLines: ["- **Conflicts with:** #122"] }));
  const fromNotes = parseSpec("123-create.md", buildNotesSpec({ noteLines: ["- Conflicts with #122."] }));
  assert.equal(fromMetadata.rawConflictsWith, "#122");
  assert.equal(fromNotes.rawConflictsWith, "#122");
  assert.equal(parseSpec("123-create.md", buildNotesSpec({})).rawConflictsWith, null);
});
