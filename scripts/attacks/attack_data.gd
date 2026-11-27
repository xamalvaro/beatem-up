extends Resource
class_name AttackData

# All the tuning for one attack. Frame counts are at 60 fps.
#
#   | startup | active (hitbox on) | recovery |
#                       ^ hit-confirm cancel     ^ move cancel (half way)
#
# Edit the .tres files in scripts/attacks/ to tune moves without touching code.

@export var animation: StringName = &"stomp"
@export var damage: int = 1

@export_group("Frame data")
@export var startup: int = 5
@export var active: int = 4               # -1 = until landing (aerial attacks)
@export var recovery: int = 10
@export var fit_animation: bool = true    # Stretch the animation to match the total length

@export_group("On hit")
@export var knockback: Vector2 = Vector2(60, 0)  # x is forward (flipped by facing), y is up (negative)
@export var hitstun: int = 18                    # Frames the enemy can't act
@export var hitstop: int = 4                     # Freeze frames for both fighters
@export var knockdown: bool = false
@export var screen_shake: float = 0.0

@export_group("Hitbox")
@export var hitbox_offset_y: float = 0.0

@export_group("Movement")
@export var air_control: float = 0.0             # 0 = locked in place
@export var lunge_speed: float = 0.0             # Forward speed during startup + active
@export var gravity_multiplier: float = 1.0

@export_group("Combo routes")
@export var next_a: String = ""
@export var next_b: String = ""
@export var down_a: String = ""
@export var down_b: String = ""
@export var forced_followup: String = ""         # Always goes here after (e.g. "pushup")

const FPS: float = 60.0

func startup_time() -> float:
	return startup / FPS

func active_end_time() -> float:
	return (startup + active) / FPS

func total_time() -> float:
	return (startup + max(active, 0) + recovery) / FPS
