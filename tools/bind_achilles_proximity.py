#!/usr/bin/env python3
"""Bind Achilles to Quaternius via measured T-pose raise + proximity bone weights.

Blender heat-map (ARMATURE_AUTO) melts this low-poly hero; distance-to-bone-segment
weights keep arms/cape/torso stable. Authentic CC0 Achilles texture, no GreekLook.
"""
from __future__ import annotations
import math
import os
import bmesh
import bpy
from mathutils import Vector

KING = "/workspace/assets/characters/quaternius_hero_king/hero_king.glb"
MESH = "/tmp/greekchars/achilles/Spartan Achilles/mesh.obj"
TEX = "/tmp/greekchars/achilles/Spartan Achilles/texture.png"
OUT = "/workspace/assets/characters/greek_hoplite/greek_hoplite.glb"
TARGET_H = 1.78

# Bones that deform the mesh (skip IK/helper clutter if present)
DEFORM_BONES = [
    "Hips", "Abdomen", "Torso", "Chest", "Neck", "Head",
    "Shoulder.L", "UpperArm.L", "LowerArm.L", "Wrist.L",
    "Shoulder.R", "UpperArm.R", "LowerArm.R", "Wrist.R",
    "UpperLeg.L", "LowerLeg.L", "Foot.L",
    "UpperLeg.R", "LowerLeg.R", "Foot.R",
]
# Finger tips get a little weight from wrist only
FINGER_PREFIXES = ("Thumb", "Index", "Middle", "Ring", "Pinky")


def clear() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def aabb(obj):
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    amin = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
    amax = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
    return amin, amax


def bone_world(arm, name):
    b = arm.data.bones.get(name)
    if b is None:
        return None
    return arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local


def rot_y(p: Vector, pivot: Vector, angle: float) -> Vector:
    q = p - pivot
    c, s = math.cos(angle), math.sin(angle)
    return Vector((c * q.x + s * q.z, q.y, -s * q.x + c * q.z)) + pivot


def xz_angle(v: Vector) -> float:
    return math.atan2(v.z, v.x)


def norm_pi(a: float) -> float:
    while a > math.pi:
        a -= 2.0 * math.pi
    while a < -math.pi:
        a += 2.0 * math.pi
    return a


def dist_point_segment(p: Vector, a: Vector, b: Vector) -> float:
    ab = b - a
    t = 0.0 if ab.length_squared < 1e-12 else max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


