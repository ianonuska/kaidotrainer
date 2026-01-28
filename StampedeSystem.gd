extends RefCounted
# StampedeSystem.gd - Stampede minigame logic
# Usage: var stampede = StampedeSystem.new(self) in _ready()

var game  # Reference to main game script

func _init(game_ref):
	game = game_ref

# ===========================================
# STAMPEDE INITIALIZATION
# ===========================================

func start_stampede():
	game.current_mode = game.GameMode.STAMPEDE
	game.stampede_active = true
	game.stampede_player_pos = Vector2(380, game.stampede_ground_y)
	game.stampede_player_vel = Vector2.ZERO
	game.stampede_player_y_vel = 0.0
	game.stampede_player_grounded = true
	game.stampede_player_hp = game.stampede_player_max_hp
	game.stampede_player_state = "idle"
	game.stampede_player_state_timer = 0.0
	game.stampede_player_facing_right = false
	game.stampede_wave = 1
	game.stampede_animals.clear()
	game.stampede_hit_effects.clear()
	game.stampede_spawn_timer = 1.5
	game.stampede_wave_timer = 0.0
	game.stampede_complete = false
	game.stampede_score = 0
	game.screen_shake = 0.0
	
	game.dialogue_queue = [
		{"speaker": "kaido", "text": "The farm animals are panicking!"},
		{"speaker": "kaido", "text": "Punch them to scare them off! Use arrows to move."},
		{"speaker": "kaido", "text": "[X]=Jump  [_]=Punch  [O]=Dodge  △=Counter"},
	]
	game.next_dialogue()

# ===========================================
# INPUT HANDLING
# ===========================================

func handle_stampede_input(event):
	if game.stampede_player_state == "hit":
		return
	
	if game.stampede_player_state == "dodging":
		return
	
	# Gadget cycling - R1 / Tab
	var cycle_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_TAB)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		cycle_pressed = true
	if cycle_pressed:
		game.cycle_gadget()
		return
	
	# Use gadget - R2 / Q
	var gadget_use_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_Q)
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.5:
		gadget_use_pressed = true
	if gadget_use_pressed and game.gadget_use_timer <= 0:
		use_stampede_gadget()
		return
	
	# Counter - Triangle / Y (during enemy telegraph)
	var counter_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_Y)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		counter_pressed = true
	if counter_pressed:
		for animal in game.stampede_animals:
			if animal.defeated:
				continue
			var dist = abs(game.stampede_player_pos.x - animal.pos.x)
			if dist < 65 and animal.get("telegraph", false):
				execute_stampede_counter(animal)
				return
	
	# Dodge - Circle / C
	var dodge_pressed = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_C)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		dodge_pressed = true
	if dodge_pressed and game.stampede_player_state == "idle":
		start_stampede_dodge()
		return
	
	# Attack - Square / X key
	var attack_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_X)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		attack_pressed = true
	if attack_pressed and game.stampede_player_state == "idle":
		start_stampede_attack()
		return
	
	# Jump - Cross / Z or Space / D-pad Up / Joystick Up
	var jump_pressed = (event is InputEventKey and event.pressed and (event.keycode == KEY_Z or event.keycode == KEY_SPACE))
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		jump_pressed = true
	# D-pad up
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_UP:
		jump_pressed = true
	# Joystick up (left stick Y axis negative = up)
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y and event.axis_value < -0.5:
		jump_pressed = true
	if jump_pressed and game.stampede_player_grounded:
		start_stampede_jump()

# ===========================================
# PLAYER ACTIONS
# ===========================================

func start_stampede_dodge():
	game.stampede_player_state = "dodging"
	game.stampede_player_state_timer = 0.3
	var dodge_dir = -1 if game.stampede_player_facing_right else 1
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1
	game.stampede_player_vel.x = dodge_dir * 350

func execute_stampede_counter(animal: Dictionary):
	animal.telegraph = false
	animal.hit_flash = 0.2
	game.stampede_player_state = "attacking"
	game.stampede_player_state_timer = 0.2
	
	var damage = 2
	animal.hp -= damage
	game.stampede_score += 15
	
	game.stampede_hit_effects.append({
		"pos": animal.pos + Vector2(0, -20),
		"text": "COUNTER!",
		"timer": 0.6,
		"color": Color(0.3, 0.9, 1.0)
	})
	
	game.screen_shake = 4.0
	
	if animal.hp <= 0:
		animal.defeated = true
		game.stampede_score += 25
		game.stampede_hit_effects.append({
			"pos": animal.pos + Vector2(0, -35),
			"text": "KO!",
			"timer": 0.8,
			"color": Color(0.3, 1.0, 0.5)
		})

