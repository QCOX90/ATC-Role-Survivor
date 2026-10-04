extends Node3D

var assets: Node3D
var noise := FastNoiseLite.new()

func height_at(x: float, z: float) -> float:
	var shore := -36.0 - sin(x * 0.018) * 12.0
	if z < shore: return -3.0
	var land := smoothstep(shore, shore + 25.0, z)
	var hill := 48.0 * exp(-pow((x + 230.0) / 100.0, 2) - pow((z - 140.0) / 190.0, 2))
	hill += 65.0 * exp(-pow((x - 175.0) / 140.0, 2) - pow((z - 280.0) / 100.0, 2))
	var detail := maxf(z - 85.0, absf(x) - 100.0)
	var rough := noise.get_noise_2d(x, z) * 9.0 * smoothstep(0, 80, detail)
	return lerpf(-2.0, -0.3 + hill + rough, land)

func _ready() -> void:
	assets = load("res://scripts/visuals.gd").new()
	add_child(assets)
	noise.seed = 417
	noise.frequency = 0.014
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	for row in range(100):
		for col in range(100):
			var x := -500.0 + col * 10.0
			var z := -400.0 + row * 10.0
			for offset in [Vector2(0, 0), Vector2(0, 10), Vector2(10, 0), Vector2(10, 0), Vector2(0, 10), Vector2(10, 10)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				var h := height_at(px, pz)
				var tint := Color("8d9872").lerp(Color("7c8561"), clampf(h / 65.0, 0, 1))
				if pz < -15: tint = Color("b9ae88")
				surface.set_color(tint.darkened(noise.get_noise_2d(px * 3, pz * 3) * 0.10))
				surface.add_vertex(Vector3(px, h, pz))
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1
	terrain.material_override = material
	add_child(terrain)
	# A calm bay with fine ripples; this shader stays in Compatibility rendering.
	var water: MeshInstance3D = assets.box(self, Vector3(0, -1.25, -300), Vector3(1400, 0.1, 900), Color.WHITE)
	var water_material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; varying vec3 world_pos; void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float ripple=sin(world_pos.x*1.2+TIME*0.6)*sin(world_pos.z*0.6-TIME*0.4); ALBEDO=mix(vec3(0.12,0.28,0.34),vec3(0.25,0.44,0.46),0.5+ripple*0.12); ROUGHNESS=0.4; METALLIC=0.15;}"
	water_material.shader = shader
	water.material_override = water_material
	# Shoreline road and airport access route.
	for i in range(35):
		var x := -170.0 + i * 10.0
		var z := 92.0 + sin(x * 0.018) * 6.0
		var road: MeshInstance3D = assets.box(self, Vector3(x, height_at(x, z) + 0.12, z), Vector3(10.3, 0.12, 4.0), Color("515855"))
		road.rotation.y = -atan(cos(x * 0.018) * 0.108)
		assets.box(self, Vector3(x, height_at(x, z) + 0.2, z), Vector3(3, 0.02, 0.07), Color("ece5ca"))
	assets.box(self, Vector3(45, 0.04, 73), Vector3(4, 0.1, 36), Color("515855"))
	# Fictional waterfront bridge, distant downtown, and hillside neighborhoods.
	for x in [-180.0, -130.0]:
		assets.box(self, Vector3(x, 11, -108), Vector3(2.4, 28, 2.4), Color("a75c43"))
		assets.box(self, Vector3(x, 20, -108), Vector3(6, 1, 2.4), Color("a75c43"))
	assets.box(self, Vector3(-155, 7, -108), Vector3(125, 1, 6), Color("676d67"))
	for x in range(-215, -91, 5):
		var cable_h := 9.0 + 15.0 * pow((x + 155.0) / 25.0, 2) if x >= -180 and x <= -130 else 24.0 - absf(x + 180.0 if x < -180 else x + 130.0) * 0.45
		var nx := x + 5.0
		var next_h := 9.0 + 15.0 * pow((nx + 155.0) / 25.0, 2) if nx >= -180 and nx <= -130 else 24.0 - absf(nx + 180.0 if nx < -180 else nx + 130.0) * 0.45
		for z in [-110.8, -105.2]:
			assets.cylinder(self, Vector3(x, (cable_h + 7.5) / 2, z), 0.045, cable_h - 7.5, Color("b77a60"))
			var a := Vector3(x, cable_h, z)
			var b := Vector3(nx, next_h, z)
			var cable: MeshInstance3D = assets.box(self, (a + b) / 2, Vector3(0.10, 0.10, a.distance_to(b)), Color("a75c43"))
			cable.look_at(b)
	var random := RandomNumberGenerator.new()
	random.seed = 612
	for i in range(130):
		var x := random.randf_range(80, 260)
		var z := random.randf_range(120, 235)
		var h := random.randf_range(3, 18)
		if i < 12: h += 22
		var base := height_at(x, z)
		var color := Color("bcb6a2").darkened(random.randf_range(0, 0.25))
		assets.box(self, Vector3(x, base + h / 2, z), Vector3(5, h, 6), color)
		for y in range(2, int(h), 3): assets.box(self, Vector3(x, base + y, z - 3.03), Vector3(4, 0.75, 0.02), Color("567280"))
	for i in range(150):
		var x := random.randf_range(-320, 280)
		var z := random.randf_range(100, 330)
		if x > 60 and z < 240: continue
		var y := height_at(x, z)
		assets.cylinder(self, Vector3(x, y + 1.5, z), 0.2, 3, Color("766c51"))
		assets.cylinder(self, Vector3(x, y + 3.2, z), 1.7, 4, Color("50694f"), 0.1)

