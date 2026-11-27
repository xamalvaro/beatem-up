# Game Feel & Code Optimization Plan

Goal: make combat feel **responsive and snappy** like a fighting game, and clean up the code so it's faster and easier to extend.

This plan comes from a read-through of every gameplay script (`scripts/States/*`, `main_dude.gd`, `enemy.gd`, `punch_hitbox.gd`, `thrown_item.gd`, the UI scripts) and the animation data in `scenes/main_dude.tscn`.

---

## Why it feels clunky (root causes)

Fighting-game players notice **input lag, dropped inputs, long recovery, and hits with no weight**. The code has all four.

| # | Problem | Where | Effect on feel |
|---|---|---|---|
| 1 | **Inputs pressed during an attack are thrown away.** The combo check only runs *after* `attack_duration` ends, using `is_action_just_pressed` (true for a single frame). | `attack_state.gd:97-118` | Mashing S to combo often does nothing. This is the #1 cause of the "clunky" feeling. |
| 2 | **Every attack locks you in for its full duration plus the full combo window**, even if you don't combo. A single stomp freezes the player for 0.4 s + 0.4 s = **0.8 s**, and you can't move or jump during the window. | `attack_state.gd:75-120`, `stomp_state.gd` | Feels sluggish. You can't walk away from a whiffed attack. |
| 3 | **Attack timers don't match the animations.** Sweep is 10 frames at 10 fps (1.0 s) but the state ends at 0.5 s. All attack animations are set to `loop = true`. | `main_dude.tscn`, `sweep_state.gd` | Animations cut off halfway or restart, so what you see doesn't match what's happening. |
| 4 | **Hitboxes are active for the whole attack** (no startup, active or recovery frames). | `attack_state.gd:_enable_hitbox` | Hits land on frame 1, before the kick visually connects. |
| 5 | **No hit feedback**: no hitstop (freeze frames), no enemy hitstun or knockback on normal hits, no screen shake. Zombies keep lunging while you hit them. | `enemy.gd:take_damage` | Hits feel weightless, and you trade hits instead of interrupting the enemy. |
| 6 | **A punch hits only one enemy.** The hitbox turns itself off after its first hit. | `punch_hitbox.gd:22` | Crowds (the core of a beat 'em up) can't be hit together. |
| 7 | ~~Jump exits on its first frame~~. Checked by running the game headless: **not a bug**, the jump works. |
| 8 | **No jump buffer, no coyote time, fixed jump height.** | `jump_state.gd`, `idle/run_state.gd` | Jumps get eaten if pressed slightly early or late. |
| 9 | **Attack B (D) does almost nothing.** Every state's `next_attack_b` is empty. | all attack states | Half the attack buttons are unused. |
| 10 | **You can't turn around between attacks**, and there's no dash, block or dodge. | attack states | Hard to deal with enemies on both sides. |

### Bugs found along the way

| Bug | Where |
|---|---|
| **Being grabbed does no damage.** `grabbed_state` calls `player.take_damage()`, which returns early because `is_grabbed` is true. | `grabbed_state.gd:49`, `main_dude.gd:48` |
| **The player can't die from the hit that triggers a grab.** That code path `return`s before the `current_health <= 0` check. | `main_dude.gd:61-64` |
| **A stagger grab teleports in the nearest zombie from anywhere on the map.** There's no range check. | `main_dude.gd:_try_stagger_grab`, `enemy.gd:97` |
| **Crawl sweep deals no damage.** It doesn't extend `AttackState` and never enables a hitbox. | `crawlsweep_state.gd` |
| **The axe damage bonus is keyed on the string `"Fireman Axe"`.** Renaming the item silently breaks it. | `attack_state.gd:11,64` |
| **Collision layers are set in both scripts and scenes**, and the comments contradict each other (e.g. "enemy layer 1" vs "enemy layer 2"). | `punch_hitbox.gd`, `thrown_item.gd`, `enemy.gd`, `.tscn` files |
| **The zombie's lunge uses `await create_timer()`.** If the zombie dies or is grabbed mid-lunge, the coroutine still runs afterwards. | `enemy.gd:138` |

### Efficiency / code-health issues

- **108 `print()` calls**, many of them on every state transition, every mash press and every hit. Printing is slow in Godot and floods the output. Put them behind a single `DEBUG` flag.
- **Lookups repeated every frame**, e.g. `player.get_node("AnimatedSprite2D")`, `get_node_or_null("PunchHitBox")`, `get_node_or_null("StruggleUI")`. Cache them once with `@onready` on the player and reuse.
- **Copy-pasted logic in every state**: gravity, reading left/right input, flipping the sprite. Move it into shared helpers on `State` or the player.
- **`stomp`, `stomp2` and `stomp3` are near-identical scripts**, configured by overwriting `@export` values in `_ready()`, which defeats the exports. Use one `AttackState` script with the values set in the Inspector, or an `AttackData` resource.
- **`crawlsweep_state.gd` re-implements `AttackState` by hand.**
- **`state_machine.gd` (the enemy machine) is unused.** The enemy runs on flags (`is_attacking`, `is_grabbing`, `is_stunned`…) instead.
- **`inventory_ui.gd` polls in `_process`** for a debug key every frame.

---

## The plan

Each phase is shippable on its own and can be tested in-game before moving on. Phases 1–2 fix most of the clunkiness.

### Phase 1 — Responsiveness (biggest impact, small changes) ✅ DONE

> Done. Measured with a headless input-simulation test:
>
> | | Before | After |
> |---|---|---|
> | Single stomp, frames until free | 49 | 26 |
> | Mashing A early | stomp → idle (presses dropped) | stomp → stomp2 → stomp3 |
> | Tap vs hold jump height | 48.5 / 48.5 | 16.5 / 48.5 |
> | Jump pressed just before landing | dropped | re-jumps |
>
> Tuning knobs: `InputBuffer.DEFAULT_WINDOW`, `COYOTE_TIME` / `JUMP_BUFFER` / `JUMP_CUT` in `main_dude.gd`, and `attack_duration` / `recovery` / `cancel_ratio` in each attack state's `_ready()`.

1. **Input buffer.** Add a small `InputBuffer` (on the player or as an autoload). It records the time of each `attack_a`, `attack_b`, `jump` and `crawl` press. States call `buffer.consume("attack_a", 0.15)` instead of `Input.is_action_just_pressed`. Presses made during an attack are remembered and fire the next move as soon as it's allowed.
2. **Cancel windows instead of lockout.**
   - Allow a combo cancel from late in the active frames onward, not only after the attack ends.
   - After recovery, return to idle/run **immediately**. Drop the "combo window" freeze; the input buffer replaces it.
   - Allow movement and jump to cancel the last ~30% of recovery.
3. **Jump improvements.** Check for landing after `move_and_slide`, handle walking off ledges, and add **coyote time** (~0.1 s), a **jump buffer** (~0.1 s, via the input buffer) and **variable jump height** (cut upward velocity when the button is released).
4. **Turn-around between attacks.** Read the facing direction when each attack starts.

### Phase 2 — Hit feel ("juice")

1. **Frame data per attack**: `startup`, `active`, `recovery` (in frames at 60 fps). Enable the hitbox only during the active frames. Store it in an `AttackData` resource: damage, frame data, hitbox offset and size, knockback, hitstop, next combo moves.
2. **Make attack animations non-looping** and set their fps so the animation length equals startup + active + recovery.
3. **Hitstop**: freeze attacker and target for 3–6 frames on hit (pause both sprites, or set `Engine.time_scale` briefly). This is the biggest single "weight" improvement.
4. **Enemy hitstun + knockback** on every hit, so a hit interrupts the zombie's lunge. The combo finisher (stomp 3) knocks the enemy down.
5. **Multi-target hits**: each hitbox activation keeps a `hit_this_swing` set, so every enemy is hit once per swing instead of only the first.
6. **Small screen shake** on heavy hits, plus a hit spark sprite.

### Phase 3 — Combat depth

1. **Give Attack B (D) a purpose**, e.g. a heavier, slower kick that launches or knocks back. Add a branching combo: `S, S, D` = launcher, `S, S, S` = finisher.
2. **Make the stagger/grab fairer**:
   - Only a zombie **within grab range** can grab.
   - Use hitstun instead of "any 2 hits = grab".
   - Make the grab damage actually apply (bypass the `is_grabbed` check for grab damage).
   - Check for death on every damage path.
3. **Optional**: a dodge/backdash with i-frames, and a block. Both are expected by fighting-game players.

### Phase 4 — Code cleanup & efficiency

1. **Cache node references** on the player (`sprite`, `hitbox`, `hitbox_shape`, `inventory`, `struggle_ui`). States use `player.sprite` etc.
2. **Base-class helpers** on `State`: `apply_gravity(delta)`, `get_move_input()`, `face(direction)`. Remove the duplicated code from all 15 states.
3. **Merge `stomp`, `stomp2`, `stomp3` and `sweep`** into one `AttackState` driven by `AttackData` resources. Rewrite `crawlsweep` as an `AttackState` with a forced `pushup` follow-up.
4. **Add a `Debug.log()` wrapper** with a global toggle. Remove or guard all 108 prints.
5. **Put the enemy on a state machine** (Idle / Chase / Lunge / Grab / Hitstun / Stunned / Dead) using the existing `state_machine.gd`. Replace the `await` timers with state timers.
6. **Centralize collision layers.** Use the named layers in Project Settings (`player`, `enemy`, `player_hitbox`, `enemy_hitbox`, `world`), set them only in the scenes, and delete the hard-coded numbers in the scripts.
7. **Replace the axe name check** with an `item.damage_multiplier` (or `weapon_damage`) field, which already exists on the resource.
8. **Remove the `_process` debug poll** in `inventory_ui.gd`, or handle it in `_unhandled_input`.

### Phase 5 — Verify

- Playtest checklist: buffered 3-hit combo, cancel into jump, turn-around combo, jump buffer and coyote jump, drop kick reachable, multi-zombie hit, grab only at close range, grab damage, death on any damage source.
- Show an on-screen debug overlay (current state, buffered inputs, frame counter) to tune frame data with your friend.

---

## Suggested starting numbers (tune by feel)

| Move | Startup | Active | Recovery | Damage | Hitstop |
|---|---|---|---|---|---|
| Stomp 1 | 4f | 3f | 8f | 1 | 4f |
| Stomp 2 | 4f | 3f | 10f | 1 | 4f |
| Stomp 3 (finisher) | 6f | 4f | 16f | 2 | 7f + knockdown |
| Sweep | 6f | 4f | 14f | 1 | 5f + trip |
| Drop kick | 3f | until landing | 10f | 2 | 6f |

For reference, the current stomp takes **~48 frames** (0.8 s) from start to idle. The table above brings it to **~15 frames**.

| Movement | Value |
|---|---|
| Input buffer | 0.15 s (9 frames) |
| Coyote time | 0.1 s |
| Jump buffer | 0.1 s |
| Recovery cancel point | last 30% of recovery |

---

## Recommended order

1. Phase 1 (input buffer, cancel windows, jump fix). Playtest with your friend.
2. Phase 2 items 1–4 (frame data, hitstop, hitstun).
3. Phase 4 cleanup. Easier to do once Phase 2 introduces `AttackData`.
4. Phase 3 depth features.
