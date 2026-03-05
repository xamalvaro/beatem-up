extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# Player stats
var max_health: int = 100
var current_health: int = 100
var speed_multiplier: float = 1.0
var speed_boost_timer: float = 0.0

# Invincibility frames after taking damage
var is_invincible: bool = false
var invincible_timer: float = 0.0
var invincible_duration: float = 0.5  # 0.5 seconds of iframes after each hit

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1  # Player body only — layer 2 is for enemies

func _physics_process(delta: float) -> void:
	# Handle speed boost timer
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_multiplier = 1.0
			print(">>> Speed boost expired")

	# Handle invincibility timer
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color(1, 1, 1)  # Restore full opacity

func take_damage(amount: int) -> void:
	# Ignore damage during iframes
	if is_invincible:
		return

	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	print(">>> Player took " + str(amount) + " damage. Health: " + str(current_health))

	# Start invincibility frames — player flickers to show iframes
	is_invincible = true
	invincible_timer = invincible_duration
	modulate = Color(1, 0.4, 0.4)  # Red tint during iframes

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)
	print(">>> Player healed " + str(amount) + " HP. Health: " + str(current_health))

func boost_speed(duration: float, multiplier: float) -> void:
	speed_multiplier = multiplier
	speed_boost_timer = duration
	print(">>> Speed boosted to " + str(multiplier) + "x for " + str(duration) + "s")

func die() -> void:
	died.emit()
	print(">>> Player died!")
	# Add death logic here later
