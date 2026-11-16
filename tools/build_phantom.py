# Fly High - ShadowPhantom v5 generator (Blender, MCP safe mode compatible).
# Builds Phantom_Body (hooded cloak, ragged hem, recessed hood), Phantom_Arms (sleeves) and
# Phantom_Claws, then exports FlyHigh_Phantom_v5.glb. Authored in Roblox axes (x, y up, -z front);
# R() maps to Blender. Install in Studio at each part's printed centre with
# CFrame.new(center) * CFrame.Angles(0, math.pi, 0) (glTF import yaw flip).
import bpy, bmesh, math, random
from mathutils import Vector, noise

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_Phantom_v5.glb"
SC = "FlyHigh_Phantom"
sc = bpy.data.scenes.get(SC) or bpy.data.scenes.new(SC)
bpy.context.window.scene = sc
for o in list(sc.objects):
    bpy.data.objects.remove(o)


def R(v):
    return Vector((v.x, -v.z, v.y))


def finish(name, bm, smooth=True):
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


def prof(y):
    pts = [(-2.9, 1.6), (-2.0, 1.35), (-1.0, 1.1), (-0.3, 1.0), (0.5, 1.15), (0.95, 0.95), (1.35, 0.72), (1.7, 0.42), (1.9, 0.12)]
    for (a, ra), (b, rb) in zip(pts, pts[1:]):
        if a <= y <= b:
            t = (y - a) / (b - a)
            return ra + (rb - ra) * (t * t * (3 - 2 * t))
    return 0.1


random.seed(6)
# --- cloak body ---
bm = bmesh.new()
NY, NT = 26, 40
ys = [-2.9 + i * (4.8 / (NY - 1)) for i in range(NY)]
rings = []
for i, y in enumerate(ys):
    tnorm = (y + 2.9) / 4.8
    r0 = prof(y)
    cz = 0.3 + 0.35 * max(0.0, y - 0.8)
    ring = []
    for k in range(NT):
        th = 2 * math.pi * k / NT
        fold = 1 + 0.09 * (1 - tnorm) * math.cos(7 * th + 0.6 * math.sin(y * 2.0)) + 0.03 * noise.noise(Vector((th * 2, y * 2, 0)))
        r = r0 * fold
        x = math.cos(th) * r; z = math.sin(th) * r
        if 0.55 < y < 1.75:  # recessed hood opening on the front (-Z)
            front = max(0.0, -math.sin(th))
            w = math.sin(math.pi * (y - 0.55) / 1.2)
            if front > 0.55:
                z = z + (front - 0.55) * 1.6 * w * r
        yy = y
        if i == 0:  # ragged hem
            yy = y - 0.45 * abs(noise.noise(Vector((th * 3.0, 0.5, 0)))) - 0.25 * (1 if (k % 4 == 0) else 0)
        ring.append(bm.verts.new(R(Vector((x, yy, z + cz)))))
    rings.append(ring)
for a, b in zip(rings, rings[1:]):
    for k in range(NT):
        bm.faces.new((a[k], a[(k + 1) % NT], b[(k + 1) % NT], b[k]))
tip = bm.verts.new(R(Vector((0, 2.0, 0.3 + 0.35 * 1.2 + 0.15))))
for k in range(NT):
    bm.faces.new((rings[-1][k], rings[-1][(k + 1) % NT], tip))
inner = []  # inner lining so the hem reads double-sided
for i in range(4):
    y = ys[i]; r0 = prof(y) * 0.93; cz = 0.3
    inner.append([bm.verts.new(R(Vector((math.cos(2 * math.pi * k / NT) * r0, y + 0.02, math.sin(2 * math.pi * k / NT) * r0 + cz)))) for k in range(NT)])
for a, b in zip(inner, inner[1:]):
    for k in range(NT):
        bm.faces.new((b[k], b[(k + 1) % NT], a[(k + 1) % NT], a[k]))
body = finish("Phantom_Body", bm)

# --- sleeves ---
bm = bmesh.new()
for s in (-1, 1):
    sh = Vector((s * 0.95, 0.45, 0.05)); el = Vector((s * 1.45, -0.35, -0.45)); wr = Vector((s * 1.55, -1.05, -1.05))
    pts = [sh, sh.lerp(el, 0.5) + Vector((s * 0.1, 0, 0)), el, el.lerp(wr, 0.5), wr]
    tube(bm, pts, [0.42, 0.4, 0.42, 0.5, 0.58], seg=12, cap=False)
arms = finish("Phantom_Arms", bm)

# --- claws ---
bm = bmesh.new()
for s in (-1, 1):
    wr = Vector((s * 1.55, -1.05, -1.05))
    for f in range(4):
        a = (f - 1.5) * 0.35
        base = wr + Vector((s * 0.12 * math.cos(a) + 0.18 * math.sin(a), -0.15, -0.25))
        p1 = base + Vector((0.15 * math.sin(a), -0.35, -0.25))
        p2 = p1 + Vector((0.1 * math.sin(a), -0.35, 0.05))
        tube(bm, [base, p1, p2], [0.075, 0.06, 0.035], seg=6)
claws = finish("Phantom_Claws", bm)

for o in bpy.context.view_layer.objects:
    o.select_set(False)
for o in sc.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                          export_apply=True, export_materials='NONE', export_yup=True,
                          export_texcoords=True, export_normals=True)
for o in sc.objects:
    bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
    mn = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    mx = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    c = (mn + mx) / 2
    print('["%s"]=Vector3.new(%.3f,%.3f,%.3f),' % (o.name, c.x, c.z, -c.y))
# Expected: Body (0.046,-0.726,0.313), Arms (0,-0.336,-0.526), Claws (0,-1.548,-1.424)
