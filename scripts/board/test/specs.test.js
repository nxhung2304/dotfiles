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
