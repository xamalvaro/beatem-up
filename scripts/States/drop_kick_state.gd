extends AttackState

var has_landed: bool = false
var land_timer: float = 0.0
var land_recovery_time: float = 0.3

func _ready() -> void:
	attack_damage = 2       # Dropkick hits harder than a punch
	attack_duration = 999.0 # Don't use the timer — we control end via landing
	attack_animation = "drop_kick"
	can_move_during_attack = true
	combo_window = 0.0
	next_attack_a = ""
	next_attack_b = ""
	directional_attacks = {}

func enter() -> void:
	has_landed = false
	land_timer = 0.0
	# Call super.enter() to enable hitbox and play animation
	super.enter()
	# Reposition hitbox forward and slightly downward for a diving kick
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 2
	# Debug — confirm hitbox is actually active after enter
	var hitbox = player.get_node_or_null("PunchHitBox")
	print(">>> DROP KICK entered. Hitbox monitoring: " + str(hitbox.monitoring if hitbox else "NOT FOUND"))
	print(">>> DROP KICK damage meta: " + str(hitbox.get_meta("damage", "NOT SET") if hitbox else "N/A"))

func exit() -> void:
	super.exit()
	# Reset hitbox y offset
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 0
	print(">>> Exited DROP KICK state")

func physics_update(delta: float) -> void:
	# Apply gravity faster than normal for a snappy dive
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta * 1.5
	else:
		if not has_landed:
			has_landed = true
			player.velocity.x = 0
			# Debug — check hitbox state at landing moment
			var hitbox = player.get_node_or_null("PunchHitBox")
			print(">>> DROP KICK landed. Hitbox monitoring at landing: " + str(hitbox.monitoring if hitbox else "NOT FOUND"))
			# Disable hitbox the moment we land — no damage on the ground
			_disable_hitbox()
			print(">>> DROP KICK landed - recovery phase")

		land_timer += delta
		if land_timer >= land_recovery_time:
			print(">>> DROP KICK recovery complete, returning to idle")
			transitioned.emit("idle")
			return

	# Keep direction updated while airborne
	if not has_landed:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.4
			player.get_node("AnimatedSprite2D").flip_h = direction < 0

		# Keep hitbox flipping correctly mid-air
		var hitbox = player.get_node_or_null("PunchHitBox")
		if hitbox and hitbox.monitoring:
			_update_hitbox_direction(hitbox)

	player.move_and_slide()
