extends State
class_name AttackState

# Attack properties
@export var attack_damage: int = 10
@export var attack_duration: float = 0.4
@export var can_move_during_attack: bool = false
@export var attack_animation: String = "stand_attack"

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
	
	# FORCE stop movement when entering attack
	player.velocity.x = 0
	
	player.get_node("AnimatedSprite2D").play(attack_animation)

func physics_update(delta: float) -> void:
	attack_timer += delta
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.get_gravity().y * delta
	
	# ONLY allow movement if explicitly allowed
	if can_move_during_attack:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			player.velocity.x = direction * player.SPEED * 0.5
			player.get_node("AnimatedSprite2D").flip_h = direction < 0
	else:
		# FORCE velocity to 0 if movement not allowed
		player.velocity.x = 0
	
	# Check if attack animation is finished
	if attack_timer >= attack_duration:
		if not attack_finished:
			attack_finished = true
			can_combo = true
			combo_timer = 0.0
	
	# Combo window logic
	if attack_finished:
		combo_timer += delta
		
		# Check for combo inputs
		if combo_timer < combo_window:
			# Check directional combos first
			var direction = Input.get_axis("ui_left", "ui_right")
			var is_down = Input.is_action_pressed("ui_down")
			
			if is_down and Input.is_action_just_pressed("attack_a"):
				if directional_attacks.has("down_a"):
					print(">>> Directional combo: down_a -> " + directional_attacks["down_a"])
					transitioned.emit(directional_attacks["down_a"])
					return
			elif is_down and Input.is_action_just_pressed("attack_b"):
				if directional_attacks.has("down_b"):
					print(">>> Directional combo: down_b -> " + directional_attacks["down_b"])
					transitioned.emit(directional_attacks["down_b"])
					return
			
			# Regular combo chain
			if Input.is_action_just_pressed("attack_a") and next_attack_a != "":
				print(">>> Combo A pressed -> " + next_attack_a)
				transitioned.emit(next_attack_a)
				return
			elif Input.is_action_just_pressed("attack_b") and next_attack_b != "":
				print(">>> Combo B pressed -> " + next_attack_b)
				transitioned.emit(next_attack_b)
				return
		else:
			# Combo window expired
			print(">>> Combo window expired, returning to idle")
			transitioned.emit("idle")
	
	player.move_and_slide()
