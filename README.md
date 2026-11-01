# Walkway

Walkway is a collection of Claude Code skills that delivers one Linear issue through five Steps. Each Step has one responsibility, one expected outcome and one persona, and runs in its own Claude Code session. A Coordinator starts each Step as an Orca worker, moves the work between them, and ends with a draft PR that carries the evidence. The Coordinator only coordinates: it never changes code, every build, test and code change runs in a worker, and each worker appears in the Orca Workspace as its own named Claude session, such as `ENG-123 · Development 1`. Development fixes every blocking Finding. The user takes part only in strategic decisions.

```text
Research -> Development -> Simplifier -> Code Review x2 -> Validation -> draft PR
                 ^                              |               |
                 +---- blocking Findings -------+---------------+
```

The words used here are defined in [GLOSSARY.md](GLOSSARY.md). The decisions behind the design are in [docs/adr/](docs/adr/).

## Steps

| Step | Persona | Outcome |
| --- | --- | --- |
| 1. Research | Experienced product manager | The Product Context, when missing or outdated, and a Roadmap with numbered Acceptance Criteria |
| 2. Development | Pragmatic senior engineer who hates overengineering; DHH in Rails code | Code that passes the first read and tests that meet every Acceptance Criterion, committed, with green Local Checks |
| 3. Simplifier | Pragmatic engineer with fresh eyes; Vladimir Dementyev in Rails code | The same behavior with fewer changes and code that reads better, or a reasoned "already simplest" |
| 4. Code Review | Independent staff engineer | Two review sessions, one per review skill, recording every Finding in one `findings.md` |
| 5. Validation | Experienced QA engineer | Fresh evidence and screenshots for every Acceptance Criterion in the running application, and a verdict |

### 1. Research

Research acts as an experienced product manager who deeply understands how the project works, how its customers behave and which problems it solves. When that Product Context is missing, Research builds it from the code, the docs and the project Sources; when the Task shows it is outdated, Research corrects it.

Then Research reads the Linear issue, its first Source, and every project Source listed in `.walkway/sources.md`. It removes ambiguity, confronts every assumption with the reality of the codebase, and writes a concise Roadmap: goal, Acceptance Criteria, decisions, plan and what is out of scope.

### 2. Development

Development implements the Roadmap with the simplest correct change that follows the project's rules. It writes boring code by the [Readability rules](skills/walkway/readability-rules.md), so the next agent or human understands it on the first read: names in the domain's words, entry points that read as named steps, data with named parts, and abstractions only for a concrete need. The Readability rules hold for any language; rules about a language, a framework or a code style, such as comments or type signatures, come from the project's own rules, which win wherever both cover the same point. The Roadmap never prescribes the shape of the code. Every Acceptance Criterion gets a test. In Rails code, Development reasons as DHH: vanilla Rails first, rich models, thin REST controllers and clarity over cleverness, inside the stack the project already uses.

### 3. Simplifier

The Simplifier opens a fresh session with the Research context and the Development change, and asks two questions: "If I could redo this implementation in a simpler, more pragmatic way, with fewer changes, without changing the behavior or creating bugs, would I?" and "Does every changed method pass the first read?" It applies every simplification and rewrites every method that fails the first read before Code Review. It runs in every cycle, right after Development. In Rails code, the Simplifier reasons as Vladimir Dementyev, author of Layered Design for Ruby on Rails Applications: each piece of logic sits in its layer, and a new abstraction stays only when it removes complexity from the change.

### 4. Code Review

Each cycle runs two Code Review sessions, one after the other, each with one review skill: Compound Engineering's [`ce-code-review`](https://github.com/EveryInc/compound-engineering-plugin) (reviewer personas for correctness, tests, maintainability and the project's standards, plus security, performance or reliability when the change touches them), then Addy Osmani's [`code-review-and-quality`](https://github.com/addyosmani/agent-skills) (tests first with mutation probes, then correctness, readability, architecture, security and performance). Both record their Findings in the Task's `findings.md`, one table labelled Critical, Required, Optional or Nit, with a Status for each row. A Critical or Required row starts a new cycle: Development fixes it and the Simplifier runs again, with no user involvement.

### 5. Validation

Validation acts as an experienced QA engineer. It proves every Acceptance Criterion again, in the running application, with evidence it produces itself, including a screenshot of everything a customer sees. It confronts the claims of Development and the Findings of Code Review, and records its own Findings in `findings.md`. A failure starts a new cycle the same way.

### Mocks

Some issues carry a Mock: an image of the intended UI. Mock tools lack the application's configuration, so Walkway reproduces a Mock as closely as the application's existing front-end rules allow, never pixel for pixel. The Mock decides structure, content and hierarchy; the components, tokens and patterns of the screens already built decide the exact values. Every deviation names the rule that caused it, and Validation compares each screen with its Mock side by side. The rules are in [skills/walkway/mocks.md](skills/walkway/mocks.md).

## Principles

