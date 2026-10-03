extends Node

























const PORT: = 5180
const HTTP_PORT: = 5181
const SNAPSHOT_INTERVAL: = 0.25
const PROTOCOL_VERSION: = 1



const MUTE_AUDIO: = false





const WS_OUTBOUND_BUFFER_BYTES: = 32 * 1024 * 1024
const WS_INBOUND_BUFFER_BYTES: = 1 * 1024 * 1024

var _server: TCPServer
var _peers: Array[WebSocketPeer] = []
var _last_snapshot_hash: String = ""
var _time_since_snapshot: float = 0.0



var _http_server: TCPServer
var _http_clients: Array[Dictionary] = []


func _ready() -> void :










	process_mode = Node.PROCESS_MODE_ALWAYS




	var is_template: bool = OS.has_feature("template")
	var tesana_embedded: String = OS.get_environment("TESANA_EMBEDDED")
	print("[TesanaWorldEditor] _ready() template=%s TESANA_EMBEDDED=%s" % [is_template, tesana_embedded])
















	if is_template and tesana_embedded != "1":
		print("[TesanaWorldEditor] not in Tesana host (template build, no TESANA_EMBEDDED) — bailing")
		set_process(false)
		return





	if OS.get_environment("TESANA_QA_TEST") == "1":
		print("[TesanaWorldEditor] QA test run — bailing")
		set_process(false)
		return

	if MUTE_AUDIO:
		AudioServer.set_bus_mute(0, true)
		print("[TesanaWorldEditor] Audio muted (MUTE_AUDIO=true)")

	_server = TCPServer.new()
	var err: int = _server.listen(PORT, "127.0.0.1")
	if err != OK:
		push_warning("[TesanaWorldEditor] Failed to listen on 127.0.0.1:%d (err=%d)" % [PORT, err])
		set_process(false)
		return
	print("[TesanaWorldEditor] WS listening on 127.0.0.1:%d" % PORT)

	_http_server = TCPServer.new()
	var http_err: int = _http_server.listen(HTTP_PORT, "127.0.0.1")
	if http_err != OK:
		push_warning(
			("[TesanaWorldEditor] Failed to listen on HTTP 127.0.0.1:%d (err=%d). "\
			+ "Texture/GLB asset serving disabled.") % [HTTP_PORT, http_err]
		)
		_http_server = null
	else:
		print("[TesanaWorldEditor] HTTP serving res:// on 127.0.0.1:%d" % HTTP_PORT)


func _process(delta: float) -> void :
	_accept_new_connections()
	_poll_existing_peers()
	_accept_http_connections()
	_poll_http_clients()
	_time_since_snapshot += delta
	if _time_since_snapshot >= SNAPSHOT_INTERVAL:
		_time_since_snapshot = 0.0
		_maybe_broadcast_snapshot()


func _accept_new_connections() -> void :
	while _server.is_connection_available():
		var tcp: StreamPeerTCP = _server.take_connection()
		if tcp == null:
			break
		var ws: = WebSocketPeer.new()
		ws.outbound_buffer_size = WS_OUTBOUND_BUFFER_BYTES
		ws.inbound_buffer_size = WS_INBOUND_BUFFER_BYTES
		var err: int = ws.accept_stream(tcp)
		if err != OK:
			push_warning("[TesanaWorldEditor] accept_stream failed (err=%d)" % err)
			continue
		_peers.append(ws)
		print("[TesanaWorldEditor] Peer accepted (now %d connected)" % _peers.size())


func _poll_existing_peers() -> void :
	var still_connected: Array[WebSocketPeer] = []
	for peer in _peers:
		peer.poll()
		var state: int = peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			still_connected.append(peer)
			while peer.get_available_packet_count() > 0:
				var msg: String = peer.get_packet().get_string_from_utf8()
				_handle_inbound(peer, msg)
		elif state == WebSocketPeer.STATE_CONNECTING:

			still_connected.append(peer)
		else:

			print("[TesanaWorldEditor] Peer disconnected (state=%d)" % state)
	_peers = still_connected