func use_stampede_gadget():
	if game.equipped_gadget == "":
		return
	
	game.gadget_use_timer = 1.5
	
	match game.equipped_gadget:
		"led_lamp":
			stampede_flashlight_effect()
		"dimmer":
			stampede_pulse_effect()
		_:
			game.stampede_hit_effects.append({
				"pos": game.stampede_player_pos + Vector2(0, -30),
				"text": "GADGET!",
				"timer": 0.5,
				"color": Color(0.5, 0.95, 0.88)
			})

func stampede_flashlight_effect():
	game.screen_shake = 3.0
	game.stampede_hit_effects.append({
		"pos": game.stampede_player_pos + Vector2(0, -30),
		"text": "FLASH!",
		"timer": 0.6,
		"color": Color(1.0, 1.0, 0.8)
	})
	
	for animal in game.stampede_animals:
		if animal.defeated:
			continue
		var dist = abs(game.stampede_player_pos.x - animal.pos.x)
		if dist < 120:
			animal.vel.x *= 0.3
			animal.hit_flash = 0.3
			if animal.get("telegraph", false):
				animal.telegraph = false

func stampede_pulse_effect():
	game.screen_shake = 5.0
	game.stampede_hit_effects.append({
		"pos": game.stampede_player_pos + Vector2(0, -30),
		"text": "PULSE!",
		"timer": 0.6,
		"color": Color(0.6, 0.3, 1.0)
	})
	
	for animal in game.stampede_animals:
		if animal.defeated:
			continue
		var dist = abs(game.stampede_player_pos.x - animal.pos.x)
		if dist < 100:
			animal.hp -= 1
			animal.hit_flash = 0.4
			animal.vel.x = 0
			game.stampede_score += 5
			if animal.hp <= 0:
				animal.defeated = true
				game.stampede_score += 25

func start_stampede_attack():
	game.stampede_player_state = "attacking"
	game.stampede_player_state_timer = 0.25  # Faster punch
	game.stampede_attack_hit_done = false  # Reset hit flag - hit check happens when punch lands

func check_stampede_attack_hit():
	# Called when punch lands (mid-animation)
	var attack_range = 60
	var attack_dir = 1 if game.stampede_player_facing_right else -1
	var attack_center = game.stampede_player_pos.x + attack_dir * 20
	var hit_something = false

	for animal in game.stampede_animals:
		if animal.defeated:
			continue
		var dist = abs(attack_center - animal.pos.x)
		if dist < attack_range:
			hit_stampede_animal(animal)
			hit_something = true

	# Haptic feedback when punch lands
	if hit_something:
		Input.start_joy_vibration(0, 0.3, 0.25, 0.08)
	else:
		Input.start_joy_vibration(0, 0.1, 0.05, 0.03)  # Light feedback even on miss

func start_stampede_jump():
	game.stampede_player_state = "jumping"
	game.stampede_player_grounded = false
	game.stampede_player_jump_start_y = game.stampede_player_pos.y  # Store where we jumped from
	game.stampede_player_y_vel = -360  # Jump height
	# Jump push-off haptic (reduced)
	Input.start_joy_vibration(0, 0.15, 0.1, 0.04)

func hit_stampede_animal(animal: Dictionary):
	var damage = 1
	if animal.type == "robot" or animal.type == "heavy_robot":
		damage = 1
	
	animal.hp -= damage
	animal.hit_flash = 0.15
	game.stampede_score += 10
	
	# Hit haptic (reduced)
	Input.start_joy_vibration(0, 0.25, 0.18, 0.06)
	
	game.stampede_hit_effects.append({
		"pos": animal.pos + Vector2(0, -20),
		"text": str(damage),
		"timer": 0.5,
		"color": Color(1.0, 0.9, 0.3)
	})
	
	game.screen_shake = 2.0
	
	if animal.hp <= 0:
		animal.defeated = true
		game.stampede_score += 25
		game.screen_shake = 4.0
		# Defeat haptic (reduced)
		Input.start_joy_vibration(0, 0.35, 0.3, 0.1)
		
		var ko_text = "KO!"
		if animal.type == "robot":
			ko_text = "SCRAPPED!"
			game.stampede_score += 15
		elif animal.type == "heavy_robot":
			ko_text = "DESTROYED!"
			game.stampede_score += 30
		
		game.stampede_hit_effects.append({
			"pos": animal.pos + Vector2(0, -35),
			"text": ko_text,
			"timer": 0.8,
			"color": Color(0.3, 1.0, 0.5)
		})

