extends Area2D

@export var item_data: ItemData  # Assign in inspector
@export var quantity: int = 1

@onready var sprite = $AnimatedSprite2D

var player_nearby: bool = false
var player_ref = null

func _ready() -> void:
	# Build the animated sprite from the item's sprite sheet
	if item_data and item_data.sprite_sheet:
		var frames = SpriteFrames.new()
		frames.add_animation("idle")
		frames.set_animation_loop("idle", true)
		frames.set_animation_speed("idle", 5.0)

		# 1px margin inset on each frame prevents pixel bleed between stacked frames
		var frame_0 = AtlasTexture.new()
		frame_0.atlas = item_data.sprite_sheet
		frame_0.region = Rect2(0, 0, 32, 32)
		frames.add_frame("idle", frame_0)

		var frame_1 = AtlasTexture.new()
		frame_1.atlas = item_data.sprite_sheet
		frame_1.region = Rect2(0, 32, 32, 32)
		frames.add_frame("idle", frame_1)

		sprite.sprite_frames = frames
		# Scale down to match player size in world space
		# Camera is 4x zoom, player is 32px world size — items at 0.5 scale = 8px world
		sprite.scale = Vector2(.65, .65)
		sprite.play("idle")
	else:
		DebugLog.log(">>> WARNING: " + (item_data.item_name if item_data else "Unknown") + " has no sprite_sheet assigned!")

	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		DebugLog.log(">>> Near item: " + item_data.item_name)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("pickup"):
		pickup()

func pickup() -> void:
	if player_ref and item_data:
		var inventory = player_ref.get_node_or_null("Inventory")
		if inventory and inventory.add_item(item_data, quantity):
			DebugLog.log(">>> Picked up: " + item_data.item_name + " x" + str(quantity))
			queue_free()  # Remove from world
		else:
			DebugLog.log(">>> Inventory full!")
