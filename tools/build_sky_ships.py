"""Fly High sky ships v2 (16 Nov 2026): CloudSailer, CloudKetch, CloudCutter.

Run inside Blender through the Blender MCP (safe mode). Authored in Roblox studs: bow +X, up +Y, beam along Z;
R() converts to Blender axes. Each ship keeps the part names BiomeScenery relies on:
  SkyHull       planked hull, keel, bowsprit, masts, yards/booms, shrouds and forestay (WoodPlanks)
  SkyHullLight  deck, gunwale rails, stern cabin (WoodPlanks; figurehead mount uses its Size.X)
  SkySail       main sails (Fabric)      SkySailShade  jib and secondary sails (Fabric)
  SkyBrass      rail lanterns, mast bands, stern rail (Metal)
  SkyPennant    masthead flag (Sailer only, Fabric)
Uploaded as asset 90982189004528; installed in EnvironmentAssets.BiomeLandmarkMeshes (old models backed up in
ServerStorage.BiomeLandmarkMeshes_Legacy), WorldPivot at the origin like v1, colours copied from v1 parts.
The Ketch was exported 80 studs and the Cutter 160 studs along +Z; the installer subtracts that offset.
Install note: parts placed at their authored centres with CFrame.new(centre) * CFrame.Angles(0, math.pi, 0)
(the Roblox glTF import turns meshes 180 degrees about Y).
"""
import bpy
import bmesh
import math
from mathutils import Vector

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_SkyShips_v2.glb"
SCENE = "FlyHigh_Ships"


def R(v):
    return Vector((v.x, -v.z, v.y))


def tube(bm, pts, radii, seg=8, caps=True):
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        ref = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        s1 = d.cross(ref).normalized()
        s2 = d.cross(s1).normalized()
        rings.append([bm.verts.new(R(p + s1 * math.cos(2 * math.pi * k / seg) * radii[i]
                                     + s2 * math.sin(2 * math.pi * k / seg) * radii[i])) for k in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    if caps:
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])


def grid(bm, P, nu, nv):
    for flip in (False, True):
        vs = [[bm.verts.new(R(P(i / nu, j / nv))) for j in range(nv + 1)] for i in range(nu + 1)]
        for i in range(nu):
            for j in range(nv):
                if flip:
                    bm.faces.new((vs[i][j], vs[i][j + 1], vs[i + 1][j + 1], vs[i + 1][j]))
                else:
                    bm.faces.new((vs[i][j], vs[i + 1][j], vs[i + 1][j + 1], vs[i][j + 1]))


def finish(sc, name, bm, smooth=True):
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
    bpy.ops.uv.cube_project(cube_size=10.0)
    bpy.ops.object.mode_set(mode='OBJECT')
    return ob


