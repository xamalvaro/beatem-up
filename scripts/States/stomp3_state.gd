extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.35
	recovery = 0.25
	attack_animation = "stomp"
	next_attack_a = ""
	directional_attacks = {"down_a": "sweep"}
