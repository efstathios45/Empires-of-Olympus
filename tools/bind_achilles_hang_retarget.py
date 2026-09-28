#!/usr/bin/env python3
"""Bind hang Achilles: hang-rest dest armature + hierarchy-ordered world retarget from King."""
from __future__ import annotations
import math
import os
import bpy
from mathutils import Matrix, Vector

KING = "/workspace/assets/characters/quaternius_hero_king/hero_king.glb"
MESH = "/tmp/greekchars/achilles/Spartan Achilles/mesh.obj"
TEX = "/tmp/greekchars/achilles/Spartan Achilles/texture.png"
OUT = "/workspace/assets/characters/greek_hoplite/greek_hoplite.glb"
TARGET_H = 1.78
FRAME_STEP = 1


def clear() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def aabb(obj):
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    amin = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
    amax = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
    return amin, amax


def bone_head(arm, name):
    b = arm.data.bones.get(name)
    return None if not b else arm.matrix_world @ b.head_local


def hierarchy_pose_bones(arm):
    """Root-to-tip pose bone order."""
    ordered = []
    def walk(pb):
        ordered.append(pb)
        for ch in pb.children:
            walk(ch)
    for pb in arm.pose.bones:
        if pb.parent is None:
            walk(pb)
    return ordered


clear()
bpy.ops.import_scene.gltf(filepath=KING)
src = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
src.name = "SrcArm"
for o in list(bpy.context.scene.objects):
    if o != src and o.type in ("MESH", "EMPTY", "LIGHT", "CAMERA"):
        bpy.data.objects.remove(o, do_unlink=True)

bpy.ops.object.select_all(action="DESELECT")
src.select_set(True)
bpy.context.view_layer.objects.active = src
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Duplicate armature for destination (hang rest)
bpy.ops.object.duplicate()
dst = bpy.context.view_layer.objects.active
dst.name = "CharacterArmature"
# Remove actions from dst — we'll bake new ones
if dst.animation_data:
    dst.animation_data.action = None

# Pose src to Idle_Neutral frame 0 for hang reference
src.animation_data_create()
idle_act = next(a for a in bpy.data.actions if "Idle_Neutral" in a.name and a.name.count("CharacterArmature") == 1)
# Prefer original short names — after import they're Name_CharacterArmature
print("idle_act", idle_act.name, "all", [a.name for a in bpy.data.actions][:5])
src.animation_data.action = idle_act
bpy.context.scene.frame_set(int(idle_act.frame_range[0]))
bpy.context.view_layer.update()

# Copy src pose world matrices onto dst, then apply as rest on dst
bpy.ops.object.select_all(action="DESELECT")
dst.select_set(True)
bpy.context.view_layer.objects.active = dst
bpy.ops.object.mode_set(mode="POSE")
for pb_src, pb_dst in zip(hierarchy_pose_bones(src), hierarchy_pose_bones(dst)):
    # Match by name
    pass
src_world = {pb.name: (src.matrix_world @ pb.matrix).copy() for pb in src.pose.bones}
for pb in hierarchy_pose_bones(dst):
    if pb.name in src_world:
        # dst.matrix_world should be I; set armature-space matrix
        pb.matrix = src.matrix_world.inverted() @ src_world[pb.name]
bpy.context.view_layer.update()
bpy.ops.pose.armature_apply()
bpy.ops.object.mode_set(mode="OBJECT")
print("dst rest = hang")

# Clear dst pose
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.pose.transforms_clear()
bpy.ops.object.mode_set(mode="OBJECT")

# --- Import hang Achilles onto dst ---
before = set(bpy.context.scene.objects)
bpy.ops.wm.obj_import(filepath=MESH)
meshes = [o for o in bpy.context.scene.objects if o not in before and o.type == "MESH"]
if len(meshes) > 1:
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    mesh = bpy.context.view_layer.objects.active
else:
    mesh = meshes[0]
mesh.name = "GreekHopliteMesh"
for mod in list(mesh.modifiers):
    if mod.type == "ARMATURE":
        mesh.modifiers.remove(mod)
mesh.vertex_groups.clear()
mesh.parent = None

