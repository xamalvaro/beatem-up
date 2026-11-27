extends Node

# Global "juice": hitstop (freeze frames), screen shake and hit sparks.
# Registered as the GameFeel autoload in project settings.

var _freeze_frames: int = 0
var _shake: float = 0.0
const SHAKE_DECAY: float = 40.0   # Strength lost per second

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Run before gameplay nodes so the freeze count is current for this frame
	process_physics_priority = -100

# Freeze all fighters for `frames` physics frames. Overlapping calls keep the longest.
func hitstop(frames: int) -> void:
	_freeze_frames = max(_freeze_frames, frames)

func is_frozen() -> bool:
	return _freeze_frames > 0

func shake(strength: float) -> void:
	_shake = max(_shake, strength)

func spark(at: Vector2, parent: Node = null) -> void:
	var s := HitSpark.new()
	s.global_position = at
	(parent if parent else get_tree().current_scene).add_child(s)

func _physics_process(_delta: float) -> void:
	if _freeze_frames > 0:
		_freeze_frames -= 1

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	if _shake > 0.0:
		cam.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = max(0.0, _shake - SHAKE_DECAY * delta)
	elif cam.offset != Vector2.ZERO:
		cam.offset = Vector2.ZERO

# Tiny procedural impact star — placeholder until there's spark art.
class HitSpark extends Node2D:
	var life: float = 0.12
	var age: float = 0.0
	func _ready() -> void:
		z_index = 10
		rotation = randf() * TAU
	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var t := age / life
		var r := lerpf(3.0, 9.0, t)
		var col := Color(1, 1, 0.8, 1.0 - t)
		for i in 4:
			var dir := Vector2.RIGHT.rotated(i * PI / 4.0)
			draw_line(-dir * r, dir * r, col, 1.5)
