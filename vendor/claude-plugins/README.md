# Vendored Claude Code plugins

Plugins copied verbatim from upstream so that the AI review workflow
(`.github/workflows/claude-code-review.yml`) runs a version reviewed in this
repository. They are served by the marketplace in
`.claude-plugin/marketplace.json`. Do not edit them by hand: re-vendor them as
described in `docs/workflow-dependencies.md`.

`.gitattributes` marks `vendor/claude-plugins/code-review/**` as `-text`, so
Git stores the files exactly as upstream does and the tree hash below can be
checked on any platform.

## code-review

| | |
|---|---|
| Upstream repository | https://github.com/anthropics/claude-plugins-official |
| Upstream path | `plugins/code-review` |
| Upstream commit | `9780cf407f5593727b668bae95a0c4ae2e0de1ae` (2026-10-26, "code-review: add version 1.0.1") |
| Upstream tree | `0a12e55fc6b4966832674e01354591e051b7a78d` |
| Plugin version | 1.0.1 |
| Vendored | 2026-11-17 |
| Licence | Apache License 2.0, in `code-review/LICENSE` |

The workflow's `--allowedTools` list mirrors the `allowed-tools` frontmatter
of `code-review/commands/code-review.md`.
