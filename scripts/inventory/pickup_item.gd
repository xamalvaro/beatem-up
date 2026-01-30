extends Area2D

@export var item_data: ItemData  # Assign in inspector
@export var quantity: int = 1

@onready var sprite = $Sprite2D
@onready var label = $Label  # Optional

var player_nearby: bool = false
var player_ref = null

func _ready() -> void:
	# Set up the sprite
	if item_data and item_data.icon:
		sprite.texture = item_data.icon
	
	# Optional label
	if label and item_data:
		label.text = item_data.item_name
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collision layers
	collision_layer = 8  # Layer 4 (2^3 = 8)
	collision_mask = 1   # Detect player on layer 1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		show_pickup_prompt()
		print(">>> Near item: " + item_data.item_name)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		hide_pickup_prompt()
		print(">>> Left item area")

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("pickup"):  # We'll add this input
		pickup()

func pickup() -> void:
	if player_ref and item_data:
		# Try to add to player's inventory
		var inventory = player_ref.get_node_or_null("Inventory")
		if inventory and inventory.add_item(item_data, quantity):
			print(">>> Picked up: " + item_data.item_name + " x" + str(quantity))
			queue_free()  # Remove from world
		else:
			print(">>> Inventory full!")

func show_pickup_prompt() -> void:
	# You can create a UI element to show "Press E to pick up"
	if label:
		label.show()

func hide_pickup_prompt() -> void:
	if label:
		label.hide()
