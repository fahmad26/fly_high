"""Fly High semi-realistic creature generator (enemies and scenery birds).

Run inside Blender through the Blender MCP (safe-mode compatible: bpy/bmesh/mathutils/math only,
no lambdas, no file IO). Authored in Roblox studs: X right, Y up, -Z forward. Converted to Blender
(X, -Z, Y) at vertex creation; glTF export with +Y up maps it back to Roblox axes.

Each creature is exported as one GLB whose mesh names map to Roblox part names:
  <Pre>Body     -> Body      (hit part)
  <Pre>WingR/L  -> Wing      (animated by ObstacleManager / SceneryHabitatArt)
  <Pre>Plumage, Spikes, Talons, Tatters, Panels, Dish, Aperture ... -> decoration or legacy names
The script prints each mesh's bounding-box centre in Roblox axes; the Roblox installer uses these as
the part offsets (SourceCenter) so pieces line up with the authored layout.

History: v1-v4 lived only in the live Blender session (16 Nov 2026). v5 (this file) adds the
GuardianDrone remodel (installed as asset 122179757209881). The phoenix/bird builders here are the v5
redesign draft; the installed phoenix/gull/eagle are still v4 (fixed by the import-yaw correction below).
The satellite builder is a draft and is NOT installed (the material-polished template already reads well).
Wyvern/bat/bee/phantom generators were never saved to a file (v1-v4 lived in the Blender session only).

IMPORTANT - import yaw: Roblox's glTF import turns every mesh 180 degrees about Y relative to the
authoring frame used here (an object authored at -Z arrives at +Z). Install by taking each MeshPart's
offset relative to the Body inside the inserted model, then pre-multiplying CFrame.Angles(0, math.pi, 0):
    cf = flip * CFrame.new(rel.Position * S) * rel.Rotation
Templates installed before 16 Nov 18:33 WIB had positions from the printed centres but un-flipped meshes,
which made the phoenix look broken (crest floating behind, tail at the head). They were corrected by
rotating each MeshPart 180 degrees about its own centre; such templates carry attribute ImportYawFixed.
"""
import bpy
import bmesh
import math
from mathutils import Vector

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/"
SCENE = "FlyHigh_Creatures"


def V(x, y, z):
    return Vector((x, y, z))


def R(p):
    return Vector((p.x, -p.z, p.y))


def new_bm():
    bm = bmesh.new()
    return bm, bm.loops.layers.uv.new("UVMap")


def put_face(bm, uv, verts, uvs):
    f = bm.faces.new(verts)
    for loop, coord in zip(f.loops, uvs):
        loop[uv].uv = coord
    return f


def tube(bm, uv, pts, radii, seg=16, vscale=1.0, urep=1.0, caps=True):
    """Lofted tube along pts; radii are floats or (rx, ry) ellipses."""
    rings = []
    acc = 0.0
    prev = None
    for i in range(len(pts)):
        p = Vector(pts[i])
        r = radii[i]
        if prev is not None:
            acc += (p - prev).length
        prev = p
        nxt = Vector(pts[min(i + 1, len(pts) - 1)])
        prv = Vector(pts[max(i - 1, 0)])
        d = (nxt - prv).normalized()
        ref = V(0, 1, 0) if abs(d.y) < 0.9 else V(1, 0, 0)
        s1 = d.cross(ref).normalized()
        s2 = d.cross(s1).normalized()
        if isinstance(r, tuple):
            rx, ry = r
        else:
            rx, ry = r, r
        ring = []
        for k in range(seg + 1):
            a = 2 * math.pi * k / seg
            q = p + s1 * math.cos(a) * rx + s2 * math.sin(a) * ry
            ring.append((bm.verts.new(R(q)), urep * k / seg, acc * vscale))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(seg):
            quad = (a[k], b[k], b[k + 1], a[k + 1])
            put_face(bm, uv, [q[0] for q in quad], [(q[1], q[2]) for q in quad])
    if caps:
        for which in (0, 1):
            ring = rings[0] if which == 0 else rings[-1]
            c = V(0, 0, 0)
            for item in ring[:-1]:
                c += item[0].co
            c /= len(ring) - 1
            cv = bm.verts.new(c)
            for k in range(seg):
                if which == 1:
                    put_face(bm, uv, [ring[k][0], ring[k + 1][0], cv], [(0.5, 0.5)] * 3)
                else:
                    put_face(bm, uv, [ring[k + 1][0], ring[k][0], cv], [(0.5, 0.5)] * 3)


