extends Resource
class_name ItemData

@export var item_name: String = "Item"
@export var description: String = "A basic item"
@export var icon: Texture2D  # The sprite shown in inventory
@export var item_type: String = "consumable"  # "consumable", "weapon", "throwable"
@export var stack_size: int = 1  # How many can stack in one slot
@export var can_equip: bool = false
@export var throw_damage: int = 0  # Damage if thrown
@export var use_effect: String = ""  # What happens when used (e.g., "heal_20", "boost_speed")

func use_item(player) -> void:
	# This will be called when the item is used
	match use_effect:
		"heal_20":
			print("Healing player for 20 HP")
			# Add healing logic here later
		"boost_speed":
			print("Boosting player speed")
			# Add speed boost logic here later
		_:
			print("Item used: " + item_name)
