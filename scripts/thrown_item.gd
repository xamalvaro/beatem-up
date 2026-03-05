extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var lifetime: float = 3.0
var fall_speed: float = 300.0

@onready var sprite = $Sprite2D
@onready var timer = $LifetimeTimer

func _ready() -> void:
	# Layer 16 — only detects enemy bodies (layer 2), NOT player (layer 1)
	collision_layer = 16
	collision_mask = 2

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()

	print(">>> Thrown item spawned with damage: " + str(damage))

func setup(item_icon: Texture2D, throw_velocity: Vector2, throw_damage: int) -> void:
	if sprite:
		sprite.texture = item_icon
		sprite.scale = Vector2(0.5, 0.5)
	else:
		print(">>> ERROR: No sprite node found!")

	velocity = throw_velocity
	damage = throw_damage
	print(">>> Thrown item setup complete")

func _physics_process(delta: float) -> void:
	position += velocity * delta
	velocity.y += fall_speed * delta
	rotation += 10 * delta

func _on_body_entered(body: Node2D) -> void:
	# Only damage enemies — never the player
	if not body.is_in_group("enemy"):
		return
	print(">>> Thrown item hit enemy: " + body.name)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print(">>> Dealt " + str(damage) + " damage to " + body.name)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Only damage enemies via their areas — never the player
	var parent = area.get_parent()
	if parent == null or not parent.is_in_group("enemy"):
		return
	print(">>> Thrown item hit enemy area: " + area.name)
	if parent.has_method("take_damage"):
		parent.take_damage(damage)
		print(">>> Dealt " + str(damage) + " damage to " + parent.name)
	queue_free()

func _on_timeout() -> void:
	print(">>> Thrown item despawned (timeout)")
	queue_free()