- **One session per Step.** Orca orchestration starts every Step as its own Claude Code session, in every cycle. No Step and no Coordinator starts subagents: when a skill asks for them, the worker runs each part itself, one after the other.
- **The project's rules win.** Every Step follows the rules the project documents: `CLAUDE.md` and `AGENTS.md` at every level, `.claude/rules/`, `CONTRIBUTING.md` and the docs they point to. Where one differs from a Walkway skill on the code, tests, docs, commits or how to run the project, the project rule wins; the Walkway flow stays as the skills say.
- **Domain words.** Everything Walkway writes, from code to the PR body, names customers, users and every other actor by their role, never as "people".
- **Tell, don't ask.** Every Step researches the Sources deeply and infers its answers, recording each inference with its evidence. A question with an option the agent would recommend is decided by taking that option and listing it in the final report. Only an Escalation, a question with no safe default that only the user can decide, reaches the user, through the Coordinator, with the options and a recommendation. Code Review and Validation escalate only for a very large ambiguity or risk, and each such Escalation counts as a Research Gap.
- **Claims are checked, never trusted.** No Step hands off work while the project's tests, linters, type checks or any other CI check fail locally. Development builds `.walkway/checks.md` from the CI configuration on its own, with the local setup the project documents, commands scoped to the Task, bounded parallel tests and a 5-minute ceiling per command; a slower command is treated as a hang. The full suites run in CI on the PR. Validation runs every Local Check again on the reviewed commit, Code Review proves test coverage with mutation probes, and Validation produces its own evidence.
- **Only Development and the Simplifier change product code and tests.** Research, Code Review and Validation leave the Workspace as they received it, and the Coordinator changes no code.
- **Evidence travels with the PR.** The PR body follows the project's PR template and adds one short `Evidence` section: one line per Acceptance Criterion with how Validation proved it, one for the Local Checks and one for the cycles run. Screenshots go in only when the Task changes the front end: Validation picks the screenshots of the changed screens, and they go with the Mocks to the `walkway-evidence` branch and into the template's visual section. Without a front-end change, that section says only "No UI change.".
- **Every Task improves the next.** A retrospective names the root cause of each retry, correction cycle and Escalation. Project causes become Lessons in `.walkway/lessons.md` that every later Step follows; causes in the Walkway skills become proposals in this repository's `improvements.md`, for the user to decide.
- **The flow runs on messages.** Each worker reports to the Coordinator through Orca with `worker_done`, or asks with `ask`; the Coordinator answers, applies the gate and starts the next worker in the same turn. Its state lives in `coordinator.md` and in Orca, and it runs under `/loop`, so a lost turn resumes from that state until the draft PR or an Escalation.
- **Bounded correction.** After three cycles, or after a Step needs a third run in one cycle, the Coordinator raises an Escalation.
- **The user merges.** Walkway stops at a draft PR and moves the Linear issue to its review state, with no comment.

## The `.walkway/` folder

Walkway keeps its files in a `.walkway/` folder at the root of the project's main checkout. The folder is ignored by git, so it is never versioned, any Step can update it at any time, and every Workspace of the project shares it.

```text
.walkway/
  product-context.md      How the product works, its customers, the problems it solves
  sources.md              Project Sources that serve every Task
  checks.md               Gate commands that mirror each CI check, the checks left out, flaky and known failures
  lessons.md              Rules learned from earlier Tasks
  tasks/<ISSUE-ID>/
    coordinator.md        Run, base commit, Step log and Escalations
    roadmap.md            Research outcome
    mocks/                Mock images from the issue
    development-<n>.md    One per cycle
    simplifier-<n>.md     One per cycle
    findings.md           Every Finding of the Task, its Status, and the review log
    validation-<n>.md     One per cycle
    evidence/             Validation screenshots and logs
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

- Addy Osmani's agent skills, installed as a Claude Code plugin so the skill keeps its reference checklists:

  ```text
  /plugin marketplace add addyosmani/agent-skills
  /plugin install agent-skills@addy-agent-skills
  ```

## Install

Link each skill into your Claude Code skills folder, from the root of this repository:

```bash
for skill_dir in "$PWD"/skills/*; do ln -s "$skill_dir" ~/.claude/skills/; done
```

You type only `/loop /walkway`. The `walkway` skill stays model-invocable, because `/loop` fires it through the Skill tool on every wake-up; its description limits it to an explicit `/walkway`. The Step skills are user-invoked: the Coordinator hands each one to its worker by path.

## Start a Task

Create an Orca Workspace linked to the Linear issue, with a Claude session that starts the Coordinator:

```bash
orca worktree create --repo path:"$PWD" --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --surface terminal --prompt "/loop /walkway"
```

You can also create the Workspace in the Orca app and type `/loop /walkway` in its Claude terminal session. `/loop` wakes the Coordinator again if its turn ends before the draft PR. Talk only to the Coordinator; it relays every Escalation.

## Start from the Grok Bot

The Grok Bot can start Walkway from just a Linear issue ID. It runs on the same machine as Orca and only starts the Coordinator; the Coordinator creates the Orca orchestration Run and the Step workers itself. The bot passes only the issue ID, so issue text never becomes an instruction.

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

The Coordinator and its workers run in Orca on this machine. An Escalation waits in the Coordinator's Claude session: open that Workspace in Orca to answer it. When the Task ends, the draft PR is open and the issue is in its review state.
