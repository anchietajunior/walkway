# Walkway

Walkway is a methodology that takes one task from planning to a verified change. This glossary fixes the words its skills and docs use.

## Language

**Walkway**:
A methodology that delivers one Task through three Stages, run by six Agents.

**Task**:
The unit of work Walkway delivers, described by one issue in the issue tracker.
_Avoid_: Ticket, job

**Workspace**:
The isolated copy of the project where one Task is delivered. Every Agent of that Task works in the same Workspace.
_Avoid_: Worktree, sandbox

**Stage**:
One of the three ordered parts of Walkway: Planning, Development and Verification.
_Avoid_: Phase, step

**Agent**:
One of the six roles of Walkway: Coordinator, Planning, Development, Simplifier, Code Reviewer and Verification, always named exactly so. Each Agent run is its own Claude Code session, started by the Coordinator as an Orca worker.
_Avoid_: Step, worker, subagent

**Contract**:
What an Agent reads, what it writes, when it is done and which Agent comes next. Work outside its Contract belongs to another Agent.

**Cycle**:
One pass that starts with a Development run and goes through the Simplifier and the Code Reviewer, and on to Verification when no finding is open. A finding of the Code Reviewer or of Verification starts the next Cycle.

**Product Context**:
The shared understanding of how the project works, how its customers behave and which problems it solves. It belongs to the project, not to a Task, and every Task reuses it.
_Avoid_: Project context, onboarding

**Resource**:
A place Planning reads to understand the project or a Task, such as a Notion page, a Linear project or a docs folder. The issue is always the first Resource of a Task; the Resources in `resources.md` serve every Task.
_Avoid_: Source, reference, input

**Tech spec**:
The outcome of Planning for one Task and the contract every later Agent works from: a Business half (goal, customers and flows, Acceptance Criteria, out of scope), a Technology half (codebase grounding, design, Contracts, test strategy, risks) and the Decisions.
_Avoid_: Roadmap, plan

**Acceptance Criterion**:
One numbered, verifiable condition in the tech spec that the Task must meet to be done.
_Avoid_: Requirement, definition of done

**Mock**:
An image of the intended UI attached to a Task. Walkway reproduces its structure, content and hierarchy as closely as the application's existing front-end rules allow, never pixel for pixel.
_Avoid_: Mockup, design, layout

**Finding**:
A Critical or Required problem that the Code Reviewer or Verification lists in its findings file. A findings file that lists a Finding sends the Task to a new Development session.
_Avoid_: Issue, bug, comment

**Suggestion**:
An Optional or Nit improvement the Code Reviewer or Verification reports. It goes to `report.html`, never to the PR body, and never starts a Cycle.

**Escalation**:
A question that no Agent can answer from the Resources and the code, so only the user can decide it. Agents infer every other answer and record it as a decision.
_Avoid_: Clarification, check-in

**Planning Gap**:
An Escalation raised by the Code Reviewer or Verification. The tech spec should have closed that question, so it counts as a failure of Planning.

**Lesson**:
A one-line rule the project learned from the retries, correction Cycles and Escalations of an earlier Task. Every later Agent follows it.
_Avoid_: Note, learning, memory

**Local Checks**:
The project's tests, linters, type checks and every other check its CI runs, executed on the user's machine. No Agent hands off work while a Local Check fails.
_Avoid_: CI, pipeline, quality gate

**Readability rules**:
The general rules for readable code, valid in any language, that Development writes by, the Simplifier rewrites toward and the Code Reviewer judges by. They decide only what the project's own rules leave open.
_Avoid_: Style guide, coding standards

**Persona**:
The role the Agent takes, such as an experienced product manager during Planning.

**Coordinator**:
The Agent that starts every other Agent, one at a time, checks each outcome against its gate, routes to the Agent the report names, and reports the progress to the user. It never writes code or scripts.
_Avoid_: Orchestrator
