# Verification skills survey

Survey of public agent skills about verification, test evidence and formal methods, for the Walkway "formal verification" skill that `walkway-validation` will load (Layer 1: AC as property, proven by example tests, property-based tests and mutation testing; Layer 2: TLA+ model checking when the diff touches concurrency, state machines, retries, idempotency or money).

All counts and file contents read on 2026-11-02. Stars come from `gh api repos/<owner>/<repo>`. Installs come from the skills.sh search API (`https://skills.sh/api/search?q=`). Locally installed copies: pstack 0.15.29 (GitHub is at 0.15.36), superpowers 7.0.0, compound-engineering 3.9.4.

## Summary

- Layer 1 has strong, widely used sources: Trail of Bits `property-based-testing` and `mutation-testing` (property catalog, tautology and vacuity checks, a five-check proof for equivalent mutants, severity by what the code does). The tool authors add stack-specific help: `mbj/mutant` for Ruby, with diff-scoped runs through `--since`, and `fast-check` for TypeScript, with `fc.scheduler` to reorder async steps.
- Layer 2 has no widely used TLA+ skill: every TLA+ skill on skills.sh has fewer than 20 installs. The useful guidance comes from reference authors: pstack `create-formal-verification-skill`, `maintain-formal-verification-skill` and `statechart`, the official `tlaplus/AgentSkills`, and `quint-co/quint` `quint-modeling` (prove reachability with witnesses before you trust invariants).
- The best evidence standards are superpowers `verification-before-completion` (fresh command output before any claim), Trail of Bits `post-patch-validation` (fail on base and pass on head, a printed marker that proves the assertion ran, a stated evidence level, gaps kept apart from findings) and Anthropic `patch-verifier` (reject by default, one confidence state with one line of evidence per claim, verbatim commands).
- At least eight skills share one rule: a check you never saw fail proves nothing. Each test, property, mutation gate or model must be shown to fail on a broken variant.
- Some skills already keep the workspace unchanged: mutant (mutations are monkeypatched into forked processes, source files are not touched), `post-patch-validation` (git worktrees), `patch-verifier` (scratch clone plus a `git status --porcelain` gate) and `statechart` (scratch folder outside the repo). Stryker writes `.stryker-tmp/` and `reports/` inside the project, so we must redirect them.
- Licenses: Trail of Bits skills are CC-BY-SA-4.0 (share-alike), so we take ideas only and write our own text. Mutant is under a commercial EULA that is free only for open-source projects, so private Rails apps need a license or a fallback. The other sources are MIT or Apache-2.0.
- No skill chains AC, property, PBT, mutation and metrics together. That is the gap our skill fills. Ruby PBT has no qualifying skill, and adding a PBT gem conflicts with "workspace unchanged".
- Metrics we can reuse: raw and equivalence-adjusted mutation score, each with its denominator (Trail of Bits); a disposition for each survivor plus before/after counts (coop, mutant); PBT run count, seed and shrunk counterexample; TLC bounds and distinct-state count; witness trace counts (Quint). Treat a threshold such as 60% to start or 80% for a mature suite (Addy) as a ratchet, not as proof that the tests are adequate.

## Selected skills

### pstack: create-formal-verification-skill

