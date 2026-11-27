extends State
class_name AttackState

# Generic attack driven by an AttackData resource (scripts/attacks/*.tres).
#
#   | startup | active (hitbox on) | recovery |
#
# - Combo presses made at ANY point in the attack are remembered and fire as
#   soon as a cancel is allowed: on hit (hit-confirm) or once active ends.
# - Movement/jump/dodge can cancel the second half of recovery.
# - When the attack ends you go straight back to neutral.

@export var data: AttackData

var attack_timer: float = 0.0
var has_hit: bool = false
var _hitbox_done: bool = false

func _ready() -> void:
	if data == null:
		push_error("AttackState '%s' has no AttackData" % name)

func enter() -> void:
	attack_timer = 0.0
	has_hit = false
	_hitbox_done = false
	player.velocity.x = 0

	# Turn around at the start of each attack (combo enemies on both sides)
	player.face(player.get_move_input())

	player.sprite.play(data.animation)
	if data.fit_animation:
		_fit_animation_speed(data.total_time())
	if not player.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.hitbox.hit_landed.connect(_on_hit_landed)

func exit() -> void:
	player.hitbox.deactivate()
	player.sprite.speed_scale = 1.0
	if player.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.hitbox.hit_landed.disconnect(_on_hit_landed)

func _on_hit_landed(_body: Node2D) -> void:
	has_hit = true

func _fit_animation_speed(total: float) -> void:
	var frames: SpriteFrames = player.sprite.sprite_frames
	if not frames or not frames.has_animation(data.animation) or total <= 0.0:
		return
	var fps: float = frames.get_animation_speed(data.animation)
	if fps <= 0.0:
		return
	var anim_length: float = frames.get_frame_count(data.animation) / fps
	player.sprite.speed_scale = anim_length / total

func get_damage() -> int:
	return int(round(data.damage * player.get_damage_multiplier()))

func facing() -> float:
	return -1.0 if player.sprite.flip_h else 1.0

# Hitbox on during [startup, startup + active). active < 0 = never auto-off.
func update_hitbox() -> void:
	if _hitbox_done:
		return
	if not player.hitbox.is_active() and attack_timer >= data.startup_time():
		player.hitbox.activate(data, get_damage(), facing())
	if player.hitbox.is_active():
		player.hitbox.set_facing(facing())
		if data.active >= 0 and attack_timer >= data.active_end_time():
			player.hitbox.deactivate()
			_hitbox_done = true

# State to combo into if a combo button was pressed during this attack.
func get_buffered_combo() -> String:
	var buf: InputBuffer = player.input_buffer
	var window := attack_timer + InputBuffer.DEFAULT_WINDOW
	var is_down := Input.is_action_pressed("ui_down")
	for pair in [[&"attack_a", data.down_a, data.next_a], [&"attack_b", data.down_b, data.next_b]]:
		if not buf.peek(pair[0], window):
			continue
		var target: String = pair[1] if is_down and pair[1] != "" else pair[2]
		if target != "":
			buf.consume(pair[0], window)
			return target
	return ""

func can_combo_cancel() -> bool:
	if data.forced_followup != "":
		return false
	if has_hit and attack_timer >= data.startup_time():
		return true  # Hit-confirm
	return data.active >= 0 and attack_timer >= data.active_end_time()

func neutral_state() -> String:
	if data.forced_followup != "":
		return data.forced_followup
	return "run" if player.get_move_input() != 0 else "idle"

func physics_update(delta: float) -> void:
	attack_timer += delta
	player.apply_gravity(delta, data.gravity_multiplier)

	var direction := player.get_move_input()
	if data.air_control > 0.0 and direction != 0:
		player.velocity.x = direction * player.SPEED * data.air_control
		player.face(direction)
	elif data.lunge_speed > 0.0 and attack_timer < data.active_end_time():
		player.velocity.x = data.lunge_speed * facing()
	elif player.is_on_floor():
		player.velocity.x = 0

	update_hitbox()

	if can_combo_cancel():
		var combo := get_buffered_combo()
		if combo != "":
			transitioned.emit(combo)
			return

	var total := data.total_time()
	# Movement / jump / dodge cancel in the back half of recovery
	if data.forced_followup == "" and attack_timer >= total - data.recovery / AttackData.FPS * 0.5:
		var buf: InputBuffer = player.input_buffer
		if buf.peek(&"ui_accept", player.JUMP_BUFFER) or buf.peek(&"dodge") or direction != 0:
			transitioned.emit(neutral_state())
			return

	if attack_timer >= total:
		transitioned.emit(neutral_state())
		return

	player.move_and_slide()
