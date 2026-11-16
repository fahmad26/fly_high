"""Fly High Hailstone v5 (16 Nov 2026): three lumpy hailstone variants with ice-crystal growths.

Run inside Blender through the Blender MCP (safe mode). Authored in Roblox studs; R() converts axes.
Per variant i (1..3, exported 12 studs apart along X): Hail<i>_Body (lumpy shell with growth rings),
Hail<i>_Core (inner frost core, ~0.6x body), Hail<i>_Crystals (6-sided ice crystals along the normals).
Uploaded as asset 95048105166805 and installed as Templates.ObstacleMeshes.Hailstone/Hailstone2/Hailstone3:
  Body     Glass 186,226,246, Transparency 0.35   (part name "Body")
  FrostCore Ice  236,246,255                       (inner core visible through the shell)
  Crystals Glass 214,244,255, Transparency 0.12
Parts placed at their authored centres with a 180-degree yaw flip (see build_creatures.py). Old templates are in
ServerStorage.ObstacleMeshes_Legacy.
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector, noise

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_Hailstone_v5.glb"
SCENE = "FlyHigh_Hail"


def R(v):
    return Vector((v.x, -v.z, v.y))


def finish(sc, name, bm, smooth):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    for o in sc.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.sphere_project()
    bpy.ops.object.mode_set(mode='OBJECT')
    return ob


def build_variant(sc, vi, seed):
    random.seed(seed)
    off = Vector((vi * 12.0, 0, 0))
    sq = Vector((1.0, 1.35, 0.98))
    lumps = [(Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))).normalized(),
              random.uniform(0.35, 0.6), random.uniform(0.12, 0.22)) for i in range(7)]

    def rad(d):
        r = 1.0 + 0.07 * noise.noise(d * 3.0 + Vector((seed, 0, 0))) + 0.03 * noise.noise(d * 8.0)
        r += 0.025 * math.sin(d.y * 14.0 + noise.noise(d * 2.0) * 3.0)
        for c, w, h in lumps:
            a = d.angle(c)
            if a < w:
                r += h * (0.5 + 0.5 * math.cos(math.pi * a / w))
        return r * 1.55

    for name, k in (("Body", 1.0), ("Core", 0.6)):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
        for v in bm.verts:
            d = v.co.normalized()
            p = d * rad(d)
            p = Vector((p.x * sq.x, p.y * sq.y, p.z * sq.z))
            if k != 1.0:
                p = p * (k + 0.06 * noise.noise(p * 1.7 + Vector((vi * 5, 1, 2))))
            v.co = R(p + off)
        finish(sc, "Hail%d_%s" % (vi + 1, name), bm, True)

    bm = bmesh.new()
    for i in range(random.randint(7, 10)):
        d = Vector((random.uniform(-1, 1), random.uniform(-0.8, 1), random.uniform(-1, 1))).normalized()
        base = d * rad(d) * 0.9
        base = Vector((base.x * sq.x, base.y * sq.y, base.z * sq.z))
        nrm = Vector((d.x / sq.x, d.y / sq.y, d.z / sq.z)).normalized()
        nrm = (nrm + Vector((random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3)))).normalized()
        L = random.uniform(0.6, 1.25)
        w = random.uniform(0.16, 0.3)
        ref = Vector((0, 1, 0)) if abs(nrm.y) < 0.9 else Vector((1, 0, 0))
        s1 = nrm.cross(ref).normalized()
        s2 = nrm.cross(s1).normalized()
        ring0, ring1 = [], []
        for j in range(6):
            a = 2 * math.pi * j / 6
            q = s1 * math.cos(a) * w + s2 * math.sin(a) * w
            ring0.append(bm.verts.new(R(base - nrm * 0.2 + q + off)))
            ring1.append(bm.verts.new(R(base + nrm * L * 0.72 + q * 0.92 + off)))
        tip = bm.verts.new(R(base + nrm * L + off))
        for j in range(6):
            bm.faces.new((ring0[j], ring0[(j + 1) % 6], ring1[(j + 1) % 6], ring1[j]))
            bm.faces.new((ring1[j], ring1[(j + 1) % 6], tip))
        bm.faces.new(ring0[::-1])
    finish(sc, "Hail%d_Crystals" % (vi + 1), bm, False)


def build_all():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    for vi, seed in enumerate((3, 17, 41)):
        build_variant(sc, vi, seed)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in sc.objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = sc.objects[0]
    bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True, export_texcoords=True,
                              export_normals=True)
    return [o.name for o in sc.objects]


print(build_all())
