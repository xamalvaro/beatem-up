extends Node
class_name State

# Signal to notify state machine of state transitions
signal transitioned(new_state_name: String)

# Reference to the player (will be set by state machine)
var player: CharacterBody2D

# Called when entering this state
func enter() -> void:
	pass

# Called when exiting this state
func exit() -> void:
	pass

# Called every frame
func update(delta: float) -> void:
	pass

# Called every physics frame
func physics_update(delta: float) -> void:
	pass
