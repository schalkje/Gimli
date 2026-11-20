# Workflow dependencies

The Claude workflows in `.github/workflows/` run code from outside this
repository: two GitHub Actions and the `code-review` plugin. Each is pinned, so
an upstream change cannot alter how pull requests are reviewed, or what the
review is allowed to do, without a reviewed pull request here, except what
the pinned action downloads at run time (see the limits under What the
review loads). The cost is that
fixes upstream are not picked up automatically; every update is a deliberate
pull request through the lifecycle (`lifecycle.md`).

## What is pinned

| Dependency | Where | Pinned to |
|---|---|---|
| `actions/checkout` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `anthropics/claude-code-action` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `code-review` plugin | `vendor/claude-plugins/code-review/` | A verbatim copy of an upstream commit, recorded in `vendor/claude-plugins/README.md` |

The upstream plugin is not pinned by pinning a marketplace: the upstream
marketplace in `anthropics/claude-code` lists `code-review` as a `git-subdir`
source from `anthropics/claude-plugins-official` at `ref: main`.

## What the review loads

A pull request cannot change the plugin that reviews it, or load its own
settings, hooks, skills or MCP servers into the review. It can still put text
in front of the reviewer through files the plugin reads; see the limits.

- **The plugin comes from `main`.** The review workflow installs
  `code-review@gimli` from this repository's marketplace,
  `.claude-plugin/marketplace.json`. The action is given the marketplace as
  this repository's Git URL, built from the workflow context as
  `${{ github.server_url }}/${{ github.repository }}.git` so that it follows a
  rename or a copy of the repository, and clones its default branch. A local
  path (`./`), which the action also accepts, would read the plugin from the
  pull request's checkout.
- **The action restores the root configuration from the base branch.** On
  every pull request event, before it installs plugins or starts Claude Code,
  the action copies the pull request's `.claude`, `.mcp.json`,
  `.claude.json`, `.gitmodules`, `.ripgreprc`, `CLAUDE.md`,
  `CLAUDE.local.md`, `AGENTS.md` and `.husky` into `.claude-pr/`, deletes
  them, and restores the versions on the pull request's base branch
  (`pull_request.base.ref`), which is `main` for every pull request the
  lifecycle opens. A stacked pull request gets its base branch's versions
  instead (`restoreConfigFromBase` in
  `src/github/operations/restore-config.ts`, called from
  `src/entrypoints/run.ts`, at the pinned `cc98b3a`). The plugin install
  therefore never sees the pull request's settings, and the reviewers can
  still read the pull request's versions in `.claude-pr/`.
- **The session loads no project configuration.** The workflow passes
  `--setting-sources user` in `claude_args`, so Claude Code loads neither
  `main`'s restored project configuration nor any nested `CLAUDE.md` or
  `.claude/` directory, which the restore does not cover because it handles
  root paths only. The action passes the option to the SDK and documents it
  "to avoid in-repo configs" (`base-action/src/parse-sdk-options.ts`). The
  plugin is installed at user scope, and the action passes its own MCP
  servers with `--mcp-config`, so neither depends on project settings. Local
  canary tests: a default run obeyed a root `CLAUDE.md` rule, a nested
  `CLAUDE.md` rule and a `SessionStart` hook, and loaded a `.mcp.json`
  server; a `--setting-sources user` run did none of these.
- **The plugin's agents read the pull request's checkout.** The job checks
  out the pull request, so the plugin's validators confirm findings against
  the changed code. The compliance check reads the root `CLAUDE.md` as the
  base branch has it, so a pull request that changes the root rules is
  checked against the old ones, and nested `CLAUDE.md` files as the pull
  request has them, as data.

The limits:

- A pull request can add or edit a nested `CLAUDE.md`, or put text in
  `.claude-pr/`, and the compliance agents read it, so it can try to steer
  the review's judgement, for example by declaring its changes pre-approved.
  It cannot run anything or change the review's tools. Treat a clean review
  of a pull request that changes a `CLAUDE.md` with that in mind.
- The pinned action downloads its runtime when it runs: Claude Code with
  `curl -fsSL https://claude.ai/install.sh | bash -s -- <version>`, Bun 1.4.4
  through a SHA-pinned `oven-sh/setup-bun`, and its npm dependencies with
  `bun install --production`. The versions are fixed by the pinned action,
  but none of these downloads is checked against a hash by this repository,
  so they can change without a pull request here.
