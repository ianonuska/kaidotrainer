extends RefCounted
# CombatSystem.gd - Combat and tunnel fight logic
# Usage: var combat = CombatSystem.new(self) in _ready()

var game  # Reference to main game script

func _init(game_ref):
	game = game_ref

# ===========================================
# COMBAT INITIALIZATION
# ===========================================

func start_combat():
	game.current_mode = game.GameMode.COMBAT
	game.combat_active = true

	game.combat_player_hp = game.combat_player_max_hp
	game.combat_player_stamina = game.combat_player_max_stamina
	game.combat_player_pos = Vector2(150, game.combat_arena_y)
	game.combat_player_vel = Vector2.ZERO
	game.combat_player_state = "idle"
	game.combat_player_state_timer = 0.0
	game.combat_combo_count = 0
	game.combat_combo_timer = 0.0
	game.combat_player_facing_right = true
	game.combat_iframe_active = false
	game.combat_player_y_offset = 0.0
	game.combat_player_y_vel = 0.0
	game.combat_player_grounded = true
	
	game.robot_hp = game.robot_max_hp
	game.robot_pos = Vector2(330, game.combat_arena_y)
	game.robot_state = "idle"
	game.robot_state_timer = 0.0
	game.robot_current_attack = ""
	game.robot_phase = 1
	game.robot_defeated = false
	game.robot_spark_timer = 0.0
	
	game.hit_effects.clear()
	game.slash_trails.clear()
	game.screen_shake = 0.0
	
	game.combat_hint = "Watch its movements!"
	game.combat_hint_timer = 3.0

func start_tunnel_fight():
	game.tunnel_fight_active = true
	game.current_mode = game.GameMode.COMBAT
	game.combat_active = true

	game.combat_player_hp = game.combat_player_max_hp
	game.combat_player_stamina = game.combat_player_max_stamina
	game.combat_player_pos = Vector2(100, game.combat_arena_y)
	game.combat_player_vel = Vector2.ZERO
	game.combat_player_state = "idle"
	game.combat_player_state_timer = 0.0
	game.combat_combo_count = 0
	game.combat_combo_timer = 0.0
	game.combat_player_facing_right = true
	game.combat_iframe_active = false
	game.combat_player_y_offset = 0.0
	game.combat_player_y_vel = 0.0
	game.combat_player_grounded = true
	game.slash_trails.clear()
	
	game.tunnel_robots = [
		{"pos": Vector2(280, game.combat_arena_y), "hp": 150, "max_hp": 150, "state": "idle", "state_timer": 0.5, "attack": "", "defeated": false},
		{"pos": Vector2(340, game.combat_arena_y - 20), "hp": 150, "max_hp": 150, "state": "idle", "state_timer": 1.2, "attack": "", "defeated": false},
		{"pos": Vector2(400, game.combat_arena_y + 10), "hp": 150, "max_hp": 150, "state": "idle", "state_timer": 1.8, "attack": "", "defeated": false}
	]
	
	game.robot_defeated = true
	game.hit_effects.clear()
	game.screen_shake = 0.0
	
	game.combat_hint = "Three robots block the tunnel!"
	game.combat_hint_timer = 3.0

# ===========================================
# TUNNEL ROBOT HELPERS
# ===========================================

func get_active_tunnel_robots() -> int:
	var count = 0
	for r in game.tunnel_robots:
		if not r.defeated:
			count += 1
	return count

func get_nearest_tunnel_robot() -> int:
	var best_idx = -1
	var best_dist = 999.0
	for i in range(game.tunnel_robots.size()):
		if game.tunnel_robots[i].defeated:
			continue
		var dist = abs(game.combat_player_pos.x - game.tunnel_robots[i].pos.x)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	return best_idx

func damage_nearest_tunnel_robot(damage: int):
	var idx = get_nearest_tunnel_robot()
	if idx >= 0:
		deal_damage_to_tunnel_robot(idx, damage)

func deal_damage_to_tunnel_robot(idx: int, damage: int):
	if idx < 0 or idx >= game.tunnel_robots.size():
		return

	if game.tunnel_robots[idx].defeated:
		return

	game.tunnel_robots[idx].hp -= damage
	game.add_hit_effect(game.tunnel_robots[idx].pos + Vector2(0, -30), str(damage), Color(1.0, 0.9, 0.3))
	game.screen_shake = 4.0
	game.hit_pause_timer = 0.04

	if game.tunnel_robots[idx].hp <= 0:
		game.tunnel_robots[idx].hp = 0
		game.tunnel_robots[idx].defeated = true
		game.add_hit_effect(game.tunnel_robots[idx].pos + Vector2(0, -40), "DEFEATED!", Color(0.3, 1.0, 0.5))
		game.screen_shake = 8.0

		# Check if all robots are defeated
		var all_defeated = true
		for robot in game.tunnel_robots:
			if not robot.defeated:
				all_defeated = false
				break

		if all_defeated:
			end_tunnel_fight_victory()

func end_tunnel_fight_victory():
	game.combat_active = false
	# Keep tunnel_fight_active = true so sewer background stays visible during dialogue
	# It will be set to false when the ending cutscene starts
	# Stay in COMBAT mode to keep tunnel background visible during dialogue
	# The "start_ending" dialogue command will transition to ENDING_CUTSCENE

	game.dialogue_queue = [
		{"speaker": "kaido", "text": "We made it through!"},
		{"speaker": "system", "text": "[ The tunnel opens into the resistance hideout. ]"},
		{"speaker": "grandmother", "text": "This is where we've been working in secret."},
		{"speaker": "grandmother", "text": "The others are already here. We're safe now."},
		{"speaker": "kaido", "text": "We did it! We saved Agricommune!"},
		{"speaker": "kaido", "text": "But this is just the beginning..."},
		{"speaker": "system", "text": "[ REGION COMPLETE: AGRICOMMUNE ]"},
		{"speaker": "start_ending", "text": ""},
	]
	game.next_dialogue()

# ===========================================
# GADGET EFFECTS IN COMBAT
# ===========================================

func use_combat_gadget():
	if game.equipped_gadget == "":
		game.combat_hint = "No gadget equipped!"
		game.combat_hint_timer = 1.0
		return
	
	game.gadget_use_timer = 1.0
	
	match game.equipped_gadget:
		"led_lamp":
			combat_flashlight_effect()
		"dimmer":
			combat_pulse_effect()
		_:
			game.combat_hint = "Gadget activated!"
			game.combat_hint_timer = 1.0

func combat_flashlight_effect():
	game.screen_shake = 3.0
	game.add_hit_effect(game.combat_player_pos + Vector2(0, -30), "FLASH!", Color(1.0, 1.0, 0.8))
	
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			if game.tunnel_robots[i].state in ["telegraph", "attack"]:
				game.tunnel_robots[i].state = "hit"
				game.tunnel_robots[i].state_timer = 0.8
				game.add_hit_effect(game.tunnel_robots[i].pos + Vector2(0, -30), "BLIND!", Color(1.0, 1.0, 0.6))
		game.combat_hint = "Light blinds them!"
	else:
		if game.robot_state in ["telegraph", "attacking"]:
			game.robot_state = "hit"
			game.robot_state_timer = 0.8
			game.counter_window_active = false
			game.add_hit_effect(game.robot_pos + Vector2(0, -30), "BLIND!", Color(1.0, 1.0, 0.6))
			game.combat_hint = "Light interrupts attack!"
		else:
			game.combat_hint = "Flash!"
	game.combat_hint_timer = 1.5
	game.hit_pause_timer = 0.05

func combat_pulse_effect():
	game.screen_shake = 5.0
	game.add_hit_effect(game.combat_player_pos + Vector2(0, -20), "PULSE!", Color(0.6, 0.3, 1.0))
	
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			game.tunnel_robots[i].state = "hit"
			game.tunnel_robots[i].state_timer = 1.2
			game.add_hit_effect(game.tunnel_robots[i].pos + Vector2(0, -30), "STUNNED!", Color(0.8, 0.4, 1.0))
		game.combat_hint = "All enemies stunned!"
	else:
		game.robot_state = "hit"
		game.robot_state_timer = 1.2
		game.counter_window_active = false
		game.add_hit_effect(game.robot_pos + Vector2(0, -30), "STUNNED!", Color(0.8, 0.4, 1.0))
		game.combat_hint = "Enemy stunned!"
	game.combat_hint_timer = 1.5
	game.hit_pause_timer = 0.08

# ===========================================
# COUNTER SYSTEM
# ===========================================

