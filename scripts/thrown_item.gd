extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var lifetime: float = 3.0
#var gravity: float = 980.0

@onready var sprite = $Sprite2D
@onready var timer = $LifetimeTimer

func _ready() -> void:
	# Set up collision
	collision_layer = 16  # Layer 5 (projectiles)
	collision_mask = 6    # Layers 2-3 (enemies + obstacles)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Set up lifetime timer
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()
	
	print(">>> Thrown item spawned with damage: " + str(damage))

func setup(item_icon: Texture2D, throw_velocity: Vector2, throw_damage: int) -> void:
	if sprite:
		sprite.texture = item_icon
		# Scale down the icon a bit
		sprite.scale = Vector2(0.5, 0.5)
	else:
		print(">>> ERROR: No sprite node found!")
	
	velocity = throw_velocity
	damage = throw_damage
	
	print(">>> Thrown item setup complete")

func _physics_process(delta: float) -> void:
	# Move the projectile
	position += velocity * delta
	
	# Apply gravity
	velocity.y += gravity * delta
	
	# Rotate based on velocity (spinning effect)
	rotation += 10 * delta

func _on_body_entered(body: Node2D) -> void:
	print(">>> Thrown item hit body: " + body.name)
	
	# Deal damage if it's an enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print(">>> Dealt " + str(damage) + " damage to " + body.name)
	
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	print(">>> Thrown item hit area: " + area.name)
	
	# Hit another area (like enemy hitbox)
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(damage)
		print(">>> Dealt " + str(damage) + " damage to " + parent.name)
	
	queue_free()

func _on_timeout() -> void:
	print(">>> Thrown item despawned (timeout)")
	queue_free()
