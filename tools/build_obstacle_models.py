"""Original Fly High obstacle meshes. Run in Blender via the Blender MCP.

Coordinates are authored in Roblox studs, X right / Y up / -Z forward;
converted to Blender metres X right / +Y forward / Z up at mesh creation.
The user's existing scene is left untouched. This script owns only a new scene.
"""
import bpy
import bmesh
import math
import json
from mathutils import Vector
OUT = 'E:/Antigravity/Fly High/assets/models/obstacles/generated/'
SCENE_NAME = 'FlyHigh_Obstacle_Atelier'
if bpy.data.scenes.get(SCENE_NAME):
    raise RuntimeError('Atelier already exists; inspect it before rebuilding')
scene = bpy.data.scenes.new(SCENE_NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
PALETTE = {'navy': '18243C', 'ink': '101827', 'white': 'FFF5DA', 'ivory': 'E5D6B6', 'teal': '227987', 'deepteal': '124A5B', 'turquoise': '57C9CE', 'ice': 'A8EDF1', 'gold': 'F3BC53', 'amber': 'D48628', 'brown': '68442E', 'bronze': '9B7954', 'red': 'B83934', 'orange': 'F17D32', 'yellow': 'FFE58A', 'purple': '60477E', 'violet': 'A384C5', 'plum': '362747', 'cloth': '302E51', 'blue': '34659B', 'steel': 'A7BBC8', 'rock': '444550', 'basalt': '282C3B', 'stone': 'D0C2A4', 'sand': 'A89473', 'moss': '567B67', 'silver': 'D4E4E6', 'darkice': '3C99B6', 'blueglass': '76B7CC', 'lavender': 'CBB8E1', 'black': '080D16', 'lava': 'F69B45'}
names = list(PALETTE)

def rgb(key):
    s = PALETTE[key]
    return tuple((int(s[i:i + 2], 16) / 255 for i in (0, 2, 4)))
image = bpy.data.images.new('FH_Obstacle_Palette', width=256, height=256, alpha=True)
pixels = [0.0] * (256 * 256 * 4)
for y in range(256):
    for x in range(256):
        idx = y // 32 * 8 + x // 32
        key = names[idx] if idx < len(names) else 'white'
        col = rgb(key)
        p = (y * 256 + x) * 4
        pixels[p:p + 4] = [*col, 1]
image.pixels = pixels
image.filepath_raw = OUT + 'obstacle_palette.png'
image.file_format = 'PNG'
image.save()
material = bpy.data.materials.new('FH_Obstacle_Enamel')
material.use_nodes = True
shader = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
shader.inputs['Roughness'].default_value = 0.46
tex = material.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = image
tex.interpolation = 'Closest'
material.node_tree.links.new(tex.outputs['Color'], shader.inputs['Base Color'])

def v3(v):
    return Vector(v)

def lerp(a, b, t):
    return a * (1 - t) + b * t

def catmull(points, steps=5):
    pts = [v3(p) for p in points]
    out = []
    for i in range(len(pts) - 1):
        a = pts[max(0, i - 1)]
        b = pts[i]
        c = pts[i + 1]
        d = pts[min(len(pts) - 1, i + 2)]
        for k in range(steps):
            t = k / steps
            out.append((2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t) * 0.5)
    out.append(pts[-1])
    return out

def _geo_add(self, verts, faces, color, smooth=True):
    n = len(self['vertices'])
    self['vertices'].extend(verts)
    self['faces'].extend([tuple((n + j for j in f)) for f in faces])
    self['colors'].extend([color] * len(faces))
    self['smooth'].extend([smooth] * len(faces))

def _geo_tube(self, points, radii, color, sides=12, steps=4, flat=False):
    pts = catmull(points, steps)
    rr = []
    for i in range(len(points) - 1):
        a = radii[i]
        b = radii[i + 1]
        a = (a, a) if isinstance(a, (int, float)) else a
        b = (b, b) if isinstance(b, (int, float)) else b
        for k in range(steps):
            rr.append((lerp(a[0], b[0], k / steps), lerp(a[1], b[1], k / steps)))
    last = radii[-1]
    rr.append((last, last) if isinstance(last, (int, float)) else last)
    verts = []
    faces = []
    for i, p in enumerate(pts):
        tangent = (pts[min(i + 1, len(pts) - 1)] - pts[max(0, i - 1)]).normalized()
        ref = Vector((0, 1, 0)) if abs(tangent.y) < 0.92 else Vector((0, 0, 1))
        u = tangent.cross(ref).normalized()
        w = tangent.cross(u).normalized()
        for j in range(sides):
            a = j * math.tau / sides
            verts.append(tuple(p + u * (math.cos(a) * rr[i][0]) + w * (math.sin(a) * rr[i][1])))
    for i in range(len(pts) - 1):
        for j in range(sides):
            faces.append((i * sides + j, i * sides + (j + 1) % sides, (i + 1) * sides + (j + 1) % sides, (i + 1) * sides + j))
    faces.extend([tuple(reversed(range(sides))), tuple(((len(pts) - 1) * sides + j for j in range(sides)))])
    _geo_add(self, verts, faces, color, not flat)

def _geo_ellipsoid(self, center, size, color, segments=20, rings=12):
    cx, cy, cz = center
    sx, sy, sz = size
    verts = [(cx, cy + sy, cz)]
    for i in range(1, rings):
        p = math.pi * i / rings
        for j in range(segments):
            a = j * math.tau / segments
            verts.append((cx + sx * math.sin(p) * math.cos(a), cy + sy * math.cos(p), cz + sz * math.sin(p) * math.sin(a)))
    bottom = len(verts)
    verts.append((cx, cy - sy, cz))
    faces = []
    for j in range(segments):
        faces.append((0, 1 + (j + 1) % segments, 1 + j))
    for i in range(rings - 2):
        for j in range(segments):
            a = 1 + i * segments + j
            b = 1 + i * segments + (j + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    for j in range(segments):
        faces.append((bottom, 1 + (rings - 2) * segments + j, 1 + (rings - 2) * segments + (j + 1) % segments))
    _geo_add(self, verts, faces, color)

def _geo_box(self, center, size, color, bevel=0.08):
    half = Vector(size) * 0.5
    inner = Vector(tuple((max(0.001, x - bevel) for x in half)))
    verts = []
    faces = []
    n = 4
    for axis in range(3):
        others = [i for i in range(3) if i != axis]
        for sign in (-1, 1):
            offset = len(verts)
            for i in range(n + 1):
                for j in range(n + 1):
                    q = Vector((0, 0, 0))
                    q[axis] = sign * half[axis]
                    q[others[0]] = (2 * i / n - 1) * half[others[0]]
                    q[others[1]] = (2 * j / n - 1) * half[others[1]]
                    cl = Vector(tuple((max(-inner[k], min(inner[k], q[k])) for k in range(3))))
                    delta = q - cl
                    if delta.length > 0:
                        q = cl + delta.normalized() * bevel
                    verts.append(tuple(q + Vector(center)))
            for i in range(n):
                for j in range(n):
                    a = offset + i * (n + 1) + j
                    faces.append((a, a + 1, a + n + 2, a + n + 1))
    _geo_add(self, verts, faces, color)

def _geo_crystal(self, center, radius, height, color, sides=6, lean=0):
    verts = []
    for y, r in [(-height * 0.5, radius * 0.35), (-height * 0.32, radius), (height * 0.27, radius * 0.86), (height * 0.5, 0)]:
        for j in range(sides):
            a = math.tau * j / sides
            verts.append((center[0] + math.cos(a) * r + lean * (y / height + 0.5), center[1] + y, center[2] + math.sin(a) * r))
    faces = []
    for ring in range(3):
        for j in range(sides):
            faces.append((ring * sides + j, ring * sides + (j + 1) % sides, (ring + 1) * sides + (j + 1) % sides, (ring + 1) * sides + j))
    faces.extend([tuple(reversed(range(sides))), tuple((3 * sides + j for j in range(sides)))])
    _geo_add(self, verts, faces, color, False)

def _geo_wing(self, outline, color, side=1, y=0.35, thickness=0.12):
    contour = catmull([(x, 0, z) for x, z in outline + [outline[0]]], 3)[:-1]
    center = sum(contour, Vector((0, 0, 0))) / len(contour)
    verts = []
    faces = []
    n = len(contour)
    for upper in (1, -1):
        verts.append((side * center.x, y + upper * thickness * 2, center.z))
        for p in contour:
            verts.append((side * p.x, y + upper * thickness, p.z))
    for j in range(n):
        a = 1 + j
        b = 1 + (j + 1) % n
        faces.extend([(0, a, b), (n + 1, n + 1 + b, n + 1 + a), (a, n + 1 + a, n + 1 + b, b)])
    _geo_add(self, verts, faces, color)

def _geo_ring(self, center, radius, tube, color, plane='xy', segments=28):
    points = []
    for j in range(segments + 1):
        a = math.tau * j / segments
        p = (math.cos(a) * radius, math.sin(a) * radius, 0) if plane == 'xy' else (math.cos(a) * radius, 0, math.sin(a) * radius)
        points.append(tuple(Vector(center) + Vector(p)))
    _geo_tube(self, points, [tube] * len(points), color, sides=8, steps=1)

def _geo_rock(self, center, size, color, seed=1, craters=False):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1)
    verts = []
    for v in bm.verts:
        p = v.co.normalized()
        r = 1 + 0.065 * math.sin(p.x * 9 + seed) * math.cos(p.z * 8 - seed)
        if craters:
            for axis in (Vector((0.7, 0.45, -0.6)).normalized(), Vector((-0.45, 0.6, -0.35)).normalized()):
                d = (p - axis).length
                r -= 0.17 * math.exp(-d * d / 0.06)
        verts.append(tuple(Vector(center) + Vector((p.x * size[0], p.y * size[1], p.z * size[2])) * r))
    bm.verts.ensure_lookup_table()
    faces = [tuple((v.index for v in f.verts)) for f in bm.faces]
    bm.free()
    _geo_add(self, verts, faces, color, craters)

def Geometry():
    return {'vertices': [], 'faces': [], 'colors': [], 'smooth': []}
models = {}

def finish(name, components):
    root = bpy.data.objects.new(name, None)
    scene.collection.objects.link(root)
    records = []
    for part, g in components.items():
        if not g['faces']:
            continue
        mesh = bpy.data.meshes.new(name + '__' + part + '_geometry')
        vertices = [(v[0] * 0.28, -v[2] * 0.28, v[1] * 0.28) for v in g['vertices']]
        mesh.from_pydata(vertices, [], g['faces'])
        mesh.update()
        uv = mesh.uv_layers.new(name='PaletteUV')
        for poly, key, smooth in zip(mesh.polygons, g['colors'], g['smooth']):
            idx = names.index(key)
            coord = ((idx % 8 + 0.5) / 8, (idx // 8 + 0.5) / 8)
            for li in poly.loop_indices:
                uv.data[li].uv = coord
            poly.use_smooth = smooth
        mesh.materials.append(material)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-05)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        obj = bpy.data.objects.new(name + '__' + part, mesh)
        scene.collection.objects.link(obj)
        obj.parent = root
        mesh.calc_loop_triangles()
        triangles = len(mesh.loop_triangles)
        if triangles > 20000:
            raise RuntimeError(name + ' ' + part + ' exceeds mesh triangle limit')
        records.append({'name': obj.name, 'triangles': triangles})
    models[name] = {'root': root, 'parts': records}
    return root

def eyes(g, head, z, y, x, color='ink', size=0.21):
    for s in (-1, 1):
        _geo_ellipsoid(g, (s * x, y, z), (0.12, size, size * 0.85), color, 12, 8)
        _geo_ellipsoid(g, (s * (x + 0.08), y + 0.06, z - 0.04), (0.045, size * 0.28, size * 0.25), 'white', 10, 6)

def bird(name, eagle=False, phoenix=False):
    body = Geometry()
    left = Geometry()
    right = Geometry()
    main = 'red' if phoenix else 'brown' if eagle else 'white'
    accent = 'gold' if phoenix else 'ink' if eagle else 'steel'
    _geo_tube(body, [(0, 0, 1.9), (0, 0, 0.8), (0, 0.1, -0.4), (0, 0.55, -1.3), (0, 0.65, -1.9), (0, 0.5, -2.45)], [(0.12, 0.12), (0.88, 0.8), (0.92, 0.87), (0.48, 0.55), (0.58, 0.55), (0.18, 0.22)], main, 16, 4)
    _geo_tube(body, [(0, 0.45, -2.22), (0, 0.4, -2.7), (0, 0.2 if eagle else 0.34, -2.92)], [(0.32, 0.21), (0.2, 0.17), (0.02, 0.025)], 'gold', 12, 4)
    eyes(body, None, -1.95, 0.76, 0.48, size=0.17)
    if eagle:
        _geo_ellipsoid(body, (0, 0.72, -1.91), (0.5, 0.11, 0.45), 'ivory', 16, 8)
    outline = [(0.68, -0.35), (1.9, -1.0), (3.3, -1.23), (4.5, -0.8), (5.05, 0.1), (4.4, 1.0), (3.1, 1.3), (1.65, 1.0), (0.68, 0.8)]
    for s, w in [(-1, left), (1, right)]:
        _geo_wing(w, outline, main, s, y=0.4, thickness=0.13)
        for j in range(5):
            x = 2.15 + j * 0.53
            _geo_tube(w, [(s * x, 0.4, 0.1), (s * (x + 0.4), 0.44, 1.0), (s * (x + 0.35), 0.32, 2.0 + (4 - j) * 0.14)], [(0.32, 0.13), (0.29, 0.12), (0.035, 0.035)], accent, 10, 3)
        for j in range(3):
            x = 1.05 + j * 0.75
            _geo_tube(w, [(s * x, 0.55, -0.35), (s * (x + 0.65), 0.6, -0.5), (s * (x + 1.1), 0.4, -0.3)], [(0.19, 0.075), (0.22, 0.08), (0.03, 0.03)], 'orange' if phoenix else main, 10, 3)
        _geo_tube(body, [(s * 0.38, -0.55, 0.8), (s * 0.48, -0.95, 1.35), (s * 0.44, -1.0, 1.75)], [0.09, 0.07, 0.025], 'gold', 8, 3)
    for j in (-1, 0, 1):
        points = [(j * 0.35, 0, 1.2), (j * 0.7, 0.1, 2.7), (j * 0.9, 1.2 if phoenix else 0.1, 5.3 if phoenix else 3.35), (j * 0.75, 1.7 if phoenix else 0.05, 7 if phoenix else 3.65)]
        _geo_tube(body, points, [(0.18, 0.09), (0.28, 0.1), (0.2, 0.08), (0.018, 0.018)], accent, 10, 5)
    if phoenix:
        for j in (-1, 0, 1):
            _geo_tube(body, [(j * 0.2, 1.0, -1.8), (j * 0.28, 1.75, -1.55), (j * 0.3, 2.2 - abs(j) * 0.25, -1.2)], [(0.16, 0.12), (0.15, 0.09), (0.015, 0.015)], 'gold', 10, 4)
        _geo_ellipsoid(body, (0, -0.2, -0.65), (0.58, 0.57, 0.52), 'orange', 16, 10)
    finish(name, {'Body': body, 'WingL': left, 'WingR': right})

def wyvern():
    b = Geometry()
    l = Geometry()
    r = Geometry()
    _geo_tube(b, [(0, 0, 2), (0, 0.05, 0.9), (0, 0.25, -0.4), (0, 0.9, -1.35), (0, 1.5, -2.15), (0, 1.5, -3.15), (0, 1.28, -3.9)], [(0.15, 0.2), (0.9, 0.98), (0.88, 0.9), (0.45, 0.65), (0.62, 0.63), (0.64, 0.4), (0.2, 0.13)], 'teal', 16, 5)
    _geo_tube(b, [(0, -0.18, -0.7), (0, 0.45, -1.4), (0, 1, -2.2), (0, 1.06, -3.35)], [(0.47, 0.1), (0.27, 0.1), (0.34, 0.1), (0.37, 0.08)], 'ice', 12, 4)
    _geo_tube(b, [(0, 0, 1.8), (0.2, -0.1, 3.4), (0.7, 0.1, 4.8), (1.1, 0.55, 6.1), (0.6, 1.05, 6.8)], [(0.56, 0.49), (0.42, 0.35), (0.26, 0.22), (0.16, 0.12), (0.015, 0.015)], 'deepteal', 12, 5)
    for s in (-1, 1):
        _geo_tube(b, [(s * 0.75, -0.25, 0.65), (s * 1.05, -0.8, 0.8), (s * 0.9, -1.2, 0.2), (s * 1.0, -1.4, -0.3)], [0.35, 0.31, 0.18, 0.17], 'deepteal', 12, 4)
        for j in (-1, 0, 1):
            _geo_tube(b, [(s * 1 + j * 0.12, -1.4, -0.15), (s * 1 + j * 0.18, -1.43, -0.55), (s * 1 + j * 0.2, -1.35, -0.82)], [0.075, 0.065, 0.005], 'ivory', 8, 3)
        _geo_tube(b, [(s * 0.46, 1.9, -2.3), (s * 0.65, 2.55, -1.85), (s * 0.72, 2.85, -1.5)], [0.19, 0.12, 0.008], 'ice', 10, 4)
        _geo_tube(b, [(s * 0.52, 1.65, -2.8), (s * 0.53, 1.7, -3.15)], [0.1, 0.04], 'deepteal', 10, 3)
        _geo_tube(b, [(s * 0.33, 1.22, -3.38), (s * 0.46, 1.13, -3.03), (s * 0.45, 1.12, -2.6)], [0.025, 0.035, 0.02], 'ink', 8, 3)
        _geo_ellipsoid(b, (s * 0.31, 1.46, -3.65), (0.095, 0.075, 0.035), 'ink', 12, 8)
    eyes(b, None, -2.8, 1.68, 0.56, 'gold', 0.17)
    for j in range(5):
        _geo_crystal(b, (0, 1.1 - j * 0.1, 0.0 + j * 0.65), 0.21, 0.8 - j * 0.08, 'turquoise', 6, 0.03)
    outline = [(0.68, -0.15), (1.5, -1), (3, -1.9), (5, -1.25), (5.8, -0.1), (4.65, 0.55), (4.9, 1.5), (3.65, 1.25), (3.0, 2.5), (2.1, 1.5), (0.7, 1.3)]
    for s, w in [(-1, l), (1, r)]:
        _geo_wing(w, outline, 'turquoise', s, 0.65, 0.11)
        for end in [(5.65, -0.08), (4.65, 1.4), (3, 2.38)]:
            _geo_tube(w, [(s * 0.68, 0.7, 0.1), (s * 1.6, 0.82, -0.8), (s * end[0], 0.69, end[1])], [0.13, 0.11, 0.025], 'deepteal', 10, 4)
        _geo_crystal(w, (s * 2.2, 1.05, -0.65), 0.19, 0.58, 'ice', 6, s * 0.05)
    finish('CrystalWyvern', {'Body': b, 'WingL': l, 'WingR': r})

def phantom():
    b = Geometry()
    arms = Geometry()
    verts = []
    faces = []
    steps = 15
    sides = 32
    for i in range(steps):
        t = i / (steps - 1)
        y = 1.0 - t * 4.1
        width = 0.48 + math.sin(t * math.pi) * 0.47 + t * 0.62
        if t < 0.2:
            width += 0.55 * math.sin(t / 0.2 * math.pi)
        for j in range(sides):
            a = math.tau * j / sides
            fold = 1 + 0.085 * math.cos(a * 7 + t)
            yy = y + max(0, t - 0.65) / 0.35 * (0.3 * math.sin(a * 3) + 0.18 * math.cos(a * 5))
            verts.append((math.cos(a) * width * fold, yy, 0.25 + math.sin(a) * width * 0.62))
    for i in range(steps - 1):
        for j in range(sides):
            faces.append((i * sides + j, i * sides + (j + 1) % sides, (i + 1) * sides + (j + 1) % sides, (i + 1) * sides + j))
    faces.extend([tuple(reversed(range(sides))), tuple(((steps - 1) * sides + j for j in range(sides)))])
    _geo_add(b, verts, faces, 'cloth')
    _geo_ellipsoid(b, (0, 1.35, -0.14), (1.08, 1.28, 0.8), 'plum', 24, 14)
    _geo_ellipsoid(b, (0, 1.24, -0.85), (0.75, 0.88, 0.12), 'black', 24, 14)
    rim = [(0.85 * math.cos(a * math.tau / 32), 1.25 + 1.04 * math.sin(a * math.tau / 32), -0.93 + 0.15 * math.sin(a * math.tau / 32)) for a in range(33)]
    _geo_tube(b, rim, [0.13] * len(rim), 'purple', 10, 1)
    for s in (-1, 1):
        _geo_tube(b, [(s * 0.18, 1.28, -0.99), (s * 0.38, 1.34, -1), (s * 0.53, 1.39, -0.97)], [0.055, 0.07, 0.025], 'lavender', 10, 4)
        _geo_tube(arms, [(s * 0.8, 0.45, 0.0), (s * 1.5, 0.16, -0.15), (s * 1.95, -0.25, -0.5)], [(0.38, 0.37), (0.27, 0.25), (0.15, 0.14)], 'purple', 12, 5)
        for j in range(3):
            _geo_tube(arms, [(s * 1.95, -0.24, -0.47 - j * 0.1), (s * (2.2 + j * 0.07), -0.5, -0.6 - j * 0.1), (s * (2.18 + j * 0.08), -0.85, -0.65 - j * 0.1)], [0.07, 0.055, 0.012], 'lavender', 8, 4)
        _geo_tube(b, [(s * 0.7, 0.7, -0.4), (s * 0.75, -0.35, -0.55), (s * 0.55, -1.3, -0.5), (s * 0.83, -2.7, -0.25)], [0.045, 0.04, 0.035, 0.008], 'violet', 8, 5)
    finish('ShadowPhantom', {'Body': b, 'Arms': arms})

def bat():
    b = Geometry()
    l = Geometry()
    r = Geometry()
    _geo_tube(b, [(0, -0.4, 1.35), (0, -0.15, 0.5), (0, 0.15, -0.5), (0, 0.55, -1.2), (0, 0.4, -1.65)], [(0.08, 0.07), (0.65, 0.85), (0.7, 0.9), (0.65, 0.6), (0.3, 0.2)], 'plum', 16, 4)
    _geo_ellipsoid(b, (0, 0.15, -1.45), (0.4, 0.3, 0.25), 'purple')
    for s in (-1, 1):
        _geo_tube(b, [(s * 0.4, 0.9, -1), (s * 0.63, 1.6, -0.95), (s * 0.68, 2.05, -0.8)], [(0.25, 0.22), (0.2, 0.12), (0.015, 0.015)], 'purple', 10, 5)
        _geo_tube(b, [(s * 0.24, 0.08, -1.6), (s * 0.25, -0.17, -1.65)], [0.08, 0.006], 'ivory', 8, 2)
        _geo_tube(b, [(s * 0.35, -0.65, 0.8), (s * 0.45, -0.9, 1.25)], [0.1, 0.025], 'bronze', 8, 3)
    eyes(b, None, -1.28, 0.65, 0.59, 'ice', 0.19)
    outline = [(0.6, -0.4), (1.7, -1.2), (3.2, -1.8), (5.4, -1.2), (5.8, -0.3), (4.65, 0.15), (4.7, 1.1), (3.7, 0.85), (3, 1.3), (2.8, 2), (1.9, 1.4), (0.6, 1.3)]
    for s, w in [(-1, l), (1, r)]:
        _geo_wing(w, outline, 'purple', s, 0.3, 0.11)
        for end in [(5.7, -0.3), (4.6, 1.05), (2.8, 1.9)]:
            _geo_tube(w, [(s * 0.6, 0.37, -0.3), (s * 1.65, 0.5, -1.05), (s * end[0], 0.35, end[1])], [0.09, 0.08, 0.018], 'violet', 9, 4)
    finish('StormBat', {'Body': b, 'WingL': l, 'WingR': r})

def bee():
    b = Geometry()
    l = Geometry()
    r = Geometry()
    _geo_tube(b, [(0, 0, 2.7), (0, 0, 1.9), (0, 0, 1.0), (0, 0, 0.15)], [(0.035, 0.05), (0.65, 0.63), (0.9, 0.85), (0.67, 0.7)], 'gold', 20, 5)
    for z, rx, ry in [(1.85, 0.66, 0.65), (1.08, 0.86, 0.82), (0.35, 0.77, 0.76)]:
        _geo_tube(b, [(0, 0, z - 0.14), (0, 0, z + 0.14)], [(rx, ry), (rx * 0.96, ry * 0.96)], 'ink', 20, 1)
    _geo_ellipsoid(b, (0, 0, -0.2), (0.82, 0.88, 0.8), 'brown')
    _geo_ellipsoid(b, (0, 0.08, -1.2), (0.8, 0.73, 0.7), 'gold')
    _geo_tube(b, [(0, 0, 2.6), (0, -0.1, 3.1)], [0.18, 0.005], 'ink', 12, 2)
    for s in (-1, 1):
        _geo_ellipsoid(b, (s * 0.6, 0.18, -1.57), (0.3, 0.42, 0.28), 'ink')
        _geo_ellipsoid(b, (s * 0.67, 0.31, -1.77), (0.09, 0.13, 0.065), 'white', 12, 8)
        _geo_tube(b, [(s * 0.36, 0.67, -1.35), (s * 0.58, 1.25, -1.5), (s * 0.78, 1.45, -1.86)], [0.06, 0.055, 0.04], 'ink', 8, 5)
        _geo_ellipsoid(b, (s * 0.78, 1.45, -1.86), (0.12, 0.12, 0.12), 'amber', 12, 8)
        for j in range(3):
            _geo_tube(b, [(s * 0.62, -0.42, -0.55 + j * 0.6), (s * 1.02, -0.9, -0.4 + j * 0.6), (s * 1.0, -1.25, 0.05 + j * 0.6)], [0.09, 0.065, 0.035], 'ink', 9, 4)
    for s, w in [(-1, l), (1, r)]:
        _geo_tube(w, [(s * 0.5, 0.55, -0.4), (s * 1.7, 1.05, -1.05), (s * 3.1, 1.25, -1.35)], [(0.15, 0.07), (0.65, 0.1), (0.03, 0.03)], 'silver', 12, 5)
        _geo_tube(w, [(s * 0.5, 0.55, 0.3), (s * 1.5, 0.8, 0.85), (s * 2.65, 0.95, 1.4)], [(0.13, 0.06), (0.48, 0.09), (0.02, 0.02)], 'blueglass', 12, 5)
        _geo_tube(w, [(s * 0.6, 0.63, -0.4), (s * 1.8, 1.16, -1.1), (s * 2.7, 1.25, -1.3)], [0.025, 0.024, 0.01], 'white', 8, 4)
    finish('FireBee', {'Body': b, 'WingL': l, 'WingR': r})

def drone():
    b = Geometry()
    eye = Geometry()
    _geo_box(b, (0, 0, 0), (3.8, 1.8, 2.8), 'bronze', 0.28)
    _geo_box(b, (0, 0.55, 0.05), (3.2, 0.85, 2.5), 'stone', 0.24)
    _geo_box(b, (0, -0.6, 0.25), (2.8, 0.65, 2.2), 'deepteal', 0.2)
    _geo_ring(b, (0, 0.08, -1.45), 0.73, 0.13, 'gold')
    _geo_ellipsoid(b, (0, 0.08, -1.46), (0.6, 0.61, 0.18), 'ink')
    _geo_ellipsoid(eye, (0, 0.08, -1.66), (0.38, 0.39, 0.1), 'turquoise')
    _geo_ellipsoid(eye, (-0.12, 0.23, -1.75), (0.085, 0.09, 0.035), 'white')
    for s in (-1, 1):
        _geo_box(b, (s * 2.15, -0.03, 0.3), (1.2, 0.88, 1.8), 'bronze', 0.22)
        _geo_ring(b, (s * 2.1, -0.33, 0.35), 0.4, 0.12, 'ink', 'xz')
        _geo_ellipsoid(b, (s * 2.1, -0.61, 0.35), (0.3, 0.08, 0.3), 'turquoise')
        _geo_box(b, (s * 1.0, 0.97, 0.0), (0.11, 0.06, 1.8), 'gold', 0.025)
    finish('GuardianDrone', {'Body': b, 'Aperture': eye})

def satellite():
    b = Geometry()
    p = Geometry()
    dish = Geometry()
    _geo_box(b, (0, 0, 0), (2.55, 2.45, 2.35), 'gold', 0.16)
    _geo_box(b, (0, 1.1, 0), (2.7, 0.28, 2.5), 'silver', 0.06)
    _geo_box(b, (0, -1.1, 0), (2.65, 0.25, 2.45), 'steel', 0.06)
    for x in (-0.7, 0, 0.7):
        _geo_box(b, (x, 0, -1.19), (0.025, 1.9, 0.025), 'amber', 0.006)
    for s in (-1, 1):
        _geo_tube(b, [(s * 1.2, 0, 0), (s * 3.6, 0, 0)], [0.095, 0.095], 'steel', 10, 2)
        length = 3.5 if s < 0 else 2.7
        x = s * (1.8 + length / 2)
        _geo_box(p, (x, 0.0, 0.0), (length, 0.16, 2.7), 'ink', 0.06)
        for a in range(4):
            for z in (-0.84, 0, 0.84):
                _geo_box(p, (x + (a - 1.5) * length / 4, 0.1, z), (length / 4 - 0.1, 0.025, 0.73), 'blue', 0.015)
        _geo_box(p, (x, 0, -1.37), (length + 0.1, 0.2, 0.07), 'silver', 0.02)
        _geo_box(p, (x, 0, 1.37), (length + 0.1, 0.2, 0.07), 'silver', 0.02)
    verts = []
    faces = []
    segments = 32
    rings = 7
    for back in (False, True):
        for i in range(rings):
            r = 0.02 + 1.1 * i / (rings - 1)
            for j in range(segments):
                a = math.tau * j / segments
                verts.append((math.cos(a) * r, 0.95 + math.sin(a) * r, -1.45 - 0.43 * (r / 1.1) ** 2 + (0.06 if back else 0)))
    n = rings * segments
    for k in range(2):
        for i in range(rings - 1):
            for j in range(segments):
                a = k * n + i * segments + j
                d = k * n + i * segments + (j + 1) % segments
                faces.append((a, d, d + segments, a + segments))
    for j in range(segments):
        a = (rings - 1) * segments + j
        d = (rings - 1) * segments + (j + 1) % segments
        faces.append((a, a + n, d + n, d))
        faces.append((j, (j + 1) % segments, n + (j + 1) % segments, n + j))
    _geo_add(dish, verts, faces, 'silver')
    for s in (-1, 1):
        _geo_tube(dish, [(s * 0.8, 1.6, -1.7), (s * 0.35, 1.2, -2.3), (0, 0.95, -2.55)], [0.045, 0.045, 0.055], 'steel', 8, 3)
    _geo_ellipsoid(dish, (0, 0.95, -2.56), (0.13, 0.13, 0.1), 'amber', 12, 8)
    _geo_tube(b, [(1.15, 0.5, 0.8), (1.6, 1.1, 1.1), (1.8, 1.2, 1.8)], [0.045, 0.04, 0.012], 'ink', 8, 4)
    finish('SatelliteDebris', {'Body': b, 'Panels': p, 'Dish': dish})

def stones():
    for i in range(3):
        g = Geometry()
        _geo_rock(g, (0, 0, 0), (1.75, 2.35, 1.6), 'ice' if i != 1 else 'blueglass', i + 1)
        _geo_tube(g, [(-0.4, 1.5, -0.95), (-0.15, 0.5, -1.5), (0.3, -0.1, -1.6), (0.18, -1.0, -1.2)], [0.025, 0.035, 0.025, 0.01], 'darkice', 7, 3)
        _geo_tube(g, [(-0.15, 0.5, -1.5), (-0.8, 0.3, -1.3), (-1.3, 0.1, -0.85)], [0.025, 0.02, 0.008], 'white', 7, 3)
        finish('Hailstone' if i == 0 else 'Hailstone' + str(i + 1), {'Body': g})
    g = Geometry()
    _geo_rock(g, (0, 0, 0), (3.8, 4.5, 3.5), 'basalt', 4, True)
    for s in (-1, 1):
        _geo_tube(g, [(s * 0.4, 3.3, -2.3), (s * 1.3, 1.8, -2.9), (s * 1.7, 0.6, -3.1), (s * 2.3, -0.5, -2.7), (s * 2, -2.4, -1.9)], [0.065, 0.11, 0.085, 0.065, 0.02], 'lava', 8, 3)
        _geo_tube(g, [(s * 1.5, 1, -3), (s * 0.8, 0.5, -3.28), (s * 0.2, -0.2, -3.25)], [0.05, 0.04, 0.01], 'orange', 8, 3)
    finish('Meteor', {'Body': g})
    g = Geometry()
    _geo_crystal(g, (0, 0, 0), 1.65, 9.0, 'turquoise', 6, 0.45)
    _geo_crystal(g, (-0.25, 0.1, -0.3), 0.65, 6.4, 'ice', 6, 0.15)
    finish('ChargedCrystal', {'Body': g})
    g = Geometry()
    _geo_tube(g, [(0, 0, 4.4), (0, 0, 2.4), (0, 0, -2.4), (0, 0, -4.4)], [0.16, 0.58, 0.47, 0.003], 'violet', 6, 1, True)
    finish('MagicSpike', {'Body': g})

def ruins():
    for idx in range(3):
        g = Geometry()
        _geo_rock(g, (0, -6.5, 0), (6.5, 3.0, 5.3), 'rock', idx + 2)
        _geo_box(g, (0, -4.2, 0), (11.5, 1.2, 9.4), 'sand', 0.22)
        _geo_box(g, (0, -3.45, 0), (10.5, 0.45, 8.6), 'stone', 0.1)
        if idx == 0:
            for s in (-1, 1):
                _geo_tube(g, [(s * 3, -3.2, 0), (s * 3, 1.0, 0)], [0.8, 0.72], 'stone', 16, 1)
                _geo_box(g, (s * 3, -2.85, 0), (1.85, 0.7, 1.85), 'sand', 0.14)
                _geo_box(g, (s * 3, 1.25, 0), (1.85, 0.65, 1.85), 'stone', 0.14)
            for k in range(8):
                a = k * math.pi / 10
                b = (k + 0.94) * math.pi / 10
                vertices = []
                for z in (-0.75, 0.75):
                    for radius in (2.2, 3.7):
                        for angle in (a, b):
                            vertices.append((math.cos(angle) * radius, 1.3 + math.sin(angle) * radius, z))
                _geo_add(g, vertices, [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)], 'stone', False)
        elif idx == 1:
            _geo_tube(g, [(0, -3.25, 0), (0.12, 1.5, 0.1), (0.28, 4.2, 0.1)], [1.25, 1.1, 0.94], 'stone', 20, 1)
            for y in (-2.7, 1.5, 3.7):
                _geo_box(g, (0.1, y, 0), (2.9, 0.45, 2.9), 'sand', 0.14)
            _geo_box(g, (0.2, 4.35, 0), (3.5, 0.6, 3.5), 'stone', 0.15)
            _geo_box(g, (2.6, -2.9, 1.5), (3.6, 0.85, 1.6), 'sand', 0.14)
        else:
            _geo_box(g, (0, -1.9, 0), (7.4, 2.1, 5.9), 'sand', 0.2)
            _geo_box(g, (0, -0.65, 0), (8.8, 0.55, 7.0), 'stone', 0.14)
            _geo_box(g, (-0.3, 0.0, -0.4), (6.4, 0.7, 4.8), 'stone', 0.12)
            for s in (-1, 1):
                _geo_box(g, (s * 2.2, 0.7, 0.0), (1.0, 0.75, 4), 'sand', 0.12)
        for s in (-1, 1):
            _geo_box(g, (0, -3.27, s * 4.2), (9.6, 0.12, 0.1), 'bronze', 0.02)
        _geo_ellipsoid(g, (-3.2, -2.95, 2.5), (1.4, 0.18, 0.6), 'moss', 16, 6)
        finish('Ruin' + str(idx + 1), {'Body': g})
wyvern()
phantom()
bird('CelestialPhoenix', phoenix=True)
bird('Seagull')
bird('Eagle', eagle=True)
bat()
bee()
drone()
satellite()
stones()
ruins()
manifest = {'version': 1, 'unit': 'metres', 'studsPerMetre': 1 / 0.28, 'forward': 'Roblox -Z / Blender +Y', 'palette': 'obstacle_palette.png', 'models': {}}
for name, record in models.items():
    bpy.ops.object.select_all(action='DESELECT')
    root = record['root']
    root.select_set(True)
    for obj in root.children:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=OUT + name + '.glb', export_format='GLB', use_selection=True, use_active_scene=True, export_yup=True, export_apply=True, export_materials='EXPORT', export_texcoords=True, export_normals=True, export_cameras=False, export_lights=False)
    verts = [obj.matrix_world @ v.co for obj in root.children if obj.type == 'MESH' for v in obj.data.vertices]
    mn = [min((v[i] for v in verts)) for i in range(3)]
    mx = [max((v[i] for v in verts)) for i in range(3)]
    manifest['models'][name] = {'parts': record['parts'], 'sizeMetres': [mx[i] - mn[i] for i in range(3)], 'sizeStudsXYZ': [(mx[0] - mn[0]) / 0.28, (mx[2] - mn[2]) / 0.28, (mx[1] - mn[1]) / 0.28]}
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT + 'FlyHigh_Obstacles.glb', export_format='GLB', use_selection=True, use_active_scene=True, export_yup=True, export_apply=True, export_materials='EXPORT', export_cameras=False, export_lights=False)
bpy.ops.wm.save_as_mainfile(filepath=OUT + 'FlyHigh_Obstacle_Atelier.blend', copy=True)
print(json.dumps({'scene': scene.name, 'modelCount': len(models), 'meshCount': sum((len(r['parts']) for r in models.values())), 'totalTriangles': sum((p['triangles'] for r in models.values() for p in r['parts'])), 'exportDirectory': OUT, 'models': manifest['models']}))
