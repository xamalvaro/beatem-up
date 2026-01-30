extends AttackState

func _ready() -> void:
	attack_damage = 20
	attack_duration = 0.45
	attack_animation = "stomp"
	can_move_during_attack = false
	
	# Combo chains
	next_attack_a = "stomp3"  # Chain to third stomp (finisher)
	next_attack_b = ""
	
	directional_attacks = {
		"down_a": "sweep",
	}
