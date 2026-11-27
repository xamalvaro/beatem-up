extends CharacterBody2D
class_name Player

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# --- Responsiveness ---
const COYOTE_TIME: float = 0.1      # Can still jump this long after walking off a ledge
const JUMP_BUFFER: float = 0.12     # Jump pressed this long before landing still fires
const JUMP_CUT: float = 0.5         # Upward speed multiplier when jump is released early

# --- Stats ---
var max_health: int = 100
var current_health: int = 100
var speed_multiplier: float = 1.0
var speed_boost_timer: float = 0.0
var is_dead: bool = false

# Invincibility frames after taking damage / while dodging
var is_invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 0.5
var is_dodging: bool = false
var dodge_cooldown: float = 0.0

# Stagger: 2 hits within STAGGER_WINDOW leaves you open to a grab from a
# zombie that is close enough (see enemy.gd). It no longer teleports zombies in.
var stagger_hits: int = 0
var stagger_timer: float = 0.0
const HITS_TO_STAGGER: int = 2
const STAGGER_WINDOW: float = 2.5

var is_grabbed: bool = false
var grabbing_zombie: Node = null

var input_buffer := InputBuffer.new()
var coyote_timer: float = 0.0
var jump_requested: bool = false    # Set by states before entering "jump"; false = falling

# Set by take_damage() for the hurt state to read
var hurt_knockback: Vector2 = Vector2.ZERO

# Cached node references (avoid get_node() every frame)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $PunchHitBox
@onready var inventory: Inventory = $Inventory
@onready var state_machine: PlayerStateMachine = $State_machine
@onready var struggle_ui: Node2D = $StruggleUI

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	add_to_group("player")

# --- Shared helpers used by states ---

func get_move_input() -> float:
	return Input.get_axis("ui_left", "ui_right")

func apply_gravity(delta: float, multiplier: float = 1.0) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta * multiplier

func face(direction: float) -> void:
	if direction != 0:
		sprite.flip_h = direction < 0

func facing() -> float:
	return -1.0 if sprite.flip_h else 1.0

func can_jump() -> bool:
	return is_on_floor() or coyote_timer > 0.0

# Consumes a buffered jump press only if a jump is actually possible right now,
# so a press made just before landing is kept until we touch the ground.
func wants_jump() -> bool:
	return can_jump() and input_buffer.consume(&"ui_accept", JUMP_BUFFER)

func wants_dodge() -> bool:
	return dodge_cooldown <= 0.0 and is_on_floor() and input_buffer.consume(&"dodge")

func start_jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0

func get_damage_multiplier() -> float:
	if inventory and inventory.equipped_item:
		return inventory.equipped_item.damage_multiplier
	return 1.0

func _physics_process(delta: float) -> void:
	# Runs before the state machine (parent processes before children).
	# Buffer time doesn't advance during hitstop so presses aren't lost.
	input_buffer.update(0.0 if GameFeel.is_frozen() else delta)
	if GameFeel.is_frozen():
		return

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_multiplier = 1.0

	if dodge_cooldown > 0:
		dodge_cooldown -= delta

	if stagger_timer > 0:
		stagger_timer -= delta
		if stagger_timer <= 0:
			stagger_hits = 0

	if is_invincible and not is_dodging:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color(1, 1, 1)

# --- Damage ---

# from_position: where the hit came from (for knockback direction)
func take_damage(amount: int, from_position: Vector2 = Vector2.INF) -> void:
	if is_dead or is_invincible or is_grabbed:
		return

	_lose_health(amount)
	if is_dead:
		return

	stagger_hits += 1
	stagger_timer = STAGGER_WINDOW
	DebugLog.log(">>> Player took ", amount, " damage. Health: ", current_health, " stagger ", stagger_hits)

	is_invincible = true
	invincible_timer = INVINCIBLE_DURATION
	modulate = Color(1, 0.4, 0.4)

	var dir := -facing()
	if from_position != Vector2.INF:
		dir = signf(global_position.x - from_position.x)
		if dir == 0:
			dir = -facing()
	hurt_knockback = Vector2(dir * 90.0, -60.0)
	GameFeel.hitstop(4)
	GameFeel.shake(1.5)
	state_machine.on_state_transition("hurt")

# Damage while held. Bypasses the is_grabbed block so grabs actually hurt.
func take_grab_damage(amount: int) -> void:
	if is_dead:
		return
	_lose_health(amount)

func _lose_health(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func is_staggered() -> bool:
	return stagger_hits >= HITS_TO_STAGGER

func can_be_grabbed() -> bool:
	return not is_dead and not is_grabbed and not is_dodging

# --- Grab ---

func try_grab(zombie: Node) -> bool:
	if not can_be_grabbed():
		return false
	is_grabbed = true
	grabbing_zombie = zombie
	stagger_hits = 0
	is_invincible = false
	modulate = Color(1, 1, 1)
	state_machine.on_state_transition("grabbed")
	DebugLog.log(">>> Player grabbed by zombie!")
	return true

# Called when the grab ends for any reason (broke free, zombie hit/killed).
func release_grab() -> void:
	if not is_grabbed:
		return
	is_grabbed = false
	grabbing_zombie = null
	if not is_dead and state_machine.current_state and state_machine.current_state.name == "Grabbed":
		state_machine.on_state_transition("idle")

# --- Items ---

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	DebugLog.log(">>> Player healed ", amount, " HP. Health: ", current_health)

func boost_speed(duration: float, multiplier: float) -> void:
	speed_multiplier = multiplier
	speed_boost_timer = duration

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if is_grabbed and grabbing_zombie and is_instance_valid(grabbing_zombie):
		grabbing_zombie.release_grab()
	is_grabbed = false
	died.emit()
	state_machine.on_state_transition("dead")
	DebugLog.log(">>> Player died!")
