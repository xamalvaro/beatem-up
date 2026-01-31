extends Node
class_name Inventory

signal inventory_changed
signal item_equipped(item: ItemData)
signal item_unequipped(item: ItemData)

@export var max_slots: int = 20  # Total inventory slots

var items: Array = []  # Array of InventorySlot
var equipped_item: ItemData = null

class InventorySlot:
	var item: ItemData
	var quantity: int
	
	func _init(p_item: ItemData, p_quantity: int):
		item = p_item
		quantity = p_quantity

func _ready() -> void:
	# Initialize empty slots
	for i in range(max_slots):
		items.append(null)
	
	print(">>> Inventory initialized with " + str(max_slots) + " slots")

func add_item(item: ItemData, quantity: int = 1) -> bool:
	print(">>> Attempting to add: " + item.item_name + " x" + str(quantity))
	
	# Check if item can stack with existing items
	if item.stack_size > 1:
		for i in range(items.size()):
			if items[i] != null and items[i].item.item_name == item.item_name:
				# Found existing stack
				var space_left = item.stack_size - items[i].quantity
				if space_left >= quantity:
					# Can add all to this stack
					items[i].quantity += quantity
					inventory_changed.emit()
					return true
				else:
					# Partially fill this stack, continue with remainder
					items[i].quantity = item.stack_size
					quantity -= space_left
	
	# Find first empty slot
	for i in range(items.size()):
		if items[i] == null:
			items[i] = InventorySlot.new(item, quantity)
			inventory_changed.emit()
			print(">>> Added to slot " + str(i))
			return true
	
	print(">>> Inventory full!")
	return false  # Inventory full

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= items.size():
		return false
	
	if items[slot_index] == null:
		return false
	
	items[slot_index].quantity -= quantity
	
	if items[slot_index].quantity <= 0:
		items[slot_index] = null
	
	inventory_changed.emit()
	return true

func get_item(slot_index: int) -> ItemData:
	if slot_index < 0 or slot_index >= items.size():
		return null
	
	if items[slot_index] == null:
		return null
	
	return items[slot_index].item

func get_item_quantity(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= items.size():
		return 0
	
	if items[slot_index] == null:
		return 0
	
	return items[slot_index].quantity

func move_item(from_slot: int, to_slot: int) -> void:
	if from_slot < 0 or from_slot >= items.size():
		return
	if to_slot < 0 or to_slot >= items.size():
		return
	
	# Swap items
	var temp = items[from_slot]
	items[from_slot] = items[to_slot]
	items[to_slot] = temp
	
	inventory_changed.emit()
	print(">>> Moved item from slot " + str(from_slot) + " to " + str(to_slot))

func equip_item(slot_index: int) -> bool:
	var item = get_item(slot_index)
	
	if item == null:
		return false
	
	if not item.can_equip:
		print(">>> Cannot equip: " + item.item_name)
		return false
	
	# Unequip current item if any
	if equipped_item != null:
		unequip_item()
	
	equipped_item = item
	item_equipped.emit(item)
	print(">>> Equipped: " + item.item_name)
	return true

func unequip_item() -> void:
	if equipped_item == null:
		return
	
	var item = equipped_item
	equipped_item = null
	item_unequipped.emit(item)
	print(">>> Unequipped: " + item.item_name)

func use_item(slot_index: int) -> bool:
	var item = get_item(slot_index)
	
	if item == null:
		return false
	
	# Use the item
	item.use_item(get_parent())
	
	# Remove consumable items after use
	if item.item_type == "consumable":
		remove_item(slot_index, 1)
	
	return true

func drop_item(slot_index: int, quantity: int = 1) -> ItemData:
	if slot_index < 0 or slot_index >= items.size():
		return null
	
	if items[slot_index] == null:
		return null
	
	var item = items[slot_index].item
	
	# Remove from inventory
	remove_item(slot_index, quantity)
	
	print(">>> Dropped: " + item.item_name + " x" + str(quantity))
	return item
	
func throw_item(slot_index: int) -> ItemData:
	var item = get_item(slot_index)
	
	if item == null:
		return null
	
	if item.throw_damage <= 0:
		print(">>> Cannot throw: " + item.item_name)
		return null
	
	# Remove from inventory
	remove_item(slot_index, 1)
	
	print(">>> Throwing: " + item.item_name)
	return item
