extends Node
class_name PlayerStateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

@onready var player = get_parent() as CharacterBody2D

var _was_frozen: bool = false

func _ready() -> void:
	await owner.ready

	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = player
			child.transitioned.connect(on_state_transition)

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _process(delta: float) -> void:
	if current_state and not GameFeel.is_frozen():
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if not current_state:
		return
	# Hitstop: hold the pose (pause animation) and skip the state update
	if GameFeel.is_frozen():
		if not _was_frozen:
			player.sprite.pause()
			_was_frozen = true
		return
	if _was_frozen:
		_was_frozen = false
		player.sprite.play()
	current_state.physics_update(delta)

func on_state_transition(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		push_warning("State not found: " + new_state_name)
		return
	if new_state == current_state:
		return
	DebugLog.log("Transitioning: " + str(current_state.name) + " -> " + new_state.name)
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