func _maybe_broadcast_snapshot() -> void :
	if _peers.is_empty():
		return
	var snapshot: Dictionary = _build_snapshot()
	var snapshot_str: String = JSON.stringify(snapshot)
	var h: String = snapshot_str.sha256_text()
	if h == _last_snapshot_hash:
		return
	_last_snapshot_hash = h
	var size_bytes: int = snapshot_str.length()
	for peer in _peers:
		if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
			continue





		var pending: int = peer.get_current_outbound_buffered_amount()
		if pending > size_bytes / 2:

			_last_snapshot_hash = ""
			continue
		var send_err: int = peer.send_text(snapshot_str)
		if send_err != OK:
			push_warning(
				("[TesanaWorldEditor] send_text failed (err=%d, snapshot=%d bytes, pending=%d). "\
				+ "If ERR_OUT_OF_MEMORY, bump WS_OUTBOUND_BUFFER_BYTES or lower SNAPSHOT_INTERVAL.")\
				%[send_err, size_bytes, pending]
			)

			_last_snapshot_hash = ""


func _build_snapshot() -> Dictionary:
	var current_scene: Node = get_tree().current_scene
	var root_kind: String = "unknown"
	var tree_data: Variant = null
	if current_scene != null:
		if current_scene is Node3D:
			root_kind = "3d"
		elif current_scene is Node2D or current_scene is Control or current_scene is CanvasItem:
			root_kind = "2d"
		tree_data = _serialize_node(current_scene)
		_infer_glb_anchors(tree_data)
	return {
		"type": "snapshot", 
		"version": PROTOCOL_VERSION, 
		"scene_root_kind": root_kind, 
		"tree": tree_data, 
	}










func _infer_glb_anchors(node) -> void :
	if node == null or not (node is Dictionary):
		return
	var children: Array = node.get("children", [])
	for child in children:
		_infer_glb_anchors(child)


	if _subtree_has_glb_marker(node):
		return
	var name_str: String = node.get("name", "")
	var type_str: String = node.get("type", "")

	if name_str.begins_with("@") or name_str.begins_with("_") or name_str == "":
		return
	if not _is_node3d_kind(type_str):
		return
	var glb_path: String = _find_glb_path_in_subtree(node)
	if glb_path != "":
		node["inferred_scene_file_path"] = glb_path


func _subtree_has_glb_marker(node) -> bool:
	if node == null or not (node is Dictionary):
		return false
	if node.has("scene_file_path") and String(node["scene_file_path"]).ends_with(".glb"):
		return true
	if node.has("inferred_scene_file_path"):
		return true
	for child in node.get("children", []):
		if _subtree_has_glb_marker(child):
			return true
	return false


func _find_glb_path_in_subtree(node) -> String:
	if node == null or not (node is Dictionary):
		return ""
	var mp: String = String(node.get("mesh_path", ""))
	if mp != "":
		var sep: int = mp.find("::")
		var base: String = mp.substr(0, sep) if sep >= 0 else mp
		if base.to_lower().ends_with(".glb") or base.to_lower().ends_with(".gltf"):
			return base
	for child in node.get("children", []):
		var r: String = _find_glb_path_in_subtree(child)
		if r != "":
			return r
	return ""


func _is_node3d_kind(type_str: String) -> bool:





	if type_str == "Skeleton3D" or type_str == "BoneAttachment3D":
		return false
	if type_str == "MeshInstance3D" or type_str == "MultiMeshInstance3D":
		return false


	if type_str.begins_with("CollisionShape") or type_str.begins_with("CollisionPolygon"):
		return false
	if type_str.ends_with("3D"):
		return true
	if type_str == "Node3D":
		return true
	return false


