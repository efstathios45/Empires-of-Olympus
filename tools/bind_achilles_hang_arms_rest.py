#!/usr/bin/env python3
from __future__ import annotations
import math, os, bpy
from mathutils import Vector

KING = "/workspace/assets/characters/quaternius_hero_king/hero_king.glb"
MESH = "/tmp/greekchars/achilles/Spartan Achilles/mesh.obj"
TEX = "/tmp/greekchars/achilles/Spartan Achilles/texture.png"
OUT = "/workspace/assets/characters/greek_hoplite/greek_hoplite.glb"
TARGET_H = 1.78
ARM_KEYS = ("Shoulder","UpperArm","LowerArm","Wrist","Thumb","Index","Middle","Ring","Pinky")

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)
def aabb(obj):
    bb=[obj.matrix_world@Vector(c) for c in obj.bound_box]
    amin=Vector((min(v.x for v in bb),min(v.y for v in bb),min(v.z for v in bb)))
    amax=Vector((max(v.x for v in bb),max(v.y for v in bb),max(v.z for v in bb)))
    return amin,amax
def bone_head(arm,name):
    b=arm.data.bones.get(name)
    return None if not b else arm.matrix_world@b.head_local
def is_arm(n):
    return any(k in n for k in ARM_KEYS)

clear()
bpy.ops.import_scene.gltf(filepath=KING)
arm=next(o for o in bpy.context.scene.objects if o.type=="ARMATURE")
for o in list(bpy.context.scene.objects):
    if o!=arm and o.type in ("MESH","EMPTY","LIGHT","CAMERA"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)

idle=next(a for a in bpy.data.actions if a.name.startswith("Idle_Neutral"))
arm.animation_data_create(); arm.animation_data.action=idle
bpy.context.scene.frame_set(int(idle.frame_range[0]))
bpy.context.view_layer.update()
bases={pb.name: pb.matrix_basis.copy() for pb in arm.pose.bones if is_arm(pb.name)}
print("saved bases", len(bases), "Wrist.L world", (arm.matrix_world@arm.pose.bones["Wrist.L"].matrix).translation)

arm.animation_data.action=None
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.pose.transforms_clear()
bpy.context.view_layer.update()
for name, mb in bases.items():
    arm.pose.bones[name].matrix_basis = mb
bpy.context.view_layer.update()
print("basis hang Wrist.L", (arm.matrix_world@arm.pose.bones["Wrist.L"].matrix).translation)
print("Chest world", (arm.matrix_world@arm.pose.bones["Chest"].matrix).translation)

bpy.ops.pose.select_all(action="DESELECT")
for pb in arm.pose.bones:
    pb.bone.select = is_arm(pb.name)
bpy.ops.pose.armature_apply(selected=True)
bpy.ops.pose.select_all(action="SELECT")
bpy.ops.pose.transforms_clear()
bpy.ops.object.mode_set(mode="OBJECT")
print("rest Wrist.L", bone_head(arm,"Wrist.L"), "Foot.L", bone_head(arm,"Foot.L"))

before=set(bpy.context.scene.objects)
bpy.ops.wm.obj_import(filepath=MESH)
meshes=[o for o in bpy.context.scene.objects if o not in before and o.type=="MESH"]
if len(meshes)>1:
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join(); mesh=bpy.context.view_layer.objects.active
else:
    mesh=meshes[0]
mesh.name="GreekHopliteMesh"
for mod in list(mesh.modifiers):
    if mod.type=="ARMATURE": mesh.modifiers.remove(mod)
mesh.vertex_groups.clear(); mesh.parent=None
amin,amax=aabb(mesh); span=amax-amin; up=max(range(3),key=lambda i:span[i])
if up==1: mesh.rotation_euler[0]+=-math.pi/2
elif up==0: mesh.rotation_euler[1]+=math.pi/2
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True)
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.transform_apply(location=False,rotation=True,scale=False)
hips=bone_head(arm,"Hips"); fl=bone_head(arm,"Foot.L"); fr=bone_head(arm,"Foot.R")
foot_z=min(fl.z,fr.z)
amin,amax=aabb(mesh); mesh.scale*=TARGET_H/(amax.z-amin.z)
bpy.context.view_layer.update(); amin,amax=aabb(mesh)
mesh.location.x+=hips.x-0.5*(amin.x+amax.x)
mesh.location.y+=hips.y-0.5*(amin.y+amax.y)
mesh.location.z+=foot_z-amin.z
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True)
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0015)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")
if os.path.isfile(TEX):
    img=bpy.data.images.load(TEX)
    mat=bpy.data.materials.new("HellenicSkin"); mat.use_nodes=True
    nodes=mat.node_tree.nodes; links=mat.node_tree.links; nodes.clear()
    outn=nodes.new("ShaderNodeOutputMaterial"); bsdf=nodes.new("ShaderNodeBsdfPrincipled")
    tex=nodes.new("ShaderNodeTexImage"); tex.image=img
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], outn.inputs["Surface"])
    if mesh.data.materials: mesh.data.materials[0]=mat
    else: mesh.data.materials.append(mat)
print("tips", tuple(round(c,3) for c in max(mesh.data.vertices,key=lambda v:v.co.x).co), "wrists", bone_head(arm,"Wrist.L"), bone_head(arm,"Wrist.R"))
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
mass={}
for v in mesh.data.vertices:
    for g in v.groups:
        n=mesh.vertex_groups[g.group].name
        if any(k in n for k in ("Arm","Wrist","Shoulder")):
            mass[n]=mass.get(n,0)+g.weight
print("arm mass", {k:round(v,1) for k,v in sorted(mass.items())})
arm.animation_data_create(); arm.animation_data.action=idle
for o in list(bpy.context.scene.objects):
    if o.type not in ("ARMATURE","MESH"): bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True); mesh.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True,
    export_animations=True, export_skins=True, export_morph=False, export_apply=False)
print("EXPORTED", os.path.getsize(OUT)); print("BASIS_OK")
