# Walkway

Walkway is a collection of Claude Code skills that delivers one Linear issue through three stages, Planning, Development and Verification, run by six agents. Each agent has one responsibility, one contract and one persona, and runs in its own Claude Code session. The Coordinator starts each agent as an Orca worker, one at a time, follows every agent and document, and ends with a draft PR that carries the evidence. The Coordinator only coordinates: it never changes code, and every build, test and code change runs in an agent. The user takes part only in strategic decisions.

```text
Planning -> Development -> Simplifier -> Code Reviewer -> Verification -> draft PR
                 ^                             |                |
                 +---- code-review-findings ---+                |
                 +---- verification-findings -------------------+
```

The words used here are defined in [GLOSSARY.md](GLOSSARY.md). The decisions behind the design are in [docs/adr/](docs/adr/).

## Agents

Every agent is named exactly as below, in Orca and in every Walkway file.

| Stage | Agent | Persona | Outcome | Next |
| --- | --- | --- | --- | --- |
| | Coordinator | Tech lead | Every agent started, followed and gated; progress reported to the user; the draft PR | |
| Planning | Planning | Product manager and senior engineer | The tech spec: half business, half technology | Development |
| Development | Development | Pragmatic senior engineer who hates overengineering; DHH in Rails code | Code and tests for the tech spec or the findings, committed, with green Local Checks | Simplifier |
| Development | Simplifier | Pragmatic engineer with fresh eyes; Vladimir Dementyev in Rails code | The same behavior with fewer changes and code that reads better | Code Reviewer |
| Development | Code Reviewer | Independent staff engineer | Two reviews in one session and `code-review-findings.md` | Development with findings, otherwise Verification |
| Verification | Verification | Verification and QA engineer | The tech spec confronted with the code, formal verification, proof in the running application, and `verification-findings.md` | Development with findings, otherwise Coordinator |

Each agent names the next agent in its report, and the Coordinator starts it. No agent starts another: in Orca the agent that starts a worker must stay alive until that worker reports, so a chain of agents would keep every session of the chain alive.

### Coordinator

The Coordinator delegates and follows the whole flow. It starts each agent, checks the outcome against the agent's gate, routes to the agent the report names, answers questions from the Resources, and brings only Escalations to the user. After each gate it tells the user in one line which agent finished, the result and the next agent.

### Planning

Planning acts as an experienced product manager who also knows the codebase. It builds or corrects the Product Context, reads the Linear issue, its first Resource, and every Resource listed in `.walkway/resources.md`, such as Notion pages, Linear projects and docs. It removes ambiguity, confronts every assumption with the codebase, and writes the tech spec, the contract of the Task:

- **Business**: goal, customers and their flows, numbered Acceptance Criteria, out of scope.
- **Technology**: codebase grounding, design by area of code and data flow, Contracts (schema, APIs, jobs, flags, emails), test strategy per AC, risks.
- **Decisions**, each with its evidence.

The tech spec says what changes and which interfaces hold; names and code shapes belong to Development.

### Development

Development implements the tech spec with the simplest correct change that follows the project's rules. It writes boring code by the [Readability rules](skills/walkway/readability-rules.md), so the next agent or human understands it on the first read: names in the domain's words, entry points that read as named steps, data with named parts, and abstractions only for a concrete need. The Readability rules hold for any language; rules about a language, a framework or a code style, such as comments or type signatures, come from the project's own rules, which win wherever both cover the same point. Every Acceptance Criterion gets an example test, and a generated-input test when its property needs one, by the [Property rules](skills/formal-verification/properties.md). In Rails code, Development reasons as DHH. In React and GraphQL code, it builds each piece the way the project already builds its neighbors.

In a correction cycle, a new Development session receives one findings file and handles it with Superpowers' `receiving-code-review`: it verifies each finding before acting, then fixes it or rejects it with evidence. A Verification finding is confronted with the tech spec; when the tech spec itself is wrong, Development raises an Escalation instead of changing it.

