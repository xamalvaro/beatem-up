extends Area2D

# Player attack hitbox. AttackState calls activate()/deactivate().
# While active it hits every enemy it overlaps, each one ONCE per swing
# (so crowds can be hit together). Layers are set in main_dude.tscn:
# layer "player_hitbox", mask "enemy".

signal hit_landed(body: Node2D)

@onready var shape: CollisionShape2D = $CollisionShape2D

var _attack: AttackData = null
var _damage: int = 0
var _facing: float = 1.0
var _hit_bodies: Dictionary = {}
var _base_x: float = 0.0

func _ready() -> void:
	_base_x = abs(shape.position.x)
	deactivate()

func activate(attack: AttackData, damage: int, facing: float) -> void:
	_attack = attack
	_damage = damage
	_hit_bodies.clear()
	set_facing(facing)
	shape.position.y = attack.hitbox_offset_y
	shape.disabled = false
	monitoring = true

func deactivate() -> void:
	_attack = null
	set_deferred("monitoring", false)
	shape.set_deferred("disabled", true)

func is_active() -> bool:
	return _attack != null

func set_facing(facing: float) -> void:
	_facing = -1.0 if facing < 0 else 1.0
	shape.position.x = _base_x * _facing

func _physics_process(_delta: float) -> void:
	if _attack == null or not monitoring:
		return
	for body in get_overlapping_bodies():
		if _hit_bodies.has(body) or not body.is_in_group("enemy") or not body.has_method("take_damage"):
			continue
		_hit_bodies[body] = true
		var kb := Vector2(_attack.knockback.x * _facing, _attack.knockback.y)
		body.take_damage(_damage, kb, _attack.hitstun / AttackData.FPS, _attack.knockdown)
		GameFeel.hitstop(_attack.hitstop)
		if _attack.screen_shake > 0.0:
			GameFeel.shake(_attack.screen_shake)
		GameFeel.spark(shape.global_position)
		DebugLog.log(">>> Hit ", body.name, " for ", _damage)
		hit_landed.emit(body)