func bounce_off_animal(animal: Dictionary):
	# Get the animal's head height for proper positioning
	var hitbox = get_animal_hitbox(animal)
	var animal_top = game.stampede_ground_y - hitbox.height

	# Player bounces up from the animal's head
	game.stampede_player_y_vel = -260  # Bounce upward
	game.stampede_player_pos.y = animal_top - 5  # Position feet just above animal head
	game.stampede_player_state = "jumping"
	game.stampede_player_grounded = false
	game.stampede_bounce_cooldown = 0.2  # Cooldown to prevent double-bounce

	# Damage the animal
	var damage = 1
	animal.hp -= damage
	animal.hit_flash = 0.15
	game.stampede_score += 15

	# Subtle bounce haptic
	Input.start_joy_vibration(0, 0.15, 0.1, 0.05)
	game.screen_shake = 1.5

	game.stampede_hit_effects.append({
		"pos": animal.pos + Vector2(0, -hitbox.height - 5),
		"text": "STOMP!",
		"timer": 0.6,
		"color": Color(0.9, 0.7, 0.3)
	})

	if animal.hp <= 0:
		animal.defeated = true
		game.stampede_score += 25
		game.screen_shake = 4.0
		Input.start_joy_vibration(0, 0.35, 0.3, 0.1)

		var ko_text = "SQUASHED!"
		if animal.type == "robot":
			ko_text = "CRUSHED!"
			game.stampede_score += 15
		elif animal.type == "heavy_robot":
			ko_text = "FLATTENED!"
			game.stampede_score += 30

		game.stampede_hit_effects.append({
			"pos": animal.pos + Vector2(0, -hitbox.height - 15),
			"text": ko_text,
			"timer": 0.8,
			"color": Color(0.3, 1.0, 0.5)
		})

# ===========================================
# PROCESS STAMPEDE
# ===========================================

func process_stampede(delta):
	if game.stampede_complete:
		return
	
	# Update screen shake
	if game.screen_shake > 0:
		game.screen_shake -= delta * 20
		if game.screen_shake < 0:
			game.screen_shake = 0
	
	# Update hit effects
	for i in range(game.stampede_hit_effects.size() - 1, -1, -1):
		game.stampede_hit_effects[i].timer -= delta
		game.stampede_hit_effects[i].pos.y -= delta * 30
		if game.stampede_hit_effects[i].timer <= 0:
			game.stampede_hit_effects.remove_at(i)
	
	# Update player state timer
	if game.stampede_player_state_timer > 0:
		game.stampede_player_state_timer -= delta
		# Check for punch landing mid-animation (at 0.15 remaining = 0.10s into animation)
		if game.stampede_player_state == "attacking" and game.stampede_player_state_timer <= 0.15 and not game.stampede_attack_hit_done:
			check_stampede_attack_hit()
			game.stampede_attack_hit_done = true
		if game.stampede_player_state_timer <= 0:
			if game.stampede_player_state != "jumping":
				game.stampede_player_state = "idle"

	# Update bounce cooldown
	if game.stampede_bounce_cooldown > 0:
		game.stampede_bounce_cooldown -= delta

	# Process jumping
	if not game.stampede_player_grounded:
		game.stampede_player_y_vel += 850 * delta  # Moderate gravity
		game.stampede_player_pos.y += game.stampede_player_y_vel * delta

		# Land at ground level
		if game.stampede_player_pos.y >= game.stampede_ground_y:
			game.stampede_player_pos.y = game.stampede_ground_y
			game.stampede_player_grounded = true
			game.stampede_player_y_vel = 0
			# Landing impact haptic
			Input.start_joy_vibration(0, 0.2, 0.15, 0.05)
			if game.stampede_player_state == "jumping":
				game.stampede_player_state = "idle"
	
	# Update animals
	update_stampede_animals(delta)
	
	# Spawn new animals
	game.stampede_spawn_timer -= delta
	if game.stampede_spawn_timer <= 0:
		spawn_stampede_animal()
		var spawn_delay = 2.0 - (game.stampede_wave * 0.15)
		spawn_delay = max(0.6, spawn_delay)
		game.stampede_spawn_timer = spawn_delay
	
	# Wave progression
	game.stampede_wave_timer += delta
	if game.stampede_wave_timer >= 15.0:
		game.stampede_wave += 1
		game.stampede_wave_timer = 0.0
		game.stampede_hit_effects.append({
			"pos": Vector2(240, 100),
			"text": "WAVE " + str(game.stampede_wave),
			"timer": 1.5,
			"color": Color(1.0, 0.8, 0.3)
		})
	
	# Process movement
	process_stampede_movement(delta)
	
	# Check defeat
	if game.stampede_player_hp <= 0:
		end_stampede(false)

