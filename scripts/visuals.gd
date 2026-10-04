extends Node3D

# Original procedural assets keep the browser build small and self contained.
const PAINT := Color("eef0ea")
const BLUE := Color("197f9b")
const GLASS := Color("234553")
var materials: Dictionary = {}

func mat(color: Color, rough: float = 0.8) -> StandardMaterial3D:
	var key := str(color) + str(rough)
	if materials.has(key): return materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = rough
	materials[key] = result
	return result

func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = at
	node.material_override = mat(color)
	parent.add_child(node)
	return node

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, at, color)

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 20
	return mesh(parent, shape, at, color)

func sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.height = 2
	shape.radius = 1
	var node := mesh(parent, shape, at, color)
	node.scale = size
	return node

func polygon(parent: Node3D, points: Array[Vector3], thickness: Vector3, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Double sided solid extrusion, with generated normals for directional light.
	for side in [0, 1]:
		for index in range(1, points.size() - 1):
			var triangle := [0, index, index + 1] if side == 0 else [0, index + 1, index]
			for vertex in triangle: surface.add_vertex(points[vertex] + thickness * side)
	for index in range(points.size()):
		var a: Vector3 = points[index]
		var b: Vector3 = points[(index + 1) % points.size()]
		for vertex in [a, a + thickness, b, b, a + thickness, b + thickness]: surface.add_vertex(vertex)
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	var material := mat(color).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	parent.add_child(node)

func surface_material(base: Color, seed_value: int) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.14
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, base.darkened(0.08))
	ramp.set_color(1, base.lightened(0.04))
	texture.color_ramp = ramp
	var result := StandardMaterial3D.new()
	result.albedo_texture = texture
	result.uv1_scale = Vector3(35, 35, 1)
	result.roughness = 1
	return result

func label(text: String, at: Vector3, color: Color, size: int = 32, flat: bool = false) -> void:
	var node := Label3D.new()
	node.text = text
	node.position = at
	node.font_size = size
	node.pixel_size = 0.04
	node.modulate = color
	node.outline_size = 0
	if flat: node.rotation_degrees.x = -90
	else: node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(node)

