extends RefCounted
# InteriorScenes.gd - Interior scene drawing (shed, tower, shop, etc.)
# Usage: var interior = InteriorScenes.new(self) in _ready()

var game  # Reference to main game script

func _init(game_ref):
	game = game_ref

# ===========================================
# SHED INTERIOR
# ===========================================

func draw_shed_interior():
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.04, 0.03))
	
	# Wooden walls (barely visible)
	for i in range(30):
		var bx = i * 16
		game.draw_rect(Rect2(bx, 0, 14, 320), Color(0.08 + fmod(i * 0.01, 0.02), 0.06, 0.04))
	
	# Flashlight cone
	var light_radius = 80
	var light_color = Color(1.0, 0.95, 0.7, 0.25)
	game.draw_circle(game.flashlight_pos, light_radius, light_color)
	game.draw_circle(game.flashlight_pos, light_radius * 0.6, Color(1.0, 0.95, 0.7, 0.15))
	game.draw_circle(game.flashlight_pos, light_radius * 0.3, Color(1.0, 0.98, 0.85, 0.1))
	
	# Objects revealed by flashlight
	draw_shed_objects(game.flashlight_pos)
	
	# Flashlight source indicator
	game.draw_circle(game.flashlight_pos, 5, Color(1.0, 0.9, 0.5, 0.8))
	
	if game.in_dialogue and not game.current_dialogue.is_empty():
		game.draw_dialogue_box()
	
	if not game.in_dialogue:
		game.draw_string(ThemeDB.fallback_font, Vector2(150, 300), "D-Pad Move Light   [X] Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.5))

func draw_shed_objects(light_pos: Vector2):
	var outline = Color(0, 0, 0)
	
	# Tools on wall (top left area)
	if light_pos.distance_to(Vector2(100, 80)) < 100:
		var vis = 1.0 - (light_pos.distance_to(Vector2(100, 80)) / 100)
		# Tool board background
		game.draw_rect(Rect2(59, 49, 82, 62), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(60, 50, 80, 60), Color(0.35, 0.28, 0.22, vis))
		
		# Wrench with outline
		game.draw_rect(Rect2(69, 59, 10, 42), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(70, 60, 8, 40), Color(0.55, 0.55, 0.6, vis))
		game.draw_rect(Rect2(68, 58, 12, 8), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(69, 59, 10, 6), Color(0.5, 0.5, 0.55, vis))
		game.draw_rect(Rect2(72, 60, 4, 4), Color(0.35, 0.28, 0.22, vis))
		
		# Hammer with outline
		game.draw_rect(Rect2(89, 54, 6, 52), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(90, 55, 4, 50), Color(0.6, 0.48, 0.38, vis))
		game.draw_rect(Rect2(84, 52, 18, 12), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(85, 53, 16, 10), Color(0.45, 0.45, 0.5, vis))
		
		# Screwdriver with outline
		game.draw_rect(Rect2(109, 69, 22, 10), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(110, 70, 20, 8), Color(0.7, 0.5, 0.35, vis))
		game.draw_rect(Rect2(128, 72, 14, 4), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(129, 73, 12, 2), Color(0.5, 0.5, 0.55, vis))
		
		# Watering can with outline
		game.draw_rect(Rect2(64, 85, 28, 22), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(65, 86, 26, 20), Color(0.5, 0.55, 0.6, vis))
		game.draw_line(Vector2(91, 90), Vector2(105, 82), Color(0, 0, 0, vis), 4)
		game.draw_line(Vector2(92, 90), Vector2(104, 83), Color(0.5, 0.55, 0.6, vis), 2)
		game.draw_arc(Vector2(78, 83), 8, PI, TAU, 8, Color(0, 0, 0, vis), 4)
		game.draw_arc(Vector2(78, 83), 8, PI, TAU, 8, Color(0.5, 0.55, 0.6, vis), 2)
	
	# Electronic components (top right)
	if light_pos.distance_to(Vector2(300, 100)) < 100:
		var vis = 1.0 - (light_pos.distance_to(Vector2(300, 100)) / 100)
		game.draw_rect(Rect2(259, 59, 102, 82), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(260, 60, 100, 80), Color(0.35, 0.28, 0.22, vis))
		
		# Jar 1 (LEDs)
		game.draw_rect(Rect2(269, 79, 27, 37), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(270, 80, 25, 35), Color(0.7, 0.8, 0.9, vis * 0.4))
		game.draw_rect(Rect2(270, 76, 25, 6), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(271, 77, 23, 4), Color(0.5, 0.45, 0.4, vis))
		game.draw_circle(Vector2(278, 95), 3, Color(1, 0.3, 0.3, vis * 0.7))
		game.draw_circle(Vector2(285, 100), 3, Color(0.3, 1, 0.3, vis * 0.7))
		game.draw_circle(Vector2(290, 92), 3, Color(1, 1, 0.3, vis * 0.7))
		
		# Jar 2 (Resistors)
		game.draw_rect(Rect2(299, 84, 22, 32), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(300, 85, 20, 30), Color(0.7, 0.8, 0.9, vis * 0.4))
		game.draw_rect(Rect2(300, 81, 20, 6), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(301, 82, 18, 4), Color(0.5, 0.45, 0.4, vis))
		for i in range(4):
			game.draw_rect(Rect2(304, 92 + i * 5, 10, 3), Color(0.7, 0.55, 0.4, vis * 0.6))
		
		# Jar 3 (Capacitors)
		game.draw_rect(Rect2(329, 81, 24, 35), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(330, 82, 22, 33), Color(0.7, 0.8, 0.9, vis * 0.4))
		game.draw_rect(Rect2(330, 78, 22, 6), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(331, 79, 20, 4), Color(0.5, 0.45, 0.4, vis))
		game.draw_rect(Rect2(336, 90, 8, 12), Color(0.2, 0.3, 0.5, vis * 0.6))
		game.draw_rect(Rect2(338, 105, 6, 8), Color(0.2, 0.3, 0.5, vis * 0.6))
		
		# Labels
		game.draw_string(ThemeDB.fallback_font, Vector2(268, 125), "LEDs", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
		game.draw_string(ThemeDB.fallback_font, Vector2(298, 125), "RES", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
		game.draw_string(ThemeDB.fallback_font, Vector2(330, 125), "CAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
	
	# Hidden photograph (bottom right behind boxes)
	if light_pos.distance_to(Vector2(360, 250)) < 80:
		var vis = 1.0 - (light_pos.distance_to(Vector2(360, 250)) / 80)
		# Cardboard boxes
		game.draw_rect(Rect2(319, 199, 62, 52), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(320, 200, 60, 50), Color(0.5, 0.42, 0.32, vis))
		game.draw_line(Vector2(320, 225), Vector2(380, 225), Color(0.4, 0.32, 0.22, vis), 2)
		game.draw_rect(Rect2(340, 205, 20, 15), Color(0.45, 0.38, 0.28, vis))
		
		game.draw_rect(Rect2(369, 219, 52, 42), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(370, 220, 50, 40), Color(0.48, 0.4, 0.3, vis))
		game.draw_line(Vector2(370, 240), Vector2(420, 240), Color(0.38, 0.3, 0.2, vis), 2)
		
		# Photo peeking out
		if game.shed_explore_stage < 3:
			if game.tex_old_family_photo:
				# Draw small preview of actual photo
				game.draw_rect(Rect2(354, 244, 42, 32), Color(0, 0, 0, vis))
				game.draw_texture_rect(game.tex_old_family_photo, Rect2(355, 245, 40, 30), false, Color(1, 1, 1, vis * 0.8))
			else:
				game.draw_rect(Rect2(354, 244, 42, 32), Color(0, 0, 0, vis))
				game.draw_rect(Rect2(355, 245, 40, 30), Color(0.9, 0.85, 0.75, vis * 0.7))
				game.draw_rect(Rect2(358, 248, 34, 24), Color(0.75, 0.7, 0.6, vis * 0.6))
			game.draw_string(ThemeDB.fallback_font, Vector2(340, 285), "Something here...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.85, 0.7, vis))
	
	# Shelves
	if light_pos.distance_to(Vector2(240, 150)) < 120:
		var vis = 1.0 - (light_pos.distance_to(Vector2(240, 150)) / 120)
		game.draw_rect(Rect2(29, 139, 422, 10), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(30, 140, 420, 8), Color(0.45, 0.38, 0.3, vis))
		game.draw_rect(Rect2(29, 199, 302, 10), Color(0, 0, 0, vis))
		game.draw_rect(Rect2(30, 200, 300, 8), Color(0.45, 0.38, 0.3, vis))

# ===========================================
# PHOTOGRAPH REVEAL
# ===========================================

func draw_photograph_reveal():
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.05, 0.08))
	var alpha = clamp(game.photo_fade, 0.0, 1.0)
	
	# Use actual photo texture if available
	if game.tex_old_family_photo:
		var photo_w = game.tex_old_family_photo.get_width()
		var photo_h = game.tex_old_family_photo.get_height()
		# Scale to fit nicely (about 200px wide)
		var scale = 200.0 / photo_w
		var display_w = photo_w * scale
		var display_h = photo_h * scale
		var photo_x = (480 - display_w) / 2
		var photo_y = (260 - display_h) / 2
		
		# Draw frame
		game.draw_rect(Rect2(photo_x - 10, photo_y - 10, display_w + 20, display_h + 20), Color(0.6, 0.55, 0.45, alpha))
		game.draw_rect(Rect2(photo_x - 8, photo_y - 8, display_w + 16, display_h + 16), Color(0.85, 0.8, 0.7, alpha))
		
		# Draw photo with alpha
		game.draw_texture_rect(game.tex_old_family_photo, Rect2(photo_x, photo_y, display_w, display_h), false, Color(1, 1, 1, alpha))
	else:
		# Fallback to procedural drawing
		# Photo frame
		game.draw_rect(Rect2(90, 40, 300, 200), Color(0.85, 0.8, 0.7, alpha))
		game.draw_rect(Rect2(90, 40, 300, 200), Color(0.6, 0.55, 0.45, alpha), false, 4)
		game.draw_rect(Rect2(100, 50, 280, 150), Color(0.75, 0.68, 0.58, alpha))
		
		# People silhouettes
		var people_y = 130
		game.draw_rect(Rect2(120, people_y, 18, 45), Color(0.45, 0.40, 0.35, alpha))
		game.draw_circle(Vector2(129, people_y - 8), 11, Color(0.55, 0.48, 0.42, alpha))
		game.draw_rect(Rect2(155, people_y - 5, 20, 50), Color(0.5, 0.35, 0.45, alpha))
		game.draw_circle(Vector2(165, people_y - 18), 13, Color(0.55, 0.50, 0.45, alpha))
		game.draw_rect(Rect2(195, people_y - 8, 22, 53), Color(0.4, 0.38, 0.35, alpha))
		game.draw_circle(Vector2(206, people_y - 22), 14, Color(0.52, 0.48, 0.42, alpha))
		game.draw_rect(Rect2(240, people_y, 20, 45), Color(0.42, 0.40, 0.38, alpha))
		game.draw_circle(Vector2(250, people_y - 12), 12, Color(0.5, 0.46, 0.40, alpha))
		
		# Robots
		game.draw_rect(Rect2(285, people_y + 5, 25, 40), Color(0.45, 0.5, 0.5, alpha))
		game.draw_rect(Rect2(285, people_y - 5, 25, 12), Color(0.5, 0.55, 0.55, alpha))
		game.draw_rect(Rect2(320, people_y + 10, 30, 35), Color(0.4, 0.45, 0.45, alpha))
		game.draw_rect(Rect2(320, people_y, 30, 12), Color(0.45, 0.5, 0.5, alpha))
		
		# "THE RESISTANCE" text
		if alpha > 0.7:
			var text_alpha = (alpha - 0.7) / 0.3
			game.draw_rect(Rect2(140, 205, 200, 30), Color(0.8, 0.75, 0.65, text_alpha))
			game.draw_string(ThemeDB.fallback_font, Vector2(165, 228), "THE RESISTANCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.35, 0.30, 0.25, text_alpha))
	
	game.draw_string(ThemeDB.fallback_font, Vector2(160, 265), "AN OLD PHOTOGRAPH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.65, 0.55, alpha))
	
	if game.photo_fade >= 1.0:
		game.draw_string(ThemeDB.fallback_font, Vector2(200, 295), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))

# ===========================================
# RADIOTOWER VIEW (from top)
# ===========================================

func draw_radiotower_view():
	# Sky gradient
	if game.is_nightfall:
		game.draw_rect(Rect2(0, 0, 480, 160), Color(0.1, 0.1, 0.2))
		game.draw_rect(Rect2(0, 160, 480, 160), Color(0.15, 0.12, 0.18))
	else:
		game.draw_rect(Rect2(0, 0, 480, 160), Color(0.3, 0.4, 0.6))
		game.draw_rect(Rect2(0, 160, 480, 160), Color(0.6, 0.5, 0.4))
	
	# Sun/moon
	if game.is_nightfall:
		game.draw_circle(Vector2(400, 60), 25, Color(0.9, 0.9, 0.8))
		for i in range(15):
			var sx = 50 + i * 30 + sin(i * 1.5) * 20
			var sy = 20 + cos(i * 2.3) * 40
			game.draw_circle(Vector2(sx, sy), 1, Color(1, 1, 1, 0.8))
	else:
		game.draw_circle(Vector2(380, 50), 30, Color(1.0, 0.9, 0.5))
	
	# Distant view
	game.draw_rect(Rect2(0, 180, 480, 140), Color(0.45, 0.55, 0.38))
	game.draw_rect(Rect2(100, 200, 40, 30), Color(0.55, 0.45, 0.38))
	game.draw_rect(Rect2(200, 210, 30, 25), Color(0.48, 0.38, 0.30))
	game.draw_rect(Rect2(300, 195, 35, 40), Color(0.5, 0.42, 0.35))
	game.draw_rect(Rect2(0, 240, 480, 20), Color(0.6, 0.48, 0.35))
	
	# Tower structure
	game.draw_rect(Rect2(10, 50, 8, 270), Color(0.45, 0.35, 0.28))
	game.draw_rect(Rect2(462, 50, 8, 270), Color(0.45, 0.35, 0.28))
	for i in range(10):
		var ry = 70 + i * 25
		game.draw_rect(Rect2(10, ry, 25, 4), Color(0.5, 0.40, 0.32))
		game.draw_rect(Rect2(445, ry, 25, 4), Color(0.5, 0.40, 0.32))
	game.draw_rect(Rect2(0, 45, 480, 8), Color(0.5, 0.40, 0.32))
	
	# Radio equipment panel
	game.draw_rect(Rect2(150, 55, 180, 70), Color(0.25, 0.25, 0.28))
	game.draw_rect(Rect2(150, 55, 180, 70), Color(0.4, 0.4, 0.45), false, 2)
	
	# Beacon indicator
	game.draw_circle(Vector2(240, 90), 18, Color(0.15, 0.15, 0.18))
	if game.quest_stage >= 12:
		var glow = (sin(game.continuous_timer * 3) * 0.3 + 0.7)
		game.draw_circle(Vector2(240, 90), 15, Color(0.2, 0.8, 0.3, glow))
	elif game.quest_stage == 11:
		game.draw_circle(Vector2(240, 90), 15, Color(0.3, 0.3, 0.35))
	
	# Task display
	var task_text = ""
	var can_leave = game.can_exit_radiotower()
	
	if game.quest_stage == 11:
		task_text = "Build: LIGHT SENSOR"
	elif game.quest_stage == 12:
		task_text = "Build: LED CHAIN"
	elif game.quest_stage == 13:
		task_text = "Build: OR GATE"
	elif game.quest_stage >= 14:
		task_text = "All beacons ready!"
	
	game.draw_rect(Rect2(140, 135, 200, 30), Color(0.1, 0.1, 0.12, 0.9))
	game.draw_rect(Rect2(140, 135, 200, 30), Color(0.4, 0.6, 0.5, 0.7), false, 2)
	game.draw_string(ThemeDB.fallback_font, Vector2(155, 156), task_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 0.85))
	
	# Controls
	if can_leave:
		game.draw_string(ThemeDB.fallback_font, Vector2(160, 300), "[X] Continue   [O] Climb Down", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.55, 0.5))
	else:
		game.draw_string(ThemeDB.fallback_font, Vector2(160, 300), "[X] Build Circuit", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.55, 0.5))
	
	if game.in_dialogue and not game.current_dialogue.is_empty():
		game.draw_dialogue_box()

# ===========================================
# RADIOTOWER INTERIOR (Climbing)
# ===========================================

func draw_radiotower_interior():
	# Draw different visuals based on current floor
	match game.tower_current_floor:
		0: draw_tower_floor_0()
		1: draw_tower_floor_1()
		2: draw_tower_floor_2()

	# Floor 2 (Radio Room) uses exploration-style rendering
	if game.tower_current_floor == 2:
		# Draw exploration-style player
		draw_radio_room_player()
		# Draw interaction prompt
		draw_radio_room_prompt()
	else:
		# Floors 0-1 use platformer style
		draw_tower_platforms()
		draw_tower_player_combat_style()

	# HUD
	draw_tower_hud()

	if game.in_dialogue and not game.current_dialogue.is_empty():
		game.draw_dialogue_box()

func draw_radio_room_kaido():
	# Draw Kaido in the radio room following player - same size as exploration mode
	var pos = game.tower_kaido_pos
	var bob = sin(game.continuous_timer * 3) * 3  # Floating animation

	if game.tex_kaido:
		var w = game.tex_kaido.get_width()
		var h = game.tex_kaido.get_height()
		# Use same adaptive scaling as exploration mode draw_kaido()
		var draw_w: int
		var draw_h: int
		if w > 48:
			draw_w = int(w / 4)
			draw_h = int(h / 4)
		elif w > 32:
			draw_w = int(w / 2)
			draw_h = int(h / 2)
		else:
			draw_w = w
			draw_h = h
		# Draw shadow
		game.draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(8, 3), Color(0, 0, 0, 0.25))
		# Draw Kaido
		game.draw_texture_rect(game.tex_kaido, Rect2(pos.x - draw_w/2, pos.y - draw_h + 3 + bob, draw_w, draw_h), false)
	else:
		# Fallback
		game.draw_circle(Vector2(pos.x, pos.y - 15 + bob), 12, Color(0.3, 0.8, 0.7))

