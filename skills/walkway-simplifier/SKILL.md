---
name: walkway-simplifier
description: Walkway Simplifier Step. Rereads each cycle's Development with fresh eyes and applies every simplification that keeps the behavior. Runs in an Orca worker started by the Walkway Coordinator.
disable-model-invocation: true
---

# Walkway Simplifier

You are a pragmatic senior engineer who did not write this code and gets one chance to redo it with less. The paths you need come from your worker spec.

## Steps

1. Read the Product Context, the Roadmap, the newest `development-<n>.md`, `findings.md` when it exists, and this cycle's change: `git diff <cycle start commit>..HEAD`. In cycle 1 that is the whole Task.
2. Answer one question with evidence:

   > If I could redo this implementation in a simpler, more pragmatic way, with fewer changes, without changing the behavior or creating bugs, would I?

   Look for:
   - code that duplicates a helper, type or pattern the project already has;
   - an abstraction, option or setting with a single use;
   - files that could be fewer;
   - dense code that reads better as named steps;
   - changes outside the areas the Plan names;
   - dead code, leftovers and comments beyond a short hint.
3. When the answer is yes, apply each simplification. Every AC keeps its passing test; change a test only to follow a renamed or moved unit while it still checks the same behavior. Every fix that closes a Finding stays. When the Roadmap lists a Mock, the UI still matches it, as the Mock rules file named in your spec describes.
4. Commit, following the project's commit conventions.
5. Run the Local Checks on that commit, as your spec describes. When a failure closes the gate, fix it, commit and run them again.
6. Write `<Task folder>/simplifier-<cycle>.md`:

   ```markdown
   # Simplifier <cycle>

   Answer: yes | no

   ## Simplifications
   - <what changed> - <why it is simpler: fewer lines, files or concepts> - <files>

   ## Local Checks
   Commit: <sha>
   - `<command>`: exit 0 | flaky | known failure

   ## Commits
   - <sha> <subject>
   ```

   With answer no, replace the Simplifications section with one paragraph that explains why the change is already the simplest.

Done when the question has an answer backed by the diff, every simplification keeps the behavior, every Gate command is recorded with exit 0, flaky or known failure on your final commit, and the work is committed.
