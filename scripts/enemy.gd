extends CharacterBody2D

# Zombie AI as a small state machine. Each state is one function below.
# Collision layers are set in enemy.tscn: body on "enemy", detection area and
# attack hitbox look for "player".

enum S { IDLE, CHASE, LUNGE, GRAB, HITSTUN, KNOCKDOWN, STUNNED, DEAD }

# Movement
@export var speed: float = 35.0
@export var ai_enabled: bool = true   # Off = training dummy (still reacts to hits)

# Health — 4 hits bare-handed, 2 with the axe
@export var max_hit_points: int = 4
var hit_points: int = 4

# Lunge attack
@export var attack_range: float = 20.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 2.0
@export var attack_hit_frame: int = 3
@export var lunge_duration: float = 1.2

# Grab — only a staggered player (hit twice recently) can be grabbed, and only
# by a zombie right next to them. It used to teleport the nearest zombie in
# from anywhere on the map.
@export var grab_range: float = 24.0
@export var grab_cooldown: float = 4.0

# Reactions
@export var stun_duration: float = 1.5
@export var knockdown_duration: float = 0.9
const FRICTION: float = 300.0
const FLASH_DURATION: float = 0.1
const DEATH_FALLBACK: float = 2.0

var state: S = S.IDLE
var state_timer: float = 0.0
var hitstun_time: float = 0.0
var attack_timer: float = 0.0
var grab_timer: float = 0.0
var flash_timer: float = 0.0
var lunge_hit_done: bool = false

var player: Player = null
var _was_frozen: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitBox
@onready var attack_shape: CollisionShape2D = $AttackHitBox/CollisionShape2D
@onready var _attack_base_x: float = abs(attack_shape.position.x)

# Back-compat for code that checks these flags
var is_dead: bool:
	get: return state == S.DEAD
var is_grabbing: bool:
	get: return state == S.GRAB

func _ready() -> void:
	add_to_group("enemy")
	hit_points = max_hit_points
	_set_attack_hitbox(false)
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)

func _set_state(new_state: S) -> void:
	if state == S.LUNGE:
		_set_attack_hitbox(false)
	state = new_state
	state_timer = 0.0
	if new_state == S.LUNGE:
		lunge_hit_done = false
		attack_timer = attack_cooldown
		velocity.x = 0
		sprite.play("lunge")

func _set_attack_hitbox(on: bool) -> void:
	attack_hitbox.set_deferred("monitoring", on)
	attack_shape.set_deferred("disabled", not on)

func _has_target() -> bool:
	return player != null and is_instance_valid(player) and not player.is_dead

func _physics_process(delta: float) -> void:
	# Hitstop: freeze pose
	if GameFeel.is_frozen():
		if not _was_frozen:
			sprite.pause()
			_was_frozen = true
		return
	if _was_frozen:
		_was_frozen = false
		sprite.play()

	state_timer += delta
	attack_timer = max(0.0, attack_timer - delta)
	grab_timer = max(0.0, grab_timer - delta)
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			sprite.modulate = Color(1, 1, 1)

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	match state:
		S.IDLE: _idle()
		S.CHASE: _chase()
		S.LUNGE: _lunge()
		S.GRAB: _grab()
		S.HITSTUN: _hitstun(delta)
		S.KNOCKDOWN: _knockdown(delta)
		S.STUNNED: _stunned(delta)
		S.DEAD: _dead(delta)

	attack_shape.position.x = _attack_base_x * (-1.0 if sprite.flip_h else 1.0)
	move_and_slide()

# --- States ---

func _idle() -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	sprite.play("idle")
	if ai_enabled and _has_target():
		_set_state(S.CHASE)

func _chase() -> void:
	if not ai_enabled or not _has_target():
		_set_state(S.IDLE)
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if player.is_staggered() and dist <= grab_range and grab_timer <= 0 and player.can_be_grabbed():
		if player.try_grab(self):
			_set_state(S.GRAB)
			return
	if dist <= attack_range and attack_timer <= 0:
		_set_state(S.LUNGE)
		return

	sprite.flip_h = to_player.x < 0
	if abs(to_player.x) > 4.0:
		velocity.x = signf(to_player.x) * speed
		sprite.play("walk")
	else:
		velocity.x = 0
		sprite.play("idle")

func _lunge() -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	_set_attack_hitbox(sprite.frame == attack_hit_frame and not lunge_hit_done)
	if state_timer >= lunge_duration:
		_set_state(S.CHASE)

func _grab() -> void:
	if not _has_target() or not player.is_grabbed:
		_set_state(S.CHASE)
		return
	global_position = player.global_position + Vector2(12 if sprite.flip_h else -12, 0)
	velocity = Vector2.ZERO
	sprite.play("grab")

func _hitstun(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	if state_timer >= hitstun_time and is_on_floor():
		_set_state(S.CHASE)

func _knockdown(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION * 2.0 * delta)
	if state_timer >= knockdown_duration and is_on_floor():
		_set_state(S.CHASE)

func _stunned(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	if state_timer >= stun_duration:
		_set_state(S.CHASE)

func _dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	if state_timer >= DEATH_FALLBACK:
		queue_free()

# --- Events ---

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, hitstun: float = 0.3, knockdown: bool = false) -> void:
	if state == S.DEAD:
		return
	hit_points = max(0, hit_points - amount)
	DebugLog.log(">>> Zombie hit! HP: ", hit_points, "/", max_hit_points)

	if state == S.GRAB and _has_target():
		player.release_grab()

	flash_timer = FLASH_DURATION
	sprite.modulate = Color(10, 10, 10)
	velocity = knockback
	if knockback.x != 0:
		sprite.flip_h = knockback.x > 0  # Face the attacker

	if hit_points <= 0:
		die()
		return

	hitstun_time = hitstun
	_set_state(S.KNOCKDOWN if knockdown else S.HITSTUN)
	sprite.play("pushed_back")
	# Small grace period so it can't counter-lunge the instant hitstun ends
	attack_timer = max(attack_timer, 0.4)

# Called by the player when they die while held
func release_grab() -> void:
	if state == S.GRAB:
		_set_state(S.CHASE)

func on_player_broke_free(broke_free_player: Node2D) -> void:
	grab_timer = grab_cooldown
	var dir := signf(global_position.x - broke_free_player.global_position.x)
	velocity = Vector2((dir if dir != 0 else 1.0) * 180.0, -40.0)
	_set_state(S.STUNNED)
	sprite.play("pushed_back")

func die() -> void:
	_set_state(S.DEAD)
	# Stop colliding with fighters but keep standing on the floor
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)
	$detection_area/CollisionShape2D.set_deferred("disabled", true)
	_set_attack_hitbox(false)
	sprite.modulate = Color(1, 1, 1)
	sprite.play("death")
	DebugLog.log(">>> Zombie died!")

func _on_animation_finished() -> void:
	if state == S.DEAD and sprite.animation == &"death":
		queue_free()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if state != S.LUNGE or lunge_hit_done:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		lunge_hit_done = true
		_set_attack_hitbox(false)
		body.take_damage(attack_damage, global_position)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
