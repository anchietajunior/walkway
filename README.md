# Walkway

Walkway is a collection of Claude Code skills that delivers one Linear issue through five Steps. Each Step has one responsibility, one expected outcome and one persona, and runs in its own Claude Code session. A Coordinator starts each Step as an Orca worker, moves the work between them, fixes its own Findings, and ends with a draft PR that carries the evidence. The user takes part only in strategic decisions.

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
| 2. Development | Pragmatic senior engineer who hates overengineering | Readable code and tests that meet every Acceptance Criterion, committed, with green Local Checks |
| 3. Simplifier | Pragmatic engineer with fresh eyes | The same behavior with fewer changes, or a reasoned "already simplest" |
| 4. Code Review | Independent staff engineer | Two review sessions, one per review skill, recording every Finding in one `findings.md` |
| 5. Validation | Experienced QA engineer | Fresh evidence and screenshots for every Acceptance Criterion in the running application, and a verdict |

### 1. Research

Research acts as an experienced product manager who deeply understands how the project works, how its customers behave and which problems it solves. When that Product Context is missing, Research builds it from the code, the docs and the project Sources; when the Task shows it is outdated, Research corrects it.

Then Research reads the Linear issue, its first Source, and every project Source listed in `.walkway/sources.md`. It removes ambiguity, confronts every assumption with the reality of the codebase, and writes a concise Roadmap: goal, Acceptance Criteria, decisions, plan and what is out of scope.

### 2. Development

Development implements the Roadmap with the simplest correct change that follows the project's conventions. It writes organized, readable code so the next agent or human understands it on the first read: clear names, explicit flow, abstractions only for a concrete need, and comments only as short hints on complex code. In Ruby, type signatures use RBS Inline. Every Acceptance Criterion gets a test.

### 3. Simplifier

The Simplifier opens a fresh session with the Research context and the Development change, and asks: "If I could redo this implementation in a simpler, more pragmatic way, with fewer changes, without changing the behavior or creating bugs, would I?" When the answer is yes, it lists and applies the simplifications before Code Review. It runs in every cycle, right after Development.

### 4. Code Review

Each cycle runs two Code Review sessions, one after the other, each with one review skill: Matt Pocock's `code-review` (Spec and Standards axes), then Addy Osmani's [`code-review-and-quality`](https://github.com/addyosmani/agent-skills) (tests first with mutation probes, then correctness, readability, architecture, security and performance). Both record their Findings in the Task's `findings.md`, one table labelled Critical, Required, Optional or Nit, with a Status for each row. A Critical or Required row starts a new cycle: Development fixes it and the Simplifier runs again, with no user involvement.

### 5. Validation

Validation acts as an experienced QA engineer. It proves every Acceptance Criterion again, in the running application, with evidence it produces itself, including a screenshot of everything a customer sees. It confronts the claims of Development and the Findings of Code Review, and records its own Findings in `findings.md`. A failure starts a new cycle the same way.

### Mocks

Some issues carry a Mock: an image of the intended UI. Mock tools lack the application's configuration, so Walkway reproduces a Mock as closely as the application's existing front-end rules allow, never pixel for pixel. The Mock decides structure, content and hierarchy; the components, tokens and patterns of the screens already built decide the exact values. Every deviation names the rule that caused it, and Validation compares each screen with its Mock side by side. The rules are in [skills/walkway/mocks.md](skills/walkway/mocks.md).

## Principles

- **Tell, don't ask.** Every Step researches the Sources deeply and infers its answers, recording each inference with its evidence. Only an Escalation, a wide-open question that only the user can decide, reaches the user, through the Coordinator, with the options and a recommendation. Code Review and Validation escalate only for a very large ambiguity or risk, and each such Escalation counts as a Research Gap.
- **Claims are checked, never trusted.** No Step hands off work while the project's tests, linters, type checks or any other CI check fail locally. The Coordinator runs those Local Checks again at every code gate, Code Review proves test coverage with mutation probes, and Validation produces its own evidence.
- **Only Development and the Simplifier change product code and tests.** Research, Code Review and Validation leave the Workspace as they received it.
- **Evidence travels with the PR.** Screenshots and Mocks are pushed to the `walkway-evidence` branch and embedded in the PR body, next to the Acceptance Criterion they prove.
- **Every Task improves the next.** A retrospective names the root cause of each retry, correction cycle and Escalation. Project causes become Lessons in `.walkway/lessons.md` that every later Step follows; causes in the Walkway skills become proposals in this repository's `improvements.md`, for the user to decide.
- **Bounded correction.** After three cycles, or after a Step needs a third run in one cycle, the Coordinator raises an Escalation.
- **The user merges.** Walkway stops at a draft PR and moves the Linear issue to its review state, with no comment.

## The `.walkway/` folder

Walkway keeps its files in a `.walkway/` folder at the root of the project's main checkout. The folder is ignored by git, so it is never versioned, any Step can update it at any time, and every Workspace of the project shares it.

```text
.walkway/
  product-context.md      How the product works, its customers, the problems it solves
  sources.md              Project Sources that serve every Task
  checks.md               Gate commands that mirror each CI check, and the checks left out
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
- Matt Pocock's `code-review` skill.
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

The skills are user-invoked: you type only `/walkway`; the Coordinator hands each Step skill to its worker.

## Start a Task

Create an Orca Workspace linked to the Linear issue, with a Claude session that starts the Coordinator:

```bash
orca worktree create --repo path:"$PWD" --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --prompt "/walkway"
```

You can also create the Workspace in the Orca app and type `/walkway` in its Claude session. Talk only to the Coordinator; it relays every Escalation.

## Start from the Grok Bot

The Grok Bot can start Walkway with no one at the keyboard: it reads Linear, picks an issue, and asks Orca to create the Workspace and start the Coordinator. The bot passes only the issue ID. The Coordinator reads the issue from Linear itself, so issue text never becomes an instruction.

### One-time setup

1. On the machine that runs the workers, copy the Orca runtime pairing link (`orca://pair?...`). `orca serve` prints it; when the Orca app already runs, take the link from the app. When the bot runs on another network, start the runtime with `--pairing-address` set to an address the bot can reach, such as a Tailscale name.
2. On the bot's machine, install the Orca CLI and save the runtime:

   ```bash
   orca environment add --name walkway-host --pairing-code "orca://pair?..."
   ```

3. Find the project's repository name with `orca repo list --environment walkway-host --json`.

### Instructions for the bot

Paste this into the Grok Bot's instructions, and fill in the selection rule and the repository name:

```text
You start Walkway Tasks in Orca for Linear issues.

1. Pick the issues to start: <selection rule, such as the team's Todo issues with the label "walkway">.
2. For each issue, check whether Orca already has a Workspace for it:
   orca reference find <ISSUE-ID> --environment walkway-host --json
   When it does, skip the issue.
3. Otherwise start it with exactly this command, changing only <ISSUE-ID>:
   orca worktree create --environment walkway-host --repo name:<repository name> --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --prompt "/walkway" --json
4. Move the issue to the team's started state, such as In Progress, and report the Workspace name.

The prompt is always exactly "/walkway", and <ISSUE-ID> is the only value you change. The Coordinator reads the issue, its comments and its attachments from Linear itself.
```

### After the start

The Coordinator and its workers run on the Orca host. An Escalation waits in the Coordinator's Claude session: open that Workspace in Orca to answer it. When the Task ends, the draft PR is open and the issue is in its review state.
