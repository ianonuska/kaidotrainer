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
	game.draw_rect(Rect2(0, 0, 480, 320), Color(0.12, 0.1, 0.08))
	
	# Metal wall panels
	for i in range(6):
		var panel_x = i * 80
		game.draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.18, 0.16, 0.14))
		game.draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.25, 0.22, 0.2), false, 2)
		for j in range(8):
			game.draw_circle(Vector2(panel_x + 6, 20 + j * 40), 3, Color(0.3, 0.28, 0.25))
			game.draw_circle(Vector2(panel_x + 72, 20 + j * 40), 3, Color(0.3, 0.28, 0.25))
	
	# Pipes
	game.draw_rect(Rect2(20, 0, 8, 320), Color(0.35, 0.32, 0.3))
	game.draw_rect(Rect2(452, 0, 8, 320), Color(0.35, 0.32, 0.3))
	game.draw_rect(Rect2(0, 160, 480, 6), Color(0.32, 0.3, 0.28))
	
	# Warning stripes
	for i in range(16):
		var stripe_y = i * 20
		if i % 2 == 0:
			game.draw_rect(Rect2(0, stripe_y, 15, 20), Color(0.8, 0.6, 0.1))
			game.draw_rect(Rect2(465, stripe_y, 15, 20), Color(0.8, 0.6, 0.1))
		else:
			game.draw_rect(Rect2(0, stripe_y, 15, 20), Color(0.15, 0.12, 0.1))
			game.draw_rect(Rect2(465, stripe_y, 15, 20), Color(0.15, 0.12, 0.1))
	
	# Platforms
	for platform in game.tower_platforms:
		var px = platform.x
		var py = platform.y
		var pw = platform.w
		
		game.draw_rect(Rect2(px + 3, py + 3, pw, 14), Color(0, 0, 0, 0.3))
		game.draw_rect(Rect2(px - 2, py - 2, pw + 4, 16), Color(0.0, 0.0, 0.0))
		game.draw_rect(Rect2(px, py, pw, 12), Color(0.4, 0.38, 0.35))
		game.draw_rect(Rect2(px, py, pw, 4), Color(0.5, 0.48, 0.45))
		
		for j in range(int(pw / 12)):
			game.draw_line(Vector2(px + 6 + j * 12, py + 2), Vector2(px + 6 + j * 12, py + 10), Color(0.3, 0.28, 0.25), 2)
		
		game.draw_circle(Vector2(px + 5, py + 6), 3, Color(0.55, 0.5, 0.45))
		game.draw_circle(Vector2(px + pw - 5, py + 6), 3, Color(0.55, 0.5, 0.45))
	
	# Radio equipment at top
	game.draw_rect(Rect2(165, 20, 150, 35), Color(0.0, 0.0, 0.0))
	game.draw_rect(Rect2(167, 22, 146, 31), Color(0.25, 0.28, 0.32))
	game.draw_rect(Rect2(175, 28, 50, 20), Color(0.15, 0.15, 0.18))
	game.draw_rect(Rect2(180, 32, 15, 12), Color(0.1, 0.4, 0.2))
	game.draw_circle(Vector2(210, 38), 6, Color(0.35, 0.32, 0.3))
	game.draw_circle(Vector2(210, 38), 4, Color(0.45, 0.42, 0.4))
	game.draw_rect(Rect2(235, 30, 8, 15), Color(0.5, 0.2, 0.2))
	game.draw_rect(Rect2(250, 30, 8, 15), Color(0.2, 0.5, 0.2))
	game.draw_rect(Rect2(265, 30, 8, 15), Color(0.5, 0.5, 0.2))
	game.draw_rect(Rect2(285, 25, 20, 8), Color(0.4, 0.38, 0.35))
	game.draw_rect(Rect2(295, 10, 6, 20), Color(0.5, 0.45, 0.4))
	
	if game.tower_reached_top:
		var glow = sin(game.continuous_timer * 3) * 0.3 + 0.7
		game.draw_circle(Vector2(295, 8), 6, Color(0.3, 1.0, 0.5, glow))
		game.draw_circle(Vector2(295, 8), 3, Color(0.8, 1.0, 0.9, glow))
	
	# Player
	draw_tower_player_combat_style()
	
	# HUD
	game.draw_rect(Rect2(10, 10, 180, 30), Color(0.08, 0.08, 0.1, 0.9))
	game.draw_rect(Rect2(10, 10, 180, 30), Color(0.4, 0.5, 0.6, 0.6), false, 2)
	
	var height_pct = 1.0 - (game.tower_player_pos.y - 50) / 240.0
	height_pct = clamp(height_pct, 0.0, 1.0)
	
	game.draw_rect(Rect2(20, 18, 100, 14), Color(0.15, 0.15, 0.18))
	game.draw_rect(Rect2(20, 18, 100 * height_pct, 14), Color(0.3, 0.7, 0.5))
	game.draw_string(ThemeDB.fallback_font, Vector2(130, 30), str(int(height_pct * 100)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 0.85))
	
	if game.tower_reached_top:
		game.draw_string(ThemeDB.fallback_font, Vector2(200, 28), "[X] Access Radio", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 1.0, 0.7))
	
	if game.tower_player_pos.y > 260:
		game.draw_rect(Rect2(175, 290, 130, 25), Color(0.08, 0.08, 0.1, 0.9))
		game.draw_string(ThemeDB.fallback_font, Vector2(185, 308), "[O] Exit Tower", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.65))
	
	game.draw_rect(Rect2(320, 290, 150, 25), Color(0.08, 0.08, 0.1, 0.9))
	game.draw_string(ThemeDB.fallback_font, Vector2(330, 308), "[X] Jump  ^v Climb", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.45))
	
	if game.in_dialogue and not game.current_dialogue.is_empty():
		game.draw_dialogue_box()