func _serialize_node(node: Node) -> Dictionary:
	var data: Dictionary = {
		"id": node.get_instance_id(), 
		"name": String(node.name), 
		"type": node.get_class(), 
		"path": String(node.get_path()), 
	}


	if node is Node2D:
		var n2d: Node2D = node as Node2D
		data["transform2d"] = {
			"position": [n2d.position.x, n2d.position.y], 
			"rotation_rad": n2d.rotation, 
			"scale": [n2d.scale.x, n2d.scale.y], 
		}



		if n2d.z_index != 0:
			data["z_index"] = n2d.z_index
	elif node is Node3D:
		var n3d: Node3D = node as Node3D
		data["transform3d"] = {
			"position": [n3d.position.x, n3d.position.y, n3d.position.z], 
			"rotation_euler_rad": [n3d.rotation.x, n3d.rotation.y, n3d.rotation.z], 
			"scale": [n3d.scale.x, n3d.scale.y, n3d.scale.z], 
		}


	if node is Sprite2D:
		var s2d: Sprite2D = node as Sprite2D
		data["texture"] = _texture_info(s2d.texture)
		data["centered"] = s2d.centered
		data["flip_h"] = s2d.flip_h
		data["flip_v"] = s2d.flip_v
	elif node is AnimatedSprite2D:
		var asp: AnimatedSprite2D = node as AnimatedSprite2D
		data["animation"] = String(asp.animation)
		data["frame"] = asp.frame
		data["centered"] = asp.centered
		data["flip_h"] = asp.flip_h
		data["flip_v"] = asp.flip_v
		if asp.sprite_frames and asp.sprite_frames.has_animation(asp.animation):
			var tex: Texture2D = asp.sprite_frames.get_frame_texture(asp.animation, asp.frame)
			data["frame_texture"] = _texture_info(tex)




	if node is TileMapLayer:
		var tml: TileMapLayer = node as TileMapLayer
		var ts: TileSet = tml.tile_set
		if ts != null:
			data["tile_size"] = [ts.tile_size.x, ts.tile_size.y]
			var sources_d: Dictionary = {}
			for i in range(ts.get_source_count()):
				var sid: int = ts.get_source_id(i)
				var src: TileSetSource = ts.get_source(sid)
				if src is TileSetAtlasSource:
					var asrc: TileSetAtlasSource = src as TileSetAtlasSource
					if asrc.texture != null:
						sources_d[str(sid)] = {
							"texture_path": asrc.texture.resource_path, 
							"region_size": [asrc.texture_region_size.x, asrc.texture_region_size.y], 
						}
			data["tile_sources"] = sources_d
			var cells: Array = []
			for cell in tml.get_used_cells():
				var c: Vector2i = cell
				var sid_c: int = tml.get_cell_source_id(c)
				var ac: Vector2i = tml.get_cell_atlas_coords(c)
				cells.append([c.x, c.y, sid_c, ac.x, ac.y])
			data["tile_cells"] = cells


	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh:
			data["mesh_path"] = mesh.resource_path
			data["mesh_kind"] = mesh.get_class()
			var size: Variant = _mesh_size(mesh)
			if size != null:
				data["mesh_size"] = [size.x, size.y, size.z]

			var mat_data: Variant = null
			if mi.material_override != null:
				mat_data = _serialize_material(mi.material_override)
			elif mi.get_surface_override_material(0) != null:
				mat_data = _serialize_material(mi.get_surface_override_material(0))
			elif mesh.get_surface_count() > 0 and mesh.surface_get_material(0) != null:
				mat_data = _serialize_material(mesh.surface_get_material(0))
			if mat_data != null:
				data["material"] = mat_data


	if node is OmniLight3D:
		var ol: OmniLight3D = node as OmniLight3D
		data["light_color"] = _color_to_array(ol.light_color)
		data["light_energy"] = ol.light_energy
		data["omni_range"] = ol.omni_range
	elif node is SpotLight3D:
		var sl: SpotLight3D = node as SpotLight3D
		data["light_color"] = _color_to_array(sl.light_color)
		data["light_energy"] = sl.light_energy
		data["spot_range"] = sl.spot_range
		data["spot_angle_deg"] = sl.spot_angle
	elif node is DirectionalLight3D:
		var dl: DirectionalLight3D = node as DirectionalLight3D
		data["light_color"] = _color_to_array(dl.light_color)
		data["light_energy"] = dl.light_energy


	if node is Camera3D:
		var cam3d: Camera3D = node as Camera3D
		data["fov_deg"] = cam3d.fov


	if node is WorldEnvironment:
		var we: WorldEnvironment = node as WorldEnvironment
		if we.environment != null:
			data["environment"] = _serialize_environment(we.environment)


	if node is CollisionShape3D:
		var cs3d: CollisionShape3D = node as CollisionShape3D
		if cs3d.shape != null:
			var shape: Shape3D = cs3d.shape
			data["shape_kind"] = shape.get_class()
			var shape_size: Variant = _shape_size_3d(shape)
			if shape_size != null:
				data["shape_size"] = [shape_size.x, shape_size.y, shape_size.z]
	elif node is CollisionShape2D:
		var cs2d: CollisionShape2D = node as CollisionShape2D
		if cs2d.shape != null:
			var shape2: Shape2D = cs2d.shape
			data["shape_kind"] = shape2.get_class()
			var shape_size2: Variant = _shape_size_2d(shape2)
			if shape_size2 != null:
				data["shape_size"] = [shape_size2.x, shape_size2.y]


	if node.scene_file_path != "":
		data["scene_file_path"] = node.scene_file_path


	var scr_v: Variant = node.get_script()
	if scr_v != null and scr_v is Script:
		var scr: Script = scr_v as Script
		data["script_path"] = scr.resource_path
		var exports_dict: Dictionary = _serialize_exports(node, scr)
		if not exports_dict.is_empty():
			data["exports"] = exports_dict


	var children: Array = []
	for child in node.get_children():
		children.append(_serialize_node(child))
	data["children"] = children

	return data


