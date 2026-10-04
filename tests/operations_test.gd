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
	print("PASS: ", checks, " operational checks, including complete aircraft lifecycle")
	quit(0)

