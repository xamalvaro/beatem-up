extends State

# Struggle meter — fills on mash, decays over time
var struggle_meter: float = 0.0
const FILL_PER_MASH: float = 0.25
const DECAY_PER_SECOND: float = 0.15
const DAMAGE_PER_SECOND: float = 5.0

# Reference to the zombie that grabbed us — set by main_dude.gd before enter()
var grabbing_zombie = null

var damage_accumulator: float = 0.0

func enter() -> void:
	struggle_meter = 0.0
	damage_accumulator = 0.0
	player.velocity = Vector2.ZERO
	player.get_node("AnimatedSprite2D").play("struggle")  # Placeholder

	# Show prompt above player's head
	var ui = player.get_node_or_null("StruggleUI")
	if ui:
		ui.show_ui()

	print(">>> Player grabbed! Mash attack_a to break free!")

func exit() -> void:
	grabbing_zombie = null
	struggle_meter = 0.0

	# Hide prompt
	var ui = player.get_node_or_null("StruggleUI")
	if ui:
		ui.hide_ui()

func physics_update(delta: float) -> void:
	# Lock movement while grabbed
	player.velocity.x = 0
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	else:
		player.velocity.y = 0

	# Passive damage while held
	damage_accumulator += DAMAGE_PER_SECOND * delta
	if damage_accumulator >= 1.0:
		var dmg = int(damage_accumulator)
		damage_accumulator -= dmg
		player.take_damage(dmg)

	# Meter decay
	struggle_meter -= DECAY_PER_SECOND * delta
	struggle_meter = clamp(struggle_meter, 0.0, 1.0)

	# Mash input
	if Input.is_action_just_pressed("attack_a"):
		struggle_meter += FILL_PER_MASH
		struggle_meter = clamp(struggle_meter, 0.0, 1.0)
		print(">>> Mash! Meter: " + str(snapped(struggle_meter, 0.01)))

	# Drive animation speed from meter value
	var ui = player.get_node_or_null("StruggleUI")
	if ui:
		ui.set_meter(struggle_meter)

	# Break free when meter is full
	if struggle_meter >= 1.0:
		_break_free()

	player.move_and_slide()

func _break_free() -> void:
	print(">>> Player broke free!")
	if grabbing_zombie and is_instance_valid(grabbing_zombie):
		grabbing_zombie.on_player_broke_free(player)
	player.broke_free.emit()
	transitioned.emit("idle")
