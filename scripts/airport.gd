extends Node3D

const Operations = preload("res://scripts/operations.gd")
var sim = Operations.new()
var selected := "SUR101"
var models: Dictionary = {}
var flight_list: ItemList
var details: Label
var runway_status: Label
var stats: Label
var radio: RichTextLabel
var hint: Label
var input: LineEdit
var pause_button: Button
var tower_button: Button
var ground_button: Button
var radar: Control
var last_radio := ""
var list_ids: Array[String] = []
var camera: Camera3D

const NAVY := Color("101c2c")
const CYAN := Color("68e2df")
const WHITE := Color("ebf2f8")

func _ready() -> void:
	_build_airport()
	_build_ui()
	_refresh()
	if OS.get_cmdline_user_args().has("--capture"):
		_capture_preview()

func _capture_preview() -> void:
	for frame in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var destination := OS.get_cmdline_user_args()[1]
	var result := get_viewport().get_texture().get_image().save_png(destination)
	get_tree().quit(result)

func _process(delta: float) -> void:
	sim.tick(delta)
	for flight in sim.aircraft:
		if not models.has(flight.id):
			models[flight.id] = _aircraft_model(flight.id)
		var model: Node3D = models[flight.id]
		model.position = flight.pos
		if not flight.route.is_empty():
			var target: Vector3 = flight.route[0]
			var flat := target - model.position
			flat.y = 0
			if flat.length() > 0.01:
				model.rotation.y = atan2(-flat.x, -flat.z)
	for id in models.keys():
		if sim.find_flight(id).is_empty():
			models[id].queue_free()
			models.erase(id)
	_refresh()
	radar.tracks = sim.aircraft
	radar.selected = selected
	radar.queue_redraw()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = _material(color)
	item.position = at
	parent.add_child(item)
	return item

func _sign(text: String, at: Vector3, color: Color = WHITE, font_size: int = 36) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.05
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _build_airport() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182c3c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c6ddec")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.0
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(-8, 94, 100)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 110
	add_child(camera)
	camera.look_at(Vector3(18, 0, 6))
	camera.current = true
	_box(self, Vector3(0, -0.5, 0), Vector3(190, 0.8, 130), Color("314b48"))
	_box(self, Vector3(0, 0, 0), Vector3(100, 0.2, 8), Color("26323c"))
	_box(self, Vector3(0, 0, 12), Vector3(94, 0.25, 5), Color("64716c"))
	_box(self, Vector3(0, 0, 24), Vector3(66, 0.25, 18), Color("89908c"))
	_box(self, Vector3(0, 3, 38), Vector3(66, 6, 9), Color("d1d1bb"))
	_box(self, Vector3(31, 8, 35), Vector3(4, 16, 4), Color("587f94"))
	_box(self, Vector3(31, 16.5, 35), Vector3(8, 3, 7), Color("a2d1dd"))
	for x in range(-42, 46, 8):
		_box(self, Vector3(x, 0.17, 0), Vector3(4, 0.05, 0.3), WHITE)
	for x in [-42.0, 12.0]:
		_box(self, Vector3(x, 0.1, 6), Vector3(5, 0.25, 12), Color("64716c"))
		_box(self, Vector3(x, 0.3, 6), Vector3(5, 0.05, 0.3), Color("ffd269"))
		_box(self, Vector3(x, 0.3, 6.6), Vector3(5, 0.05, 0.3), Color("ffd269"))
	_box(self, Vector3(0, 0.2, 12), Vector3(90, 0.05, 0.15), Color("ffd269"))
	for gate in range(3):
		var x: float = Operations.GATES[gate]
		_box(self, Vector3(x, 0.2, 23), Vector3(0.2, 0.05, 18), Color("ffd269"))
		_sign("G" + str(gate + 1), Vector3(x, 1, 31), NAVY, 30)
	_sign("09", Vector3(-40, 0.8, -2), WHITE, 42)
	_sign("27", Vector3(40, 0.8, -2), WHITE, 42)
	_sign("A · TAXIWAY", Vector3(-8, 1, 16), Color("ffd269"), 26)
	_sign("B", Vector3(15, 1, 7), Color("ffd269"), 26)
	_sign("HARBOR FIELD", Vector3(-8, 8, 38), NAVY, 30)

func _aircraft_model(id: String) -> Node3D:
	var plane := Node3D.new()
	add_child(plane)
	_box(plane, Vector3.ZERO, Vector3(0.8, 0.6, 4.3), WHITE)
	_box(plane, Vector3(0, 0, 0.2), Vector3(4.6, 0.18, 1), CYAN)
	_box(plane, Vector3(0, 0.55, 1.6), Vector3(0.2, 1.2, 0.8), CYAN)
	_box(plane, Vector3(0, 0.25, 1.5), Vector3(2.2, 0.15, 0.6), WHITE)
	_box(plane, Vector3(0, 0.22, -1.6), Vector3(0.65, 0.22, 0.5), NAVY)
	var label := Label3D.new()
	label.text = id
	label.position.y = 3.2
	label.font_size = 30
	label.pixel_size = 0.04
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = CYAN
	plane.add_child(label)
	return plane

