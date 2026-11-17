# Fly High - StormBat v6 and FireBee v6 generator (Blender, MCP safe mode compatible).
# Safe mode: paste the file into execute_blender_code (no open/exec); no callables passed as arguments.
# Assets: StormBat 113741592165135, FireBee 115566779938714 (17 Nov 2026). Source of record also in
# assets/models/scenery/FlyHigh_SceneryKits_round6.blend (scenes FlyHigh_Bat6, FlyHigh_Bee6).
# Authored in Roblox axes (x right, y up, -z front); R() maps to Blender. Template units (the game scales
# enemies by ENEMY_SCALES * 1.25). Wing parts flap about (+-0.68, 0.35, 0) in ObstacleManager, so wing roots
# start there. Install each part at its printed centre with CFrame.new(center) * CFrame.Angles(0, math.pi, 0)
# (glTF import yaw flip), as for the Phantom v5 kit.
import bpy, bmesh, math, random
from mathutils import Vector, noise

OUTDIR = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/"


def R(v):
    return Vector((v.x, -v.z, v.y))


def scene(name):
    sc = bpy.data.scenes.get(name) or bpy.data.scenes.new(name)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    return sc


def finish(sc, name, bm, smooth=True):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me); sc.collection.objects.link(ob)
    for o in sc.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=2.0); bpy.ops.object.mode_set(mode='OBJECT')
    return ob


def ellipsoid(bm, c, r, seg=20, rings=14, fur=0.0, seed=0.0, taper=0.0):
    """Ellipsoid in Roblox axes; taper shrinks the +z (rear) half."""
    verts = []
    for i in range(rings + 1):
        phi = math.pi * i / rings
        row = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            d = Vector((math.sin(phi) * math.cos(th), math.cos(phi), math.sin(phi) * math.sin(th)))
            s = 1.0 - taper * max(0.0, d.z)
            if fur:
                s *= 1 + fur * noise.noise(Vector((d.x * 3 + seed, d.y * 3, d.z * 3)))
            p = c + Vector((d.x * r.x, d.y * r.y, d.z * r.z)) * s
            row.append(bm.verts.new(R(p)))
        verts.append(row)
    for i in range(rings):
        for k in range(seg):
            a, b = verts[i][k], verts[i][(k + 1) % seg]
            cc, dd = verts[i + 1][(k + 1) % seg], verts[i + 1][k]
            bm.faces.new((a, b, cc, dd))
    return verts


