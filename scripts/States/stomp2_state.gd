extends AttackState

func _ready() -> void:
	attack_damage = 1
	attack_duration = 0.3
	recovery = 0.14
	attack_animation = "stomp"
	next_attack_a = "stomp3"
	directional_attacks = {"down_a": "sweep"}
