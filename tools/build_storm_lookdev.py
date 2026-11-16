# Fly High - Batch 1 semi-realistic look-dev (Zone 2): cumulonimbus v4, wall cloud, tornado core + shell, textures.
# Approved art direction 15 Nov 2026: "semi-realistis" (soft textured clouds, believable light/shadow, PRD indigo/violet palette).
# Run in Blender 5.3 scene FlyHigh_StormBatch1 by pasting into execute_blender_code (MCP safe mode blocks exec/open).
# Export selected [StormCumulonimbus, StormWallCloud, StormFunnelCore, StormFunnelShell] at origin ->
#   glTF GLB, export_yup, apply, materials EXPORT, texcoords -> assets/models/scenery/storm/generated/FlyHigh_StormLookDev2.glb
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, noise
from mathutils.bvhtree import BVHTree

GEN = r"E:/Antigravity/Fly High/assets/models/scenery/storm/generated/"


def ss(a, b, x):
    t = min(max((x - a) / (b - a), 0), 1); return t * t * (3 - 2 * t)


def lobes_to_mesh(sc, name, lobes, voxel, smooth_iter, decimate_ratio, flat_z=None):
    """Union of ellipsoid lobes -> voxel remesh -> light laplacian smooth -> decimate -> flat base."""
    bm = bmesh.new()
    for (c, s) in lobes:
        m = Matrix.Translation(Vector(c)) @ Matrix.Diagonal((s[0], s[1], s[2], 1.0))
        bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=9, radius=1.0, matrix=m)
    src = bpy.data.meshes.new(name + "_src"); bm.to_mesh(src); bm.free()
    ob = bpy.data.objects.new(name + "_tmp", src); sc.collection.objects.link(ob)
    r = ob.modifiers.new("R", 'REMESH'); r.mode = 'VOXEL'; r.voxel_size = voxel
    sm = ob.modifiers.new("S", 'LAPLACIANSMOOTH'); sm.iterations = smooth_iter; sm.lambda_factor = 0.6; sm.use_volume_preserve = True
    d = ob.modifiers.new("D", 'DECIMATE'); d.ratio = decimate_ratio
    dg = bpy.context.evaluated_depsgraph_get(); dg.update()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg)); bpy.data.objects.remove(ob); bpy.data.meshes.remove(src)
    if flat_z is not None:
        for v in me.vertices:
            if v.co.z < flat_z: v.co.z = flat_z - 1.0 * noise.noise(Vector((v.co.x / 40, v.co.y / 40, 0.7)))
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free(); me.shade_smooth(); me.name = name
    return me


def add_detail(P, rnd, zmin, zmax):
    """Fractal billows: medium lobes on primaries (zmin..zmax), small lobes on mediums."""
    L = list(P); med = []
    for (c, s) in P:
        if c[2] < zmin or c[2] > zmax: continue
        for _ in range(rnd.randint(2, 3)):
            d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.2, 1.0))).normalized()
            p = Vector(c) + Vector((d.x * s[0], d.y * s[1], d.z * s[2])) * 0.82; r = min(s[0], s[1]) * rnd.uniform(0.36, 0.5)
            med.append((tuple(p), (r, r, r * 0.88)))
    L += med
    for (c, s) in med:
        for _ in range(2):
            d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(0.0, 1.0))).normalized()
            p = Vector(c) + Vector((d.x * s[0], d.y * s[1], d.z * s[2])) * 0.8; r = s[0] * rnd.uniform(0.35, 0.5)
            L.append((tuple(p), (r, r, r * 0.9)))
    return L


