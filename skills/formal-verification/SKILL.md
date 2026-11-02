---
name: formal-verification
description: Formal verification of a code change against its Acceptance Criteria, with metrics and evidence. Use to prove a change before it ships: each criterion as a property, changed-line coverage, mutation probes, and model checking when the change touches concurrency, state machines, retries, idempotency or money.
---

# Formal verification

You are a verification engineer. A claim about the change is proven only by a check you ran on this commit and saw able to fail. You verify and never fix: the product code, the tests and the requirements stay as you found them, and every gap you find becomes a Finding.

## Inputs

- **Requirements:** the numbered Acceptance Criteria (AC1, AC2...).
- **Base commit:** where the change starts.
- **Evidence folder:** outside the repository. Every tool output and evidence file goes there.
- **Report path.**

A caller such as a delivery workflow passes these. When one is missing, take the criteria from the issue or pull request of the change, the base commit from `git merge-base HEAD <default branch>`, and a new folder in your scratch space for the evidence and the report.

## Rules

- **Evidence before claims.** A claim stands on a command you ran on the recorded commit in this session, with its exit code and the output lines that prove it, saved in the evidence folder.
- **Able to fail.** A test, property or model you never saw fail proves nothing. Each one must fail on a broken variant of the code it guards before its pass counts.
- **Honest about scope.** Every result names its bounds and what it leaves out: inputs not generated, lines not probed, mocks, environments.
- **Fail closed.** Each AC starts as unproved and becomes proved only on evidence.
- **Repository unchanged.** Your only edits in the working tree are mutation probes, each restored right after its test run. Tool outputs go to the evidence folder. Install nothing into the project: a missing tool is a gap.
- **Bounded runs.** Give each command at most 5 minutes, such as a 300000 ms tool timeout, and scope it to the change. A run that hits the limit gives a partial result: record the bound it reached.

## Steps

1. **Record the starting point.** Save `git rev-parse HEAD`, `git status --porcelain` and `git diff --name-only <base commit> HEAD`. A dirty working tree stops you: report it, because the probes restore files from HEAD.
2. **State each property.** Write the property of each AC from the AC's text, never from the code, as [properties.md](properties.md) describes: precondition, action, postcondition, invariant, the change that would break it, and whether it needs generated inputs.
3. **Audit the tests.** For each AC, find the example test that asserts its postcondition, and the generated-input test when its property needs one, by the rules of properties.md. A missing or weaker test is a Finding. In the same diff, report each lowered bar as a Finding: a new skip, pending, focus or only, a deleted test or assertion, a coverage or mutation ignore, a lowered threshold.
4. **Run the tests.** Run each AC's tests on the recorded commit with the project's own test command. Run each generated-input test twice, each time with a seed you pick and record: `PROPERTY_SEED` for a seeded loop, the library's seed option otherwise. Record the runs and the discarded inputs.
5. **Measure changed-line coverage.** Collect the coverage of the AC tests:
   - Ruby: run them with `DISABLE_BOOTSNAP_COMPILE_CACHE=1 RUBYOPT="-r<this skill's folder>/coverage_preload.rb" COVERAGE_OUTPUT_DIR=<evidence folder>/coverage PARALLEL_WORKERS=1`. The preload uses Ruby's own `Coverage` module, so the project needs no coverage gem; bootsnap's compile cache fails to start while coverage runs, and one worker keeps every test in a measured process. When the project already runs SimpleCov, use its `.resultset.json` instead.
   - JavaScript and TypeScript: run the project's test runner with LCOV coverage into the evidence folder, such as `bun test --coverage --coverage-reporter=lcov --coverage-dir=<evidence folder>/coverage` or `vitest run --coverage.enabled --coverage.reporter=lcov --coverage.reportsDirectory=<evidence folder>/coverage`.

   Then run `ruby <this skill's folder>/changed_lines_coverage.rb <base commit> <coverage files>` from the repository root. It prints the covered and uncovered changed lines of each changed source file, and each changed source file the tests never loaded. Every changed executable line must be reached: each uncovered line is a Finding, unless you exclude it with a reason a reviewer can check, such as a branch for a failure the test environment cannot produce.
6. **Probe for mutants.** A mutation probe is one small breaking edit in a changed line of AC code, followed by that AC's tests. Probe every changed decision and side effect:
   - negate a condition, or swap `if` and `unless`;
   - move a boundary: `<` and `<=`, `>` and `>=`;
   - swap `&&` and `||`;
   - remove a guard clause or an early return;
   - replace a return value with `nil`, `null`, `false`, `0` or an empty collection;
   - remove a call with a side effect or a check: a save, an enqueue, a delivery, an authorization, a cache write, a state update.

   For each probe, apply the edit, run the AC's tests, record killed or survived, then restore the file with `git checkout -- <file>` and confirm `git diff --quiet`. Only a failing assertion kills a probe; a load or syntax error means the probe is broken, so fix it and run it again. Give each survivor one disposition:
   - **missing test:** a Finding that names the input that would kill it;
   - **equivalent:** the edit cannot change any behavior, proven in one line;
   - **simplify:** the code it touches does nothing, an Optional Finding.

   The score is killed / (probes - equivalent). It gives context and never decides the verdict: the gate is zero survivors without a disposition, and each AC's tests killing at least one probe on its code. When more than 30 probes qualify, probe every one in authorization, money and state code and an even sample of the rest, and list the rest as not probed. When the project already runs `mutant` or Stryker, run it on the change instead: `mutant run --since <base commit>`, or `stryker run --mutate <file>:<lines>` with its temp and report folders in the evidence folder.
