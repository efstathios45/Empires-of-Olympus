extends SceneTree
## Runtime: remote combat FX must survive a follow-up apply_state (walk/idle).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var RemoteScr: Script = load("res://scripts/remote_avatar.gd") as Script
	if RemoteScr == null:
		print("FAIL load remote_avatar")
		quit(1)
		return
	var av: = CharacterBody3D.new()
	av.set_script(RemoteScr)
	root.add_child(av)
	av.call("setup", 2, "Peer", "sparta", 5, "hoplite")
	## Wait a few frames for model/anim.
	for _i in 8:
		await process_frame
	if av.anim == null:
		print("FAIL no anim on remote")
		quit(1)
		return
	av.call("play_combat_fx", "q", Vector3.ZERO, 0.5, "hoplite")
	var lock: float = float(av.get("_fx_lock"))
	if lock <= 0.0:
		print("FAIL fx lock not set after skill")
		quit(1)
		return
	## Simulate a state sync that used to wipe the cast.
	av.call("apply_state", Vector3(1, 0, 1), 0.5, 100.0, 100.0, 5, true)
	if float(av.get("_fx_lock")) <= 0.0:
		print("FAIL lock cleared unexpectedly")
		quit(1)
		return
	## Current clip should still be a combat clip, not Walk/Idle forced.
	var cur: String = String(av.anim.current_animation)
	var lower: = cur.to_lower()
	if lower.contains("walk") or lower == "idle" or lower.contains("idle_neutral"):
		## Only fail if lock is still active — walk would mean clobber.
		print("FAIL apply_state clobbered combat anim while locked: ", cur)
		quit(1)
		return
	av.call("play_combat_fx", "attack_1", Vector3.ZERO, 1.0, "hoplite")
	if float(av.get("_fx_lock")) <= 0.0:
		print("FAIL attack fx lock missing")
		quit(1)
		return
	print("SMOKE_REMOTE_COMBAT_RUNTIME_OK lock=", lock, " anim=", cur)
	quit(0)
