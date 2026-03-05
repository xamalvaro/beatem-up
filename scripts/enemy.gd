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
var attack_range: float = 20.0       # Distance at which lunge triggers
var attack_damage: int = 10          # Damage dealt to player per lunge
var attack_hit_frame: int = 3        # Which lunge frame deals damage (0-indexed)
var lunge_duration: float = 1.2      # How long the lunge animation plays before cooldown

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

	# Hit flash — briefly modulate white then back to normal
	if flash_timer > 0:
		flash_timer -= delta
		sprite.modulate = Color(10, 10, 10)  # Bright white flash
		if flash_timer <= 0:
			sprite.modulate = Color(1, 1, 1)  # Back to normal

	# Attack cooldown
	if attack_timer > 0:
		attack_timer -= delta

	# State logic
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed)
	elif player_chase and player:
		var distance = position.distance_to(player.position)

		# If in attack range and cooled down — trigger lunge
		if distance <= attack_range and attack_timer <= 0:
			start_lunge()
		else:
			# Chase the player
			var direction = (player.position - position).normalized()
			velocity.x = direction.x * speed
			sprite.play("walk")
			sprite.flip_h = direction.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		sprite.play("idle")

	# Keep AttackHitBox shape facing the same direction as the zombie
	var attack_shape = attack_hitbox.get_node_or_null("CollisionShape2D")
	if attack_shape:
		attack_shape.position.x = abs(attack_shape.position.x) * (-1 if sprite.flip_h else 1)

	move_and_slide()

func start_lunge() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	velocity.x = 0
	sprite.play("lunge")

	# Enable hitbox on the damage frame using animation signal
	sprite.frame_changed.connect(_on_lunge_frame_changed)

	# End attack after lunge duration
	await get_tree().create_timer(lunge_duration).timeout
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
	# Disconnect frame signal to avoid stacking connections
	if sprite.frame_changed.is_connected(_on_lunge_frame_changed):
		sprite.frame_changed.disconnect(_on_lunge_frame_changed)

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