def tube(bm, pts, radii, seg=8, cap=True):
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        ref = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
        s1 = d.cross(ref).normalized(); s2 = d.cross(s1).normalized()
        rings.append([bm.verts.new(R(p + s1 * math.cos(2 * math.pi * k / seg) * radii[i]
                                     + s2 * math.sin(2 * math.pi * k / seg) * radii[i])) for k in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    if cap:
        bm.faces.new(rings[0][::-1])
        tip = bm.verts.new(R(pts[-1] + (pts[-1] - pts[-2]).normalized() * radii[-1]))
        for k in range(seg):
            bm.faces.new((rings[-1][k], rings[-1][(k + 1) % seg], tip))


def cone(bm, base, tip, r0, seg=10, bend=None):
    pts = []
    n = 6
    for i in range(n + 1):
        t = i / n
        p = base.lerp(tip, t)
        if bend:
            p = p + bend * math.sin(math.pi * t) * 0.5
        pts.append(p)
    tube(bm, pts, [r0 * (1 - i / (n + 0.6)) for i in range(n + 1)], seg=seg)


def sheet(bm, outline, thickness=0.05, fan_index=0):
    """Closed outline (Roblox points), fan-triangulated from outline[fan_index], solidified."""
    top = [bm.verts.new(R(p + Vector((0, thickness / 2, 0)))) for p in outline]
    bot = [bm.verts.new(R(p - Vector((0, thickness / 2, 0)))) for p in outline]
    n = len(outline)
    f = fan_index
    for k in range(n):
        a, b = (f + 1 + k) % n, (f + 2 + k) % n
        if b == f or a == f:
            continue
        bm.faces.new((top[f], top[a], top[b]))
        bm.faces.new((bot[f], bot[b], bot[a]))
    for k in range(n):
        a, b = k, (k + 1) % n
        bm.faces.new((top[a], bot[a], bot[b], top[b]))


def export(sc, path, center_names=None):
    bpy.context.window.scene = sc
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in sc.objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = sc.objects[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True,
                              export_texcoords=True, export_normals=True)
    for o in sc.objects:
        bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
        mn = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
        mx = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
        c = (mn + mx) / 2
        print('["%s"]=Vector3.new(%.3f,%.3f,%.3f), tris=%d' % (o.name, c.x, c.z, -c.y,
              sum(len(p.vertices) - 2 for p in o.data.polygons)))


def bat_w(s, u, v):
    # Wing plane: u along the span, v back along the chord; dihedral + camber.
    y = 0.62 + 0.13 * u + 0.22 * math.sin(math.pi * min(u, 5.4) / 5.4)
    return Vector((s * u, y, v))


def scallop(a, b, wr, depth=0.26):
    return a.lerp(b, 0.5).lerp(wr, depth)


def blade(s, root, length, width, sweep, lift):
    out = []
    pts = []
    n = 14
    for i in range(n):
        a = math.pi * i / (n - 1)
        pts.append(((1 - math.cos(a)) / 2 * length, max(0.0, math.sin(a)) ** 0.8 * width))
    for u, h in pts:  # leading edge out
        out.append(root + Vector((s * u, lift * u / length, -h * 0.35 + sweep * u / length)))
    for u, h in reversed(pts[1:-1]):  # trailing edge back
        out.append(root + Vector((s * u, lift * u / length, h + sweep * u / length)))
    return out


# ------------------------------------------------------------------------------------------------
# StormBat v6: plump furred body, big ears, finger-boned wings with scalloped membranes.
# ------------------------------------------------------------------------------------------------
sc = scene("FlyHigh_Bat6")
bm = bmesh.new()
ellipsoid(bm, Vector((0, 0.42, 0.25)), Vector((0.82, 0.92, 1.2)), seg=22, rings=16, fur=0.07, seed=1.3,
          taper=0.12)  # slightly tapered rump
ellipsoid(bm, Vector((0, 0.9, -1.05)), Vector((0.72, 0.66, 0.68)), seg=20, rings=14, fur=0.05, seed=4.1)
ellipsoid(bm, Vector((0, 0.74, -1.62)), Vector((0.34, 0.27, 0.32)), seg=14, rings=10)  # snout
ellipsoid(bm, Vector((0, 0.88, -1.9)), Vector((0.13, 0.09, 0.08)), seg=10, rings=6)  # nose leaf
for s in (-1, 1):
    # Tall pointed ears, leaning out and back.
    cone(bm, Vector((s * 0.36, 1.3, -1.02)), Vector((s * 0.78, 2.45, -0.78)), 0.34, seg=12,
         bend=Vector((s * 0.12, 0, -0.18)))
    # Fangs.
    cone(bm, Vector((s * 0.12, 0.55, -1.78)), Vector((s * 0.1, 0.24, -1.82)), 0.055, seg=6)
    # Tucked feet with claws under the rump.
    tube(bm, [Vector((s * 0.3, -0.25, 1.0)), Vector((s * 0.34, -0.55, 1.35)), Vector((s * 0.3, -0.62, 1.62))],
         [0.11, 0.08, 0.05], seg=7)
body = finish(sc, "Bat_Body", bm)

for s, tag in ((1, "R"), (-1, "L")):
    S, E, Wr = bat_w(s, 0.62, -0.05), bat_w(s, 1.6, -0.32), bat_w(s, 2.65, -0.12)
    T1, T2, T3, T4 = bat_w(s, 5.45, -0.45), bat_w(s, 5.05, 1.25), bat_w(s, 4.0, 2.25), bat_w(s, 2.55, 2.45)
    B = bat_w(s, 0.68, 1.55)
    outline = [Wr, T1, scallop(T1, T2, Wr, 0.18), T2, scallop(T2, T3, Wr), T3, scallop(T3, T4, Wr), T4,
               scallop(T4, B, Wr, 0.2), B, S, E]
    bm = bmesh.new()
    sheet(bm, outline, thickness=0.06, fan_index=0)
    finish(sc, "Bat_Wing" + tag, bm)
    bm = bmesh.new()
    tube(bm, [S, S.lerp(E, 0.5) + Vector((0, 0.05, 0)), E, E.lerp(Wr, 0.5), Wr],
         [0.14, 0.12, 0.11, 0.1, 0.11], seg=8, cap=False)
    for tip, r in ((T1, 0.075), (T2, 0.065), (T3, 0.06), (T4, 0.055)):
        tube(bm, [Wr, Wr.lerp(tip, 0.5) + Vector((0, 0.06, 0)), tip], [r, r * 0.8, r * 0.35], seg=6)
    cone(bm, Wr, Wr + Vector((s * 0.15, 0.35, -0.38)), 0.08, seg=6)  # thumb claw
    finish(sc, "Bat_Bones" + tag, bm)

export(sc, OUTDIR + "FlyHigh_StormBat_v6.glb", None)

# ------------------------------------------------------------------------------------------------
# FireBee v6: fuzzy ember thorax, glowing striped abdomen with stinger, compound eyes, veined wings.
# ------------------------------------------------------------------------------------------------
sc = scene("FlyHigh_Bee6")


def abdomen_profile(t):
    # t 0 (front, waist) .. 1 (stinger); radius multiplier.
    return math.sin(math.pi * min(1.0, 0.08 + t * 0.95)) ** 0.75


AB0, AB1 = 0.05, 2.35  # z extent of the abdomen
AB_C = Vector((0, 0.28, 0))
AB_R = Vector((0.86, 0.8, 1.0))


def abdomen_ring(bm, t0, t1, grow=0.0, seg=22, steps=6):
    rows = []
    for i in range(steps + 1):
        t = t0 + (t1 - t0) * i / steps
        z = AB0 + (AB1 - AB0) * t
        r = abdomen_profile(t)
        droop = -0.32 * t * t
        row = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            p = Vector((math.cos(th) * AB_R.x * r * (1 + grow), AB_C.y + droop + math.sin(th) * AB_R.y * r * (1 + grow), z))
            row.append(bm.verts.new(R(p)))
        rows.append(row)
    for a, b in zip(rows, rows[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    return rows


bm = bmesh.new()
# Abdomen dark base, full length with closed ends.
rows = abdomen_ring(bm, 0.0, 1.0, steps=18)
bm.faces.new(rows[0][::-1])
tipc = bm.verts.new(R(Vector((0, AB_C.y - 0.32, AB1 + 0.02))))
for k in range(len(rows[-1])):
    bm.faces.new((rows[-1][k], rows[-1][(k + 1) % len(rows[-1])], tipc))
cone(bm, Vector((0, AB_C.y - 0.3, AB1 - 0.05)), Vector((0, AB_C.y - 0.42, AB1 + 0.62)), 0.12, seg=8)  # stinger
ellipsoid(bm, Vector((0, 0.42, -1.92)), Vector((0.62, 0.62, 0.55)), seg=18, rings=12)  # head
ellipsoid(bm, Vector((0, 0.42, -0.25)), Vector((0.28, 0.28, 0.3)), seg=12, rings=8)  # waist
for s in (-1, 1):
    # Curled antennae.
    tube(bm, [Vector((s * 0.2, 0.9, -2.25)), Vector((s * 0.35, 1.45, -2.55)), Vector((s * 0.62, 1.78, -2.5)),
              Vector((s * 0.78, 1.72, -2.25))], [0.06, 0.05, 0.045, 0.07], seg=6)
    # Mandibles.
    cone(bm, Vector((s * 0.2, 0.05, -2.3)), Vector((s * 0.05, -0.12, -2.55)), 0.08, seg=6)
    # Six bent legs tucked under the thorax.
    for i, z in enumerate((-1.35, -0.85, -0.35)):
        hip = Vector((s * 0.45, 0.0, z))
        knee = Vector((s * 0.95, -0.35, z - 0.15 + i * 0.12))
        foot = Vector((s * 0.7, -0.95, z + 0.25 + i * 0.1))
        tube(bm, [hip, knee, foot], [0.08, 0.065, 0.04], seg=6)
body = finish(sc, "Bee_Body", bm)

bm = bmesh.new()
# Fuzzy ember thorax (separate colour) and collar fuzz behind the head.
ellipsoid(bm, Vector((0, 0.52, -0.9)), Vector((0.86, 0.82, 0.78)), seg=22, rings=16, fur=0.11, seed=7.7)
finish(sc, "Bee_Fuzz", bm)

bm = bmesh.new()
for t0, t1 in ((0.16, 0.3), (0.42, 0.56), (0.68, 0.8)):
    rows = abdomen_ring(bm, t0, t1, grow=0.035, steps=4)
glow = finish(sc, "Bee_Glow", bm)

bm = bmesh.new()
for s in (-1, 1):
    ellipsoid(bm, Vector((s * 0.48, 0.55, -2.08)), Vector((0.26, 0.36, 0.3)), seg=14, rings=10)
finish(sc, "Bee_Visor", bm)

for s, tag in ((1, "R"), (-1, "L")):
    bm = bmesh.new()
    sheet(bm, blade(s, Vector((s * 0.55, 1.05, -1.05)), 3.1, 0.62, 0.65, 0.55), thickness=0.04)
    sheet(bm, blade(s, Vector((s * 0.55, 0.98, -0.65)), 2.2, 0.42, 1.0, 0.25), thickness=0.04)
    finish(sc, "Bee_Wing" + tag, bm)

export(sc, OUTDIR + "FlyHigh_FireBee_v6.glb", None)