clear()
bpy.ops.import_scene.gltf(filepath=KING)
arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
for o in list(bpy.context.scene.objects):
    if o != arm and o.type in ("MESH", "EMPTY", "LIGHT", "CAMERA"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Collect bone segments in world (rest)
segments = []
for name in DEFORM_BONES:
    ht = bone_world(arm, name)
    if ht is None:
        continue
    # Radius: thicker for torso, tighter for limbs
    if name in ("Hips", "Abdomen", "Torso", "Chest"):
        rad = 0.30
    elif name in ("Neck", "Head"):
        rad = 0.18
    elif "Shoulder" in name:
        rad = 0.14
    elif "UpperArm" in name or "UpperLeg" in name:
        rad = 0.14
    elif "LowerArm" in name or "LowerLeg" in name:
        rad = 0.12
    elif "Wrist" in name or "Foot" in name:
        rad = 0.12
    else:
        rad = 0.12
    segments.append((name, ht[0], ht[1], rad))

# Finger bones → fold into Wrist
for b in arm.data.bones:
    if any(b.name.startswith(p) for p in FINGER_PREFIXES):
        side = ".L" if b.name.endswith(".L") else ".R"
        wname = "Wrist" + side
        ht = bone_world(arm, b.name)
        if ht and any(s[0] == wname for s in segments):
            # slight extra reach from finger bones into wrist bucket
            segments.append((wname, ht[0], ht[1], 0.06))

wr_l = bone_world(arm, "Wrist.L")[0]
wr_r = bone_world(arm, "Wrist.R")[0]
sh_l = bone_world(arm, "UpperArm.L")[0]
sh_r = bone_world(arm, "UpperArm.R")[0]
hips = bone_world(arm, "Hips")[0]
fl = bone_world(arm, "Foot.L")[0]
fr = bone_world(arm, "Foot.R")[0]

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

# Do NOT delete back gear — punching verts opened black torso holes.
# Stowed spear/shield stay as mesh detail (GearGrip still adds playable props).

tip_l = max(mesh.data.vertices, key=lambda v: v.co.x)
tip_r = min(mesh.data.vertices, key=lambda v: v.co.x)
rel_l = tip_l.co - sh_l
rel_r = tip_r.co - sh_r
tgt_l = wr_l - sh_l
tgt_r = wr_r - sh_r
ang_l = norm_pi(xz_angle(Vector((rel_l.x, 0, rel_l.z))) - xz_angle(Vector((tgt_l.x, 0, tgt_l.z))))
ang_r = norm_pi(xz_angle(Vector((rel_r.x, 0, rel_r.z))) - xz_angle(Vector((tgt_r.x, 0, tgt_r.z))))
print("raise_deg L", round(math.degrees(ang_l), 1), "R", round(math.degrees(ang_r), 1))

# Rigid raise for ARM verts only (exclude back-shield / deep-Y gear / cape flaps)
hips_z = hips.z
bm = bmesh.new()
bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()


def is_arm_vert(co: Vector, side_sign: float) -> bool:
    """Outer limb hanging beside the torso — not the back-carried aspis/dory."""
    if co.z < hips_z + 0.02:
        return False
    if co.x * side_sign < 0.18:
        return False
    # Stowed aspis: deep back, near midline/mid torso. Hands sit farther out on X.
    if co.y < -0.14 and abs(co.x) < 0.42 and 0.65 < co.z < 1.35:
        return False
    # Stowed spear shaft/tip behind
    if co.y < -0.14 and abs(co.x) < 0.35 and co.z > 1.45:
        return False
    return True


raised_l: set[int] = set()
raised_r: set[int] = set()
for v in bm.verts:
    co = v.co.copy()
    if is_arm_vert(co, 1.0):
        v.co = rot_y(co, sh_l, ang_l)
        raised_l.add(v.index)
    elif is_arm_vert(co, -1.0):
        v.co = rot_y(co, sh_r, ang_r)
        raised_r.add(v.index)
bm.to_mesh(mesh.data)
bm.free()
mesh.data.update()
print("raised L", len(raised_l), "R", len(raised_r))

# Scale only raised arm verts so farthest tip lands on wrist
tip_l = max(mesh.data.vertices, key=lambda v: v.co.x)
tip_r = min(mesh.data.vertices, key=lambda v: v.co.x)
print("pre-scale tips", tuple(round(c, 3) for c in tip_l.co), tuple(round(c, 3) for c in tip_r.co))


def scale_arm_out(side_sign: float, shoulder: Vector, wrist: Vector, indices: set[int]) -> None:
    target_len = (wrist - shoulder).length
    far_d = 0.0
    for vi in indices:
        v = mesh.data.vertices[vi]
        if v.co.x * side_sign < 0.18:
            continue
        d = (v.co - shoulder).length
        if d > far_d:
            far_d = d
    if far_d < 1e-4:
        return
    scale = target_len / far_d
    print(f"arm_scale side={side_sign} {scale:.3f} far={far_d:.3f} tgt={target_len:.3f}")
    bm2 = bmesh.new()
    bm2.from_mesh(mesh.data)
    bm2.verts.ensure_lookup_table()
    for vi in indices:
        v = bm2.verts[vi]
        if v.co.x * side_sign < 0.18:
            continue
        v.co = shoulder + (v.co - shoulder) * scale
    bm2.to_mesh(mesh.data)
    bm2.free()
    mesh.data.update()


scale_arm_out(1.0, sh_l, wr_l, raised_l)
scale_arm_out(-1.0, sh_r, wr_r, raised_r)
tip_l = max(mesh.data.vertices, key=lambda v: v.co.x)
tip_r = min(mesh.data.vertices, key=lambda v: v.co.x)
print("post tips L", tuple(round(c, 3) for c in tip_l.co), "vs", tuple(round(c, 3) for c in wr_l))
print("post tips R", tuple(round(c, 3) for c in tip_r.co), "vs", tuple(round(c, 3) for c in wr_r))

# Parent with empty groups, then paint proximity weights
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_NAME")  # empty groups for all bones

# Ensure groups exist
for name, _, _, _ in segments:
    if mesh.vertex_groups.find(name) < 0:
        mesh.vertex_groups.new(name=name)

# Clear all weights
for vg in mesh.vertex_groups:
    vg.remove(range(len(mesh.data.vertices)))

POWER = 3.0
for vi, v in enumerate(mesh.data.vertices):
    p = v.co
    weights = {}
    for name, a, b, rad in segments:
        d = dist_point_segment(p, a, b)
        if d >= rad:
            continue
        w = (1.0 - d / rad) ** POWER
        weights[name] = weights.get(name, 0.0) + w
    if not weights:
        # fallback nearest bone
        best_n, best_d = "Hips", 1e9
        for name, a, b, rad in segments:
            d = dist_point_segment(p, a, b)
            if d < best_d:
                best_d = d
                best_n = name
        weights = {best_n: 1.0}
    # Cap to 4 influences
    items = sorted(weights.items(), key=lambda kv: -kv[1])[:4]
    total = sum(w for _, w in items) or 1.0
    for name, w in items:
        mesh.vertex_groups[name].add([vi], w / total, "REPLACE")

zero = sum(1 for v in mesh.data.vertices if sum(g.weight for g in v.groups) < 1e-5)
print(f"zero_weights={zero}/{len(mesh.data.vertices)}")
mass = {}
for v in mesh.data.vertices:
    for g in v.groups:
        name = mesh.vertex_groups[g.group].name
        if any(k in name for k in ("Arm", "Wrist", "Shoulder")):
            mass[name] = mass.get(name, 0.0) + g.weight
print("arm mass", {k: round(v, 1) for k, v in sorted(mass.items())})
for label, tip in (("L", tip_l), ("R", tip_r)):
    tip = max(mesh.data.vertices, key=lambda v: v.co.x) if label == "L" else min(mesh.data.vertices, key=lambda v: v.co.x)
    wmap = {mesh.vertex_groups[g.group].name: round(g.weight, 3) for g in tip.groups}
    print(f"tip_{label}", tuple(round(c, 3) for c in tip.co), wmap)

# Make sure Armature modifier exists and uses vertex groups
has_arm = any(m.type == "ARMATURE" for m in mesh.modifiers)
if not has_arm:
    mod = mesh.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
else:
    for m in mesh.modifiers:
        if m.type == "ARMATURE":
            m.object = arm

for o in list(bpy.context.scene.objects):
    if o.type not in ("ARMATURE", "MESH"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = arm
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
print("PROXIMITY_BIND_OK")
