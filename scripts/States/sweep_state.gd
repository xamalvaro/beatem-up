extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.5
	attack_animation = "sweep"
	can_move_during_attack = false
	combo_window = 0.4
	next_attack_a = "stomp"
	next_attack_b = ""
	directional_attacks = {}

func enter() -> void:
	super.enter()
	# Reposition hitbox low and wide for a sweep kick
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 4  # Lower than a punch — near ground level
	print(">>> Entered SWEEP state")

func exit() -> void:
	super.exit()
	# Reset hitbox y position back to default punch height
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 0
	print(">>> Exited SWEEP state")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