def build_ship(sc, pre, L, B, D, masts, sails, jib, pennant, offset):
    def X(s):
        return s * L / 2

    def half(s):
        if s >= 0:
            return B * max(0.0, 1 - (s ** 2.2)) ** 0.55
        return B * (0.62 + 0.38 * max(0.0, 1 - ((-s) ** 2.5)) ** 0.5)

    def sheer(s):
        return 2.0 + 5.0 * (s ** 2) * (1.3 if s > 0 else 0.8)

    def keel(s):
        return -D * (1 - abs(s) ** 3.0) * (0.85 if s < 0 else 1.0) - 1.0

    def O(v):
        return v + offset

    ns, nphi = 28, 12
    bm = bmesh.new()
    rings = []
    for i in range(ns + 1):
        s = -1 + 2 * i / ns
        b, top, bot = half(s), sheer(s), keel(s)
        rings.append([bm.verts.new(R(O(Vector((X(s), top - (top - bot) * math.sin(math.pi * k / nphi) ** 0.8,
                                                 b * math.cos(math.pi * k / nphi)))))) for k in range(nphi + 1)])
    for a, c in zip(rings, rings[1:]):
        for k in range(nphi):
            bm.faces.new((a[k], c[k], c[k + 1], a[k + 1]))
    bm.faces.new(rings[0][::-1])
    tube(bm, [O(Vector((X(s), keel(s) - 0.6, 0))) for s in (-0.85, -0.4, 0.0, 0.4, 0.85)], [0.8, 1.0, 1.0, 0.9, 0.5], seg=6)
    tube(bm, [O(Vector((X(0.92), sheer(0.92), 0))), O(Vector((X(1.25), sheer(0.92) + 6, 0)))], [0.9, 0.4], seg=8)
    for (ms, h) in masts:
        tube(bm, [O(Vector((X(ms), 0, 0))), O(Vector((X(ms), h, 0)))], [1.2, 0.55], seg=10)
        for sgn in (-1, 1):
            for dx in (-6, 0, 6):
                s2 = max(-0.95, min(0.9, ms + dx / (L / 2)))
                tube(bm, [O(Vector((X(s2), sheer(s2) + 0.6, sgn * half(s2)))), O(Vector((X(ms), h * 0.86, 0)))], [0.16, 0.16], seg=4, caps=False)
    tall = masts[0]
    tube(bm, [O(Vector((X(1.25), sheer(0.92) + 6, 0))), O(Vector((X(tall[0]), tall[1] * 0.95, 0)))], [0.18, 0.18], seg=4, caps=False)
    for sp in sails:
        if sp[0] == "square":
            ms, y0, y1, w = sp[1], sp[2], sp[3], sp[4]
            for (yy, ww) in ((y1, w * 0.82), (y0, w)):
                tube(bm, [O(Vector((X(ms) + 0.8, yy, -ww / 2))), O(Vector((X(ms) + 0.8, yy, ww / 2)))], [0.45, 0.45], seg=6)
        else:
            ms, y0, y1, boom = sp[1], sp[2], sp[3], sp[4]
            tube(bm, [O(Vector((X(ms), y0, 0))), O(Vector((X(ms) - boom, y0 + 1.5, 0)))], [0.5, 0.4], seg=6)
    objs = [finish(sc, pre + "SkyHull", bm)]

    bm = bmesh.new()
    for i in range(ns):
        s0 = -1 + 2 * i / ns
        s1 = s0 + 2 / ns
        y0, y1 = sheer(s0) - 1.0, sheer(s1) - 1.0
        b0, b1 = half(s0) * 0.96, half(s1) * 0.96
        bm.faces.new([bm.verts.new(R(O(Vector((X(s0), y0, -b0))))), bm.verts.new(R(O(Vector((X(s1), y1, -b1))))),
                      bm.verts.new(R(O(Vector((X(s1), y1, b1))))), bm.verts.new(R(O(Vector((X(s0), y0, b0)))))])
    for sgn in (-1, 1):
        tube(bm, [O(Vector((X(s), sheer(s) + 0.6, sgn * half(s)))) for s in [-1 + 2 * i / ns for i in range(ns + 1)]],
             [0.7] * (ns + 1), seg=6, caps=False)
    tube(bm, [O(Vector((X(-0.78), sheer(-0.78) - 1, 0))), O(Vector((X(-0.78), sheer(-0.78) + 5, 0)))], [B * 0.45, B * 0.42], seg=4)
    objs.append(finish(sc, pre + "SkyHullLight", bm, smooth=False))

    bm, bm2 = bmesh.new(), bmesh.new()
    for idx, sp in enumerate(sails):
        target = bm if idx % 2 == 0 else bm2
        if sp[0] == "square":
            ms, y0, y1, w = sp[1], sp[2], sp[3], sp[4]

            def P(u, v, ms=ms, y0=y0, y1=y1, w=w):
                bulge = 7.0 * math.sin(math.pi * u) * math.sin(math.pi * (0.15 + 0.85 * v))
                return O(Vector((X(ms) + 1.6 + bulge, y0 + (y1 - y0) * v, (u - 0.5) * w * (1 - 0.18 * v))))
            grid(target, P, 8, 6)
        else:
            ms, y0, y1, boom = sp[1], sp[2], sp[3], sp[4]

            def P(u, v, ms=ms, y0=y0, y1=y1, boom=boom):
                bulge = 4.0 * math.sin(math.pi * u) * math.sin(math.pi * v)
                return O(Vector((X(ms) - 0.8 - boom * (1 - 0.75 * v) * u, y0 + (y1 - y0) * v + 1.5 * u * (1 - v), bulge)))
            grid(target, P, 7, 7)
    js, jy0, jy1 = jib

    def J(u, v):
        a = Vector((X(1.25), sheer(0.92) + 5.5, 0))
        b = Vector((X(js), jy1, 0))
        c = Vector((X(js) + 1, jy0, 0))
        return O(a.lerp(b, v).lerp(c.lerp(b, v), u) + Vector((0, 0, 3.0 * math.sin(math.pi * u) * math.sin(math.pi * v))))
    grid(bm2, J, 6, 6)
    objs.append(finish(sc, pre + "SkySail", bm))
    objs.append(finish(sc, pre + "SkySailShade", bm2))

    bm = bmesh.new()
    for s in (-0.95, 0.0, 0.6):
        for sgn in (-1, 1):
            tube(bm, [O(Vector((X(s), sheer(s) + 0.4, sgn * (half(s) + 0.2)))), O(Vector((X(s), sheer(s) + 2.6, sgn * (half(s) + 0.2))))], [0.5, 0.5], seg=8)
    for (ms, h) in masts:
        for t in (0.35, 0.7):
            tube(bm, [O(Vector((X(ms), h * t - 0.4, 0))), O(Vector((X(ms), h * t + 0.4, 0)))], [1.25 - 0.5 * t, 1.2 - 0.5 * t], seg=10)
    tube(bm, [O(Vector((X(-1.0) - 0.3, sheer(-1) - 3.5, -B * 0.4))), O(Vector((X(-1.0) - 0.3, sheer(-1) - 3.5, B * 0.4)))], [0.6, 0.6], seg=8)
    objs.append(finish(sc, pre + "SkyBrass", bm))

    if pennant:
        tall = masts[0]
        for m in masts:
            if m[1] > tall[1]:
                tall = m
        ms, h = tall

        def F(u, v, ms=ms, h=h):
            return O(Vector((X(ms) - u * 12, h - 1 - v * 4 * (1 - u * 0.7), 1.2 * math.sin(u * 6.0))))
        bm = bmesh.new()
        grid(bm, F, 8, 2)
        objs.append(finish(sc, pre + "SkyPennant", bm))
    return objs


def build_all():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    build_ship(sc, "Sailer_", 95, 13, 14, [(0.32, 58), (-0.22, 66)],
               [("square", 0.32, 22, 50, 30), ("square", -0.22, 24, 58, 34)], (0.32, 12, 52), True, Vector((0, 0, 0)))
    build_ship(sc, "Ketch_", 99, 10.5, 12, [(0.18, 64), (-0.55, 44)],
               [("gaff", 0.18, 6, 60, 30), ("gaff", -0.55, 6, 40, 18)], (0.18, 10, 58), False, Vector((0, 0, 80)))
    build_ship(sc, "Cutter_", 74, 13, 14, [(0.05, 72)], [("gaff", 0.05, 6, 68, 30)], (0.05, 10, 64), False, Vector((0, 0, 160)))
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