def cumulonimbus_lobes():
    rnd = random.Random(41); P = []
    for i in range(7):                                    # merged flat dark base
        P.append(((-80 + i * 27 + rnd.uniform(-5, 5), rnd.uniform(-10, 10), 20), (44, 42, 22)))
    for k in range(11):                                   # tower leaning downwind (+x)
        z = 38 + k * 13; w = 44 + k * 2.4; lean = k * 3.2
        for j in range(3):
            P.append(((lean + rnd.uniform(-28, 28), rnd.uniform(-24, 24), z + rnd.uniform(-4, 4)), (w * rnd.uniform(0.75, 0.95), w * 0.85, 34)))
    P += [((20, 0, 198), (95, 72, 28)), ((100, 0, 196), (115, 100, 21)), ((185, 0, 191), (90, 125, 14))]   # continuous anvil sheet
    for i in range(46):
        x = rnd.uniform(-20, 220); spread = 35 + 0.5 * max(0, x); y = rnd.uniform(-spread, spread)
        edge = max(0.0, x / 220.0); r = rnd.uniform(26, 38) * (1 - 0.3 * edge)
        P.append(((x, y, 197 - 6 * edge + rnd.uniform(-2, 2)), (r, r * 0.9, 22 * (1 - 0.5 * edge))))
    for i in range(16):                                   # overshooting-top bumps near the core
        x = rnd.uniform(-20, 100); y = rnd.uniform(-40, 40); r = rnd.uniform(20, 28)
        P.append(((x, y, 216 - 0.1 * x), (r, r, r * 0.55)))
    return add_detail(P, rnd, 30, 185)                    # ~371 lobes; voxel 2.8, decimate 0.13 -> ~10.7k tris


def wallcloud_lobes():
    rnd = random.Random(31); P = []
    P.append(((0, 0, 24), (118, 108, 28))); P.append(((40, 4, 30), (112, 88, 28)))
    for i in range(12):
        a = 2 * math.pi * i / 12 + rnd.uniform(-0.12, 0.12); rr = rnd.uniform(88, 110)
        P.append(((rr * math.cos(a), rr * math.sin(a), 15), (34, 34, 18)))
    for (x, y, z, r) in [(-30, -20, 48, 40), (22, 26, 54, 44), (62, -8, 46, 38), (-62, 22, 40, 34), (0, 0, 60, 38), (95, 15, 36, 32), (-90, -30, 30, 30)]:
        P.append(((x, y, z), (r, r, r * 0.8)))
    for i in range(8):                                    # lowered collar under the throat
        a = 2 * math.pi * i / 8; P.append(((52 * math.cos(a), 52 * math.sin(a), 2), (30, 30, 16)))
    return add_detail(P, rnd, 20, 1e9)                    # voxel 2.4, decimate to ~8k tris


def bake_lut_uv(me, reach=60.0):
    """UV = (occlusion+down-facing shade, normalized height) -> samples FH_CloudLUT (gradient map)."""
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table(); tree = BVHTree.FromBMesh(bm)
    dirs = []
    for i in range(12):
        z = 0.15 + 0.85 * (i + 0.5) / 12; r = math.sqrt(1 - z * z); a = i * 2.39996
        dirs.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    zs = [v.co.z for v in bm.verts]; z0, z1 = min(zs), max(zs); vals = []
    for v in bm.verts:
        n = v.normal; t = n.orthogonal().normalized(); b = n.cross(t); hits = 0
        for dd in dirs:
            w = (t * dd.x + b * dd.y + n * dd.z).normalized()
            if tree.ray_cast(v.co + n * 0.6, w, reach)[0] is not None: hits += 1
        occ = hits / len(dirs); vals.append((min(1.0, 0.8 * occ ** 1.1 + 0.4 * max(0.0, -n.z)), (v.co.z - z0) / (z1 - z0)))
    bm.free()
    uv = me.uv_layers.get("LUT") or me.uv_layers.new(name="LUT"); me.uv_layers.active = uv
    for loop in me.loops:
        s, h = vals[loop.vertex_index]; uv.data[loop.index].uv = (0.02 + 0.96 * s, 0.02 + 0.96 * h)


