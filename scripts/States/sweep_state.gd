extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.4
	recovery = 0.2
	attack_animation = "sweep"
	next_attack_a = "stomp"
	directional_attacks = {}

func enter() -> void:
	super.enter()
	# Sweep kick hits low, near ground level
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 4

func exit() -> void:
	super.exit()
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 0