func execute_counter():
	game.counter_window_active = false
	game.combat_player_state = "countering"
	game.combat_player_state_timer = 0.3
	game.combat_iframe_active = true
	
	if game.tunnel_fight_active:
		var best_idx = -1
		var best_dist = 999.0
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			if game.tunnel_robots[i].state == "telegraph":
				var dist = abs(game.combat_player_pos.x - game.tunnel_robots[i].pos.x)
				if dist < best_dist:
					best_dist = dist
					best_idx = i
		
		if best_idx >= 0:
			game.tunnel_robots[best_idx].state = "hit"
			game.tunnel_robots[best_idx].state_timer = 0.6
			deal_damage_to_tunnel_robot(best_idx, 12)
			game.add_hit_effect(game.tunnel_robots[best_idx].pos + Vector2(0, -40), "COUNTER!", Color(0.3, 0.9, 1.0))
			game.combat_hint = "Follow up with [X]!"
			game.combat_hint_timer = 1.5
			game.screen_shake = 6.0
			game.hit_pause_timer = 0.08
	else:
		if game.robot_state == "telegraph" or game.robot_state == "attacking":
			game.robot_state = "hit"
			game.robot_state_timer = 0.5
			deal_damage_to_robot(10)
			game.add_hit_effect(game.robot_pos + Vector2(0, -40), "COUNTER!", Color(0.3, 0.9, 1.0))
			game.combat_hint = "Follow up with [X]!"
			game.combat_hint_timer = 1.5
			game.screen_shake = 6.0
			game.hit_pause_timer = 0.08
	
	game.last_counter_success = true

# ===========================================
# PLAYER ACTIONS
# ===========================================

func start_player_attack():
	game.combat_player_state = "attacking"
	game.combat_player_state_timer = 0.15  # Faster punch
	game.combat_combo_count += 1
	game.combat_combo_timer = 0.6
	
	var dir = 1 if game.combat_player_facing_right else -1
	game.add_slash_trail(dir)
	
	check_player_attack_hit()

func start_player_heavy_attack():
	game.combat_player_stamina -= 15
	game.combat_player_state = "heavy_attack"
	game.combat_player_state_timer = 0.35  # Faster heavy punch
	
	var dir = 1 if game.combat_player_facing_right else -1
	game.add_slash_trail(dir, true)
	
	check_player_heavy_hit()

func start_player_dodge():
	game.combat_player_stamina -= 15
	game.combat_player_state = "dodging"
	game.combat_player_state_timer = 0.25
	game.combat_iframe_active = true

	var dodge_dir = 1 if game.combat_player_facing_right else -1
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1

	game.combat_player_vel.x = dodge_dir * 400

func start_player_high_kick():
	game.combat_player_stamina -= 20
	game.combat_player_state = "high_kick"
	game.combat_player_state_timer = 0.30  # Faster high kick
	game.combat_combo_count += 1
	game.combat_combo_timer = 0.6

	var dir = 1 if game.combat_player_facing_right else -1
	add_slash_trail(dir, true)  # Use heavy trail effect for kick

func start_combat_jump():
	game.combat_player_state = "jumping"
	game.combat_player_grounded = false
	game.combat_player_y_vel = -350.0  # Initial upward velocity
	game.combat_iframe_active = true  # Brief i-frames during jump

func check_player_attack_hit():
	var attack_range = 50
	var attack_dir = 1 if game.combat_player_facing_right else -1
	var attack_center = game.combat_player_pos.x + attack_dir * 30
	var hit_something = false

	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			var dist = abs(attack_center - game.tunnel_robots[i].pos.x)
			if dist < attack_range:
				var damage = 8 + game.combat_combo_count * 2
				deal_damage_to_tunnel_robot(i, damage)
				game.tunnel_robots[i].state = "hit"
				game.tunnel_robots[i].state_timer = 0.2
				hit_something = true
	else:
		if not game.robot_defeated:
			var dist = abs(attack_center - game.robot_pos.x)
			if dist < attack_range:
				var damage = 8 + game.combat_combo_count * 2
				deal_damage_to_robot(damage)
				hit_something = true

	# Haptic feedback when punch lands
	if hit_something:
		Input.start_joy_vibration(0, 0.35, 0.25, 0.08)
	else:
		Input.start_joy_vibration(0, 0.1, 0.05, 0.03)

func check_player_heavy_hit():
	var attack_range = 65
	var attack_dir = 1 if game.combat_player_facing_right else -1
	var attack_center = game.combat_player_pos.x + attack_dir * 35
	var hit_something = false

	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			var dist = abs(attack_center - game.tunnel_robots[i].pos.x)
			if dist < attack_range:
				deal_damage_to_tunnel_robot(i, 20)
				game.tunnel_robots[i].state = "hit"
				game.tunnel_robots[i].state_timer = 0.4
				game.interrupt_tunnel_robot(i)
				hit_something = true
	else:
		if not game.robot_defeated:
			var dist = abs(attack_center - game.robot_pos.x)
			if dist < attack_range:
				deal_damage_to_robot(20)
				if game.robot_state == "telegraph":
					game.robot_state = "hit"
					game.robot_state_timer = 0.4
				hit_something = true

	# Haptic feedback for heavy hit
	if hit_something:
		Input.start_joy_vibration(0, 0.5, 0.4, 0.12)
	else:
		Input.start_joy_vibration(0, 0.15, 0.08, 0.04)

func check_player_high_kick_hit():
	var attack_range = 60
	var attack_dir = 1 if game.combat_player_facing_right else -1
	var attack_center = game.combat_player_pos.x + attack_dir * 40
	var hit_something = false

	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			var dist = abs(attack_center - game.tunnel_robots[i].pos.x)
			if dist < attack_range:
				var damage = 18 + game.combat_combo_count * 3
				deal_damage_to_tunnel_robot(i, damage)
				game.tunnel_robots[i].state = "hit"
				game.tunnel_robots[i].state_timer = 0.5
				game.interrupt_tunnel_robot(i)
				hit_something = true
	else:
		if not game.robot_defeated:
			var dist = abs(attack_center - game.robot_pos.x)
			if dist < attack_range:
				var damage = 18 + game.combat_combo_count * 3
				deal_damage_to_robot(damage)
				if game.robot_state == "telegraph":
					game.robot_state = "hit"
					game.robot_state_timer = 0.5
				hit_something = true

	# Haptic feedback for high kick
	if hit_something:
		Input.start_joy_vibration(0, 0.45, 0.35, 0.1)
	else:
		Input.start_joy_vibration(0, 0.12, 0.06, 0.04)

# ===========================================
# DAMAGE DEALING
# ===========================================

func deal_damage_to_robot(damage: int):
	game.robot_hp -= damage
	game.add_hit_effect(game.robot_pos + Vector2(0, -30), str(damage), Color(1.0, 0.9, 0.3))
	game.hit_flash_timer = 0.1
	game.hit_flash_target = "robot"
	game.screen_shake = 4.0
	game.hit_pause_timer = 0.04
	
	if game.robot_hp <= 0:
		game.robot_hp = 0
		game.robot_defeated = true
		game.robot_state = "defeated"
		game.add_hit_effect(game.robot_pos + Vector2(0, -50), "DEFEATED!", Color(0.3, 1.0, 0.5))
		game.screen_shake = 10.0
	else:
		game.update_robot_phase()

func deal_damage_to_player(damage: int):
	game.combat_player_hp -= damage
	game.add_hit_effect(game.combat_player_pos + Vector2(0, -30), str(damage), Color(1, 0.3, 0.3))
	game.hit_flash_timer = 0.12
	game.hit_flash_target = "player"
	game.screen_shake = 5.0
	game.hit_pause_timer = 0.05
	
	game.combat_player_state = "hit"
	game.combat_player_state_timer = 0.35
	game.combat_combo_count = 0
	
	var knockback_dir = -1 if game.combat_player_facing_right else 1
	game.combat_player_pos.x += knockback_dir * 20
	game.combat_player_pos.x = clamp(game.combat_player_pos.x, game.combat_arena_left, game.combat_arena_right)
	
	if game.combat_player_hp > 0 and game.combat_player_hp < 40:
		game.combat_hint = "Watch the telegraph!"
		game.combat_hint_timer = 2.0
	
	if game.combat_player_hp <= 0:
		game.combat_player_hp = 0
		player_defeated()

func player_defeated():
	game.combat_hint = "Try again!"
	game.combat_hint_timer = 2.0
	await game.get_tree().create_timer(2.0).timeout
	start_combat()

# ===========================================
# COMBAT END
# ===========================================

func end_combat_victory():
	game.combat_active = false
	
	if game.tunnel_fight_active:
		return
	
	game.current_mode = game.GameMode.EXPLORATION
	game.robot_defeated = true
	
	game.dialogue_queue = [
		{"speaker": "kaido", "text": "You did it! That was incredible!"},
		{"speaker": "grandmother", "text": "Are you hurt? That was too close."},
		{"speaker": "grandmother", "text": "They'll send more. We need to move faster."},
		{"speaker": "system", "text": "[ The robot sparks and collapses. ]"},
		{"speaker": "system", "text": "[ Components scatter across the ground. ]"},
		{"speaker": "kaido", "text": "We can salvage parts from this."},
		{"speaker": "set_stage", "text": "8"},
		{"speaker": "quest", "text": "Talk to Grandmother"},
	]
	game.next_dialogue()

# ===========================================
# COMBAT PROCESSING (Main Loop)
# ===========================================

