const fs = require("node:fs");
const path = require("node:path");
const {
  SPECS_RELATIVE_DIR,
  DEFAULT_PRIORITY,
  extractHeader,
  normalizePriority,
  loadSpecs,
  resolveDependencies,
} = require("./specs");

const NO_DEPENDENCY = "—";
const METADATA_HEADING = /^## Metadata\s*$/;
const BULLET_LINE = /^\s*-\s/;

function planDependsOn(spec, specs) {
  const { dependsOn, unresolvedDependencies } = resolveDependencies(spec, specs);
  if (unresolvedDependencies.length > 0) {
    return {
      value: spec.rawDependsOn,
      problem: unresolvedDependencies.map((dependency) => `${dependency.unresolvedToken}: ${dependency.reason}`).join("; "),
    };
  }
  return { value: dependsOn.length > 0 ? dependsOn.join(", ") : NO_DEPENDENCY, problem: null };
}

function planPriority(spec) {
  if (spec.rawPriority === null) return { value: DEFAULT_PRIORITY, problem: null };
  const normalized = normalizePriority(spec.rawPriority);
  if (normalized) return { value: normalized, problem: null };
  return { value: spec.rawPriority, problem: `unknown priority "${spec.rawPriority}"` };
}

function planMigration(specs) {
  return specs.map((spec) => ({
    spec,
    dependsOn: planDependsOn(spec, specs),
    priority: planPriority(spec),
  }));
}

function upsertMetadataField(content, fieldName, value) {
  const header = extractHeader(content);
  const fieldLine = `- **${fieldName}:** ${value}`;
  const existingField = new RegExp(`^\\s*-\\s*(?:\\*\\*)?${fieldName}:(?:\\*\\*)?.*$`, "m");
  if (existingField.test(header)) {
    return content.replace(existingField, () => fieldLine);
  }
  const lines = content.split("\n");
  const headingIndex = lines.findIndex((line) => METADATA_HEADING.test(line));
  if (headingIndex === -1) throw new Error(`no "## Metadata" section`);
  let lastBulletIndex = headingIndex;
  while (BULLET_LINE.test(lines[lastBulletIndex + 1] ?? "")) lastBulletIndex += 1;
  lines.splice(lastBulletIndex + 1, 0, fieldLine);
  return lines.join("\n");
}

function applyPlanEntry(repoRoot, entry) {
  const filePath = path.join(repoRoot, SPECS_RELATIVE_DIR, `${entry.spec.id}.md`);
  const original = fs.readFileSync(filePath, "utf8");
  let updated = original;
  if (!entry.dependsOn.problem) updated = upsertMetadataField(updated, "Depends on", entry.dependsOn.value);
  if (!entry.priority.problem) updated = upsertMetadataField(updated, "Priority", entry.priority.value);
  if (updated !== original) fs.writeFileSync(filePath, updated);
  return updated !== original;
}

function describeChange(before, after) {
  return before === after ? after : `${before ?? "(none)"} → ${after}`;
}

function printPlan(plan) {
  for (const entry of plan) {
    const problems = [entry.dependsOn.problem, entry.priority.problem].filter(Boolean);
    console.log(entry.spec.id);
    console.log(`  Depends on: ${describeChange(entry.spec.rawDependsOn, entry.dependsOn.value)}`);
    console.log(`  Priority:   ${describeChange(entry.spec.rawPriority, entry.priority.value)}`);
    if (problems.length > 0) console.log(`  SKIPPED (fix by hand): ${problems.join("; ")}`);
  }
}

function main() {
  const isWriteMode = process.argv.includes("--write");
  const repoRoot = process.argv.slice(2).find((argument) => !argument.startsWith("--")) ?? process.cwd();
  const plan = planMigration(loadSpecs(repoRoot));
  printPlan(plan);
  if (!isWriteMode) {
    console.log("\nDry run. Re-run with --write to apply.");
    return;
  }
  const changedCount = plan.filter((entry) => applyPlanEntry(repoRoot, entry)).length;
  console.log(`\nUpdated ${changedCount} spec file(s).`);
}

if (require.main === module) main();

module.exports = { planMigration, upsertMetadataField };
