# Workflow dependencies

The Claude workflows in `.github/workflows/` run code from outside this
repository: two GitHub Actions and the `code-review` plugin. Each is pinned, so
an upstream change cannot alter how pull requests are reviewed, or what the
review is allowed to do, without a reviewed pull request here. The cost is that
fixes upstream are not picked up automatically; every update is a deliberate
pull request through the lifecycle (`lifecycle.md`).

## What is pinned

| Dependency | Where | Pinned to |
|---|---|---|
| `actions/checkout` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `anthropics/claude-code-action` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `code-review` plugin | `vendor/claude-plugins/code-review/` | A verbatim copy of an upstream commit, recorded in `vendor/claude-plugins/README.md` |

The review workflow installs the plugin as `code-review@gimli` from this
repository's marketplace, `.claude-plugin/marketplace.json`. The action is
given the marketplace as a Git URL, `https://github.com/schalkje/Gimli.git`,
and clones its default branch, so the plugin that reviews a pull request is
always the one on `main`. A local path (`./`), which the action also accepts,
would read the plugin from the pull request's own checkout and let a pull
request change its own review.

The upstream plugin is not pinned by pinning a marketplace: the upstream
marketplace in `anthropics/claude-code` lists `code-review` as a `git-subdir`
source from `anthropics/claude-plugins-official` at `ref: main`.

## Update an action pin

1. Resolve the tag to a commit SHA, and find the exact version that commit
   carries:

   ```sh
   gh api repos/actions/checkout/commits/v6 --jq .sha
   gh api "repos/actions/checkout/tags?per_page=100" --jq '.[] | select(.commit.sha == "<sha>") | .name'
   ```

   Use `anthropics/claude-code-action` and `v1` for the other action. For a
   new major version, read its release notes first; that is a change in what
   the workflow does, not only a pin.
2. Replace the SHA and the trailing version comment in **both** workflows, so
   they stay on the same version:

   ```yaml
   - uses: actions/checkout@<sha> # v6.1.0
   ```

3. Open a pull request. Record the `gh api` output in its evidence.

## Re-vendor the plugin

1. Find the upstream commit to take, usually the newest that touches the
   plugin:

   ```sh
   gh api "repos/anthropics/claude-plugins-official/commits?path=plugins/code-review&per_page=5" \
     --jq '.[] | .sha + " " + .commit.committer.date + " " + (.commit.message | split("\n")[0])'
   ```

2. Replace `vendor/claude-plugins/code-review/` with the upstream directory at
   that commit. Fetch every file in the upstream tree raw, so the bytes are
   unchanged:

   ```sh
   gh api "repos/anthropics/claude-plugins-official/git/trees/<sha>?recursive=1" \
     --jq '.tree[] | select(.type == "blob" and (.path | startswith("plugins/code-review/"))) | .path'
   gh api -H "Accept: application/vnd.github.raw" \
     "repos/anthropics/claude-plugins-official/contents/<path>?ref=<sha>" > vendor/claude-plugins/code-review/<path minus plugins/code-review/>
   ```

   Delete files that upstream removed. Do not edit the copy.
3. Check it is identical (below), then update the commit, tree, version and
   date in `vendor/claude-plugins/README.md`.
4. Compare the `allowed-tools` frontmatter of
   `vendor/claude-plugins/code-review/commands/code-review.md` with the review
   workflow's `--allowedTools`. If upstream changed the list, decide whether to
   follow it; a widened list is a change in what the review may do and is
   assessed as such.
5. Open a pull request. It is reviewed with `/code-review <pr>`: the workflow
   still runs the plugin from `main`, so the new copy takes effect on the next
   pull request after the merge.

## Check the copy is identical

Equal Git tree hashes mean byte-identical files, on any platform.
`.gitattributes` marks `vendor/**` as `-text`, so Git never rewrites the
vendored files' line endings.

```sh
git rev-parse HEAD:vendor/claude-plugins/code-review
gh api "repos/anthropics/claude-plugins-official/contents/plugins?ref=<sha>" \
  --jq '.[] | select(.name == "code-review") | .sha'
```

Before committing, `git add vendor && git write-tree --prefix=vendor/claude-plugins/code-review/`
gives the same hash for the staged copy.

`claude plugin validate .` checks the marketplace and the plugin manifest.

## Changes to these files

A pull request that changes `claude-code-review.yml` is not reviewed by that
workflow, and one that changes `claude.yml` gets no mention-triggered replies,
because the action only runs a workflow file identical to the copy on `main`
(see `lifecycle.md`, Review). A pull request that changes the vendored plugin
is reviewed by the old copy. Review the first two with `/code-review <pr>`,
and in all three cases check the first run after the merge.
