extends AttackState

func _ready() -> void:
	attack_damage = 15
	attack_duration = 0.4
	attack_animation = "stomp"
	can_move_during_attack = false
	
	# Combo chains
	next_attack_a = "stomp2"  # Can chain to second stomp
	next_attack_b = ""         # No B chain yet (no animation)
	
	# Directional combos
	directional_attacks = {
		"down_a": "sweep",      # Down+A = sweep kick
		"down_b": "crouch"      # Down+B = go to crouch
	}
