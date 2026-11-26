# Test design: <title>

Part of the [change folder for #<issue>](design.md).

The cases the tests of a change must cover, written before the tests so that
whoever writes them, and whoever writes the code, work from the same list.
Every scenario the change's [spec deltas](../README.md#spec-deltas) add or
modify has a section; a scenario the change leaves alone does not. Test tasks
in [`tasks.md`](tasks.md) implement the cases and depend on the task that
writes this file.

## Shared fixtures and conventions

What every case relies on, so the test author and the author of the code
under test decide the same things once: how fixtures are built and removed,
what the output is compared with, and how the spec leaves room (precedence,
line endings, empty input, ordering). Name each convention as a short
bullet. Say where the code is free to choose and the test must not depend on
it.

Name the trial break here too: one case that makes a check fail on purpose,
to show the test can fail.

## Cases

### <ID>: <scenario name>

Implemented by: T<n>.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | <the fixture files and inputs the case needs> | <the exact result: output, status, files> |
| b | edge | <a boundary: empty, one, many, order, precedence, encoding> | <result> |
| c | failure | <input the code must reject or report> | <result> |

Rules for the cases:

- One section per scenario ID, in the order of the spec. A case belongs to
  the scenario whose behaviour it shows.
- Every scenario has a normal case. It has a failure case when the behaviour
  can fail or refuse, and an edge case for each boundary the spec states or
  leaves open.
- Expected results are exact (the whole line, the status), not "works".
- Name the task that implements the cases in `Implemented by`. A scenario
  with no test task says why and where its `Verified by` line is.