func _texture_path(tex: Texture2D) -> String:
	if tex == null:
		return ""
	var p: String = tex.resource_path
	if p == "" and tex is AtlasTexture:
		var atlas_tex: AtlasTexture = tex as AtlasTexture
		if atlas_tex.atlas != null:
			p = atlas_tex.atlas.resource_path
	return p






func _texture_info(tex: Texture2D) -> Dictionary:
	var info: Dictionary = {}
	if tex == null:
		return info
	var path: String = tex.resource_path
	var w: int = 0
	var h: int = 0
	if tex is AtlasTexture:
		var at: AtlasTexture = tex as AtlasTexture
		if at.atlas != null:
			path = at.atlas.resource_path
		var r: Rect2 = at.region
		info["region"] = [r.position.x, r.position.y, r.size.x, r.size.y]
		w = int(r.size.x)
		h = int(r.size.y)
	else:
		w = tex.get_width()
		h = tex.get_height()
	info["path"] = path
	info["width"] = w
	info["height"] = h
	return info


func _color_to_array(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]


func _mesh_size(mesh: Mesh) -> Variant:
	if mesh is BoxMesh:
		return (mesh as BoxMesh).size
	elif mesh is PlaneMesh:
		var pm: PlaneMesh = mesh as PlaneMesh
		return Vector3(pm.size.x, 0.01, pm.size.y)
	elif mesh is SphereMesh:
		var sm: SphereMesh = mesh as SphereMesh
		var d: float = sm.radius * 2.0
		return Vector3(d, sm.height, d)
	elif mesh is CapsuleMesh:
		var cm: CapsuleMesh = mesh as CapsuleMesh
		var d2: float = cm.radius * 2.0
		return Vector3(d2, cm.height, d2)
	elif mesh is CylinderMesh:
		var cym: CylinderMesh = mesh as CylinderMesh
		var d3: float = max(cym.top_radius, cym.bottom_radius) * 2.0
		return Vector3(d3, cym.height, d3)
	elif mesh is QuadMesh:
		var qm: QuadMesh = mesh as QuadMesh
		return Vector3(qm.size.x, qm.size.y, 0.01)
	elif mesh is PrismMesh:
		return (mesh as PrismMesh).size
	return null


