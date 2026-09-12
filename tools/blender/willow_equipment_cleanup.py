"""Remove the sculpted bow and arrow tips; gameplay equipment owns these visuals."""
import bpy, bmesh
import numpy as np

def remove_archery(obj, paint):
    mesh = obj.data
    points = np.array([v.co[:] for v in mesh.vertices])
    normals = np.array([v.normal[:] for v in mesh.vertices])
    labels, _, _, names = paint(points, 0, normals)
    # These authored wood regions cover the fixed upper bow and arrow shafts.
    x, y, z = points.T
    wood = (labels == names.index('wood')) & (z > 1.58)
    # Feather/shaft edges outside the painted wood stroke still belong to arrows.
    arrow_tips = (x < -.06) & (x > -.18) & (y > -.06) & (z > 1.66) & (z < 1.85)
    arrow_tips &= labels != names.index('hair')
    remove = set(np.nonzero(wood | arrow_tips)[0])
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    original_boundary = {e for e in bm.edges if e.is_boundary}
    bmesh.ops.delete(bm, geom=[bm.verts[i] for i in remove], context='VERTS')
    # Cutting fused shafts can leave tiny disconnected slivers of fletching.
    unseen = set(bm.verts)
    islands = []
    while unseen:
        seed = unseen.pop()
        island, pending = [seed], [seed]
        while pending:
            vertex = pending.pop()
            for edge in vertex.link_edges:
                neighbor = edge.other_vert(vertex)
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    island.append(neighbor)
                    pending.append(neighbor)
        islands.append(island)
    fragments = [v for island in islands if len(island) < 256 and all(v.co.z > 1.58 for v in island) for v in island]
    if fragments:
        bmesh.ops.delete(bm, geom=fragments, context='VERTS')
    opening = [e for e in bm.edges if e.is_boundary and e not in original_boundary]
    for face in bm.faces:
        face.select = False
    caps = bmesh.ops.holes_fill(bm, edges=opening, sides=0).get('faces', []) if opening else []
    for face in caps:
        face.select = True
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    # Give newly closed attachment surfaces real UV space before the paint bake.
    if caps:
        bpy.context.tool_settings.mesh_select_mode = (False, False, True)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=.006)
        bpy.ops.object.mode_set(mode='OBJECT')
    obj['baked_archery_removed'] = True
    print('WILLOW ARCHERY REMOVED', len(remove), 'vertices;', len(caps), 'attachment caps', flush=True)
    return dict(removed_archery_vertices=len(remove), removed_archery_fragment_vertices=len(fragments), archery_attachment_caps=len(caps))
