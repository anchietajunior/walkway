# Formal verification methods for Walkway

Research notes for a standalone verification skill that replaces today's Validation Step. Researched 2026-11-02 against primary sources: tool docs, source repositories, registries, standards bodies and the original papers.

Markers:
- **our judgment**: a recommendation of ours, not a claim of the source.
- **unconfirmed**: no primary source was reachable; the claim rests on a secondary source or an abstract only.

Each method lists five items: **Proves**, **Bounds and assumptions**, **Metric**, **Tools** (Ruby/Rails | TypeScript/React), **Fits 5 minutes scoped**.

## Summary

- Layer 1 is feasible on both stacks today: property-based testing (`pbt`, `prop_check` or `rantly` inside RSpec; `fast-check` in TS), mutation testing scoped to the diff (`mutant --since`; Stryker `--mutate file:lines` and `--incremental`), and diff coverage (`undercover`; Vitest `coverage.changed` or `diff-cover` on LCOV).
- Mutation testing has the best evidence of the adequacy metrics: mutant detection correlates with real-fault detection independently of coverage, and 73% of 357 real faults were coupled to mutants ([Just et al. 2014](https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014.pdf)); 70% of 1,502 Google high-priority bugs had a coupled mutant at the bug-introducing change ([Petrović et al. 2021](https://arxiv.org/abs/2103.07189)).
- The mutation score itself is a weak predictor once suite size is controlled (correlations about 0.05 to 0.20), so Walkway must treat surviving mutants as a to-do list, not the score as proof ([Papadakis et al. 2018](https://orbilu.uni.lu/handle/10993/34950)).
- Coverage finds untested code but is not a quality target: correlation with effectiveness drops to low or moderate when suite size is controlled ([Inozemtseva & Holmes 2014](https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf)).
- Every PBT library checked defaults to 100 generated cases; in a 40-project Python study, 86% of mutations found by property tests appeared within the first 100 inputs ([Ravi & Coblenz artifact](https://github.com/ucsd-salad/python-pbt-eval)).
- Ruby gaps: `mutant` needs a paid licence for private code ([commercial terms](https://github.com/mbj/mutant/blob/main/docs/commercial.md)), and the only Ruby stateful PBT API (`Pbt.stateful`) is experimental ([pbt README](https://github.com/ohbarye/pbt)).
- Layer 2 default: TLA+ (PlusCal where the code reads like an algorithm) checked by TLC, which is exhaustive within the model's constants; Quint is the strong second choice for teams who prefer TypeScript-like syntax. The main risk is model drift: tie each model action to code and replay counterexamples as tests.
- Standards ask for bidirectional traceability between requirements, code and tests (DO-178C), V&V tasks scaled by integrity level (IEEE 1012) and documented test design (ISO/IEC/IEEE 29119), which maps to one Walkway matrix: AC → property → test → evidence.

## Layer 1

### 1. AC as a checkable property

Background:
- Hoare triple `P {Q} R`: if assertion P holds before program Q starts, R holds on its completion ([Hoare 1969, CACM](https://doi.org/10.1145/363235.363259); text read from [author copy](https://personal.utdallas.edu/~hamlen/cs6371sp20/hoare.pdf)).
- The triple gives partial correctness only: the paper says it gives no basis to prove termination ([Hoare 1969](https://personal.utdallas.edu/~hamlen/cs6371sp20/hoare.pdf)).
- Design by Contract: the precondition binds every caller, the postcondition binds the routine, and a class invariant constrains all routines of the class and holds for all instances ([Meyer 1992, IEEE Computer](https://doi.org/10.1109/2.161279); [copy](https://www.kth.se/social/files/59526bfb56be5b4f17000807/meyer-92-contracts.pdf)).
- Gherkin: `Given` sets the initial context, `When` is the event or action, `Then` is the expected outcome; a `Scenario Outline` reruns one scenario over `Examples` rows ([Cucumber Gherkin reference](https://cucumber.io/docs/gherkin/reference/)).
- Mapping (**our judgment**): Given → precondition and generator constraints; When → the single action under test; Then → postcondition; the invariant → a predicate that holds before and after every action (Meyer's class invariant, or a database/domain invariant).

A well-formed property (**our judgment**, built from the sources above and from QuickCheck's lessons in section 3):
- Names its AC (`AC2`), and states the precondition, one action, an observable postcondition and any invariant in one line each.
- Quantifies over an input domain ("for every cart with 0..50 items") instead of one example.
- Has a postcondition a test can observe: return value, persisted record, emitted event, rendered text or GraphQL response.
- Keeps the precondition satisfiable by most generated inputs; QuickCheck showed that a strict precondition skews the tested distribution ([Claessen & Hughes 2000](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- States what is out of scope (bounds, mocked services, time zone), so the evidence does not claim more than it proves.

Five items:
- **Proves:** nothing alone; it turns an AC into a predicate that tests and models can check ([Hoare 1969](https://doi.org/10.1145/363235.363259)).
- **Bounds and assumptions:** partial correctness only; the property is only as right as its wording, and QuickCheck users found errors in their specifications, not only in code ([Claessen & Hughes 2000, section 5.1.3](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- **Metric:** share of ACs with a written property (target 100%; **our judgment**).
- **Tools:** Ruby: plain Markdown plus RSpec `describe "AC2: ..."` naming; TS: same with Vitest/Jest `describe` (**our judgment**; no tool needed).
- **Fits 5 minutes:** yes; writing only.

### 2. Example tests

- **Proves:** the postcondition holds for the listed concrete inputs only; testing shows the presence of bugs, never their absence ([Dijkstra, EWD249](https://www.cs.utexas.edu/~EWD/transcriptions/EWD02xx/EWD249/EWD249.html)).
- **Bounds and assumptions:** the chosen inputs and the test doubles; real services behind mocks are not covered (**our judgment**).
- **Metric:** per AC, at least one example test that passes on HEAD and fails on the base commit (red/green evidence; **our judgment**).
- **Tools:** Ruby: RSpec ([rspec.info](https://rspec.info/)); TS: Vitest or Jest ([Vitest](https://vitest.dev/guide/coverage), [Jest](https://jestjs.io/docs/configuration)).
- **Fits 5 minutes:** yes when scoped to the spec files of the changed code (**our judgment**).

### 3. Property-based testing (PBT)

Origins and concepts:
- QuickCheck: properties are Haskell functions tested on random inputs; a run passes after 100 tests, which the authors call "rather arbitrary" ([Claessen & Hughes, ICFP 2000](https://doi.org/10.1145/351240.351266); [copy](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- Conditional laws (`==>`) discard inputs that fail the precondition; QuickCheck tries at most 1000 candidates and then reports how many tests passed ([Claessen & Hughes 2000, section 2.3](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- Distribution matters: in their unification case study over 95% of valid cases were trivial until they wrote a custom generator; `classify` and `collect` report the distribution ([Claessen & Hughes 2000, sections 2.4 and 5.1](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- The 2000 paper has no shrinking; the word does not appear in the text (our reading of the paper). All current libraries below shrink.
- Hypothesis (reference design): `max_examples` defaults to 100, `deadline` to 200 ms, failing cases are saved to `.hypothesis/examples` and replayed first, `@seed` makes runs repeatable, and the `shrink` phase minimises failures ([Hypothesis API reference](https://hypothesis.readthedocs.io/en/latest/reference/api.html)).
- fast-check: `numRuns` defaults to 100, `seed` defaults to `Date.now()`, and `seed` plus `path` replays one counterexample ([fast-check Parameters](https://fast-check.dev/docs/api/interfaces/Parameters/)); latest 4.10.2, 2026-09-19, MIT ([npm registry](https://registry.npmjs.org/fast-check)).
- fast-check also has model-based testing (`fc.commands`, `fc.modelRun`, `fc.asyncModelRun`) that shrinks command sequences, and `fc.scheduledModelRun` for race conditions ([model-based testing](https://fast-check.dev/docs/advanced/model-based-testing/), [race conditions](https://fast-check.dev/docs/tutorials/detect-race-conditions/)).

Ruby options today:
- `pbt` 0.7.0, 2026-04-04, MIT, Ruby >= 3.1, repo pushed 2026-09-19 ([RubyGems](https://rubygems.org/gems/pbt), [GitHub](https://github.com/ohbarye/pbt)): `num_runs` 100 by default, random seed printed on failure and replayable with `Pbt.assert(seed:)`, shrinking, optional Ractor workers (experimental), and an experimental `Pbt.stateful` API for model-based tests ([README](https://github.com/ohbarye/pbt)).
- `prop_check` 1.0.2, 2025-03-14, MIT ([RubyGems](https://rubygems.org/gems/prop_check)): `PropCheck.forall` inside an RSpec `it`, shrinking, `n_runs` 100 by default ([configuration.rb](https://github.com/Qqwy/ruby-prop_check/blob/master/lib/prop_check/property/configuration.rb)); no seed option is documented and stateful testing is a "nice-to-have" ([README](https://github.com/Qqwy/ruby-prop_check)).
- `rantly` 3.0.0, 2024-10-21, MIT, Ruby >= 3.2 ([RubyGems](https://rubygems.org/gems/rantly)): `rantly/rspec_extensions`, 100 runs by default or `RANTLY_COUNT`, opt-in shrinking capped at 1024 steps and not guaranteed minimal ([README](https://github.com/rantly-rb/rantly)); a seed option is unconfirmed.
- All three run inside RSpec examples: `prop_check` and `rantly` document it; `Pbt.assert` raises on failure, so an RSpec example fails with it (our reading of the [pbt README](https://github.com/ohbarye/pbt)).
- Rails note: tests that avoid the database are 10x to 100x faster, and DB state must be cleaned around each generated example, not each RSpec example ([prop_check README, "Usage within Rails"](https://github.com/Qqwy/ruby-prop_check)).

Five items:
- **Proves:** the property holds for N generated inputs from the chosen distribution, with a shrunk counterexample when it fails ([Claessen & Hughes 2000](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf), [fast-check](https://fast-check.dev/docs/api/interfaces/Parameters/)).
- **Bounds and assumptions:** random sampling, not exhaustive; only as good as the generator's distribution and the precondition's discard rate ([Claessen & Hughes 2000](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- **Metric:** properties per AC, runs per property, seed, and pass/fail with the shrunk counterexample; optionally the mutants killed by property tests ([Ravi & Coblenz, OOPSLA 2025](https://2025.splashcon.org/details/OOPSLA/102)).
- **Tools:** Ruby: `pbt` (most active), `prop_check`, `rantly`; TS: `fast-check` with Vitest or Jest.
- **Fits 5 minutes:** yes at 100 to 1000 runs for pure or service-level code; DB-backed properties need fewer runs or a DB-free seam ([prop_check README](https://github.com/Qqwy/ruby-prop_check); run budget is **our judgment**).

### 4. Mutation testing

Definitions:
- Mutation score: killed mutants over non-equivalent mutants; equivalent mutants cannot be killed and detecting them all is undecidable ([Jia & Harman, TSE 2011](https://doi.org/10.1109/TSE.2010.62); [copy](https://web.eecs.umich.edu/~weimerw/2020-481F/readings/mutation-testing.pdf)).
- Stryker's operational score: detected / valid × 100, with detected = killed + timeout and valid = detected + survived + no coverage; compile and runtime errors and ignored mutants are excluded; a second score uses covered mutants only ([Stryker metrics](https://stryker-mutator.io/docs/mutation-testing-elements/mutant-states-and-metrics/)).

`mutant` (Ruby):
- Version 0.17.1, 2026-10-21, licence "Nonstandard" ([RubyGems](https://rubygems.org/gems/mutant)); free for open source with `--usage opensource`, otherwise $30/month or $250/year per developer, no free trial ([README](https://github.com/mbj/mutant), [commercial terms](https://github.com/mbj/mutant/blob/main/docs/commercial.md)).
- Ruby 3.2 to 4.0 on Linux and macOS; Rails 7.2, 8.0 and 8.1 verified in CI ([README](https://github.com/mbj/mutant)).
- RSpec via `mutant-rspec`; test selection by longest prefix match of example group descriptions (`describe Foo::Bar, "#baz"`), `mutant_expression:` metadata to map a test, `mutant: false` to exclude slow tests ([mutant-rspec docs](https://github.com/mbj/mutant/blob/main/docs/mutant-rspec.md)).
- Rails: `RAILS_ENV=test bundle exec mutant run -r ./config/environment --integration rspec User` ([mutant-rspec docs](https://github.com/mbj/mutant/blob/main/docs/mutant-rspec.md)).
- Incremental: `--since <git-ref>` selects subjects whose line range overlaps a diff hunk; it misses indirect effects such as a changed constant ([incremental docs](https://github.com/mbj/mutant/blob/main/docs/incremental.md)).
- Mutations are inserted into the running process as monkeypatches with fork isolation; IO and file-system isolation is the test author's job ([nomenclature](https://github.com/mbj/mutant/blob/main/docs/nomenclature.md)). Whether `mutant` writes session files inside the project is unconfirmed.
- Each alive mutation is either a simplification the code can take or a missing test ([README](https://github.com/mbj/mutant)).
- Speed reference: the docs' example ran 1,003 mutations in about 51 s with 8 jobs ([mutant-rspec docs](https://github.com/mbj/mutant/blob/main/docs/mutant-rspec.md)).
- No maintained free Ruby alternative was found (search only; unconfirmed that none exists).

Stryker (JS/TS):
- `@stryker-mutator/core` 10.1.1, 2026-10-23, Apache-2.0 ([npm registry](https://registry.npmjs.org/@stryker-mutator/core)).
- `--mutate` takes globs or line ranges such as `src/app.js:5-7` ([configuration](https://stryker-mutator.io/docs/stryker-js/configuration/), [incremental](https://stryker-mutator.io/docs/stryker-js/incremental/)).
- `--incremental` (since 6.2) reuses results from `reports/stryker-incremental.json` when the mutant's code and its covering tests are unchanged; the dry run still happens every time; Jest and Vitest report test locations precisely ([incremental](https://stryker-mutator.io/docs/stryker-js/incremental/)).
- Defaults: `coverageAnalysis: perTest`, `thresholds {high: 80, low: 60, break: null}`, `timeoutMS 5000`, `timeoutFactor 1.5`; works on a copy in `.stryker-tmp` (`inPlace: false`) and writes reports under `reports/` ([configuration](https://stryker-mutator.io/docs/stryker-js/configuration/)).

At scale (Google):
- Mutants only on changed lines that tests cover, at most one mutant per line, with more than a hundred "arid node" rules that suppress unproductive mutants; developer-rated productivity rose from about 15% to 89% ([Petrović et al., "Practical Mutation Testing at Scale"](https://arxiv.org/abs/2102.11378)).

Equivalent mutants:
- Trivial Compiler Equivalence flagged more than 7% of mutants as equivalent and 21% as duplicates on large C programs, and caught about 30% of hand-identified equivalents ([Papadakis et al., ICSE 2015](https://orbilu.uni.lu/bitstream/10993/20289/1/ICSE15.pdf)).
- In 140 surviving mutants of seven Java programs, 45% were equivalent, and classifying one took about 15 minutes (unconfirmed: [Schuler & Zeller](https://www.st.cs.uni-saarland.de/publications/details/schuler-stvrbis-2013/) was unreachable; numbers from the indexed abstract).

Five items:
- **Proves:** the tests detect the seeded small faults (mutants) in the changed code; surviving mutants show behaviour no test pins down ([Jia & Harman 2011](https://web.eecs.umich.edu/~weimerw/2020-481F/readings/mutation-testing.pdf)).
- **Bounds and assumptions:** only the operators the tool applies; 17% of real faults are not coupled to any common mutant ([Just et al. 2014](https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014.pdf)); equivalent mutants inflate survivors ([Jia & Harman 2011](https://web.eecs.umich.edu/~weimerw/2020-481F/readings/mutation-testing.pdf)).
- **Metric:** mutation score on the changed subjects, survivors list, and equivalents with reasons ([Stryker metrics](https://stryker-mutator.io/docs/mutation-testing-elements/mutant-states-and-metrics/)).
- **Tools:** Ruby: `mutant` + `mutant-rspec` with `--since` (licence needed for private code), or manual mutation probes (edit, run spec, `git checkout` the file); TS: Stryker with the Vitest or Jest runner.
- **Fits 5 minutes:** yes for a typical issue diff when scoped by `--since` / `--mutate` and run against the mapped specs only; a Rails boot per worker and Stryker's dry run add fixed cost (**our judgment**, from the 51 s example above).

### 5. Diff coverage

- SimpleCov: `enable_coverage :branch`, `minimum_coverage line: 90, branch: 80`, per-file minimums, `refuse_coverage_drop`, and `ignore :implicit_else` for synthetic branches ([Configuration.md](https://github.com/simplecov-ruby/simplecov/blob/main/docs/Configuration.md)); version 1.3.2, 2026-09-30, Ruby >= 3.3 ([RubyGems API](https://rubygems.org/api/v1/versions/simplecov.json)).
- `undercover` 0.9.0, 2026-10-26: flags changed methods, classes and blocks without coverage using SimpleCov JSON and `--compare <ref>`, exits 1 on warnings, reports uncovered branches when branch coverage is on ([README](https://github.com/grodowski/undercover), [RubyGems API](https://rubygems.org/api/v1/versions/undercover.json)).
- `diff-cover` 11.0.0 (PyPI, 2026-10-27): percentage of new or changed lines covered, from Cobertura, Clover, JaCoCo or LCOV, `--compare-branch` (default `origin/main`) and `--fail-under`; branch coverage is not documented ([README](https://github.com/Bachmann1234/diff_cover), [PyPI](https://pypi.org/project/diff-cover/)).
- Vitest: `v8` provider by default with AST-aware remapping since 3.2 ("identical to Istanbul"), `istanbul` optional ([coverage guide](https://vitest.dev/guide/coverage)); `coverage.changed` limits coverage to files changed since a ref; thresholds for lines, branches, functions, statements, per file ([coverage config](https://vitest.dev/config/coverage)).
- Jest: `coverageProvider` `babel` (Istanbul) by default or `v8`; `coverageThreshold` global or per path; default reporters include `lcov` ([Jest configuration](https://jestjs.io/docs/configuration)).
- c8: native V8 coverage for Node, `--check-coverage` with `--lines/--branches/--functions`, `--per-file`, and `--all` to include unloaded files ([c8 README](https://github.com/bcoe/c8)).

Five items:
- **Proves:** which changed lines and branches ran during the tests; nothing about whether the tests checked their results ([Inozemtseva & Holmes 2014](https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf)).
- **Bounds and assumptions:** execution only; uncovered code also escapes mutation (Google mutates covered lines only; Stryker counts no-coverage mutants as undetected) ([Petrović et al.](https://arxiv.org/abs/2102.11378), [Stryker metrics](https://stryker-mutator.io/docs/mutation-testing-elements/mutant-states-and-metrics/)).
- **Metric:** changed-line coverage and changed-branch coverage percentages, plus the list of uncovered changed lines.
- **Tools:** Ruby: SimpleCov (branch) + `undercover --compare <base>`; TS: Vitest or Jest coverage to LCOV + `diff-cover`, or Vitest `coverage.changed`.
- **Fits 5 minutes:** yes; it piggybacks on the scoped spec run (**our judgment**).

### 6. Traceability in standards

- **DO-178C** (RTCA, 2011; recognised by the FAA in AC 20-115D): full text is paywalled; RTCA's page gives only purpose and supplements DO-330 to DO-333, DO-333 being the formal methods supplement ([RTCA](https://www.rtca.org/do-178/)).
  - A NASA report quotes its objectives: high-level requirements traceable to system requirements (A-3.6), low-level to high-level (A-4.6), source code to low-level requirements (A-5.5) ([NASA/CR-2014-218244](https://ntrs.nasa.gov/citations/20140004055)).
  - Level A needs MC/DC structural coverage, per a NASA tutorial written for DO-178B; carry-over to DO-178C is unconfirmed here ([NASA/TM-2001-210876](https://ntrs.nasa.gov/citations/20010057789)).
- **IEEE 1012-2024** (active, supersedes 1012-2016): V&V decides whether products meet their activity's requirements and the user's needs, through analysis, review, inspection and testing, with requirements scaled by integrity level; the abstract does not mention traceability analysis and the full text is paywalled ([IEEE SA](https://standards.ieee.org/ieee/1012/7324/)).
- **ISO/IEC/IEEE 29119** (2021 editions; full text paywalled): part 2 defines test processes at organisational, management and dynamic levels ([IEEE listing](https://standards.ieee.org/ieee/29119-3/7498/)); part 3 gives test documentation templates mapped to part 2 ([ISO 79429](https://www.iso.org/standard/79429.html)); part 4 defines test design techniques ([ISO 79430](https://www.iso.org/standard/79430.html)). Explicit traceability clauses could not be read (unconfirmed).

Five items:
- **Proves:** that every requirement has verification and every test has a reason; not that the software is correct ([NASA/CR-2014-218244](https://ntrs.nasa.gov/citations/20140004055)).
- **Bounds and assumptions:** only as complete as the AC list Research wrote (**our judgment**).
- **Metric:** ACs with property, test and evidence / total ACs; orphan tests (no AC) (**our judgment**, modelled on DO-178C bidirectional tracing).
- **Tools:** Ruby and TS: none needed; a Markdown matrix in the Task folder (**our judgment**).
- **Fits 5 minutes:** yes.

## Layer 2

### 7. TLA+ / PlusCal with TLC

- TLA+ is for modelling programs and systems, especially concurrent and distributed ones ([Lamport](https://lamport.azurewebsites.net/tla/tla.html)).
- TLC is an explicit-state model checker for safety and liveness; it also simulates; near-linear speed-up up to 32+ cores; PlusCal translates to TLA+ ([TLA+ tools](https://lamport.azurewebsites.net/tla/tools.html)).
- TLC enumerates all reachable states, so it needs a small enough state space and finite sets for nondeterministic choices ([Quint model checkers page](https://quint.sh/docs/model-checkers)).
- Install: Java 11+ and `tla2tools.jar`; the Eclipse Toolbox is unmaintained and the VS Code extension replaces it ([tlaplus repo](https://github.com/tlaplus/tlaplus)); last tagged release v1.7.4, 2024-08-05, with a rolling 1.8.0 pre-release ([releases](https://github.com/tlaplus/tlaplus/releases)).
- Run control: `-workers auto`, `-simulate num=N`, `-depth` (default 100 in simulation), `-dfid`, and `-dumpTrace json file.json` for counterexamples; no built-in time limit is documented ([current-tools.md](https://github.com/tlaplus/tlaplus/blob/master/general/docs/current-tools.md)).

Five items:
- **Proves:** every invariant (and checked temporal property) holds in all reachable states of the model for the chosen constants ([TLA+ tools](https://lamport.azurewebsites.net/tla/tools.html)).
- **Bounds and assumptions:** finite constants (for example 2 workers, 3 retries); proves the design, not the code ([Newcombe et al. preprint](https://6826.csail.mit.edu/2019/papers/formal-methods-amazon.pdf)).
- **Metric:** invariants checked, distinct states explored, search depth, run time, and counterexample trace if any.
- **Tools:** Ruby: none native, model is language-agnostic; TS: none native (Quint is the TS-friendly front end, section 10).
- **Fits 5 minutes:** yes for a small model with small constants (**our judgment**; no primary source gives typical run times, and Datadog's first Courier model reached 5,515,710 distinct states with no time reported ([Datadog](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/))); wrap in `timeout 300`.

### 8. Apalache

- Symbolic bounded model checker for TLA+: encodes executions of up to `--length` steps (default 10) in SMT; incomplete, so longer bugs can be missed; can also check inductive invariants with `--length` 0 or 1; `simulate` mode runs `--max-run` 100 random symbolic runs ([running Apalache](https://apalache-mc.org/docs/apalache/running.html)).
- Latest release v0.62.4, 2026-10-12 ([releases](https://github.com/apalache-mc/apalache/releases)); needs a JDK 17+ when used through Quint ([Quint getting started](https://quint.sh/docs/getting-started)).

Five items:
- **Proves:** no invariant violation within k steps for all values the types allow, or an inductive invariant holds for all steps ([running Apalache](https://apalache-mc.org/docs/apalache/running.html)).
- **Bounds and assumptions:** execution length k; incomplete beyond k ([running Apalache](https://apalache-mc.org/docs/apalache/running.html)).
- **Metric:** k, invariants checked, verdict, run time.
- **Tools:** Ruby: none; TS: through Quint (`quint verify`, Apalache by default) ([Quint CLI](https://quint.sh/docs/quint)).
- **Fits 5 minutes:** likely for small k (**our judgment**; no timing data in the docs).

### 9. Alloy 6

- Adds mutable state (`var`), primed next-state values and future and past temporal operators; analysis is bounded by signature scopes and a time horizon, default `for 10 steps`; `for 1.. steps` needs NuSMV or nuXmv installed separately ([Alloy 6](https://alloytools.org/alloy6.html)).
- Java 17+, bundled Sat4j plus native solvers ([repo](https://github.com/AlloyTools/org.alloytools.alloy)); v6.2.0, 2025-01-09 ([releases](https://github.com/AlloyTools/org.alloytools.alloy/releases)).
- Bounded scope rests on the small scope hypothesis: many bugs show up in small instances (Andoni et al. 2002, "Evaluating the small scope hypothesis", CiteSeerX 10.1.1.8.7702; the paper was not reachable, unconfirmed).

Five items:
- **Proves:** no counterexample to an assertion within the given scope and step bound ([Alloy 6](https://alloytools.org/alloy6.html)).
- **Bounds and assumptions:** scope per signature and steps; small scope hypothesis.
- **Metric:** scope, steps, assertions checked, counterexample.
- **Tools:** Ruby: none; TS: none.
- **Fits 5 minutes:** likely at small scopes (**our judgment**); the CLI is not documented in the README, which leans on the GUI ([repo](https://github.com/AlloyTools/org.alloytools.alloy)).

### 10. Quint

- Typed specification language for the same logic as TLA+; `npm i @informalsystems/quint -g`; model checking needs JDK 17+ ([getting started](https://quint.sh/docs/getting-started)); version 0.33.1, 2026-10-28 ([npm registry](https://registry.npmjs.org/@informalsystems/quint)).
- `quint verify` uses Apalache by default (`--max-steps` 10) or TLC with `--backend=tlc`; `quint run` simulates with `--max-samples` 10000 and `--max-steps` 20 ([CLI manual](https://quint.sh/docs/quint), [model checkers](https://quint.sh/docs/model-checkers)).
- Model-based testing: `quint run --mbt` exports ITF JSON traces with the action and nondeterministic picks per step; Quint Connect drives Rust code; other languages need their own driver ([MBT](https://quint.sh/docs/model-based-testing)).

Five items:
- **Proves:** with TLC backend, same as section 7; with Apalache, same as section 8; `quint run` only samples ([model checkers](https://quint.sh/docs/model-checkers)).
- **Bounds and assumptions:** backend bounds; simulation is random, not a proof.
- **Metric:** backend, bound, invariants, samples, verdict.
- **Tools:** Ruby: none native (an ITF trace driver would be ours to write); TS: Quint CLI from npm, ITF driver ours to write.
- **Fits 5 minutes:** yes for simulation and small models (**our judgment**).

### 11. P language

- Communicating state machines; the checker explores interleavings of messages and failures with search heuristics and gives a reproducible trace; PEx is exhaustive, PVerifier proves, PObserve checks production logs against the same monitors ([What is P](https://p-org.github.io/P/whatisP/), [repo](https://github.com/p-org/P)).
- Install: .NET SDK 8.0, Java 11+, `dotnet tool install --global P`; run `p check -tc <test> -i 1000` ([install](https://p-org.github.io/P/getstarted/install/)); NuGet package P 3.1.0 ([NuGet](https://www.nuget.org/packages/P)).
- Used by AWS teams on S3, EBS, DynamoDB, MemoryDB, Aurora, EC2 and IoT ([repo](https://github.com/p-org/P)).

Five items:
- **Proves:** default checker: no safety or liveness violation in the explored schedules (testing, not proof); PEx/PVerifier give stronger guarantees ([What is P](https://p-org.github.io/P/whatisP/)).
- **Bounds and assumptions:** iteration count, test harness scenario, message-passing abstraction.
- **Metric:** schedules explored, bugs found, trace.
- **Tools:** Ruby: none; TS: none.
- **Fits 5 minutes:** yes with a bounded `-i` (**our judgment**); install cost (.NET 8) is the highest of the four.

### 12. Keeping a model faithful to the code

- Amazon: asked how they know code implements the verified design, the answer was "we don't"; models still help get the design right and find invariants worth asserting in code ([Newcombe et al. preprint](https://6826.csail.mit.edu/2019/papers/formal-methods-amazon.pdf)).
- MongoDB: trace checking the server against an abstract TLA+ spec was abandoned after 10 weeks (concurrency, locking, model/code gaps); generating 4,913 C++ tests from a TLA+ model of an operational-transform algorithm reached 100% branch coverage of the targeted code versus 21% for handwritten tests and 92% for fuzzing ([Davis et al., VLDB 2020](https://arxiv.org/abs/2006.00915)).
- MongoDB's advice: trace small modules in unit tests, where nondeterminism is easier to remove, and log only variables the code can see at each transition ([Davis et al.](https://arxiv.org/abs/2006.00915)).
- Trace validation: instrument the program to log spec-variable updates and let TLC check the trace is a behaviour of the spec; it found spec/code discrepancies in every case study ([Cirstea et al., arXiv 2404.16075](https://arxiv.org/abs/2404.16075)).
- Microsoft CCF: TLA+ specs plus trace validation in CI found six subtle bugs before production ([Howard et al., NSDI 2025](https://www.usenix.org/conference/nsdi25/presentation/howard)).
- Amazon S3 ShardStore: executable reference models about 1% of the code size, checked against the implementation by PBT on random operation sequences and by stateless model checking for concurrency; 16 issues kept out of production ([Bornholt et al., SOSP 2021](https://www.cs.utexas.edu/~bornholt/papers/shardstore-sosp21.pdf)).
- Datadog: models are updated for large design changes; routine changes rely on unit, integration and chaos tests ([Datadog](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/)).

Five items (for conformance checks):
- **Proves:** the code's observed or generated behaviours are allowed by the model, for the traces tested ([Cirstea et al.](https://arxiv.org/abs/2404.16075), [Quint MBT](https://quint.sh/docs/model-based-testing)).
- **Bounds and assumptions:** only the traces produced; logging and post-processing bugs can mask code bugs ([Davis et al.](https://arxiv.org/abs/2006.00915)).
- **Metric:** traces or command sequences checked, conformance failures, branch coverage of the targeted code.
- **Tools:** Ruby: `Pbt.stateful` (experimental) against a Ruby reference model, or RSpec tests replayed from TLC `-dumpTrace json` counterexamples; TS: `fast-check` `fc.commands` / `fc.scheduledModelRun`.
- **Fits 5 minutes:** yes for unit-level command sequences (**our judgment**).

### Industry evidence

- AWS (CACM 2015): TLA+ on S3, DynamoDB, EBS and a lock manager; DynamoDB bugs needed traces of 35 steps; engineers learned TLA+ in 2 to 3 weeks; specs of 102 to 939 lines ([preprint](https://6826.csail.mit.edu/2019/papers/formal-methods-amazon.pdf), [CACM landing](https://cacm.acm.org/research/how-amazon-web-services-uses-formal-methods/), [Amazon Science](https://www.amazon.science/publications/how-amazon-web-services-uses-formal-methods)).
- AWS (CACM 2025, Brooker & Desai): surveys TLA+, P, PBT, fault injection and deterministic simulation; the article was blocked to us, so details beyond the P repository are unconfirmed ([CACM](https://cacm.acm.org/practice/systems-correctness-practices-at-amazon-web-services/)).
- Microsoft: a client-focused TLA+ spec of Cosmos DB found two documentation issues and explained a past high-impact outage ([Hackett et al., ICSE-SEIP 2023](https://arxiv.org/abs/2210.13661)); CCF as above.
- MongoDB: section 12.
- Datadog: TLA+ verified idempotency for Husky and a no-lost-messages property for the Courier queue; FoundationDB optimistic concurrency bugs led to making all transactions idempotent ([Datadog](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/)).

### Code patterns that justify model checking

Sources show model checking paying off on: replication and fault tolerance, data migration, lock-free structures, lock managers, schemas with rich invariants ([Newcombe et al.](https://6826.csail.mit.edu/2019/papers/formal-methods-amazon.pdf)); idempotency and message delivery with retries ([Datadog](https://www.datadoghq.com/blog/engineering/formal-modeling-and-simulation/)); consistency levels ([Hackett et al.](https://arxiv.org/abs/2210.13661)); concurrent merges ([Davis et al.](https://arxiv.org/abs/2006.00915)). The Rails/TS triggers in the recommendations are **our judgment** derived from these.

## Evidence on metrics

Coverage:
- Inozemtseva & Holmes (ICSE 2014): 31,000 suites over five Java systems up to 724,000 LOC; statement, decision and modified condition coverage; effectiveness measured with mutants. Correlation is low to moderate once suite size is controlled; stronger coverage types add little; coverage "should not be used as a quality target" ([paper](https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf)).
  - Extremes: Joda Time fell from 0.80 to 0.85 to about zero with size controlled; Apache POI fell from 0.94 to 0.46 to 0.85 ([paper, section 4](https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf)).
- Gopinath et al. (ICSE 2014): over hundreds of open-source Java projects (1,254 after filtering), statement coverage predicted mutation kills best among statement, block, branch and path coverage ([paper](https://www.cefns.nau.edu/~adg326/icse14.pdf)); the outcome is mutants, not real faults.

Mutants versus real faults:
- Just et al. (FSE 2014): 357 real faults, 5 programs, 321,000 LOC, 230,000 mutants. Mutant detection correlates with real-fault detection independently of coverage and more strongly than statement coverage; 73% of real faults coupled to mutants, 10% need new or stronger operators, 17% not coupled; conditional operator replacement, relational operator replacement and statement deletion couple most ([paper](https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014.pdf)).
- Chekam et al. (ICSE 2017): on CoREBench faults in Coreutils, Findutils, Grep and Make, without the clean-program assumption, strong mutation had the highest fault revelation, on average at least 12% above statement, branch and weak mutation; gains appear only at high levels: about 5%, 13% and 18% above random suites of the same size for the top 20%, 10% and 5% ([paper](https://discovery.ucl.ac.uk/10058915/7/Chekam_ICSE17.pdf)).
- Papadakis et al. (ICSE 2018): CoreBench and Defects4J. Correlation between mutation score and real-fault detection is 0.35 to 0.75 without size control and about 0.05 to 0.20 with it; still, the top 25% and 10% of suites by mutation score found 8% and 11% more faults (Defects4J) and 18% and 46% more (CoreBench) than random suites of equal size; under 1% of mutants behave like the real faults ([paper](https://orbilu.uni.lu/handle/10993/34950)).
- Petrović et al. (ICSE 2021, Google): developers shown mutants wrote more tests (median 11 changed test hunks per changelist versus 0 for the coverage baseline); 1,043 of 1,502 high-priority bugs (70%) would have had a live coupled mutant at the bug-introducing change ([paper](https://arxiv.org/abs/2103.07189)).
- Petrović et al. (TSE 2021, Google): diff-scoped, coverage-gated, one mutant per line; productivity from about 15% to 89% after suppression rules; 16.9 million mutants generated, 2.1 million surfaced ([paper](https://arxiv.org/abs/2102.11378)).

Property-based testing:
- Ravi & Coblenz (OOPSLA 2025): 426 Python projects using Hypothesis, mutation testing on 40; a property test finds about 50 times as many mutations as an average unit test; tests for exceptions, collection membership and types were over 19 times more effective than other property kinds ([SPLASH abstract](https://2025.splashcon.org/details/OOPSLA/102)).
  - 76% of the mutations property tests found appeared in the first 20 inputs, 86% in 100, 96% in 350; property tests were 1.6% of tests and killed 15.3% of mutations ([artifact](https://github.com/ucsd-salad/python-pbt-eval)).

Model checking:
- No controlled study of fault-detection rates was found; the evidence is first-party industry reports (section "Industry evidence").

## Recommendations for Walkway

Candidate metrics and thresholds (one gate per AC unless stated):
- **Property per AC: 100%.** Each AC has a written property (precondition, action, postcondition, invariant). Our judgment, modelled on DO-178C's requirement-to-code-to-test tracing ([NASA/CR-2014-218244](https://ntrs.nasa.gov/citations/20140004055)).
- **Example test per AC: at least 1, green on HEAD, red on the base commit.** Our judgment; red-on-base shows the test checks the change.
- **Property test per AC with a non-trivial input domain: at least 1, 100 runs by default, 500 for money and state-transition code, seed recorded.** 100 is every library's default ([fast-check](https://fast-check.dev/docs/api/interfaces/Parameters/), [pbt](https://github.com/ohbarye/pbt), [prop_check](https://github.com/Qqwy/ruby-prop_check/blob/master/lib/prop_check/property/configuration.rb), [rantly](https://github.com/rantly-rb/rantly), [Hypothesis](https://hypothesis.readthedocs.io/en/latest/reference/api.html)); 86% of mutations found by 100 inputs and 96% by 350 ([artifact](https://github.com/ucsd-salad/python-pbt-eval)); 500 is our judgment.
- **Generator health: every property reaches its run count without exhausting its precondition, and the evidence reports the input distribution.** From QuickCheck's discard limit and trivial-case finding ([Claessen & Hughes 2000](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)).
- **Changed-line coverage: 100% of changed executable lines, exclusions listed with reasons; changed-branch coverage reported, not gated.** Uncovered lines cannot be mutation-tested ([Petrović et al.](https://arxiv.org/abs/2102.11378)); coverage is not a quality target and stronger coverage types add little ([Inozemtseva & Holmes](https://cs.ubc.ca/~rtholmes/papers/icse_2014_inozemtseva.pdf)); the 100% line is our judgment.
- **Mutation on changed subjects: zero unexplained survivors; each survivor is killed by a new test, removed as a simplification, or recorded as equivalent with a one-line reason; the score (Stryker formula) is reported.** Fault detection improves only at high mutation levels ([Chekam et al.](https://discovery.ucl.ac.uk/10058915/7/Chekam_ICSE17.pdf), [Papadakis et al.](https://orbilu.uni.lu/handle/10993/34950)); mutant's own rule for alive mutations ([README](https://github.com/mbj/mutant)); the gate is our judgment. Stryker's 80/60 bands are tool defaults, not evidence ([configuration](https://stryker-mutator.io/docs/stryker-js/configuration/)).
- **Traceability matrix complete: every AC → property → test IDs → evidence (command, exit code, seed, score); no orphan test in the diff.** Our judgment, modelled on DO-178C.
- **Layer 2, when triggered: TLC finds no invariant violation and no deadlock for the stated constants; the evidence records constants, distinct states, depth and run time; each model action maps to a code method; each counterexample found during the run becomes a regression test.** Our judgment, from the sources in section 12.

Layer 2 triggers (our judgment, derived from the industry evidence above). Run Layer 2 when the diff adds or changes behaviour with at least two steps or actors that can interleave or repeat, and one of these holds:
- **Concurrency:** read-modify-write of shared rows across requests or jobs (`with_lock`, `lock!`, `lock_version`, `update_all` counters), threads or `Concurrent::` primitives, or TS async flows racing on shared client state (Apollo cache, optimistic updates).
- **State machines:** a status or state column with guarded transitions (AASM, `state_machines`, enum plus transition methods), or a client state machine (XState, reducer with status).
- **Retries:** `retry_on`, Sidekiq retries, HTTP or GraphQL retry links, webhook redelivery.
- **Idempotency:** idempotency keys, `find_or_create_by`, upserts, unique-index reliance, at-least-once consumers.
- **Money:** balances, ledgers, payments, refunds, currency conversion or rounding.

Default Layer 2 tool:
- **TLA+ (PlusCal for algorithm-shaped code) checked by TLC**: exhaustive within small constants, safety and liveness, one jar on Java 11+, JSON counterexamples, and the deepest first-party evidence (AWS, Microsoft, MongoDB, Datadog) ([TLA+ tools](https://lamport.azurewebsites.net/tla/tools.html), [current-tools.md](https://github.com/tlaplus/tlaplus/blob/master/general/docs/current-tools.md)).
- Alternatives: Quint when the team wants TypeScript-like syntax and npm install, still able to run TLC ([Quint](https://quint.sh/docs/model-checkers)); Apalache when TLC's state space blows up and a bounded depth is acceptable; Alloy 6 for data-model invariants; P for message-passing services, at the cost of .NET 8.
- Pair every model with a code-level conformance check: `fast-check` `fc.commands` in TS, `Pbt.stateful` or replayed counterexamples in RSpec (our judgment, after [ShardStore](https://www.cs.utexas.edu/~bornholt/papers/shardstore-sosp21.pdf) and [MongoDB](https://arxiv.org/abs/2006.00915)).

Risks:
- **Run time.** Rails boot per mutant worker, Stryker's dry run on every run, and TLC state explosion can pass 5 minutes. Mitigate: `mutant --since <base>` with mapped specs, `stryker --mutate <file:lines>`, small model constants, `timeout 300`; on timeout, report the bound reached and mark the result partial (our judgment). TLC simulation is not exhaustive and must be labelled as such.
- **Equivalent mutants.** Detection is undecidable ([Jia & Harman](https://web.eecs.umich.edu/~weimerw/2020-481F/readings/mutation-testing.pdf)); tools catch only part (TCE about 30% of known equivalents ([Papadakis et al. 2015](https://orbilu.uni.lu/bitstream/10993/20289/1/ICSE15.pdf))); a share of survivors near half may be equivalent and cost minutes each (unconfirmed, Schuler & Zeller). Mitigate: one-line reason per equivalent claim, spot-checked by Code Review (our judgment).
- **Mutation score as proof.** Weak correlation once size is controlled ([Papadakis et al. 2018](https://orbilu.uni.lu/handle/10993/34950)); 17% of real faults are not coupled to mutants ([Just et al.](https://homes.cs.washington.edu/~mernst/pubs/mutation-effectiveness-fse2014.pdf)). Report survivors, never claim "verified" from the score.
- **Model drift.** Models prove the design, not the code ([Newcombe et al.](https://6826.csail.mit.edu/2019/papers/formal-methods-amazon.pdf)); full trace checking of a large system was abandoned after 10 weeks ([Davis et al.](https://arxiv.org/abs/2006.00915)). Mitigate: action-to-method map, model kept beside the Task, counterexamples turned into tests, and model-based or stateful tests at unit level.
- **Licence.** `mutant` requires a paid subscription for private code ([commercial terms](https://github.com/mbj/mutant/blob/main/docs/commercial.md)); without it, Ruby mutation falls back to manual probes on changed lines, restored with `git checkout -- <file>` right after each probe.
- **Immature Ruby PBT.** `Pbt.stateful` and Ractor workers are experimental; `prop_check` has no documented seed ([pbt](https://github.com/ohbarye/pbt), [prop_check](https://github.com/Qqwy/ruby-prop_check)).
- **Workspace changes.** Stryker writes `.stryker-tmp` and `reports/` in the project by default ([configuration](https://stryker-mutator.io/docs/stryker-js/configuration/)); SimpleCov and Vitest write coverage folders; `mutant` session files are unconfirmed. Point outputs to the Task folder where the tool allows it, delete the rest after the run, and check `git status --porcelain` is empty (our judgment).
- **Who owns the tests.** The verifier must leave the workspace unchanged, so tests it writes cannot stay in the repo. Either Development writes the property and example tests and the verifier audits them, or the verifier keeps its tests in the Task folder and runs them by absolute path (our judgment; a design decision for the skill).
