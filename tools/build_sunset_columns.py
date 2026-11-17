# Fly High - Sunset broken column kit (Blender, MCP safe mode compatible; paste into execute_blender_code).
# Builds ColumnTall, ColumnStump, ColumnDrum and ColumnCapital (fluted shafts with jagged broken ends) and
# exports FlyHigh_SunsetColumns_v1.glb. Roblox asset 115927584511158 (17 Nov 2026), installed as
# ReplicatedStorage.FlyHigh.EnvironmentAssets.SunsetColumns with a SourceCenter attribute per piece
# (offset from the piece foot): Tall (0,3.984,0), Stump (0,1.636,0), Drum (0.316,0.86,0.068), Capital (0,0.56,0).
# Source of record: assets/models/scenery/FlyHigh_SceneryKits_round6.blend, scene FlyHigh_Columns.
import bpy, bmesh, math
from mathutils import Vector, noise

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_SunsetColumns_v1.glb"


def R(v):
    return Vector((v.x, -v.z, v.y))


sc = bpy.data.scenes.get("FlyHigh_Columns") or bpy.data.scenes.new("FlyHigh_Columns")
bpy.context.window.scene = sc
for o in list(sc.objects):
    bpy.data.objects.remove(o)


def finish(name, bm, smooth=True):
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


def fluted_r(th, r):
    f = max(0.0, math.cos(16 * th))
    return r * (1 - 0.07 * f * f)


def shaft(bm, origin, axis_up, height, r, seed, broken_top=True, broken_bottom=False, seg=48, rows=10, chip=0.55):
    """Fluted shaft along axis_up (Roblox vector) from origin. Broken ends are jagged."""
    up = axis_up.normalized()
    ref = Vector((1, 0, 0)) if abs(up.x) < 0.9 else Vector((0, 0, 1))
    s1 = up.cross(ref).normalized(); s2 = up.cross(s1).normalized()

    def end_offset(th, top):
        n = noise.noise(Vector((math.cos(th) * 1.7 + seed, math.sin(th) * 1.7, 3.1 if top else -3.1)))
        n2 = noise.noise(Vector((math.cos(th) * 4.2, math.sin(th) * 4.2 + seed, 1.0)))
        return chip * (0.5 + 0.5 * n) + 0.18 * n2

    grid = []
    for i in range(rows + 1):
        t = i / rows
        row = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            h = t * height
            if broken_top and i == rows:
                h = height - end_offset(th, True)
            if broken_bottom and i == 0:
                h = end_offset(th, False)
            rr = fluted_r(th, r * (1 - 0.06 * t))
            p = origin + up * h + (s1 * math.cos(th) + s2 * math.sin(th)) * rr
            row.append(bm.verts.new(R(p)))
        grid.append(row)
    for a, b in zip(grid, grid[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
    for row, h, flip in ((grid[-1], height - (chip * 0.75 if broken_top else 0), False),
                         (grid[0], (chip * 0.75 if broken_bottom else 0), True)):
        c = bm.verts.new(R(origin + up * h))
        for k in range(seg):
            f = (row[k], row[(k + 1) % seg], c)
            bm.faces.new(f[::-1] if flip else f)


def disc(bm, center, r, h, seg=32, square=False):
    y0, y1 = center.y, center.y + h
    pts = []
    for k in range(seg):
        th = 2 * math.pi * k / seg
        if square:
            c, s = math.cos(th), math.sin(th)
            m = max(abs(c), abs(s))
            pts.append((c / m * r, s / m * r))
        else:
            pts.append((math.cos(th) * r, math.sin(th) * r))
    bot = [bm.verts.new(R(Vector((center.x + x, y0, center.z + z)))) for x, z in pts]
    top = [bm.verts.new(R(Vector((center.x + x, y1, center.z + z)))) for x, z in pts]
    for k in range(seg):
        bm.faces.new((bot[k], bot[(k + 1) % seg], top[(k + 1) % seg], top[k]))
    bm.faces.new(top)
    bm.faces.new(bot[::-1])


bm = bmesh.new()  # 1. tall broken column on a plinth (foot at the origin)
disc(bm, Vector((0, 0, 0)), 1.35, 0.45, seg=32, square=True)
disc(bm, Vector((0, 0.45, 0)), 1.18, 0.28, seg=40)
disc(bm, Vector((0, 0.73, 0)), 1.05, 0.18, seg=40)
shaft(bm, Vector((0, 0.9, 0)), Vector((0, 1, 0)), 7.2, 0.92, seed=1.7)
finish("ColumnTall", bm)

bm = bmesh.new()  # 2. short stump (x offset for layout only)
o = Vector((5, 0, 0))
disc(bm, o, 1.35, 0.45, seg=32, square=True)
disc(bm, o + Vector((0, 0.45, 0)), 1.18, 0.28, seg=40)
shaft(bm, o + Vector((0, 0.73, 0)), Vector((0, 1, 0)), 2.6, 0.92, seed=5.3, chip=0.7)
finish("ColumnStump", bm)

bm = bmesh.new()  # 3. fallen drum, both ends broken
o = Vector((10, 0.86, -1.6))
shaft(bm, o, Vector((0.2, 0, 1)), 3.4, 0.9, seed=8.9, broken_top=True, broken_bottom=True, chip=0.45)
finish("ColumnDrum", bm)

bm = bmesh.new()  # 4. fallen capital
o = Vector((15, 0, 0))
disc(bm, o, 1.4, 0.5, seg=32, square=True)
disc(bm, o + Vector((0, 0.5, 0)), 1.12, 0.32, seg=40)
disc(bm, o + Vector((0, 0.82, 0)), 0.9, 0.3, seg=40)
finish("ColumnCapital", bm)

for ob in bpy.context.view_layer.objects:
    ob.select_set(False)
for ob in sc.objects:
    ob.select_set(True)
bpy.context.view_layer.objects.active = sc.objects[0]
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, use_active_scene=True,
                          export_apply=True, export_materials='NONE', export_yup=True,
                          export_texcoords=True, export_normals=True)
