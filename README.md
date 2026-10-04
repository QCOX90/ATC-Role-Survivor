# ATC Role Survivor

A Godot 4.7.2 prototype for a controller-position game. The first playable slice uses a fictional airport, one runway, a parallel taxiway, three gates, and one simple aircraft model.

## Play

Import `project.godot` in the standard Godot editor and press **F5**. No .NET SDK, account, external models, or paid license is required. The project can be run directly with the standard Godot executable as well.

1. Select **SUR101**, stay on **Tower**, and choose **Clear to land**.
2. After landing, choose **Exit runway**.
3. Switch to **Ground**, choose **Taxi to gate**, and wait for turnaround.
4. Choose **Approve pushback**, then **Taxi runway 09**.
5. When holding short, switch to **Tower** and choose **Clear for takeoff**.

Use **+ Arrival** to add traffic (three active aircraft maximum), **Pause / Resume** to freeze movement, and **Reset** to restart. A cycle completes when an aircraft departs.

Typed instructions use the selected aircraft unless a valid active callsign is supplied. Examples: `SUR101, cleared to land`, `exit runway`, `taxi to gate`, `pushback approved`, `taxi runway 09`, and `cleared for takeoff`. This first parser recognizes a small vocabulary; it is not a full natural-language or FAA phraseology engine.

## Current behavior

- Procedural 3D airport and aircraft; Ground / Tower position switching.
- Complete arrival–departure lifecycle with pilot requests and readbacks.
- Runway reservations block conflicting landing / takeoff clearances.
- Aircraft stop at the hold-short point before takeoff.
- Three gate reservations, manual traffic spawning, a traffic overview, elapsed time, completed cycles, and safety-error count.

## Limits

Movement, geometry, speeds, and clearances are simplified game mechanics. This is a fictional early prototype, not certified training software. Surface traffic collision avoidance, wake separation, go-arounds, voice commands, radar vectoring, career lessons, grades, persistence, and realistic timing are not implemented yet. Runway reservation starts at clearance time and ends at exit / departure; this is intentionally conservative.

## Source

- `scripts/operations.gd`: simulation rules and text commands.
- `scripts/airport.gd`: 3D view and controls.
- `scripts/radar.gd`: schematic traffic overview.
- `tests/operations_test.gd`: lifecycle, pause, hold-short, position, callsign, and runway-conflict checks.

Run checks: `godot --headless --path . --script res://tests/operations_test.gd`.

All coding for this project is handled through Codex. Godot's generated `.godot` cache is excluded from version control. The earlier Memphis browser trainer remains a separate repository.
