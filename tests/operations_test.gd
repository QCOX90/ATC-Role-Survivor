extends SceneTree
const Operations = preload("res://scripts/operations.gd")
var checks := 0

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error("FAILED: " + message)
		quit(1)

func _initialize() -> void:
	var sim = Operations.new()
	var id := "SUR101"
	verify(sim.command(id, "land"), "Landing clearance accepted")
	var second: String = sim.spawn_arrival()
	verify(not sim.command(second, "land"), "Conflicting landing blocked")
	verify(sim.errors == 1 and sim.runway_owner == id, "Runway reservation retained")
	sim.paused = true
	var before: Vector3 = sim.find_flight(id).pos
	sim.tick(20)
	verify(sim.find_flight(id).pos == before and sim.elapsed == 0, "Pause freezes movement and clock")
	sim.paused = false
	sim.tick(130)
	verify(sim.find_flight(id).state == "Landed", "Landing finishes")
	verify(sim.command(id, "exit"), "Runway exit accepted")
	sim.tick(10)
	verify(sim.runway_owner.is_empty(), "Runway released only after exit")
	verify(not sim.command(id, "gate"), "Tower cannot issue Ground clearance")
	sim.position = "Ground"
	verify(sim.text_command(id, "SUR101 taxi to gate"), "Typed taxi instruction accepted")
	sim.tick(30)
	verify(sim.find_flight(id).state == "Turnaround", "Aircraft parks")
	sim.tick(13)
	verify(sim.find_flight(id).state == "Ready for pushback", "Turnaround finishes")
	verify(sim.text_command(id, "SUR999 pushback approved") == false, "Unknown callsign rejected")
	verify(sim.text_command(id, "SUR101 pushback approved"), "Pushback accepted")
	sim.tick(10)
	verify(sim.command(id, "taxi"), "Taxi to runway accepted")
	sim.tick(30)
	verify(sim.find_flight(id).state == "Holding short", "Aircraft stops at hold line")
	verify(sim.find_flight(id).pos.z == 6, "Aircraft remains outside runway")
	sim.position = "Tower"
	verify(sim.command(id, "takeoff"), "Takeoff clearance accepted")
	var next_arrival: String = sim.spawn_arrival()
	verify(not sim.command(next_arrival, "land"), "Landing during takeoff blocked")
	sim.tick(20)
	verify(sim.departures == 1 and sim.find_flight(id).is_empty(), "Full cycle completed")
	verify(sim.runway_owner.is_empty(), "Departure releases runway")
	verify(sim.command(next_arrival, "land"), "Next arrival can use runway")
	var gates_sim = Operations.new()
	gates_sim.position = "Ground"
	for gate in range(4):
		var gate_id: String = "SUR101" if gate == 0 else gates_sim.spawn_arrival()
		var parked: Dictionary = gates_sim.find_flight(gate_id)
		parked.state = "Clear of runway"
		parked.pos = Vector3(12, 0.8, 12)
		verify(gates_sim.command(gate_id, "gate"), "Every gate accepts a reservation")
		verify(parked.gate == gate, "Gate reservations remain distinct")
	verify(gates_sim.spawn_arrival().is_empty(), "Four-flight capacity is enforced")
	var approach_sim = Operations.new()
	var inbound: Dictionary = approach_sim.find_flight("SUR101")
	var initial: Vector3 = inbound.pos
	verify(is_equal_approx((Operations.THRESHOLD_X - initial.x) * Operations.METERS_PER_UNIT / 1852.0, 4.0), "Arrival starts four nautical miles away")
	verify(is_equal_approx(inbound.heading, -PI / 2.0), "Arrival initially faces runway heading")
	approach_sim.tick(10)
	verify(inbound.pos.x > initial.x and inbound.pos.y < initial.y, "Uncleared arrival flies and descends")
	approach_sim.tick(80)
	verify(inbound.state == "Going around" and inbound.pos.y > 2, "Uncleared approach climbs instead of landing")
	verify(approach_sim.runway_owner.is_empty(), "Missed approach does not reserve runway")
	verify(not approach_sim.command("SUR101", "land"), "Late landing clearance rejected after go-around")
	approach_sim.tick(400)
	verify(inbound.state == "Inbound" and not inbound.route.is_empty(), "Missed approach rejoins a moving final")
	var cleared_sim = Operations.new()
	cleared_sim.tick(10)
	var before_clearance: Vector3 = cleared_sim.find_flight("SUR101").pos
	verify(cleared_sim.command("SUR101", "land"), "Moving approach accepts clearance")
	verify(cleared_sim.find_flight("SUR101").pos == before_clearance, "Clearance does not teleport aircraft")
	cleared_sim.tick(130)
	verify(cleared_sim.find_flight("SUR101").state == "Landed", "Cleared approach touches down and rolls out")
	var reverse_sim = Operations.new()
	reverse_sim.position = "Ground"
	var reverse_flight: Dictionary = reverse_sim.find_flight("SUR101")
	reverse_flight.state = "Ready for pushback"
	reverse_flight.route = []
	reverse_flight.gate = 0
	reverse_flight.pos = Vector3(Operations.GATES[0], 0.8, 24)
	reverse_flight.heading = PI
	verify(reverse_sim.command("SUR101", "pushback"), "Pushback accepted from parked gate")
	var parked_position: Vector3 = reverse_flight.pos
	reverse_sim.tick(0.5)
	var forward := Vector3(-sin(reverse_flight.heading), 0, -cos(reverse_flight.heading))
	verify(forward.dot(reverse_flight.pos - parked_position) < 0, "Pushback displacement is behind the aircraft nose")
	verify(absf(wrapf(reverse_flight.heading - PI, -PI, PI)) < 0.01, "Initial pushback does not flip the aircraft")
	reverse_sim.tick(20)
	verify(reverse_flight.state == "On taxiway" and is_equal_approx(reverse_flight.heading, PI / 2.0), "Pushback ends facing the outbound taxi direction")
	verify(reverse_flight.pos.x > Operations.GATES[0] and reverse_flight.pos.z == 12, "Curved reverse path reaches taxiway")
	var fast_sim = Operations.new()
	fast_sim.time_scale = 8
	fast_sim.command("SUR101", "land")
	var normal_sim = Operations.new()
	normal_sim.command("SUR101", "land")
	fast_sim.tick(1)
	normal_sim.tick(8)
	verify(fast_sim.find_flight("SUR101").pos.is_equal_approx(normal_sim.find_flight("SUR101").pos), "Eight-times speed matches normal elapsed simulation time")
	fast_sim.paused = true
	var fast_position: Vector3 = fast_sim.find_flight("SUR101").pos
	fast_sim.tick(20)
	verify(fast_sim.find_flight("SUR101").pos == fast_position, "Pause still freezes accelerated simulation")
	var fast_uncleared = Operations.new()
	fast_uncleared.time_scale = 8
	fast_uncleared.tick(12)
	verify(fast_uncleared.find_flight("SUR101").state == "Going around", "Accelerated time preserves the uncleared approach decision")
	print("PASS: ", checks, " operational checks, including complete aircraft lifecycle")
	quit(0)

