"""Fly High IslandKit v3 rocks (16 Nov 2026): blunt the floating-island undersides.

Feedback 16 Nov 22:20: the island bottoms ended in a needle tip plus hanging stalactites. This takes the v2
kit (assets/models/scenery/storm/generated/islands/FlyHigh_IslandKit_v2.glb), deletes the loose stalactite
pieces, widens and rounds the lower half, shortens the keel to ~73% height and relaxes the tip, then exports
the three rock meshes to FlyHigh_IslandKit_v3_rocks.glb (asset 77785941045525). Turf meshes are unchanged.
Installed in EnvironmentAssets.IslandKit (SurfaceAppearance and attributes moved from the v2 parts; v2 kept in
ServerStorage.IslandKit_Legacy). New SourceCenter values (Roblox axes):
  IslandShelfRock (-0.968, -36.176, 0.414)  IslandCragRock (2.743, -51.275, 0.965)
  IslandTwinRock (0.183, -42.887, -0.803)
Run inside Blender through the Blender MCP (safe mode).
"""
import bpy
import bmesh
from mathutils import Vector, noise

SRC = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/islands/FlyHigh_IslandKit_v2.glb"
OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/islands/FlyHigh_IslandKit_v3_rocks.glb"
SCENE = "FlyHigh_IslandFix"
ROCKS = ("IslandShelfRock", "IslandCragRock", "IslandTwinRock")


def smooth01(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def blunt(o):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    seen, groups = set(), []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, g = [v], []
        seen.add(v.index)
        while stack:
            x = stack.pop()
            g.append(x)
            for e in x.link_edges:
                w = e.other_vert(x)
                if w.index not in seen:
                    seen.add(w.index)
                    stack.append(w)
        groups.append(g)
    groups.sort(key=len, reverse=True)
    for g in groups[1:]:
        bmesh.ops.delete(bm, geom=g, context='VERTS')
    zs = [v.co.z for v in bm.verts]
    top, bot = max(zs), min(zs)
    H = top - bot
    bins = {}
    for v in bm.verts:
        k = int((top - v.co.z) / H * 20)
        b = bins.setdefault(k, [0.0, 0.0, 0])
        b[0] += v.co.x
        b[1] += v.co.y
        b[2] += 1
    cs = {}
    for k, b in bins.items():
        cs[k] = Vector((b[0] / b[2], b[1] / b[2], 0))

    def centre(t):
        k = min(19, int(t * 20))
        while k > 0 and k not in cs:
            k -= 1
        return cs.get(k, Vector((0, 0, 0)))

    for v in bm.verts:
        t = (top - v.co.z) / H
        c = centre(t)
        w = smooth01((t - 0.4) / 0.6)
        rel = Vector((v.co.x - c.x, v.co.y - c.y, 0))
        n = noise.noise(Vector((v.co.x * 0.06, v.co.y * 0.06, v.co.z * 0.06)))
        rel = rel * (1.0 + 0.45 * w + 0.35 * w * w) * (1 + 0.1 * n * w)
        tz = t if t < 0.45 else 0.45 + (t - 0.45) * 0.72
        v.co = Vector((c.x + rel.x, c.y + rel.y, top - tz * H))
    low = [v for v in bm.verts if (top - v.co.z) / H > 0.5]
    for it in range(4):
        bmesh.ops.smooth_vert(bm, verts=low, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update()
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def run():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    bpy.ops.import_scene.gltf(filepath=SRC)
    for name in ROCKS:
        blunt(sc.objects[name])
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    objs = [sc.objects[n] for n in ROCKS]
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                              export_apply=True, export_materials='NONE', export_yup=True, export_texcoords=True,
                              export_normals=True)


run()