func _label(parent: Node, text: String, size: int = 18, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var banner := VBoxContainer.new()
	banner.position = Vector2(28, 22)
	banner.size = Vector2(830, 110)
	root.add_child(banner)
	_label(banner, "ATC ROLE SURVIVOR", 30, WHITE)
	_label(banner, "HARBOR FIELD / GROUND + TOWER / PROTOTYPE 0.1", 15, CYAN)
	stats = _label(banner, "", 16)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -390
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c2cf5")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 9)
	scroll.add_child(controls)
	_label(controls, "CONTROL DESK", 23, CYAN)
	var positions := HBoxContainer.new()
	controls.add_child(positions)
	tower_button = _button(positions, "TOWER", func(): _set_position("Tower"))
	ground_button = _button(positions, "GROUND", func(): _set_position("Ground"))
	tower_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ground_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	runway_status = _label(controls, "", 16)
	flight_list = ItemList.new()
	flight_list.custom_minimum_size.y = 88
	flight_list.item_selected.connect(func(index): selected = list_ids[index])
	controls.add_child(flight_list)
	details = _label(controls, "", 16)
	hint = _label(controls, "", 15, CYAN)
	var actions := GridContainer.new()
	actions.columns = 2
	controls.add_child(actions)
	for pair in [["Clear to land", "land"], ["Exit runway", "exit"], ["Taxi to gate", "gate"], ["Approve pushback", "pushback"], ["Taxi runway 09", "taxi"], ["Clear for takeoff", "takeoff"]]:
		var action: String = pair[1]
		var button := _button(actions, pair[0], func(): sim.command(selected, action))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(controls, "RADIO INSTRUCTION", 13, CYAN)
	input = LineEdit.new()
	input.placeholder_text = "SUR101, cleared to land"
	input.custom_minimum_size.y = 36
	input.text_submitted.connect(_send)
	controls.add_child(input)
	_button(controls, "Transmit / Enter", func(): _send(input.text))
	var session := HBoxContainer.new()
	controls.add_child(session)
	pause_button = _button(session, "Pause", func(): sim.paused = not sim.paused)
	pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(session, "+ Arrival", func():
		var id: String = sim.spawn_arrival()
		if not id.is_empty(): selected = id)
	_button(session, "Reset", _reset)
	_label(controls, "PILOT READBACKS + REQUESTS", 13, CYAN)
	radio = RichTextLabel.new()
	radio.custom_minimum_size.y = 155
	radio.scroll_following = true
	radio.add_theme_font_size_override("normal_font_size", 14)
	controls.add_child(radio)
	_label(controls, "One full cycle: land → exit → gate → turnaround → pushback → taxi → takeoff. Switch positions when prompted. Traffic is added manually.", 13, Color("a8bbcd"))
	var footer := Label.new()
	footer.position = Vector2(28, 758)
	footer.text = "Fictional airport · Simplified movement · Early game prototype"
	footer.add_theme_color_override("font_color", Color("b6c9d1"))
	root.add_child(footer)
	radar = preload("res://scripts/radar.gd").new()
	radar.position = Vector2(28, 550)
	radar.size = Vector2(180, 180)
	root.add_child(radar)

func _set_position(value: String) -> void:
	sim.position = value

func _send(text: String) -> void:
	if text.strip_edges().is_empty(): return
	sim.text_command(selected, text)
	input.clear()

func _reset() -> void:
	sim = Operations.new()
	selected = "SUR101"
	last_radio = ""

func _refresh() -> void:
	var ids: Array[String] = []
	for flight in sim.aircraft: ids.append(flight.id)
	if ids != list_ids:
		list_ids = ids
		flight_list.clear()
		for id in ids: flight_list.add_item(id)
	if sim.find_flight(selected).is_empty():
		selected = ids[0] if not ids.is_empty() else ""
	for index in range(ids.size()):
		var flight: Dictionary = sim.find_flight(ids[index])
		flight_list.set_item_text(index, flight.id + "  ·  " + flight.state)
		if ids[index] == selected: flight_list.select(index)
	var flight: Dictionary = sim.find_flight(selected)
	details.text = "Selected: " + selected + " / " + str(flight.get("state", "No active flight"))
	hint.text = sim.suggested_action(selected)
	runway_status.text = "RUNWAY 09  ·  " + ("AVAILABLE" if sim.runway_owner.is_empty() else "RESERVED: " + sim.runway_owner)
	runway_status.modulate = CYAN if sim.runway_owner.is_empty() else Color("ffd269")
	stats.text = "Cycles completed: %d    Safety errors: %d    Time: %02d:%02d" % [sim.departures, sim.errors, int(sim.elapsed) / 60, int(sim.elapsed) % 60]
	pause_button.text = "Resume" if sim.paused else "Pause"
	tower_button.modulate = CYAN if sim.position == "Tower" else WHITE
	ground_button.modulate = CYAN if sim.position == "Ground" else WHITE
	var transcript := "\n\n".join(sim.radio)
	if transcript != last_radio:
		radio.text = transcript
		last_radio = transcript
