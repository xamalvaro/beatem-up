extends Node
class_name State

# Signal to notify state machine of state transitions
signal transitioned(new_state_name: String)

# Reference to the player (will be set by state machine)
var player: Player

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

# Shared "neutral" transitions for standing states (idle, run).
# Returns true if a transition was emitted, so the caller should return.
func try_neutral_actions() -> bool:
	var buf: InputBuffer = player.input_buffer
	if player.wants_jump():
		player.jump_requested = true
		transitioned.emit("jump")
		return true
	if not player.is_on_floor():
		# Walked off a ledge — the jump state handles falling + coyote jumps
		player.jump_requested = false
		transitioned.emit("jump")
		return true
	if player.wants_dodge():
		transitioned.emit("dodge")
		return true
	if buf.consume(&"attack_a"):
		transitioned.emit("sweep" if Input.is_action_pressed("ui_down") else "stomp")
		return true
	if buf.consume(&"attack_b"):
		transitioned.emit("heavy")
		return true
	if buf.consume(&"crawl"):
		transitioned.emit("crawlenter")
		return true
	if Input.is_action_pressed("ui_down"):
		transitioned.emit("crouch")
		return true
	return false
