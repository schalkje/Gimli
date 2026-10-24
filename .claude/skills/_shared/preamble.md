# Shared skill preamble

Every lifecycle stage skill starts by following this file. The skill that
cites it supplies three things: the **expected stage** label, the **comment
headings** a non-interactive run may post, and the rest of its own procedure.
Everything here is about the lifecycle contract (`docs/lifecycle.md`, the
`stage:*` labels, `scripts/stage.sh`, `scripts/risk.sh`); nothing here is
specific to one repository.

## 1. Arguments

- The issue number is the **first word** of the skill's arguments with any
  leading `#` removed. Ignore everything after it.
- If that is not a plain number, say so and stop.
- Never pass the raw arguments to a command; pass only the parsed number.

## 2. Session mode

Decide now, before reading anything, whether this session is:

- **interactive**: you can use `AskUserQuestion`, or the user can reply; or
- **non-interactive**: a `claude -p` run, a hook, a scheduled run, or any
  session with no way to ask and wait for an answer.

In a non-interactive session the only writes allowed are comments under the
headings the skill names for that purpose. A non-interactive run never edits
the issue body, posts a confirmed artifact, changes a label, or moves the
stage. When unsure which mode applies, treat the session as non-interactive.

Temporary files, such as a comment body to pass with `--body-file`, go in the
session's scratchpad directory when one is given, otherwise in the system
temporary directory. Never write them inside the repository.

## 3. Stage check

Read the issue:

```sh
gh issue view <n> --json title,body,state,labels,comments
```

- The stage is the `stage:*` label in the output. If it is not the expected
  stage, or the issue is closed, say which condition failed and stop. Only
  continue if the user explicitly tells you to.
- Read every comment before acting. `Stage:` transition comments from
  `scripts/stage.sh` and `Risk:` comments from `scripts/risk.sh` carry the
  notes that explain how the issue got here. Comments headed by one of the
  skill's own headings are earlier runs of the skill; the skill says what to
  do with each kind.

## 4. Duplicate guard

A non-interactive run is often repeated, by a schedule or a retry, against an
issue nobody has touched. Before posting a comment under heading `H`:

1. Find the most recent comment on the issue. If it is not headed `H`, post.
   If it is headed `H` but has been edited since it was posted
   (`includesCreatedEdit` is true in the `gh issue view` output), someone
   answered in place: post.
2. Otherwise find when the issue body was last edited:

   ```sh
   gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<n> \
     -f query='query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){issue(number:$n){createdAt lastEditedAt}}}' \
     --jq '.data.repository.issue | (.lastEditedAt // .createdAt)'
   ```

   `lastEditedAt` is null until the body is edited; the fallback is the
   creation time.
3. If the body edit time is earlier than that comment's `createdAt`, nothing
   has changed since the skill last spoke: post nothing and say so in your
   report, naming the existing comment.
4. If the body was edited after the comment, post.

The guard is by heading and timestamp, not by content: a regenerated comment
rarely matches the previous one word for word, so comparing text would not
stop the duplicate. Any newer comment, a body edit, or an edit to the guarded
comment re-arms the skill. A title or label change alone does not.
