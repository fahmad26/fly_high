# Fly High - Environment art Batch 1 (Zone 2 storm) graybox builder.
# Run inside Blender 5.3. With BLENDER_MCP_SAFE_MODE the file cannot be exec()-ed: paste its body into execute_blender_code.
# Export: select the five objects at origin -> glTF GLB (export_yup, apply) -> assets/models/scenery/storm/generated/FlyHigh_StormBatch1.glb
# Builds ONLY into scene FlyHigh_StormBatch1; objects carry the custom prop fh_batch1=1.
# Units: 1 Blender unit = 1 Roblox stud (final MeshPart.Size is set in Luau).
import bpy, bmesh, math, random
from mathutils import Vector, noise

SCENE = "FlyHigh_StormBatch1"
OUT = r"E:/Antigravity/Fly High/assets/models/scenery/storm/generated"


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    sc.unit_settings.scale_length = 1
    return sc


def clear(sc):
    for ob in list(sc.collection.all_objects):
        if ob.get("fh_batch1"):
            data = ob.data
            bpy.data.objects.remove(ob)
            if data is not None and data.users == 0:
                if isinstance(data, bpy.types.Mesh):
                    bpy.data.meshes.remove(data)
                elif isinstance(data, bpy.types.MetaBall):
                    bpy.data.metaballs.remove(data)


def link(sc, name, me):
    ob = bpy.data.objects.new(name, me)
    ob["fh_batch1"] = 1
    sc.collection.objects.link(ob)
    return ob


def finish_mesh(me):
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    me.shade_smooth()
    return me


# ---------------- Tornado funnel: one continuous surface of revolution ----------------
def funnel(name, H=210.0, rt=78.0, rb=6.5, rings=64, segs=48, seed=3):
    rnd = random.Random(seed)
    bm = bmesh.new()
    rows = []
    centers = []
    for i in range(rings + 1):
        t = i / rings
        r = rb + (rt - rb) * t ** 1.8
        r *= 1 + 0.16 * smoothstep(0.80, 1.0, t)           # lip flaring into the cloud base
        cx = 0.32 * rt * (1 - t) ** 1.7                      # rope leans out toward the foot
        cy = 0.08 * rt * math.sin(t * 3.1 + seed)
        z = t * H
        centers.append(Vector((cx, cy, z)))
        row = []
        for j in range(segs):
            th = 2 * math.pi * j / segs
            groove = 0.055 * (0.3 + 0.7 * t) * math.sin(4 * th + 7.5 * t + seed)   # gentle spiral bands
            lumpy = 0.05 * noise.noise(Vector((math.cos(th) * 1.3, math.sin(th) * 1.3, t * 3.5 + seed)))
            rr = r * (1 + groove + lumpy)
            row.append(bm.verts.new((cx + rr * math.cos(th), cy + rr * math.sin(th), z)))
        rows.append(row)
    for i in range(rings):
        a, b = rows[i], rows[i + 1]
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((a[j], a[k], b[k], b[j]))
    tip = bm.verts.new(centers[0] + Vector((0, 0, -4.0)))
    for j in range(segs):
        bm.faces.new((rows[0][(j + 1) % segs], rows[0][j], tip))
    top = bm.verts.new(centers[-1] + Vector((0, 0, 6.0)))
    for j in range(segs):
        bm.faces.new((rows[-1][j], rows[-1][(j + 1) % segs], top))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    return finish_mesh(me)


def foot_skirt(name, R=34.0, h=14.0, segs=40, seed=5):
    """Low flared dust ring around the rope tip (rendered semi-transparent in Roblox)."""
    bm = bmesh.new(); prof = [(0.25, 0.0), (0.55, 0.35), (1.0, 0.15), (0.92, -0.05), (0.5, -0.12)]
    rows = []
    for (pr, pz) in prof:
        row = []
        for j in range(segs):
            th = 2 * math.pi * j / segs
            rag = 1 + 0.18 * noise.noise(Vector((math.cos(th) * 2, math.sin(th) * 2, seed + pr)))
            row.append(bm.verts.new((R * pr * rag * math.cos(th), R * pr * rag * math.sin(th), h * pz)))
        rows.append(row)
    for i in range(len(rows)):
        a, b = rows[i], rows[(i + 1) % len(rows)]
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((a[j], a[k], b[k], b[j]))
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    return finish_mesh(me)


