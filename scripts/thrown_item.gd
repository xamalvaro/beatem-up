extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var lifetime: float = 3.0
var fall_speed: float = 300.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer = $LifetimeTimer

func _ready() -> void:
	# Layers set in thrown_item.tscn: layer "thrown_item", mask "enemy"
	body_entered.connect(_on_body_entered)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func setup(item_icon: Texture2D, throw_velocity: Vector2, throw_damage: int) -> void:
	sprite.texture = item_icon
	sprite.scale = Vector2(0.5, 0.5)
	velocity = throw_velocity
	damage = throw_damage

func _physics_process(delta: float) -> void:
	if GameFeel.is_frozen():
		return
	position += velocity * delta
	velocity.y += fall_speed * delta
	rotation += 10 * delta

func _on_body_entered(body: Node2D) -> void:
	# Only hits the zombie's body now — it used to hit the zombie's large
	# detection area, which killed zombies from far away.
	if not body.is_in_group("enemy") or not body.has_method("take_damage"):
		return
	body.take_damage(damage, Vector2(signf(velocity.x) * 150.0, -80.0), 0.5, true)
	GameFeel.hitstop(6)
	GameFeel.shake(2.0)
	GameFeel.spark(global_position)
	queue_free()