def feather(bm, uv, base, dirv, side, length, width, droop=0.1, camber=0.06, segs=7, twist=0.0, eye=False):
    """Double-sided vane with a rounded tip. UV: u across (rachis at 0.5), v base->tip."""
    dirv = dirv.normalized()
    side = side.normalized()
    up = dirv.cross(side).normalized()
    rows = []
    for k in range(segs + 1):
        t = k / segs
        if eye:
            # Streamer: narrow shaft that swells into a teardrop "eye" at the end.
            w = width * (0.22 + 0.78 * max(0.0, math.sin(math.pi * min(1.0, max(0.0, (t - 0.55) / 0.45)))))
        else:
            # Rounded feather: full width through the middle, elliptical tip, slight root taper.
            tip = max(0.0, 1.0 - ((t - 0.5) / 0.5) ** 4)
            w = width * (0.45 + 0.55 * math.sqrt(tip)) * (1.0 if t < 0.97 else 0.25)
        c = base + dirv * (length * t) - up * (droop * length * t * t)
        sd = side * math.cos(twist * t) + up * math.sin(twist * t)
        rows.append([(c - sd * (w / 2), 0.0, t), (c + up * (camber * w), 0.5, t), (c + sd * (w / 2), 1.0, t)])
    for sgn in (1, -1):
        off = V(0, 0, 0) if sgn > 0 else up * -0.012
        vr = [[bm.verts.new(R(p + off)) for (p, _u, _v) in row] for row in rows]
        for k in range(segs):
            for j in range(2):
                if sgn > 0:
                    idx = ((k, j), (k, j + 1), (k + 1, j + 1), (k + 1, j))
                else:
                    idx = ((k, j + 1), (k, j), (k + 1, j), (k + 1, j + 1))
                put_face(bm, uv, [vr[a][b] for (a, b) in idx], [(rows[a][b][1], rows[a][b][2]) for (a, b) in idx])


def sheet(bm, uv, front, back, steps_u, steps_v, bow=0.0):
    """Double-sided surface between two polylines (same point count). UV u along, v front->back."""
    n = len(front)
    rows = []
    for j in range(steps_v + 1):
        s = j / steps_v
        row = []
        for i in range(n):
            p = front[i].lerp(back[i], s) + V(0, bow * math.sin(math.pi * s), 0)
            row.append((p, i / (n - 1), s))
        rows.append(row)
    for sgn in (1, -1):
        vr = [[bm.verts.new(R(p + V(0, 0 if sgn > 0 else -0.012, 0))) for (p, _u, _v) in row] for row in rows]
        for j in range(steps_v):
            for i in range(n - 1):
                if sgn > 0:
                    idx = ((j, i), (j, i + 1), (j + 1, i + 1), (j + 1, i))
                else:
                    idx = ((j, i + 1), (j, i), (j + 1, i), (j + 1, i + 1))
                put_face(bm, uv, [vr[a][b] for (a, b) in idx], [(rows[a][b][1], rows[a][b][2]) for (a, b) in idx])


def bez(a, b, c, t):
    return a * ((1 - t) ** 2) + b * (2 * (1 - t) * t) + c * (t * t)


def sphere(bm, uv, center, radii, seg=18, rings=10):
    pts = []
    rad = []
    for k in range(rings + 1):
        t = k / rings
        a = math.pi * t
        pts.append(center + V(0, 0, -math.cos(a) * radii.z))
        rad.append((max(0.001, math.sin(a) * radii.x), max(0.001, math.sin(a) * radii.y)))
    tube(bm, uv, pts, rad, seg=seg, vscale=0.5, caps=False)


def finish(name, bm):
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-5)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------------------------------------------------------------- birds