### Simplifier

The Simplifier opens a fresh session with the tech spec and the Development change, and asks two questions: "If I could redo this implementation in a simpler, more pragmatic way, with fewer changes, without changing the behavior or creating bugs, would I?" and "Does every changed method pass the first read?" It applies every simplification and rewrites every method that fails the first read. It runs in every cycle, right after Development. In Rails code, it reasons as Vladimir Dementyev, author of Layered Design for Ruby on Rails Applications.

### Code Reviewer

One Code Reviewer session runs two reviews, one after the other: Compound Engineering's [`ce-code-review`](https://github.com/EveryInc/compound-engineering-plugin) (reviewer personas for correctness, tests, maintainability and the project's standards, plus security, performance or reliability when the change touches them), then Superpowers' [`requesting-code-review`](https://github.com/lucianghinda/superpowers-ruby) (code quality, architecture, tests, requirements and production readiness). It runs every persona and reviewer itself, with no subagent. Critical and Required findings go to `code-review-findings.md`, which a new Development session receives; Optional and Nit findings become suggestions in the PR. With no finding listed, the flow goes to Verification.

### Verification

Verification confronts the tech spec with the code that Development, the Simplifier and the Code Reviewer produced. It reads the reports of those agents only for their answers to its own earlier findings, because they are claims; the tech spec is the truth. It traces every AC, Contract, Decision and changed file between the tech spec and the code, then verifies the change formally with the [`formal-verification`](skills/formal-verification/SKILL.md) skill: each Acceptance Criterion becomes a written property, its tests are audited and run, every changed line must be reached, mutation probes break the changed code, and TLA+ model checking runs when the change touches concurrency, a state machine, retries, idempotency or money. Then it proves every Acceptance Criterion in the running application, with screenshots of everything a customer sees. Each mismatch goes to `verification-findings.md`, which a new Development session receives; with no finding listed, the Coordinator delivers.

### Mocks

Some issues carry a Mock: an image of the intended UI. Mock tools lack the application's configuration, so Walkway reproduces a Mock as closely as the application's existing front-end rules allow, never pixel for pixel. The Mock decides structure, content and hierarchy; the components, tokens and patterns of the screens already built decide the exact values. Every deviation names the rule that caused it, and Verification compares each screen with its Mock side by side. The rules are in [skills/walkway/mocks.md](skills/walkway/mocks.md).

## Limits

Each agent's skill opens with a **Contract**: what it reads, what it writes, when it is done and which agent comes next. Work outside the contract belongs to another agent. The Coordinator enforces the limits that keep the machine free:

- **One agent at a time.** At most two Claude sessions of a Task are alive: the Coordinator's and the running agent's.
- **A new session per run.** Every agent run is a new Orca worker, in every cycle, and it ends right after it reports. Finished workers close; nobody keeps them open.
- **No subagents.** No agent and no Coordinator starts subagents, Workflows, agent teams or other workers. When a skill asks for subagents, the agent runs each part itself, one after the other.
- **Bounded runs.** Two runs per agent per cycle, three cycles per Task, and five minutes per command; more needs an Escalation.

## Principles

