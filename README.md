# playwright-stealth-mcp

Microsoft's [`playwright-mcp`](https://github.com/microsoft/playwright-mcp)
rebuilt with [`patchright`](https://github.com/Kaliiiiiiiiii-Vinyzu/patchright-nodejs)
as the underlying Playwright implementation. Same MCP surface; the runtime
stops volunteering the automation tells (`navigator.webdriver`, CDP runtime
artifacts, etc.) that anti-bot systems key off of.

## What it does and doesn't do

Handles: Cloudflare IUAM ("Just a moment..."), passive Turnstile, Datadome,
PerimeterX — anything that's actually a JS fingerprint challenge dressed up
as a captcha.

Does **not** handle: hCaptcha, reCAPTCHA, interactive Turnstile, or anything
that requires submitting a real answer token. Those need a solver service
(CapSolver, 2Captcha, NopeCHA) regardless of browser runtime.

## How the build works

`playwright-mcp` imports from `playwright` and `playwright-core/lib/*`.
The Dockerfile clones the upstream source at the pinned tag and uses
npm package aliases to redirect those imports to patchright:

```jsonc
"dependencies": {
  "playwright":      "npm:patchright@^1.60.0",
  "playwright-core": "npm:patchright-core@^1.60.0"
}
```

No source-level edits to playwright-mcp. The patched `node_modules` is
then layered onto Microsoft's official runtime image, reusing their
chromium binary, system deps, user setup, and entrypoint.

## Versioning

Tags track upstream `playwright-mcp` releases verbatim. `v0.0.75` here = a
patchright-backed build of upstream's `v0.0.75`.

Microsoft pins Playwright to alpha builds (e.g. `1.61.0-alpha`); patchright
ships against the preceding stable (`1.60.0`). The minor-version skew has
worked in practice. If patchright lags far behind a chosen upstream tag,
pin to an earlier `playwright-mcp` release where the alpha matches a
stable patchright.

## Bumping the upstream version

1. Edit the `FROM` line in `Dockerfile` (and the `PLAYWRIGHT_MCP_VERSION`
   default) to the new upstream tag.
2. Commit, push to `main`.
3. `git tag vX.Y.Z && git push --tags` — GHA builds linux/amd64 + linux/arm64
   and pushes `ghcr.io/kelchm/playwright-stealth-mcp:vX.Y.Z` and `:latest`.

Renovate is configured to PR step 1 automatically.
