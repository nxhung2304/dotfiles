const fs = require("node:fs");
const path = require("node:path");
const { runJsonCommand } = require("./command");

const ISSUE_FIELDS = "number,title,state,body,url,labels,author,createdAt,comments";

class DetailNotFoundError extends Error {
  constructor(message) {
    super(message);
    this.httpStatus = 404;
  }
}

const DOC_FILE_PATTERN = /^[\w.-]+\.md$/;

function listSpecFiles(specDir, mainFileName) {
  const siblingNames = fs.readdirSync(specDir).filter((name) => DOC_FILE_PATTERN.test(name) && name !== mainFileName).sort();
  return [mainFileName, ...siblingNames];
}

function readSpecDetail(repoRoot, spec, requestedFileName = null) {
  const mainFile = path.join(spec.sourceRoot ?? repoRoot, spec.specPath);
  const files = spec.isFolderSpec ? listSpecFiles(path.dirname(mainFile), path.basename(mainFile)) : [path.basename(mainFile)];
  if (requestedFileName !== null && !files.includes(requestedFileName)) throw new DetailNotFoundError(`Không có file ${requestedFileName} trong spec này`);
  const fileName = requestedFileName ?? files[0];
  const specFile = path.join(path.dirname(mainFile), fileName);
  let content;
  try {
    content = fs.readFileSync(specFile, "utf8");
  } catch {
    throw new DetailNotFoundError(`Không đọc được file spec ${spec.specPath}`);
  }
  return { source: "spec", id: spec.id, title: spec.title, path: path.join(path.dirname(spec.specPath), fileName), files, fileName, content };
}

async function readIssueDetail(repoRoot, issueNumber, runJson = runJsonCommand) {
  if (!Number.isInteger(issueNumber) || issueNumber <= 0) throw new DetailNotFoundError("Số issue không hợp lệ");
  const issue = await runJson("gh", ["issue", "view", String(issueNumber), "--json", ISSUE_FIELDS], { cwd: repoRoot });
  return {
    source: "github",
    number: issue.number,
    title: issue.title,
    state: issue.state,
    url: issue.url,
    body: issue.body ?? "",
    labels: (issue.labels ?? []).map((label) => label.name),
    author: issue.author?.login ?? null,
    createdAt: issue.createdAt,
    commentCount: (issue.comments ?? []).length,
  };
}

module.exports = { readSpecDetail, readIssueDetail, DetailNotFoundError };
