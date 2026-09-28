#!/usr/bin/env python3
"""Bind Ancient Greek CC0 / Tripo meshes onto Quaternius Ultimate Modular armature.

Keeps Quaternius Z-up + authored Walk / Idle / Sword_Slash clips. Auto-weights
each Hellenic mesh so Godot plays real animations (no LegPlant).
"""
from __future__ import annotations

import math
import os
import sys

import bpy
from mathutils import Vector

KING = "/workspace/assets/characters/quaternius_hero_king/hero_king.glb"
OUT_DIR = "/workspace/assets/characters"

# mesh_path, texture_or_None, out_subdir, out_glb_name, target_height_m
# Static OBJs (no skin) bind cleanly; Tripo GLBs leave orphan skins that crash export.
JOBS = [
    (
        "/tmp/greekchars/achilles/Spartan Achilles/mesh.obj",
        "/tmp/greekchars/achilles/Spartan Achilles/texture.png",
        "greek_hoplite",
        "greek_hoplite.glb",
        1.78,
    ),
    (
        "/tmp/hellenic_packs/spartan.obj",
        None,
        "greek_spartan",
        "greek_spartan.glb",
        1.78,
    ),
    (
        "/tmp/hellenic_packs/city_guard.obj",
        None,
        "greek_guard",
        "greek_guard.glb",
        1.78,
    ),
    (
        "/tmp/hellenic_packs/citizen_merchant.obj",
        None,
        "greek_merchant",
        "greek_merchant.glb",
        1.72,
    ),
    (
        "/tmp/hellenic_packs/citizen_woman.obj",
        None,
        "greek_citizen_woman",
        "greek_citizen_woman.glb",
        1.65,
    ),
    (
        "/tmp/hellenic_packs/blacksmith.obj",
        None,
        "greek_smith",
        "greek_smith.glb",
        1.75,
    ),
    (
        "/tmp/hellenic_packs/oracle.obj",
        None,
        "greek_oracle",
        "greek_oracle.glb",
        1.68,
    ),
]


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def bone_world(arm, name: str) -> Vector | None:
    b = arm.data.bones.get(name)
    if b is None:
        return None
    return arm.matrix_world @ b.head_local


def aabb(obj):
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    amin = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
    amax = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
    return amin, amax


def delete_non_armature_junk(arm, keep_weight_donors: bool = False) -> list:
    """Remove Quaternius meshes + stray icospheres; keep armature + actions.

    When keep_weight_donors is True, retain body/leg meshes for Data Transfer.
    """
    donors = []
    doomed = []
    for o in list(bpy.context.scene.objects):
        if o == arm:
            continue
        if o.type == "MESH":
            n = o.name.lower()
            if keep_weight_donors and any(k in n for k in ("body", "leg", "feet", "head", "arm")):
                donors.append(o)
            else:
                doomed.append(o)
        elif o.type == "EMPTY" or "icosphere" in o.name.lower():
            doomed.append(o)
    for o in doomed:
        bpy.data.objects.remove(o, do_unlink=True)
    return donors


def import_source_mesh(path: str):
    """Import OBJ or GLB and return a single joined MESH object (no armature)."""
    before = set(bpy.context.scene.objects)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".obj":
        bpy.ops.wm.obj_import(filepath=path)
    elif ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    else:
        raise RuntimeError(f"unsupported mesh format: {path}")
    after = [o for o in bpy.context.scene.objects if o not in before]

    # Drop any armature that came with a Tripo GLB — we only want the mesh.
    for o in list(after):
        if o.type == "ARMATURE":
            bpy.data.objects.remove(o, do_unlink=True)
            after.remove(o)

    meshes = [o for o in after if o.type == "MESH"]
    # Clear existing armature modifiers / vertex groups from Tripo skins.
    for m in meshes:
        for mod in list(m.modifiers):
            if mod.type == "ARMATURE":
                m.modifiers.remove(mod)
        m.vertex_groups.clear()
        # Unparent from deleted armatures
        m.parent = None
        m.matrix_parent_inverse.identity()

    if not meshes:
        raise RuntimeError(f"no mesh imported from {path}")
    if len(meshes) > 1:
        bpy.ops.object.select_all(action="DESELECT")
        for o in meshes:
            o.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
        mesh = bpy.context.view_layer.objects.active
    else:
        mesh = meshes[0]
    return mesh