- Whatever is on `main` reviews every open pull request. The `protect-main`
  ruleset admits changes to `main` only through a pull request, but admin
  credentials, including those Claude runs with, could change or remove the
  ruleset (`lifecycle.md`, Review).
- `claude.yml` gets the same root restore on pull request events, but not
  `--setting-sources user`, so it loads `main`'s project configuration and
  any nested `CLAUDE.md` it reads. It acts only for people with write access.
- Whenever the action pin moves, check again that `restoreConfigFromBase`
  still runs before the plugin install, which paths and which base branch it
  uses, that `--setting-sources` still reaches the session, and that
  `claude plugin install` still installs at user scope, which
  `--setting-sources user` needs to load the plugin.

## Update an action pin

1. Resolve the tag to a commit SHA, and find the exact version that commit
   carries. `--paginate` matters: `claude-code-action` has more than 100 tags.

   ```sh
   gh api repos/actions/checkout/commits/v6 --jq .sha
   gh api --paginate "repos/actions/checkout/tags?per_page=100" --jq '.[] | select(.commit.sha == "<sha>") | .name'
   ```

   If no exact version tag points at that commit, pin the newest release
   within the same major version instead. List the releases with
   `gh api --paginate "repos/<owner>/<repo>/releases?per_page=100" --jq '.[].tag_name'`,
   take the newest `v1.*` (or `v6.*`) tag, and resolve it with
   `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`. Do not use
   `releases/latest`, which can be a new major version. The trailing comment
   always names a tag that points at the pinned SHA.

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
   that commit, on the pull request's branch. Fetch the commit into a
   temporary repository, so this clone gets no foreign objects and no
   `.git/shallow`, empty the directory, including untracked files, and extract
   the subtree with `git archive`. `core.autocrlf=false` stops `git archive`
   from converting line endings on Windows:

   ```sh
   tmp=$(mktemp -d)
   git -C "$tmp" init -q
   git -C "$tmp" fetch -q --depth 1 https://github.com/anthropics/claude-plugins-official.git <sha>
   rm -rf vendor/claude-plugins/code-review
   mkdir -p vendor/claude-plugins/code-review
   git -C "$tmp" -c core.autocrlf=false archive FETCH_HEAD:plugins/code-review | tar -x -C vendor/claude-plugins/code-review
   rm -rf "$tmp"
   git add -A vendor/claude-plugins/code-review
   ```

   Do not edit the copy. `git archive` and `tar` are not verbatim in every
   case: upstream `export-ignore` or `export-subst` attributes, symlinks
   (which Git Bash's `tar` may copy), and executable files on a clone with
   `core.filemode=false` can all come out different. The check below catches
   any of these. If it fails, re-vendor in a throwaway clone of this
   repository instead: `git fetch --depth 1 <upstream> <sha>`, then
   `git rm -r -q vendor/claude-plugins/code-review` and
   `git read-tree --prefix=vendor/claude-plugins/code-review/ -u FETCH_HEAD:plugins/code-review`,
   which copies the tree exactly; commit there and push the branch.
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

Equal Git tree hashes mean identical files, modes, and symlinks, on any
platform. `.gitattributes` marks `vendor/claude-plugins/*/**` as `-text`, so
Git never rewrites a vendored plugin's line endings.

```sh
git rev-parse HEAD:vendor/claude-plugins/code-review
gh api "repos/anthropics/claude-plugins-official/contents/plugins?ref=<sha>" \
  --jq '.[] | select(.name == "code-review") | .sha'
```

Before committing, `git write-tree --prefix=vendor/claude-plugins/code-review/`
gives the same hash for the staged copy.

`claude plugin validate .` checks the marketplace and the plugin manifest.

## Changes to these files

The action only runs a workflow file identical to the copy on `main` (see
`lifecycle.md`, Review). A pull request that changes `claude-code-review.yml`
is therefore not reviewed by that workflow; review it with
`/code-review <pr>`. One that changes `claude.yml` still gets replies to
mentions in plain pull request comments, because GitHub runs `issue_comment`
workflows from `main`, but not to mentions in reviews or review comments,
which run the pull request's copy and are skipped. A pull request that
changes the vendored plugin is reviewed by the old copy. In every case,
check the first run after the merge.