func draw_tower_player_combat_style():
	var pos = game.tower_player_pos
	var scale_factor = 1.8
	
	# Use new animation system if available
	if game.player_anim_loaded:
		var tex: Texture2D = null
		var frame = game.player_frame % 6
		
		if not game.tower_player_grounded:
			# Jumping - use mid-walk frame
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
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.08, 0.1))
			game.draw_rect(Rect2(140, 80, 200, 160), Color(0.05, 0.05, 0.08))
			game.draw_string(ThemeDB.fallback_font, Vector2(170, 180), "ENTERING TUNNEL...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))
		1:
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.15, 0.08, 0.05))
			for i in range(5):
				var fx = 80 + i * 80
				var fy = 100 + sin(game.anim_timer * 2 + i) * 20
				game.draw_circle(Vector2(fx, fy), 30, Color(1.0, 0.5, 0.2, 0.4))
				game.draw_circle(Vector2(fx, fy - 10), 20, Color(1.0, 0.7, 0.3, 0.3))
			game.draw_string(ThemeDB.fallback_font, Vector2(140, 280), "Agricommune burns...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.7, 0.5))
		2:
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.1, 0.08, 0.12))
			game.draw_circle(Vector2(240, 150), 30, Color(0.5, 0.35, 0.5, 0.6))
			game.draw_robot_soldier(Vector2(180, 160))
			game.draw_robot_soldier(Vector2(300, 160))
			game.draw_string(ThemeDB.fallback_font, Vector2(130, 280), "Grandmother is captured.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.5, 0.5))
		3:
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.05, 0.08))
			game.draw_rect(Rect2(200, 130, 80, 30), Color(0.5, 0.5, 0.55))
			game.draw_rect(Rect2(280, 135, 15, 20), Color(0.6, 0.6, 0.65))
			game.draw_circle(Vector2(240, 145), 10, Color(0.3, 0.8, 0.7, 0.6))
			game.draw_string(ThemeDB.fallback_font, Vector2(150, 200), "\"Find Professor Ohm.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 0.75))
			game.draw_string(ThemeDB.fallback_font, Vector2(150, 230), "\"Show him this.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 0.75))
		4:
			game.draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.1, 0.12))
			game.draw_rect(Rect2(100, 60, 280, 200), Color(0.12, 0.14, 0.16))
			game.draw_rect(Rect2(140, 90, 200, 140), Color(0.1, 0.12, 0.14))
			for i in range(5):
				var sx = 180 + i * 25
				var sy = 180 + i * 5
				game.draw_rect(Rect2(sx, sy - 20, 8, 22), Color(0.3, 0.3, 0.35))
				game.draw_circle(Vector2(sx + 4, sy - 25), 5, Color(0.35, 0.35, 0.4))
			game.draw_circle(Vector2(300, 160), 12, Color(0.3, 0.75, 0.7))
			game.draw_string(ThemeDB.fallback_font, Vector2(140, 290), "To New Sumida City...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.8, 0.75))

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
	var skills = ["LED Basics", "Buttons & Switches", "Logic Gates (NOT, OR)", "Light Sensors", "Series Circuits"]
	var sy = 198
	for skill in skills:
		game.draw_string(ThemeDB.fallback_font, Vector2(170, sy), "- " + skill, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6))
		sy += 15
	
	game.draw_string(ThemeDB.fallback_font, Vector2(140, 280), "NEXT: New Sumida City", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.85, 0.8))

# ===========================================
# SHOP INTERIOR
# ===========================================