def cloud_lut_image(N=256):
    """Desaturated storm palette (sRGB); Roblox zone-2 ambient adds the indigo/violet."""
    def lerp(c1, c2, t): return tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(3))
    BASE = (40, 38, 52); LOW = (70, 67, 86); MID = (118, 114, 138); TOP = (196, 190, 210)
    px = [0.0] * (N * N * 4)
    for y in range(N):
        h = (y / (N - 1) - 0.02) / 0.96
        c = lerp(BASE, LOW, ss(0, 0.07, h)) if h < 0.07 else (lerp(LOW, MID, ss(0.07, 0.5, h)) if h < 0.5 else lerp(MID, TOP, ss(0.5, 1.0, h)))
        for x in range(N):
            s = (x / (N - 1) - 0.02) / 0.96; k = 1 - 0.66 * min(1, max(0, s)) ** 1.1; i = (y * N + x) * 4
            px[i] = c[0] * k / 255; px[i + 1] = c[1] * k / 255; px[i + 2] = c[2] * k / 255; px[i + 3] = 1.0
    img = bpy.data.images.get("FH_CloudLUT") or bpy.data.images.new("FH_CloudLUT", N, N, alpha=False)
    img.pixels.foreach_set(px); img.filepath_raw = GEN + "FH_CloudLUT.png"; img.file_format = 'PNG'; img.save()
    return img


def funnel_uv(name, H=210.0, rt=78.0, rb=6.0, rings=60, segs=40, seed=3, rscale=1.0, lip=0.16):
    """Continuous tornado funnel with cylindrical UVs (u = angle, v = height); core: segs 40/rings 60, shell: rscale 1.12, lip .22, seed 5, segs 36/rings 48."""
    bm = bmesh.new(); uvl = bm.loops.layers.uv.new("UVMap"); rows = []; cen = []
    for i in range(rings + 1):
        t = i / rings
        r = (rb + (rt - rb) * t ** 1.8) * (1 + lip * ss(0.8, 1.0, t)) * rscale
        cx = 0.32 * rt * (1 - t) ** 1.7; cy = 0.08 * rt * math.sin(t * 3.1 + seed); z = t * H
        cen.append(Vector((cx, cy, z))); row = []
        for j in range(segs):
            th = 2 * math.pi * j / segs
            g = 0.05 * (0.3 + 0.7 * t) * math.sin(4 * th + 7.5 * t + seed)
            lum = 0.045 * noise.noise(Vector((math.cos(th) * 1.3, math.sin(th) * 1.3, t * 3.5 + seed)))
            rr = r * (1 + g + lum); row.append(bm.verts.new((cx + rr * math.cos(th), cy + rr * math.sin(th), z)))
        rows.append(row)
    for i in range(rings):
        for j in range(segs):
            k = (j + 1) % segs
            f = bm.faces.new((rows[i][j], rows[i][k], rows[i + 1][k], rows[i + 1][j]))
            for loop, uv in zip(f.loops, [(j / segs, i / rings), ((j + 1) / segs, i / rings), ((j + 1) / segs, (i + 1) / rings), (j / segs, (i + 1) / rings)]):
                loop[uvl].uv = uv
    tip = bm.verts.new(cen[0] + Vector((0, 0, -4)))
    for j in range(segs):
        f = bm.faces.new((rows[0][(j + 1) % segs], rows[0][j], tip))
        for loop in f.loops: loop[uvl].uv = ((j + 0.5) / segs, 0.0)
    top = bm.verts.new(cen[-1] + Vector((0, 0, 6)))
    for j in range(segs):
        f = bm.faces.new((rows[-1][j], rows[-1][(j + 1) % segs], top))
        for loop in f.loops: loop[uvl].uv = ((j + 0.5) / segs, 1.0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); me.shade_smooth(); return me


def streak_image(name, alpha, seed, W=512, Hh=256):
    """Tileable (in u) spiral streak texture; alpha version is the translucent rotating sheath."""
    px = [0.0] * (W * Hh * 4); rnd = random.Random(seed)
    waves = [(rnd.randint(3, 14), rnd.uniform(1.5, 4.5), rnd.uniform(0, 6.28), rnd.uniform(0.3, 1.0)) for _ in range(9)]
    norm = sum(w[3] for w in waves)
    BOT = (56, 52, 62); MIDC = (96, 92, 112); TOPC = (130, 126, 148)
    for y in range(Hh):
        v = y / (Hh - 1); c = [BOT[i] + (MIDC[i] - BOT[i]) * ss(0, 0.55, v) + (TOPC[i] - MIDC[i]) * ss(0.55, 1, v) for i in range(3)]
        for x in range(W):
            u = x / W; s = sum(a * math.sin(2 * math.pi * (n * u + tw * v) + ph) for (n, tw, ph, a) in waves) / norm
            k = 1 + 0.26 * s; i = (y * W + x) * 4
            px[i] = min(1, c[0] * k / 255); px[i + 1] = min(1, c[1] * k / 255); px[i + 2] = min(1, c[2] * k / 255)
            px[i + 3] = (max(0.0, min(1.0, 0.42 + 0.55 * s)) * (0.35 + 0.65 * ss(0.0, 0.25, v)) * (1 - 0.5 * ss(0.85, 1, v))) if alpha else 1.0
    img = bpy.data.images.get(name) or bpy.data.images.new(name, W, Hh, alpha=alpha)
    img.pixels.foreach_set(px); img.filepath_raw = GEN + name + ".png"; img.file_format = 'PNG'; img.save()
    return img