func _shape_size_3d(shape: Shape3D) -> Variant:
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size
	elif shape is SphereShape3D:
		var d: float = (shape as SphereShape3D).radius * 2.0
		return Vector3(d, d, d)
	elif shape is CapsuleShape3D:
		var cs: CapsuleShape3D = shape as CapsuleShape3D
		var d2: float = cs.radius * 2.0
		return Vector3(d2, cs.height, d2)
	elif shape is CylinderShape3D:
		var cys: CylinderShape3D = shape as CylinderShape3D
		var d3: float = cys.radius * 2.0
		return Vector3(d3, cys.height, d3)
	return null


func _shape_size_2d(shape: Shape2D) -> Variant:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size
	elif shape is CircleShape2D:
		var d: float = (shape as CircleShape2D).radius * 2.0
		return Vector2(d, d)
	elif shape is CapsuleShape2D:
		var cs: CapsuleShape2D = shape as CapsuleShape2D
		var d2: float = cs.radius * 2.0
		return Vector2(d2, cs.height)
	return null


func _serialize_exports(node: Node, scr: Script) -> Dictionary:
	var out: Dictionary = {}
	if scr == null:
		return out
	var props: Array = scr.get_script_property_list()
	for prop_v in props:
		if not (prop_v is Dictionary):
			continue
		var prop: Dictionary = prop_v as Dictionary
		var name_str: String = prop.get("name", "")
		var usage: int = prop.get("usage", 0)


		if (usage & 4) == 0 or (usage & 4096) == 0:
			continue
		if name_str == "" or name_str.begins_with("_"):
			continue
		var val: Variant = node.get(name_str)
		var serialized: Variant = _to_json_safe(val)
		if serialized != null:
			out[name_str] = serialized
	return out


func _serialize_material(mat: Material) -> Variant:
	if mat == null:
		return null
	var out: Dictionary = {
		"kind": mat.get_class(), 
	}
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat as StandardMaterial3D
		out["albedo_color"] = _color_to_array(sm.albedo_color)
		if sm.albedo_texture != null:
			out["albedo_texture_path"] = _texture_path(sm.albedo_texture)
		if sm.normal_texture != null:
			out["normal_texture_path"] = _texture_path(sm.normal_texture)
		out["roughness"] = sm.roughness
		out["metallic"] = sm.metallic
		out["uv1_scale"] = [sm.uv1_scale.x, sm.uv1_scale.y, sm.uv1_scale.z]

		if sm.emission_enabled:
			out["emission_color"] = _color_to_array(sm.emission)
			out["emission_energy"] = sm.emission_energy_multiplier

		if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			out["transparent"] = true
	elif mat is ORMMaterial3D:
		var om: ORMMaterial3D = mat as ORMMaterial3D
		out["albedo_color"] = _color_to_array(om.albedo_color)
		if om.albedo_texture != null:
			out["albedo_texture_path"] = _texture_path(om.albedo_texture)

	return out


