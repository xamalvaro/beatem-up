extends CanvasLayer

@onready var background_panel = $BackgroundPanel
@onready var slots_grid = $BackgroundPanel/MarginContainer/VBoxContainer/SlotsGrid
@onready var use_button = $BackgroundPanel/MarginContainer/VBoxContainer/HBoxContainer/UseButton
@onready var equip_button = $BackgroundPanel/MarginContainer/VBoxContainer/HBoxContainer/EquipButton
@onready var drop_button = $BackgroundPanel/MarginContainer/VBoxContainer/HBoxContainer/DropButton
@onready var throw_button = $BackgroundPanel/MarginContainer/VBoxContainer/HBoxContainer/ThrowButton


var inventory: Inventory
var slot_scene = preload("res://scenes/ui/inventory_slot.tscn")
var slots: Array = []
var selected_slot: int = -1
var is_open: bool = false

func _ready() -> void:
	add_to_group("inventory_ui")
	
	# IMPORTANT: Hide the UI initially
	visible = false
	is_open = false
	
	# Disable focus on all buttons so mouse works properly
	use_button.focus_mode = Control.FOCUS_NONE
	equip_button.focus_mode = Control.FOCUS_NONE
	drop_button.focus_mode = Control.FOCUS_NONE
	throw_button.focus_mode = Control.FOCUS_NONE
	
	# Connect buttons
	use_button.pressed.connect(_on_use_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	throw_button.pressed.connect(_on_throw_pressed)
	
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find player's inventory
	var player = get_tree().get_first_node_in_group("player")
	if player:
		inventory = player.get_node_or_null("Inventory")
		if inventory:
			inventory.inventory_changed.connect(refresh_inventory)
			setup_slots()
			print(">>> Inventory UI connected to player inventory")
		else:
			print(">>> ERROR: Could not find Inventory node on player")
	else:
		print(">>> ERROR: Could not find player in scene")
	
	update_button_states()

func _unhandled_input(event: InputEvent) -> void:
	# Toggle inventory with I key
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	
	# Close inventory with Escape key
	if is_open and event.is_action_pressed("ui_cancel"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

func toggle_inventory() -> void:
	is_open = !is_open
	visible = is_open
	
	if is_open:
		print(">>> Inventory OPENED")
		refresh_inventory()  # Refresh when opening
	else:
		print(">>> Inventory CLOSED")
		selected_slot = -1
		# Reset slot highlights
		for slot in slots:
			slot.modulate = Color(1, 1, 1)

func setup_slots() -> void:
	if not inventory:
		print(">>> ERROR: No inventory in setup_slots!")
		return
	
	# Clear existing slots
	for slot in slots:
		slot.queue_free()
	slots.clear()
	
	print(">>> Creating " + str(inventory.max_slots) + " slots...")
	
	# Create slot UI elements
	for i in range(inventory.max_slots):
		var slot = slot_scene.instantiate()
		slots_grid.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_right_clicked.connect(_on_slot_right_clicked)
		slots.append(slot)
		
		# Set initial data
		var item = inventory.get_item(i)
		var qty = inventory.get_item_quantity(i)
		
		# DEBUG
		if item != null:
			print("  Slot " + str(i) + " has item: " + item.item_name)
		
		slot.set_slot_data(i, item, qty)
	
	print(">>> Created " + str(slots.size()) + " inventory slots")
	print(">>> Grid has " + str(slots_grid.get_child_count()) + " children")

func refresh_inventory() -> void:
	if not inventory:
		return
	
	# Update all slots
	for i in range(slots.size()):
		var item = inventory.get_item(i)
		var qty = inventory.get_item_quantity(i)
		slots[i].set_slot_data(i, item, qty)
	
	update_button_states()

func _on_slot_clicked(slot_index: int, _button: int) -> void:
	selected_slot = slot_index
	print(">>> Selected slot: " + str(slot_index))
	
	# Highlight selected slot (optional visual feedback)
	for i in range(slots.size()):
		if i == slot_index:
			slots[i].modulate = Color(1.2, 1.2, 1.2)  # Brighten
		else:
			slots[i].modulate = Color(1, 1, 1)  # Normal
	
	update_button_states()

func _on_slot_right_clicked(slot_index: int) -> void:
	# Right click to quick-use item
	if inventory:
		inventory.use_item(slot_index)

func swap_slots(from_index: int, to_index: int) -> void:
	if inventory:
		inventory.move_item(from_index, to_index)

func _on_use_pressed() -> void:
	if selected_slot >= 0 and inventory:
		inventory.use_item(selected_slot)

func _on_equip_pressed() -> void:
	if selected_slot >= 0 and inventory:
		var item = inventory.get_item(selected_slot)
		if item and item == inventory.equipped_item:
			# Unequip
			inventory.unequip_item()
			equip_button.text = "Equip"
		else:
			# Equip
			inventory.equip_item(selected_slot)
			equip_button.text = "Unequip"

func _on_drop_pressed() -> void:
	if selected_slot >= 0 and inventory:
		var item = inventory.drop_item(selected_slot, 1)
		
		if item:
			# Spawn the item in the world near the player
			spawn_dropped_item(item)

func spawn_dropped_item(item: ItemData) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Load the pickup scene
	var pickup_scene = load("res://scenes/pickup_item.tscn")
	var pickup = pickup_scene.instantiate()
	
	# Set item data
	pickup.item_data = item
	pickup.quantity = 1
	
	# Position it near the player
	var drop_offset = Vector2(20, 0)  # Drop 20 pixels to the right
	if player.get_node("AnimatedSprite2D").flip_h:
		drop_offset.x = -20  # Drop to the left if facing left
	
	pickup.position = player.position + drop_offset
	
	# Add to the scene
	get_tree().root.add_child(pickup)
	print(">>> Dropped item: " + item.item_name)

func _on_throw_pressed() -> void:
	if selected_slot >= 0 and inventory:
		var item = inventory.throw_item(selected_slot)
		
		if item:
			spawn_thrown_item(item)

func spawn_thrown_item(item: ItemData) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print(">>> ERROR: Cannot throw - no player found")
		return
	
	if not item.icon:
		print(">>> ERROR: Item has no icon to throw")
		return
	
	# Load the thrown item scene
	var thrown_scene = load("res://scenes/thrown_item.tscn")
	if not thrown_scene:
		print(">>> ERROR: Could not load thrown_item.tscn")
		return
	
	var thrown = thrown_scene.instantiate()
	
	# Calculate throw direction based on player facing
	var throw_direction = Vector2.RIGHT
	if player.has_node("AnimatedSprite2D"):
		if player.get_node("AnimatedSprite2D").flip_h:
			throw_direction = Vector2.LEFT
	
	var throw_velocity = throw_direction * 300  # Horizontal speed
	throw_velocity.y = -150  # Upward arc (increased from -100)
	
	# Position at player chest height
	thrown.position = player.global_position + Vector2(0, -8)
	
	# Setup BEFORE adding to scene (important!)
	thrown.setup(item.icon, throw_velocity, item.throw_damage)
	
	# Add to scene root
	get_tree().root.add_child(thrown)
	
	print(">>> Threw: " + item.item_name + " with " + str(item.throw_damage) + " damage")

func update_button_states() -> void:
	if selected_slot < 0 or not inventory:
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true
		throw_button.disabled = true
		return
	
	var item = inventory.get_item(selected_slot)
	
	if item == null:
		use_button.disabled = true
		equip_button.disabled = true
		drop_button.disabled = true
		throw_button.disabled = true
		return
	
	# Enable/disable based on item type
	use_button.disabled = (item.item_type != "consumable")
	equip_button.disabled = not item.can_equip
	drop_button.disabled = false
	throw_button.disabled = (item.throw_damage <= 0)

func _process(_delta: float) -> void:
	# Debug: Press P to print inventory contents
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key for testing
		debug_print_inventory()

func debug_print_inventory() -> void:
	if not inventory:
		print(">>> DEBUG: No inventory reference!")
		return
	
	print(">>> DEBUG: Inventory contents:")
	for i in range(inventory.items.size()):
		var slot = inventory.items[i]
		if slot != null:
			print("  Slot " + str(i) + ": " + slot.item.item_name + " x" + str(slot.quantity))
		else:
			print("  Slot " + str(i) + ": Empty")
