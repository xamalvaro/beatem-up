extends Area2D

# Sits on PunchHitBox (Area2D) under the player.
# attack_state.gd enables/disables it and sets the "damage" meta.
#
# collision_mask = 1  →  hits the zombie CharacterBody2D (layer 1)
# Only disables itself after hitting a confirmed enemy — not the floor or walls.

func _ready() -> void:
	collision_layer = 32
	collision_mask = 1
	monitoring = false
	get_node("CollisionShape2D").disabled = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		var damage = get_meta("damage", 1)
		body.take_damage(damage)
		print(">>> Punch hit: " + body.name + " for " + str(damage) + " damage")
		# Only disable after a confirmed enemy hit
		set_deferred("monitoring", false)
		get_node("CollisionShape2D").set_deferred("disabled", true)
	else:
		print(">>> Hitbox touched non-enemy: " + body.name + " (ignored)")
