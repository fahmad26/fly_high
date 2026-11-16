"""Fly High Sunset ruins kit v1: broken temple arch + sakura tree (16 Nov 2026).

Run inside Blender through the Blender MCP (safe mode: bpy/bmesh/mathutils/math/random only).
Authored in Roblox studs (X right, Y up, Z back); R() converts to Blender axes for the glTF exporter.
One GLB with four meshes, uploaded as asset 71021817391731 and installed in
ReplicatedStorage.FlyHigh.EnvironmentAssets as two models:
  RuinArch   -> ArchStone (Limestone 228,214,192); Root part at the plinth base
  SakuraTree -> Bark (Wood 98,64,60), Bloom (Fabric 250,146,178), BloomLight (Fabric 255,196,214);
                Bloom/BloomLight were enlarged x1.3/x1.6/x1.3 and lifted 1.2 studs after import.
BiomeScenery uses RuinArch on temple islands (buildSculptedIslandTerrain, keepTempleRuins) and
SakuraTree in buildBlossomTree. Import yaw: see tools/build_creatures.py (parts were installed with the
180-degree flip relative to the Bark / ArchStone).
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix, noise

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_SunsetRuins_v1.glb"
SCENE = "FlyHigh_Ruins"


def R(v):
    return Vector((v.x, -v.z, v.y))


def block(bm, center, size, yaw=0.0, roll=0.0, pitch=0.0, bev=0.25, jag=0.0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    vs = res["verts"]
    m = (Matrix.Translation(R(center)) @ Matrix.Rotation(yaw, 4, 'Z') @ Matrix.Rotation(-roll, 4, 'Y')
         @ Matrix.Rotation(pitch, 4, 'X') @ Matrix.Diagonal((size.x, size.z, size.y, 1.0)))
    bmesh.ops.transform(bm, matrix=m, verts=vs)
    if jag > 0:
        c = R(center).z
        for v in vs:
            if v.co.z > c:
                v.co.z += random.uniform(-jag, jag * 0.3)
    edges = list({e for v in vs for e in v.link_edges})
    if bev > 0:
        bmesh.ops.bevel(bm, geom=edges + vs, offset=bev, segments=2, affect='EDGES', profile=0.5)


def build_arch(sc):
    random.seed(5)
    bm = bmesh.new()
    for (w, d, h, y) in ((58, 26, 2.2, 1.1), (52, 22, 2.0, 3.2), (46, 18, 1.8, 5.1)):
        block(bm, Vector((0, y, 0)), Vector((w, h, d)), bev=0.35)
    for side in (-1, 1):
        x = side * 18.0
        block(bm, Vector((x, 7.2, 0)), Vector((8.4, 2.4, 8.4)), bev=0.3)
        top = 33.0 if side < 0 else 23.0
        h = top - 8.4
        block(bm, Vector((x, 8.4 + h / 2, 0)), Vector((6.2, h, 6.2)), bev=0.45, jag=(0 if side < 0 else 2.2))
        if side < 0:
            block(bm, Vector((x, top + 1.0, 0)), Vector((8.2, 2.0, 8.2)), bev=0.3)
    n = 13
    r = 18.0
    for k in range(n):
        a = math.pi - (k + 0.5) * (math.pi / n)
        if a < math.radians(58):
            break
        pos = Vector((math.cos(a) * r, 34.0 + math.sin(a) * r, 0))
        jit = random.uniform(-0.04, 0.04)
        drop = 0.0 if a > math.radians(75) else random.uniform(0.2, 0.6)
        block(bm, pos - Vector((0, drop, 0)), Vector((4.5, 5.0, 6.4)), roll=(a - math.pi / 2) + jit, bev=0.3)
    for i, (x, z, yaw, roll) in enumerate(((9, 6, 0.5, 0.25), (13.5, -4.5, 1.2, -0.3), (22, 7.5, 2.0, 0.5), (-6, 8.5, 0.9, 0.1))):
        block(bm, Vector((x, 7.8, z)), Vector((4.5, 5.0, 6.2)), yaw=yaw, roll=roll, pitch=0.2 * i, bev=0.35)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("RuinArchStone")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("RuinArchStone", me)
    sc.collection.objects.link(ob)
    for o in sc.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=12.0)
    bpy.ops.object.mode_set(mode='OBJECT')
    return ob


def tube(bm, pts, radii, seg=10):
    rings = []
    for i in range(len(pts)):
        p = pts[i]
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        ref = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
        s1 = d.cross(ref).normalized()
        s2 = d.cross(s1).normalized()
        rings.append([bm.verts.new(p + s1 * math.cos(2 * math.pi * k / seg) * radii[i]
                                   + s2 * math.sin(2 * math.pi * k / seg) * radii[i]) for k in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    c = bm.verts.new(pts[-1] + (pts[-1] - pts[-2]).normalized() * radii[-1] * 0.5)
    for k in range(seg):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % seg], c))


def bez(a, b, c, t):
    return a * ((1 - t) ** 2) + b * (2 * (1 - t) * t) + c * (t * t)


def blobs(sc, name, centers):
    bm = bmesh.new()
    for (c, r) in centers:
        res = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        for v in res["verts"]:
            d = v.co.normalized()
            k = 1.0 + 0.22 * noise.noise(d * 2.3 + c * 0.1) + 0.08 * noise.noise(d * 6.0 + c)
            v.co = R(c) + Vector((d.x * r * 1.15 * k, d.y * r * 1.15 * k, d.z * r * 0.72 * k))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    return ob


def build_sakura(sc):
    random.seed(21)
    bm = bmesh.new()
    trunk = [R(Vector((math.sin(y * 0.25) * 0.8, y, math.cos(y * 0.2) * 0.5))) for y in (0, 3, 6, 9, 12)]
    tube(bm, trunk, [1.9, 1.5, 1.25, 1.1, 0.95], seg=12)
    tips = []
    for i in range(6):
        ang = i * math.pi * 2 / 6 + random.uniform(-0.3, 0.3)
        base = Vector((0, 9 + random.uniform(-1.5, 2), 0))
        mid = base + Vector((math.cos(ang) * 5, 4 + random.uniform(0, 2), math.sin(ang) * 5))
        tip = base + Vector((math.cos(ang) * 11, 6 + random.uniform(-1, 3), math.sin(ang) * 11))
        tube(bm, [R(bez(base, mid, tip, t / 5)) for t in range(6)], [0.85, 0.7, 0.55, 0.42, 0.3, 0.2], seg=8)
        tips.append(tip)
        tw = bez(base, mid, tip, 0.6)
        tw2 = tw + Vector((math.cos(ang + 1.2) * 3.5, 2.5, math.sin(ang + 1.2) * 3.5))
        tube(bm, [R(tw), R((tw + tw2) / 2 + Vector((0, 0.6, 0))), R(tw2)], [0.3, 0.22, 0.12], seg=6)
        tips.append(tw2)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("SakuraBark")
    bm.to_mesh(me)
    bm.free()
    bark = bpy.data.objects.new("SakuraBark", me)
    sc.collection.objects.link(bark)
    main, light = [], []
    for t in tips:
        for j in range(4):
            main.append((t + Vector((random.uniform(-3, 3), random.uniform(-1, 2), random.uniform(-3, 3))), random.uniform(2.6, 3.8)))
        light.append((t + Vector((random.uniform(-2, 2), random.uniform(1.5, 3), random.uniform(-2, 2))), random.uniform(2.0, 2.8)))
    main.append((Vector((0, 17, 0)), 5.5))
    light.append((Vector((0, 19.5, 0)), 3.6))
    return [bark, blobs(sc, "SakuraBloom", main), blobs(sc, "SakuraBloomLight", light)]


def build_all():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    objs = [build_arch(sc)] + build_sakura(sc)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True, export_texcoords=True,
                              export_normals=True)
    return [o.name for o in objs]


print(build_all())
