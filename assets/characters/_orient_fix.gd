@tool
extends EditorScenePostImport












func _post_import(scene: Node) -> Object:
	if scene is Node3D:
		(scene as Node3D).rotation.y = PI
	return scene
