"""Fly High Sunset kit 2 (16 Nov 2026): torii-style chime gate + broken bridge half span.

Run inside Blender through the Blender MCP (safe mode). Authored in Roblox studs (X right, Y up, Z back);
R() converts to Blender axes. Uploaded as asset 112587462648702 and installed in
ReplicatedStorage.FlyHigh.EnvironmentAssets as:
  ChimeGate  -> GateTimber (Wood 170,62,48), GateStone (Sandstone 196,150,118), GateGold (Metal 244,192,86)
                pillars at local X=0 and X=18 like the old WindChimeRuin; chimes hang from Y=26 (scaled).
  BridgeHalf -> BridgeStone (Limestone 226,200,172), BridgeMasonry (Sandstone 176,132,108)
                anchor at the origin, span runs 40 studs toward -Z (CFrame.lookAt "inward"); BiomeScenery
                stretches it along Z to each span length.
Install note: the Roblox glTF import turns meshes 180 degrees about Y, so each part was placed at its
authored centre with CFrame.new(centre) * CFrame.Angles(0, math.pi, 0). Centres (Roblox axes):
  GateTimber (9, 16.45, 0)  GateStone (9, 1.95, 0)  GateGold (9, 25.83, 0)
  BridgeStone (0, 0.99, -20.38)  BridgeMasonry (0, -15.57, -19.15)
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_SunsetKit2_v1.glb"
SCENE = "FlyHigh_SunsetKit2"


def R(v):
    return Vector((v.x, -v.z, v.y))


def block(bm, center, size, yaw=0.0, roll=0.0, pitch=0.0, bev=0.2):
    res = bmesh.ops.create_cube(bm, size=1.0)
    vs = res["verts"]
    m = (Matrix.Translation(R(center)) @ Matrix.Rotation(yaw, 4, 'Z') @ Matrix.Rotation(-roll, 4, 'Y')
         @ Matrix.Rotation(pitch, 4, 'X') @ Matrix.Diagonal((size.x, size.z, size.y, 1.0)))
    bmesh.ops.transform(bm, matrix=m, verts=vs)
    if bev > 0:
        edges = list({e for v in vs for e in v.link_edges})
        bmesh.ops.bevel(bm, geom=edges + vs, offset=bev, segments=2, affect='EDGES', profile=0.5)


def loft_rect(bm, pts, w, h, up=Vector((0, 1, 0))):
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        side = d.cross(up).normalized()
        u = side.cross(d).normalized()
        corners = [p + side * w / 2 + u * h / 2, p - side * w / 2 + u * h / 2, p - side * w / 2 - u * h / 2, p + side * w / 2 - u * h / 2]
        rings.append([bm.verts.new(R(c)) for c in corners])
    for a, b in zip(rings, rings[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])


def cyl(bm, base, height, r0, r1, seg=16):
    res = bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=height)
    bmesh.ops.translate(bm, vec=R(base + Vector((0, height / 2, 0))), verts=res["verts"])


def finish(sc, name, bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    for o in sc.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=8.0)
    bpy.ops.object.mode_set(mode='OBJECT')
    return ob


def build_gate(sc):
    bm = bmesh.new()
    for x in (0.0, 18.0):
        cyl(bm, Vector((x, 3.6, 0)), 21.4, 1.55, 1.35, seg=20)
        cyl(bm, Vector((x, 24.6, 0)), 0.5, 1.7, 1.7, seg=20)
    loft_rect(bm, [Vector((x, 20.6, 0)) for x in (-3.5, 9, 21.5)], 1.3, 1.6)
    loft_rect(bm, [Vector((-4.5, 25.6, 0)), Vector((22.5, 25.6, 0))], 2.2, 1.2)
    k = []
    for i in range(25):
        x = -8.0 + i / 24 * 34.0
        k.append(Vector((x, 27.2 + 0.0045 * ((x - 9.0) ** 2), 0)))
    loft_rect(bm, k, 3.0, 1.6)
    block(bm, Vector((9, 23.4, 0)), Vector((1.6, 4.2, 1.2)), bev=0.1)
    finish(sc, "GateTimber", bm)
    bm = bmesh.new()
    for x in (0.0, 18.0):
        block(bm, Vector((x, 1.6, 0)), Vector((5.6, 3.2, 5.6)), bev=0.35)
        block(bm, Vector((x, 3.5, 0)), Vector((4.2, 0.8, 4.2)), bev=0.2)
    finish(sc, "GateStone", bm)
    bm = bmesh.new()
    for x in (-8.0, 26.0):
        block(bm, Vector((x, 27.2 + 0.0045 * ((x - 9.0) ** 2), 0)), Vector((0.6, 1.9, 3.3)), bev=0.12)
    block(bm, Vector((9, 23.4, 0.62)), Vector((1.0, 2.4, 0.1)), bev=0.0)
    finish(sc, "GateGold", bm)


def build_bridge(sc):
    random.seed(9)
    L = 40.0
    bm = bmesh.new()
    n = 10
    for i in range(n):
        z = -(i + 0.5) * L / n
        drop, tilt, yaw = 0.0, 0.0, 0.0
        if i == n - 1:
            drop, tilt, yaw = -1.2, -0.18, 0.08
        if i == n - 2:
            drop, tilt = -0.25, -0.05
        block(bm, Vector((random.uniform(-0.08, 0.08), drop, z)), Vector((13.5, 3.6, L / n - 0.12)), yaw=yaw, pitch=tilt, bev=0.25)
    for side in (-1, 1):
        block(bm, Vector((side * 7.0, 1.6, -L * 0.46)), Vector((1.0, 0.9, L * 0.9)), bev=0.15)
        cut = 7 if side < 0 else 9
        for k in range(cut):
            block(bm, Vector((side * 5.9, 3.2, -1.5 - k * 3.6)), Vector((1.4, 2.8, 1.4)), bev=0.18)
        rail = (cut - 1) * 3.6 + 1.6
        block(bm, Vector((side * 5.9, 4.9, -1.5 - rail / 2 + 0.8)), Vector((1.9, 0.7, rail)), bev=0.15)
        for k in range(cut - 1):
            for j in range(3):
                block(bm, Vector((side * 5.9, 3.0, -1.5 - k * 3.6 - 0.9 * (j + 1))), Vector((0.6, 2.4, 0.6)), bev=0.08)
    finish(sc, "BridgeStone", bm)

    bm = bmesh.new()
    segs = 16
    pts = [Vector((0, -15.0 + 12.4 * math.sin(s / segs * math.pi / 2), -4.0 - 34.0 * s / segs)) for s in range(segs + 1)]
    th, hw = 2.8, 6.4
    for s in range(segs):
        a, b = pts[s], pts[s + 1]
        d = (b - a).normalized()
        na = Vector((0, -d.z, d.y)).normalized()
        if na.y > 0:
            na = -na
        a2 = a + d * 0.12
        b2 = b - d * 0.12
        corners = []
        for p in (a2, b2):
            for (x, o) in ((-hw, 0), (hw, 0), (hw, th), (-hw, th)):
                corners.append(p + Vector((x, 0, 0)) + na * o)
        v = [bm.verts.new(R(c)) for c in corners]
        for f in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
            bm.faces.new([v[i] for i in f])
    hw2 = 5.8
    vt, vb = [], []
    for side in (-hw2, hw2):
        vt.append([bm.verts.new(R(Vector((side, -1.9, p.z)))) for p in pts])
        vb.append([bm.verts.new(R(Vector((side, p.y + 0.2, p.z)))) for p in pts])
    for i in range(segs):
        bm.faces.new((vb[0][i], vb[0][i + 1], vt[0][i + 1], vt[0][i]))
        bm.faces.new((vt[1][i], vt[1][i + 1], vb[1][i + 1], vb[1][i]))
        bm.faces.new((vb[1][i], vb[1][i + 1], vb[0][i + 1], vb[0][i]))
    bm.faces.new((vt[0][0], vt[1][0], vb[1][0], vb[0][0]))
    block(bm, Vector((0, -21.0, -4.0)), Vector((8.4, 12.0, 6.4)), bev=0.3)
    block(bm, Vector((0, -15.4, -4.0)), Vector((9.6, 1.6, 7.4)), bev=0.25)
    block(bm, Vector((0, -28.0, -4.0)), Vector((6.0, 2.5, 4.8)), bev=0.3)
    finish(sc, "BridgeMasonry", bm)


def build_all():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    build_gate(sc)
    build_bridge(sc)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in sc.objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = sc.objects["GateTimber"]
    bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True, export_texcoords=True,
                              export_normals=True)
    return [o.name for o in sc.objects]


print(build_all())
