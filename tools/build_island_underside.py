"""Fly High - stratified floating-island underside (review fixes, 16 Nov 2026).

Run inside Blender (MCP safe mode compatible: bpy/bmesh/mathutils only). Builds object "IslandUnderside"
(~140 x 110 x 102 studs, top at z~0) and exports
assets/models/scenery/storm/generated/FlyHigh_IslandUnderside_v1.glb (uploaded as asset 119786612713966).
Roblox: template ReplicatedStorage.FlyHigh.EnvironmentAssets.IslandKit.IslandUnderside, used by
BiomeScenery.buildSculptedIslandTerrain to replace the old inverted-cone "Basalt" mesh.
"""
import bpy, bmesh, math
from mathutils import Vector, noise

N = 96
W, D = 68.0, 52.0
K = 5
H = 78.0
R = 34


def n2(a, b, c):
    return noise.noise(Vector((a, b, c)))


def profile(th, t):
    # Tilted strata: each band shrinks with depth, undercuts toward its bottom, deeper on the keel side.
    tilt = 0.06 * math.cos(th - 0.9) + 0.03 * n2(math.cos(th) * 2, math.sin(th) * 2, 3)
    tt = min(max(t + tilt, 0), 1)
    k = min(int(tt * K), K - 1)
    f = tt * K - k
    keel = 0.18 * math.cos(th + 2.2)
    base = 1.0 - 0.78 * (k / K) ** 1.15 + keel * (k / K)
    step = 0.9 + 0.12 * n2(math.cos(th) * 1.3, math.sin(th) * 1.3, k * 2.7)
    s = base * min(1, step + 0.1)
    s *= 1.03 - 0.10 * f ** 2.2
    col = 0.05 * n2(math.cos(th) * 9, math.sin(th) * 9, k * 0.3)
    return max(s + col, 0.05)


def spire(bm, cx, cy, ztop, r, L, lean):
    M = 9
    rings = []
    for fr, sc in [(0, 1), (0.35, 0.7), (0.7, 0.38)]:
        rings.append([bm.verts.new((cx + math.cos(2 * math.pi * i / M) * r * sc * (1 + 0.15 * math.sin(i * 2.3)) + lean * fr * L,
                                    cy + math.sin(2 * math.pi * i / M) * r * sc, ztop - fr * L)) for i in range(M)])
    t = bm.verts.new((cx + lean * L, cy, ztop - L))
    for a, b in zip(rings, rings[1:]):
        for i in range(M):
            j = (i + 1) % M
            bm.faces.new((a[i], a[j], b[j], b[i]))
    for i in range(M):
        bm.faces.new((rings[-1][i], rings[-1][(i + 1) % M], t))


def build():
    bm = bmesh.new()
    grid = []
    for r in range(R + 1):
        t = r / R
        row = []
        for i in range(N):
            th = 2 * math.pi * i / N
            s = profile(th, t)
            o = 1 + 0.09 * n2(math.cos(th) * 1.6, math.sin(th) * 1.6, 0.4) + 0.04 * n2(math.cos(th) * 4, math.sin(th) * 4, 1.1)
            z = -t * H * (0.85 + 0.15 * math.cos(th + 2.2))
            dx = 6 * math.sin(t * 3.0) * t
            dy = -4 * t
            row.append(bm.verts.new((math.cos(th) * W * s * o + dx, math.sin(th) * D * s * o + dy, z)))
        grid.append(row)
    for a, b in zip(grid, grid[1:]):
        for i in range(N):
            j = (i + 1) % N
            bm.faces.new((a[i], a[j], b[j], b[i]))
    cap = bm.verts.new((0, 0, 0.8))
    for i in range(N):
        bm.faces.new((grid[0][(i + 1) % N], grid[0][i], cap))
    for v in bm.verts:
        p = v.co
        if p.z < -1:
            h = Vector((p.x, p.y, 0))
            if h.length > 0.1:
                v.co += h.normalized() * (noise.noise(p * 0.06) * 2.6 + noise.noise(p * 0.17 + Vector((5, 1, 2))) * 0.9)
    for ang, t, L, r, lean in [(0.5, 0.55, 26, 7, 0.1), (2.4, 0.7, 18, 5.5, -0.15), (4.1, 0.45, 15, 5, 0.05), (5.4, 0.8, 12, 4, 0.12)]:
        s = profile(ang, t) * 0.8
        spire(bm, math.cos(ang) * W * s, math.sin(ang) * D * s - 4 * t, -t * H * 0.9 + 2, r, L, lean)
    # Root: taper the last ring into an irregular hanging keel instead of a flat fan.
    ring = grid[-1]
    cen = Vector()
    for v in ring:
        cen += v.co
    cen /= len(ring)

    def ang_of(v):
        return math.atan2(v.co.y - cen.y, v.co.x - cen.x)

    ring = sorted(ring, key=ang_of)
    rows = [ring]
    drops = [6, 7, 7, 6]
    for k, sc in enumerate([0.82, 0.62, 0.42, 0.24]):
        nr = []
        for i, v in enumerate(rows[0]):
            th = ang_of(v)
            jag = 1 + 0.25 * noise.noise(Vector((math.cos(th) * 3, math.sin(th) * 3, k * 1.7)))
            d = v.co - cen
            d.z = 0
            p = cen + d * sc * jag + Vector((3 * k, -1.5 * k, -sum(drops[:k + 1]) + 3 * noise.noise(Vector((math.cos(th) * 2, math.sin(th) * 2, k)))))
            p.z = min(p.z, rows[-1][i].co.z - 1.5)
            nr.append(bm.verts.new(p))
        rows.append(nr)
    n = len(ring)
    for a, b in zip(rows, rows[1:]):
        for i in range(n):
            j = (i + 1) % n
            try:
                bm.faces.new((a[i], a[j], b[j], b[i]))
            except ValueError:
                pass
    low = Vector()
    for v in rows[-1]:
        low += v.co
    low /= n
    tip = bm.verts.new(low + Vector((2, -1, -9)))
    for i in range(n):
        try:
            bm.faces.new((rows[-1][i], rows[-1][(i + 1) % n], tip))
        except ValueError:
            pass
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("IslandUnderside")
    bm.to_mesh(me)
    bm.free()
    old = bpy.data.objects.get("IslandUnderside")
    if old:
        bpy.data.objects.remove(old)
    ob = bpy.data.objects.new("IslandUnderside", me)
    bpy.context.scene.collection.objects.link(ob)
    for p in me.polygons:
        p.use_smooth = not (p.center.z > 0.0)
    return ob


def export(ob, path):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    # use_active_scene: without it the exporter also writes other scenes' selections.
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True)


ob = build()
export(ob, r"E:\Antigravity\Fly High\assets\models\scenery\storm\generated\FlyHigh_IslandUnderside_v1.glb")
print(len(ob.data.polygons), [round(x, 1) for x in ob.dimensions])
