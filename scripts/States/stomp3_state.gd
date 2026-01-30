extends AttackState

func _ready() -> void:
	attack_damage = 30
	attack_duration = 0.5
	attack_animation = "stomp"
	can_move_during_attack = false
	
	# End of combo chain
	next_attack_a = ""
	next_attack_b = ""
	
	directional_attacks = {
		"down_a": "sweep"
	}
