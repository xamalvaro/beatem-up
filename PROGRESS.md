# Beat 'Em Up — Development Log

A 2D side-scrolling beat 'em up with fighting-game mechanics, built in **Godot 4.6** (started on 4.5).
This document summarizes everything done on the project so far, based on the repository's commit history (25 commits, Jan 29 – Mar 12, 2026).

---

## Current Feature Summary

| Area | Status |
|---|---|
| Player state machine (idle, run, jump, crouch, crawl, attacks, grabbed) | ✅ Working |
| Attack combos (stomps, sweep, drop kick, crawl sweep) | ✅ Working |
| Player & enemy hitboxes | ✅ Working (follow facing direction) |
| Zombie enemy (chase, lunge attack, stun, knockback, death) | ✅ Working |
| Grab mechanic + button-mash escape | ✅ Working: needs a staggered player, deals damage (animations need polish) |
| Input buffer, cancels, coyote/variable jump | ✅ Working |
| Frame data, hitstop, hitstun, knockdown, screen shake | ✅ Working |
| Heavy attack (D), dodge (Shift), hurt + death states | ✅ Working (placeholder animations) |
| Automated playtest + F3 debug overlay | ✅ Working |
| Inventory UI + item pickup | ✅ Working |
| Usable items (Bandage, Energy Drink) | ✅ Working |
| Throwable weapon (Fireman Axe) | ✅ Working |
| Health bar HUD | ✅ Working |
| Pistol / Magnum | 🎨 Sprites added, not yet implemented |

## Controls (current input map)

| Action | Key |
|---|---|
| Move left / right | Arrow keys (`ui_left` / `ui_right`) |
| Crouch | Down arrow (`ui_down`) |
| Jump | Space / Enter (`ui_accept`) |
| Attack A (combo: S, S, S) | **S** |
| Attack B, heavy kick (S, S, D branches into it) | **D** |
| Dodge (i-frames) | **Shift** |
| Debug overlay | **F3** |
| Crawl / go prone | **C** |
| Pick up item | **E** |
| Throw equipped item | **T** |
| Open inventory | **Tab** |
| Close inventory | **Esc** |
| Break free from grab | Mash **Attack A** |

> Early commits mapped attacks to F/G; they were later remapped to S/D in `project.godot`.

---

## Timeline

### Phase 1 — Foundation & Player State Machine (Jan 29, 2026)

- **Initial commit** — project scaffold, player (`main_dude`), enemy, and game scene.
- **Enemy gravity fix** — switched the enemy from `move_and_collide` to `move_and_slide` so it detects the floor instead of floating.
- **State machine implemented**
  - `state.gd` base class reworked to support character movement.
  - `player_state_machine.gd` drives the player.
  - First states: **Idle**, **Run**, **Jump**.
  - Added `attack_a` / `attack_b` input actions.
- **Run/Jump/Idle fully wired up** as nodes under the player's StateMachine; `main_dude.gd` reduced to constants since logic moved into states.
- **New animations from sprite sheet:** crawl, crouch, crouch_walk, drop_kick, pushup (recovery from crawl), stomp, sweep.
- **Attack states added** — multiple attack states; original states updated to transition into them. Mapped **C** to crawl.
- **Bug-fix pass**
  - Prone state now has enter/exit animations (`crawl_enter`, `crawl_idle`, `crawl_move`, `pushup`).
  - Sweep no longer hits continuously.
  - Debug output prints the current state.
  - Drop kick reads its state correctly and plays faster.
  - Added `crawlsweep_state.gd`.
- **Script restructure** — briefly moved attacks/crawl into subfolders, then reverted to a flat `scripts/States/` folder.

### Phase 2 — Inventory, Items & HUD (Jan 29–30, 2026)

- **Storage system** — `inventory.gd`, `item.gd` (Resource), `pickup_item.gd`, and a `Pickup_item` scene. First prototype item: **Bandage**.
- **Inventory UI** — `InventoryUI.tscn`, `inventory_slot.tscn`, `inventory_ui.gd`, `inventory_slot.gd`. Picked-up items now appear in the player's inventory.
- **Thrown items & health bar**
  - `thrown_item.gd` / `thrown_item.tscn` for throwing items.
  - `health_bar.gd` / `health_bar.tscn` HUD.
  - Usable items: speed boost and healing.
- **Minor bug fixes** — health bar pinned to top of screen, thrown-item crash fixed, inventory now clickable with the mouse.

### Phase 3 — Art & Enemy Animations (Feb 27, 2026)

- **First zombie** (`zombie1_1.png`) with animations added to `enemy.tscn`.
- **Three item sprites:** Fireman Axe, Bandage, Energy Drink (files later renamed for simplicity).
- **Item animations hooked into the game.** Items are 32×32 and scaled to 0.65 (see `pickup_item.gd`). The Baseball Bat placeholder was replaced by the Fireman Axe.

Current item definitions (`scripts/item/*.tres`):