func airport() -> void:
	var surroundings := preload("res://scripts/scenery.gd").new()
	add_child(surroundings)
	var grass := box(self, Vector3(0, -0.55, 30), Vector3(180, 0.8, 110), Color.WHITE)
	grass.material_override = surface_material(Color("718465"), 12)
	var runway := box(self, Vector3(0, 0, 0), Vector3(104, 0.2, 8), Color.WHITE)
	runway.material_override = surface_material(Color("343a3c"), 21)
	box(self, Vector3(0, -0.05, 0), Vector3(108, 0.1, 10), Color("7f877b"))
	for x in [-42.0, 12.0]:
		box(self, Vector3(x, 0.04, 6), Vector3(5, 0.18, 12), Color("636963"))
	var apron := box(self, Vector3(0, 0.02, 26), Vector3(76, 0.18, 25), Color.WHITE)
	apron.material_override = surface_material(Color("a6a59a"), 41)
	var taxi := box(self, Vector3(0, 0.06, 12), Vector3(96, 0.16, 5), Color.WHITE)
	taxi.material_override = surface_material(Color("727770"), 33)
	for x in range(-36, 39, 6):
		box(self, Vector3(x, 0.135, 26), Vector3(0.025, 0.01, 24), Color("82857d"))
	for z in range(16, 39, 6):
		box(self, Vector3(0, 0.135, z), Vector3(75, 0.01, 0.025), Color("82857d"))
	for x in range(-36, 37, 8):
		box(self, Vector3(x, 0.12, 0), Vector3(3.8, 0.02, 0.18), PAINT)
	for z in [-3.7, 3.7]:
		box(self, Vector3(0, 0.12, z), Vector3(99, 0.02, 0.09), PAINT)
		for x in range(-48, 49, 4): sphere(self, Vector3(x, 0.25, z + sign(z) * 0.5), Vector3(0.10, 0.08, 0.10), Color("fff3b5"))
	for x in [-47.0, 47.0]:
		for z in [-2.9, -2.0, -1.1, 1.1, 2.0, 2.9]: box(self, Vector3(x, 0.13, z), Vector3(3.2, 0.02, 0.45), PAINT)
	for x in [-28.0, 28.0]:
		for z in [-2.0, 2.0]: box(self, Vector3(x, 0.13, z), Vector3(4, 0.02, 0.75), PAINT)
	for x in range(-24, 30, 3): box(self, Vector3(x, 0.14, 0.8), Vector3(2.5, 0.01, 0.10), Color("272b2c"))
	label("09", Vector3(-41, 0.16, 0), PAINT, 65, true)
	label("27", Vector3(41, 0.16, 0), PAINT, 65, true)
	box(self, Vector3(0, 0.16, 12), Vector3(90, 0.02, 0.12), Color("efd177"))
	for x in [-42.0, 12.0]:
		box(self, Vector3(x, 0.16, 7), Vector3(0.12, 0.02, 10), Color("efd177"))
		for z in [5.6, 6.0, 6.5, 6.9]: box(self, Vector3(x, 0.18, z), Vector3(4.6, 0.02, 0.12), Color("efd177"))
	for x in range(-44, 45, 4): sphere(self, Vector3(x, 0.22, 14.5), Vector3(0.09, 0.07, 0.09), Color("80a7ff"))
	# Terminal: glazed concourse, roof ribs, entrance, jet bridges and service equipment.
	box(self, Vector3(0, 2.1, 39), Vector3(69, 4.2, 9), Color("d3cbb7"))
	box(self, Vector3(0, 2.5, 34.45), Vector3(67, 2.4, 0.15), GLASS)
	box(self, Vector3(0, 4.35, 39), Vector3(71, 0.4, 10), Color("f2ead8"))
	for x in range(-32, 33, 4):
		box(self, Vector3(x, 2.5, 34.25), Vector3(0.14, 3.2, 0.35), Color("b9bdba"))
	for x in range(-30, 32, 10):
		box(self, Vector3(x, 4.7, 40), Vector3(3, 0.7, 2), Color("7d8c8b"))
	box(self, Vector3(0, 1.8, 45), Vector3(18, 3.6, 7), GLASS)
	label("H A R B O R   F I E L D", Vector3(0, 5.4, 37), Color("f7eddb"), 26)
	for gate in range(4):
		var x: float = [-27.0, -9.0, 9.0, 27.0][gate]
		box(self, Vector3(x, 0.17, 23), Vector3(0.13, 0.02, 17), Color("efd177"))
		box(self, Vector3(x, 0.18, 26), Vector3(4, 0.02, 0.13), Color("efd177"))
		label("G" + str(gate + 1), Vector3(x, 0.2, 30), Color("efe5b5"), 38, true)
		box(self, Vector3(x + 3, 1.6, 31.5), Vector3(1.4, 1.3, 6), Color("adb9b5"))
		box(self, Vector3(x + 2, 1.5, 28.5), Vector3(3, 1.3, 1.5), Color("bbc6bd"))
		cylinder(self, Vector3(x + 3, 0.7, 29), 0.14, 1.4, Color("5b6666"))
		for offset in [7.0, 9.0]:
			box(self, Vector3(x + offset, 0.5, 31), Vector3(1.4, 0.7, 2.3), Color("ede2bf"))
			box(self, Vector3(x + offset, 0.95, 30.6), Vector3(1.2, 0.45, 0.9), GLASS)
	# Tower with tapered shaft, wraparound glass cab and antenna.
	cylinder(self, Vector3(39, 5, 33), 1.6, 10, Color("c9c4b5"), 1.0)
	cylinder(self, Vector3(39, 10.6, 33), 2.8, 1.4, GLASS, 3.2).add_to_group("tower_shell")
	cylinder(self, Vector3(39, 11.5, 33), 3.4, 0.4, Color("e4dcca")).add_to_group("tower_shell")
	cylinder(self, Vector3(39, 13, 33), 0.06, 3, Color("657279")).add_to_group("tower_shell")
	# Landside access, parking stalls and modest background buildings.
	box(self, Vector3(0, -0.02, 53), Vector3(160, 0.1, 5), Color("505a58"))
	box(self, Vector3(0, -0.02, 65), Vector3(72, 0.1, 17), Color("6a726b"))
	for x in range(-32, 34, 3):
		box(self, Vector3(x, 0.05, 61), Vector3(0.05, 0.02, 5), PAINT)
		if x % 2 == 0: box(self, Vector3(x + 1, 0.55, 61), Vector3(1.2, 1.0, 2.4), Color("465b66"))
	for x in [-70.0, 67.0]:
		box(self, Vector3(x, 2, 34), Vector3(16, 4, 12), Color("a5ad9b"))
		box(self, Vector3(x, 4.15, 34), Vector3(17, 0.3, 13), Color("d0cbb7"))
	var random := RandomNumberGenerator.new()
	random.seed = 82
	for index in range(70):
		var x := random.randf_range(-85, 85)
		var z := random.randf_range(-15, 90)
		if abs(x) < 58 and z > -12 and z < 78: continue
		cylinder(self, Vector3(x, 1, z), 0.18, 2, Color("6c6550"))
		sphere(self, Vector3(x, 2.7, z), Vector3(1.5, 2.2, 1.5), Color("4e6e51"))