func _serialize_environment(env: Environment) -> Dictionary:
	var out: Dictionary = {}

	out["background_mode"] = env.background_mode
	out["background_color"] = _color_to_array(env.background_color)
	out["background_energy"] = env.background_energy_multiplier
	out["ambient_light_color"] = _color_to_array(env.ambient_light_color)
	out["ambient_light_energy"] = env.ambient_light_energy
	if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		var psm: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
		out["sky_top_color"] = _color_to_array(psm.sky_top_color)
		out["sky_horizon_color"] = _color_to_array(psm.sky_horizon_color)
		out["ground_bottom_color"] = _color_to_array(psm.ground_bottom_color)
		out["ground_horizon_color"] = _color_to_array(psm.ground_horizon_color)
	out["fog_enabled"] = env.fog_enabled
	if env.fog_enabled:
		out["fog_light_color"] = _color_to_array(env.fog_light_color)
		out["fog_density"] = env.fog_density
	return out


func _to_json_safe(val: Variant) -> Variant:
	if val == null:
		return null
	var t: int = typeof(val)
	if t == TYPE_BOOL or t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING:
		return val
	if val is Vector2:
		return [val.x, val.y]
	if val is Vector3:
		return [val.x, val.y, val.z]
	if val is Color:
		return _color_to_array(val)
	if val is StringName:
		return String(val)

	return null


func _handle_inbound(_peer: WebSocketPeer, msg: String) -> void :
	var parsed: Variant = JSON.parse_string(msg)
	if parsed == null or not (parsed is Dictionary):
		push_warning("[TesanaWorldEditor] Unparseable inbound message: %s" % msg)
		return
	var parsed_dict: Dictionary = parsed as Dictionary
	_dispatch_op(parsed_dict)


func _dispatch_op(op: Dictionary) -> void :
	var op_type: String = op.get("type", "")
	match op_type:
		"set_position":
			_apply_set_position(op)
		"set_rotation":
			_apply_set_rotation(op)
		"set_scale":
			_apply_set_scale(op)
		"set_property":
			_apply_set_property(op)
		"delete_node":
			_apply_delete_node(op)
		"clone_node":
			_apply_clone_node(op)
		"batch":


			var ops: Array = op.get("ops", [])
			for inner_v in ops:
				if inner_v is Dictionary:
					_dispatch_op(inner_v as Dictionary)
		_:
			push_warning("[TesanaWorldEditor] Unknown inbound message type: %s" % op_type)


func _apply_set_position(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	var pos: Variant = op.get("position", null)
	if node_id == 0 or pos == null:
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj):
		return
	if obj is Node3D and pos is Array and (pos as Array).size() >= 3:
		var p3: Array = pos as Array
		(obj as Node3D).position = Vector3(float(p3[0]), float(p3[1]), float(p3[2]))
	elif obj is Node2D and pos is Array and (pos as Array).size() >= 2:
		var p2: Array = pos as Array
		(obj as Node2D).position = Vector2(float(p2[0]), float(p2[1]))


func _apply_set_rotation(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	var rot: Variant = op.get("rotation", null)
	if node_id == 0 or rot == null:
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj):
		return
	if obj is Node3D and rot is Array and (rot as Array).size() >= 3:
		var r3: Array = rot as Array
		(obj as Node3D).rotation = Vector3(float(r3[0]), float(r3[1]), float(r3[2]))
	elif obj is Node2D:
		var r: float = float(rot) if not (rot is Array) else float((rot as Array)[0])
		(obj as Node2D).rotation = r


func _apply_set_scale(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	var sc: Variant = op.get("scale", null)
	if node_id == 0 or sc == null:
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj):
		return
	if obj is Node3D and sc is Array and (sc as Array).size() >= 3:
		var s3: Array = sc as Array
		(obj as Node3D).scale = Vector3(float(s3[0]), float(s3[1]), float(s3[2]))
	elif obj is Node2D and sc is Array and (sc as Array).size() >= 2:
		var s2: Array = sc as Array
		(obj as Node2D).scale = Vector2(float(s2[0]), float(s2[1]))






func _apply_set_property(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	var prop_name: String = op.get("property", "")
	if node_id == 0 or prop_name == "":
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj):
		return
	var raw_value: Variant = op.get("value", null)


	var current: Variant = obj.get(prop_name)
	var target_value: Variant = _coerce_value(raw_value, current)
	obj.set(prop_name, target_value)


