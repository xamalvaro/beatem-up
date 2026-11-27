extends CanvasLayer

# Press F3 in game to toggle. Shows what the game thinks is happening so you
# can tune frame data by feel: current state, frame counter inside the state,
# buffered inputs, hitstop, and each zombie's state.

var _label: Label
var _last_state: String = ""
var _state_frames: int = 0

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(8, 40)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		visible = not visible

func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or not player.state_machine or not player.state_machine.current_state:
		return
	var st := String(player.state_machine.current_state.name)
	if st != _last_state:
		_last_state = st
		_state_frames = 0
	elif not GameFeel.is_frozen():
		_state_frames += 1
	if not visible:
		return

	var lines: PackedStringArray = [
		"FPS %d" % Engine.get_frames_per_second(),
		"State: %s  (frame %d)" % [st, _state_frames],
		"HP %d/%d  stagger %d  %s%s" % [player.current_health, player.max_health, player.stagger_hits,
			"INVINCIBLE " if player.is_invincible else "", "GRABBED" if player.is_grabbed else ""],
		"Buffer: " + player.input_buffer.debug_string(),
		"Hitstop: " + ("YES" if GameFeel.is_frozen() else "no"),
	]
	for e in get_tree().get_nodes_in_group("enemy"):
		lines.append("%s: %s  HP %d" % [e.name, e.S.keys()[e.state], e.hit_points])
	_label.text = "\n".join(lines)
