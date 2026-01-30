extends CharacterBody2D

var speed = 35
var player_chase = false
var player = null

func _physics_process(delta: float) -> void:
	# Apply gravity FIRST
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle horizontal movement toward player
	if player_chase and player:
		var direction = (player.position - position).normalized()
		velocity.x = direction.x * speed
		
		$AnimatedSprite2D.play("walk")
		
		# Flip sprite based on direction
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		# Stop horizontal movement when not chasing
		velocity.x = move_toward(velocity.x, 0, speed)
		$AnimatedSprite2D.play("idle")
	
	# THIS IS THE KEY - use move_and_slide() to actually move the enemy
	move_and_slide()

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false