amin, amax = aabb(mesh)
span = amax - amin
up = max(range(3), key=lambda i: span[i])
if up == 1:
    mesh.rotation_euler[0] += -math.pi / 2
elif up == 0:
    mesh.rotation_euler[1] += math.pi / 2
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

hips = bone_head(dst, "Hips")
fl = bone_head(dst, "Foot.L")
fr = bone_head(dst, "Foot.R")
foot_z = min(fl.z, fr.z)
amin, amax = aabb(mesh)
mesh.scale *= TARGET_H / (amax.z - amin.z)
bpy.context.view_layer.update()
amin, amax = aabb(mesh)
mesh.location.x += hips.x - 0.5 * (amin.x + amax.x)
mesh.location.y += hips.y - 0.5 * (amin.y + amax.y)
mesh.location.z += foot_z - amin.z
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

if os.path.isfile(TEX):
    img = bpy.data.images.load(TEX)
    mat = bpy.data.materials.new("HellenicSkin")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    outn = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], outn.inputs["Surface"])
    if mesh.data.materials:
        mesh.data.materials[0] = mat
    else:
        mesh.data.materials.append(mat)

bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
dst.select_set(True)
bpy.context.view_layer.objects.active = dst
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
zero = sum(1 for v in mesh.data.vertices if sum(g.weight for g in v.groups) < 1e-5)
print(f"zero_weights={zero}/{len(mesh.data.vertices)}")
mass = {}
for v in mesh.data.vertices:
    for g in v.groups:
        n = mesh.vertex_groups[g.group].name
        if any(k in n for k in ("Arm", "Wrist", "Shoulder")):
            mass[n] = mass.get(n, 0.0) + g.weight
print("arm mass", {k: round(v, 1) for k, v in sorted(mass.items())})

# --- Bake retargeted actions onto dst from src world poses ---
# Collect original action names before we create new ones
src_actions = [a for a in bpy.data.actions if a.name.count("CharacterArmature") <= 1]
# Actually all imported actions have _CharacterArmature once. New ones we'll name cleanly.
src_actions = list(bpy.data.actions)
print("src actions", len(src_actions))

dst.animation_data_create()
for pb in dst.pose.bones:
    pb.rotation_mode = "QUATERNION"

new_actions = []
for act in src_actions:
    # Clean name: Idle_Neutral_CharacterArmature -> Idle_Neutral
    clean = act.name
    if clean.endswith("_CharacterArmature"):
        clean = clean[: -len("_CharacterArmature")]
    f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
    frames = list(range(f0, f1 + 1, FRAME_STEP))
    if frames[-1] != f1:
        frames.append(f1)

    new_act = bpy.data.actions.new(name=clean)
    dst.animation_data.action = new_act
    src.animation_data.action = act

    for f in frames:
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        world = {pb.name: (src.matrix_world @ pb.matrix).copy() for pb in src.pose.bones}
        for pb in hierarchy_pose_bones(dst):
            if pb.name not in world:
                continue
            pb.matrix = dst.matrix_world.inverted() @ world[pb.name]
        bpy.context.view_layer.update()
        for pb in dst.pose.bones:
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("rotation_quaternion", frame=f)
            pb.keyframe_insert("scale", frame=f)
    new_act.use_frame_range = True
    new_act.frame_start = f0
    new_act.frame_end = f1
    new_actions.append(clean)
    print("baked", clean, "frames", len(frames))

# Delete source armature and old actions that still reference it
bpy.data.objects.remove(src, do_unlink=True)
# Remove old CharacterArmature-suffixed actions not in new set
for act in list(bpy.data.actions):
    if act.name not in new_actions:
        bpy.data.actions.remove(act)

dst.animation_data.action = bpy.data.actions.get("Idle_Neutral")

for o in list(bpy.context.scene.objects):
    if o.type not in ("ARMATURE", "MESH"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
dst.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = dst
bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_skins=True,
    export_morph=False,
    export_apply=False,
)
print("EXPORTED", OUT, os.path.getsize(OUT))
print("actions_out", [a.name for a in bpy.data.actions])
print("HANG_RETARGET_OK")
