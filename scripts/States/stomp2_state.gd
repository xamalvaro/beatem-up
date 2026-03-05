extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.45
	attack_animation = "stomp"
	can_move_during_attack = false
	combo_window = 0.4
	next_attack_a = "stomp3"
	next_attack_b = ""
	directional_attacks = {
		"down_a": "sweep",
	}

func enter() -> void:
	super.enter()
	print(">>> Entered STOMP 2 state (COMBO!)")

func exit() -> void:
	super.exit()  # CRITICAL — disables hitbox before next state enters
	print(">>> Exited STOMP 2 state")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
