extends Node3D

func _ready() -> void:
	var assets := preload("res://scripts/visuals.gd").new()
	add_child(assets)
	assets.box(self, Vector3(0, -0.08, 0), Vector3(6.8, 0.16, 6.8), Color("38454b"))
	assets.box(self, Vector3(0, 3.35, 0), Vector3(7, 0.18, 7), Color("465860"))
	# Clear windows retain unobstructed visibility; frames define the room.
	for side in [-1.0, 1.0]:
		assets.box(self, Vector3(0, 0.28, side * 3.25), Vector3(6.8, 0.56, 0.16), Color("607780"))
		assets.box(self, Vector3(side * 3.25, 0.28, 0), Vector3(0.16, 0.56, 6.8), Color("607780"))
		assets.box(self, Vector3(0, 3.0, side * 3.25), Vector3(6.8, 0.14, 0.16), Color("263d49"))
		assets.box(self, Vector3(side * 3.25, 3.0, 0), Vector3(0.16, 0.14, 6.8), Color("263d49"))
		for offset in [-3.2, 0.0, 3.2]:
			assets.box(self, Vector3(offset, 1.8, side * 3.25), Vector3(0.07, 2.5, 0.12), Color("263d49"))
			assets.box(self, Vector3(side * 3.25, 1.8, offset), Vector3(0.12, 2.5, 0.07), Color("263d49"))
	# Wraparound controller desks, radar consoles, flight strips and radio.
	for x in [-1.7, 0.0, 1.7]:
		assets.box(self, Vector3(x, 0.43, -2.3), Vector3(1.5, 0.86, 1.0), Color("26343b"))
		assets.box(self, Vector3(x, 0.89, -2.2), Vector3(1.65, 0.10, 1.3), Color("52616a"))
		var monitor := assets.box(self, Vector3(x, 1.23, -2.5), Vector3(0.82, 0.52, 0.08), Color("14262c"))
		monitor.rotation_degrees.x = -12
		var display := assets.box(self, Vector3(x, 1.23, -2.45), Vector3(0.73, 0.43, 0.015), Color("124548"))
		display.rotation_degrees.x = -12
		for line in range(4):
			assets.box(self, Vector3(x, 1.08 + line * 0.08, -2.405), Vector3(0.49, 0.012, 0.01), Color("76cdb6"))
		assets.box(self, Vector3(x, 0.96, -1.97), Vector3(0.55, 0.04, 0.22), Color("17272e"))
		for strip in range(3): assets.box(self, Vector3(x + 0.48, 0.96, -2.3 + strip * 0.16), Vector3(0.27, 0.015, 0.11), Color("e7d8aa"))
	assets.cylinder(self, Vector3(-0.6, 1.1, -1.8), 0.025, 0.38, Color("17272e"))
	assets.sphere(self, Vector3(-0.6, 1.29, -1.8), Vector3(0.04, 0.06, 0.04), Color("17272e"))
	assets.box(self, Vector3(2.45, 0.9, 0.4), Vector3(1.0, 0.10, 3.5), Color("52616a"))
	assets.box(self, Vector3(0, 0.9, 2.65), Vector3(2.5, 1.8, 0.25), Color("273d49"))
	assets.box(self, Vector3(0, 2.45, 3.1), Vector3(1.1, 0.35, 0.06), Color("d7dbc9"))
	for x in [-1.8, 1.8]:
		var lamp := assets.box(self, Vector3(x, 3.23, 0), Vector3(0.7, 0.03, 1.5), Color("e6eddf"))
		var material := lamp.material_override.duplicate() as StandardMaterial3D
		material.emission_enabled = true
		material.emission = Color("d7e5de")
		lamp.material_override = material
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.5, 0)
	light.omni_range = 6
	light.light_energy = 0.45
	add_child(light)
