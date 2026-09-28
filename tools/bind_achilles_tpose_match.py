#!/usr/bin/env python3
"""Full pipeline: raise Achilles, WELD seams, AUTO, flood arm weights, torso scrub, normals."""
from __future__ import annotations
import math, os, bmesh, bpy
from mathutils import Vector

KING = "/workspace/assets/characters/quaternius_hero_king/hero_king.glb"
MESH = "/tmp/greekchars/achilles/Spartan Achilles/mesh.obj"
TEX = "/tmp/greekchars/achilles/Spartan Achilles/texture.png"
OUT = "/workspace/assets/characters/greek_hoplite/greek_hoplite.glb"
TARGET_H = 1.78

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)
def aabb(obj):
    bb=[obj.matrix_world@Vector(c) for c in obj.bound_box]
    amin=Vector((min(v.x for v in bb),min(v.y for v in bb),min(v.z for v in bb)))
    amax=Vector((max(v.x for v in bb),max(v.y for v in bb),max(v.z for v in bb)))
    return amin,amax
def bone_ht(arm,name):
    b=arm.data.bones.get(name)
    if not b: return None
    return arm.matrix_world@b.head_local, arm.matrix_world@b.tail_local
def bone_head(arm,name):
    ht=bone_ht(arm,name); return None if not ht else ht[0]
def rot_y(p,pivot,angle):
    q=p-pivot; c,s=math.cos(angle),math.sin(angle)
    return Vector((c*q.x+s*q.z,q.y,-s*q.x+c*q.z))+pivot
def xz_angle(v): return math.atan2(v.z,v.x)
def norm_pi(a):
    while a>math.pi: a-=2*math.pi
    while a<-math.pi: a+=2*math.pi
    return a
def dist_seg(p,a,b):
    ab=b-a
    t=0.0 if ab.length_squared<1e-12 else max(0.0,min(1.0,(p-a).dot(ab)/ab.length_squared))
    return (p-(a+ab*t)).length,t

clear()
bpy.ops.import_scene.gltf(filepath=KING)
arm=next(o for o in bpy.context.scene.objects if o.type=="ARMATURE")
for o in list(bpy.context.scene.objects):
    if o!=arm and o.type in ("MESH","EMPTY","LIGHT","CAMERA"):
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)

wr_l,wr_r=bone_head(arm,"Wrist.L"),bone_head(arm,"Wrist.R")
sh_l,sh_r=bone_head(arm,"UpperArm.L"),bone_head(arm,"UpperArm.R")
hips=bone_head(arm,"Hips"); fl=bone_head(arm,"Foot.L"); fr=bone_head(arm,"Foot.R")
def chain(side):
    out=[]
    for n in (f"Shoulder.{side}",f"UpperArm.{side}",f"LowerArm.{side}",f"Wrist.{side}"):
        ht=bone_ht(arm,n)
        if ht: out.append((n,ht[0],ht[1]))
    return out
chain_l,chain_r=chain("L"),chain("R")

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

# WELD first (before raise) so arm islands join torso
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0015)
bpy.ops.object.mode_set(mode="OBJECT")
print("welded verts", len(mesh.data.vertices))

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

tip_l=max(mesh.data.vertices,key=lambda v:v.co.x)
tip_r=min(mesh.data.vertices,key=lambda v:v.co.x)
rel_l,rel_r=tip_l.co-sh_l, tip_r.co-sh_r
tgt_l,tgt_r=wr_l-sh_l, wr_r-sh_r
ang_l=norm_pi(xz_angle(Vector((rel_l.x,0,rel_l.z)))-xz_angle(Vector((tgt_l.x,0,tgt_l.z))))
ang_r=norm_pi(xz_angle(Vector((rel_r.x,0,rel_r.z)))-xz_angle(Vector((tgt_r.x,0,tgt_r.z))))
hips_z=hips.z
print("raise_deg", round(math.degrees(ang_l),1), round(math.degrees(ang_r),1))

# Volume raise: all outer limb verts (flood alone only gets thin hand islands)
bm=bmesh.new(); bm.from_mesh(mesh.data); bm.verts.ensure_lookup_table()
raised_l, raised_r = set(), set()
for v in bm.verts:
    co = v.co.copy()
    if co.z < hips_z + 0.02:
        continue
    # skip back-carried aspis/spear
    if co.y < -0.14 and abs(co.x) < 0.45:
        continue
    if co.x > 0.14:
        t = min(1.0, max(0.0, (co.x - 0.14) / 0.20))
        if t <= 0:
            continue
        v.co = co.lerp(rot_y(co, sh_l, ang_l), t)
        if t > 0.25:
            raised_l.add(v.index)
    elif co.x < -0.14:
        t = min(1.0, max(0.0, (-co.x - 0.14) / 0.20))
        if t <= 0:
            continue
        v.co = co.lerp(rot_y(co, sh_r, ang_r), t)
        if t > 0.25:
            raised_r.add(v.index)
print("volume raised", len(raised_l), len(raised_r))
for sign, pivot, wrist, idxs, label in (
    (1.0, sh_l, wr_l, raised_l, "L"),
    (-1.0, sh_r, wr_r, raised_r, "R"),
):
    target = (wrist - pivot).length
    far = max(((bm.verts[i].co - pivot).length for i in idxs if bm.verts[i].co.x * sign >= 0.14), default=0)
    if far < 1e-4:
        continue
    sc = target / far
    print("scale", label, round(sc, 3), "n", len(idxs))
    for i in idxs:
        v = bm.verts[i]
        if v.co.x * sign < 0.14:
            continue
        v.co = pivot + (v.co - pivot) * sc
