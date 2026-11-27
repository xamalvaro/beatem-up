extends State

# Held by a zombie: mash attack_a to fill the struggle meter and break free.

const FILL_PER_MASH: float = 0.25
const DECAY_PER_SECOND: float = 0.15
const DAMAGE_PER_SECOND: float = 5.0

var struggle_meter: float = 0.0
var damage_accumulator: float = 0.0

func enter() -> void:
	struggle_meter = 0.0
	damage_accumulator = 0.0
	player.velocity = Vector2.ZERO
	player.sprite.play("struggle")
	player.struggle_ui.show_ui()

func exit() -> void:
	struggle_meter = 0.0
	player.struggle_ui.hide_ui()
	player.input_buffer.clear()  # Don't let leftover mash presses fire a stomp

func physics_update(delta: float) -> void:
	player.velocity.x = 0
	if player.is_on_floor():
		player.velocity.y = 0
	player.apply_gravity(delta)

	# Damage while held (this used to be silently blocked)
	damage_accumulator += DAMAGE_PER_SECOND * delta
	if damage_accumulator >= 1.0:
		var dmg := int(damage_accumulator)
		damage_accumulator -= dmg
		player.take_grab_damage(dmg)
		if player.is_dead:
			return

	struggle_meter = clamp(struggle_meter - DECAY_PER_SECOND * delta, 0.0, 1.0)
	if player.input_buffer.consume(&"attack_a"):
		struggle_meter = clamp(struggle_meter + FILL_PER_MASH, 0.0, 1.0)
	player.struggle_ui.set_meter(struggle_meter)

	if struggle_meter >= 1.0:
		_break_free()
		return

	player.move_and_slide()

func _break_free() -> void:
	var zombie := player.grabbing_zombie
	if zombie and is_instance_valid(zombie):
		zombie.on_player_broke_free(player)
	player.release_grab()