def bird_wing(sx, span, kind):
    """Continuous wing: covert sheet + three covert rows + secondaries + rounded primaries."""
    bm, uv = new_bm()
    sh = V(sx * 0.7, 0.62, -0.55)
    el = V(sx * 2.4 * span, 1.05, -0.35)
    wr = V(sx * 4.3 * span, 0.95, -0.55)
    lead = [bez(sh, el, wr, i / 12) for i in range(13)]
    trail = [p + V(0, -0.05, 1.35 - 0.55 * (i / 12)) for i, p in enumerate(lead)]
    sheet(bm, uv, lead, trail, 12, 3, bow=0.08)
    rows = ((0.9, 0.55, 14), (1.35, 0.6, 13), (1.8, 0.62, 12))
    for r, (ln, wd, count) in enumerate(rows):
        for k in range(count):
            t = (k + 0.5) / count
            p = bez(sh, el, wr, t) + V(0, 0.07 - r * 0.03, 0.05 + r * 0.32)
            feather(bm, uv, p, V(sx * 0.08, -0.03, 1), V(sx, 0, 0), ln, wd, droop=0.05, segs=5)
    nsec = 12
    for k in range(nsec):
        t = (k + 0.5) / nsec
        p = bez(sh, el, wr, t) + V(0, -0.04, 0.95)
        feather(bm, uv, p, V(sx * (0.04 + 0.18 * t), -0.04, 1), V(sx, 0, 0), 2.1 - 0.35 * t, 0.62, droop=0.1, segs=6)
    nprim = 9 if kind != "eagle" else 7
    spread = 7.5 if kind != "eagle" else 10.5
    for k in range(nprim):
        a = math.radians(6 + k * spread)
        base = wr + V(-sx * 0.12 * k, 0.0, 0.08 * k)
        ln = (3.5 if kind == "phoenix" else 3.2) - 0.14 * k
        wd = 0.58 if kind != "eagle" else 0.46
        feather(bm, uv, base, V(sx * math.cos(a), -0.03, math.sin(a)), V(-sx * math.sin(a), 0, math.cos(a)), ln, wd, droop=0.12, segs=8)
    return bm


def bird(pre, kind):
    phoenix = kind == "phoenix"
    eagle = kind == "eagle"
    out = []
    # Body: chest, slender neck, rounded head. Small UV tiles so the scale texture stays fine-grained.
    bm, uv = new_bm()
    if phoenix:
        spine = [(0, 0.3, 2.6), (0, 0.25, 1.9), (0, 0.15, 0.9), (0, 0.22, -0.15), (0, 0.55, -0.95), (0, 1.05, -1.5),
                 (0, 1.5, -1.95), (0, 1.75, -2.4), (0, 1.78, -2.85), (0, 1.62, -3.2), (0, 1.45, -3.4)]
        radii = [(0.18, 0.15), (0.5, 0.45), (0.8, 0.74), (0.85, 0.82), (0.55, 0.55), (0.34, 0.36), (0.33, 0.35),
                 (0.48, 0.5), (0.52, 0.5), (0.4, 0.38), (0.12, 0.1)]
    else:
        spine = [(0, 0.25, 2.1), (0, 0.18, 1.5), (0, 0.1, 0.6), (0, 0.15, -0.35), (0, 0.45, -1.15), (0, 0.78, -1.65),
                 (0, 0.9, -2.1), (0, 0.84, -2.5), (0, 0.72, -2.7)]
        radii = [(0.18, 0.14), (0.55, 0.46), (0.85, 0.78), (0.88, 0.82), (0.62, 0.62), (0.56, 0.55), (0.52, 0.5),
                 (0.36, 0.34), (0.1, 0.1)]
    tube(bm, uv, spine, radii, seg=22, vscale=1.4, urep=3.0)
    out.append(finish(pre + "Body", bm))
    # Plumage: crest and tail.
    bm, uv = new_bm()
    if phoenix:
        # Swept-back flame crest (three flowing plumes, not upright spikes).
        for j in (-1, 0, 1):
            feather(bm, uv, V(j * 0.12, 2.15, -2.75), V(j * 0.12, 0.55, 1), V(1, 0, 0), 1.9 - abs(j) * 0.4, 0.34,
                    droop=-0.35, camber=0.1, segs=7)
        # Tail: short fan plus two long streamers that end in eye feathers.
        for j in (-3, -2, -1, 0, 1, 2, 3):
            feather(bm, uv, V(j * 0.12, 0.38, 2.4), V(j * 0.24, -0.04, 1), V(1, 0, 0), 2.6 - abs(j) * 0.16, 0.62,
                    droop=0.06, segs=6)
        for j in (-1, 1):
            feather(bm, uv, V(j * 0.12, 0.42, 2.5), V(j * 0.12, -0.12, 1), V(1, 0, 0), 8.0, 1.05, droop=-0.08,
                    camber=0.04, segs=16, twist=0.35 * j, eye=True)
        feather(bm, uv, V(0, 0.45, 2.5), V(0, -0.05, 1), V(1, 0, 0), 6.2, 0.9, droop=-0.1, camber=0.04, segs=14, eye=True)
    else:
        n = (-3, -2, -1, 0, 1, 2, 3) if eagle else (-2, -1, 0, 1, 2)
        for j in n:
            feather(bm, uv, V(j * 0.13, 0.3, 1.95), V(j * (0.3 if eagle else 0.18), -0.03, 1), V(1, 0, 0),
                    (2.3 if eagle else 1.9) - abs(j) * 0.1, 0.64, droop=0.04, segs=6)
    out.append(finish(pre + "Plumage", bm))
    # Beak and talons.
    bm, uv = new_bm()
    if phoenix:
        tube(bm, uv, [(0, 1.62, -3.25), (0, 1.52, -3.62), (0, 1.32, -3.92), (0, 1.12, -3.98)],
             [(0.24, 0.21), (0.17, 0.15), (0.07, 0.06), (0.012, 0.012)], seg=12)
    elif eagle:
        tube(bm, uv, [(0, 0.86, -2.45), (0, 0.8, -2.78), (0, 0.58, -3.05), (0, 0.38, -3.0)],
             [(0.22, 0.2), (0.16, 0.15), (0.08, 0.07), (0.012, 0.012)], seg=12)
    else:
        tube(bm, uv, [(0, 0.76, -2.5), (0, 0.72, -2.95), (0, 0.68, -3.3), (0, 0.58, -3.4)],
             [(0.15, 0.13), (0.11, 0.09), (0.06, 0.05), (0.012, 0.012)], seg=12)
    for s in (-1, 1):
        tube(bm, uv, [(s * 0.36, -0.48, 0.55), (s * 0.42, -0.95, 1.05), (s * 0.4, -1.05, 1.45)], [0.09, 0.065, 0.02], seg=8)
    out.append(finish(pre + "Talons", bm))
    span = 1.0 if phoenix else (1.05 if eagle else 1.15)
    out.append(finish(pre + "WingR", bird_wing(1, span, kind)))
    out.append(finish(pre + "WingL", bird_wing(-1, span, kind)))
    return out


