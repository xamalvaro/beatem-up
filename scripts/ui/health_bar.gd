extends CanvasLayer

@onready var progress_bar = $Panel/ProgressBar
@onready var health_label = $Panel/HealthLabel

func _ready() -> void:
	# Find player and connect to health signal
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.max_health)
	else:
		print(">>> ERROR: Could not find player for health bar")

func _on_health_changed(current: int, maximum: int) -> void:
	if not progress_bar or not health_label:
		return
	
	progress_bar.max_value = float(maximum)  # Explicitly cast to float
	progress_bar.value = float(current)
	health_label.text = str(current) + " / " + str(maximum)
