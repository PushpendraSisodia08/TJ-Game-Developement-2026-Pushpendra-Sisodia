extends CanvasModulate

# Seconds spent transitioning between each pair of colors below.
const CYCLE_DURATION : float = 30.0

# Add/remove/reorder colors here to change the cycle. It loops back
# to COLORS[0] after the last one, so the sequence is seamless.
var colors : Array[Color] = [
	Color(1.0, 0.95, 0.85),   # day
	Color(1.0, 0.7, 0.55),    # dusk
	Color(0.35, 0.35, 0.55),  # night
	Color(1.0, 0.85, 0.7),    # dawn
]

var current_index : int = 0
var elapsed : float = 0.0

func _process(delta):
	elapsed += delta
	var t : float = elapsed / CYCLE_DURATION

	if t >= 1.0:
		elapsed = 0.0
		t = 0.0
		current_index = (current_index + 1) % colors.size()

	var next_index : int = (current_index + 1) % colors.size()
	color = colors[current_index].lerp(colors[next_index], t)