func process_combat(delta):
	# Hit pause - brief freeze for impact feel
	if game.hit_pause_timer > 0:
		game.hit_pause_timer -= delta
		return
	
	# Update screen shake decay
	if game.screen_shake > 0:
		game.screen_shake -= delta * 30
		if game.screen_shake < 0:
			game.screen_shake = 0
	
	# Update hit flash
	if game.hit_flash_timer > 0:
		game.hit_flash_timer -= delta
	
	# Update slash trails
	for i in range(game.slash_trails.size() - 1, -1, -1):
		game.slash_trails[i].timer -= delta
		if game.slash_trails[i].timer <= 0:
			game.slash_trails.remove_at(i)
	
	# Update hit effects
	for i in range(game.hit_effects.size() - 1, -1, -1):
		game.hit_effects[i].timer -= delta
		game.hit_effects[i].pos.y -= delta * 40
		if game.hit_effects[i].timer <= 0:
			game.hit_effects.remove_at(i)
	
	# Update combat hint
	if game.combat_hint_timer > 0:
		game.combat_hint_timer -= delta
		if game.combat_hint_timer <= 0:
			game.combat_hint = ""
	
	# Update combo timer
	if game.combat_combo_count > 0:
		game.combat_combo_timer -= delta
		if game.combat_combo_timer <= 0:
			game.combat_combo_count = 0
	
	# Regenerate stamina when idle or moving
	if game.combat_player_state == "idle" or game.combat_player_state == "attacking":
		game.combat_player_stamina = min(game.combat_player_max_stamina, game.combat_player_stamina + 25 * delta)
	
	# Process player state
	process_player_combat_state(delta)
	
	# Process robot AI
	if game.tunnel_fight_active:
		process_tunnel_robots(delta)
	elif not game.robot_defeated:
		process_robot_ai(delta)
	else:
		game.robot_spark_timer += delta
		if game.robot_spark_timer > 2.0 and game.combat_active:
			end_combat_victory()
	
	# Process movement
	var can_move = game.combat_player_state == "idle" or game.combat_player_state == "attacking" or game.combat_player_state == "counter_followup"
	if can_move:
		process_combat_movement(delta)
	else:
		game.combat_player_vel.x *= 0.85
	
	# Apply velocity
	game.combat_player_pos.x += game.combat_player_vel.x * delta
	game.combat_player_pos.x = clamp(game.combat_player_pos.x, game.combat_arena_left, game.combat_arena_right)
	
	# Update player facing
	if game.combat_player_state == "idle":
		if game.tunnel_fight_active:
			var idx = get_nearest_tunnel_robot()
			if idx >= 0:
				game.combat_player_facing_right = game.combat_player_pos.x < game.tunnel_robots[idx].pos.x
		else:
			game.combat_player_facing_right = game.combat_player_pos.x < game.robot_pos.x

# ===========================================
# PLAYER STATE PROCESSING
# ===========================================

func process_player_combat_state(delta):
	game.combat_player_state_timer -= delta

	# Handle jumping physics
	if game.combat_player_state == "jumping" or not game.combat_player_grounded:
		game.combat_player_y_vel += 900.0 * delta  # Gravity
		game.combat_player_y_offset += game.combat_player_y_vel * delta

		# I-frames only during rising part of jump
		game.combat_iframe_active = game.combat_player_y_vel < 0

		# Landing
		if game.combat_player_y_offset >= 0:
			game.combat_player_y_offset = 0.0
			game.combat_player_y_vel = 0.0
			game.combat_player_grounded = true
			game.combat_iframe_active = false
			if game.combat_player_state == "jumping":
				game.combat_player_state = "idle"

	match game.combat_player_state:
		"attacking":
			if game.combat_player_state_timer <= 0:
				check_player_attack_hit()
				game.combat_player_state = "idle"
				game.last_counter_success = false
		"heavy_attack":
			if game.combat_player_state_timer <= 0:
				check_player_heavy_hit()
				game.combat_player_state = "idle"
		"high_kick":
			# Hit check mid-animation
			if game.combat_player_state_timer <= 0.25 and game.combat_player_state_timer > 0.20:
				check_player_high_kick_hit()
			if game.combat_player_state_timer <= 0:
				game.combat_player_state = "idle"
		"dodging":
			game.combat_iframe_active = game.combat_player_state_timer > 0.08
			if game.combat_player_state_timer <= 0:
				game.combat_player_state = "idle"
				game.combat_iframe_active = false
		"countering":
			game.combat_iframe_active = true
			if game.combat_player_state_timer <= 0:
				game.combat_player_state = "counter_followup"
				game.combat_player_state_timer = 0.8
				game.combat_iframe_active = false
		"counter_followup":
			if game.combat_player_state_timer <= 0:
				game.combat_player_state = "idle"
				game.last_counter_success = false
		"hit":
			if game.combat_player_state_timer <= 0:
				game.combat_player_state = "idle"

func process_combat_movement(delta):
	var input_x = game.get_input_horizontal()
	var target_speed = input_x * 220
	var accel = 2000.0 if input_x != 0 else 1500.0

	# Track if player is walking (for animation)
	game.combat_player_is_walking = (input_x != 0 and game.combat_player_state == "idle")

	# Metal tunnel floor haptics (reduced)
	if input_x != 0:
		game.footstep_timer += delta
		if game.footstep_timer >= 0.18:
			game.footstep_timer = 0.0
			var foot_var = randf_range(0.9, 1.1)
			Input.start_joy_vibration(0, 0.15 * foot_var, 0.12 * foot_var, 0.02)
	else:
		game.footstep_timer = 0.0
	
	if input_x != 0:
		if abs(game.combat_player_vel.x) < abs(target_speed):
			game.combat_player_vel.x = move_toward(game.combat_player_vel.x, target_speed, accel * delta)
		else:
			game.combat_player_vel.x = target_speed
	else:
		game.combat_player_vel.x = move_toward(game.combat_player_vel.x, 0, accel * delta)
	
	var new_x = game.combat_player_pos.x + game.combat_player_vel.x * delta
	new_x = clamp(new_x, game.combat_arena_left, game.combat_arena_right)
	
	var player_width = 25.0
	var robot_width = 20.0
	
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			var robot_x = game.tunnel_robots[i].pos.x
			var min_dist = player_width + robot_width
			if abs(new_x - robot_x) < min_dist:
				if new_x < robot_x:
					new_x = robot_x - min_dist
				else:
					new_x = robot_x + min_dist
				game.combat_player_vel.x = 0
	else:
		if not game.robot_defeated:
			var min_dist = player_width + robot_width
			if abs(new_x - game.robot_pos.x) < min_dist:
				if new_x < game.robot_pos.x:
					new_x = game.robot_pos.x - min_dist
				else:
					new_x = game.robot_pos.x + min_dist
				game.combat_player_vel.x = 0
	
	game.combat_player_pos.x = clamp(new_x, game.combat_arena_left, game.combat_arena_right)
	apply_robot_push()

func apply_robot_push():
	var player_width = 25.0
	var robot_width = 20.0
	var min_dist = player_width + robot_width
	
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			if game.tunnel_robots[i].defeated:
				continue
			var robot_x = game.tunnel_robots[i].pos.x
			var dist = abs(game.combat_player_pos.x - robot_x)
			if dist < min_dist:
				var push = (min_dist - dist) + 1
				if game.combat_player_pos.x < robot_x:
					game.combat_player_pos.x -= push
				else:
					game.combat_player_pos.x += push
	else:
		if not game.robot_defeated:
			var dist = abs(game.combat_player_pos.x - game.robot_pos.x)
			if dist < min_dist:
				var push = (min_dist - dist) + 1
				if game.combat_player_pos.x < game.robot_pos.x:
					game.combat_player_pos.x -= push
				else:
					game.combat_player_pos.x += push
	
	game.combat_player_pos.x = clamp(game.combat_player_pos.x, game.combat_arena_left, game.combat_arena_right)

# ===========================================
# TUNNEL ROBOT PROCESSING
# ===========================================

func process_tunnel_robots(delta):
	for i in range(game.tunnel_robots.size()):
		var r = game.tunnel_robots[i]
		if r.defeated:
			continue
		
		r.state_timer -= delta
		
		match r.state:
			"idle":
				if r.state_timer <= 0:
					var dist = abs(game.combat_player_pos.x - r.pos.x)
					if dist < 55:
						r.state = "telegraph"
						r.state_timer = 0.6
						r.attack = "swing"
					else:
						r.state = "approach"
						r.state_timer = 0.6
			"approach":
				var dir = 1 if game.combat_player_pos.x > r.pos.x else -1
				var move_speed = 100
				var new_x = r.pos.x + dir * move_speed * delta
				
				var blocked = false
				for j in range(game.tunnel_robots.size()):
					if i == j or game.tunnel_robots[j].defeated:
						continue
					var other_x = game.tunnel_robots[j].pos.x
					var min_dist = 28
					if abs(new_x - other_x) < min_dist:
						if (dir > 0 and other_x > r.pos.x) or (dir < 0 and other_x < r.pos.x):
							blocked = true
							break
				
				if not blocked:
					r.pos.x = new_x
				r.pos.x = clamp(r.pos.x, game.combat_arena_left + 40, game.combat_arena_right - 10)
				
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = 0.15
			"telegraph":
				game.counter_window_active = true
				if r.state_timer <= 0:
					r.state = "attack"
					r.state_timer = 0.25
					game.counter_window_active = false
			"attack":
				game.counter_window_active = false
				if r.state_timer <= 0:
					var dist = abs(game.combat_player_pos.x - r.pos.x)
					if dist < 55 and not game.combat_iframe_active and game.combat_player_state != "dodging":
						deal_damage_to_player(10)
					r.state = "recover"
					r.state_timer = 0.5
			"recover":
				var dir_away = -1 if game.combat_player_pos.x > r.pos.x else 1
				r.pos.x += dir_away * 30 * delta
				r.pos.x = clamp(r.pos.x, game.combat_arena_left + 40, game.combat_arena_right - 10)
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = randf_range(0.1, 0.4)
			"hit":
				game.counter_window_active = false
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = 0.15
	
	resolve_tunnel_robot_collisions()

