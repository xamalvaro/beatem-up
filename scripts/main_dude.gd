extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# Player stats
var max_health: int = 100
var current_health: int = 100
var speed_multiplier: float = 1.0  # For speed boosts
var speed_boost_timer: float = 0.0

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Handle speed boost timer
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_multiplier = 1.0
			print(">>> Speed boost expired")

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	print(">>> Player took " + str(amount) + " damage. Health: " + str(current_health))
	
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
