const test = require("node:test");
const assert = require("node:assert/strict");
const { toGithubWebUrl } = require("../repo-url");

test("toGithubWebUrl reads a plain github.com remote", () => {
  assert.equal(toGithubWebUrl("git@github.com:owner/repo.git"), "https://github.com/owner/repo");
  assert.equal(toGithubWebUrl("https://github.com/owner/repo"), "https://github.com/owner/repo");
});

test("toGithubWebUrl reads an SSH alias host such as github-personal.com", () => {
  assert.equal(toGithubWebUrl("git@github-personal.com:nxhung2304/elearning-mobile.git"), "https://github.com/nxhung2304/elearning-mobile");
});

test("toGithubWebUrl returns null for a non-GitHub remote", () => {
  assert.equal(toGithubWebUrl("git@gitlab.com:owner/repo.git"), null);
});
