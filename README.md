# alexmak.pro — RU mirror (Dokploy deploy)

Static deploy of [alexmak.pro](https://alexmak.pro) website on the Russian Dokploy server (am32) for RU-audience testing. Cloudflare deploy of alexmak.pro can be slow/blocked from Russia — this mirror gives a reliable RU-side preview.

- **URL:** https://alexmak.am32.oneln.ru
- **Source site repo:** `~/plan/website/` (Astro, see `astro.config.mjs`)
- **Production site (Cloudflare):** https://alexmak.pro

## How it works

1. Source site lives in `~/plan/website/` (Astro static site generator).
2. Build artifacts (`dist/`) are committed into this repo.
3. Dokploy on am32 watches this GitHub repo (`main` branch). On every push it:
   - Pulls the repo
   - Runs `docker compose build` (uses our `Dockerfile` → nginx + dist)
   - Restarts the container
   - Traefik routes `alexmak.am32.oneln.ru` → container :80

## Update workflow

```bash
# 1. Make changes in source repo
cd ~/plan/website
# ... edit content ...
npm run build

# 2. Sync dist to deploy repo and push
rsync -av --delete ~/plan/website/dist/ ~/alexmak-pro-static-deploy/dist/
cd ~/alexmak-pro-static-deploy
git add -A
git commit -m "Deploy: <what changed>"
git push

# Dokploy auto-deploys within ~30 sec
```

For full deploy guide (both Cloudflare + Dokploy), see `~/plan/website/DEPLOY.md`.

## Files

- `Dockerfile` — nginx:alpine + COPY dist/
- `nginx.conf` — clean URLs, gzip, cache headers, security headers
- `docker-compose.yml` — Dokploy compose definition (no manual Traefik labels — Dokploy generates them)
- `dist/` — Astro build artifacts (committed)
