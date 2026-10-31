# Walkway

Walkway is a methodology that takes one task from research to a validated change. This glossary fixes the words its skills and docs use.

## Language

**Walkway**:
A methodology that delivers one Task through five ordered Steps.

**Task**:
The unit of work Walkway delivers, described by one issue in the issue tracker.
_Avoid_: Ticket, job

**Workspace**:
The isolated copy of the project where one Task is delivered. All Steps of that Task work in the same Workspace.
_Avoid_: Worktree, sandbox

**Step**:
One of the five ordered stages of Walkway: Research, Development, Simplifier, Code Review, Validation. Each Step has one responsibility, one expected outcome and one Persona, and runs in its own Claude Code session.
_Avoid_: Phase, stage

**Product Context**:
The shared understanding of how the project works, how its customers behave and which problems it solves. It belongs to the project, not to a Task, and every Task reuses it.
_Avoid_: Project context, onboarding

**Source**:
A place Research reads to understand the project or a Task. The issue is always the first Source of a Task; project Sources serve every Task.
_Avoid_: Reference, input

**Roadmap**:
The outcome of Research for one Task: its goal, Acceptance Criteria, decisions, plan and what is out of scope. Every later Step works from it.
_Avoid_: Spec, plan

**Acceptance Criterion**:
One numbered, verifiable condition in the Roadmap that the Task must meet to be done.
_Avoid_: Requirement, definition of done

**Mock**:
An image of the intended UI attached to a Task. Walkway reproduces its structure, content and hierarchy as closely as the application's existing front-end rules allow, never pixel for pixel.
_Avoid_: Mockup, design, layout

**Finding**:
A problem that Code Review or Validation reports against the Roadmap or the project standards. A blocking Finding sends the Task back to Development.
_Avoid_: Issue, bug, comment

**Escalation**:
A question that no Step can answer from the Sources and the code, so only the user can decide it. Steps infer every other answer and record it as a decision.
_Avoid_: Clarification, check-in

**Research Gap**:
An Escalation raised by Code Review or Validation. The Roadmap should have closed that question, so it counts as a failure of Research.

**Lesson**:
A one-line rule the project learned from the retries, correction cycles and Escalations of an earlier Task. Every later Step follows it.
_Avoid_: Note, learning, memory

**Local Checks**:
The project's tests, linters, type checks and every other check its CI runs, executed on the user's machine. No Step hands off work while a Local Check fails.
_Avoid_: CI, pipeline, quality gate

**Readability rules**:
The general rules for readable code, valid in any language, that Development writes by, the Simplifier rewrites toward and Code Review judges by. They decide only what the project's own rules leave open.
_Avoid_: Style guide, coding standards

**Persona**:
The role the agent takes during a Step, such as an experienced product manager during Research.

**Coordinator**:
The role that moves a Task through the Steps, checks the outcome of each Step before the next one starts, and sends the work back to Development when Code Review or Validation fails. It never changes the code.
_Avoid_: Orchestrator
