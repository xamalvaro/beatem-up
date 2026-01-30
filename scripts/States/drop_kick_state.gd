extends AttackState

func _ready() -> void:
	attack_damage = 25
	attack_duration = 0.6
	attack_animation = "drop_kick"
	can_move_during_attack = true  # Can drift during aerial attack
	
	# No combos in air

func enter() -> void:
	super.enter()
	# Add downward velocity for drop kick
	player.velocity.y = 150  # Downward momentum

func physics_update(delta: float) -> void:
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	else:
		# Land and finish attack
		if not attack_finished:
			attack_finished = true
			attack_timer = attack_duration  # Force finish
	
	# Allow air control
	if can_move_during_attack:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.5
			player.get_node("AnimatedSprite2D").flip_h = direction < 0
	
	# When attack is done and on ground
	if attack_finished and player.is_on_floor():
		transitioned.emit("idle")
	
	player.move_and_slide()