# ---------------------------------------------------------------- membrane creatures

def poly3(a, b, c, t):
    return a.lerp(b, t * 2) if t < 0.5 else b.lerp(c, (t - 0.5) * 2)


def membrane(bm, uv, shoulder, fingers, root_back, sag=0.25, steps=10):
    lines = [[poly3(shoulder, el, tip, i / steps) for i in range(steps + 1)] for (el, tip) in fingers]
    lines.append([shoulder.lerp(root_back, i / steps) for i in range(steps + 1)])
    sub = 3
    rows = []
    for li in range(len(lines) - 1):
        for s in range(sub):
            t = s / sub
            rows.append([lines[li][i].lerp(lines[li + 1][i], t) + V(0, -sag * math.sin(math.pi * t) * (i / steps), 0)
                         for i in range(steps + 1)])
    rows.append(lines[-1])
    for sgn in (1, -1):
        vr = [[bm.verts.new(R(p) + V(0, 0, 0 if sgn > 0 else -0.015)) for p in row] for row in rows]
        for a in range(len(rows) - 1):
            for i in range(steps):
                idx = ((a, i), (a, i + 1), (a + 1, i + 1), (a + 1, i))
                if sgn < 0:
                    idx = (idx[1], idx[0], idx[3], idx[2])
                put_face(bm, uv, [vr[x][y] for (x, y) in idx], [(y / steps, x / (len(rows) - 1)) for (x, y) in idx])
    for el, tip in fingers:
        tube(bm, uv, [tuple(shoulder), tuple(el), tuple(tip)], [0.12, 0.08, 0.02], seg=6)


# ---------------------------------------------------------------- machines

