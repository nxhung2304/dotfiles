const fs = require("node:fs");
const path = require("node:path");

const SPECS_RELATIVE_DIR = path.join("specs", "issues");
const PRIORITY_LEVELS = ["P1", "P2", "P3"];
const DEFAULT_PRIORITY = "P2";
const PRIORITY_ALIASES = { high: "P1", medium: "P2", low: "P3" };
const NO_DEPENDENCY_MARKERS = ["", "—", "-", "none"];
const FOLDER_SPEC_FILE = "issue.md";
const SPEC_NUMBER_LENGTH = 3;
const MIN_MATCHING_WORD_LENGTH = 3;

function extractHeader(content) {
  const separatorIndex = content.search(/^---\s*$/m);
  return separatorIndex === -1 ? content : content.slice(0, separatorIndex);
}

function extractStatusBlock(header) {
  const metadataIndex = header.search(/^## Metadata\s*$/m);
  return metadataIndex === -1 ? "" : header.slice(0, metadataIndex);
}

function readField(header, fieldPattern) {
  const pattern = new RegExp(`^\\s*-\\s*(?:\\*\\*)?(?:${fieldPattern}):(?:\\*\\*)?\\s*(.*)$`, "m");
  const match = header.match(pattern);
  return match ? match[1].trim() : null;
}

function normalizePriority(rawPriority) {
  if (rawPriority === null) return null;
  const upperCased = rawPriority.toUpperCase();
  if (PRIORITY_LEVELS.includes(upperCased)) return upperCased;
  return PRIORITY_ALIASES[rawPriority.toLowerCase()] ?? null;
}

function parseIssueNumbers(rawIssueField) {
  if (rawIssueField === null) return [];
  return [...rawIssueField.matchAll(/#(\d+)/g)].map((match) => Number(match[1]));
}

function parseSpec(fileOrFolderName, content) {
  const header = extractHeader(content);
  const id = fileOrFolderName.replace(/\.md$/, "");
  const rawPriority = readField(header, "Priority");
  return {
    id,
    number: id.match(/^(\d+)-/)?.[1] ?? null,
    slug: id.replace(/^\d+-/, ""),
    title: readField(header, "Title") ?? id,
    githubIssues: parseIssueNumbers(readField(header, "GitHub Issues?")),
    isApproved: /approved/i.test(readField(header, "Review") ?? ""),
    isMarkedDone: /merged|completed/i.test(extractStatusBlock(header)),
    rawPriority,
    priority: normalizePriority(rawPriority) ?? DEFAULT_PRIORITY,
    rawDependsOn: readField(header, "Depends on"),
  };
}

function listSpecSources(specsDir) {
  const entries = fs.readdirSync(specsDir, { withFileTypes: true });
  const fileSpecIds = new Set(entries.filter((entry) => entry.isFile() && entry.name.endsWith(".md")).map((entry) => entry.name.replace(/\.md$/, "")));
  const fileSources = [...fileSpecIds].map((id) => ({ name: `${id}.md`, relativePath: path.join(SPECS_RELATIVE_DIR, `${id}.md`) }));
  const folderSources = entries
    .filter((entry) => entry.isDirectory() && !fileSpecIds.has(entry.name))
    .filter((entry) => fs.existsSync(path.join(specsDir, entry.name, FOLDER_SPEC_FILE)))
    .map((entry) => ({ name: entry.name, relativePath: path.join(SPECS_RELATIVE_DIR, entry.name, FOLDER_SPEC_FILE) }));
  return [...fileSources, ...folderSources].sort((first, second) => first.name.localeCompare(second.name));
}

function loadSpecs(rootDir) {
  const specsDir = path.join(rootDir, SPECS_RELATIVE_DIR);
  if (!fs.existsSync(specsDir)) return [];
  return listSpecSources(specsDir).map((source) => ({
    ...parseSpec(source.name, fs.readFileSync(path.join(rootDir, source.relativePath), "utf8")),
    specPath: source.relativePath,
    isFolderSpec: source.relativePath.endsWith(FOLDER_SPEC_FILE),
  }));
}

function splitDependencyTokens(rawDependsOn) {
  if (rawDependsOn === null) return [];
  if (NO_DEPENDENCY_MARKERS.includes(rawDependsOn.trim().toLowerCase())) return [];
  return rawDependsOn
    .split(/[,;](?=\s*(?:#|PR\s*#|\d+-[a-z]))/i)
    .map((token) => token.trim())
    .filter((token) => token.length > 0);
}

function significantWords(text) {
  return new Set(
    text
      .toLowerCase()
      .split(/[^\p{L}\p{N}]+/u)
      .filter((word) => word.length >= MIN_MATCHING_WORD_LENGTH),
  );
}

function countSharedWords(hint, spec) {
  const specWords = significantWords(`${spec.title} ${spec.slug}`);
  return [...significantWords(hint)].filter((word) => specWords.has(word)).length;
}

function pickByTitleHint(candidates, titleHint) {
  if (candidates.length <= 1 || !titleHint) return candidates;
  const scored = candidates.map((spec) => ({ spec, score: countSharedWords(titleHint, spec) }));
  const bestScore = Math.max(...scored.map((entry) => entry.score));
  if (bestScore === 0) return candidates;
  return scored.filter((entry) => entry.score === bestScore).map((entry) => entry.spec);
}

function findCandidatesByNumber(digits, specs) {
  const bySpecNumber = specs.filter((spec) => spec.number === digits);
  if (digits.length === SPEC_NUMBER_LENGTH && bySpecNumber.length > 0) return bySpecNumber;
  return specs.filter((spec) => spec.githubIssues.includes(Number(digits)));
}

function resolveDependencyToken(token, specs) {
  const exactSpec = specs.find((spec) => spec.id === token || `${spec.id}.md` === token);
  if (exactSpec) return { specId: exactSpec.id };

  const pullRequestMatch = token.match(/^PR\s*#(\d+)/i);
  if (pullRequestMatch) return { pullRequestNumber: Number(pullRequestMatch[1]) };

  const numberMatch = token.match(/^#(\d+)\s*(?:\(([^)]*)\))?/);
  if (!numberMatch) return { unresolvedToken: token, reason: "unknown format" };

  const [, digits, titleHint] = numberMatch;
  const candidates = pickByTitleHint(findCandidatesByNumber(digits, specs), titleHint);
  if (candidates.length === 1) return { specId: candidates[0].id };
  const reason = candidates.length === 0 ? "no matching spec" : `ambiguous: ${candidates.map((spec) => spec.id).join(", ")}`;
  return { unresolvedToken: token, reason };
}

function resolveDependencies(spec, specs) {
  const resolutions = splitDependencyTokens(spec.rawDependsOn).map((token) => resolveDependencyToken(token, specs));
  return {
    dependsOn: resolutions.filter((resolution) => resolution.specId).map((resolution) => resolution.specId),
    pullRequestDependencies: resolutions.filter((resolution) => resolution.pullRequestNumber).map((resolution) => resolution.pullRequestNumber),
    unresolvedDependencies: resolutions.filter((resolution) => resolution.unresolvedToken),
  };
}

module.exports = {
  SPECS_RELATIVE_DIR,
  DEFAULT_PRIORITY,
  PRIORITY_LEVELS,
  extractHeader,
  normalizePriority,
  parseSpec,
  loadSpecs,
  splitDependencyTokens,
  resolveDependencyToken,
  resolveDependencies,
};