# ---------------- Cloud family: ellipsoid lobes -> voxel remesh -> laplacian smooth -> flat base -> decimate ----------------
# (Metaballs were tried first and produced thin pancakes with detached puffs; replaced 15 Nov.)
def blobcloud(sc, name, lobes, flat_z=None, voxel=4.0, smooth_iter=12, target_tris=3200, seed=0):
    from mathutils import Matrix
    bm = bmesh.new()
    for (c, s) in lobes:
        m = Matrix.Translation(Vector(c)) @ Matrix.Diagonal((s[0], s[1], s[2], 1.0))
        bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0, matrix=m)
    src = bpy.data.meshes.new(name + "_src"); bm.to_mesh(src); bm.free()
    ob = bpy.data.objects.new(name + "_tmp", src); sc.collection.objects.link(ob)
    r = ob.modifiers.new("Remesh", 'REMESH'); r.mode = 'VOXEL'; r.voxel_size = voxel; r.use_smooth_shade = True
    sm = ob.modifiers.new("Smooth", 'LAPLACIANSMOOTH'); sm.iterations = smooth_iter; sm.lambda_factor = 0.8; sm.use_volume_preserve = True
    dg = bpy.context.evaluated_depsgraph_get(); dg.update()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob); bpy.data.meshes.remove(src)
    if flat_z is not None:
        for v in me.vertices:
            if v.co.z < flat_z:
                v.co.z = flat_z - 1.5 * noise.noise(Vector((v.co.x / 50, v.co.y / 50, seed + 0.3)))
    ob = bpy.data.objects.new(name + "_dec", me); sc.collection.objects.link(ob)
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    if tris > target_tris:
        d = ob.modifiers.new("Decimate", 'DECIMATE'); d.ratio = target_tris / tris
        dg = bpy.context.evaluated_depsgraph_get(); dg.update()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob); bpy.data.meshes.remove(me); me = me2
    else:
        bpy.data.objects.remove(ob)
    me.name = name
    return finish_mesh(me)


def head_lobes(seed=31):
    rnd = random.Random(seed); L = []
    L.append(((0, 0, 24), (118, 108, 30)))
    L.append(((38, 4, 30), (112, 88, 30)))
    for i in range(10):
        a = 2 * math.pi * i / 10 + rnd.uniform(-0.12, 0.12); rr = rnd.uniform(90, 108)
        L.append(((rr * math.cos(a), rr * math.sin(a), 16), (36, 36, 20)))
    for (x, y, z, r) in [(-30, -20, 52, 42), (22, 26, 58, 46), (62, -8, 50, 40), (-62, 22, 44, 36), (0, 0, 66, 40), (95, 15, 40, 34)]:
        L.append(((x, y, z), (r, r, r * 0.85)))
    return L


def thunder_lobes(seed=11):
    # Iteration 2 (cumulonimbus): broad base, tower widening upward, thick lumpy anvil streaming downwind (+x).
    # Iteration 1 read as a mushroom/goblet in Studio (narrow stem + thin plate), see audit/storm-batch1-2026-11-15.
    rnd = random.Random(seed); L = []
    for i in range(6):
        L.append(((-110 + i * 42 + rnd.uniform(-6, 6), rnd.uniform(-14, 14), 26), (56, 52, 28)))
    for k in range(7):
        z = 50 + k * 14; w = 52 + k * 5.5
        for j in range(2):
            L.append(((-20 + rnd.uniform(-28, 28) + k * 4, rnd.uniform(-20, 20), z + rnd.uniform(-5, 5)), (w * rnd.uniform(0.8, 1.0), w * 0.85, 38)))
    L.append(((45, 0, 150), (150, 82, 30)))
    L.append(((150, 4, 146), (95, 62, 24)))
    for i in range(8):
        L.append(((-60 + i * 30 + rnd.uniform(-8, 8), rnd.uniform(-35, 35), 168 + rnd.uniform(-4, 6)), (rnd.uniform(30, 40), rnd.uniform(28, 36), 18)))
    for i in range(5):
        L.append(((20 + i * 32, rnd.uniform(-30, 30), 128), (30, 30, 14)))
    return L