func process_stampede_movement(delta):
	var move_speed = 160.0
	var move_dir = 0.0

	# Keyboard input
	if Input.is_action_pressed("move_left"):
		move_dir = -1.0
	elif Input.is_action_pressed("move_right"):
		move_dir = 1.0

	# Controller joystick input (overrides keyboard if significant)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(joy_x) > 0.3:  # Deadzone
		move_dir = sign(joy_x)

	# Update facing direction
	if move_dir < 0:
		game.stampede_player_facing_right = false
	elif move_dir > 0:
		game.stampede_player_facing_right = true

	# Running haptics
	if move_dir != 0 and game.stampede_player_grounded:
		game.footstep_timer += delta
		if game.footstep_timer >= 0.1:
			game.footstep_timer = 0.0
			Input.start_joy_vibration(0, 0.08, 0.04, 0.02)
	else:
		game.footstep_timer = 0.0

	# Track if player is walking (for animation)
	game.stampede_player_is_walking = (move_dir != 0 and game.stampede_player_grounded and game.stampede_player_state == "idle")

	# Apply movement directly when in moveable states
	if game.stampede_player_state in ["idle", "jumping"]:
		game.stampede_player_pos.x += move_dir * move_speed * delta

	# Clamp position to arena bounds
	game.stampede_player_pos.x = clamp(game.stampede_player_pos.x, game.stampede_arena_left, game.stampede_arena_right)

func get_animal_hitbox(animal: Dictionary) -> Dictionary:
	# Returns hitbox dimensions based on animal type
	# width = horizontal collision width, height = how tall the animal is (for stomp detection)
	match animal.type:
		"chicken":
			return {"width": 20, "height": 18}
		"cow":
			return {"width": 28, "height": 28}
		"bull":
			return {"width": 30, "height": 30}
		"robot":
			return {"width": 24, "height": 32}
		"heavy_robot":
			return {"width": 32, "height": 38}
		_:
			return {"width": 24, "height": 24}

func update_stampede_animals(delta):
	for animal in game.stampede_animals:
		if animal.defeated:
			continue

		# Update hit flash
		if animal.hit_flash > 0:
			animal.hit_flash -= delta

		# Move animal
		animal.pos.x += animal.vel.x * delta

		# Remove if off screen
		if animal.pos.x > 500 or animal.pos.x < -50:
			animal.defeated = true
			continue

		# Skip collision if dodging
		if game.stampede_player_state == "dodging":
			continue

		# Get animal hitbox
		var hitbox = get_animal_hitbox(animal)
		var animal_half_width = hitbox.width / 2.0
		var animal_top = game.stampede_ground_y - hitbox.height  # Y position of animal's head

		# Player collision box (feet position)
		var player_x = game.stampede_player_pos.x
		var player_y = game.stampede_player_pos.y  # Player's feet Y position
		var player_half_width = 12.0

		# Check horizontal overlap
		var x_overlap = abs(player_x - animal.pos.x) < (player_half_width + animal_half_width)

		if not x_overlap:
			continue

		# Check for stomp - player must be:
		# 1. In the air (not grounded)
		# 2. Falling downward
		# 3. Feet are at or just above the animal's head
		# 4. Horizontally centered on the animal (tighter check for stomp)
		var player_falling = not game.stampede_player_grounded and game.stampede_player_y_vel > 0
		var stomp_x_range = abs(player_x - animal.pos.x) < animal_half_width  # Must be on top, not side
		var feet_at_head = player_y >= animal_top - 8 and player_y <= animal_top + 12

		if player_falling and stomp_x_range and feet_at_head and game.stampede_bounce_cooldown <= 0:
			bounce_off_animal(animal)
			continue

		# If player is high enough in the air, skip ground collision
		if not game.stampede_player_grounded and player_y < animal_top:
			continue

		# Ground collision - player gets hit if overlapping at ground level
		# Only hurt if player is in FRONT of the animal (animals move left to right)
		# If player is behind the animal (player_x < animal.pos.x - threshold), no damage
		var behind_threshold = animal_half_width * 0.6  # Safe zone behind animal
		var player_behind_animal = player_x < animal.pos.x - behind_threshold

		if (game.stampede_player_grounded or player_y >= game.stampede_ground_y - 10) and not player_behind_animal:
			# Player hit by animal from the front
			game.stampede_player_hp -= 1
			game.stampede_player_state = "hit"
			game.stampede_player_state_timer = 0.4
			game.screen_shake = 6.0
			Input.start_joy_vibration(0, 0.5, 0.4, 0.15)

			var knockback = 80 if animal.pos.x < player_x else -80
			game.stampede_player_pos.x += knockback
			game.stampede_player_pos.x = clamp(game.stampede_player_pos.x, game.stampede_arena_left, game.stampede_arena_right)

			game.stampede_hit_effects.append({
				"pos": game.stampede_player_pos + Vector2(0, -30),
				"text": "HIT!",
				"timer": 0.5,
				"color": Color(1, 0.3, 0.3)
			})

			animal.defeated = true
			break

