extends RefCounted
class_name InputBuffer

# Remembers recent button presses so an input pressed slightly early
# (e.g. during an attack, or just before landing) still counts.
# The player calls update() once per physics frame BEFORE states run,
# and states call consume() instead of Input.is_action_just_pressed().

const ACTIONS: Array[StringName] = [&"attack_a", &"attack_b", &"ui_accept", &"crawl"]
const DEFAULT_WINDOW: float = 0.15  # ~9 frames at 60 fps

var _time: float = 0.0
var _pressed_at: Dictionary = {}

func update(delta: float) -> void:
	_time += delta
	for action in ACTIONS:
		if Input.is_action_just_pressed(action):
			_pressed_at[action] = _time

# True if `action` was pressed within the last `window` seconds. Clears it so
# one press only triggers one move.
func consume(action: StringName, window: float = DEFAULT_WINDOW) -> bool:
	if peek(action, window):
		_pressed_at.erase(action)
		return true
	return false

# Same as consume() but leaves the press in the buffer.
func peek(action: StringName, window: float = DEFAULT_WINDOW) -> bool:
	if not _pressed_at.has(action):
		return false
	return _time - _pressed_at[action] <= window

func clear() -> void:
	_pressed_at.clear()
