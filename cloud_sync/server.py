#!/usr/bin/env python3
"""Empires of Olympus — cloud account + save sync API.

Endpoints:
  GET  /health
  POST /v1/register   {username, password, display_name?}
  POST /v1/login      {username, password}
  PUT  /v1/save       Authorization: Bearer <token>  {save: {...}}
  GET  /v1/save       Authorization: Bearer <token>

Run:  uvicorn server:app --host 0.0.0.0 --port 8787
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import secrets
import sqlite3
import time
from pathlib import Path
from typing import Any, Optional

import jwt
from fastapi import Depends, FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

DATA_DIR = Path(os.environ.get("EOO_DATA", Path(__file__).resolve().parent / "data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB_PATH = DATA_DIR / "eoo.sqlite3"
JWT_SECRET = os.environ.get("EOO_JWT_SECRET", "dev-only-change-me")
JWT_HOURS = int(os.environ.get("EOO_JWT_HOURS", "720"))  # 30 days
USER_RE = re.compile(r"^[a-z0-9_]{3,24}$")

app = FastAPI(title="Empires of Olympus Sync", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                salt TEXT NOT NULL,
                pw_hash TEXT NOT NULL,
                display_name TEXT NOT NULL,
                created_at REAL NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS saves (
                username TEXT PRIMARY KEY,
                payload TEXT NOT NULL,
                saved_at REAL NOT NULL,
                FOREIGN KEY(username) REFERENCES users(username)
            )
            """
        )


def hash_pw(password: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{password}".encode("utf-8")).hexdigest()


def make_token(username: str) -> str:
    now = int(time.time())
    return jwt.encode(
        {"sub": username, "iat": now, "exp": now + JWT_HOURS * 3600},
        JWT_SECRET,
        algorithm="HS256",
    )


def user_from_auth(authorization: Optional[str] = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError as exc:
        raise HTTPException(401, "Invalid or expired token") from exc
    user = str(payload.get("sub", ""))
    if not user:
        raise HTTPException(401, "Invalid token")
    return user


class RegisterIn(BaseModel):
    username: str
    password: str
    display_name: str = ""


class LoginIn(BaseModel):
    username: str
    password: str


class SaveIn(BaseModel):
    save: dict[str, Any] = Field(default_factory=dict)


@app.on_event("startup")
def _startup() -> None:
    init_db()


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": True, "service": "eoo-sync", "ts": time.time()}


@app.post("/v1/register")
def register(body: RegisterIn) -> dict[str, Any]:
    user = body.username.strip().lower()
    password = body.password.strip()
    hero = (body.display_name or user).strip() or user
    if not USER_RE.match(user):
        raise HTTPException(400, "Username: 3–24 chars, letters/numbers/underscore")
    if len(password) < 6:
        raise HTTPException(400, "Password must be at least 6 characters")
    salt = secrets.token_hex(16)
    pw_hash = hash_pw(password, salt)
    try:
        with db() as conn:
            conn.execute(
                "INSERT INTO users(username, salt, pw_hash, display_name, created_at) VALUES (?,?,?,?,?)",
                (user, salt, pw_hash, hero, time.time()),
            )
    except sqlite3.IntegrityError as exc:
        raise HTTPException(409, "Username already taken") from exc
    token = make_token(user)
    return {"username": user, "display_name": hero, "token": token}


@app.post("/v1/login")
def login(body: LoginIn) -> dict[str, Any]:
    user = body.username.strip().lower()
    password = body.password.strip()
    with db() as conn:
        row = conn.execute("SELECT * FROM users WHERE username=?", (user,)).fetchone()
    if row is None:
        raise HTTPException(404, "Unknown account")
    if hash_pw(password, row["salt"]) != row["pw_hash"]:
        raise HTTPException(401, "Wrong password")
    token = make_token(user)
    return {
        "username": user,
        "display_name": row["display_name"],
        "token": token,
    }


@app.put("/v1/save")
def put_save(body: SaveIn, username: str = Depends(user_from_auth)) -> dict[str, Any]:
    payload = body.save or {}
    payload["account"] = username
    payload["saved_at"] = time.time()
    blob = json.dumps(payload, separators=(",", ":"))
    with db() as conn:
        conn.execute(
            """
            INSERT INTO saves(username, payload, saved_at) VALUES (?,?,?)
            ON CONFLICT(username) DO UPDATE SET payload=excluded.payload, saved_at=excluded.saved_at
            """,
            (username, blob, payload["saved_at"]),
        )
    return {"ok": True, "saved_at": payload["saved_at"]}


@app.get("/v1/save")
def get_save(username: str = Depends(user_from_auth)) -> dict[str, Any]:
    with db() as conn:
        row = conn.execute(
            "SELECT payload, saved_at FROM saves WHERE username=?", (username,)
        ).fetchone()
    if row is None:
        raise HTTPException(404, "No save for this account")
    save = json.loads(row["payload"])
    return {"save": save, "saved_at": row["saved_at"]}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="0.0.0.0", port=int(os.environ.get("PORT", "8787")))