func resolve_tunnel_robot_collisions():
	var min_dist = 25.0
	for i in range(game.tunnel_robots.size()):
		if game.tunnel_robots[i].defeated:
			continue
		for j in range(i + 1, game.tunnel_robots.size()):
			if game.tunnel_robots[j].defeated:
				continue
			var dist = abs(game.tunnel_robots[i].pos.x - game.tunnel_robots[j].pos.x)
			if dist < min_dist:
				var push = (min_dist - dist) / 2.0 + 0.5
				if game.tunnel_robots[i].pos.x < game.tunnel_robots[j].pos.x:
					game.tunnel_robots[i].pos.x -= push
					game.tunnel_robots[j].pos.x += push
				else:
					game.tunnel_robots[i].pos.x += push
					game.tunnel_robots[j].pos.x -= push
				game.tunnel_robots[i].pos.x = clamp(game.tunnel_robots[i].pos.x, game.combat_arena_left + 25, game.combat_arena_right - 15)
				game.tunnel_robots[j].pos.x = clamp(game.tunnel_robots[j].pos.x, game.combat_arena_left + 25, game.combat_arena_right - 15)

func interrupt_tunnel_robot(idx: int):
	if game.tunnel_robots[idx].state in ["telegraph", "attack"]:
		game.tunnel_robots[idx].state = "hit"
		game.tunnel_robots[idx].state_timer = 0.4

# ===========================================
# ROBOT AI (Single Boss)
# ===========================================

func process_robot_ai(delta):
	game.robot_state_timer -= delta
	
	if game.counter_indicator_timer > 0:
		game.counter_indicator_timer -= delta
	
	var dist_to_player = abs(game.robot_pos.x - game.combat_player_pos.x)
	var ideal_distance = 55
	
	match game.robot_state:
		"idle":
			game.counter_window_active = false
			if dist_to_player > ideal_distance + 25:
				var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
				game.robot_pos.x += dir * 70 * delta
			elif dist_to_player < ideal_distance - 15:
				var dir = -1 if game.combat_player_pos.x > game.robot_pos.x else 1
				game.robot_pos.x += dir * 40 * delta
			
			game.robot_pos.x = clamp(game.robot_pos.x, game.combat_arena_left + 20, game.combat_arena_right - 20)
			
			if game.robot_state_timer <= 0:
				choose_robot_attack()
		"telegraph":
			game.counter_window_active = true
			game.counter_indicator_timer = game.robot_state_timer
			
			if game.robot_current_attack in ["baton_swing", "lunge_grab", "quick_jab"]:
				var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
				game.robot_pos.x += dir * 30 * delta
				game.robot_pos.x = clamp(game.robot_pos.x, game.combat_arena_left + 20, game.combat_arena_right - 20)
			
			if game.robot_state_timer <= 0:
				execute_robot_attack()
		"attacking":
			game.counter_window_active = false
			if game.robot_current_attack == "combo_strike":
				if (game.robot_state_timer <= 0.28 and game.robot_state_timer > 0.26) or (game.robot_state_timer <= 0.12 and game.robot_state_timer > 0.10):
					check_robot_attack_hit()
			else:
				if game.robot_state_timer <= 0.08 and game.robot_state_timer > 0:
					check_robot_attack_hit()
			if game.robot_state_timer <= 0:
				game.robot_state = "recovering"
				game.robot_state_timer = get_recovery_time()
		"recovering":
			game.counter_window_active = false
			var dir = -1 if game.combat_player_pos.x > game.robot_pos.x else 1
			game.robot_pos.x += dir * 35 * delta
			game.robot_pos.x = clamp(game.robot_pos.x, game.combat_arena_left + 20, game.combat_arena_right - 20)
			
			if game.robot_state_timer <= 0:
				game.robot_state = "idle"
				game.robot_state_timer = randf_range(0.4, 0.9)
		"hit":
			game.counter_window_active = false
			if game.robot_state_timer <= 0:
				game.robot_state = "idle"
				game.robot_state_timer = 0.25

func choose_robot_attack():
	var attacks = ["quick_jab", "quick_jab", "baton_swing"]
	
	if game.robot_phase >= 2:
		attacks.append("quick_jab")
		attacks.append("baton_swing")
		attacks.append("lunge_grab")
	if game.robot_phase >= 3:
		attacks.append("combo_strike")
		attacks.append("scan_sweep")
	
	game.robot_current_attack = attacks[randi() % attacks.size()]
	game.robot_state = "telegraph"
	game.robot_state_timer = get_telegraph_time()
	
	if game.robot_hp > 240:
		match game.robot_current_attack:
			"quick_jab":
				game.combat_hint = "△ to Counter!"
				game.combat_hint_timer = 0.6
			"baton_swing":
				game.combat_hint = "△ Counter or [O] Evade!"
				game.combat_hint_timer = 1.0
			"lunge_grab":
				game.combat_hint = "Heavy attack - △ Counter!"
				game.combat_hint_timer = 1.2

func get_telegraph_time() -> float:
	match game.robot_current_attack:
		"quick_jab": return 0.35
		"baton_swing": return 0.9
		"lunge_grab": return 1.4
		"combo_strike": return 0.5
		"scan_sweep": return 0.8
	return 0.8

func get_recovery_time() -> float:
	match game.robot_current_attack:
		"quick_jab": return 0.4
		"baton_swing": return 0.8
		"lunge_grab": return 1.2
		"combo_strike": return 0.5
		"scan_sweep": return 0.4
	return 0.6

func execute_robot_attack():
	game.robot_state = "attacking"
	
	match game.robot_current_attack:
		"quick_jab":
			game.robot_state_timer = 0.15
			var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
			game.robot_pos.x += dir * 15
		"baton_swing":
			game.robot_state_timer = 0.25
			var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
			game.robot_pos.x += dir * 25
		"lunge_grab":
			game.robot_state_timer = 0.35
			var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
			game.robot_pos.x += dir * 50
		"combo_strike":
			game.robot_state_timer = 0.4
			var dir = 1 if game.combat_player_pos.x > game.robot_pos.x else -1
			game.robot_pos.x += dir * 20
		"scan_sweep":
			game.robot_state_timer = 0.3
	
	game.robot_pos.x = clamp(game.robot_pos.x, game.combat_arena_left + 20, game.combat_arena_right - 20)

func check_robot_attack_hit():
	if game.combat_iframe_active:
		game.combat_hint = "Good dodge! Now strike!"
		game.combat_hint_timer = 1.0
		return
	
	var dist = abs(game.combat_player_pos.x - game.robot_pos.x)
	var hit_range = 50
	
	match game.robot_current_attack:
		"quick_jab": hit_range = 45
		"baton_swing": hit_range = 55
		"lunge_grab": hit_range = 60
		"combo_strike": hit_range = 50
		"scan_sweep": hit_range = 65
	
	if dist < hit_range:
		deal_damage_to_player(get_attack_damage())

func get_attack_damage() -> int:
	match game.robot_current_attack:
		"quick_jab": return 8
		"baton_swing": return 18
		"lunge_grab": return 25
		"combo_strike": return 12
		"scan_sweep": return 10
	return 10

func update_robot_phase():
	var hp_percent = float(game.robot_hp) / float(game.robot_max_hp)
	if hp_percent <= 0.3 and game.robot_phase < 3:
		game.robot_phase = 3
		game.combat_hint = "It's getting desperate!"
		game.combat_hint_timer = 2.0
	elif hp_percent <= 0.6 and game.robot_phase < 2:
		game.robot_phase = 2
		game.combat_hint = "Watch out - it's changing tactics!"
		game.combat_hint_timer = 2.0

func add_slash_trail(dir: int, is_heavy: bool = false):
	var base_x = game.combat_player_pos.x + dir * 20
	var base_y = game.combat_player_pos.y - 25
	
	var trail = {
		"start": Vector2(base_x - dir * 15, base_y - 20),
		"mid": Vector2(base_x + dir * 25, base_y),
		"end": Vector2(base_x - dir * 10, base_y + 25),
		"timer": 0.15 if is_heavy else 0.1,
		"max_timer": 0.15 if is_heavy else 0.1,
		"color": Color(1.0, 0.95, 0.7, 0.9) if is_heavy else Color(1.0, 1.0, 1.0, 0.8),
		"width": 6.0 if is_heavy else 4.0,
		"is_heavy": is_heavy
	}
	game.slash_trails.append(trail)