func _coerce_value(raw: Variant, current: Variant) -> Variant:
	if raw == null:
		return null

	if current is Color and raw is Array and (raw as Array).size() >= 3:
		var arr: Array = raw as Array
		var a: float = float(arr[3]) if arr.size() >= 4 else 1.0
		return Color(float(arr[0]), float(arr[1]), float(arr[2]), a)
	if current is Vector3 and raw is Array and (raw as Array).size() >= 3:
		var v3: Array = raw as Array
		return Vector3(float(v3[0]), float(v3[1]), float(v3[2]))
	if current is Vector2 and raw is Array and (raw as Array).size() >= 2:
		var v2: Array = raw as Array
		return Vector2(float(v2[0]), float(v2[1]))

	if current is int and raw is float:
		return int(raw)
	return raw




func _apply_delete_node(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	if node_id == 0:
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj) or not obj is Node:
		return
	(obj as Node).queue_free()






func _apply_clone_node(op: Dictionary) -> void :
	var node_id: int = int(op.get("node_id", 0))
	if node_id == 0:
		return
	var obj: Object = instance_from_id(node_id)
	if obj == null or not is_instance_valid(obj) or not obj is Node:
		return
	var node: Node = obj as Node
	var parent: Node = node.get_parent()
	if parent == null:
		return
	var flags: int = (
		Node.DUPLICATE_GROUPS
		| Node.DUPLICATE_SIGNALS
		| Node.DUPLICATE_SCRIPTS
		| Node.DUPLICATE_USE_INSTANTIATION
	)
	var dup: Node = node.duplicate(flags)
	parent.add_child(dup)
	dup.owner = parent.owner if parent.owner != null else parent


	var offset: Variant = op.get("position_delta", null)
	if dup is Node3D:
		var nd3: Node3D = dup as Node3D
		if offset is Array and (offset as Array).size() >= 3:
			var od: Array = offset as Array
			nd3.position += Vector3(float(od[0]), float(od[1]), float(od[2]))
		else:
			nd3.position += Vector3(0.5, 0, 0)
	elif dup is Node2D:
		var nd2: Node2D = dup as Node2D
		if offset is Array and (offset as Array).size() >= 2:
			var od2: Array = offset as Array
			nd2.position += Vector2(float(od2[0]), float(od2[1]))
		else:
			nd2.position += Vector2(20, 0)
















func _accept_http_connections() -> void :
	if _http_server == null:
		return
	while _http_server.is_connection_available():
		var tcp: StreamPeerTCP = _http_server.take_connection()
		if tcp == null:
			break
		_http_clients.append({"peer": tcp, "buf": PackedByteArray()})


func _poll_http_clients() -> void :
	var still: Array[Dictionary] = []
	for client in _http_clients:
		var tcp: StreamPeerTCP = client["peer"]
		tcp.poll()
		var status: int = tcp.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			continue
		var avail: int = tcp.get_available_bytes()
		if avail > 0:
			var got: Array = tcp.get_data(avail)
			if got[0] == OK:
				var bytes: PackedByteArray = got[1]
				var existing: PackedByteArray = client["buf"]
				existing.append_array(bytes)
				client["buf"] = existing
		var buf: PackedByteArray = client["buf"]
		var s: String = buf.get_string_from_utf8()
		var head_end: int = s.find("\r\n\r\n")
		if head_end == -1:

			if buf.size() < 8192:
				still.append(client)
			continue

		_handle_http_request(tcp, s)
	_http_clients = still