func draw_radio_room_player():
	# Draw Kaido first (behind player)
	draw_radio_room_kaido()

	var pos = game.radio_room_player_pos
	var facing = game.radio_room_player_facing
	var scale = 2.5  # Scale player to match interior scene

	# Draw shadow (scaled)
	game.draw_ellipse(Vector2(pos.x, pos.y + 15), Vector2(20, 8), Color(0, 0, 0, 0.3))

	# Get appropriate texture based on facing direction
	var tex: Texture2D = null
	match facing:
		"down": tex = game.tex_player_idle_south
		"up": tex = game.tex_player_idle_north
		"left": tex = game.tex_player_idle_west
		"right": tex = game.tex_player_idle_east

	if tex:
		var w = tex.get_width() * scale
		var h = tex.get_height() * scale
		# Draw at scaled size for interior
		game.draw_texture_rect(tex, Rect2(pos.x - w/2, pos.y - h + 15, w, h), false)
	else:
		# Fallback - simple rectangle (scaled)
		game.draw_rect(Rect2(pos.x - 16, pos.y - 50, 32, 56), Color(0.3, 0.6, 0.7))

func draw_radio_room_prompt():
	if game.is_near_radio_console():
		# Draw interaction prompt near bottom
		var prompt_text = "[X] Use Radio"
		var prompt_w = prompt_text.length() * 8 + 20
		var prompt_x = 240 - prompt_w / 2
		var prompt_y = 280

		# Background
		game.draw_rect(Rect2(prompt_x, prompt_y, prompt_w, 24), Color(0, 0.3, 0.35, 0.9))
		game.draw_rect(Rect2(prompt_x, prompt_y, prompt_w, 24), Color(0.3, 0.8, 0.8), false, 2)
		# Text
		game.draw_string(ThemeDB.fallback_font, Vector2(prompt_x + 10, prompt_y + 17), prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func draw_tower_floor_0():
	# Ground floor - Industrial entrance, dark and gritty
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.07, 0.06))

	# Concrete walls with rust stains
	for i in range(6):
		var panel_x = i * 80
		game.draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.15, 0.14, 0.12))
		# Rust stains
		game.draw_rect(Rect2(panel_x + 20, 50, 15, 80), Color(0.25, 0.15, 0.1, 0.4))
		game.draw_rect(Rect2(panel_x + 45, 120, 20, 60), Color(0.22, 0.12, 0.08, 0.3))

	# Heavy industrial pipes
	game.draw_rect(Rect2(15, 0, 12, 320), Color(0.3, 0.28, 0.25))
	game.draw_rect(Rect2(453, 0, 12, 320), Color(0.3, 0.28, 0.25))
	game.draw_rect(Rect2(17, 0, 3, 320), Color(0.4, 0.38, 0.35))

	# Warning stripes at edges
	for i in range(16):
		var stripe_y = i * 20
		var col = Color(0.8, 0.5, 0.1) if i % 2 == 0 else Color(0.1, 0.1, 0.1)
		game.draw_rect(Rect2(0, stripe_y, 12, 20), col)
		game.draw_rect(Rect2(468, stripe_y, 12, 20), col)

	# "FLOOR 1" sign
	game.draw_rect(Rect2(200, 10, 80, 25), Color(0.15, 0.12, 0.1))
	game.draw_string(ThemeDB.fallback_font, Vector2(212, 28), "FLOOR 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.5, 0.4))

	# Arrow pointing up
	game.draw_rect(Rect2(235, 40, 10, 30), Color(0.3, 0.6, 0.3))
	var arrow_pts = PackedVector2Array([Vector2(240, 35), Vector2(230, 50), Vector2(250, 50)])
	game.draw_colored_polygon(arrow_pts, Color(0.3, 0.6, 0.3))

func draw_tower_floor_1():
	# Middle floor - Cables and machinery
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.1, 0.09, 0.08))

	# Metal panel walls
	for i in range(6):
		var panel_x = i * 80
		game.draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.18, 0.17, 0.15))
		game.draw_rect(Rect2(panel_x + 2, 2, 74, 316), Color(0.2, 0.19, 0.17), false, 1)
		# Rivets
		for j in range(8):
			game.draw_circle(Vector2(panel_x + 8, 20 + j * 40), 2, Color(0.25, 0.23, 0.2))
			game.draw_circle(Vector2(panel_x + 70, 20 + j * 40), 2, Color(0.25, 0.23, 0.2))

	# Vertical cable bundles
	game.draw_rect(Rect2(50, 0, 6, 320), Color(0.2, 0.2, 0.25))
	game.draw_rect(Rect2(424, 0, 6, 320), Color(0.2, 0.2, 0.25))
	game.draw_rect(Rect2(52, 0, 2, 320), Color(0.3, 0.3, 0.35))

	# Horizontal conduits
	game.draw_rect(Rect2(0, 100, 480, 8), Color(0.25, 0.23, 0.2))
	game.draw_rect(Rect2(0, 200, 480, 8), Color(0.25, 0.23, 0.2))

	# Blinking machinery lights
	var blink1 = sin(game.continuous_timer * 4) > 0
	var blink2 = sin(game.continuous_timer * 3 + 1) > 0
	game.draw_circle(Vector2(100, 80), 4, Color(1.0, 0.3, 0.2) if blink1 else Color(0.3, 0.1, 0.1))
	game.draw_circle(Vector2(380, 150), 4, Color(0.2, 1.0, 0.3) if blink2 else Color(0.1, 0.3, 0.1))

	# "FLOOR 2" sign
	game.draw_rect(Rect2(200, 10, 80, 25), Color(0.15, 0.15, 0.18))
	game.draw_string(ThemeDB.fallback_font, Vector2(212, 28), "FLOOR 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.6, 0.7))

func draw_tower_floor_2():
	# Top floor - Radio room with horizon view
	# Sky gradient background (visible through windows)
	for i in range(32):
		var sky_y = i * 10
		var t = float(i) / 32.0
		var sky_col = Color(0.15 + t * 0.3, 0.25 + t * 0.2, 0.4 + t * 0.1)
		game.draw_rect(Rect2(0, sky_y, 480, 10), sky_col)

	# Distant horizon - mountains/landscape
	var horizon_y = 120
	# Mountain silhouettes
	var mountain_pts = PackedVector2Array([
		Vector2(0, horizon_y + 40),
		Vector2(60, horizon_y - 20), Vector2(100, horizon_y + 10),
		Vector2(150, horizon_y - 40), Vector2(200, horizon_y),
		Vector2(250, horizon_y - 30), Vector2(300, horizon_y + 5),
		Vector2(350, horizon_y - 50), Vector2(400, horizon_y - 10),
		Vector2(450, horizon_y - 25), Vector2(480, horizon_y + 30),
		Vector2(480, horizon_y + 40)
	])
	game.draw_colored_polygon(mountain_pts, Color(0.12, 0.15, 0.2))

	# Distant village lights (twinkling)
	for i in range(8):
		var lx = 50 + i * 55 + sin(i * 2.5) * 20
		var ly = horizon_y + 10 + cos(i * 1.5) * 15
		var twinkle = (sin(game.continuous_timer * (2 + i * 0.3)) * 0.3 + 0.7)
		game.draw_circle(Vector2(lx, ly), 2, Color(1.0, 0.9, 0.6, twinkle * 0.8))

	# Sun/moon glow on horizon
	var glow_phase = sin(game.continuous_timer * 0.5) * 0.2 + 0.8
	game.draw_circle(Vector2(400, horizon_y - 30), 25, Color(1.0, 0.8, 0.5, 0.15 * glow_phase))
	game.draw_circle(Vector2(400, horizon_y - 30), 15, Color(1.0, 0.9, 0.7, 0.25 * glow_phase))

	# Window frames (structural beams cutting across view)
	game.draw_rect(Rect2(0, 0, 480, 140), Color(0, 0, 0, 0), false)  # Transparent top
	game.draw_rect(Rect2(0, 140, 480, 180), Color(0.12, 0.11, 0.1))  # Floor area

	# Metal cross beams (moved up for more floor space)
	game.draw_rect(Rect2(0, 145, 480, 10), Color(0.2, 0.18, 0.16))
	game.draw_rect(Rect2(0, 148, 480, 4), Color(0.25, 0.23, 0.2))

	# Vertical window dividers
	for i in range(5):
		var beam_x = 20 + i * 110
		game.draw_rect(Rect2(beam_x, 0, 8, 150), Color(0.18, 0.16, 0.14))

	# Floor area (larger for walking)
	game.draw_rect(Rect2(0, 155, 480, 165), Color(0.12, 0.11, 0.1))

	# Floor tiles pattern
	for tx in range(8):
		for ty in range(3):
			var tile_x = tx * 60
			var tile_y = 160 + ty * 50
			game.draw_rect(Rect2(tile_x, tile_y, 58, 48), Color(0.14, 0.13, 0.12))

	# "RADIO ROOM" sign (smaller, at console)
	game.draw_rect(Rect2(200, 158, 80, 14), Color(0.08, 0.08, 0.1))
	game.draw_rect(Rect2(200, 158, 80, 14), Color(0.4, 0.6, 0.5), false, 1)
	game.draw_string(ThemeDB.fallback_font, Vector2(212, 169), "RADIO ROOM", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.8, 0.6))

	# Radio console (main equipment - scaled down)
	draw_radio_equipment()