# ===========================================
# COMBAT DRAWING
# ===========================================

func draw_combat_arena():
	var shake_offset = Vector2(randf_range(-game.screen_shake, game.screen_shake), randf_range(-game.screen_shake, game.screen_shake))

	game.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	if game.tunnel_fight_active:
		# Dark sewer tunnel environment
		draw_sewer_background()
	else:
		# Normal combat - irrigation area
		game.draw_rect(Rect2(0, 0, 480, 320), Color(0.35, 0.55, 0.38))

		# Ground
		var ground_y = 240
		game.draw_rect(Rect2(0, ground_y - 20, 480, 100), Color(0.58, 0.42, 0.32))
		game.draw_rect(Rect2(0, ground_y - 25, 480, 8), Color(0.65, 0.5, 0.38))

		# Arena boundaries
		game.draw_rect(Rect2(50, 150, 8, 100), Color(0.5, 0.38, 0.28))
		game.draw_rect(Rect2(422, 150, 8, 100), Color(0.5, 0.38, 0.28))

		# Irrigation pipes
		game.draw_rect(Rect2(0, 180, 50, 6), Color(0.5, 0.5, 0.55))
		game.draw_rect(Rect2(430, 180, 50, 6), Color(0.5, 0.5, 0.55))
	
	# Draw player
	draw_combat_player(game.combat_player_pos + shake_offset)
	
	# Draw robots
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			var r = game.tunnel_robots[i]
			if not r.defeated:
				draw_tunnel_robot(r, shake_offset, i)
			else:
				draw_defeated_robot(r.pos + shake_offset)
	else:
		if not game.robot_defeated:
			draw_combat_robot(game.robot_pos + shake_offset)
		else:
			draw_defeated_robot(game.robot_pos + shake_offset)
	
	# Health bars
	draw_combat_health_bar(game.combat_player_pos + shake_offset + Vector2(-30, -55), game.combat_player_hp, game.combat_player_max_hp, Color(0.3, 0.85, 0.4), "YOU")
	
	if game.tunnel_fight_active:
		for i in range(game.tunnel_robots.size()):
			var r = game.tunnel_robots[i]
			if not r.defeated:
				draw_combat_health_bar(r.pos + shake_offset + Vector2(-25, -55), r.hp, r.max_hp, Color(0.9, 0.25, 0.25), "")
	else:
		if not game.robot_defeated:
			draw_combat_health_bar(game.robot_pos + shake_offset + Vector2(-30, -65), game.robot_hp, game.robot_max_hp, Color(0.9, 0.25, 0.25), "EN-07")
	
	# Stamina bar
	game.draw_stamina_bar(game.combat_player_pos + shake_offset + Vector2(-30, -45))
	
	# Counter indicator for main robot
	if game.counter_window_active and not game.tunnel_fight_active and not game.robot_defeated:
		var flash = sin(game.continuous_timer * 20) * 0.3 + 0.7
		var counter_color = Color(0.3, 0.9, 1.0, flash)
		var tri_pos = game.robot_pos + shake_offset + Vector2(0, -75)
		game.draw_string(ThemeDB.fallback_font, tri_pos + Vector2(-8, 0), "△", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, counter_color)
		var ring_size = 30 + sin(game.continuous_timer * 15) * 5
		game.draw_arc(game.robot_pos + shake_offset + Vector2(0, -20), ring_size, 0, TAU, 32, counter_color, 2.0)
	
	# Hit effects
	for effect in game.hit_effects:
		var alpha = effect.timer / 0.8
		var eff_color = effect.color
		eff_color.a = alpha
		game.draw_string(ThemeDB.fallback_font, effect.pos + shake_offset, effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, eff_color)
	
	# Slash trails
	for trail in game.slash_trails:
		var alpha = trail.timer / trail.max_timer
		var trail_color = trail.color
		trail_color.a = alpha * 0.9
		var width = trail.width * alpha
		game.draw_line(trail.start + shake_offset, trail.mid + shake_offset, trail_color, width)
		game.draw_line(trail.mid + shake_offset, trail.end + shake_offset, trail_color, width)
		var glow_color = Color(1, 1, 1, alpha * 0.6)
		game.draw_line(trail.start + shake_offset, trail.mid + shake_offset, glow_color, width * 0.5)
		game.draw_line(trail.mid + shake_offset, trail.end + shake_offset, glow_color, width * 0.5)
		if trail.is_heavy and alpha > 0.5:
			var spark_pos = trail.mid + shake_offset
			for j in range(3):
				var angle = randf() * TAU
				var spark_end = spark_pos + Vector2(cos(angle), sin(angle)) * 15 * alpha
				game.draw_line(spark_pos, spark_end, Color(1, 0.9, 0.5, alpha), 2)
	
	# Combat hint
	if game.combat_hint != "":
		var hint_alpha = min(1.0, game.combat_hint_timer)
		game.draw_rect(Rect2(90, 280, 300, 30), Color(0.1, 0.1, 0.15, 0.85 * hint_alpha))
		game.draw_rect(Rect2(90, 280, 300, 30), Color(0.4, 0.9, 0.85, hint_alpha), false, 2)
		game.draw_string(ThemeDB.fallback_font, Vector2(110, 302), game.combat_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.95, 0.9, hint_alpha))
	
	# Controls - show keyboard/controller options
	var controls_text = ""
	if game.is_using_controller():
		controls_text = "[X] Strike  [□] Heavy  [L1] Kick  [○] Evade  [D-Up] Jump  [△] Counter"
	else:
		controls_text = "[Z] Strike  [X] Heavy  [V] Kick  [C] Evade  [Space] Jump  [Y] Counter"
	game.draw_string(ThemeDB.fallback_font, Vector2(10, 315), controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
	
	# Gadget indicator
	draw_combat_gadget_indicator()
	
	# Combo counter
	if game.combat_combo_count > 0:
		var combo_color = Color(1.0, 0.9, 0.3) if game.combat_combo_count < 5 else Color(1.0, 0.5, 0.2)
		if game.combat_combo_count >= 10:
			combo_color = Color(1.0, 0.3, 0.8)
		game.draw_string(ThemeDB.fallback_font, Vector2(400, 30), str(game.combat_combo_count) + " HIT!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, combo_color)

	# Draw sewer darkness overlay if in tunnel fight
	if game.tunnel_fight_active:
		draw_sewer_darkness_overlay()

	# Draw dialogue box after combat ends (for victory dialogue)
	if game.in_dialogue and not game.combat_active:
		game.draw_dialogue_box()

func draw_sewer_background():
	# Dark sewer/tunnel environment
	var wall_dark = Color(0.12, 0.1, 0.08)
	var wall_mid = Color(0.18, 0.15, 0.12)
	var wall_light = Color(0.22, 0.18, 0.14)
	var floor_dark = Color(0.15, 0.12, 0.1)
	var floor_wet = Color(0.1, 0.12, 0.15)
	var pipe_color = Color(0.3, 0.28, 0.25)
	var rust_color = Color(0.4, 0.25, 0.15)

	# Dark background
	game.draw_rect(Rect2(0, 0, 480, 320), wall_dark)

	# Brick/stone wall pattern
	for row in range(0, 200, 24):
		var offset = 16 if (row / 24) % 2 == 0 else 0
		for col in range(-16 + offset, 500, 32):
			var brick_shade = wall_mid if ((col + row) / 32) % 3 == 0 else wall_light
			game.draw_rect(Rect2(col, row, 30, 22), brick_shade)
			game.draw_rect(Rect2(col, row, 30, 2), wall_dark)
			game.draw_rect(Rect2(col, row, 2, 22), wall_dark)

	# Ceiling pipes
	game.draw_rect(Rect2(0, 30, 480, 8), pipe_color)
	game.draw_rect(Rect2(0, 32, 480, 4), Color(0.35, 0.32, 0.28))
	for x in range(0, 480, 60):
		game.draw_rect(Rect2(x, 20, 6, 20), pipe_color)
		game.draw_rect(Rect2(x + 2, 35, 4, 8), rust_color)

	# Ground - wet concrete floor
	var ground_y = 220
	game.draw_rect(Rect2(0, ground_y, 480, 100), floor_dark)
	game.draw_rect(Rect2(0, ground_y, 480, 4), Color(0.2, 0.17, 0.14))

	# Wet patches on floor (reflective)
	var time_offset = game.continuous_timer * 0.5
	for i in range(5):
		var wx = 50 + i * 90 + sin(time_offset + i) * 10
		var shimmer = 0.03 + sin(game.continuous_timer * 2 + i * 1.5) * 0.02
		game.draw_rect(Rect2(wx, ground_y + 10, 40, 60), Color(0.15, 0.18, 0.22, 0.6 + shimmer))

	# Side walls/tunnel boundaries
	game.draw_rect(Rect2(0, 100, 50, 220), wall_dark)
	game.draw_rect(Rect2(430, 100, 50, 220), wall_dark)

	# Grates on walls
	for y in range(120, 220, 40):
		game.draw_rect(Rect2(10, y, 30, 25), Color(0.08, 0.08, 0.08))
		for gy in range(y + 3, y + 23, 5):
			game.draw_rect(Rect2(12, gy, 26, 2), Color(0.25, 0.22, 0.2))

	# Dripping water effect
	var drip_x = 100 + int(game.continuous_timer * 0.3) % 4 * 100
	var drip_y = int(game.continuous_timer * 80) % 180
	if drip_y < 170:
		game.draw_circle(Vector2(drip_x, 50 + drip_y), 2, Color(0.3, 0.4, 0.5, 0.6))

	# Emergency lights (dim red)
	var light_pulse = sin(game.continuous_timer * 2) * 0.2 + 0.3
	game.draw_circle(Vector2(60, 60), 8, Color(0.6, 0.1, 0.1, light_pulse))
	game.draw_circle(Vector2(420, 60), 8, Color(0.6, 0.1, 0.1, light_pulse))

func draw_sewer_darkness_overlay():
	# Draw darkness with flashlight cone lighting the area around player
	var cell_size = 12
	var player_pos = game.combat_player_pos

	# Flashlight properties
	var flashlight_on = game.equipped_gadget == "led_lamp" and game.flashlight_on
	var base_visibility = 0.25  # Base visibility even without flashlight
	var flashlight_radius = 120.0 if flashlight_on else 50.0
	var flashlight_inner = 60.0 if flashlight_on else 25.0

	# Draw shadow grid
	for y in range(0, 320, cell_size):
		for x in range(0, 480, cell_size):
			var cell_center = Vector2(x + cell_size / 2, y + cell_size / 2)
			var dist_to_player = cell_center.distance_to(player_pos)

			# Calculate visibility based on distance from player
			var visibility = base_visibility

			# Player's natural visibility radius
			if dist_to_player < flashlight_inner:
				visibility = 1.0
			elif dist_to_player < flashlight_radius:
				var t = (dist_to_player - flashlight_inner) / (flashlight_radius - flashlight_inner)
				visibility = lerp(1.0, base_visibility, t * t)

			# Robot eyes glow - give some visibility around active robots
			for r in game.tunnel_robots:
				if not r.defeated:
					var dist_to_robot = cell_center.distance_to(r.pos)
					if dist_to_robot < 40:
						var robot_light = 1.0 - (dist_to_robot / 40.0)
						visibility = max(visibility, robot_light * 0.5)

			# Emergency lights at edges
			var dist_to_left_light = cell_center.distance_to(Vector2(60, 60))
			var dist_to_right_light = cell_center.distance_to(Vector2(420, 60))
			if dist_to_left_light < 50:
				visibility = max(visibility, 0.4 * (1.0 - dist_to_left_light / 50.0))
			if dist_to_right_light < 50:
				visibility = max(visibility, 0.4 * (1.0 - dist_to_right_light / 50.0))

			# Draw shadow
			var shadow_alpha = (1.0 - visibility) * 0.85
			if shadow_alpha > 0.05:
				game.draw_rect(Rect2(x, y, cell_size, cell_size), Color(0.02, 0.02, 0.05, shadow_alpha))

	# Flashlight beam effect when on
	if flashlight_on:
		var beam_alpha = 0.15 + sin(game.continuous_timer * 3) * 0.05
		var facing_dir = 1 if game.combat_player_facing_right else -1
		var beam_start = player_pos + Vector2(0, -20)
		var beam_end = beam_start + Vector2(facing_dir * 100, 0)
		var beam_width = 40.0

		# Draw cone approximation with triangles
		var beam_pts = PackedVector2Array([
			beam_start,
			beam_end + Vector2(0, -beam_width),
			beam_end + Vector2(0, beam_width)
		])
		game.draw_colored_polygon(beam_pts, Color(1.0, 0.95, 0.8, beam_alpha * 0.3))

func draw_combat_gadget_indicator():
	var gx = 410
	var gy = 5
	game.draw_rect(Rect2(gx, gy, 65, 50), Color(0.1, 0.1, 0.15, 0.8))
	game.draw_rect(Rect2(gx, gy, 65, 50), Color(0.4, 0.5, 0.6, 0.6), false, 2)
	
	if game.equipped_gadget == "":
		game.draw_string(ThemeDB.fallback_font, Vector2(gx + 8, gy + 30), "No Gadget", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 0.5, 0.5))
	else:
		var data = game.gadget_data.get(game.equipped_gadget, {})
		var name_text = data.get("name", game.equipped_gadget)
		if name_text.length() > 8:
			name_text = name_text.substr(0, 7) + "."
		var icon_color = Color.WHITE
		if game.gadget_use_timer > 0:
			icon_color = Color(0.5, 0.5, 0.5)
		game.draw_gadget_mini_icon(game.equipped_gadget, gx + 33, gy + 22, icon_color)
		game.draw_string(ThemeDB.fallback_font, Vector2(gx + 5, gy + 42), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.9, 0.85))
		if game.gadget_use_timer > 0:
			var cooldown_pct = game.gadget_use_timer / 1.0
			game.draw_rect(Rect2(gx + 2, gy + 2, 61 * cooldown_pct, 46), Color(0.2, 0.2, 0.3, 0.6))
		game.draw_string(ThemeDB.fallback_font, Vector2(gx + 45, gy + 12), "R1", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.6, 0.6))

