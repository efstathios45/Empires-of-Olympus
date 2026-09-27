# Accounts, saves, and cross-device continue

Yes — **continuing on another device needs a sync server**. This repo ships one.

## What you get

| Layer | What it does |
|-------|----------------|
| **Local account** | Username + password (SHA-256 salted) stored in `user://accounts.json` |
| **Local save** | Full run snapshot in `user://saves/<user>.json` (level, gold, bag, gear, quests, position…) |
| **Cloud sync** | `cloud_sync/` FastAPI + SQLite — register / login / upload / download the same JSON |

## In the game

1. Title screen → **Create Account** or **Sign In**
2. Play → Esc → **Save Legend** (also autosaves every ~45s when signed in)
3. On another PC: **Sign In** with the same username/password → **Sync From Cloud** → **Continue Legend**

Guest play still works; it does not cloud-save.

## Sync server

```bash
cd cloud_sync
pip install -r requirements.txt
export EOO_JWT_SECRET="$(openssl rand -hex 24)"
uvicorn server:app --host 0.0.0.0 --port 8787
```

Point a build at your host by writing one line to the game’s user data file `sync_url.txt`:

```
https://your-sync-host.example
```

The client default URL is set in `scripts/autoloads/account_system.gd` (`sync_url`).

Docker: see `cloud_sync/Dockerfile` and `cloud_sync/README.md`.

## Security note

Passwords are hashed; the sync API uses JWT bearer tokens. Use HTTPS in production and a strong `EOO_JWT_SECRET`. This is an indie save-sync service, not a full anti-cheat backend.