func draw_radio_equipment():
	# Scaled down equipment - positioned as background furniture
	# Console desk at back of room (smaller, positioned higher)
	var console_y = 175
	game.draw_rect(Rect2(140, console_y, 200, 35), Color(0.15, 0.14, 0.13))
	game.draw_rect(Rect2(140, console_y, 200, 3), Color(0.25, 0.23, 0.2))

	# Monitor/screen (smaller)
	game.draw_rect(Rect2(155, console_y + 5, 45, 25), Color(0.05, 0.05, 0.08))
	game.draw_rect(Rect2(158, console_y + 8, 39, 19), Color(0.1, 0.2, 0.15))
	# Screen content - waveform (smaller)
	for i in range(8):
		var wave_h = sin(game.continuous_timer * 3 + i * 0.5) * 4 + 6
		game.draw_rect(Rect2(161 + i * 4, console_y + 14 - wave_h/2, 2, wave_h), Color(0.3, 0.9, 0.4))

	# Frequency dial (smaller)
	game.draw_circle(Vector2(230, console_y + 18), 12, Color(0.2, 0.18, 0.16))
	game.draw_circle(Vector2(230, console_y + 18), 10, Color(0.35, 0.32, 0.3))
	# Dial needle
	var needle_angle = sin(game.continuous_timer * 0.8) * 0.8
	var needle_end = Vector2(230 + cos(needle_angle) * 8, console_y + 18 + sin(needle_angle) * 8)
	game.draw_line(Vector2(230, console_y + 18), needle_end, Color(1.0, 0.3, 0.2), 2)

	# Status lights panel (smaller)
	game.draw_rect(Rect2(260, console_y + 5, 40, 25), Color(0.12, 0.12, 0.14))
	# Power light
	game.draw_circle(Vector2(270, console_y + 14), 3, Color(0.2, 0.8, 0.3))
	# Signal light (blinking)
	var sig_on = sin(game.continuous_timer * 5) > 0.3
	game.draw_circle(Vector2(283, console_y + 14), 3, Color(0.9, 0.7, 0.2) if sig_on else Color(0.3, 0.25, 0.1))
	# TX light
	game.draw_circle(Vector2(296, console_y + 14), 3, Color(0.3, 0.1, 0.1))
	game.draw_string(ThemeDB.fallback_font, Vector2(263, console_y + 27), "PWR SIG TX", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.4, 0.4, 0.4))

	# Microphone (smaller)
	game.draw_rect(Rect2(315, console_y + 8, 5, 18), Color(0.25, 0.23, 0.2))
	game.draw_circle(Vector2(317, console_y + 5), 6, Color(0.3, 0.28, 0.25))

	# Antenna connection (smaller, above console)
	game.draw_rect(Rect2(235, console_y - 10, 6, 12), Color(0.4, 0.38, 0.35))
	game.draw_rect(Rect2(237, console_y - 18, 2, 10), Color(0.5, 0.45, 0.4))
	if game.tower_reached_top:
		var glow = sin(game.continuous_timer * 3) * 0.3 + 0.7
		game.draw_circle(Vector2(238, console_y - 20), 3, Color(0.3, 1.0, 0.5, glow))

