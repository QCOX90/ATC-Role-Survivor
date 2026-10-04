extends RefCounted
## Simulation rules are independent of the 3D presentation.

var aircraft: Array[Dictionary] = []
var runway_owner := ""
var position := "Tower"
var paused := false
var elapsed := 0.0
var departures := 0
var errors := 0
var serial := 101
var radio: Array[String] = []
const GATES := [-27.0, -9.0, 9.0, 27.0]

func _init() -> void:
	spawn_arrival()
	_note("Welcome to Harbor Field. Select a flight, then issue a clearance.")

func spawn_arrival() -> String:
	if aircraft.size() >= 4:
		_note("Traffic limit reached. Work the four active flights first.")
		return ""
	var id := "SUR" + str(serial)
	serial += 1
	aircraft.append({"id": id, "state": "Inbound", "pos": Vector3(-72, 18, 0),
		"route": [], "next_state": "", "speed": 8.0, "gate": -1, "timer": 0.0})
	_note(id + ": inbound runway 09, request landing clearance.")
	return id

func find_flight(id: String) -> Dictionary:
	for flight in aircraft:
		if flight.id == id:
			return flight
	return {}

func tick(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	var completed: Array[String] = []
	for flight in aircraft:
		if flight.state == "Turnaround":
			flight.timer -= delta
			if flight.timer <= 0:
				flight.state = "Ready for pushback"
				_note(flight.id + ": turnaround complete, request pushback.")
		if flight.route.is_empty():
			continue
		var budget: float = flight.speed * delta
		while budget > 0 and not flight.route.is_empty():
			var target: Vector3 = flight.route[0]
			var distance: float = flight.pos.distance_to(target)
			if budget >= distance:
				flight.pos = target
				flight.route.pop_front()
				budget -= distance
			else:
				flight.pos = flight.pos.move_toward(target, budget)
				budget = 0
		if flight.route.is_empty():
			flight.state = flight.next_state
			match flight.state:
				"Landed":
					_note(flight.id + ": landing complete, request runway exit.")
				"Clear of runway":
					runway_owner = ""
					_note(flight.id + ": runway vacated. Contacting Ground.")
				"Turnaround":
					flight.timer = 12.0
					_note(flight.id + ": parked at gate " + str(flight.gate + 1) + ". Turning around.")
				"On taxiway":
					_note(flight.id + ": pushback complete, request taxi runway 09.")
				"Holding short":
					_note(flight.id + ": holding short runway 09. Contacting Tower.")
				"Departed":
					runway_owner = ""
					departures += 1
					_note(flight.id + ": airborne. Full aircraft cycle completed.")
					completed.append(flight.id)
	for id in completed:
		var flight := find_flight(id)
		aircraft.erase(flight)

func _route(flight: Dictionary, points: Array, moving_state: String, next_state: String, speed: float) -> void:
	flight.route = points.duplicate()
	flight.state = moving_state
	flight.next_state = next_state
	flight.speed = speed

func command(id: String, action: String) -> bool:
	var flight := find_flight(id)
	if flight.is_empty():
		return _reject("Select an active flight first.", false)
	var required := "Tower" if action in ["land", "exit", "takeoff"] else "Ground"
	if position != required:
		return _reject("Switch to " + required + " to issue this clearance.", false)
	match action:
		"land":
			if flight.state != "Inbound":
				return _reject(id + ": not awaiting landing clearance.", false)
			if not runway_owner.is_empty():
				return _reject("Unsafe landing clearance: runway reserved by " + runway_owner + ".")
			runway_owner = id
			_route(flight, [Vector3(-38, 0.8, 0), Vector3(12, 0.8, 0)], "Landing", "Landed", 10)
			_note(id + ": runway 09, cleared to land.")
		"exit":
			if flight.state != "Landed":
				return _reject(id + ": must finish landing before exiting.", false)
			_route(flight, [Vector3(12, 0.8, 12)], "Exiting runway", "Clear of runway", 3)
			_note(id + ": exit via Bravo, contact Ground.")
		"gate":
			if flight.state != "Clear of runway":
				return _reject(id + ": taxi to gate requires a vacated runway.", false)
			var gate := _free_gate()
			if gate < 0:
				return _reject("All gates are occupied or reserved. Depart another flight first.", false)
			flight.gate = gate
			_route(flight, [Vector3(GATES[gate], 0.8, 12), Vector3(GATES[gate], 0.8, 24)], "Taxi to gate", "Turnaround", 3)
			_note(id + ": taxi gate " + str(gate + 1) + " via Alpha.")
		"pushback":
			if flight.state != "Ready for pushback":
				return _reject(id + ": pushback available after turnaround.", false)
			_route(flight, [Vector3(GATES[flight.gate], 0.8, 12)], "Pushing back", "On taxiway", 2)
			_note(id + ": pushback approved.")
		"taxi":
			if flight.state != "On taxiway":
				return _reject(id + ": complete pushback before taxiing.", false)
			flight.gate = -1
			_route(flight, [Vector3(-42, 0.8, 12), Vector3(-42, 0.8, 6)], "Taxi to runway", "Holding short", 3)
			_note(id + ": taxi runway 09 via Alpha, hold short runway 09.")
		"takeoff":
			if flight.state != "Holding short":
				return _reject(id + ": must taxi and hold short before takeoff.", false)
			if not runway_owner.is_empty():
				return _reject("Unsafe takeoff clearance: runway reserved by " + runway_owner + ".")
			runway_owner = id
			_route(flight, [Vector3(-42, 0.8, 0), Vector3(35, 0.8, 0), Vector3(78, 24, 0)], "Taking off", "Departed", 11)
			_note(id + ": runway 09, cleared for takeoff.")
		_:
			return _reject("Instruction not recognized.", false)
	return true

func text_command(selected_id: String, text: String) -> bool:
	var instruction := text.to_lower().strip_edges().replace("-", " ")
	var id := selected_id
	for flight in aircraft:
		if instruction.contains(flight.id.to_lower()):
			id = flight.id
			instruction = instruction.replace(flight.id.to_lower(), "")
	if instruction.contains("sur"):
		return _reject("Unknown callsign. Use an active SUR callsign or omit it for the selected flight.", false)
	if instruction.contains("cancel") or instruction.contains("not cleared"):
		return _reject("Cancellation instructions are not supported in this prototype.", false)
	if instruction.contains("takeoff") or instruction.contains("take off"):
		return command(id, "takeoff")
	if instruction.contains("land"):
		return command(id, "land")
	if instruction.contains("exit") or instruction.contains("vacate"):
		return command(id, "exit")
	if instruction.contains("pushback") or instruction.contains("push back"):
		return command(id, "pushback")
	if instruction.contains("gate"):
		return command(id, "gate")
	if instruction.contains("taxi") and instruction.contains("runway"):
		return command(id, "taxi")
	return _reject("Try: cleared to land, exit runway, taxi to gate, pushback approved, taxi runway 09, or cleared for takeoff.", false)

func _free_gate() -> int:
	for gate in range(GATES.size()):
		var occupied := false
		for flight in aircraft:
			if flight.gate == gate:
				occupied = true
		if not occupied:
			return gate
	return -1

func _reject(message: String, safety_error: bool = true) -> bool:
	if safety_error:
		errors += 1
	_note("CONTROL CHECK: " + message)
	return false

func _note(message: String) -> void:
	radio.append(message)
	if radio.size() > 80:
		radio.pop_front()

func suggested_action(id: String) -> String:
	var flight := find_flight(id)
	if flight.is_empty():
		return "Spawn an arrival to start a new aircraft cycle."
	match flight.state:
		"Inbound": return "Tower → Clear to land"
		"Landed": return "Tower → Exit runway"
		"Clear of runway": return "Ground → Taxi to gate"
		"Ready for pushback": return "Ground → Approve pushback"
		"On taxiway": return "Ground → Taxi runway 09"
		"Holding short": return "Tower → Clear for takeoff"
		"Turnaround": return "Wait for the turnaround to finish."
		_: return "Aircraft is moving. Wait for its next request."

