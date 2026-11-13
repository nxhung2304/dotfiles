const fs = require("node:fs");
const path = require("node:path");
const { runJsonCommand } = require("./command");

const ISSUE_FIELDS = "number,title,state,body,url,labels,author,createdAt,comments";
const DOC_FILE_PATTERN = /^[\w.-]+\.md$/;

class DetailError extends Error {
  constructor(message, httpStatus) {
    super(message);
    this.httpStatus = httpStatus;
  }
}

function listSpecFiles(specDir, mainFileName) {
  const siblingNames = fs.readdirSync(specDir).filter((name) => DOC_FILE_PATTERN.test(name) && name !== mainFileName).sort();
  return [mainFileName, ...siblingNames];
}

function resolveSpecFile(repoRoot, spec, requestedFileName) {
  const mainFile = path.join(spec.sourceRoot ?? repoRoot, spec.specPath);
  const files = spec.isFolderSpec ? listSpecFiles(path.dirname(mainFile), path.basename(mainFile)) : [path.basename(mainFile)];
  if (requestedFileName !== null && !files.includes(requestedFileName)) {
    throw new DetailError(`Không có file ${requestedFileName} trong spec này`, 404);
  }
  const fileName = requestedFileName ?? files[0];
  return { files, fileName, specFile: path.join(path.dirname(mainFile), fileName) };
}

function readSpecDetail(repoRoot, spec, requestedFileName = null) {
  const { files, fileName, specFile } = resolveSpecFile(repoRoot, spec, requestedFileName);
  let content;
  let modifiedMs;
  try {
    content = fs.readFileSync(specFile, "utf8");
    modifiedMs = fs.statSync(specFile).mtimeMs;
  } catch {
    throw new DetailError(`Không đọc được file spec ${spec.specPath}`, 404);
  }
  return {
    source: "spec",
    id: spec.id,
    title: spec.title,
    path: path.join(path.dirname(spec.specPath), fileName),
    files,
    fileName,
    content,
    modifiedMs,
    canEdit: !spec.sourceRoot,
  };
}

function writeSpecFile(repoRoot, spec, { fileName, content, baseModifiedMs }) {
  if (spec.sourceRoot) throw new DetailError("Spec chỉ có trong nhánh khác, hãy sửa trong worktree của nhánh đó", 409);
  if (typeof content !== "string") throw new DetailError("Thiếu nội dung để lưu", 400);
  if (typeof fileName !== "string") throw new DetailError("Thiếu tên file", 400);
  const { specFile } = resolveSpecFile(repoRoot, spec, fileName);
  if (fs.statSync(specFile).mtimeMs !== baseModifiedMs) {
    throw new DetailError("File đã bị thay đổi từ lúc anh mở, chưa lưu để tránh ghi đè. Copy nội dung đang sửa rồi tải lại.", 409);
  }
  const temporaryFile = `${specFile}.board-${process.pid}.tmp`;
  fs.writeFileSync(temporaryFile, content);
  fs.renameSync(temporaryFile, specFile);
  return { modifiedMs: fs.statSync(specFile).mtimeMs };
}

async function readIssueDetail(repoRoot, issueNumber, runJson = runJsonCommand) {
  if (!Number.isInteger(issueNumber) || issueNumber <= 0) throw new DetailError("Số issue không hợp lệ", 404);
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

module.exports = { readSpecDetail, writeSpecFile, readIssueDetail, DetailError };
