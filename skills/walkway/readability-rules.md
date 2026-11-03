# Readability rules

Development writes code by these rules, the Simplifier rewrites the change toward them, and the Code Reviewer judges the change by them. They hold for any language. Rules about a language, a framework or a code style, such as comments or type signatures, belong to the project's rules, which win wherever they cover the same point. Over a habit of the surrounding code that no rule documents, and over a name or code shape the tech spec suggests, these rules win. The exception is React and GraphQL code: there the patterns the project already uses decide how each component, hook, query, mutation, fragment and schema type is built, and these rules decide the names and the flow inside it.

The bar is the **first read**: a reviewer who never saw the Task reads each changed method once and can tell what it does and why it exists, from its name and body alone.

## Names

- A name says what the thing holds or does, in the project's domain words: `send_customer_digests`, `test_ids_by_recipient`. A generic noun such as `rows`, `data`, `info`, `items` or `result` sends the reader into the body; name the content instead.
- One concept keeps one name across the change: the email's addressee is not a `recipient` in one method and a `user` in the next.

## Flow

- **Boring code.** Write the version a tired reader follows without effort: named intermediate values, plain conditionals and loops, three clear lines over one dense line. A chain that does several things at once, nested destructuring, metaprogramming and other language tricks fail the first read.
- **Named steps.** An entry point, such as a job, a service or a request handler, reads as a short list of named steps, one line for each thing it does. A job that sends two kinds of email calls `send_account_owner_digests` and `send_customer_digests`.
- A method works at one level: it either calls named steps or does one concrete thing.
- **Named data.** Data that passes between methods has named parts: a record, a map with named keys, or a type the project already uses. An array used as a tuple, or as a map key such as `[company, user]`, makes the reader decode positions.

## Size

- Reuse the helper, query or pattern the project already has before you write a new one.
- Add an abstraction, dependency, option or setting only for a concrete need of this Task. A little duplication beats a hasty abstraction.
