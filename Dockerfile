# Microsoft's playwright-mcp image is mostly system setup (chromium binary,
# system deps, node user, entrypoint). The actual application is just
# /app/node_modules + /app/cli.js. We build playwright-mcp from source with
# patchright swapped in for playwright (via npm package aliases), then replace
# the node_modules layer in Microsoft's runtime image with the patched build.
#
# Why patchright (not rebrowser-patches/rebrowser-playwright): rebrowser is
# stuck at playwright 1.52 (April 2025). Patchright tracks current Playwright
# (v1.60 as of build), is actively maintained, and ships as a drop-in npm
# package — no source-level patching required.
ARG PLAYWRIGHT_MCP_VERSION=v0.0.75
ARG PATCHRIGHT_VERSION=^1.60.0

# ---------------------------------------------------------------------------
# Build: clone playwright-mcp source, alias playwright→patchright, npm install
# ---------------------------------------------------------------------------
FROM node:22-bookworm AS builder
ARG PLAYWRIGHT_MCP_VERSION
ARG PATCHRIGHT_VERSION

WORKDIR /build
RUN apt-get update \
  && apt-get install -y --no-install-recommends git jq \
  && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${PLAYWRIGHT_MCP_VERSION} \
    https://github.com/microsoft/playwright-mcp.git . \
  && rm -rf .git

# npm package aliases: every `require('playwright')` resolves to patchright,
# every `require('playwright-core/...')` resolves to patchright-core/.... No
# source edits to playwright-mcp needed — same internal layout (utilsBundle,
# coreBundle, etc.) since patchright is a fork, not a reimplementation.
RUN jq \
    --arg pv "npm:patchright@${PATCHRIGHT_VERSION}" \
    --arg cv "npm:patchright-core@${PATCHRIGHT_VERSION}" \
    '.dependencies.playwright = $pv | .dependencies."playwright-core" = $cv' \
    package.json > /tmp/p.json \
  && mv /tmp/p.json package.json \
  && rm package-lock.json
RUN npm install --omit=dev --no-audit --no-fund

# ---------------------------------------------------------------------------
# Runtime: Microsoft's image, with node_modules replaced
# ---------------------------------------------------------------------------
FROM mcr.microsoft.com/playwright/mcp:v0.0.75

USER root
RUN rm -rf /app/node_modules
COPY --from=builder --chown=node:node /build/node_modules /app/node_modules
USER node