func spawn_stampede_animal():
	var animal_type = "chicken"
	var hp = 1
	var speed = 200  # Base speed doubled

	# Wave-based spawning (all speeds increased significantly)
	var roll = randf()
	if game.stampede_wave >= 6:
		# Heavy robots appear
		if roll < 0.15:
			animal_type = "heavy_robot"
			hp = 4
			speed = 140  # Was 60
		elif roll < 0.4:
			animal_type = "robot"
			hp = 2
			speed = 180  # Was 80
		elif roll < 0.6:
			animal_type = "bull"
			hp = 2
			speed = 280  # Was 140
		elif roll < 0.8:
			animal_type = "cow"
			hp = 2
			speed = 200  # Was 90
		else:
			animal_type = "chicken"
			hp = 1
			speed = 260  # Was 120
	elif game.stampede_wave >= 4:
		# Robots start appearing
		if roll < 0.25:
			animal_type = "robot"
			hp = 2
			speed = 180  # Was 80
		elif roll < 0.5:
			animal_type = "bull"
			hp = 2
			speed = 280  # Was 140
		elif roll < 0.75:
			animal_type = "cow"
			hp = 2
			speed = 200  # Was 90
		else:
			animal_type = "chicken"
			hp = 1
			speed = 260  # Was 120
	elif game.stampede_wave >= 2:
		# Bulls and cows
		if roll < 0.3:
			animal_type = "bull"
			hp = 2
			speed = 280  # Was 140
		elif roll < 0.6:
			animal_type = "cow"
			hp = 2
			speed = 200  # Was 90
		else:
			animal_type = "chicken"
			hp = 1
			speed = 260  # Was 120
	else:
		# Wave 1: mostly chickens
		if roll < 0.7:
			animal_type = "chicken"
			hp = 1
			speed = 220  # Was 100
		else:
			animal_type = "cow"
			hp = 2
			speed = 180  # Was 80
	
	# Speed variation
	speed *= randf_range(0.85, 1.15)

	# Spawn from left, moving right - at ground level
	var spawn_x = -30
	var vel_x = speed

	game.stampede_animals.append({
		"type": animal_type,
		"pos": Vector2(spawn_x, game.stampede_ground_y),
		"vel": Vector2(vel_x, 0),
		"hp": hp,
		"max_hp": hp,
		"hit_flash": 0.0,
		"defeated": false,
		"telegraph": false,
		"color": randi() % 3  # Fixed color for chickens (0=black, 1=brown, 2=white)
	})

# ===========================================
# END STAMPEDE
# ===========================================

func end_stampede(victory: bool):
	game.stampede_complete = true
	game.stampede_active = false
	
	if game.stampede_score > game.stampede_high_score:
		game.stampede_high_score = game.stampede_score
	
	game.current_mode = game.GameMode.EXPLORATION
	game.current_area = game.Area.FARM
	game.player_pos = Vector2(30, 180)
	game.stampede_player_hp = game.stampede_player_max_hp
	
	game.kaido_trail_history.clear()
	game.kaido_pos = game.player_pos + Vector2(-20, -15)
	
	var score_msg = "Final Score: " + str(game.stampede_score)
	var wave_msg = "You reached Wave " + str(game.stampede_wave) + "!"
	
	if game.stampede_score >= game.stampede_high_score and game.stampede_score > 0:
		game.dialogue_queue = [
			{"speaker": "kaido", "text": "New high score!"},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": wave_msg},
		]
	elif game.stampede_wave >= 6:
		game.dialogue_queue = [
			{"speaker": "kaido", "text": "Those robots were tough!"},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": wave_msg},
		]
	elif game.stampede_wave >= 4:
		game.dialogue_queue = [
			{"speaker": "kaido", "text": "Robots appeared... the Collective!"},
			{"speaker": "kaido", "text": score_msg},
		]
	else:
		game.dialogue_queue = [
			{"speaker": "kaido", "text": "Ow... they got me."},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": "I can try again when ready."},
		]
	game.next_dialogue()
