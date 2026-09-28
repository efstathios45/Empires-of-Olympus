# Player chat

Press **Enter** in-world to open the say field. **Enter** sends, **Esc** closes.

## Behaviour today

- Messages show in the bottom-left log for everyone on this client.
- Solo / offline: your lines echo locally (channel is ready; no other peers yet).
- With a Godot multiplayer peer connected: `ChatSystem` fans messages out with
  `@rpc("any_peer", "reliable", "call_local")` so peers see the same say.

## Multiplayer wiring (when you add netcode)

1. Establish `multiplayer.multiplayer_peer` (ENet / WebRTC / custom).
2. Keep using `ChatSystem.send_say()` from the HUD — no UI change needed.
3. Optionally move `_rpc_chat` onto a dedicated server that validates length /
   rate-limits, then relays to the lobby/instance.
4. Same display name source as saves (`AccountSystem` / `GameState.player_name`).

Payload stays `{sender, text, t}` in `ChatSystem.history` for UI replay.
