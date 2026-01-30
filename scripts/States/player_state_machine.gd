extends Node
class_name PlayerStateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

@onready var player = get_parent() as CharacterBody2D

func _ready() -> void:
	await owner.ready
	
	# Collect all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = player
			child.transitioned.connect(on_state_transition)
			print("Registered state: " + child.name.to_lower())  # Debug print
	
	# Start with initial state
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		print("Starting state: " + initial_state.name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_state_transition(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	
	if !new_state:
		print("ERROR: State not found: " + new_state_name)
		print("Available states: " + str(states.keys()))
		return
	
	if new_state == current_state:
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Enter new state
	print("Transitioning: " + current_state.name + " -> " + new_state.name)
	current_state = new_state
	current_state.enter()
