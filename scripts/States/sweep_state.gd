extends AttackState

func _ready() -> void:
	attack_damage = 18
	attack_duration = 0.4
	attack_animation = "sweep"
	can_move_during_attack = false
	
	# After sweep, can combo into stomp or stay low
	next_attack_a = "stomp"
	next_attack_b = "crawl"  # Go into crawl position
	
	directional_attacks = {}