func draw_tower_platforms():
	for platform in game.tower_platforms:
		var px = platform.x
		var py = platform.y
		var pw = platform.w

		# Platform shadow
		game.draw_rect(Rect2(px + 3, py + 3, pw, 14), Color(0, 0, 0, 0.3))
		# Platform outline
		game.draw_rect(Rect2(px - 2, py - 2, pw + 4, 16), Color(0.0, 0.0, 0.0))
		# Platform body
		game.draw_rect(Rect2(px, py, pw, 12), Color(0.35, 0.33, 0.3))
		game.draw_rect(Rect2(px, py, pw, 4), Color(0.45, 0.43, 0.4))

		# Grating lines
		for j in range(int(pw / 15)):
			game.draw_line(Vector2(px + 7 + j * 15, py + 2), Vector2(px + 7 + j * 15, py + 10), Color(0.25, 0.23, 0.2), 2)

		# Bolts at ends
		game.draw_circle(Vector2(px + 5, py + 6), 3, Color(0.5, 0.48, 0.45))
		game.draw_circle(Vector2(px + pw - 5, py + 6), 3, Color(0.5, 0.48, 0.45))

func draw_tower_hud():
	# Floor indicator
	game.draw_rect(Rect2(10, 10, 120, 35), Color(0.08, 0.08, 0.1, 0.9))
	game.draw_rect(Rect2(10, 10, 120, 35), Color(0.4, 0.5, 0.6, 0.6), false, 2)

	var floor_name = ["GROUND", "MIDDLE", "RADIO ROOM"][game.tower_current_floor]
	game.draw_string(ThemeDB.fallback_font, Vector2(20, 28), "Floor " + str(game.tower_current_floor + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.7, 0.65))
	game.draw_string(ThemeDB.fallback_font, Vector2(20, 40), floor_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.9, 0.85))

	# Progress bar (3 floor segments)
	game.draw_rect(Rect2(140, 15, 90, 25), Color(0.08, 0.08, 0.1, 0.9))
	for i in range(3):
		var seg_x = 145 + i * 28
		var seg_col = Color(0.3, 0.7, 0.5) if i <= game.tower_current_floor else Color(0.15, 0.15, 0.18)
		game.draw_rect(Rect2(seg_x, 20, 24, 15), seg_col)
		game.draw_rect(Rect2(seg_x, 20, 24, 15), Color(0.4, 0.5, 0.6, 0.4), false, 1)

	# Exit prompt at ground floor bottom
	if game.tower_current_floor == 0 and game.tower_player_pos.y > 260:
		game.draw_rect(Rect2(175, 290, 130, 25), Color(0.08, 0.08, 0.1, 0.9))
		game.draw_string(ThemeDB.fallback_font, Vector2(185, 308), "[O] Exit Tower", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.65))

	# Controls hint (different for Radio Room)
	game.draw_rect(Rect2(320, 290, 150, 25), Color(0.08, 0.08, 0.1, 0.9))
	if game.tower_current_floor == 2:
		game.draw_string(ThemeDB.fallback_font, Vector2(345, 308), "<-> Move", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.45))
	else:
		game.draw_string(ThemeDB.fallback_font, Vector2(330, 308), "[X] Jump  <-> Move", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.45))