- **The project's rules win.** Every agent follows the rules the project documents: `CLAUDE.md` and `AGENTS.md` at every level, `.claude/rules/`, `CONTRIBUTING.md` and the docs they point to. Where one differs from a Walkway skill on the code, tests, docs, commits or how to run the project, the project rule wins; the Walkway flow stays as the skills say.
- **Domain words.** Everything Walkway writes, from code to the PR body, names customers, users and every other actor by their role, never as "people".
- **Tell, don't ask.** Every agent researches the Resources deeply and infers its answers, recording each inference with its evidence. A question with an option the agent would recommend is decided by taking that option and listing it in the final report. Only an Escalation, a question with no safe default that only the user can decide, reaches the user, through the Coordinator, with the options and a recommendation. Code Reviewer and Verification escalate only for a very large ambiguity or risk, and each such Escalation counts as a Planning gap.
- **Claims are checked, never trusted.** No agent hands off work while the project's tests, linters, type checks or any other CI check fail locally. Development builds `.walkway/checks.md` from the CI configuration on its own, with commands scoped to the Task, bounded parallel tests and a 5-minute ceiling per command. The full suites run in CI on the PR. Verification runs every Local Check again on the reviewed commit and produces its own evidence.
- **Only Development and the Simplifier change product code and tests.** Planning, Code Reviewer and Verification leave the Workspace as they received it, Verification restoring each mutation probe right after it runs, and the Coordinator changes no code.
- **Evidence travels with the PR.** The PR body follows the project's PR template and adds one short `Evidence` section: one line per Acceptance Criterion with how Verification proved it, one for the Local Checks, one for the cycles run, and the Code Reviewer's suggestions. Screenshots go in only when the Task changes the front end: they go with the Mocks to the `walkway-evidence` branch and into the template's visual section. Without a front-end change, that section says only "No UI change.".
- **Every Task improves the next.** A retrospective names the root cause of each retry, correction cycle and Escalation. Project causes become Lessons in `.walkway/lessons.md` that every later agent follows; causes in the Walkway skills become proposals in this repository's `improvements.md`, for the user to decide.
- **The flow runs on messages.** Each agent reports to the Coordinator through Orca with `worker_done`, or asks with `ask`; the Coordinator answers, applies the gate and starts the next agent in the same turn. Its state lives in `coordinator.md` and in Orca, and it runs under `/loop`, so a lost turn resumes from that state until the draft PR or an Escalation.
- **The user merges.** Walkway stops at a draft PR and moves the Linear issue to its review state, with no comment.

## The `.walkway/` folder

Every Walkway file of a project lives in a `.walkway/` folder at the root of the project's main checkout, temporary files included. The folder is ignored by git, in the repository's shared `info/exclude` from the first run and in `.gitignore` from the first Task's PR, so it is never versioned, any agent can update it at any time, and every Workspace of the project shares it.

```text
.walkway/
  product-context.md          How the product works, its customers, the problems it solves
  resources.md                Resources that serve every Task: Notion, Linear, docs, repositories
  checks.md                   Gate commands that mirror each CI check, the checks left out, flaky and known failures
  lessons.md                  Rules learned from earlier Tasks
  tasks/<ISSUE-ID>/
    coordinator.md            Run, base commit, agent log and Escalations
    tech-spec.md              Planning outcome
    mocks/                    Mock images from the issue
    development-<n>.md        One per cycle
    simplifier-<n>.md         One per cycle
    code-review-<n>.md        Both reviews and the suggestions, one per cycle
    code-review-findings.md   Open Critical and Required review findings
    formal-verification-<n>.md  Formal verification report, one per cycle
    verification-<n>.md       Verdict, spec-to-code trace and application evidence, one per cycle
    verification-findings.md  Open Critical and Required verification findings
    evidence/                 Verification screenshots and logs
    tmp/                      Temporary files of any agent
```

## Requirements

- Claude Code.
- Orca, with the `orchestration` and `orca-linear` skills installed (`orca skills install`) and Linear connected.
- The GitHub CLI (`gh`), signed in.
- Claude Code permissions for unattended workers. Workers run in terminals nobody watches and write to the main checkout's `.walkway/` folder, outside their Workspace. A permission prompt there stalls the Task, so allow those edits and the project's commands in your Claude Code settings before the first Task.
- The Compound Engineering plugin, for `ce-code-review` and its reviewer personas:

  ```text
  /plugin marketplace add EveryInc/compound-engineering-plugin
  /plugin install compound-engineering@compound-engineering-plugin
  ```

- The Superpowers Ruby plugin, for `requesting-code-review` and `receiving-code-review`:

  ```text
  /plugin marketplace add lucianghinda/superpowers-ruby
  /plugin install superpowers-ruby@superpowers-ruby
  ```