bm.to_mesh(mesh.data); bm.free(); mesh.data.update()

# Weld again after raise (seams may have shifted)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.002)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode="OBJECT")
print("after raise verts", len(mesh.data.vertices))
tip_l=max(mesh.data.vertices,key=lambda v:v.co.x)
tip_r=min(mesh.data.vertices,key=lambda v:v.co.x)
print("tips", tuple(round(c,3) for c in tip_l.co), tuple(round(c,3) for c in tip_r.co))

# Connectivity check
bm=bmesh.new(); bm.from_mesh(mesh.data); bm.verts.ensure_lookup_table(); bm.edges.ensure_lookup_table()
tip=max(bm.verts,key=lambda v:v.co.x)
seen={tip.index}; stack=[tip.index]; reached=False
while stack:
    vi=stack.pop(); v=bm.verts[vi]
    if v.co.x<0.20 and v.co.z>1.30: reached=True; break
    for e in v.link_edges:
        o=e.other_vert(v)
        if o.index in seen: continue
        if o.co.x<0.05: continue
        seen.add(o.index); stack.append(o.index)
print("tip->shoulder connected?", reached, "size", len(seen))
bm.free()

# AUTO + flood paint arms + torso scrub
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")

# Paint every volume-raised vert (flood misses shoulder-adjacent arm mass)
# Re-collect by position after weld (indices may shift): outer T-pose limb
arm_l = {i for i,v in enumerate(mesh.data.vertices)
         if v.co.x > 0.16 and v.co.z > hips_z + 0.05 and v.co.y > -0.14}
arm_r = {i for i,v in enumerate(mesh.data.vertices)
         if v.co.x < -0.16 and v.co.z > hips_z + 0.05 and v.co.y > -0.14}
print("paint sets", len(arm_l), len(arm_r))

def paint_chain(indices, segs):
    names=[s[0] for s in segs]
    for n in names:
        if mesh.vertex_groups.find(n)<0: mesh.vertex_groups.new(name=n)
    sh,wr=segs[1][1],segs[3][1]; axis=wr-sh
    for vi in indices:
        for vg in mesh.vertex_groups:
            try: vg.remove([vi])
            except: pass
        p=mesh.data.vertices[vi].co
        t=0.0 if axis.length_squared<1e-12 else max(0.0,min(1.0,(p-sh).dot(axis)/axis.length_squared))
        d_sh=(p-sh).length
        raw={
            names[0]: max(0.0,1.0-t/0.22)*max(0.0,1.0-d_sh/0.18),
            names[1]: max(0.0,1.0-abs(t-0.22)/0.40),
            names[2]: max(0.0,1.0-abs(t-0.62)/0.38),
            names[3]: max(0.0,(t-0.72)/0.28),
        }
        for n,a,b in segs:
            d,_=dist_seg(p,a,b)
            raw[n]=raw.get(n,0.0)+max(0.0,1.0-d/0.11)**2.5
        if d_sh<0.14 and t<0.2:
            for cn in ("Chest","Torso"):
                if mesh.vertex_groups.find(cn)>=0:
                    raw[cn]=0.35*(1.0-d_sh/0.14)
        items=sorted([(n,w) for n,w in raw.items() if w>1e-5], key=lambda kv:-kv[1])[:4]
        total=sum(w for _,w in items) or 1.0
        for n,w in items:
            if mesh.vertex_groups.find(n)<0: mesh.vertex_groups.new(name=n)
            mesh.vertex_groups[n].add([vi], w/total, "REPLACE")

paint_chain(arm_l, chain_l); paint_chain(arm_r, chain_r)

# Torso scrub: strip arm weights from core (narrow — don't eat shoulders)
ARM_KEYS=("UpperArm","LowerArm","Wrist","Shoulder","Thumb","Index","Middle","Ring","Pinky")
fixed=0
for vi,v in enumerate(mesh.data.vertices):
    co=v.co
    if abs(co.x)<0.14 and hips_z-0.1<co.z<1.25:
        arm_names=[mesh.vertex_groups[g.group].name for g in v.groups if any(k in mesh.vertex_groups[g.group].name for k in ARM_KEYS)]
        if not arm_names: continue
        aw=sum(g.weight for g in v.groups if mesh.vertex_groups[g.group].name in arm_names)
        for n in arm_names: mesh.vertex_groups[n].remove([vi])
        tgt="Torso" if mesh.vertex_groups.find("Torso")>=0 else "Chest"
        if mesh.vertex_groups.find(tgt)<0: mesh.vertex_groups.new(name=tgt)
        mesh.vertex_groups[tgt].add([vi], max(aw,0.5), "ADD"); fixed+=1
print("torso scrub", fixed)

bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True)
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.vertex_group_normalize_all(lock_active=False)

for o in list(bpy.context.scene.objects):
    if o.type not in ("ARMATURE","MESH"): bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True); mesh.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True,
    export_animations=True, export_skins=True, export_morph=False, export_apply=False)
print("EXPORTED", os.path.getsize(OUT)); print("WELD_BIND_OK")