7. **Check the Layer 2 triggers.** Layer 2 runs when the change adds or changes behavior with two or more steps or actors that can interleave or repeat, and one of these holds:
   - **Concurrency:** read-modify-write of shared rows across requests or jobs (`with_lock`, `lock!`, `lock_version`, counters), threads, or async client flows racing on shared state such as a cache or an optimistic update.
   - **State machine:** a status column with guarded transitions, or a client reducer with statuses.
   - **Retries:** job retries, retried HTTP or GraphQL calls, webhook redelivery.
   - **Idempotency:** idempotency keys, `find_or_create_by`, upserts, reliance on a unique index, at-least-once consumers.
   - **Money:** balances, ledgers, payments, refunds, currency conversion or rounding.

   When a trigger holds, model-check that behavior as [model-checking.md](model-checking.md) describes. Otherwise record each trigger you checked and why it does not hold.
8. **Decide each AC.**
   - **Proved:** its property is stated, its example test and any generated-input test pass, its tests killed at least one probe on its code, its changed lines are reached, every survivor in its code has a disposition, and its Layer 2 check, when triggered, found no violation.
   - **Failed:** a test, a probe gate or the model shows the code breaks its property.
   - **Unproved:** anything else. The Gaps section says what evidence is missing.

   Give each AC a confidence, CONFIDENT, NOT_CONFIDENT or UNSURE, that agrees with its evidence, and its evidence level: executed, loaded or only read. The verdict is PASS when every AC is proved and no blocking Finding remains, FAIL when an AC failed or a blocking Finding remains, and INCOMPLETE otherwise.
9. **Confirm the repository is unchanged.** `git status --porcelain` and `git rev-parse HEAD` must match step 1. Then write the report.

## Findings

Each Finding has a severity, a `file:line`, the AC it touches, the problem and a concrete fix.

- **Critical:** the code breaks a property, or the model finds a counterexample the code can follow.
- **Required:** a missing or weaker test, an uncovered changed line, a survivor without a killing test, a lowered bar.
- **Optional:** a simplify survivor.

Critical and Required Findings are blocking.

## Report

```markdown
# Verification

Commit: <sha>
Base commit: <sha>
Verdict: PASS | FAIL | INCOMPLETE
Metrics: <n>/<n> ACs proved; changed lines <covered>/<executable>; probes <killed>/<probes - equivalent> killed, <n> equivalent, <n> without disposition; <n> generated inputs per property; Layer 2: not triggered | <n> distinct states, depth <n>, no violation | gap

## Acceptance Criteria

### AC1 <the criterion in a few words>: proved | failed | unproved
- Property: given <precondition>, when <action>, then <postcondition>; invariant: <invariant | none>; breaks if: <change>
- Example test: `<file>` "<test name>": exit 0
- Generated-input test: `<file>` "<test name>": <runs> runs, seeds <seed>, <seed>, <n> discarded | not needed: <reason>
- Able to fail: killed probe P<n>
- Coverage: <covered>/<executable> changed lines
- Layer 2: <the promise checked> | not triggered
- Confidence: CONFIDENT | NOT_CONFIDENT | UNSURE, evidence <executed | loaded | read>: <one line>
- Not covered: <bounds, mocks and environments this proof leaves out>

## Probes
- P1 `<file>:<line>` <edit> (AC<n>): killed by "<test name>" | survived, missing test: Finding <n> | equivalent: <reason> | simplify: Finding <n>
- Not probed: <file:line list, only when sampled>

## Coverage
- `<file>`: <covered>/<executable>; uncovered <lines> | excluded <lines>: <reason>
- Not loaded by the tests: <files>

## Layer 2
- Triggers: <each trigger and whether it holds>
- <when run: the promise, constants, properties checked, distinct states, depth, run time, label-to-code map, what the model leaves out>

## Findings
1. <severity> `<file:line>` AC<n>: <problem>. Fix: <fix>

## Gaps
- <what could not run>: <why>; leaves <ACs> unproved

## Commands
- `<command>`: exit <code>, <evidence file>
```

Done when every AC has a property and a decision backed by evidence from the recorded commit, every probe has a result and every survivor a disposition, every changed source file has a coverage line or a gap, every Layer 2 trigger is checked, the repository matches step 1, and the report is written.