func draw_combat_player(pos: Vector2):
	var flash_mod = Color(1, 1, 1, 1)
	if game.hit_flash_timer > 0 and game.hit_flash_target == "player":
		flash_mod = Color(2, 1.5, 1.5, 1)

	# Apply jump offset to position
	var draw_pos = pos
	draw_pos.y += game.combat_player_y_offset

	var idle_bob = 0.0
	if game.combat_player_state == "idle" and game.combat_player_grounded:
		idle_bob = sin(game.continuous_timer * 3) * 2

	# Use new animation system if available
	if game.player_anim_loaded:
		var tex: Texture2D = null
		var frame = int(game.continuous_timer * 10) % 6  # Smoother animation timing
		var fight_frame = int(game.continuous_timer * 8) % 8  # Fight stance uses 8 frames
		var scale_factor = 2.0  # Larger for combat view
		var flip = not game.combat_player_facing_right

		# Determine which sprite to use based on state and facing
		match game.combat_player_state:
			"idle":
				# Check if player is walking while in idle state
				if game.combat_player_is_walking:
					# Walking animation with correct direction
					var walk_frames = game.tex_player_walk_east if game.combat_player_facing_right else game.tex_player_walk_west
					if walk_frames.size() > frame:
						tex = walk_frames[frame]
				else:
					# Use fight stance idle in combat instead of regular idle
					var fight_idle_frames = game.tex_player_fight_idle_east if game.combat_player_facing_right else game.tex_player_fight_idle_west
					if fight_idle_frames.size() > fight_frame:
						tex = fight_idle_frames[fight_frame]
					elif game.combat_player_facing_right:
						tex = game.tex_player_idle_east
					else:
						tex = game.tex_player_idle_west
			"attacking", "heavy_attack":
				# Use attack animation frames
				var attack_frames = game.tex_player_attack_east if game.combat_player_facing_right else game.tex_player_attack_west
				if attack_frames.size() > 0:
					var attack_frame = int((0.25 - game.combat_player_state_timer) * 24) % attack_frames.size()
					attack_frame = clamp(attack_frame, 0, attack_frames.size() - 1)
					tex = attack_frames[attack_frame]
				else:
					# Fallback to walk frames if no attack animation
					var walk_frames = game.tex_player_walk_east if game.combat_player_facing_right else game.tex_player_walk_west
					if walk_frames.size() > frame:
						tex = walk_frames[frame]
			"high_kick":
				# Use high kick animation frames (7 frames)
				var kick_frames = game.tex_player_high_kick_east if game.combat_player_facing_right else game.tex_player_high_kick_west
				if kick_frames.size() > 0:
					var kick_progress = 1.0 - (game.combat_player_state_timer / 0.45)
					var kick_frame = int(kick_progress * kick_frames.size())
					kick_frame = clamp(kick_frame, 0, kick_frames.size() - 1)
					tex = kick_frames[kick_frame]
				else:
					# Fallback to attack frames
					var attack_frames = game.tex_player_attack_east if game.combat_player_facing_right else game.tex_player_attack_west
					if attack_frames.size() > 0:
						tex = attack_frames[attack_frames.size() - 1]
			"jumping":
				# Use running jump animation frames (8 frames)
				var jump_frames = game.tex_player_jump_east if game.combat_player_facing_right else game.tex_player_jump_west
				if jump_frames.size() > 0:
					# Progress through jump animation based on vertical position
					var jump_progress = abs(game.combat_player_y_offset) / 70.0  # Max jump height ~70 pixels
					var jump_frame = int(jump_progress * jump_frames.size())
					if game.combat_player_y_vel > 0:  # Falling
						jump_frame = jump_frames.size() - 1 - int((1.0 - jump_progress) * 3)
					jump_frame = clamp(jump_frame, 0, jump_frames.size() - 1)
					tex = jump_frames[jump_frame]
				else:
					# Fallback
					tex = game.tex_player_idle_east if game.combat_player_facing_right else game.tex_player_idle_west
			"dodging":
				# Draw ghost trails
				var walk_frames = game.tex_player_walk_east if game.combat_player_facing_right else game.tex_player_walk_west
				for i in range(3):
					var ghost_alpha = 0.3 - i * 0.1
					var roll_dir = 1 if game.combat_player_facing_right else -1
					var ghost_x = draw_pos.x - roll_dir * i * 25
					if walk_frames.size() > 0:
						var ghost_tex = walk_frames[frame % walk_frames.size()]
						var gw = ghost_tex.get_width() * scale_factor
						var gh = ghost_tex.get_height() * scale_factor
						var ghost_dest = Rect2(ghost_x - gw/2, draw_pos.y - gh + 10, gw, gh)
						game.draw_texture_rect(ghost_tex, ghost_dest, false, Color(1, 1, 1, ghost_alpha))
				if walk_frames.size() > frame:
					tex = walk_frames[frame]
			"hit":
				tex = game.tex_player_idle_east if game.combat_player_facing_right else game.tex_player_idle_west
				var lean_dir = -1 if game.combat_player_facing_right else 1
				draw_pos.x += lean_dir * 8
				idle_bob = -5
			_:
				# Default to fight stance idle
				var fight_idle_frames = game.tex_player_fight_idle_east if game.combat_player_facing_right else game.tex_player_fight_idle_west
				if fight_idle_frames.size() > fight_frame:
					tex = fight_idle_frames[fight_frame]
				elif game.combat_player_facing_right:
					tex = game.tex_player_idle_east
				else:
					tex = game.tex_player_idle_west

		if tex:
			var w = tex.get_width() * scale_factor
			var h = tex.get_height() * scale_factor
			var dest = Rect2(draw_pos.x - w/2, draw_pos.y - h + 10 + idle_bob, w, h)
			game.draw_texture_rect(tex, dest, false, flash_mod)

			# Attack effect overlay
			if game.combat_player_state == "attacking" or game.combat_player_state == "heavy_attack":
				var arm_dir = 1 if game.combat_player_facing_right else -1
				var swing_alpha = 0.6 if game.combat_player_state == "attacking" else 0.9
				var swing_size = 25 if game.combat_player_state == "attacking" else 35
				var arc_x = draw_pos.x + arm_dir * 30
				game.draw_arc(Vector2(arc_x, draw_pos.y - 20), swing_size, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.7, swing_alpha), 4)
				if game.combat_player_state_timer < 0.1:
					game.draw_circle(Vector2(arc_x + arm_dir * 15, draw_pos.y - 15), 12, Color(1, 1, 0.8, 0.6))
			# High kick effect overlay
			elif game.combat_player_state == "high_kick":
				var kick_dir = 1 if game.combat_player_facing_right else -1
				var kick_progress = 1.0 - (game.combat_player_state_timer / 0.45)
				if kick_progress > 0.3 and kick_progress < 0.7:
					var arc_x = draw_pos.x + kick_dir * 35
					game.draw_arc(Vector2(arc_x, draw_pos.y - 35), 30, deg_to_rad(-90), deg_to_rad(30), 12, Color(1, 0.6, 0.3, 0.8), 5)
			return
	
	# Fallback to old spritesheet system
	if not game.tex_player:
		return
	
	var row = 0
	var frame = game.player_frame % 6
	var flip = not game.combat_player_facing_right
	var scale_factor = 1.5
	
	match game.combat_player_state:
		"idle":
			row = 0
			frame = int(game.continuous_timer * 2) % 3
		"attacking":
			row = 3
			frame = 2 + int((0.2 - game.combat_player_state_timer) * 15) % 3
		"heavy_attack":
			row = 3
			if game.combat_player_state_timer > 0.3:
				frame = 0
			else:
				frame = 4 + int((0.3 - game.combat_player_state_timer) * 10) % 2
		"dodging":
			for i in range(3):
				var ghost_alpha = 0.3 - i * 0.1
				var roll_dir = 1 if game.combat_player_facing_right else -1
				var ghost_x = pos.x - roll_dir * i * 25
				var ghost_src = Rect2(frame * 48, 3 * 48, 48, 48)
				var ghost_dest = Rect2(ghost_x - 36, pos.y - 60, 72, 72)
				if flip:
					ghost_dest.position.x += 72
					ghost_dest.size.x = -72
				game.draw_texture_rect_region(game.tex_player, ghost_dest, ghost_src, Color(1, 1, 1, ghost_alpha))
			row = 3
			frame = 3
		"hit":
			row = 0
			var lean_dir = -1 if game.combat_player_facing_right else 1
			pos.x += lean_dir * 8
			idle_bob = -5
	
	var src = Rect2(frame * 48, row * 48, 48, 48)
	var sprite_size = 48 * scale_factor
	var dest = Rect2(pos.x - sprite_size/2, pos.y - sprite_size + 10 + idle_bob, sprite_size, sprite_size)
	if flip:
		dest.position.x += sprite_size
		dest.size.x = -sprite_size
	game.draw_texture_rect_region(game.tex_player, dest, src, flash_mod)
	
	# Attack effect overlay
	if game.combat_player_state == "attacking" or game.combat_player_state == "heavy_attack":
		var arm_dir = 1 if game.combat_player_facing_right else -1
		var swing_alpha = 0.6 if game.combat_player_state == "attacking" else 0.9
		var swing_size = 25 if game.combat_player_state == "attacking" else 35
		var arc_x = pos.x + arm_dir * 30
		game.draw_arc(Vector2(arc_x, pos.y - 20), swing_size, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.7, swing_alpha), 4)
		if game.combat_player_state_timer < 0.1:
			game.draw_circle(Vector2(arc_x + arm_dir * 15, pos.y - 15), 12, Color(1, 1, 0.8, 0.6))

