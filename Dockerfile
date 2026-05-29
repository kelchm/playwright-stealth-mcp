# Layers rebrowser-patches onto Microsoft's official playwright-mcp image so the
# bundled playwright-core stops volunteering CDP/webdriver tells that anti-bot
# systems (Cloudflare IUAM, passive Turnstile, Datadome) key off of. See README
# for the threat model — this does NOT solve interactive captchas.
FROM mcr.microsoft.com/playwright/mcp:v0.0.75

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends patch \
  && rm -rf /var/lib/apt/lists/* \
  && cd /app \
  && npx -y rebrowser-patches@latest patch --packagePath node_modules/playwright-core
USER node
