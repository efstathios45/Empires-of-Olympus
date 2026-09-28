
extends SceneTree
func _init(): call_deferred("r")
func r():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel
	for n in m.find_children("*","Skeleton3D",true,false): skel=n; break
	var fix=skel.get_node_or_null("SkyGazeFix")
	var anim=m.find_child("AnimationPlayer",true,false)
	if anim==null: anim=AnimationPlayer.new(); m.add_child(anim)
	var lib=load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
	if anim.has_animation_library(""): anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.play("ual1_Idle")
	for i in 20: await process_frame
	if fix: fix.set_process(false)
	for i in 5: await process_frame
	_d("RAW", skel)
	if fix: fix.set_process(true)
	for i in 8: await process_frame
	_d("HEADFIX", skel)
	# Also level UpperChest forward
	ModelUtils.correct_sky_gaze(skel, 1.0)
	# manual chest level
	_level(skel, "UpperChest")
	_level(skel, "Chest")
	_level(skel, "Head")
	_d("FULLLEVEL", skel)
	quit(0)
func _level(skel, name):
	var i=skel.find_bone(name)
	if i<0: return
	var g=skel.global_transform*skel.get_bone_global_pose(i)
	var fwd=(-g.basis.z).normalized()
	var up=fwd.dot(Vector3.UP)
	if up<=0.01: return
	var err=asin(clampf(up,-1,1))
	var flat=Vector3(fwd.x,0,fwd.z).normalized()
	var right=Vector3.UP.cross(flat).normalized()
	var wc=Basis(Quaternion(right, err))
	var pi=skel.get_bone_parent(i)
	var pg=skel.global_transform
	if pi>=0: pg=skel.global_transform*skel.get_bone_global_pose(pi)
	var nb=wc*g.basis
	var local=pg.affine_inverse()*Transform3D(nb, g.origin)
	skel.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
func _d(tag, skel):
	for name in ["Hips","Chest","UpperChest","Head"]:
		var i=skel.find_bone(name)
		var g=skel.global_transform*skel.get_bone_global_pose(i)
		var fwd=(-g.basis.z).normalized()
		var upv=g.basis.y.normalized()
		print("%s %s fwd_up=%.3f bone_up_dot=%.3f o=%s" % [tag,name,fwd.dot(Vector3.UP),upv.dot(Vector3.UP),g.origin])