func draw_combat_robot(pos: Vector2):
	# Use heavy robot animations if loaded, otherwise fallback procedural
	if game.heavy_robot_anim_loaded:
		draw_heavy_combat_robot(pos)
	else:
		draw_fallback_robot(pos)

func draw_heavy_combat_robot(pos: Vector2):
	# Draw the heavy robot with proper animations based on state
	var flash_mod = Color(1, 1, 1, 1)
	var is_flashing = game.hit_flash_timer > 0 and game.hit_flash_target == "robot"
	if is_flashing:
		var flash_intensity = game.hit_flash_timer / 0.15
		flash_mod = Color(1 + flash_intensity, 1 + flash_intensity * 0.8, 1 + flash_intensity * 0.8, 1)

	# Determine facing direction (robot faces player)
	var facing_left = pos.x > game.combat_player_pos.x
	var tex: Texture2D = null
	var scale_factor = 4.5

	# Handle hit shake
	if game.robot_state == "hit":
		pos.x += randf_range(-4, 4)
		pos.y += randf_range(-3, 3)

	match game.robot_state:
		"idle", "recovering":
			# Use idle/walk animation while idle
			var walk_frames = game.tex_heavy_robot_walk_west if facing_left else game.tex_heavy_robot_walk_east
			if walk_frames.size() > 0:
				var frame = int(game.continuous_timer * 4) % walk_frames.size()
				tex = walk_frames[frame]
			else:
				tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"telegraph":
			# Show idle during telegraph (no extra indicators)
			tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"attacking":
			# Use jab animation for quick attacks, fireball for special
			var use_fireball = game.robot_current_attack in ["baton_swing", "lunge_grab", "scan_sweep"]
			if use_fireball:
				var fireball_frames = game.tex_heavy_robot_fireball_west if facing_left else game.tex_heavy_robot_fireball_east
				if fireball_frames.size() > 0:
					var prog = 1.0 - (game.robot_state_timer / 0.4)
					var frame = int(prog * fireball_frames.size()) % fireball_frames.size()
					tex = fireball_frames[frame]
			else:
				var jab_frames = game.tex_heavy_robot_jab_west if facing_left else game.tex_heavy_robot_jab_east
				if jab_frames.size() > 0:
					var prog = 1.0 - (game.robot_state_timer / 0.25)
					var frame = int(prog * jab_frames.size()) % jab_frames.size()
					tex = jab_frames[frame]

			# Fallback to idle if animation not found
			if tex == null:
				tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"hit":
			# Show idle frame while taking damage
			tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

	# Draw the texture
	if tex:
		var w = tex.get_width()
		var h = tex.get_height()
		var dest = Rect2(pos.x - (w * scale_factor)/2, pos.y - (h * scale_factor) + 15, w * scale_factor, h * scale_factor)
		game.draw_texture_rect(tex, dest, false, flash_mod)
	else:
		# Fallback if no texture
		draw_fallback_robot(pos)

	# Flash effect on hit
	if is_flashing:
		var burst_size = 25 * (game.hit_flash_timer / 0.15)
		game.draw_circle(pos + Vector2(0, -30), burst_size, Color(1, 1, 0.8, game.hit_flash_timer * 3))