- Java 11 or newer and the TLA+ tools at `~/.local/lib/tla2tools.jar`, from the [TLA+ releases](https://github.com/tlaplus/tlaplus/releases), for model checking. Without them, a Task whose change needs model checking ends in an Escalation.
- Tools to read the Notion pages listed in `resources.md`, such as a Notion MCP server, when the project keeps its docs there.

## Install

Link each skill into your Claude Code skills folder, from the root of this repository:

```bash
for skill_dir in "$PWD"/skills/*; do ln -sfn "$skill_dir" ~/.claude/skills/; done
```

You type only `/loop /walkway`. The `walkway` skill stays model-invocable, because `/loop` fires it through the Skill tool on every wake-up; its description limits it to an explicit `/walkway`. The agent skills are user-invoked: the Coordinator hands each one to its worker by path. `formal-verification` is model-invocable, so you can also ask Claude to verify any change formally outside Walkway.

## Start a Task

Create an Orca Workspace linked to the Linear issue, with a Claude session that starts the Coordinator:

```bash
orca worktree create --repo path:"$PWD" --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --surface terminal --prompt "/loop /walkway"
```

You can also create the Workspace in the Orca app and type `/loop /walkway` in its Claude terminal session. `/loop` wakes the Coordinator again if its turn ends before the draft PR. At setup, the Coordinator names the Workspace `<ISSUE-ID> <issue title>`, as the Orca app does, however the Workspace was created. Talk only to the Coordinator; it relays every Escalation.

## Start from the Grok Bot

The Grok Bot can start Walkway from just a Linear issue ID. It runs on the same machine as Orca and only starts the Coordinator; the Coordinator creates the Orca orchestration Run and the agents itself. The bot passes only the issue ID, so issue text never becomes an instruction.

Paste this prompt into the bot's instructions. Repositories maps each Linear team key to its Orca repository, as `orca repo list --json` names it; add one line per team:

```text
You start Walkway in the local Orca for one Linear issue. The user gives you an issue ID, such as ENG-123, or its Linear URL.

Repositories (Linear team key -> Orca repository):
- ENG: platform

1. Take the issue ID; from a URL, use the path segment after /issue/. It must match ^[A-Z][A-Z0-9]{0,9}-[0-9]+$. With any other value, stop and report the invalid input.
2. Look up the team key, the part before the dash, in Repositories. With no entry, stop and report the missing mapping.
3. Run `orca status --json`. When the runtime is not reachable, run `orca open --json` and check again.
4. Run `orca reference find <ISSUE-ID> --json`. When it lists a Workspace for the issue, report that Workspace and stop.
5. Start the Coordinator:
   orca worktree create --repo name:<repository> --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --surface terminal --prompt "/loop /walkway" --json
   Keep result.launch.outcome.handle from the receipt. When the command reports a lost launch reply, run it again with --retry-launch <operationId> from the error; a fresh create would make a second Workspace.
6. After about 20 seconds, run `orca terminal read --terminal <handle> --screen`. Claude working on /walkway means the Coordinator runs. An idle Claude prompt means the prompt never arrived: send it once with `orca terminal send --terminal <handle> --text "/loop /walkway" --enter`, then read the screen again.
7. Move the issue to the team's started state, such as In Progress: list the states with `orca linear team states --team <TEAM> --json`, then run `orca linear status set <ISSUE-ID> --to "<state>" --json`.
8. Report the issue ID, the Workspace name, the terminal handle and the Linear state.

The issue ID is the only value you pass to Orca, and the prompt is always exactly "/loop /walkway". The Coordinator reads the issue, its comments and its attachments from Linear, and runs the Orca orchestration itself.
```

Then ask the bot: "Start Walkway for ENG-123".

The Coordinator and its agents run in Orca on this machine. An Escalation waits in the Coordinator's Claude session: open that Workspace in Orca to answer it. When the Task ends, the draft PR is open and the issue is in its review state.