def upright_z(mesh) -> None:
    """Ensure mesh height axis is +Z (Blender / Quaternius convention)."""
    amin, amax = aabb(mesh)
    span = amax - amin
    up = max(range(3), key=lambda i: span[i])
    if up == 2:
        return  # already Z-up
    if up == 1:
        # Y was tallest → rotate -90° around X so Y → Z
        mesh.rotation_euler[0] += -math.pi / 2
    elif up == 0:
        # X was tallest → rotate +90° around Y so X → Z
        mesh.rotation_euler[1] += math.pi / 2
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)


def fit_to_armature(mesh, arm, target_h: float) -> None:
    """Scale mesh so sole→crown ≈ target_h and center on armature feet/hips."""
    fl = bone_world(arm, "Foot.L")
    fr = bone_world(arm, "Foot.R")
    head = bone_world(arm, "Head")
    hips = bone_world(arm, "Hips")
    foot_z = min(fl.z, fr.z)
    # Prefer bone span; fall back to target_h
    bone_h = (head.z - foot_z) if head and fl else target_h
    want = target_h if target_h > 0.5 else bone_h

    amin, amax = aabb(mesh)
    mesh_h = amax.z - amin.z
    if mesh_h < 1e-4:
        raise RuntimeError("mesh has zero height")
    s = want / mesh_h
    mesh.scale *= s
    bpy.context.view_layer.update()

    amin, amax = aabb(mesh)
    # Place soles on foot_z, center X on hips, center Y on hips (forward)
    cx = 0.5 * (amin.x + amax.x)
    cy = 0.5 * (amin.y + amax.y)
    mesh.location.x += (hips.x if hips else 0.0) - cx
    mesh.location.y += (hips.y if hips else 0.0) - cy
    mesh.location.z += foot_z - amin.z
    bpy.context.view_layer.update()

    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def apply_texture(mesh, tex_path: str | None) -> None:
    if not tex_path or not os.path.isfile(tex_path):
        return
    img = bpy.data.images.load(tex_path)
    mat = bpy.data.materials.new(name="HellenicSkin")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    if mesh.data.materials:
        mesh.data.materials[0] = mat
    else:
        mesh.data.materials.append(mat)


def _decimate_if_dense(mesh, max_faces: int = 12000) -> None:
    me = mesh.data
    if me is None or len(me.polygons) <= max_faces:
        return
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    mod = mesh.modifiers.new(name="Dec", type="DECIMATE")
    mod.ratio = max_faces / float(len(me.polygons))
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print(f"decimated {mesh.name} -> {len(mesh.data.polygons)} faces")


def _count_zero_weights(mesh) -> int:
    if not mesh.data or not mesh.vertex_groups:
        return len(mesh.data.vertices) if mesh.data else 0
    zero = 0
    for v in mesh.data.vertices:
        wsum = 0.0
        for g in v.groups:
            wsum += g.weight
        if wsum < 1e-5:
            zero += 1
    return zero


