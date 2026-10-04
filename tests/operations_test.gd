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
	sim.tick(20)
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
	verify(not sim.command(second, "land"), "Landing during takeoff blocked")
	sim.tick(20)
	verify(sim.departures == 1 and sim.find_flight(id).is_empty(), "Full cycle completed")
	verify(sim.runway_owner.is_empty(), "Departure releases runway")
	verify(sim.command(second, "land"), "Next arrival can use runway")
	print("PASS: ", checks, " operational checks, including complete aircraft lifecycle")
	quit(0)
