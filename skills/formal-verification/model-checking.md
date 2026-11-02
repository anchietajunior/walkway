# Model checking (Layer 2)

A model checker explores every order of steps in a small model of the behavior, within the constants you set. It answers the question tests reach least: can these steps interleave or repeat into a bad state?

Layer 2 needs Java 11 or newer and the TLA+ tools at `~/.local/lib/tla2tools.jar`, from the official releases at https://github.com/tlaplus/tlaplus/releases. When either is missing, Layer 2 is a gap: record it with the trigger that called for it, and finish Layer 1.

## Steps

1. **Choose the promise.** Name, in one plain sentence, the strongest promise at risk in the triggered behavior, and the harm when it breaks: "a payment is captured at most once, even when the job retries", "an order never moves from refunded back to paid". Model that promise, not the easiest one.
2. **Write the model** in `<evidence folder>/model/`: PlusCal when the behavior reads as an algorithm, plain TLA+ otherwise.
   - Each actor that can interleave is a process: a request, a job, a retry, a webhook delivery, a browser tab.
   - Each atomic step in the code is one label: one database transaction, one locked block or one SQL statement. A read and a later write in separate statements, requests or jobs are two labels.
   - Above each label, a comment names the code it models: `\* Source: app/jobs/capture_payment_job.rb#perform`.
   - Names come from the code.
   - A correct finish is an explicit terminal state, so the deadlock check stays on.
   - Constants stay small: two or three actors, two or three retries, two values per field.
3. **Write the properties** in the model's `.cfg`: `TypeOK`, at least one domain invariant that states the promise, such as no double charge, a conserved balance or at most one active state, and a liveness property when the AC promises that something eventually happens.
4. **Witnesses first.** For each action, check once a temporary invariant that says the action never happens. TLC must report it violated, which shows the action can fire; a witness that already holds in the initial state proves nothing. Then remove the witnesses.
5. **Run TLC**, each command within 5 minutes:

   ```bash
   java -cp ~/.local/lib/tla2tools.jar pcal.trans <Model>.tla
   java -XX:+UseParallelGC -cp ~/.local/lib/tla2tools.jar tlc2.TLC -workers auto -config <Model>.cfg <Model>.tla
   ```

   Save the full output in the evidence folder. Read TLC's final summary: states generated, distinct states, depth, and either no error or the violated property with its trace. A run stopped by the timeout is partial: record the depth it reached.
6. **Able to fail.** Break a copy of the model the way the promise guards against: drop the lock, split the transaction, swap two steps, remove the idempotency check. TLC must report the violation. Keep that run's output as evidence.
7. **Read each counterexample in the code's words.** Retell the trace as numbered steps that name the code: "1. Job A reads the payment as pending (`capture_payment_job.rb#perform`)". Check each step against the code. A step the code cannot take is a modeling error: fix the model and run again. A trace the code can follow is a Critical Finding, with the steps as its problem and a regression test of that sequence as its fix. Never weaken an invariant or remove a behavior from the model to get a pass.
8. **Record** the promise, the constants, the properties checked, the distinct states, the depth, the run time, the map from each label to its code, and what the model leaves out: other actors, failures not modeled, values beyond the constants.
