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
var invincible_duration: float = 0.5

# Stagger system — 2 hits triggers a grab, resets only on grab or break-free
var stagger_hits: int = 0
const HITS_TO_GRAB: int = 2

# Whether we are currently being grabbed (blocks new grabs)
var is_grabbed: bool = false

# --- Responsiveness ---
const COYOTE_TIME: float = 0.1      # Can still jump this long after walking off a ledge
const JUMP_BUFFER: float = 0.12     # Jump pressed this long before landing still fires
const JUMP_CUT: float = 0.5         # Upward speed multiplier when jump is released early

var input_buffer := InputBuffer.new()
var coyote_timer: float = 0.0
var jump_requested: bool = false    # Set by states before entering "jump"; false = falling

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal health_changed(new_health: int, max_health: int)
signal died
signal broke_free

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	broke_free.connect(on_broke_free)

# --- Shared helpers used by states ---

func get_move_input() -> float:
	return Input.get_axis("ui_left", "ui_right")

func apply_gravity(delta: float, multiplier: float = 1.0) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta * multiplier

func face(direction: float) -> void:
	if direction != 0:
		sprite.flip_h = direction < 0

func can_jump() -> bool:
	return is_on_floor() or coyote_timer > 0.0

# Consumes a buffered jump press only if a jump is actually possible right now,
# so a press made just before landing is kept until we touch the ground.
func wants_jump() -> bool:
	return can_jump() and input_buffer.consume(&"ui_accept", JUMP_BUFFER)

func start_jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0

func _physics_process(delta: float) -> void:
	# Runs before the state machine (parent processes before children)
	input_buffer.update(delta)
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Speed boost timer
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_multiplier = 1.0

	# Invincibility timer
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color(1, 1, 1)

func take_damage(amount: int) -> void:
	if is_invincible or is_grabbed:
		return

	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)
	print(">>> Player took " + str(amount) + " damage. Health: " + str(current_health))

	# Stagger tracking — check BEFORE setting iframes so the grab can fire
	stagger_hits += 1
	print(">>> Stagger hits: " + str(stagger_hits) + "/" + str(HITS_TO_GRAB))

	# Stagger threshold reached — find the closest enemy and trigger grab immediately
	if stagger_hits >= HITS_TO_GRAB:
		stagger_hits = 0
		_try_stagger_grab()
		return

	is_invincible = true
	invincible_timer = invincible_duration
	modulate = Color(1, 0.4, 0.4)

	if current_health <= 0:
		die()

func _try_stagger_grab() -> void:
	# Find the nearest enemy and have them grab us
	var nearest: Node = null
	var nearest_dist: float = 999999.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_dead or enemy.is_grabbing:
			continue
		var d = global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	if nearest:
		nearest.try_grab()

func try_grab(zombie) -> bool:
	# is_grabbed blocks all grabs
	# is_invincible does NOT block stagger grabs — the player was just hit so
	# iframes are almost certainly active. We clear them when grab starts.
	if is_grabbed:
		return false
	get_grabbed(zombie)
	return true

func get_grabbed(zombie) -> void:
	is_grabbed = true
	stagger_hits = 0
	is_invincible = false
	modulate = Color(1, 1, 1)

	var state_machine = get_node_or_null("State_machine")
	if state_machine:
		var grabbed_st = state_machine.states.get("grabbed")
		if grabbed_st:
			grabbed_st.grabbing_zombie = zombie
		state_machine.on_state_transition("grabbed")

	print(">>> Player grabbed by zombie!")

func on_broke_free() -> void:
	is_grabbed = false

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