func aircraft(id: String) -> Node3D:
	var plane := Node3D.new()
	add_child(plane)
	# Lathed fuselage with a rounded nose and tapering tail, aligned to -Z.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var rings := [Vector2(-3.4, 0.02), Vector2(-3.1, 0.24), Vector2(-2.6, 0.43), Vector2(-1.9, 0.48), Vector2(1.5, 0.48), Vector2(2.3, 0.32), Vector2(3.1, 0.06)]
	for row in range(rings.size() - 1):
		for segment in range(24):
			var corners: Array[Vector3] = []
			for pair in [[row, segment], [row, segment + 1], [row + 1, segment], [row + 1, segment + 1]]:
				var ring: Vector2 = rings[pair[0]]
				var angle: float = pair[1] * TAU / 24
				corners.append(Vector3(cos(angle) * ring.y, sin(angle) * ring.y, ring.x))
			for corner in [0, 2, 1, 1, 2, 3]: surface.add_vertex(corners[corner])
	surface.generate_normals()
	mesh(plane, surface.commit(), Vector3.ZERO, PAINT)
	for side in [-1.0, 1.0]:
		polygon(plane, [Vector3(side * 0.35, -0.05, -0.9), Vector3(side * 3.9, -0.05, 1.3), Vector3(side * 3.7, -0.05, 1.8), Vector3(side * 0.35, -0.05, 0.9)], Vector3(0, 0.09, 0), Color("c8d2d3"))
		polygon(plane, [Vector3(side * 0.2, 0.1, 2.0), Vector3(side * 1.5, 0.1, 2.8), Vector3(side * 1.4, 0.1, 3.0), Vector3(side * 0.2, 0.1, 2.7)], Vector3(0, 0.07, 0), Color("c8d2d3"))
		box(plane, Vector3(side * 3.75, 0.18, 1.5), Vector3(0.08, 0.45, 0.4), BLUE)
		var engine := cylinder(plane, Vector3(side * 1.3, -0.35, 0.15), 0.27, 1.05, PAINT)
		engine.rotation_degrees.x = 90
		var intake := cylinder(plane, Vector3(side * 1.3, -0.35, -0.39), 0.22, 0.02, GLASS)
		intake.rotation_degrees.x = 90
		for z in range(12): sphere(plane, Vector3(side * 0.465, 0.13, -1.75 + z * 0.24), Vector3(0.025, 0.06, 0.045), GLASS)
		box(plane, Vector3(side * 0.476, -0.06, -0.1), Vector3(0.015, 0.08, 3.9), BLUE)
		for z in [-1.8, 1.45]: box(plane, Vector3(side * 0.46, 0, z), Vector3(0.025, 0.35, 0.17), Color("a4b8ba"))
		for z in [-2.0, 0.65]: sphere(plane, Vector3(side * 0.30, -0.59, z), Vector3(0.12, 0.16, 0.16), Color("273237"))
	polygon(plane, [Vector3(0, 0.25, 1.7), Vector3(0, 1.6, 2.7), Vector3(0, 1.6, 3.1), Vector3(0, 0.25, 3.0)], Vector3(0.07, 0, 0), BLUE)
	sphere(plane, Vector3(0, 0.25, -2.6), Vector3(0.32, 0.12, 0.30), GLASS)
	var call_sign := Label3D.new()
	call_sign.text = id
	call_sign.position.y = 2.8
	call_sign.font_size = 24
	call_sign.pixel_size = 0.035
	call_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	call_sign.modulate = Color("b2f5ef")
	plane.add_child(call_sign)
	return plane




