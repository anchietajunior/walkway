# Properties

Development writes the tests of each Acceptance Criterion by these rules. Formal verification states each property by them and audits the tests against it.

## A property per Acceptance Criterion

```text
AC<n> property
Given: <precondition: the state and the input before the action>
When: <action: what the customer or the system does>
Then: <postcondition: the result a customer or a caller can observe>
Invariant: <what stays true before and after the action | none>
Breaks if: <one production change that would make it fail>
Generated inputs: yes | no - <why>
```

- Take every value from the AC or from a literal you checked by hand. An expected value computed by the code under test, or by its helpers, proves nothing.
- Choose the strongest shape the AC supports, weakest first:
  1. runs without error;
  2. returns the right type or shape;
  3. keeps an invariant;
  4. idempotent: doing it twice equals doing it once;
  5. round trip or oracle: decoding what you encoded gives the input back, or the result matches a simpler computation you trust.

  Write "examples only" when the AC supports nothing beyond fixed examples.
- An AC needs generated inputs when its text says always, never, any, every or all, or when its action takes input that varies: amounts, counts, strings, dates and time zones, collections, states.

## Example test

- At least one per AC, at the seam the customer uses: a request or integration test for a route, an execution of the GraphQL schema for a query or a mutation, the component rendered through the project's testing library for UI behavior, the job performed for a job.
- It asserts the postcondition and, when there is one, the invariant.
- Pair each "never does X" assertion with a case where X does happen, so the test shows it can see X.
- The test name states the property: `test "a refund never exceeds the captured amount"`.

## Generated-input test

Use the project's property-based testing library when it has one, such as fast-check, `pbt`, `prop_check` or `rantly`. Otherwise write a seeded loop in the project's test framework, with no new dependency:

- Take the seed from `PROPERTY_SEED` when it is set, otherwise a new random seed, and put the seed in every failure message.
- Run 100 iterations, or 500 for money and state-transition code.
- Build each input in a small named generator method.
- Test the edges first, as fixed examples of their own: empty, one, duplicates, zero, negative, the maximum, nil or null, and dates at month ends, daylight saving changes and other time zones.
- Keep every constraint inside a generator. An input skipped by a condition is a discard, and more than a tenth of discards means the generator is wrong.

```ruby
test "a refund never exceeds the captured amount" do
  seed = Integer(ENV.fetch("PROPERTY_SEED", Random.new_seed))
  random = Random.new(seed)

  100.times do
    captured_cents = random.rand(1..1_000_000)
    requested_cents = random.rand(0..2_000_000)

    refund = create_refund(captured_cents:, requested_cents:)

    assert_operator refund.amount_cents, :<=, captured_cents, "PROPERTY_SEED=#{seed}"
  end
end
```

```ts
test("a refund never exceeds the captured amount", () => {
  const seed = Number(process.env.PROPERTY_SEED ?? Date.now());
  const random = seededRandom(seed);

  for (let iteration = 0; iteration < 100; iteration += 1) {
    const capturedCents = random.integer(1, 1_000_000);
    const requestedCents = random.integer(0, 2_000_000);

    const refund = buildRefund({ capturedCents, requestedCents });

    expect(refund.amountCents, `PROPERTY_SEED=${seed}`).toBeLessThanOrEqual(capturedCents);
  }
});
```

`seededRandom` stands for the project's seeded generator; when it has none, a small one in the test file is enough.
