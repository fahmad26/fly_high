"""Fly High meteor v5: cratered basalt rock with glowing lava cracks.

Run inside Blender through the Blender MCP (safe mode: bpy/bmesh/mathutils/math/random only).
Exports two meshes in one GLB:
  MeteorRock -> template part "Body" (Basalt + IslandKit rock SurfaceAppearance, tint 170,138,120)
  MeteorLava -> template part "Lava" (Neon 255,112,34)
Both are renamed to "MeteorFragment" at runtime by ObstacleArt (Visuals.Attach), and ObstacleManager
restores each fragment's own transparency when the meteor falls, so the Neon cracks stay visible.
Installed 16 Nov 2026 as asset 104097092302147, scaled so the Body is 9.29 studs tall (same as v4).
The rock is roughly symmetric, so the import-yaw flip (see build_creatures.py) was not applied;
parts keep the relative layout of the inserted model.
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector, noise

OUT = "E:/Antigravity/Fly High/assets/models/scenery/storm/generated/creatures/FlyHigh_Meteor_v5.glb"
SCENE = "FlyHigh_Meteor"


def rdir():
    return Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))).normalized()


def arc(a, axis, span, n, seed):
    pts = []
    for k in range(n):
        t = (k / (n - 1) - 0.5) * span
        p = a * math.cos(t) + axis.cross(a) * math.sin(t)
        w = Vector((noise.noise(p * 2.7 + Vector((seed, 0, 0))), noise.noise(p * 2.7 + Vector((0, seed, 0))),
                    noise.noise(p * 2.7 + Vector((0, 0, seed)))))
        pts.append((p + w * 0.16).normalized())
    return pts


def build():
    sc = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = sc
    for o in list(sc.objects):
        bpy.data.objects.remove(o)
    random.seed(11)
    craters = [(rdir(), random.uniform(0.18, 0.36), random.uniform(0.05, 0.10)) for i in range(9)]
    cracks = []
    for i in range(6):
        a = rdir()
        axis = rdir().cross(a).normalized()
        main = arc(a, axis, random.uniform(1.2, 2.0), 28, i * 3.3)
        cracks.append(main)
        for b in range(2):
            s = main[random.randint(6, 21)]
            ax2 = rdir().cross(s).normalized()
            br = arc(s, ax2, random.uniform(0.35, 0.6), 10, i * 7.1 + b)
            cracks.append([s] + br[len(br) // 2:])

    def seg_dist(d):
        best = 9.0
        for pts in cracks:
            for k in range(len(pts) - 1):
                a = pts[k]
                ab = pts[k + 1] - a
                t = max(0.0, min(1.0, (d - a).dot(ab) / max(ab.length_squared, 1e-9)))
                best = min(best, (d - (a + ab * t)).length)
        return best

    def base(d):
        r = 1.0 + 0.15 * noise.noise(d * 1.6) + 0.065 * noise.noise(d * 4.3 + Vector((3, 1, 2))) + 0.022 * noise.noise(d * 11.0)
        for c, rad, dep in craters:
            x = d.angle(c) / rad
            if x < 1.0:
                r -= dep * (1.0 - x * x)
            elif x < 1.35:
                r += dep * 0.45 * math.sin((x - 1.0) / 0.35 * math.pi)
        return r

    W = 0.085   # groove half-width (unit sphere)
    DEP = 0.07  # groove depth

    def shape(d):
        r = base(d)
        g = seg_dist(d)
        if g < W:
            r -= DEP * (0.5 + 0.5 * math.cos(g / W * math.pi))
        return r

    STR = Vector((1.0, 0.95, 1.18))

    def sq(v):
        return Vector((v.x * STR.x, v.y * STR.y, v.z * STR.z))

    me = bpy.data.meshes.new("MeteorRock")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=88, v_segments=56, radius=1.0, calc_uvs=True)
    for v in bm.verts:
        d = v.co.normalized()
        v.co = sq(d * shape(d))
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    rock = bpy.data.objects.new("MeteorRock", me)
    sc.collection.objects.link(rock)

    me2 = bpy.data.meshes.new("MeteorLava")
    bm = bmesh.new()
    for pts in cracks:
        dense = []
        for k in range(len(pts) - 1):
            for s in range(3):
                dense.append((pts[k].lerp(pts[k + 1], s / 3.0)).normalized())
        dense.append(pts[-1])
        n = len(dense)
        prev = None
        for k in range(n):
            d = dense[k]
            tan = (dense[min(k + 1, n - 1)] - dense[max(k - 1, 0)]).normalized()
            side = d.cross(tan).normalized()
            f = k / (n - 1)
            hw = 0.045 * max(0.25, math.sin(f * math.pi)) ** 0.6
            r = base(d) - DEP * 0.5
            a = bm.verts.new(sq((d + side * hw).normalized() * r))
            b = bm.verts.new(sq((d - side * hw).normalized() * r))
            if prev:
                bm.faces.new((prev[0], prev[1], b, a))
            prev = (a, b)
    bm.normal_update()
    for f in bm.faces:
        if f.normal.dot(f.calc_center_median()) < 0:
            f.normal_flip()
    bm.to_mesh(me2)
    bm.free()
    lava = bpy.data.objects.new("MeteorLava", me2)
    sc.collection.objects.link(lava)

    bpy.ops.object.select_all(action='DESELECT')
    rock.select_set(True)
    lava.select_set(True)
    bpy.ops.export_scene.gltf(filepath=OUT, use_selection=True, use_active_scene=True, export_yup=True, export_apply=True)
    return len(rock.data.polygons), len(lava.data.polygons)


print(build())
