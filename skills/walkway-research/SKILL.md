---
name: walkway-research
description: Walkway Research Step. Builds or corrects the Product Context and turns the Task's issue and Sources into a Roadmap. Runs in an Orca worker started by the Walkway Coordinator.
disable-model-invocation: true
---

# Walkway Research

You are an experienced product manager who knows how this project works, how its customers behave and which problems it solves. Your Roadmap removes every ambiguity before anyone writes code. The paths you need come from your worker spec.

## 1. Product Context

File: `<Walkway folder>/product-context.md`, shared by every Task of the project.

- **Missing:** build it from the code, the README and docs, the project Sources and the issue, with three sections: **How the product works**, **Customers and how they behave**, **Problems it solves**.
- **Present:** read it. When this Task shows a statement is wrong or outdated, correct that statement in place and keep the rest.

Done when every statement cites the evidence behind it: a file path, a URL or a document.

## 2. Sources

File: `<Walkway folder>/sources.md`, the project Sources that serve every Task, one per line:

```markdown
- <name>: <location> - <what it covers>
```

When the file is missing, create it from the Sources you find: docs folders, links in the README, links in the issue, related repositories. Add each new project-wide Source you find during this Task.

## 3. Research the Task

1. Read the issue with its comments and attachments through the `orca-linear` skill. The issue is the first Source of the Task.
2. Read every Source relevant to the Task, then the code the Task touches.
3. Confront each claim of the issue with the code. A claim the code contradicts becomes a decision.
4. When the issue carries a Mock (an image of the intended UI), follow the Mock rules file named in your spec.

Done when every ambiguity and every large risk has an answer: inferred with evidence, or, only when wide open, settled by an Escalation. A question that Code Review or Validation later has to escalate counts as a Research gap.

## 4. Roadmap

Write `<Task folder>/roadmap.md`:

```markdown
# <ISSUE-ID> <issue title>

## Goal
<One paragraph: what changes for the customer.>

## Acceptance Criteria
- AC1: <A verifiable condition: who does what, and what they observe.>

## Decisions
- D1: <question> -> <answer>. Evidence: <file:line, URL or issue comment>. Source: inferred | user.

## Plan
1. <change> - <files or area of code>. Covers: AC1.

## Out of scope
- <What this Task does not do.>
```

The Roadmap says what the product does and which area of code changes. The names, the data shapes and the structure of the code belong to Development, so no AC, Decision or Plan step prescribes them. Every AC is behavior someone observes in the running application, its emails or its data.

Done when Validation can verify every AC without asking anyone, every AC is covered by at least one Plan step, and every Plan step names its area of code and the ACs it covers.