def drone():
    """GuardianDrone: armoured sentinel orb, equatorial armour band, lens eye, side thruster nacelles, halo."""
    out = []
    bm, uv = new_bm()
    sphere(bm, uv, V(0, 0, 0), V(1.5, 1.32, 1.5), seg=28, rings=14)
    ring = [V(math.cos(2 * math.pi * k / 40) * 1.5, 0.0, math.sin(2 * math.pi * k / 40) * 1.5) for k in range(41)]
    tube(bm, uv, [tuple(p) for p in ring], [(0.2, 0.12)] * 41, seg=10, caps=False)
    ring2 = [V(math.cos(2 * math.pi * k / 32) * 0.95, 1.05, math.sin(2 * math.pi * k / 32) * 0.95) for k in range(33)]
    tube(bm, uv, [tuple(p) for p in ring2], [0.07] * 33, seg=8, caps=False)
    for s in (-1, 1):
        tube(bm, uv, [(s * 1.45, 0.0, 0.0), (s * 1.95, 0.0, 0.0)], [0.22, 0.18], seg=10)
        tube(bm, uv, [(s * 2.3, 0.0, -1.0), (s * 2.3, 0.0, -0.75), (s * 2.3, 0.0, 0.6), (s * 2.3, 0.0, 1.05), (s * 2.3, 0.0, 1.2)],
             [0.18, 0.4, 0.42, 0.34, 0.3], seg=16)
    tube(bm, uv, [(0, -1.25, 0.2), (0, -1.75, 0.45), (0, -2.05, 0.7)], [0.12, 0.08, 0.03], seg=8)
    out.append(finish("DroBody", bm))
    bm, uv = new_bm()
    lens = [V(math.cos(2 * math.pi * k / 32) * 0.78, 0.05 + math.sin(2 * math.pi * k / 32) * 0.78, -1.32) for k in range(33)]
    tube(bm, uv, [tuple(p) for p in lens], [0.12] * 33, seg=10, caps=False)
    sphere(bm, uv, V(0, 0.05, -1.3), V(0.66, 0.66, 0.22), seg=24, rings=8)
    out.append(finish("DroAperture", bm))
    bm, uv = new_bm()
    pts = [V(math.cos(2 * math.pi * k / 40) * 2.75, 0.35, math.sin(2 * math.pi * k / 40) * 2.75) for k in range(41)]
    tube(bm, uv, [tuple(p) for p in pts], [0.07] * 41, seg=8, caps=False)
    for s in (-1, 1):
        exh = [V(s * 2.3 + math.cos(2 * math.pi * k / 16) * 0.26, math.sin(2 * math.pi * k / 16) * 0.26, 1.24) for k in range(17)]
        tube(bm, uv, [tuple(p) for p in exh], [0.05] * 17, seg=6, caps=False)
    out.append(finish("DroHalo", bm))
    return out


def satellite():
    """SatelliteDebris: bevelled bus, two solar wings with a broken panel, dish and antenna."""
    out = []
    bm, uv = new_bm()
    tube(bm, uv, [(0, 0, 1.3), (0, 0, -1.3)], [(1.25, 1.1), (1.25, 1.1)], seg=8)
    tube(bm, uv, [(0, 0, -1.3), (0, 0, -1.6)], [(0.9, 0.8), (0.6, 0.55)], seg=8)
    for s in (-1, 1):
        tube(bm, uv, [(s * 1.25, 0, 0), (s * 1.9, 0, 0)], [0.12, 0.12], seg=8)
    tube(bm, uv, [(0.4, 1.1, 0.3), (0.55, 2.4, 0.5)], [0.05, 0.02], seg=6)
    out.append(finish("SatBody", bm))
    bm, uv = new_bm()
    for s in (-1, 1):
        for k in range(3 if s > 0 else 2):
            x0 = s * (1.95 + k * 1.55)
            front = [V(x0 + s * 1.45 * i / 4, 0, -0.95) for i in range(5)]
            back = [V(x0 + s * 1.45 * i / 4, 0, 0.95) for i in range(5)]
            if s < 0 and k == 1:
                front = [p + V(0, 0.25 * (i / 4), 0) for i, p in enumerate(front)]   # bent panel
            sheet(bm, uv, front, back, 4, 2)
    out.append(finish("SatPanels", bm))
    bm, uv = new_bm()
    prof = [(0, 0.0), (0.5, 0.06), (0.85, 0.22), (1.1, 0.45)]
    tube(bm, uv, [(0.0, 1.0, 0.6), (0.0, 1.2, 0.6)], [0.12, 0.12], seg=10)
    rad = [max(0.01, p[0]) for p in prof]
    tube(bm, uv, [(0, 1.2 + p[1], 0.6) for p in prof], rad, seg=20, caps=False)
    out.append(finish("SatDish", bm))
    return out


# ---------------------------------------------------------------- build + export

def export(objs, path):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    info = []
    for o in objs:
        o.location = (0, 0, 0)
        o.select_set(True)
        bb = [Vector(c) for c in o.bound_box]
        mn = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
        mx = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
        c = (mn + mx) / 2
        info.append("%s=Vector3.new(%.3f,%.3f,%.3f)" % (o.name, c.x, c.z, -c.y))
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True, export_texcoords=True,
                              export_normals=True)
    return ", ".join(info)


def scene():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    return sc


def build_all(which):
    scene()
    report = {}
    groups = {
        "Phx": "phoenix", "Gull": "gull", "Eagle": "eagle",
    }
    for pre in which:
        if pre in groups:
            objs = bird(pre, groups[pre])
        elif pre == "Dro":
            objs = drone()
        elif pre == "Sat":
            objs = satellite()
        else:
            continue
        report[pre] = export(objs, OUT + "FlyHigh_Creature_" + pre + "_v5.glb")
    return report