# Images: FH_FunnelStreaks (seed 1, opaque), FH_FunnelShellAlpha (seed 4, alpha). Materials: image -> Base Color (+Alpha for shell).


# --- Cumulonimbus v2 (installed 15 Nov 22:53): split tower + translucent anvil veil ---
# Reason: single-mesh cumulonimbus read as a stacked "table"/tiered cake at eye level (rows of tower lobes,
# terraced anvil sheets). Tower: random lobes, no rows. Anvil: separate lenticular veil, rendered T 0.5 in Roblox.
def cb_tower_lobes():
    rnd = random.Random(91); P = []
    for i in range(8):
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0, 55)
        P.append(((d * math.cos(a) * 1.2, d * math.sin(a), 22), (rnd.uniform(46, 58), rnd.uniform(42, 52), 24)))
    for i in range(40):
        z = rnd.uniform(40, 185); t = (z - 40) / 145; lean = t * 24; spread = 34 + 20 * t
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0, spread); r = rnd.uniform(40, 62) * (1 - 0.15 * t)
        P.append(((lean + d * math.cos(a), d * math.sin(a) * 0.9, z), (r, r * 0.9, r * rnd.uniform(0.75, 0.95))))
    return add_detail(P, rnd, 30, 1e9)          # voxel 2.8, smooth 6, decimate 0.14, flat_z 5, keep largest island


def cb_anvil_lobes():
    rnd = random.Random(97); P = []
    for (x, z, sx, sy, th) in [(20, 206, 100, 80, 22), (70, 205, 110, 95, 19), (120, 203, 110, 110, 16), (170, 201, 100, 125, 13), (215, 199, 80, 130, 10)]:
        P.append(((x, 0, z), (sx, sy, th)))
    for i in range(60):
        x = rnd.uniform(-20, 240); spread = 40 + 0.55 * max(0, x); y = rnd.uniform(-spread, spread)
        edge = min(1, max(0, x / 240)); r = rnd.uniform(28, 42) * (1 - 0.25 * edge)
        P.append(((x, y, 205 - 7 * edge + rnd.uniform(-2, 3)), (r, r * 0.9, max(8, 20 * (1 - 0.5 * edge)))))
    for i in range(12):
        x = rnd.uniform(-10, 70); y = rnd.uniform(-35, 35); r = rnd.uniform(22, 30)
        P.append(((x, y, 222 - 0.1 * x), (r, r, r * 0.5)))
    L = list(P)
    for (c, s) in P:                              # flat lateral fringes only
        for _ in range(rnd.randint(1, 2)):
            a = rnd.uniform(0, 2 * math.pi); d = Vector((math.cos(a), math.sin(a), rnd.uniform(-0.2, 0.3))).normalized()
            p = Vector(c) + Vector((d.x * s[0], d.y * s[1], d.z * s[2])) * 0.85; r = min(s[0], s[1]) * rnd.uniform(0.32, 0.45)
            L.append((tuple(p), (r, r, min(r * 0.45, s[2]))))
    return L                                     # voxel 2.6, smooth 8, decimate 0.2, keep largest island
# LUT bake height mapping: tower h 0.0-0.92, anvil h 0.7-1.0, wall cloud 0.30-1.0, congestus 0-0.85, shelf 0-0.6.
