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
var visuals: Node3D
var view_index := 0

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
	if OS.get_cmdline_user_args().has("--showcase"):
		sim.command(selected, "land")
		sim.tick(30.0)
		_set_view(2)
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
				model.rotation.y = lerp_angle(model.rotation.y, atan2(-flat.x, -flat.z), minf(delta * 4.0, 1.0))
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
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("547f9f")
	atmosphere.sky_horizon_color = Color("c9d8d6")
	atmosphere.ground_horizon_color = Color("c9d8d6")
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c3d2df")
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -38, 0)
	sun.light_color = Color("fff0d4")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260
	add_child(sun)
	visuals = preload("res://scripts/visuals.gd").new()
	add_child(visuals)
	visuals.airport()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	_set_view(0)
	camera.current = true

func _set_view(index: int) -> void:
	view_index = index
	if index == 0:
		camera.position = Vector3(-30, 68, 87)
		camera.size = 100
		camera.look_at(Vector3(17, 0, 12))
	elif index == 1:
		camera.position = Vector3(10, 34, 54)
		camera.size = 54
		camera.look_at(Vector3(20, 0, 20))
	else:
		camera.position = Vector3(-34, 18, 24)
		camera.size = 45
		camera.look_at(Vector3(18, 0, 0))

func _aircraft_model(id: String) -> Node3D:
	return visuals.aircraft(id)
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
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("233d4b")
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("356072")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("176b78")
	button.add_theme_stylebox_override("pressed", pressed)
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
	var title_panel := Panel.new()
	title_panel.position = Vector2(16, 14)
	title_panel.size = Vector2(730, 110)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("101c2cdd")
	title_style.set_corner_radius_all(8)
	title_panel.add_theme_stylebox_override("panel", title_style)
	root.add_child(title_panel)
	var banner := VBoxContainer.new()
	banner.position = Vector2(28, 22)
	banner.size = Vector2(830, 110)
	root.add_child(banner)
	_label(banner, "ATC ROLE SURVIVOR", 30, WHITE)
	_label(banner, "HARBOR FIELD / GROUND + TOWER / VISUAL PREVIEW 0.2", 15, CYAN)
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
	_label(controls, "One full cycle: land / exit / gate / turnaround / pushback / taxi / takeoff. Switch positions when prompted. Traffic is added manually.", 13, Color("a8bbcd"))
	var views := HBoxContainer.new()
	views.position = Vector2(28, 140)
	root.add_child(views)
	_button(views, "Airport", func(): _set_view(0))
	_button(views, "Apron close-up", func(): _set_view(1))
	_button(views, "Runway view", func(): _set_view(2))
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



