extends SceneTree

# Soak test: real level, real zombie AI, player walks in and mashes attacks for
# ~20 seconds. Fails on any script error; prints what happened.
#
#   godot --headless --fixed-fps 60 -s res://tests/soak_test.gd

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var p = get_first_node_in_group("player")
	var zombies := get_nodes_in_group("enemy").size()
	var states := {}
	var grabbed := false
	var min_hp: int = p.max_health
	var dir := 1.0
	for i in 1200:
		await physics_frame
		if p.is_dead:
			break
		var near = null
		for e in get_nodes_in_group("enemy"):
			if not e.is_dead:
				near = e
		if near:
			dir = signf(near.global_position.x - p.global_position.x)
		Input.action_release("ui_left"); Input.action_release("ui_right")
		if near and abs(near.global_position.x - p.global_position.x) > 22:
			Input.action_press("ui_right" if dir > 0 else "ui_left")
		elif i % 6 == 0:
			Input.action_press("attack_a" if i % 24 else "attack_b")
		else:
			Input.action_release("attack_a"); Input.action_release("attack_b")
		states[String(p.state_machine.current_state.name)] = true
		grabbed = grabbed or p.is_grabbed
		min_hp = min(min_hp, p.current_health)
	var left := get_nodes_in_group("enemy").filter(func(e): return not e.is_dead).size()
	print("zombies at start: %d, alive at end: %d" % [zombies, left])
	print("player states used: ", states.keys())
	print("player lowest HP: %d, was grabbed: %s, dead: %s" % [min_hp, grabbed, p.is_dead])

	# Scenario 2: stand still next to a fresh zombie and let it attack
	for a in ["ui_left", "ui_right", "attack_a", "attack_b"]:
		Input.action_release(a)
	current_scene.free()
	scene = load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	p = get_first_node_in_group("player")
	for e in get_nodes_in_group("enemy"):
		e.free()
	for i in 20:
		await physics_frame
	var z = load("res://scenes/enemy.tscn").instantiate()
	z.position = p.global_position + Vector2(30, -4)
	current_scene.add_child(z)
	var hp_start: int = p.current_health
	grabbed = false
	var mashed_free := false
	for i in 1800:
		await physics_frame
		if p.is_grabbed:
			grabbed = true
			if i % 4 == 0:
				Input.action_press("attack_a")
			else:
				Input.action_release("attack_a")
		elif grabbed:
			mashed_free = true
			break
	print("idle player: HP %d -> %d, got grabbed: %s, mashed free: %s" % [hp_start, p.current_health, grabbed, mashed_free])
	quit()