func draw_tunnel_robot(robot: Dictionary, shake_offset: Vector2, index: int):
	var pos = robot.pos + shake_offset

	# Use heavy robot animations if loaded, otherwise fallback procedural
	if game.heavy_robot_anim_loaded:
		draw_heavy_tunnel_robot(robot, pos, index)
	else:
		# Fallback: smaller procedural robot for tunnel fight
		var tints = [Color(0.9, 0.3, 0.3), Color(0.3, 0.3, 0.9), Color(0.3, 0.9, 0.3)]
		var body_color = tints[index % 3]
		game.draw_rect(Rect2(pos.x - 15, pos.y - 45, 30, 40), body_color)
		game.draw_rect(Rect2(pos.x - 12, pos.y - 55, 24, 15), body_color)
		game.draw_rect(Rect2(pos.x - 8, pos.y - 52, 16, 6), Color(0.2, 0.2, 0.2))
		# Telegraph state - animation only, no extra indicators

func draw_heavy_tunnel_robot(robot: Dictionary, pos: Vector2, index: int):
	# Draw heavy robot for tunnel fight with proper animations
	var flash_mod = Color(1, 1, 1, 1)
	var facing_left = pos.x > game.combat_player_pos.x
	var tex: Texture2D = null
	var scale_factor = 3.0

	# Handle hit shake
	if robot.state == "hit":
		flash_mod = Color(2.0, 1.5, 1.5, 1)
		pos.x += randf_range(-3, 3)
		pos.y += randf_range(-2, 2)

	match robot.state:
		"idle", "recover", "approach":
			# Use walking animation
			var walk_frames = game.tex_heavy_robot_walk_west if facing_left else game.tex_heavy_robot_walk_east
			if walk_frames.size() > 0:
				var frame = int(game.continuous_timer * 5 + index) % walk_frames.size()
				tex = walk_frames[frame]
			else:
				tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"telegraph":
			# Show idle during telegraph (no extra indicators)
			tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"attack":
			# Use jab animation
			var jab_frames = game.tex_heavy_robot_jab_west if facing_left else game.tex_heavy_robot_jab_east
			if jab_frames.size() > 0:
				var frame = int(game.continuous_timer * 10) % jab_frames.size()
				tex = jab_frames[frame]
			else:
				tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

		"hit":
			tex = game.tex_heavy_robot_idle_west if facing_left else game.tex_heavy_robot_idle_east

	# Draw the texture
	if tex:
		var w = tex.get_width()
		var h = tex.get_height()
		var dest = Rect2(pos.x - (w * scale_factor)/2, pos.y - (h * scale_factor) + 12, w * scale_factor, h * scale_factor)
		game.draw_texture_rect(tex, dest, false, flash_mod)

func draw_robot_attack_effects(pos: Vector2):
	var accent = Color(1.0, 0.25, 0.25)
	match game.robot_current_attack:
		"quick_jab":
			var punch_dir = 1 if pos.x < game.combat_player_pos.x else -1
			var prog = 1.0 - (game.robot_state_timer / 0.15)
			var punch_extend = prog * 30
			game.draw_rect(Rect2(pos.x + punch_dir * 10, pos.y - 22, punch_extend * punch_dir, 8), accent)
		"baton_swing":
			var swing_prog = 1.0 - (game.robot_state_timer / 0.25)
			var arm_angle = -90 + swing_prog * 180
			var arm_x = pos.x + cos(deg_to_rad(arm_angle)) * 25
			var arm_y = pos.y - 25 + sin(deg_to_rad(arm_angle)) * 25
			game.draw_line(Vector2(pos.x, pos.y - 25), Vector2(arm_x, arm_y), accent, 6)
		"lunge_grab":
			var grab_dir = -1 if pos.x > game.combat_player_pos.x else 1
			game.draw_rect(Rect2(pos.x + grab_dir * 10, pos.y - 20, 25 * grab_dir, 12), accent)
		"combo_strike":
			var prog = 1.0 - (game.robot_state_timer / 0.4)
			var punch_dir = 1 if pos.x < game.combat_player_pos.x else -1
			if prog < 0.5:
				var extend = (prog * 2) * 25
				game.draw_rect(Rect2(pos.x + punch_dir * 8, pos.y - 25, extend * punch_dir, 7), accent)
			else:
				var extend = ((prog - 0.5) * 2) * 25
				game.draw_rect(Rect2(pos.x + punch_dir * 8, pos.y - 18, extend * punch_dir, 7), accent)
		"scan_sweep":
			var sweep_prog = game.robot_state_timer / 0.3
			var sweep_x = game.combat_arena_left + (game.combat_arena_right - game.combat_arena_left) * (1.0 - sweep_prog)
			game.draw_line(Vector2(pos.x, pos.y - 22), Vector2(sweep_x, game.combat_arena_y), Color(1.0, 0.2, 0.1, 0.8), 3)

func draw_fallback_robot(pos: Vector2):
	# Simple procedural robot when sprite not loaded
	var body_color = Color(0.3, 0.5, 0.4)  # Greenish metallic
	var accent_color = Color(0.8, 0.2, 0.2)  # Red accents
	var metal_color = Color(0.5, 0.5, 0.55)

	# Flash on hit
	if game.hit_flash_timer > 0 and game.hit_flash_target == "robot":
		body_color = Color(1.0, 0.8, 0.8)
		accent_color = Color(1.0, 0.6, 0.6)

	# Shake on hit
	if game.robot_state == "hit":
		pos.x += randf_range(-4, 4)
		pos.y += randf_range(-3, 3)

	# Body (larger than player - about 60x80 pixels)
	game.draw_rect(Rect2(pos.x - 25, pos.y - 70, 50, 60), body_color)
	# Head
	game.draw_rect(Rect2(pos.x - 20, pos.y - 90, 40, 25), body_color)
	# Eye visor
	game.draw_rect(Rect2(pos.x - 15, pos.y - 85, 30, 10), accent_color)
	# Arms
	game.draw_rect(Rect2(pos.x - 35, pos.y - 65, 12, 40), metal_color)
	game.draw_rect(Rect2(pos.x + 23, pos.y - 65, 12, 40), metal_color)
	# Legs
	game.draw_rect(Rect2(pos.x - 18, pos.y - 15, 14, 25), metal_color)
	game.draw_rect(Rect2(pos.x + 4, pos.y - 15, 14, 25), metal_color)

	# Telegraph state - animation only, no extra indicators

func draw_defeated_robot(pos: Vector2):
	# Use heavy robot sprite if available (lying flat)
	if game.heavy_robot_anim_loaded and game.tex_heavy_robot_idle_west:
		var tex = game.tex_heavy_robot_idle_west
		var w = tex.get_width()
		var h = tex.get_height()
		var scale = 3.0
		# Draw lying flat (squashed vertically)
		var dest = Rect2(pos.x - (w * scale)/2 - 10, pos.y - 15, w * scale, h * scale * 0.3)
		game.draw_texture_rect(tex, dest, false, Color(0.5, 0.5, 0.5, 1))
	else:
		# Fallback defeated robot
		var metal_color = Color(0.35, 0.35, 0.4, 0.7)
		game.draw_rect(Rect2(pos.x - 30, pos.y - 10, 60, 20), metal_color)

	# Sparks
	if fmod(game.robot_spark_timer, 0.5) < 0.25:
		var spark_x = pos.x + randf_range(-20, 20)
		var spark_y = pos.y + randf_range(-15, 5)
		game.draw_circle(Vector2(spark_x, spark_y), 3, Color(1.0, 0.9, 0.3))
		game.draw_circle(Vector2(spark_x + 5, spark_y - 3), 2, Color(1.0, 0.7, 0.2))

	# Scattered components
	game.draw_circle(Vector2(pos.x - 30, pos.y + 5), 4, Color(0.4, 0.4, 0.45))
	game.draw_rect(Rect2(pos.x + 35, pos.y + 2, 8, 4), Color(0.5, 0.3, 0.2))
	game.draw_circle(Vector2(pos.x - 10, pos.y + 8), 3, Color(0.7, 0.2, 0.2))

func draw_combat_health_bar(pos: Vector2, current_hp: int, max_hp: int, color: Color, label: String):
	var bar_width = 60
	var bar_height = 8
	
	game.draw_string(ThemeDB.fallback_font, pos + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.9))
	game.draw_rect(Rect2(pos.x - 1, pos.y, bar_width + 2, bar_height + 2), Color(0.0, 0.0, 0.0))
	game.draw_rect(Rect2(pos.x, pos.y + 1, bar_width, bar_height), Color(0.2, 0.2, 0.2))
	
	var fill_width = int((float(current_hp) / float(max_hp)) * bar_width)
	if fill_width > 0:
		game.draw_rect(Rect2(pos.x, pos.y + 1, fill_width, bar_height), color)
	
	var hp_text = str(current_hp) + "/" + str(max_hp)
	game.draw_string(ThemeDB.fallback_font, pos + Vector2(bar_width + 5, bar_height), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.8, 0.8))
