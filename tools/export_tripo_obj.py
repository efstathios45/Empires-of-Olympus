import bpy, os
jobs = [
 ("/workspace/assets/characters/city_guard/city_guard.glb", "/tmp/hellenic_packs/city_guard.obj"),
 ("/workspace/assets/characters/citizen_merchant/citizen_merchant.glb", "/tmp/hellenic_packs/citizen_merchant.obj"),
 ("/workspace/assets/characters/citizen_woman/citizen_woman.glb", "/tmp/hellenic_packs/citizen_woman.obj"),
 ("/workspace/assets/characters/blacksmith_npc/blacksmith_npc.glb", "/tmp/hellenic_packs/blacksmith.obj"),
 ("/workspace/assets/characters/oracle_priestess/oracle_priestess.glb", "/tmp/hellenic_packs/oracle.obj"),
 ("/workspace/assets/characters/spartan_hoplite/spartan_hoplite.glb", "/tmp/hellenic_packs/spartan.obj"),
]
os.makedirs("/tmp/hellenic_packs", exist_ok=True)
for src, dst in jobs:
  bpy.ops.wm.read_factory_settings(use_empty=True)
  bpy.ops.import_scene.gltf(filepath=src)
  meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
  arms=[o for o in bpy.context.scene.objects if o.type=="ARMATURE"]
  for a in arms:
    bpy.context.view_layer.objects.active=a
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.ops.object.mode_set(mode="OBJECT")
  bpy.context.view_layer.update()
  for m in meshes:
    bpy.ops.object.select_all(action="DESELECT")
    m.select_set(True)
    bpy.context.view_layer.objects.active=m
    for mod in list(m.modifiers):
      if mod.type=="ARMATURE":
        try:
          bpy.ops.object.modifier_apply(modifier=mod.name)
        except Exception as e:
          print("apply fail", m.name, e)
          m.modifiers.remove(mod)
    m.vertex_groups.clear()
    m.parent=None
  for a in arms:
    bpy.data.objects.remove(a, do_unlink=True)
  # also remove leftovers
  for o in list(bpy.context.scene.objects):
    if o.type not in ("MESH",):
      try: bpy.data.objects.remove(o, do_unlink=True)
      except: pass
  meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
  if not meshes:
    print("NO MESH", src); continue
  bpy.ops.object.select_all(action="DESELECT")
  for m in meshes: m.select_set(True)
  bpy.context.view_layer.objects.active=meshes[0]
  if len(meshes)>1:
    bpy.ops.object.join()
  bpy.ops.wm.obj_export(filepath=dst, export_selected_objects=True, export_materials=True, path_mode="COPY")
  print("OBJ", dst, os.path.getsize(dst))
print("EXPORT_DONE")