func draw_tower_kaido():
	# Draw Kaido following player in tower climbing - same size as exploration mode
	var pos = game.tower_kaido_pos
	var bob = sin(game.continuous_timer * 3) * 3  # Floating animation

	if game.tex_kaido:
		var w = game.tex_kaido.get_width()
		var h = game.tex_kaido.get_height()
		# Use same adaptive scaling as exploration mode draw_kaido()
		var draw_w: int
		var draw_h: int
		if w > 48:
			draw_w = int(w / 4)
			draw_h = int(h / 4)
		elif w > 32:
			draw_w = int(w / 2)
			draw_h = int(h / 2)
		else:
			draw_w = w
			draw_h = h
		# Draw shadow
		game.draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(8, 3), Color(0, 0, 0, 0.25))
		# Draw Kaido
		game.draw_texture_rect(game.tex_kaido, Rect2(pos.x - draw_w/2, pos.y - draw_h + 3 + bob, draw_w, draw_h), false)
	else:
		# Fallback
		game.draw_circle(Vector2(pos.x, pos.y - 15 + bob), 12, Color(0.3, 0.8, 0.7))

func draw_tower_player_combat_style():
	# Draw Kaido first (behind player)
	draw_tower_kaido()

	var pos = game.tower_player_pos
	var scale_factor = 1.8

	# Use new animation system if available
	if game.player_anim_loaded:
		var tex: Texture2D = null
		var frame = game.player_frame % 6

		if not game.tower_player_grounded:
			# Jumping - use proper jump animation
			var jump_frames = game.tex_player_jump_east if game.tower_player_facing_right else game.tex_player_jump_west
			if jump_frames.size() > 0:
				# Determine jump frame based on vertical velocity
				# Rising = early frames, peak = middle frames, falling = late frames
				var jump_frame: int
				if game.tower_player_vel.y < -200:  # Rising fast
					jump_frame = 0
				elif game.tower_player_vel.y < -100:  # Rising
					jump_frame = 1
				elif game.tower_player_vel.y < 0:  # Near peak (still rising)
					jump_frame = 2
				elif game.tower_player_vel.y < 100:  # Near peak (starting to fall)
					jump_frame = 3
				elif game.tower_player_vel.y < 200:  # Falling
					jump_frame = 4
				elif game.tower_player_vel.y < 400:  # Falling fast
					jump_frame = 5
				else:  # Falling very fast
					jump_frame = min(6, jump_frames.size() - 1)
				jump_frame = clamp(jump_frame, 0, jump_frames.size() - 1)
				tex = jump_frames[jump_frame]
			else:
				# Fallback to walk frame if jump not loaded
				var walk_frames = game.tex_player_walk_east if game.tower_player_facing_right else game.tex_player_walk_west
				if walk_frames.size() > 2:
					tex = walk_frames[2]
		elif abs(game.tower_player_vel.x) > 5:
			# Walking
			var walk_frames = game.tex_player_walk_east if game.tower_player_facing_right else game.tex_player_walk_west
			if walk_frames.size() > frame:
				tex = walk_frames[frame]
		else:
			# Idle
			tex = game.tex_player_idle_east if game.tower_player_facing_right else game.tex_player_idle_west

		if tex:
			var w = tex.get_width() * scale_factor
			var h = tex.get_height() * scale_factor
			var draw_x = pos.x - w / 2
			var draw_y = pos.y - h + 10
			game.draw_texture_rect(tex, Rect2(draw_x, draw_y, w, h), false)
			return
	
	# Fallback to old system
	if not game.tex_player:
		return
	
	var row = 0
	var frame = 0
	var sprite_size = 48 * 1.5
	
	if not game.tower_player_grounded:
		row = 3
		frame = 2
	elif abs(game.tower_player_vel.x) > 5:
		row = 3
		frame = int(game.continuous_timer * 8) % 6
	else:
		row = 0
		frame = int(game.continuous_timer * 2) % 3
	
	var src = Rect2(frame * 48, row * 48, 48, 48)
	var draw_x = pos.x - sprite_size / 2
	var draw_y = pos.y - sprite_size + 10
	
	if game.tower_player_facing_right:
		game.draw_texture_rect_region(game.tex_player, Rect2(draw_x, draw_y, sprite_size, sprite_size), src)
	else:
		game.draw_texture_rect_region(game.tex_player, Rect2(draw_x + sprite_size, draw_y, -sprite_size, sprite_size), src)

