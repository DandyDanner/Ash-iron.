extends Node3D
## Viewmodel hand: shaped palm, four separate fingers, opposed thumb, wrist and cuff.
const D = preload("res://scripts/character_mesh.gd")
const M = preload("res://scripts/traveler_model.gd")
var relaxed: Node3D
var gripping: Node3D
var arm: Node3D

func build(skin: Color, cloth: Color, left: bool = false) -> void:
	arm = M.joint(self, "Forearm", Vector3(0,-0.045,0.075))
	D.strand(arm, [Vector3(-0.02,-0.155,0.425), Vector3(0,-0.045,0.165), Vector3.ZERO], [0.068,0.060,0.048], cloth, 0.85, Vector3.RIGHT)
	var cuff := D.loft(arm, [Vector4(0,0.065,0.060,0), Vector4(0.016,0.078,0.069,0), Vector4(0.045,0.080,0.070,0), Vector4(0.060,0.064,0.057,0)], Color("d4c7a0"), 24, 0.04)
	cuff.position = Vector3(0,-0.01,0.015)
	cuff.rotation.x = PI / 2
	var wrist := D.loft(self, [Vector4(-0.09,0.035,0.029,0.065), Vector4(-0.04,0.048,0.031,0.042), Vector4(0.025,0.055,0.031,0.035), Vector4(0.055,0.042,0.027,0.030), Vector4(0.073,0.012,0.008,0.030), Vector4(0.075,0.001,0.001,0.030)], skin, 24, 0.01)
	wrist.name = "PalmAndWrist"
	relaxed = M.joint(self, "RelaxedFingers", Vector3.ZERO)
	gripping = M.joint(self, "GripFingers", Vector3.ZERO)
	for i in range(4):
		var x := (i - 1.5) * 0.027
		var length := [0.084,0.096,0.088,0.068][i] as float
		var root := Vector3(x,0.052,0.025)
		var finger := D.strand(relaxed, [root, root + Vector3(0,length * 0.48,-0.009), root + Vector3(0,length * 0.62,-0.044), root + Vector3(0,length * 0.24,-0.069)], [0.015,0.014,0.012,0.007], skin, 0.85)
		finger.name = "Finger_%d" % i
		D.oval(relaxed, root + Vector3(0,length * 0.57,-0.043), Vector3(0.014,0.006,0.019), skin.lightened(0.14))
		var y := 0.033 - i * 0.028
		var grip := D.strand(gripping, [Vector3(0.040,y,0.040), Vector3(0.061,y,0.01), Vector3(0.042,y,-0.038), Vector3(-0.009,y,-0.042)], [0.016,0.016,0.014,0.008], skin, 0.85)
		grip.name = "Finger_%d" % i
		D.oval(gripping, Vector3(0.042,y,0.042), Vector3(0.027,0.024,0.026), skin.lightened(0.035))
	D.strand(relaxed, [Vector3(-0.037,-0.015,0.036),Vector3(-0.076,0.008,0.014),Vector3(-0.074,0.020,-0.036)], [0.023,0.018,0.009], skin)
	D.strand(gripping, [Vector3(-0.043,0.023,0.046),Vector3(-0.055,0.067,0.008),Vector3(-0.012,0.057,-0.023)], [0.024,0.020,0.011], skin)
	if left: _mirror_geometry()
	set_grip(false)

func set_grip(enabled: bool) -> void:
	gripping.visible = enabled
	relaxed.visible = not enabled

func set_draw_pose(drawing: bool) -> void:
	# The drawing wrist follows the nock; the sleeve still approaches from the right shoulder.
	arm.rotation.y = 1.0 if drawing else 0.0

func _mirror_geometry() -> void:
	# Bake reflection with corrected triangle winding; negative node scale reverses face culling.
	for node in find_children("*", "Node3D", true, false):
		node.position.x = -node.position.x
		if not node is MeshInstance3D: continue
		var arrays: Array = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in range(vertices.size()):
			vertices[i].x = -vertices[i].x
			normals[i].x = -normals[i].x
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var old := indices[i + 1]
			indices[i + 1] = indices[i + 2]
			indices[i + 2] = old
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		arrays[Mesh.ARRAY_TANGENT] = null
		var mirrored := ArrayMesh.new()
		mirrored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		node.mesh = mirrored
