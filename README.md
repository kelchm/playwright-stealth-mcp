# playwright-stealth-mcp

Microsoft's [`playwright-mcp`](https://github.com/microsoft/playwright-mcp) image
with [`rebrowser-patches`](https://github.com/rebrowser/rebrowser-patches)
applied to the bundled `playwright-core`. Same MCP surface, patched runtime
that doesn't volunteer the automation tells (`navigator.webdriver`, CDP runtime
artifacts, etc.) that anti-bot systems key off of.

## What it does and doesn't do

Handles: Cloudflare IUAM ("Just a moment..."), passive Turnstile, Datadome,
PerimeterX — anything that's actually a JS fingerprint challenge dressed up
as a captcha.

Does **not** handle: hCaptcha, reCAPTCHA, interactive Turnstile, or anything
that requires submitting a real answer token. Those need a solver service
(CapSolver, 2Captcha, NopeCHA) regardless of browser runtime.

## Versioning

Tags track upstream `playwright-mcp` releases verbatim. `v0.0.75` here = a
patched build of `mcr.microsoft.com/playwright/mcp:v0.0.75`.

## Bumping the upstream version

1. Edit the `FROM` line in `Dockerfile` to the new upstream tag.
2. Commit, push to `main`.
3. `git tag vX.Y.Z && git push --tags` — GHA builds and pushes
   `ghcr.io/kelchm/playwright-stealth-mcp:vX.Y.Z` and `:latest`.

Renovate is configured to PR step 1 automatically.
