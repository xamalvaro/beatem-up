extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.4
	attack_animation = "stomp"
	can_move_during_attack = false
	combo_window = 0.4
	next_attack_a = "stomp2"
	next_attack_b = ""
	directional_attacks = {
		"down_a": "sweep",
		"down_b": "crouch"
	}

func enter() -> void:
	super.enter()
	print(">>> Entered STOMP 1 state")

func exit() -> void:
	super.exit()  # CRITICAL — disables hitbox before next state enters
	print(">>> Exited STOMP 1 state")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
