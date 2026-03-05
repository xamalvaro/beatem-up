extends Area2D

# This script lives on the PunchHitBox node under the player.
# attack_state.gd enables/disables it and sets the "damage" meta value.
# Collision layer 32 — detected by enemies on mask 32.

func _ready() -> void:
	collision_layer = 32  # Player punch hitbox layer
	collision_mask = 2    # Detects enemy bodies (layer 2)
	monitoring = false
	get_node("CollisionShape2D").disabled = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		var damage = get_meta("damage", 1)
		body.take_damage(damage)
		print(">>> Punch hit: " + body.name + " for " + str(damage) + " damage")
		# Disable after first hit so one swing can't hit same enemy twice
		monitoring = false
		get_node("CollisionShape2D").disabled = true
