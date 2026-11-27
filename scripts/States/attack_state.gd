extends State
class_name AttackState

# Attack timeline:
#
#   0 ──── attack_duration ──── + recovery ──→ back to neutral
#   [ hitbox on            ][ hitbox off    ]
#              ^ cancel_start            ^ move_cancel_start
#
# - Combo presses made ANY time during the attack are remembered (input buffer)
#   and fire as soon as the cancel point is reached, so mashing never drops inputs.
# - After the attack, the player returns to neutral right away instead of
#   being frozen for a combo window.
# - Movement / jump can cut the end of the recovery short.

@export var attack_duration: float = 0.4   # Hitbox active time
@export var recovery: float = 0.1          # Hitbox off, still committed
@export var cancel_ratio: float = 0.7      # Fraction of attack_duration before a combo can cancel
@export var move_cancel_ratio: float = 0.5 # Fraction of recovery before move/jump can cancel
@export var can_move_during_attack: bool = false
@export var attack_animation: String = "stomp"
@export var fit_animation: bool = true     # Speed the animation up/down to match the attack length

# Base damage — axe doubles it
@export var attack_damage: int = 1
const AXE_ITEM_NAME: String = "Fireman Axe"

# Combo routes
@export var next_attack_a: String = ""
@export var next_attack_b: String = ""
@export var directional_attacks: Dictionary = {}  # "down_a" / "down_b" -> state name

var attack_timer: float = 0.0
var attack_finished: bool = false

func enter() -> void:
	attack_timer = 0.0
	attack_finished = false
	player.velocity.x = 0

	# Turn around at the start of each attack (lets you combo enemies on both sides)
	player.face(player.get_move_input())

	player.sprite.play(attack_animation)
	if fit_animation:
		_fit_animation_speed()
	_enable_hitbox()

func exit() -> void:
	_disable_hitbox()
	player.sprite.speed_scale = 1.0

func _fit_animation_speed() -> void:
	var frames: SpriteFrames = player.sprite.sprite_frames
	if not frames or not frames.has_animation(attack_animation):
		return
	var fps: float = frames.get_animation_speed(attack_animation)
	var total := attack_duration + recovery
	if fps <= 0.0 or total <= 0.0:
		return
	var anim_length: float = frames.get_frame_count(attack_animation) / fps
	player.sprite.speed_scale = anim_length / total

func _enable_hitbox() -> void:
	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox:
		hitbox.set_meta("damage", _get_attack_damage())
		hitbox.get_node("CollisionShape2D").disabled = false
		hitbox.monitoring = true
		_update_hitbox_direction(hitbox)

func _disable_hitbox() -> void:
	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _update_hitbox_direction(hitbox: Node) -> void:
	# Move the CollisionShape2D child, not the Area2D parent.
	var shape = hitbox.get_node_or_null("CollisionShape2D")
	if shape:
		shape.position.x = abs(shape.position.x) * (-1 if player.sprite.flip_h else 1)

func _get_attack_damage() -> int:
	var inventory = player.get_node_or_null("Inventory")
	if inventory and inventory.equipped_item:
		if inventory.equipped_item.item_name == AXE_ITEM_NAME:
			return attack_damage * 2
	return attack_damage

# Returns the state to combo into if a combo button was pressed during this
# attack, or "" if none. Presses are remembered for the whole attack.
func _get_buffered_combo() -> String:
	var buf: InputBuffer = player.input_buffer
	var window := attack_timer + InputBuffer.DEFAULT_WINDOW
	var is_down := Input.is_action_pressed("ui_down")

	if buf.peek(&"attack_a", window):
		var target: String = directional_attacks.get("down_a", "") if is_down else ""
		if target == "":
			target = next_attack_a
		if target != "":
			buf.consume(&"attack_a", window)
			return target
	if buf.peek(&"attack_b", window):
		var target: String = directional_attacks.get("down_b", "") if is_down else ""
		if target == "":
			target = next_attack_b
		if target != "":
			buf.consume(&"attack_b", window)
			return target
	return ""

func physics_update(delta: float) -> void:
	attack_timer += delta
	player.apply_gravity(delta)

	if can_move_during_attack:
		var direction = player.get_move_input()
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.5
			player.face(direction)
	else:
		player.velocity.x = 0

	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox and hitbox.monitoring:
		_update_hitbox_direction(hitbox)

	# End of active frames — hitbox off
	if not attack_finished and attack_timer >= attack_duration:
		attack_finished = true
		_disable_hitbox()

	# Combo cancel (from late in the active frames onward)
	if attack_timer >= attack_duration * cancel_ratio:
		var combo := _get_buffered_combo()
		if combo != "":
			transitioned.emit(combo)
			return

	# Movement / jump cancel during the back half of recovery
	if attack_timer >= attack_duration + recovery * move_cancel_ratio:
		if player.input_buffer.peek(&"ui_accept", player.JUMP_BUFFER) or player.get_move_input() != 0:
			transitioned.emit("run" if player.get_move_input() != 0 else "idle")
			return

	# Attack fully over — straight back to neutral
	if attack_timer >= attack_duration + recovery:
		transitioned.emit("run" if player.get_move_input() != 0 else "idle")
		return

	player.move_and_slide()
