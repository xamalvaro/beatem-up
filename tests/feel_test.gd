extends SceneTree

# Headless playtest: simulates button presses and checks game feel + combat rules.
#
#   godot --headless --fixed-fps 60 -s res://tests/feel_test.gd
#
# Exit code 0 = all checks passed.

# Untyped + loaded at runtime: in -s mode this script compiles before autoloads exist.
var ENEMY_SCENE
var gf
var player
var sm
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

# --- helpers ---

func st() -> String:
	return String(sm.current_state.name).to_lower()

func step(n := 1) -> void:
	for i in n:
		await physics_frame

func tap(action: String, hold := 1) -> void:
	Input.action_press(action)
	await step(hold)
	Input.action_release(action)

func check(name: String, ok: bool, detail = "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("  PASS  " if ok else "  FAIL  ") + name + ("" if str(detail) == "" else "  (" + str(detail) + ")"))

func clear_enemies() -> void:
	for e in get_nodes_in_group("enemy"):
		e.free()

func reset() -> void:
	for a in ["ui_left", "ui_right", "ui_down", "ui_accept", "attack_a", "attack_b", "crawl", "dodge"]:
		Input.action_release(a)
	clear_enemies()
	await step(2)
	player.is_grabbed = false
	player.grabbing_zombie = null
	player.is_invincible = false
	player.is_dead = false
	player.modulate = Color.WHITE
	player.stagger_hits = 0
	player.current_health = player.max_health
	player.dodge_cooldown = 0
	sm.on_state_transition("idle")
	player.input_buffer.clear()
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(spawn.x, spawn.y)
	await step(30)

var spawn: Vector2

func spawn_enemy(dx: float, ai := false) -> Node:
	var e = ENEMY_SCENE.instantiate()
	e.ai_enabled = ai
	e.position = player.global_position + Vector2(dx, 0)
	current_scene.add_child(e)
	return e

func frames_until(cond: Callable, limit := 240) -> int:
	for i in limit:
		if cond.call():
			return i
		await step()
	return -1

# --- tests ---

func _run() -> void:
	ENEMY_SCENE = load("res://scenes/enemy.tscn")
	gf = root.get_node("GameFeel")
	var scene = load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await step(5)
	clear_enemies()
	player = get_first_node_in_group("player")
	sm = player.state_machine
	await step(30)
	spawn = player.global_position
	check("player starts on floor", player.is_on_floor())

	print("\n[Movement]")
	await reset()
	var y0: float = player.global_position.y
	Input.action_press("ui_accept")
	await step(2)
	check("jump enters jump state", st() == "jump", st())
	var min_y := y0
	for i in 60:
		min_y = min(min_y, player.global_position.y); await step()
	Input.action_release("ui_accept")
	var held := y0 - min_y
	await reset()
	await tap("ui_accept", 3)
	min_y = y0
	for i in 60:
		min_y = min(min_y, player.global_position.y); await step()
	var tapped := y0 - min_y
	check("tap jump is shorter than held jump", tapped < held * 0.6, "tap %.1f vs held %.1f" % [tapped, held])

	await reset()
	await tap("ui_accept", 30)
	var pressed := false
	var rejumped := false
	for i in 120:
		if not pressed and player.velocity.y > 0 and player.global_position.y > y0 - 6:
			pressed = true
			await tap("ui_accept")
		if pressed and st() == "jump" and player.velocity.y < 0:
			rejumped = true; break
		await step()
	check("jump pressed just before landing still fires (buffer)", rejumped)

	await reset()
	await tap("ui_accept", 20)
	await tap("attack_a")
	await step()
	check("air attack = drop kick", st() == "dropkick", st())

	await reset()
	await tap("dodge")
	await step()
	check("dodge enters dodge state", st() == "dodge", st())
	check("dodge is invincible", player.is_invincible)
	var hp: int = player.current_health
	player.take_damage(10, player.global_position)
	check("damage ignored while dodging", player.current_health == hp)

	print("\n[Attacks]")
	await reset()
	await tap("attack_a")
	await step()
	check("A = stomp", st() == "stomp", st())
	var f: int = await frames_until(func(): return st() == "idle")
	check("single stomp recovers quickly (< 25f)", f > 0 and f < 25, "%d frames" % f)

	await reset()
	var seen := {}
	await tap("attack_a"); await step(3); await tap("attack_a")
	for i in 120:
		seen[st()] = true
		if st() == "stomp2" and not seen.has("_p"):
			seen["_p"] = true
			await tap("attack_a")
		await step()
	check("mashing A early chains stomp > stomp2 > stomp3", seen.has("stomp2") and seen.has("stomp3"), seen.keys())

	await reset()
	seen = {}
	await tap("attack_a"); await step(3); await tap("attack_a")
	for i in 120:
		seen[st()] = true
		if st() == "stomp2" and not seen.has("_p"):
			seen["_p"] = true
			await tap("attack_b")
		await step()
	check("S, S, D branches into heavy", seen.has("heavy") and not seen.has("stomp3"), seen.keys())

	await reset()
	await tap("attack_b"); await step()
	check("D from neutral = heavy", st() == "heavy", st())

	await reset()
	await tap("attack_a")
	Input.action_press("ui_left")
	await step()
	var flipped: bool = player.sprite.flip_h
	await step(40)
	Input.action_release("ui_left")
	check("attack faces held direction", flipped)

	print("\n[Hits]")
	await reset()
	player.sprite.flip_h = false
	var e1 = spawn_enemy(15)
	var e2 = spawn_enemy(17)
	await step(5)
	var froze := false
	await tap("attack_a")
	for i in 30:
		if gf.is_frozen(): froze = true
		await step()
	check("one stomp hits BOTH overlapping zombies", e1.hit_points == 3 and e2.hit_points == 3, "%d, %d" % [e1.hit_points, e2.hit_points])
	check("hit causes hitstop", froze)
	check("hit zombie goes into hitstun/knockback", e1.state in [e1.S.HITSTUN, e1.S.CHASE, e1.S.IDLE] and e1.global_position.x > player.global_position.x + 16)

	await reset()
	player.sprite.flip_h = false
	e1 = spawn_enemy(14, true)
	await step(2)
	e1._set_state(e1.S.LUNGE)
	e1.take_damage(1, Vector2(50, 0), 0.3, false)
	check("hit interrupts zombie lunge", e1.state == e1.S.HITSTUN)

	await reset()
	e1 = spawn_enemy(15)
	await step(3)
	await tap("crawl"); await step(30)
	await tap("attack_a")
	await step(40)
	check("crawl sweep now deals damage", e1.hit_points < e1.max_hit_points, "HP %d" % e1.hit_points)

	await reset()
	player.inventory.equipped_item = load("res://scripts/item/FiremanAxe.tres")
	check("axe doubles damage via damage_multiplier", is_equal_approx(player.get_damage_multiplier(), 2.0))
	player.inventory.equipped_item = null

	print("\n[Grabs & damage]")
	await reset()
	e1 = spawn_enemy(100, true)
	player.stagger_hits = 2
	player.stagger_timer = 2.0
	await step(10)
	check("far zombie can't grab a staggered player", not player.is_grabbed)

	await reset()
	e1 = spawn_enemy(18, true)
	await step(5)
	check("zombie doesn't grab an un-staggered player", not player.is_grabbed)
	player.stagger_hits = 2
	player.stagger_timer = 2.0
	var grabbed_at: int = await frames_until(func(): return player.is_grabbed, 120)
	check("close zombie grabs a staggered player", grabbed_at >= 0)
	hp = player.current_health
	await step(60)
	check("being grabbed deals damage", player.current_health < hp, "%d -> %d" % [hp, player.current_health])
	for i in 8:
		await tap("attack_a"); await step(2)
	await step(2)
	check("mashing breaks free", not player.is_grabbed and st() != "grabbed", st())
	check("zombie stunned after break-free", e1.state == e1.S.STUNNED)

	await reset()
	player.current_health = 5
	player.take_damage(10, player.global_position + Vector2(10, 0))
	await step()
	check("lethal hit kills (no stagger/grab skip)", player.is_dead and st() == "dead", st())

	await reset()
	player.current_health = 3
	player.is_grabbed = true
	sm.on_state_transition("grabbed")
	await step(60)
	check("grab damage can kill", player.is_dead)

	await reset()
	player.take_damage(10, player.global_position + Vector2(10, 0))
	await step()
	check("getting hit interrupts into hurt state", st() == "hurt", st())

	print("\n%d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)
