extends CharacterBody2D

# Movement
var speed: float = 35.0

# Health — 4 hits to kill bare fist, 2 hits with axe (axe deals 2 damage)
var max_hit_points: int = 4
var hit_points: int = 4
var is_dead: bool = false

# Chase
var player_chase: bool = false
var player = null

# Attack
var is_attacking: bool = false
var attack_cooldown: float = 2.0
var attack_timer: float = 0.0
var attack_range: float = 20.0
var attack_damage: int = 10
var attack_hit_frame: int = 3
var lunge_duration: float = 1.2

# Grab
var grab_range: float = 10.0       # Closer than lunge range — zombie is right on top
var is_grabbing: bool = false
var grab_cooldown: float = 4.0     # Can't grab again for 4 seconds after a break-free
var grab_timer: float = 0.0

# Stun (after player breaks free)
var is_stunned: bool = false
var stun_duration: float = 1.5
var stun_timer: float = 0.0

# Knockback (applied when player breaks free)
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 300.0

# Hit flash
var flash_timer: float = 0.0
var flash_duration: float = 0.1

@onready var sprite = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitBox

func _ready() -> void:
	add_to_group("enemy")
	# Detection area must look for player on layer 1
	$detection_area.collision_mask = 1
	# AttackHitBox starts disabled — only enabled on the damage frame
	attack_hitbox.monitoring = false
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Hit flash
	if flash_timer > 0:
		flash_timer -= delta
		sprite.modulate = Color(10, 10, 10)
		if flash_timer <= 0:
			sprite.modulate = Color(1, 1, 1)

	# Timers
	if attack_timer > 0:
		attack_timer -= delta
	if grab_timer > 0:
		grab_timer -= delta

	# Stun — just stand still after knockback
	if is_stunned:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, knockback_friction * delta)
		if stun_timer <= 0:
			is_stunned = false
			print(">>> Zombie recovered from stun")
		move_and_slide()
		return

	# Knockback decay
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return

	# Currently grabbing — hold position on player
	if is_grabbing:
		if player and is_instance_valid(player):
			var grab_offset = Vector2(-12 if not sprite.flip_h else 12, 0)
			global_position = player.global_position + grab_offset
			sprite.play("lunge")  # Placeholder — swap for grab animation later
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Normal AI
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed)
	elif player_chase and player:
		var distance = position.distance_to(player.position)

		# Proximity grab — zombie is right on top of player
		if distance <= grab_range and grab_timer <= 0 and not player.is_grabbed:
			try_grab()
		# Normal lunge attack
		elif distance <= attack_range and attack_timer <= 0 and not is_grabbing:
			start_lunge()
		else:
			var direction = (player.position - position).normalized()
			velocity.x = direction.x * speed
			sprite.play("walk")
			sprite.flip_h = direction.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		sprite.play("idle")

	# Keep AttackHitBox facing correct direction
	var attack_shape = attack_hitbox.get_node_or_null("CollisionShape2D")
	if attack_shape:
		attack_shape.position.x = abs(attack_shape.position.x) * (-1 if sprite.flip_h else 1)

	move_and_slide()

func start_lunge() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	velocity.x = 0
	sprite.play("lunge")
	sprite.frame_changed.connect(_on_lunge_frame_changed)

	await get_tree().create_timer(lunge_duration).timeout
	# Don't end lunge if we started grabbing mid-animation
	if not is_grabbing:
		end_lunge()

func _on_lunge_frame_changed() -> void:
	if sprite.animation != "lunge":
		return
	if sprite.frame == attack_hit_frame:
		attack_hitbox.set_deferred("monitoring", true)
		attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
	else:
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func end_lunge() -> void:
	is_attacking = false
	attack_hitbox.monitoring = false
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	if sprite.frame_changed.is_connected(_on_lunge_frame_changed):
		sprite.frame_changed.disconnect(_on_lunge_frame_changed)

func try_grab() -> void:
	if not player or not player.has_method("try_grab"):
		return
	var accepted = player.try_grab(self)
	if accepted:
		is_grabbing = true
		is_attacking = false
		# Clean up any in-progress lunge
		if sprite.frame_changed.is_connected(_on_lunge_frame_changed):
			sprite.frame_changed.disconnect(_on_lunge_frame_changed)
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
		print(">>> Zombie grabbed player!")

func on_player_broke_free(broke_free_player) -> void:
	is_grabbing = false
	grab_timer = grab_cooldown

	# Knock back away from the player
	var dir = (global_position - broke_free_player.global_position).normalized()
	knockback_velocity = dir * 180.0

	# Enter stun
	is_stunned = true
	stun_timer = stun_duration
	sprite.play("idle")  # Placeholder — swap for stun animation later
	print(">>> Zombie knocked back after break-free!")

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		print(">>> Zombie lunged! Dealt " + str(attack_damage) + " to player")
	# Must use set_deferred when changing monitoring inside a signal callback
	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	hit_points -= amount
	hit_points = max(0, hit_points)
	print(">>> Zombie hit! HP: " + str(hit_points) + "/" + str(max_hit_points))

	# Cancel grab if hit while grabbing
	if is_grabbing:
		is_grabbing = false
		grab_timer = grab_cooldown
		if player and player.is_grabbed:
			player.on_broke_free()
			player.broke_free.emit()

	# Trigger hit flash
	flash_timer = flash_duration
	sprite.modulate = Color(10, 10, 10)

	if hit_points <= 0:
		die()

func die() -> void:
	is_dead = true
	player_chase = false
	velocity = Vector2.ZERO

	# All collision changes must use set_deferred when called from a signal
	$CollisionShape2D.set_deferred("disabled", true)
	$detection_area/CollisionShape2D.set_deferred("disabled", true)
	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	sprite.modulate = Color(1, 1, 1)
	sprite.play("death")
	print(">>> Zombie died!")

	# Death animation is looped in the scene so animation_finished never fires.
	# Wait a fixed duration then disappear — replace with a poof animation later.
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		player_chase = false
