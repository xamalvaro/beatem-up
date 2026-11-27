extends AttackState

# Diving kick: hitbox stays on from startup until landing, then recovery.

var has_landed: bool = false
var land_timer: float = 0.0

func enter() -> void:
	has_landed = false
	land_timer = 0.0
	super.enter()

func physics_update(delta: float) -> void:
	if not has_landed:
		attack_timer += delta
		player.apply_gravity(delta, data.gravity_multiplier)
		var direction := player.get_move_input()
		if direction != 0:
			player.velocity.x = direction * player.SPEED * data.air_control
			player.face(direction)
		update_hitbox()
		player.move_and_slide()
		if player.is_on_floor():
			has_landed = true
			player.velocity.x = 0
			player.hitbox.deactivate()
		return

	land_timer += delta
	if land_timer >= data.recovery / AttackData.FPS:
		transitioned.emit(neutral_state())
		return
	player.velocity.x = 0
	player.move_and_slide()
