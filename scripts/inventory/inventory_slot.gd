extends Panel

signal slot_clicked(slot_index: int, button: int)
signal slot_right_clicked(slot_index: int)

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $QuantityLabel
@onready var slot_button: Button = $SlotButton

var slot_index: int = 0
var item_data: ItemData = null
var quantity: int = 0

func _ready() -> void:
	slot_button.pressed.connect(_on_slot_pressed)
	slot_button.gui_input.connect(_on_slot_gui_input)
	update_display()

func set_slot_data(index: int, item: ItemData, qty: int) -> void:
	slot_index = index
	item_data = item
	quantity = qty
	update_display()

func clear_slot() -> void:
	item_data = null
	quantity = 0
	update_display()

func update_display() -> void:
	if item_data == null:
		item_icon.texture = null
		quantity_label.hide()
	else:
		item_icon.texture = item_data.icon
		quantity_label.text = str(quantity)
		
		if quantity > 1:
			quantity_label.show()
		else:
			quantity_label.hide()

func _on_slot_pressed() -> void:
	slot_clicked.emit(slot_index, MOUSE_BUTTON_LEFT)

func _on_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(slot_index)
			accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null:
		return null
	
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = item_data.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(32, 32)
	preview.modulate = Color(1, 1, 1, 0.7)
	
	set_drag_preview(preview)
	
	return {
		"slot_index": slot_index,
		"item": item_data,
		"quantity": quantity
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Can always drop items into slots
	return data is Dictionary and data.has("slot_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("slot_index"):
		# Tell the inventory to swap these slots
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		if inventory:
			inventory.swap_slots(data.slot_index, slot_index)