func _handle_http_request(tcp: StreamPeerTCP, request: String) -> void :
	var first_line_end: int = request.find("\r\n")
	if first_line_end == -1:
		_send_http(tcp, 400, "Bad Request", PackedByteArray())
		return
	var first_line: String = request.substr(0, first_line_end)
	var parts: PackedStringArray = first_line.split(" ")
	if parts.size() < 2:
		_send_http(tcp, 400, "Bad Request", PackedByteArray())
		return
	var method: String = parts[0]
	var url_path: String = parts[1]

	var qmark: int = url_path.find("?")
	if qmark != -1:
		url_path = url_path.substr(0, qmark)
	url_path = url_path.uri_decode()

	if method == "OPTIONS":
		_send_http(tcp, 200, "OK", PackedByteArray())
		return
	if method != "GET" and method != "HEAD":
		_send_http(tcp, 405, "Method Not Allowed", PackedByteArray())
		return
	if url_path.find("..") != -1 or url_path == "/" or url_path == "":
		_send_http(tcp, 403, "Forbidden", PackedByteArray())
		return


	var res_path: String = "res:/" + url_path
	if not FileAccess.file_exists(res_path):
		_send_http(tcp, 404, "Not Found", PackedByteArray())
		return
	var f: FileAccess = FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		_send_http(tcp, 500, "Internal Error", PackedByteArray())
		return
	var data: PackedByteArray = f.get_buffer(f.get_length())
	f.close()

	if method == "HEAD":
		_send_http(tcp, 200, "OK", PackedByteArray(), _content_type_for(url_path), data.size())
	else:
		_send_http(tcp, 200, "OK", data, _content_type_for(url_path))


func _send_http(
	tcp: StreamPeerTCP, 
	code: int, 
	status: String, 
	body: PackedByteArray, 
	content_type: String = "application/octet-stream", 
	content_length_override: int = -1, 
) -> void :
	var content_length: int = content_length_override if content_length_override >= 0 else body.size()
	var headers: String = "HTTP/1.1 %d %s\r\n" % [code, status]
	headers += "Content-Type: %s\r\n" % content_type
	headers += "Content-Length: %d\r\n" % content_length
	headers += "Access-Control-Allow-Origin: *\r\n"
	headers += "Access-Control-Allow-Methods: GET, HEAD, OPTIONS\r\n"
	headers += "Access-Control-Allow-Headers: *\r\n"
	headers += "Cache-Control: max-age=3600\r\n"
	headers += "Connection: close\r\n"
	headers += "\r\n"
	var head_bytes: PackedByteArray = headers.to_utf8_buffer()
	tcp.put_data(head_bytes)
	if body.size() > 0:
		tcp.put_data(body)
	tcp.disconnect_from_host()


func _content_type_for(path: String) -> String:
	var lower: String = path.to_lower()
	if lower.ends_with(".png"): return "image/png"
	if lower.ends_with(".jpg") or lower.ends_with(".jpeg"): return "image/jpeg"
	if lower.ends_with(".webp"): return "image/webp"
	if lower.ends_with(".gif"): return "image/gif"
	if lower.ends_with(".svg"): return "image/svg+xml"
	if lower.ends_with(".glb"): return "model/gltf-binary"
	if lower.ends_with(".gltf"): return "model/gltf+json"
	if lower.ends_with(".bin"): return "application/octet-stream"
	if lower.ends_with(".json"): return "application/json"
	if lower.ends_with(".ogg"): return "audio/ogg"
	if lower.ends_with(".wav"): return "audio/wav"
	if lower.ends_with(".mp3"): return "audio/mpeg"
	if lower.ends_with(".ttf"): return "font/ttf"
	if lower.ends_with(".otf"): return "font/otf"
	if lower.ends_with(".txt"): return "text/plain; charset=utf-8"
	return "application/octet-stream"


func _exit_tree() -> void :
	for peer in _peers:
		peer.close(1000, "shutdown")
	_peers.clear()
	if _server:
		_server.stop()
	for client in _http_clients:
		var tcp: StreamPeerTCP = client["peer"]
		tcp.disconnect_from_host()
	_http_clients.clear()
	if _http_server:
		_http_server.stop()
