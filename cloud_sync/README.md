# Empires of Olympus — Cloud Sync

Cross-device continue: accounts + encrypted-at-rest save blobs (SQLite).

## Run locally

```bash
cd cloud_sync
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export EOO_JWT_SECRET="$(openssl rand -hex 24)"
uvicorn server:app --host 0.0.0.0 --port 8787
```

Point the game at it by writing one line to `user://sync_url.txt`:

```
http://127.0.0.1:8787
```

Or set the default in `scripts/autoloads/account_system.gd` (`sync_url`).

## API

| Method | Path | Auth | Body |
|--------|------|------|------|
| POST | `/v1/register` | — | `{username, password, display_name?}` |
| POST | `/v1/login` | — | `{username, password}` → `{token}` |
| PUT | `/v1/save` | Bearer | `{save: {...GameState...}}` |
| GET | `/v1/save` | Bearer | → `{save}` |

## Deploy

Any Docker host works (Fly.io, Render, Railway, a VPS):

```bash
docker build -t eoo-sync .
docker run -d -p 8787:8787 -e EOO_JWT_SECRET=... -v eoo_data:/data eoo-sync
```
