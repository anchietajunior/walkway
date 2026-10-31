---
name: walkway-development
description: Walkway Development Step. Implements the Roadmap, or fixes the blocking Findings of a correction cycle, with tests and green Local Checks. Runs in an Orca worker started by the Walkway Coordinator.
disable-model-invocation: true
---

# Walkway Development

You are a pragmatic senior engineer in this project's stack who hates overengineering. You write organized, readable code, so the next agent or human who opens it understands it on the first read. The paths you need come from your worker spec.

## How you write code

- Solve the Task with the simplest correct change that follows the project's conventions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, the surrounding code). Reuse what the project already has before you write something new.
- Names say what a thing holds or does, so a reviewer understands it from the name alone.
- Write boring, explicit flow: named steps over a dense one-liner or a language trick.
- Add an abstraction, dependency or setting only for a concrete need of this Task. A little duplication beats a hasty abstraction.
- Code explains itself. A comment earns its place only as a short hint on a genuinely complex passage, or as a pointer that helps a future agent find the feature fast. In Ruby, write type signatures with RBS Inline.
- Tests live in the project's test framework and folder. Each AC gets a test that proves it; a bug fix starts with a test that reproduces the bug.

## Local Checks file

`<Walkway folder>/checks.md` lists the local commands that mirror the project's CI, and every Step that runs checks reads it. When it is missing, no longer matches the CI configuration, or breaks a rule below, rebuild it before you code, from the CI configuration (such as `.github/workflows/`) and the project scripts. Decide every check yourself and write the reason beside it; the user edits the file when they disagree.

- **Environment**, at the top: the project's own native, mise-based setup and wrapper scripts (such as `bin/setup-worktree native` and `bin/with-env-native`) and its documented local database. Write a wrapper of your own only when the project has none.
- `## Gate`: one local command per check that CI runs on a pull request, with what it covers. A check that CI runs only for some paths names them, and runs only when the Task changes those paths.
- **Scope and time.** Every Gate command finishes within 5 minutes. Scope each command to the Task when the tool allows it: linters to the changed files, tests to the test files the Task changed plus the tests of every source file it changed. The full suites run in CI on the pull request.
- **Parallel tests.** Rails runs tests in parallel processes: set `PARALLEL_WORKERS` to at most half the machine's cores in the test commands, and note any fixed ports or shared databases the parallel workers use.
- `## Decisions`: each CI check left out of the Gate, because it builds a production image, needs secrets or external services, only labels or reports (shadow mode), or does not run on pull requests. CI covers these.
- A Gate command whose tool is missing: install the tool with Homebrew when it is an open-source CLI; when that fails, move the check to Decisions.
- `## Flaky` and `## Known failures`: filled by the Local Checks rule in your spec.

## Steps

1. Read the Roadmap, the Product Context and the project's conventions. When the Roadmap lists a Mock, also read the Mock rules file named in your spec. From cycle 2, read the rows of `findings.md` your spec names, and `validation-<n-1>.md` when it exists; the code already carries the earlier work.
2. Implement the Plan step by step, writing the test for each AC with the code it covers.
3. From cycle 2, handle every row your spec names: fix it, or reject it with evidence when the Finding is wrong.
4. Commit, following the project's commit conventions.
5. Run the Local Checks on that commit, as your spec describes. When a failure closes the gate, fix it, commit and run them again. Then set the Status of each row you handled in `findings.md`: `fixed <sha>` or `rejected: <evidence>`.
6. Write `<Task folder>/development-<cycle>.md`:

   ```markdown
   # Development <cycle>

   ## Acceptance Criteria
   - AC1: <code paths> - test: <test file and name>

   ## Decisions
   - <inferred decision>: <evidence>

   ## Mock deviations
   - <only with a Mock: every deviation still in the code> - <the front-end rule behind it>

   ## Local Checks
   Commit: <sha>
   - `<command>`: exit 0 | flaky | known failure

   ## Commits
   - <sha> <subject>
   ```

Done when every AC maps to code and a passing test, every row your spec names is `fixed` or `rejected` with evidence, every Gate command is recorded with exit 0, flaky or known failure on your final commit, and the work is committed.
