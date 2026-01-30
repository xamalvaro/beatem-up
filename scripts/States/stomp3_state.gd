extends AttackState

func _ready() -> void:
	attack_damage = 30
	attack_duration = 0.5
	attack_animation = "stomp"
	can_move_during_attack = false
	combo_window = 0.3
	
	# End of combo chain
	next_attack_a = ""
	next_attack_b = ""
	
	directional_attacks = {
		"down_a": "sweep"
	}

func enter() -> void:
	super.enter()
	print(">>> Entered STOMP 3 state (FINISHER!)")

func exit() -> void:
	print(">>> Exited STOMP 3 state")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if attack_finished and not can_combo:
		can_combo = true
		print(">>> STOMP 3 finished - combo chain ends")