- Source: [cursor/plugins `pstack/skills/create-formal-verification-skill/SKILL.md`](https://github.com/cursor/plugins/blob/main/pstack/skills/create-formal-verification-skill/SKILL.md)
- Popularity: cursor/plugins 15,077 stars; 968 installs on skills.sh (2026-11-02)
- License: MIT (pstack `LICENSE` and `plugin.json`; the repo root has no license)
- Verifies: one high-value promise of the code (races, retries, state machines, parsers), and leaves behind a project-local verify skill.
- How: pick the target where a bug costs most and tests reach least; let the question pick the tool (TLA+ for "bad order of events", a code verifier for "every input", generated inputs if no verifier exists); run the generated skill once on a scratch break.
- Evidence standard: the check must catch a deliberately broken variant of the real code, then return to passing (or to the reported findings) after the break is dropped.
- Metrics: none numeric; it requires bounds, assumptions and a sync commit.
- Take: the seven qualities in "What makes it good" (lines 23-31): true to the code, able to fail, findings stay findings, honest about scope, readable without the tool, cheap to rerun, kept in step with the code. Also the "choose the strongest target, not the easiest" rule (line 17).
- Leave: generating a project-local skill, because Walkway's skill runs per issue and must not add files to the repo; the sync-commit record only matters if models persist across issues.

### pstack: maintain-formal-verification-skill

- Source: [cursor/plugins `pstack/skills/maintain-formal-verification-skill/SKILL.md`](https://github.com/cursor/plugins/blob/main/pstack/skills/maintain-formal-verification-skill/SKILL.md)
- Popularity: 822 installs (2026-11-02); repo as above
- License: MIT
- Verifies: that an existing model still describes the code after changes.
- How: run the check as it is first; read every change to covered code and classify it (no effect, model stale, promise changed on purpose, promise maybe broken); update the model from the code, not from the result, then rerun.
- Evidence standard: a pass after an update must be re-proven by breaking the new code; a failure must be replayed step by step against the real code before calling it a bug.
- Metrics: one outcome per check: in sync, updated, bug, blocked.
- Take: the outcome vocabulary ("Outcomes", lines 13-22); "a pass on a stale description looks like a proof" framing; the rule to replay each counterexample against real code (Pass step 5, line 42); "update from the code, not from the result" (step 4, line 40).
- Leave: the multi-commit drift hunt; Validation sees one diff per cycle.

### pstack: create-verification-skill and maintain-verification-skill

- Source: [create](https://github.com/cursor/plugins/blob/main/pstack/skills/create-verification-skill/SKILL.md), [maintain](https://github.com/cursor/plugins/blob/main/pstack/skills/maintain-verification-skill/SKILL.md)
- Popularity: 4,623 and 4,177 installs (2026-11-02)
- License: MIT
- Verifies: real app behavior by driving it the way a user does (UI, CLI, API).
- How: read launch/drive/observe from the repo, not the user; write Launch, Doctor, Drive, Evidence, Cleanup sections; prove it by running it once end to end.
- Evidence standard: real user path, not test-only endpoints; capture the action and the resulting state; check side effects (rows, messages) next to what is visible; verify what a dry-run really skips; evidence survives cleanup.
- Metrics: none; outcomes clean, changed, blocked.
- Take: the proof standards in "Evidence" (line 32), "Doctor before driving" (line 30), "kill only what you started" (line 33), and "a journey that lacks a precondition reports failure, never a weaker journey" (section 3).
- Leave: the feature map and generated skill; Walkway Validation already maps each AC to a route and drives it through Orca.

### pstack: principle-test-behavior-not-implementation

- Source: [cursor/plugins `pstack/skills/principle-test-behavior-not-implementation/SKILL.md`](https://github.com/cursor/plugins/blob/main/pstack/skills/principle-test-behavior-not-implementation/SKILL.md)
- Popularity: 2,351 installs (2026-11-02)
- License: MIT
- Verifies: that a test asserts what users of the code can observe.
- How: judge each test with two imagined edits: break the behavior (the test must fail) and change the internals (the test must pass).
- Evidence standard: the test catches the first edit and survives the second.
- Metrics: none.
- Take: the two-edit test (lines 13-14) as the definition of a good example test; "the contract decides" (line 18), including pairing a "never charges" assertion with a case where the charge happens so the test shows it can see the call.
- Leave: nothing; it is short and fully compatible.

### pstack: statechart

- Source: [cursor/plugins `pstack/skills/statechart/SKILL.md`](https://github.com/cursor/plugins/blob/main/pstack/skills/statechart/SKILL.md) (only in GitHub 0.15.36, not in the local 0.15.29)
- Popularity: 666 installs (2026-11-02)
- License: MIT
- Verifies: rules of a state-machine model with TLC, and draws the result as a Mermaid statechart with the shortest path to each broken rule.
- How: write the spec in a scratch folder outside the repo; each agreed rule is an INVARIANT; mark correct end states with an explicit `Done` action so they are not reported as deadlocks; run the bundled script.
- Evidence standard: replay each bug path against the real code as a test or live repro, one step per action; if it does not reproduce, assume the model is wrong until shown otherwise.
- Metrics: TLC state count; "Rules not checked" when a 100,000-state bound or error stops a run.
- Take: scratch folder outside the repo ("Run"); "never weaken a rule" and the `Done` action trick ("Write the spec"); listing rules not checked ("Read the report"); a statechart of the bug path for the PR reader.
- Leave: its TypeScript runner, mise install and Pele renderer; we need only plain TLC.

### superpowers: verification-before-completion

- Source: [obra/superpowers `skills/verification-before-completion/SKILL.md`](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md)
- Popularity: 310,861 stars; 261,397 installs (2026-11-02)
- License: MIT
- Verifies: any success claim (tests pass, bug fixed, requirement met, agent done).
- How: a five-step gate: identify the proving command, run it fully, read all output and the exit code, compare with the claim, only then state it.
- Evidence standard: output from a command run in the current message; a regression test proven by revert-fail-restore-pass; delegated work checked through the VCS diff.
- Metrics: failure counts and exit codes as read from output.
- Take: "The Gate Function"; the claim-to-evidence table in "Common Failures" (for example "requirements met" needs a line-by-line checklist, not green tests); the red-flag words ("should", "probably"); the regression pattern under "Key Patterns".
- Leave: the motivational tone and the rationalization table length; Validation already states the core rule.

### superpowers: test-driven-development (with writing-good-tests.md)

- Source: [SKILL.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md), [writing-good-tests.md](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/writing-good-tests.md)
- Popularity: about 267,200 installs (skills.sh home page, 2026-11-02); repo as above
- License: MIT
- Verifies: that each test fails first, for the expected reason, then passes.
- How: red, verify red, green, verify green, refactor; before each test body, name the production change that would make it fail.
- Evidence standard: the test was seen failing because the feature was missing, not because of a typo; the whole project suite passes, and failures you did not cause are reported by name.
- Metrics: none numeric.
- Take: the "Name the Break" gate and "derive expectations independently" (writing-good-tests.md, Principle 1); "The Mutation Check" list (wrong constant, wrong branch, missing side effect, empty return, missing validation); "a red test you saw and did not mention falsifies the report" (Verify GREEN).
- Leave: "delete code and start over"; the verifier does not write product code.

### compound-engineering: ce-test-browser

- Source: [EveryInc/compound-engineering-plugin `skills/ce-test-browser/SKILL.md`](https://github.com/EveryInc/compound-engineering-plugin/blob/main/skills/ce-test-browser/SKILL.md)
- Popularity: 25,846 stars; 3,073 installs (2026-11-02)
- License: MIT
- Verifies: pages affected by a branch or PR, in a real browser.
- How: diff to changed files, map files to routes, check root is served, visit each route, exercise critical interactions, screenshot, summarize Pass/Fail/Skip.
- Evidence standard: every affected route ends Pass, Fail or Skip with a reason; dropping a route from the summary is a failure (current "Done" line on GitHub).
- Metrics: pages tested, console errors, failures, human verifications.
- Take: the file-to-route mapping for Rails and React (3.9.4 step 4 table; GitHub `references/route-and-report.md`); "no route silently dropped"; pipeline mode logs external flows (OAuth, payments) as Skip with a reason instead of blocking.
- Leave: the `agent-browser` driver and headed/headless question (Walkway uses Orca); "Fix now" (the verifier never fixes).

### compound-engineering: testing reviewer persona

- Source: local `agents/ce-testing-reviewer.md` (3.9.4); now [`skills/ce-code-review/references/personas/testing-reviewer.md`](https://github.com/EveryInc/compound-engineering-plugin/blob/main/skills/ce-code-review/references/personas/testing-reviewer.md)
- Popularity: repo as above (persona, no install count)
- License: MIT
- Verifies: test gaps in a diff: untested branches, false-confidence tests, brittle tests, missing error paths, behavior changes with no test changes.
- How: trace each new branch to a test; anchor confidence at 100/75/50/25 by how provable the gap is from the diff.
- Evidence standard: a gap counts only when it is provable from the diff (anchor 75 or higher).
- Metrics: confidence anchors per finding.
- Take: "behavioral changes with no test additions"; the newer GitHub items: a negative case rejected by a different guard than the one the test names, test-only production seams, nondeterministic tests; "do not flag coverage % targets".
- Leave: JSON finding schema and confidence anchors; Walkway uses `findings.md` severities.

### Addy Osmani: test-driven-development

- Source: [addyosmani/agent-skills `skills/test-driven-development/SKILL.md`](https://github.com/addyosmani/agent-skills/blob/main/skills/test-driven-development/SKILL.md)
- Popularity: 112,640 stars; 66,678 installs (2026-11-02)
- License: MIT
- Verifies: behavior through red-green-refactor and the "Prove-It" pattern for bugs.
- How: discover the repo's own test commands first; write the reproduction test; see it fail; fix; run the full suite.
- Evidence standard: a bug fix includes a test that failed before the fix; the repo's own full-suite command passes.
- Metrics: coverage must not fall (if tracked).
- Take: "Discover the Stack First" (use checked-in wrappers and CI commands, never assume `npm test`); "exercise the real boundary: an injected exception is not a crash, a mocked transaction is not a rollback" (Prefer Real Implementations); the reproduction test written by a subagent that does not know the fix.
- Leave: the test pyramid percentages and generic style rules.

### Addy Osmani: constraint-driven-development

- Source: [addyosmani/agent-skills `skills/constraint-driven-development/SKILL.md`](https://github.com/addyosmani/agent-skills/blob/main/skills/constraint-driven-development/SKILL.md)
- Popularity: 37,910 installs (2026-11-02)
- License: MIT
- Verifies: that a written quality bar holds and is not quietly lowered.
- How: record thresholds in `CONSTRAINTS.md`; scope expensive checks to the diff (`stryker run --mutate <changed files>`); watch the diff for weakened checks.
- Evidence standard: each enforced command must fail on a deliberate violation and on a scanner error, and pass a clean control.
- Metrics: mutation score defaults: 60% or more to start, 80% for a mature suite; changed-line coverage of 80% or more; ratchet tolerance of 0.5%.
- Take: "Guard the bar itself" (Step 6, line 209): skips, deleted tests, stripped assertions, new suppressions such as `Stryker disable` and `istanbul ignore`; the external-vs-suite circularity ranking (an agent can pass its own tests with broken code); "cost decides placement" (Step 5); "Sane Defaults" (line 241) as ratchets.
- Leave: writing `CONSTRAINTS.md` and editing AGENTS.md (changes the workspace); the interview needs a live user.

### Addy Osmani: doubt-driven-development

- Source: [addyosmani/agent-skills `skills/doubt-driven-development/SKILL.md`](https://github.com/addyosmani/agent-skills/blob/main/skills/doubt-driven-development/SKILL.md)
- Popularity: 61,208 installs (2026-11-02)
- License: MIT
- Verifies: non-trivial claims through a fresh-context reviewer that tries to disprove them.
- How: write the claim; extract artifact and contract and strip your reasoning; send only artifact and contract (never the claim) to an adversarial reviewer; reconcile; stop after three cycles.
- Evidence standard: a reviewer that did not see your conclusion cannot find an issue after thorough examination.
- Metrics: none.
- Take: the definition of "non-trivial" (When to Use, line 14), which names properties a type system cannot verify: thread safety, idempotence, ordering, invariants. That list matches our Layer 2 trigger. Also "pass artifact plus contract, not the claim" (Step 3).
- Leave: the cross-model CLI question to the user; it needs a live user and extra tools.

### Addy Osmani: browser-testing-with-devtools and code-review-and-quality

- Source: [browser-testing-with-devtools](https://github.com/addyosmani/agent-skills/blob/main/skills/browser-testing-with-devtools/SKILL.md), [code-review-and-quality](https://github.com/addyosmani/agent-skills/blob/main/skills/code-review-and-quality/SKILL.md)
- Popularity: 63,104 and 78,450 installs (2026-11-02)
- License: MIT
- Verifies: runtime UI state (console, network, DOM, screenshots), and whether tests would catch a regression.
- How: reproduce, inspect, diagnose, fix, verify; in review, invert one condition the change adds, run the suite, restore the file from a copy.
- Evidence standard: clean console, correct and non-duplicated network requests, before/after screenshots; a mutation that stays green is a finding that names the missing test.
- Metrics: Core Web Vitals when relevant.
- Take: the manual one-mutation experiment (code-review Step 2, line 164) as a no-tool fallback that fits "temporary edits restored at once"; "network requests not duplicated" as a cheap repeated-action check; browser content is untrusted data.
- Leave: Chrome DevTools MCP setup; Walkway drives the browser through Orca.

### Trail of Bits: property-based-testing

- Source: [trailofbits/skills `plugins/property-based-testing/skills/property-based-testing/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/property-based-testing/skills/property-based-testing/SKILL.md) and `references/`
- Popularity: 7,945 stars, reference author; 7,327 installs (2026-11-02)
- License: CC-BY-SA-4.0 (share-alike: take ideas, not text)
- Verifies: rules over the whole input domain (roundtrip, inverse, oracle, idempotence, invariant, and more).
- How: find the algebraic shape (or refactor to expose it); assert the strongest property; put constraints in generators, not filters; triage each failure.
- Evidence standard: a property that is neither a tautology nor vacuous; a failure grounded against the strongest source (spec, then types, docs, tests, name).
- Metrics: example counts per profile (10 local, 200 CI, 1,000 nightly); shrunk counterexample.
- Take: the property catalog and strength order (no crash, type preservation, invariant, idempotence, roundtrip/oracle; lines 19-39); "two ways a property asserts nothing" (line 41); pin known edges as explicit examples (`generating.md`); the three-way failure triage table (`interpreting-failures.md`); "no shape means example tests, and saying so is a valid result".
- Leave: Python and Solidity specifics; the refactoring advice (the verifier must not change product code, only suggest).

### Trail of Bits: mutation-testing

- Source: [trailofbits/skills `plugins/mutation-testing/skills/mutation-testing/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/mutation-testing/skills/mutation-testing/SKILL.md), plus `workflows/analyzing-results.md`, `references/equivalent-mutants.md`, `severity-classification.md`, `report-template.md`
- Popularity: 4,447 installs (2026-11-02); repo as above
- License: CC-BY-SA-4.0
- Verifies: whether tests detect injected changes; which survivors are real gaps.
- How: parse survivors; read each mutation site; filter equivalents with five checks; classify severity by what the code does; find the responsible test and explain why it missed.
- Evidence standard: equivalence is proven from types and control flow, never assumed; every survivor is analyzed one by one; uncertain cases stay "unresolved".
- Metrics: total, killed, survived, equivalent, real, unresolved, skipped or timeout; raw and adjusted kill rate, each with its denominator.
- Take: the five-check equivalence procedure (type context, reachability, downstream use, semantic comparison, distinguishing-input attempt); "looks equivalent but is not" (boundary `>` vs `>=`); the four tiers (security, money/state, business, observability); "Rationalizations to Reject" (line 20), for example "above 80% means adequate"; Phase 6 rule that a rate never proves overall adequacy; "no test touches it" is a stronger finding than a weak assertion.
- Leave: mewt/muton (no Ruby support); blockchain references; writing `mutation-testing-report.md` into the working directory.

### Trail of Bits: genotoxic

- Source: [trailofbits/skills `plugins/trailmark/skills/genotoxic/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/trailmark/skills/genotoxic/SKILL.md)
- Popularity: 4,023 installs (2026-11-02)
- License: CC-BY-SA-4.0
- Verifies: survivors and unnecessary test statements, triaged with call-graph data.
- How: build a graph with trailmark; run mutation testing and necessist (removes test statements); classify as corroborated, false positive, missing test, fuzz target.
- Evidence standard: tool output; it forbids "manual analysis" as a fallback for a missing tool.
- Metrics: counts per category.
- Take: "a tool is missing" is reported as a gap, never replaced by a quiet manual guess; mutant is the named Ruby framework and Stryker the TS one (`references/mutation-frameworks.md`).
- Leave: trailmark and necessist (no Ruby; extra installs).

### Trail of Bits: post-patch-validation

- Source: [trailofbits/skills `plugins/post-patch-validation/skills/post-patch-validation/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/post-patch-validation/skills/post-patch-validation/SKILL.md), `references/evidence-model.md`
- Popularity: 937 installs (2026-11-02); reference author
- License: CC-BY-SA-4.0
- Verifies: a fix, by comparing the base and patched revisions with pinned commits.
- How: scaffold a plan with seven check kinds (control, exploit, variant, behavior, regression, security, suite); run each on both revisions in isolated worktrees; assess.
- Evidence standard: the exploit check fails on base and passes on patch; it prints a marker line right before the assertion, so a build or import error cannot pose as a reproduction; checks are blind to which side they run on; evidence level is declared (source, build, runtime).
- Metrics: status complete or incomplete; findings and gaps listed separately; exit codes 0/1/10/64.
- Take: base-vs-head differential ("Evidence Contract", line 85) mapped to "each AC test fails on the base commit"; the reached marker (line 109); evidence levels; "a gap and a finding can coexist"; "a flaky rerun that passes does not replace the first pinned result" (line 250); validation never edits the original worktree.
- Leave: the Python runner and the security framing; side-blind execution is more than we need.

### Trail of Bits: spec-to-code-compliance

- Source: [trailofbits/skills `plugins/spec-to-code-compliance/skills/spec-to-code-compliance/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/spec-to-code-compliance/skills/spec-to-code-compliance/SKILL.md)
- Popularity: 6,033 installs (2026-11-02)
- License: CC-BY-SA-4.0
- Verifies: each requirement in a document against the code, in both directions.
- How: split the spec into checkable requirements; one agent per requirement; independent agents try to refute every divergence.
- Evidence standard: an `absent` verdict carries the searches tried; a divergence survives only if agents that did not produce it fail to knock it down.
- Metrics: one of six verdicts per requirement.
- Take: the verdict set (implemented, partial, contradicted, stronger-than-spec, absent, undecidable) as a richer per-AC result; "partial is usually the most serious"; "undecidable is a finding about the requirement" (maps to Walkway Escalation); one context per requirement because honest checking does not fit in one window.
- Leave: the Workflow script and smart-contract focus.

### Trail of Bits: writing-lean-proofs

- Source: [trailofbits/skills `plugins/writing-lean-proofs/skills/writing-lean-proofs/SKILL.md`](https://github.com/trailofbits/skills/blob/main/plugins/writing-lean-proofs/skills/writing-lean-proofs/SKILL.md)
- Popularity: 1,351 installs (2026-11-02)
- License: CC-BY-SA-4.0
- Verifies: Lean 4 theorems and library hygiene.
- How: design statements first, build a `sorry` skeleton, fill goals, verify mechanically.
- Evidence standard: ask the kernel for the axiom footprint, never grep for `sorry`; a green build can still hide unproved goals.
- Metrics: axiom footprint; heartbeat counts.
- Take: "a check that cannot fail proves nothing" and "ask the tool, not grep" (Rationalizations table, Step 4); for TLC this means reading its summary lines (states found, invariants checked), not searching for "Error".
- Leave: everything Lean-specific; wrong stack.

### Anthropic: webapp-testing

- Source: [anthropics/skills `skills/webapp-testing/SKILL.md`](https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md)
- Popularity: 186,523 stars; 195,126 installs (2026-11-02)
- License: Apache-2.0 (skill `LICENSE.txt`)
- Verifies: local web apps with Python Playwright scripts.
- How: decision tree (static HTML or dynamic; server running or not); `with_server.py` owns the server lifecycle; reconnaissance first, then action.
- Evidence standard: screenshots, DOM and console logs; no explicit pass bar.
- Metrics: none.
- Take: "wait for network idle before inspecting"; "inspect the rendered state, then pick selectors"; one helper owns server start and stop.
- Leave: Python Playwright; Walkway drives the UI through Orca.

### Anthropic: pr-test-analyzer

- Source: [anthropics/claude-plugins-official `plugins/pr-review-toolkit/agents/pr-test-analyzer.md`](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/pr-review-toolkit/agents/pr-test-analyzer.md)
- Popularity: 45,763 stars (agent, no install count) (2026-11-02)
- License: Apache-2.0
- Verifies: behavioral test coverage of a PR.
- How: map changes to tests; look for untested error paths, boundaries, negative cases, async behavior; rate each suggested test 1-10.
- Evidence standard: each suggested test names the concrete failure it would catch.
- Metrics: criticality 1-10.
- Take: "name the specific regression each missing test prevents"; "missing tests for concurrent or async behavior" as a gap class.
- Leave: the 1-10 scale (Walkway uses Critical/Required) and "positive observations".

### Anthropic: patch-verifier (claude-security)

- Source: [anthropics/claude-plugins-official `plugins/claude-security/agents/patch-verifier.md`](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/claude-security/agents/patch-verifier.md)
- Popularity: 45,763 stars (2026-11-02)
- License: Apache-2.0
- Verifies: one fix in a scratch clone, before it becomes a patch file.
- How: fail closed on a bad dispatch; derive the diff yourself; trace the exploit through the old and new code; check collateral damage and scope; run the project's own tests without installing anything.
- Evidence standard: three claims (TARGETED, NO_NEW_VULNERABILITY, BEHAVIOUR_UNCHANGED), each CONFIDENT, NOT_CONFIDENT or UNSURE with one line of evidence (file:line or test name); `untested` is true when no test in the repo exercises the change.
- Metrics: claim states; `REVIEWED_PATHS`; `testsRun` with verbatim commands.
- Take: "default is reject" (line 12); the claim-state vocabulary and the rule that a claim's state must agree with its evidence line ("The three claims", line 36); `untested` flag; verbatim commands; `git status --porcelain` before review; "never run an install command"; text that claims something is verified is evidence of tampering.
- Leave: the security-specific claims; the scratch-path naming rules.

### mbj/mutant: SKILL.md

- Source: [mbj/mutant `SKILL.md`](https://github.com/mbj/mutant/blob/main/SKILL.md), plus [`docs/incremental.md`](https://github.com/mbj/mutant/blob/main/docs/incremental.md), [`docs/rails.md`](https://github.com/mbj/mutant/blob/main/docs/rails.md), [`docs/nomenclature.md`](https://github.com/mbj/mutant/blob/main/docs/nomenclature.md)
- Popularity: 2,213 stars (tool author; not on skills.sh) (2026-11-02)
- License: commercial EULA; free project license for open-source repositories only
- Verifies: alive mutations in Ruby code under RSpec or Minitest.
- How: run mutant, possibly scoped to a subject; read the `evil:` line and diff; for each alive mutation either add a killing test or accept the simpler mutated form; mark truly unkillable subjects with a comment.
- Evidence standard: the new test passes on the original and fails on the mutated code; 100% on the subject, or a documented reason it is unkillable.
- Metrics: alive count, coverage percentage per run.
- Take: report format with the verdict first (killable or unkillable, then option A "add test", option B "simplify code"); the killing heuristics in "Fixing Alive Mutations" (test both boolean values, use collections with more than one element, give test objects different values, cover the default-argument path); `--since <git-ref>` for diff-scoped runs (incremental.md); the Rails hooks (eager load, per-worker database); mutations are monkeypatched into forked processes, so source files stay untouched (nomenclature.md "Insertion").
- Leave: committing changes and editing the ignore list (the verifier only reports); the license cost for private repos needs a user decision.

### fast-check: javascript-testing-expert

- Source: [dubzzz/fast-check `skills/javascript-testing-expert/SKILL.md`](https://github.com/dubzzz/fast-check/blob/main/skills/javascript-testing-expert/SKILL.md)
- Popularity: 5,226 stars; 262 installs (2026-11-02)
- License: MIT
- Verifies: JS/TS functions and components with example tests and properties.
- How: documentation-like example tests first, then property tests; control time and randomness through generators; test async ordering with `fc.scheduler`.
- Evidence standard: a test must break when you drop the thing that makes it pass (Core guidelines).
- Metrics: none beyond runner output; fast-check reports seed and shrunk counterexample.
- Take: "a test named always or never becomes a property" (line 162); the five classical property families ("Guidelines for properties", line 200); no artificial `maxLength` or bounds that the requirement does not state; prefer arbitrary options over `.filter`; generated "today" instead of a fixed fake clock; `fc.scheduler` for race conditions ("Guidelines for race conditions", line 249), a cheap concurrency check for React and GraphQL client code before Layer 2.
- Leave: the advice to install tooling (conflicts with "workspace unchanged"); Vitest-specific layout rules.

### recharts: mutation-testing

- Source: [recharts/recharts `.agents/skills/mutation-testing/SKILL.md`](https://github.com/recharts/recharts/blob/main/.agents/skills/mutation-testing/SKILL.md)
- Popularity: 27,681 stars, repo-local skill (2026-11-02)
- License: MIT
- Verifies: TS test strength with Stryker, one file or glob at a time.
- How: mutate only named files from the CLI; skip the TypeScript checker while iterating; use `--incremental`; read `reports/mutation/mutation.json`.
- Evidence standard: a test whose assertion fails under the mutation and passes on the real code.
- Metrics: mutation score per file; killed, survived, no coverage.
- Take: CLI scope instead of editing config; JSON report for metrics; "no coverage" needs a test that runs the branch and asserts, not one that only flips the status.
- Leave: repo-specific scripts; reports and `.stryker-tmp/` inside the project.

### Trail of Bits: coop mutation-check

- Source: [trailofbits/coop `.agents/skills/mutation-check/SKILL.md`](https://github.com/trailofbits/coop/blob/main/.agents/skills/mutation-check/SKILL.md)
- Popularity: 803 stars; reference author (2026-11-02)
- License: Apache-2.0
- Verifies: mutation coverage of changed Rust logic with cargo-mutants.
- How: inspect the diff first; exclude I/O shells and test their extracted pure logic; sweep touched files; triage `missed.txt`.
- Evidence standard: each new test is confirmed by re-running the mutant or breaking the behavior on purpose.
- Metrics: files swept, missed count before and after, disposition for every survivor.
- Take: the five-line report shape (step 5); "do not pipe a long run through head or grep, redirect to a file"; skip I/O-heavy code and say so instead of running a useless sweep.
- Leave: Rust tooling.

### Quint: quint-modeling

- Source: [quint-co/quint `skills/quint-modeling/SKILL.md`](https://github.com/quint-co/quint/blob/main/skills/quint-modeling/SKILL.md)
- Popularity: 1,900 stars; 9 installs (90 for the quint-llm-kit copy) (2026-11-02)
- License: Apache-2.0
- Verifies: a model of a protocol or state machine, built from an idea, requirements, code or TLA+.
- How: separate concerns; shape state; pure functions; guarded actions; witnesses, then invariants; simulate; self-review.
- Evidence standard: every action has a witness reached in more than 0 traces; at least one protocol-level invariant (not a type check); a short trace is a hidden deadlock signal.
- Metrics: witness trace counts (for example 90 of 100); violations with traces.
- Take: "witnesses first" (Step 5, line 303); a witness that already holds at init proves nothing; terminal states vs deadlock (line 374); the hand-off record: what it covers, what it does NOT cover, when to update (Step 7, line 401); "the spec is ground truth; never edit it to match broken code".
- Leave: Quint syntax and simulation-only policy; user chose TLA+ with TLC by default.

### tlaplus/AgentSkills: tlaplus-from-source (with split-action, add-variable)

- Source: [tlaplus/AgentSkills `skills/tlaplus-from-source/SKILL.md`](https://github.com/tlaplus/AgentSkills/blob/main/skills/tlaplus-from-source/SKILL.md), [README](https://github.com/tlaplus/AgentSkills/blob/main/README.md)
- Popularity: 44 stars, but reference author (official TLA+ organization; tlaplus/tlaplus has 3,172 stars) (2026-11-02)
- License: MIT
- Verifies: a high-level TLA+ model derived from code, with proposed safety and liveness properties.
- How: understand the code (functions, state, concurrency patterns); choose abstractions; write the spec and parse with SANY; propose invariants and check with TLC (MCP tools).
- Evidence standard: SANY parse and TLC check; small bounds first; TypeOk holds.
- Metrics: none stated beyond TLC output.
- Take: the code-to-TLA+ mapping tables (Steps 2.1-2.2); a `Source: function() in file` comment on each action; "a mutex-protected region is one action"; `split-action` for finer atomicity (for Rails, a check-then-act across two requests is two actions); common pitfalls (missing UNCHANGED, unbounded state).
- Leave: C/C++/Rust examples; the VS Code MCP dependency (use `tla2tools.jar` directly).

### mattpocock/skills: tdd

- Source: [mattpocock/skills `skills/engineering/tdd/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md)
- Popularity: 309,560 stars; 1,184,170 installs (2026-11-02)
- License: MIT
- Verifies: behavior through public interfaces, one vertical slice at a time.
- How: agree the seams first; one test, one implementation per cycle; refactoring is left to review.
- Evidence standard: red before green; expected values from an independent source.
- Metrics: none.
- Take: the tautology definition ("Anti-patterns"): an assertion that recomputes the expected value the way the code does; "seam" as the place for AC properties (request spec, GraphQL schema execution, React component through Testing Library); use `GLOSSARY.md` terms in test names.
- Leave: confirming seams with the user (Validation runs unattended).

### ECC: verification-loop

- Source: [affaan-m/ECC `.agents/skills/verification-loop/SKILL.md`](https://github.com/affaan-m/ECC/blob/main/.agents/skills/verification-loop/SKILL.md)
- Popularity: 295,048 stars; 11,872 installs (2026-11-02)
- License: MIT
- Verifies: build, types, lint, tests, secrets, diff before a PR.
- How: six phases with fixed commands; one report block.
- Evidence standard: weak; it trims output with `head` and `tail`.
- Metrics: pass/fail per phase, coverage % (80% target).
- Take: report target acceptance (staging, production) separately from local checks, with "not performed" and the next permitted step ("Target Acceptance").
- Leave: everything else; generic, Node-centric, and output truncation can hide failures.

## Skipped candidates

- StanfordLegion/legion `tla/skills/tlc-model-checking`: 774 stars, not a reference author.
- nWave-ai/nWave `nw-tlaplus-verification`, `nw-formal-verification-tlaplus`: 628 stars; 10-13 installs.
- younes-io/agent-skills `tla-check`, `tlaplus-workbench`: 21 stars; 4-6 installs.
- jonmumm/skills `tlaplus`, melodic-software/claude-code-plugins `tla-specification`: 16 installs each, no 1k-star repo.
- ArabelaTso/Skills-4-SE (TLA+, Dafny, property generators): 260 stars; 4-5 installs.
- OutlineDriven/odin-claude-plugin and outline-driven-development (TLA+, Dafny/Why3, Z3): 40 and 56 stars.
- Beneficial-AI-Foundation/formal-verification-skills: 23 stars.
- gokeshenzhen/awesome-formal-verification-skill: 36 stars.
- linn0x/engineering-verification-loop (TLA+, Dafny): 6 stars; 1 install.
- muloka/model-check-skills (Dafny): 2 stars.
- joshft/correctless `cmodel` (Alloy): 65 stars.
- adzerk/spec-driven-workshop `alloy`, LabLambWorks/alloy6-skill: 15 and 0 stars.
- quint-co/quint-llm-kit: 115 stars, about 90 installs; same team's skills in quint-co/quint were analyzed instead.
- citypaul/.dotfiles `mutation-testing`, `tdd`: 759 stars; 184 installs.
- thibautbaissac/rails_ai_agents `mutation-testing` (Rails): 671 stars; 32 installs.
- RailsEventStore/ecommerce skills that run mutant: 507 stars.
- discourse/markbridge `.claude/skills/mutant`: 1 star (Discourse org, small repo).
- secondsky/claude-skills `mutation-testing`: 242 stars; 442 installs.
- lvlup-sw/exarchos `mutation-adequacy`, `invariants`: 22 stars; 207 installs.
- laurigates/claude-plugins `property-based-testing`: 59 stars; 72 installs.
- meganemura/hegel-ruby skill: 1 star.
- ohbarye/pbt (Ruby PBT gem): a library, not a skill; 241 stars. Note it as a tool option.
- foryourhealth111-pixel/Vibe-Skills `property-based-testing`: passes (3,788 stars) but is a bundled generic tutorial with no evidence standard; Trail of Bits and fast-check cover it better.
- jeremylongshore/tons-of-skills-marketplace `proof-strategy`, `fuzzing-apis`: passes (2,890 stars) but is an aggregator; test-strategy prose with no proof standard.
- a5c-ai/babysitter `stryker-mutation`: passes (1,889 stars) but has 1 install and duplicates recharts and Addy.
- majiayu000/claude-skill-registry, proffesor-for-testing/agentic-qe, vibeeval/vibecosystem: 707, 522 and 541 stars; mirrors or low adoption.
- CircleCI-Public/chunk-cli `chunk-testing-gaps`: 87 stars.
- Trail of Bits `testing-handbook-skills` (AFL++, libFuzzer, sanitizers, coverage), `fp-check`, `regression-hunt`: reference author, but C/C++/Rust fuzzing and security triage, outside our stack.
- pstack `tdd` (3,645 installs): bug-fix TDD only; covered by superpowers and mattpocock.
- pstack `principle-prove-it-works` (5,257 installs): its one extra idea ("script the check, keep the output for re-runs") is merged below; no separate section.
- github/awesome-copilot `webapp-testing` (12,490 installs): a copy of Anthropic's skill.
- microsoft/playwright-cli, vercel-labs/agent-browser, currents-dev playwright-best-practices: browser drivers, not verification methods; Walkway drives the UI through Orca.
- dotnet/skills `property-patterns`: .NET-specific.

## Ideas to merge

### Layer 1: AC as property, examples, PBT, mutation

- Write each AC as a property before choosing tests: precondition, action, postcondition, invariant, plus "the production change that would make it fail". Sources: pstack principle (two edits), superpowers writing-good-tests (Name the Break), Trail of Bits PBT.
- Pick the strongest property the AC supports (no crash < type preservation < invariant < idempotence < roundtrip/oracle); say "examples only" when the AC has no such shape. Sources: Trail of Bits PBT catalog, fast-check property families.
- AC wording with "always", "never", "any", "every" becomes a property test; other ACs get example tests at a seam (request spec, GraphQL schema execution, component through Testing Library). Sources: fast-check, mattpocock tdd.
- Expected values come from the AC or a hand-checked literal, never from the code under test or its helpers. Sources: superpowers, mattpocock, Trail of Bits (tautology).
- Guard against vacuous properties: constraints live in generators, not filters; record generated runs and discarded inputs; pin known edges (empty, one, duplicates, zero, negative, max, nil) as explicit examples. Sources: Trail of Bits `generating.md`, fast-check.
- Generate time, locale and order instead of fixing them (`travel_to` with a generated time; `vi.setSystemTime` with a generated date). Source: fast-check.
- Triage each property failure as wrong property, ambiguous AC or code bug, grounded spec > types > docs > tests > name; an ambiguous AC becomes a Walkway Escalation, a code bug becomes a `findings.md` row. Source: Trail of Bits `interpreting-failures.md`.
- Pair every "it never does X" assertion with a case where X happens, so the test shows it can observe X. Source: pstack principle.
- Scope mutation to the diff: `bundle exec mutant run --since <base>` for Ruby, `stryker run --mutate <changed files> --incremental` for TS; never a whole-repo run. Sources: mutant `incremental.md`, Addy CDD, recharts.
- Give each surviving mutant one disposition: killed by a named new test, equivalent (with the five-check proof), unresolved (with the missing evidence), or "simplify" (a suggestion only, since the verifier does not change product code). Sources: Trail of Bits mutation-testing, mutant, coop.
- Rank survivors by what the code does (auth, money and state, business logic, observability), not by mutation operator; auth and money survivors on AC code are blocking. Source: Trail of Bits `severity-classification.md`.
- "No coverage" survivors are stronger findings than weak assertions. Sources: Trail of Bits Phase 5, recharts.
- When no mutation tool can run (for example a private Rails repo without a mutant license), do a manual mutation: invert one condition per AC, run the AC's tests, restore the file at once, record the result. Sources: Addy code-review Step 2, superpowers Mutation Check.
- Use mutant's killing heuristics when a survivor needs a test: both boolean values, collections with more than one element, test objects with different values, default-argument path. Source: mutant SKILL.md.
- In TS, test async ordering of the changed code with `fc.scheduler` before deciding Layer 2 is needed. Source: fast-check.

### Layer 2: model checking

- Trigger list: the diff asserts something a type system cannot check: thread safety, idempotence, ordering, retries, state transitions, money invariants. Sources: Addy doubt-driven ("non-trivial"), pstack create-formal.
- Model the strongest promise, not the easiest one. Source: pstack create-formal.
- Keep the spec, config and TLC output in a scratch folder outside the repo; copy only the evidence into the Task folder. Sources: pstack statechart, Anthropic patch-verifier.
- True to the code: each action carries a `Source:` reference to a file and method; one database transaction or lock is one action; a read-then-write across requests or jobs is two actions. Sources: tlaplus-from-source, tlaplus-split-action, pstack create-formal.
- Witnesses first: show each action can fire (reachability), then check invariants; a witness true at Init proves nothing. Source: Quint modeling.
- At least one domain invariant (no double charge, balance conserved, at most one active state), not only TypeOK. Source: Quint modeling Step 7.
- Mark correct terminal states with an explicit `Done` action so deadlock checking stays on. Sources: pstack statechart, Quint.
- Small constants first; record constants, depth, distinct states, and the rules TLC did not check. Sources: tlaplus-from-source, pstack statechart.
- Able to fail: break the model the way the property guards (drop a guard, swap two steps) and confirm TLC reports a violation. Source: pstack create-formal.
- Replay every counterexample against the real code as a test or live repro, one step per action; if it does not reproduce, suspect the model first. Sources: pstack statechart, maintain-formal.
- Never weaken an invariant or the model to get a pass; the spec is ground truth. Sources: pstack, Quint.
- Tell the counterexample in the code's own words and draw the bug path as a statechart for the PR. Sources: pstack create-formal, statechart.
- Read TLC's summary (states, invariants checked, result), never grep for "Error". Source: Trail of Bits Lean ("ask the tool, not grep").

### Evidence and reporting

- No claim without output from a command run on the recorded commit in this run; read the exit code and counts. Source: superpowers verification-before-completion.
- Each AC test must fail on the base commit and pass on HEAD; run the base side in a temporary `git worktree` outside the workspace. Sources: Trail of Bits post-patch-validation, superpowers regression pattern, Addy definition-of-done.
- Prove a failing check reached its assertion (a marker line printed just before it), so a load or setup error never counts as "failed as expected". Source: Trail of Bits post-patch-validation.
- State the evidence level per claim: source read, built or loaded, executed at runtime. Source: Trail of Bits post-patch-validation.
- Per-claim confidence: CONFIDENT, NOT_CONFIDENT or UNSURE, each with one line of evidence (file:line, test name, command); the state must agree with the evidence line. Source: Anthropic patch-verifier.
- Per-AC verdicts richer than proved/failed: implemented, partial, contradicted, stronger-than-spec, absent (with the searches tried), undecidable (escalate). Source: Trail of Bits spec-to-code.
- Keep "could not run" gaps apart from "ran and failed" findings; a run can have both. Source: Trail of Bits post-patch-validation.
- Every metric names its denominator: mutation score raw and adjusted, with timeouts, skipped and no-coverage counted apart; PBT runs, seed, discards, shrunk counterexample; TLC bounds and states. Sources: Trail of Bits mutation report template, Quint, fast-check.
- A score never proves adequacy; use 60% to start and 80% for a mature suite only as ratchets, and gate on survivors in AC code. Sources: Addy CDD, Trail of Bits analyzing-results.
- Record tool versions, seeds, bounds and one rerun command per check, and keep the raw output file. Sources: pstack (cheap to rerun), principle-prove-it-works, Trail of Bits report template.
- List verbatim commands; set `untested` when no repo test exercises the changed code. Source: Anthropic patch-verifier.
- Report target-environment acceptance apart from local checks, with "not performed" and the next step. Source: ECC verification-loop.
- Each AC result names what it does not cover (bounds, mocks, environments). Sources: pstack (honest about scope), Quint hand-off record.

### Process

- Able to fail: every test, property, mutation gate and model is shown failing on a broken variant before its pass counts. Sources: pstack, superpowers, Trail of Bits Lean, Addy CDD, fast-check, coop.
- Honest about scope: say what is verified, under which bounds, and what is left out. Sources: pstack, Quint, Trail of Bits evidence levels.
- Evidence before claims. Sources: superpowers, pstack principle-prove-it-works.
- Findings stay findings: no weakening of properties or models, no product-code edits; suggestions go to `findings.md`. Sources: pstack, Quint, Trail of Bits post-patch, pstack maintain-verification edit scope.
- Workspace unchanged: snapshot `git status --porcelain` and `git stash list` before and after; base-side runs in a temporary worktree; temporary edits (manual mutation) restored at once and checked with `git diff --quiet`; redirect Stryker `tempDirName` and reports outside the repo; mutant needs no source edits. Sources: Anthropic patch-verifier, Trail of Bits post-patch, pstack statechart, mutant docs.
- No silent installs: adding a PBT library or mutation tool is the user's decision; when a tool is missing, report a gap or escalate, never replace it with a quiet manual guess. Sources: Trail of Bits PBT ("dependency is the user's call"), Anthropic patch-verifier, Trail of Bits genotoxic.
- Guard the bar when confronting Development: flag new `skip`, `xit`, `pending`, `focus`, deleted tests, stripped assertions, suppressions (`Stryker disable`, `istanbul ignore`, mutant ignores) and lowered thresholds in the diff. Source: Addy CDD Step 6.
- One AC per fresh context when there are many ACs, and adversarial review gets the artifact and AC, not your verdict. Sources: Trail of Bits spec-to-code, Addy doubt-driven.
- Fail closed: the default verdict is not proved until evidence says otherwise. Source: Anthropic patch-verifier.
- Run the project's full suite and report failures you did not cause by name. Source: superpowers TDD.
- Cost decides placement: fast checks per AC, diff-scoped mutation and small-bound TLC in Validation, full runs left to CI. Source: Addy CDD Step 5.
- Keep a short "rationalizations to reject" list (for example "the score is high", "probably equivalent", "a flaky rerun passed"). Sources: Trail of Bits mutation-testing and post-patch, superpowers.

### Open points for the skill author

- Ruby PBT tool: no qualifying skill; candidates are `pbt` (ohbarye), PropCheck, Rantly. If the project lacks one, running it without editing `Gemfile` needs a scratch Gemfile (for example `BUNDLE_GEMFILE` pointing to a file outside the repo that loads the project's Gemfile and adds the gem). This is our own idea and is not verified.
- Mutant license for private Rails repos: decide between a paid license, the manual one-mutation fallback, or an Escalation.
- fast-check and Stryker missing from a TS project: same choice as above (scratch install outside the repo, or a gap).