def congestus_lobes(seed=17):
    # Rounded cauliflower mound, no anvil, flat dark base (second silhouette so copies are not identical).
    rnd = random.Random(seed); L = []
    for i in range(6):
        L.append(((-115 + i * 46 + rnd.uniform(-6, 6), rnd.uniform(-16, 16), 26), (58, 54, 28)))
    for i in range(14):
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0, 80)
        z = 55 + rnd.uniform(0, 55) * (1 - d / 120)
        r = rnd.uniform(36, 52)
        L.append(((d * math.cos(a) * 1.3, d * math.sin(a) * 0.6, z), (r, r * 0.9, r * 0.85)))
    for i in range(4):
        L.append(((rnd.uniform(-40, 40), rnd.uniform(-20, 20), 115 + rnd.uniform(0, 15)), (34, 32, 30)))
    return L


def shelf_lobes(seed=21, length=420):
    rnd = random.Random(seed); L = []; n = 10
    for i in range(n):
        x = -length / 2 + i * length / (n - 1) + rnd.uniform(-8, 8)
        L.append(((x, rnd.uniform(-14, 14), 24), (56, 48, 26)))
        if rnd.random() < 0.75:
            r = rnd.uniform(32, 42)
            L.append(((x + rnd.uniform(-14, 14), rnd.uniform(-14, 14), 46 + rnd.uniform(0, 8)), (r, r * 0.95, r * 0.8)))
    return L


def build():
    sc = scene(); clear(sc)
    win = bpy.context.window; prev = win.scene; win.scene = sc
    try:
        made = {}
        made["StormFunnel"] = link(sc, "StormFunnel", funnel("StormFunnel"))
        made["StormFootSkirt"] = link(sc, "StormFootSkirt", foot_skirt("StormFootSkirt"))
        made["StormVortexHead"] = link(sc, "StormVortexHead", blobcloud(sc, "StormVortexHead", head_lobes(), flat_z=4.0, target_tris=3000))
        made["StormThunderhead"] = link(sc, "StormThunderhead", blobcloud(sc, "StormThunderhead", thunder_lobes(), flat_z=6.0, target_tris=3800))
        made["StormCongestus"] = link(sc, "StormCongestus", blobcloud(sc, "StormCongestus", congestus_lobes(), flat_z=6.0, target_tris=3200))
        made["StormShelfBank"] = link(sc, "StormShelfBank", blobcloud(sc, "StormShelfBank", shelf_lobes(), flat_z=5.0, target_tris=3000))
        # layout for review only (export resets transforms)
        made["StormFootSkirt"].location = (0.32 * 78, 0.08 * 78 * math.sin(3), 0)
        made["StormVortexHead"].location = (0, 0, 200)
        made["StormThunderhead"].location = (320, 0, 0)
        made["StormShelfBank"].location = (0, 260, 0)
        made["StormCongestus"].location = (320, -260, 0)
        out = {}
        for n, ob in made.items():
            me = ob.data
            out[n] = dict(tris=sum(len(p.vertices) - 2 for p in me.polygons), verts=len(me.vertices),
                          dims=[round(v, 1) for v in ob.dimensions])
        return out
    finally:
        win.scene = prev


RESULT = build()
print(RESULT)