func draw_shop_interior():
	var floor_color = Color(0.55, 0.45, 0.35)
	var wall_color = Color(0.75, 0.65, 0.55)
	var shelf_color = Color(0.5, 0.38, 0.28)
	
	game.draw_rect(Rect2(0, 0, 480, 320), wall_color)
	game.draw_rect(Rect2(0, 150, 480, 170), floor_color)
	
	for i in range(14):
		game.draw_line(Vector2(0, 150 + i * 12), Vector2(480, 150 + i * 12), Color(0.45, 0.38, 0.28), 1)
	
	# Shelves
	for row in range(2):
		var shelf_y = 40 + row * 50
		game.draw_rect(Rect2(30, shelf_y, 180, 8), shelf_color)
		game.draw_rect(Rect2(270, shelf_y, 180, 8), shelf_color)
		for i in range(5):
			var item_x = 40 + i * 35
			var hue1 = fmod(i * 0.15 + row * 0.3, 1.0)
			var hue2 = fmod(i * 0.2 + row * 0.25, 1.0)
			game.draw_rect(Rect2(item_x, shelf_y - 20, 15, 20), Color.from_hsv(hue1, 0.4, 0.7))
			game.draw_rect(Rect2(item_x + 240, shelf_y - 20, 15, 20), Color.from_hsv(hue2, 0.4, 0.7))
	
	# Counter
	game.draw_rect(Rect2(160, 130, 160, 30), Color(0.45, 0.35, 0.28))
	game.draw_rect(Rect2(160, 125, 160, 8), Color(0.55, 0.42, 0.32))
	
	game.draw_robot_npc(game.interior_npc_pos.x, game.interior_npc_pos.y, "shop")
	
	# Door
	game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	game.draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	
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
	var floor_color = Color(0.45, 0.42, 0.4)
	var wall_color = Color(0.65, 0.6, 0.55)
	var pillar_color = Color(0.55, 0.52, 0.48)
	
	game.draw_rect(Rect2(0, 0, 480, 320), wall_color)
	game.draw_rect(Rect2(0, 150, 480, 170), floor_color)
	
	# Checkered floor
	for i in range(12):
		for j in range(5):
			if (i + j) % 2 == 0:
				game.draw_rect(Rect2(i * 40, 150 + j * 34, 40, 34), Color(0.4, 0.38, 0.35))
	
	# Pillars
	game.draw_rect(Rect2(50, 50, 30, 120), pillar_color)
	game.draw_rect(Rect2(400, 50, 30, 120), pillar_color)
	
	# Banner
	game.draw_rect(Rect2(200, 20, 80, 80), Color(0.7, 0.2, 0.2))
	game.draw_circle(Vector2(240, 60), 25, Color(0.9, 0.85, 0.3))
	
	# Mayor's desk
	game.draw_rect(Rect2(180, 110, 120, 40), Color(0.4, 0.3, 0.22))
	game.draw_rect(Rect2(180, 105, 120, 8), Color(0.5, 0.38, 0.28))
	
	game.draw_mayor_npc(game.interior_npc_pos.x, game.interior_npc_pos.y)
	
	# Door
	game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	game.draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	
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
	var floor_color = Color(0.6, 0.5, 0.4)
	var wall_color = Color(0.85, 0.75, 0.65)
	
	game.draw_rect(Rect2(0, 0, 480, 320), wall_color)
	game.draw_rect(Rect2(0, 150, 480, 170), floor_color)
	game.draw_rect(Rect2(0, 0, 480, 320), Color(1.0, 0.9, 0.7, 0.1))
	
	# Brick oven
	game.draw_rect(Rect2(50, 50, 100, 70), Color(0.6, 0.35, 0.25))
	game.draw_rect(Rect2(70, 70, 60, 35), Color(0.2, 0.1, 0.05))
	var fire_pulse = sin(game.continuous_timer * 5) * 0.2 + 0.8
	game.draw_rect(Rect2(75, 78, 50, 22), Color(1.0, 0.5, 0.2, fire_pulse))
	
	# Display case
	game.draw_rect(Rect2(200, 110, 150, 50), Color(0.5, 0.4, 0.3))
	game.draw_rect(Rect2(205, 105, 140, 10), Color(0.6, 0.5, 0.4))
	for i in range(4):
		game.draw_ellipse_shape(Vector2(230 + i * 30, 130), Vector2(12, 8), Color(0.75, 0.55, 0.35))
	
	game.draw_robot_npc(game.interior_npc_pos.x, game.interior_npc_pos.y, "baker")
	
	# Door
	game.draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	game.draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Kaido and player Y-sorted
	if game.interior_kaido_pos.y < game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	game.draw_interior_player(game.interior_player_pos)
	if game.interior_kaido_pos.y >= game.interior_player_pos.y:
		game.draw_kaido(game.interior_kaido_pos)
	
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
