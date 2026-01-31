extends Area2D

@export var item_data: ItemData  # Assign in inspector
@export var quantity: int = 1

@onready var sprite = $Sprite2D

var player_nearby: bool = false
var player_ref = null

func _ready() -> void:
	# Set up the sprite
	if item_data and item_data.icon:
		sprite.texture = item_data.icon
	
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
		print(">>> Near item: " + item_data.item_name)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("pickup"):
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
