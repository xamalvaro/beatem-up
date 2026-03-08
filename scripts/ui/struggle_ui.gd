extends Node2D

# Floats above the player's head during a grab.
# No meter — animation speed increases as struggle_meter fills.
# Attach this as a child of the player in main_dude.tscn.

@onready var sprite = $AnimatedSprite2D

# Vertical offset above player center — adjust to sit above their head
const HEAD_OFFSET: float = -28.0

# Animation speed range — slow when just grabbed, fast when almost free
const SPEED_MIN: float = 5.0
const SPEED_MAX: float = 18.0

func _ready() -> void:
	add_to_group("struggle_ui")
	visible = false
	_build_animation()

func _build_animation() -> void:
	var sheet = load("res://assets/UI animations/StruggleButtonMash.png")
	if not sheet:
		push_error(">>> StruggleUI: Could not load StruggleButtonMash.png — check the path!")
		return

	var frames = SpriteFrames.new()
	frames.add_animation("mash")
	frames.set_animation_loop("mash", true)
	frames.set_animation_speed("mash", SPEED_MIN)

	# 2x2 grid of 32x32 frames
	for row in range(2):
		for col in range(2):
			var tex = AtlasTexture.new()
			tex.atlas = sheet
			tex.region = Rect2(col * 32, row * 32, 32, 32)
			frames.add_frame("mash", tex)

	sprite.sprite_frames = frames
	sprite.animation = "mash"

func show_ui() -> void:
	visible = true
	position = Vector2(0, HEAD_OFFSET)
	sprite.play("mash")
	sprite.speed_scale = 1.0

func hide_ui() -> void:
	visible = false
	sprite.stop()

func set_meter(value: float) -> void:
	# Speed up animation as meter fills — gives player subtle progress feedback
	var t = clamp(value, 0.0, 1.0)
	var target_speed = lerp(SPEED_MIN, SPEED_MAX, t)
	sprite.speed_scale = target_speed / SPEED_MIN