def skin(mesh, arm, donors: list | None = None) -> None:
    _decimate_if_dense(mesh)
    mesh.vertex_groups.clear()
    for mod in list(mesh.modifiers):
        if mod.type == "ARMATURE":
            mesh.modifiers.remove(mod)
    mesh.parent = None

    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")

    arm_mod = None
    for mod in mesh.modifiers:
        if mod.type == "ARMATURE":
            arm_mod = mod
            break
    if arm_mod is None:
        arm_mod = mesh.modifiers.new(name="Armature", type="ARMATURE")
    arm_mod.object = arm
    arm_mod.use_vertex_groups = True

    zero = _count_zero_weights(mesh)
    nverts = len(mesh.data.vertices) if mesh.data else 0
    donor_objs = [d for d in (donors or []) if d is not None and d.name in bpy.data.objects]
    if nverts and zero > nverts * 0.12 and donor_objs:
        print(f"data-transfer weights ({zero}/{nverts} zero)")
        bpy.ops.object.select_all(action="DESELECT")
        for d in donor_objs:
            d.select_set(True)
        bpy.context.view_layer.objects.active = donor_objs[0]
        if len(donor_objs) > 1:
            bpy.ops.object.join()
        donor = bpy.context.view_layer.objects.active
        donor.name = "WeightDonor"
        mesh.vertex_groups.clear()
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select_set(True)
        bpy.context.view_layer.objects.active = mesh
        dt = mesh.modifiers.new(name="DT", type="DATA_TRANSFER")
        dt.object = donor
        dt.use_vert_data = True
        dt.data_types_verts = {"VGROUP_WEIGHTS"}
        dt.vert_mapping = "POLYINTERP_NEAREST"
        bpy.ops.object.datalayout_transfer(modifier="DT")
        bpy.ops.object.modifier_apply(modifier="DT")
        bpy.data.objects.remove(donor, do_unlink=True)
        for mod in list(mesh.modifiers):
            if mod.type == "ARMATURE":
                mesh.modifiers.remove(mod)
        arm_mod = mesh.modifiers.new(name="Armature", type="ARMATURE")
        arm_mod.object = arm
        mesh.parent = arm
        zero = _count_zero_weights(mesh)
        print(f"after transfer zero={zero}/{nverts}")
    elif nverts and zero > nverts * 0.15:
        print(f"re-skin envelope ({zero} zero-weight verts)")
        mesh.vertex_groups.clear()
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select_set(True)
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        bpy.ops.object.parent_set(type="ARMATURE_ENVELOPE")
        for mod in mesh.modifiers:
            if mod.type == "ARMATURE":
                mod.object = arm
    # Drop leftover donors (joined donor already removed).
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and o != mesh and ("king" in o.name.lower() or "donor" in o.name.lower()
                or "body" in o.name.lower() or "weight" in o.name.lower()):
            bpy.data.objects.remove(o, do_unlink=True)


def export_glb(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    # Purge everything else (cameras, lights, empties, leftovers).
    for o in list(bpy.context.scene.objects):
        if o.type not in ("ARMATURE", "MESH"):
            bpy.data.objects.remove(o, do_unlink=True)
    # Parent mesh under armature (keeps glTF skin gathering happy).
    for m in meshes:
        if m.parent != arm:
            m.parent = arm
            # Keep world transform
            m.matrix_parent_inverse = arm.matrix_world.inverted()
        # One armature modifier only
        mods = [mod for mod in m.modifiers if mod.type == "ARMATURE"]
        for mod in mods[1:]:
            m.modifiers.remove(mod)
        if mods:
            mods[0].object = arm
        else:
            mod = m.modifiers.new(name="Armature", type="ARMATURE")
            mod.object = arm
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_extras=False,
        export_def_bones=False,
    )


def bind_one(mesh_path: str, tex: str | None, out_sub: str, out_name: str, height: float) -> str:
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=KING)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    # Keep Quaternius body parts as weight donors for stubborn AI meshes.
    use_donors = "achilles" not in mesh_path.lower()
    donors = delete_non_armature_junk(arm, keep_weight_donors=use_donors)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    mesh = import_source_mesh(mesh_path)
    mesh.name = out_sub.replace("_", " ").title().replace(" ", "") + "Mesh"
    upright_z(mesh)
    fit_to_armature(mesh, arm, height)
    apply_texture(mesh, tex)
    skin(mesh, arm, donors=donors if use_donors else None)

    amin, amax = aabb(mesh)
    fl = bone_world(arm, "Foot.L")
    head = bone_world(arm, "Head")
    print(
        f"BOUND {out_name}: meshZ=[{amin.z:.3f},{amax.z:.3f}] "
        f"foot={fl.z:.3f} head={head.z:.3f} vgroups={len(mesh.vertex_groups)}"
    )

    out = os.path.join(OUT_DIR, out_sub, out_name)
    export_glb(out)
    print(f"EXPORTED {out} bytes={os.path.getsize(out)}")
    return out


def main() -> int:
    only = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    done = []
    for mesh_path, tex, sub, name, h in JOBS:
        if only and sub not in only and name not in only:
            continue
        if not os.path.isfile(mesh_path):
            print(f"SKIP missing {mesh_path}")
            continue
        try:
            done.append(bind_one(mesh_path, tex, sub, name, h))
        except Exception as exc:
            print(f"FAIL {name}: {exc}")
            raise
    print("ALL_DONE", len(done), done)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
