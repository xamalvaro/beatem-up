extends Resource
class_name ItemData

@export var item_name: String = "Item"
@export var description: String = "A basic item"
@export var icon: Texture2D
@export var item_type: String = "consumable"  # "consumable", "weapon", "throwable"
@export var stack_size: int = 1
@export var can_equip: bool = false
@export var throw_damage: int = 0
@export var use_effect: String = ""

# Weapon stats (if equippable)
@export var weapon_damage: int = 0
@export var attack_speed_multiplier: float = 1.0

func use_item(player) -> void:
	match use_effect:
		"heal_20":
			if player.has_method("heal"):
				player.heal(20)
		"heal_50":
			if player.has_method("heal"):
				player.heal(50)
		"boost_speed":
			if player.has_method("boost_speed"):
				player.boost_speed(5.0, 1.5)  # 1.5x speed for 5 seconds
		"full_heal":
			if player.has_method("heal"):
				player.heal(999)  # Heal to max
		_:
			print(">>> Item used: " + item_name + " (no effect)")
