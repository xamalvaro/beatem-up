extends State
class_name AttackState

# Attack properties — child states override these in _ready()
@export var attack_duration: float = 0.4
@export var can_move_during_attack: bool = false
@export var attack_animation: String = "stomp"  # Matches actual player animation name

# Base damage — axe doubles it
@export var attack_damage: int = 1
const AXE_ITEM_NAME: String = "Fireman Axe"

# Combo system
@export var combo_window: float = 0.3
@export var next_attack_a: String = ""
@export var next_attack_b: String = ""
@export var directional_attacks: Dictionary = {}

var attack_timer: float = 0.0
var combo_timer: float = 0.0
var attack_finished: bool = false
var can_combo: bool = false

func enter() -> void:
	attack_timer = 0.0
	combo_timer = 0.0
	attack_finished = false
	can_combo = false
	player.velocity.x = 0
	player.get_node("AnimatedSprite2D").play(attack_animation)
	_enable_hitbox()

func exit() -> void:
	_disable_hitbox()

func _enable_hitbox() -> void:
	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox:
		var damage = _get_attack_damage()
		hitbox.set_meta("damage", damage)
		hitbox.get_node("CollisionShape2D").disabled = false
		hitbox.monitoring = true
		_update_hitbox_direction(hitbox)
		print(">>> Attack started — damage: " + str(damage))

func _disable_hitbox() -> void:
	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _update_hitbox_direction(hitbox: Node) -> void:
	# Place hitbox in front of the player based on facing direction
	var sprite = player.get_node("AnimatedSprite2D")
	hitbox.position.x = abs(hitbox.position.x) * (-1 if sprite.flip_h else 1)

func _get_attack_damage() -> int:
	var inventory = player.get_node_or_null("Inventory")
	if inventory and inventory.equipped_item:
		if inventory.equipped_item.item_name == AXE_ITEM_NAME:
			return attack_damage * 2
	return attack_damage

func physics_update(delta: float) -> void:
	attack_timer += delta

	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta

	if can_move_during_attack:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.5
			player.get_node("AnimatedSprite2D").flip_h = direction < 0
	else:
		player.velocity.x = 0

	# Keep hitbox flipped correctly every frame during the attack
	var hitbox = player.get_node_or_null("PunchHitBox")
	if hitbox and hitbox.monitoring:
		_update_hitbox_direction(hitbox)

	# Attack motion finished — disable hitbox, open combo window
	if attack_timer >= attack_duration:
		if not attack_finished:
			attack_finished = true
			can_combo = true
			combo_timer = 0.0
			_disable_hitbox()

	# Combo window
	if attack_finished:
		combo_timer += delta

		if combo_timer < combo_window:
			var direction = Input.get_axis("ui_left", "ui_right")
			var is_down = Input.is_action_pressed("ui_down")

			if is_down and Input.is_action_just_pressed("attack_a"):
				if directional_attacks.has("down_a"):
					transitioned.emit(directional_attacks["down_a"])
					return
			elif is_down and Input.is_action_just_pressed("attack_b"):
				if directional_attacks.has("down_b"):
					transitioned.emit(directional_attacks["down_b"])
					return

			if Input.is_action_just_pressed("attack_a") and next_attack_a != "":
				transitioned.emit(next_attack_a)
				return
			elif Input.is_action_just_pressed("attack_b") and next_attack_b != "":
				transitioned.emit(next_attack_b)
				return
		else:
			transitioned.emit("idle")

	player.move_and_slide()