# ===========================================
# ENDING CUTSCENE
# ===========================================

func draw_ending_cutscene():
	match game.ending_stage:
		0:
			# Entering the tunnel
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.08, 0.1))
			game.draw_rect(Rect2(140, 80, 200, 160), Color(0.05, 0.05, 0.08))
			game.draw_string(ThemeDB.fallback_font, Vector2(170, 180), "ENTERING TUNNEL...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))
		1:
			# Agricommune burns
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.15, 0.08, 0.05))
			for i in range(5):
				var fx = 80 + i * 80
				var fy = 100 + sin(game.anim_timer * 2 + i) * 20
				game.draw_circle(Vector2(fx, fy), 30, Color(1.0, 0.5, 0.2, 0.4))
				game.draw_circle(Vector2(fx, fy - 10), 20, Color(1.0, 0.7, 0.3, 0.3))
			game.draw_string(ThemeDB.fallback_font, Vector2(140, 280), "Agricommune burns...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.7, 0.5))
		2:
			# Grandmother stands her ground
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.12, 0.08, 0.08))
			# Draw grandmother facing robots (facing right)
			game.grandmother_facing = "right"
			game.draw_grandmother(Vector2(200, 180))
			game.draw_robot_soldier(Vector2(320, 150))
			game.draw_robot_soldier(Vector2(380, 160))
			game.draw_robot_soldier(Vector2(400, 145))
			game.draw_string(ThemeDB.fallback_font, Vector2(80, 250), "\"Go! Get the children to safety!\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.7))
			game.draw_string(ThemeDB.fallback_font, Vector2(80, 275), "Grandmother turns to face the patrol.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.6, 0.5))
		3:
			# Grandmother's sacrifice
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.1, 0.06, 0.08))
			# Grandmother surrounded by robots (facing down/camera)
			game.grandmother_facing = "down"
			game.draw_grandmother(Vector2(240, 180))
			game.draw_robot_soldier(Vector2(150, 140))
			game.draw_robot_soldier(Vector2(180, 170))
			game.draw_robot_soldier(Vector2(300, 140))
			game.draw_robot_soldier(Vector2(330, 170))
			game.draw_string(ThemeDB.fallback_font, Vector2(90, 240), "\"I am the one you want. The children\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.7, 0.6))
			game.draw_string(ThemeDB.fallback_font, Vector2(90, 260), "\"know nothing of the old ways.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.7, 0.6))
			game.draw_string(ThemeDB.fallback_font, Vector2(100, 290), "She sacrifices herself for the village.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.5, 0.5))
		4:
			# Grandmother captured
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.1, 0.08, 0.12))
			# Grandmother captured between robots (facing down)
			game.grandmother_facing = "down"
			game.draw_grandmother(Vector2(240, 180))
			game.draw_robot_soldier(Vector2(180, 160))
			game.draw_robot_soldier(Vector2(300, 160))
			# Energy restraints around grandmother
			game.draw_rect(Rect2(220, 160, 40, 4), Color(0.8, 0.2, 0.2, 0.7))
			game.draw_string(ThemeDB.fallback_font, Vector2(130, 250), "Grandmother is taken prisoner.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.5, 0.5))
			game.draw_string(ThemeDB.fallback_font, Vector2(100, 280), "The villagers escape through the tunnel.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.7, 0.6))
		5:
			# Grandmother's final words (flashback)
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.05, 0.08))
			game.draw_rect(Rect2(200, 120, 80, 40), Color(0.5, 0.5, 0.55))  # Memory device
			game.draw_rect(Rect2(280, 130, 15, 20), Color(0.6, 0.6, 0.65))
			game.draw_circle(Vector2(240, 140), 12, Color(0.3, 0.8, 0.7, 0.6))
			game.draw_string(ThemeDB.fallback_font, Vector2(100, 200), "\"Find Professor Ohm in New Sumida.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.8, 0.75))
			game.draw_string(ThemeDB.fallback_font, Vector2(100, 225), "\"Show him Kaido. He will understand.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.8, 0.75))
			game.draw_string(ThemeDB.fallback_font, Vector2(100, 260), "\"I will find my own way out.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.8, 0.75))
			game.draw_string(ThemeDB.fallback_font, Vector2(140, 295), "- Grandmother's last words", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.5))
		6:
			# Journey to New Sumida
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.1, 0.12))
			game.draw_rect(Rect2(100, 60, 280, 200), Color(0.12, 0.14, 0.16))
			game.draw_rect(Rect2(140, 90, 200, 140), Color(0.1, 0.12, 0.14))
			for i in range(5):
				var sx = 180 + i * 25
				var sy = 180 + i * 5
				game.draw_rect(Rect2(sx, sy - 20, 8, 22), Color(0.3, 0.3, 0.35))
				game.draw_circle(Vector2(sx + 4, sy - 25), 5, Color(0.35, 0.35, 0.4))
			game.draw_circle(Vector2(300, 160), 12, Color(0.3, 0.75, 0.7))  # Kaido
			game.draw_string(ThemeDB.fallback_font, Vector2(120, 260), "The journey to New Sumida City begins...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.8, 0.75))
			game.draw_string(ThemeDB.fallback_font, Vector2(160, 280), "We will come back for you.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.7, 0.65))

	# Draw "Press to continue" prompt with blinking effect
	var blink = sin(game.ending_timer * 3) * 0.3 + 0.7
	game.draw_string(ThemeDB.fallback_font, Vector2(175, 308), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6, blink))

# ===========================================
# REGION COMPLETE
# ===========================================

func draw_region_complete():
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.06, 0.08, 0.1))
	
	game.draw_rect(Rect2(30, 30, 420, 260), Color(0.12, 0.15, 0.14))
	game.draw_rect(Rect2(30, 30, 420, 260), Color(0.3, 0.7, 0.65), false, 3)
	
	game.draw_string(ThemeDB.fallback_font, Vector2(130, 70), "REGION COMPLETED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 0.95, 0.85))
	game.draw_string(ThemeDB.fallback_font, Vector2(180, 110), "AGRICOMMUNE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.65, 0.55))
	game.draw_string(ThemeDB.fallback_font, Vector2(150, 150), "Circuits built: " + str(game.circuits_built), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	game.draw_string(ThemeDB.fallback_font, Vector2(150, 180), "Skills learned:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
	var skills = ["LED Basics", "Buttons & Switches", "Logic Gates (AND, OR)", "Light Sensors", "Series Circuits"]
	var sy = 198
	for skill in skills:
		game.draw_string(ThemeDB.fallback_font, Vector2(170, sy), "- " + skill, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6))
		sy += 15
	
	game.draw_string(ThemeDB.fallback_font, Vector2(140, 280), "NEXT: New Sumida City", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.85, 0.8))

# ===========================================
# SHOP INTERIOR
# ===========================================

func draw_shop_interior():
	var TILE = 16  # Tile size
	var SCALE = 2  # Scale tiles 2x to match game zoom

	# Background fill (in case tiles don't load)
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.55, 0.45, 0.35))

	# Draw tiled floor using TilesetInteriorFloor (orange brick pattern)
	if game.tex_interior_floor:
		# Use orange brick tile from first row (tile at 16,0 - center brick)
		var floor_src = Rect2(16, 0, TILE, TILE)
		var floor_y_start = 100  # Wall/floor boundary
		for y in range(int((320 - floor_y_start) / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				var dest = Rect2(x * TILE * SCALE, floor_y_start + y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, floor_src)

	# Draw wall area (tan decorative pattern from interior floor tileset)
	if game.tex_interior_floor:
		# Use tan/beige wall pattern from row 2 (ornate carpet pattern at x=176)
		var wall_src = Rect2(176, 16, TILE, TILE)
		for y in range(int(100 / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				var dest = Rect2(x * TILE * SCALE, y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, wall_src)

	# Draw shelves using TilesetHouse (wooden shelf elements)
	if game.tex_house_tileset:
		# Shelf bracket at ~(368, 144) in TilesetHouse - shelf/plank piece
		var shelf_src = Rect2(368, 128, 32, 16)
		# Left shelves
		for row in range(2):
			var shelf_y = 30 + row * 45
			for i in range(3):
				var dest = Rect2(20 + i * 64, shelf_y, 64, 32)
				game.draw_texture_rect_region(game.tex_house_tileset, dest, shelf_src)
		# Right shelves
		for row in range(2):
			var shelf_y = 30 + row * 45
			for i in range(3):
				var dest = Rect2(280 + i * 64, shelf_y, 64, 32)
				game.draw_texture_rect_region(game.tex_house_tileset, dest, shelf_src)

		# Draw items on shelves using barrel/crate sprites from TilesetHouse
		# Barrel at ~(448, 96), crate at ~(464, 96)
		var barrel_src = Rect2(448, 96, 16, 16)
		var crate_src = Rect2(464, 96, 16, 16)
		for row in range(2):
			var item_y = 10 + row * 45
			for i in range(5):
				var src = barrel_src if (i + row) % 2 == 0 else crate_src
				# Left side items
				game.draw_texture_rect_region(game.tex_house_tileset, Rect2(30 + i * 36, item_y, 28, 28), src)
				# Right side items
				game.draw_texture_rect_region(game.tex_house_tileset, Rect2(290 + i * 36, item_y, 28, 28), src)

		# Counter using wooden plank/counter from TilesetHouse
		# Counter top piece at ~(320, 64)
		var counter_src = Rect2(320, 64, 48, 16)
		for i in range(4):
			game.draw_texture_rect_region(game.tex_house_tileset, Rect2(140 + i * 52, 115, 52, 20), counter_src)
		# Counter front
		var counter_front_src = Rect2(320, 80, 48, 16)
		for i in range(4):
			game.draw_texture_rect_region(game.tex_house_tileset, Rect2(140 + i * 52, 135, 52, 20), counter_front_src)

	# Draw shop NPC
	game.draw_robot_npc(game.interior_npc_pos.x, game.interior_npc_pos.y, "shop")

	# Door (wooden door from TilesetHouse or solid color)
	if game.tex_house_tileset:
		# Door at ~(128, 32) in TilesetHouse
		var door_src = Rect2(128, 32, 32, 32)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(200, 275, 80, 45), door_src)
	else:
		game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))

	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)

	# Title
	game.draw_rect(Rect2(150, 5, 180, 25), Color(0, 0, 0, 0.6))
	game.draw_string(ThemeDB.fallback_font, Vector2(195, 22), "GENERAL STORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))

	# Prompts
	if not game.in_dialogue:
		if game.interior_near_npc:
			game.draw_rect(Rect2(180, 100, 120, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(180, 100, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(200, 117), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if game.interior_near_exit:
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))

	if game.in_dialogue:
		game.draw_dialogue_box()

# ===========================================
# TOWN HALL INTERIOR
# ===========================================

func draw_townhall_interior():
	var TILE = 16  # Tile size
	var SCALE = 2  # Scale tiles 2x to match game zoom

	# Background fill
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.65, 0.6, 0.55))

	# Draw ornate floor using TilesetInteriorFloor (tan/beige decorative pattern)
	if game.tex_interior_floor:
		# Use tan carpet/ornate pattern from second column (around x=176)
		var floor_src_light = Rect2(176, 32, TILE, TILE)  # Light tan tile
		var floor_src_dark = Rect2(192, 32, TILE, TILE)   # Darker tan tile
		var floor_y_start = 100
		for y in range(int((320 - floor_y_start) / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				# Checkered pattern using two tile variants
				var src = floor_src_light if (x + y) % 2 == 0 else floor_src_dark
				var dest = Rect2(x * TILE * SCALE, floor_y_start + y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, src)

	# Draw wall area using gray stone pattern
	if game.tex_interior_floor:
		# Use gray stone wall tile from row 4 (around y=64, x=176)
		var wall_src = Rect2(176, 64, TILE, TILE)
		for y in range(int(100 / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				var dest = Rect2(x * TILE * SCALE, y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, wall_src)

	# Draw pillars using stone pillar from TilesetHouse
	if game.tex_house_tileset:
		# Stone pillar/statue elements at ~(0, 224) in TilesetHouse
		var pillar_src = Rect2(0, 224, 32, 48)
		# Left pillar
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(40, 40, 48, 72), pillar_src)
		# Right pillar
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(392, 40, 48, 72), pillar_src)
	else:
		# Fallback pillars
		game.draw_rect(Rect2(50, 50, 30, 120), Color(0.55, 0.52, 0.48))
		game.draw_rect(Rect2(400, 50, 30, 120), Color(0.55, 0.52, 0.48))

	# Banner (red with gold emblem)
	game.draw_rect(Rect2(200, 15, 80, 75), Color(0.7, 0.2, 0.2))
	game.draw_rect(Rect2(202, 17, 76, 71), Color(0.75, 0.25, 0.22))
	game.draw_circle(Vector2(240, 52), 22, Color(0.9, 0.75, 0.2))
	game.draw_circle(Vector2(240, 52), 16, Color(0.95, 0.85, 0.3))
	# Banner tassels
	game.draw_rect(Rect2(205, 85, 8, 12), Color(0.9, 0.75, 0.2))
	game.draw_rect(Rect2(267, 85, 8, 12), Color(0.9, 0.75, 0.2))

	# Mayor's desk using wooden desk from TilesetHouse
	if game.tex_house_tileset:
		# Desk/table piece at ~(320, 64)
		var desk_src = Rect2(320, 64, 48, 32)
		for i in range(3):
			game.draw_texture_rect_region(game.tex_house_tileset, Rect2(165 + i * 50, 105, 55, 40), desk_src)
	else:
		game.draw_rect(Rect2(180, 110, 120, 40), Color(0.4, 0.3, 0.22))
		game.draw_rect(Rect2(180, 105, 120, 8), Color(0.5, 0.38, 0.28))

	# Draw mayor NPC
	game.draw_mayor_npc(game.interior_npc_pos.x, game.interior_npc_pos.y)

	# Door
	if game.tex_house_tileset:
		var door_src = Rect2(128, 32, 32, 32)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(200, 275, 80, 45), door_src)
	else:
		game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))

	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)

	# Title
	game.draw_rect(Rect2(180, 5, 120, 25), Color(0, 0, 0, 0.6))
	game.draw_string(ThemeDB.fallback_font, Vector2(205, 22), "TOWN HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))

	# Prompts
	if not game.in_dialogue:
		if game.interior_near_npc:
			game.draw_rect(Rect2(180, 85, 120, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(180, 85, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(200, 102), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if game.interior_near_exit:
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))

	if game.in_dialogue:
		game.draw_dialogue_box()

# ===========================================
# BAKERY INTERIOR
# ===========================================

func draw_bakery_interior():
	var TILE = 16  # Tile size
	var SCALE = 2  # Scale tiles 2x to match game zoom

	# Background fill with warm bakery glow
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.85, 0.75, 0.65))

	# Draw warm brick floor using TilesetInteriorFloor (orange brick pattern)
	if game.tex_interior_floor:
		# Use warm orange brick from first row
		var floor_src = Rect2(0, 0, TILE, TILE)
		var floor_y_start = 100
		for y in range(int((320 - floor_y_start) / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				var dest = Rect2(x * TILE * SCALE, floor_y_start + y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, floor_src)

	# Draw cream/beige wall using lighter tiles
	if game.tex_interior_floor:
		# Use warm beige/cream wall tile
		var wall_src = Rect2(176, 0, TILE, TILE)
		for y in range(int(100 / (TILE * SCALE)) + 1):
			for x in range(int(480 / (TILE * SCALE)) + 1):
				var dest = Rect2(x * TILE * SCALE, y * TILE * SCALE, TILE * SCALE, TILE * SCALE)
				game.draw_texture_rect_region(game.tex_interior_floor, dest, wall_src)

	# Warm bakery glow overlay
	game.draw_rect(Rect2(0, 0, 480, 320), Color(1.0, 0.9, 0.7, 0.08))

	# Brick oven structure using TilesetHouse
	if game.tex_house_tileset:
		# Brick oven dome at ~(224, 176) - rounded oven shape
		var oven_src = Rect2(224, 176, 48, 32)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(40, 40, 96, 64), oven_src)
		# Oven base
		var oven_base_src = Rect2(224, 208, 48, 16)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(40, 100, 96, 32), oven_base_src)
	else:
		# Fallback oven
		game.draw_rect(Rect2(50, 50, 100, 70), Color(0.6, 0.35, 0.25))

	# Oven opening with fire
	game.draw_rect(Rect2(60, 65, 56, 32), Color(0.15, 0.08, 0.05))
	var fire_pulse = sin(game.continuous_timer * 5) * 0.2 + 0.8
	game.draw_rect(Rect2(65, 72, 46, 20), Color(1.0, 0.5, 0.2, fire_pulse))
	# Fire glow
	game.draw_circle(Vector2(88, 82), 18, Color(1.0, 0.7, 0.3, fire_pulse * 0.4))

	# Display case/counter using TilesetHouse
	if game.tex_house_tileset:
		# Wooden counter from TilesetHouse
		var counter_src = Rect2(320, 64, 48, 32)
		for i in range(4):
			game.draw_texture_rect_region(game.tex_house_tileset, Rect2(180 + i * 45, 105, 48, 36), counter_src)
	else:
		game.draw_rect(Rect2(200, 110, 150, 50), Color(0.5, 0.4, 0.3))

	# Bread loaves on display (drawn as ovals)
	for i in range(4):
		var bread_x = 205 + i * 38
		var bread_y = 118
		# Bread shadow
		game.draw_ellipse_shape(Vector2(bread_x + 2, bread_y + 8), Vector2(14, 7), Color(0.3, 0.2, 0.1, 0.4))
		# Bread loaf
		game.draw_ellipse_shape(Vector2(bread_x, bread_y + 4), Vector2(13, 8), Color(0.8, 0.55, 0.3))
		# Bread highlight
		game.draw_ellipse_shape(Vector2(bread_x - 2, bread_y + 1), Vector2(8, 4), Color(0.9, 0.7, 0.45))

	# Sacks of flour using barrels/crates from TilesetHouse
	if game.tex_house_tileset:
		var sack_src = Rect2(448, 96, 16, 16)  # Use barrel/sack sprite
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(380, 60, 36, 36), sack_src)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(415, 70, 32, 32), sack_src)

	# Draw baker NPC
	game.draw_robot_npc(game.interior_npc_pos.x, game.interior_npc_pos.y, "baker")

	# Door
	if game.tex_house_tileset:
		var door_src = Rect2(128, 32, 32, 32)
		game.draw_texture_rect_region(game.tex_house_tileset, Rect2(200, 275, 80, 45), door_src)
	else:
		game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))

	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_interior_kaido(game.interior_kaido_pos)

	# Title
	game.draw_rect(Rect2(195, 5, 90, 25), Color(0, 0, 0, 0.6))
	game.draw_string(ThemeDB.fallback_font, Vector2(215, 22), "BAKERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))

	# Prompts
	if not game.in_dialogue:
		if game.interior_near_npc:
			game.draw_rect(Rect2(180, 95, 120, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(180, 95, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(200, 112), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if game.interior_near_exit:
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			game.draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			game.draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))

	if game.in_dialogue:
		game.draw_dialogue_box()
