extends AttackState

func _ready() -> void:
	attack_damage = 15
	attack_duration = 0.4
	attack_animation = "stomp"
	can_move_during_attack = false
	combo_window = 0.4
	
	# Combo chains
	next_attack_a = "stomp2"
	next_attack_b = ""
	
	# Directional combos
	directional_attacks = {
		"down_a": "sweep",
		"down_b": "crouch"
	}

func enter() -> void:
	super.enter()
	print(">>> Entered STOMP 1 state")

func exit() -> void:
	print(">>> Exited STOMP 1 state")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Additional debug when combo is ready
	if attack_finished and not can_combo:
		can_combo = true
		print(">>> STOMP 1 finished - can combo now!")