| Item | Type | Effect |
|---|---|---|
| Bandage | Consumable (stack 5) | Heals 20 HP |
| Energy Drink | Consumable (stack 3) | +50% speed for 5 s |
| Fireman Axe | Weapon (equippable, throwable) | 30 melee dmg / 15 throw dmg |

### Phase 4 — Engine Upgrade (Mar 4, 2026)

- Item z-index set to match characters so items render behind the player when walked over.
- **Migrated Godot 4.5 → 4.6** (merged via PR #4, branch `godot-4-6-migration`), then ran *Project → Tools → Upgrade Project Files* to update all scenes/resources.

### Phase 5 — Combat: Hitboxes & Throwing (Mar 4, 2026)

- **Hitboxes** for player (`punch_hitbox.gd`) and zombie. New physics layers: `player_hitbox` (6) and `zombie_attack` (7).
- **Axe throwing** — an equipped axe can be thrown at a zombie, triggering its death animation and removing it.
- Large expansion of `enemy.gd`: chase, lunge attack with cooldown, hit points, stun, knockback, damage flash.
- **Hitbox fixes** — drop kick, sweep kick, and stomp now register hits; hitboxes flip with the player's facing direction. Zombie death no longer loops — it disappears after dying.

### Phase 6 — Grab Mechanic (Mar 7, 2026)

- Zombies can **grab** the player: after 2 stagger hits (`HITS_TO_GRAB`) and when within grab range, the player enters `grabbed_state.gd`.
- **Button-mash escape:** mashing Attack A fills a struggle meter (+0.25 per press, decays 0.15/s) while the player takes 5 dmg/s. Filling it breaks free; the zombie then has a 4 s grab cooldown.
- `struggle_ui.gd` shows a "mash A" prompt (`StruggleButtonMash.png`) above the player's head.
- New art: `Player_Concept_3.png`, `Swing_Animations.png`.
- Note: animations still need polish; mechanics are fully functional.

### Phase 7 — Upcoming Weapon Art (Mar 12, 2026)

- **Pistol / Magnum sprites** added under `assets/Don's sprite animation/` (contributed by a collaborator). Not yet implemented in code.

---

### Phase 8 — Game Feel & Optimization Overhaul (Nov 2026)

Done to address feedback that combat "feels a bit clunky". Full details in `OPTIMIZATION_PLAN.md`.

- **Responsiveness:**
  - Input buffer, so presses are no longer dropped.
  - Attacks recover fast (a stomp went from 49 to 19 frames).
  - Hit-confirm combo cancels, plus movement/jump cancels of late recovery.
  - Coyote time, jump buffer and variable jump height.
- **Hit feel:**
  - Per-attack frame data (`scripts/attacks/*.tres`).
  - Hitstop, screen shake and hit sparks.
  - Zombie hitstun, knockback and knockdown.
  - One swing hits every zombie it touches.
- **Depth:**
  - Heavy kick on D and an S,S,D branch.
  - Dodge with i-frames.
  - Player hurt and death states.
  - Fair grabs: staggered players only, from close range, and the grab now deals damage.
- **Cleanup:**
  - Zombie state machine.
  - One data-driven attack script.
  - Named collision layers.
  - `DebugLog` replaces 108 prints.
  - Cached node lookups.
- **Bug fixes:**
  - Crawl sweep dealt no damage.
  - Grab damage never applied.
  - The grab-triggering hit couldn't kill.
  - Zombies teleported in to grab.
  - Thrown items hit from 45 px away.
  - Inventory UI path casing broke loading on Linux.
- **Tests:** `tests/feel_test.gd` (29 checks) and `tests/soak_test.gd`.

## Project Structure

```
assets/
  CITY_TILES/              City tileset (+ license, previews)
  Don's sprite animation/  Player, zombie, swing, and pistol/magnum sprites
  item animations/         Bandage, EnergyDrink, FiremanAxe
  UI animations/           StruggleButtonMash
scenes/
  game.tscn, main_dude.tscn, enemy.tscn, Pickup_item.tscn, thrown_item.tscn
  UI/ InventoryUI.tscn, inventory_slot.tscn, health_bar.tscn
scripts/
  main_dude.gd, enemy.gd, punch_hitbox.gd, thrown_item.gd, input_buffer.gd
  attacks/   AttackData + one .tres per attack (frame data, damage, combos)
  autoload/  GameFeel (hitstop/shake/sparks), DebugOverlay (F3), DebugLog
  States/    state machine + all player states
  inventory/ inventory.gd, inventory_slot.gd, item.gd, pickup_item.gd
  item/      Bandage, Energy_Drink, FiremanAxe (.tres)
  ui/        health_bar.gd, inventory_ui.gd, struggle_ui.gd
```

## Running the tests

```
godot --headless --fixed-fps 60 -s res://tests/feel_test.gd
godot --headless --fixed-fps 60 -s res://tests/soak_test.gd
```

## Known To-Dos
- Real animations for hurt, dodge, death, and a heavy kick (they currently reuse other animations).
- Hit spark art (currently a procedural placeholder).
- Blocking.
- Polish grab/struggle animations.
- Implement the Pistol/Magnum weapon using the new sprites.
- Add more enemy types and level content using the city tileset.
