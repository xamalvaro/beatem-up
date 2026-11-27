extends AttackState

# Diving kick: hitbox stays active until landing, then a short recovery.

const LAND_RECOVERY: float = 0.2
const DIVE_GRAVITY: float = 1.5
const AIR_CONTROL: float = 0.4

var has_landed: bool = false
var land_timer: float = 0.0

func _ready() -> void:
	attack_damage = 2
	attack_animation = "drop_kick"
	fit_animation = false
	can_move_during_attack = true

func enter() -> void:
	has_landed = false
	land_timer = 0.0
	super.enter()
	# Hitbox forward and slightly down for a diving kick
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 2

func exit() -> void:
	super.exit()
	var shape = player.get_node_or_null("PunchHitBox/CollisionShape2D")
	if shape:
		shape.position.y = 0

func physics_update(delta: float) -> void:
	if not has_landed:
		player.apply_gravity(delta, DIVE_GRAVITY)
		var direction = player.get_move_input()
		if direction != 0:
			player.velocity.x = direction * player.SPEED * AIR_CONTROL
			player.face(direction)
		var hitbox = player.get_node_or_null("PunchHitBox")
		if hitbox and hitbox.monitoring:
			_update_hitbox_direction(hitbox)
		player.move_and_slide()
		if player.is_on_floor():
			has_landed = true
			player.velocity.x = 0
			_disable_hitbox()  # No damage once on the ground
		return

	land_timer += delta
	if land_timer >= LAND_RECOVERY:
		transitioned.emit("run" if player.get_move_input() != 0 else "idle")
		return
	player.velocity.x = 0
	player.move_and_slide()
