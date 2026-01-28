extends RefCounted
# UIDrawing.gd - User interface rendering functions
# Usage: var ui = UIDrawing.new(self) in _ready(), then ui.draw_X() in _draw()

var game  # Reference to main game script for state access
var canvas: CanvasItem

func _init(game_ref):
	game = game_ref
	canvas = game_ref

# ===========================================
# PROMPTS
# ===========================================

func draw_prompt(text: String):
	var prompt = "[X] " + text
	var w = prompt.length() * 8 + 16
	var px = 240 - w / 2
	canvas.draw_rect(Rect2(px, 272, w, 24), Color(0, 0, 0, 0.8))
	canvas.draw_rect(Rect2(px, 272, w, 24), Color(0.3, 0.75, 0.68), false, 2)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(px + 8, 290), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

# ===========================================
# HELP METER (Battery Style)
# ===========================================

func draw_help_meter():
	var bx = 38  # To the right of backpack
	var by = 10
	var bw = 60  # Battery width
	var bh = 22  # Battery height
	
	# Battery outline
	canvas.draw_rect(Rect2(bx, by, bw, bh), Color(0.15, 0.2, 0.25))
	canvas.draw_rect(Rect2(bx, by, bw, bh), Color(0.3, 0.7, 0.8), false, 2)
	
	# Battery terminal (right nub)
	canvas.draw_rect(Rect2(bx + bw, by + 6, 4, 10), Color(0.3, 0.7, 0.8))
	
	# Inner fill area
	var inner_margin = 3
	var inner_w = bw - inner_margin * 2
	var inner_h = bh - inner_margin * 2
	var fill_pct = game.help_meter / game.help_meter_max
	var fill_w = int(inner_w * fill_pct)
	
	# Background of empty area
	canvas.draw_rect(Rect2(bx + inner_margin, by + inner_margin, inner_w, inner_h), Color(0.08, 0.12, 0.15))
	
	# Fill color based on level (teal to electric blue gradient feel)
	var fill_color = Color(0.2, 0.8, 0.85)  # Electric blue/teal
	if fill_pct < 0.3:
		fill_color = Color(0.9, 0.3, 0.3)  # Red when low
	elif fill_pct < 0.6:
		fill_color = Color(0.9, 0.7, 0.2)  # Yellow/orange when medium
	
	# Draw segmented battery fill (4 segments)
	var segment_count = 4
	var segment_w = (inner_w - 3) / segment_count
	var segments_filled = int(fill_pct * segment_count + 0.5)
	
	for i in range(segments_filled):
		var seg_x = bx + inner_margin + i * (segment_w + 1)
		canvas.draw_rect(Rect2(seg_x, by + inner_margin, segment_w, inner_h), fill_color)
		# Add highlight to each segment
		canvas.draw_rect(Rect2(seg_x, by + inner_margin, segment_w, 3), Color(1, 1, 1, 0.2))
	
	# Small lightning bolt icon inside
	var lx = bx + 4
	var ly = by + 5
	canvas.draw_line(Vector2(lx + 6, ly), Vector2(lx + 2, ly + 6), Color(1, 1, 1, 0.4), 2)
	canvas.draw_line(Vector2(lx + 2, ly + 6), Vector2(lx + 6, ly + 6), Color(1, 1, 1, 0.4), 2)
	canvas.draw_line(Vector2(lx + 6, ly + 6), Vector2(lx + 2, ly + 12), Color(1, 1, 1, 0.4), 2)

# ===========================================
# QUEST BOX (Top-Right)
# ===========================================

func draw_quest_box():
	if game.current_quest == "":
		return
	
	var w = min(game.current_quest.length() * 7 + 16, 180)
	var base_x = 472 - w
	var base_y = 8  # Top right
	
	var bounce_offset = 0.0
	var text_color = Color(0.5, 0.95, 0.88)
	var border_color = Color(0.2, 0.5, 0.55)
	var bg_color = Color(0.05, 0.1, 0.12, 0.9)
	
	if game.quest_is_new:
		bounce_offset = sin(game.quest_anim_timer * 12) * 2
		text_color = Color(1.0, 0.95, 0.6)
		border_color = Color(0.4, 0.8, 0.75)
	
	var box_y = base_y + bounce_offset
	
	# Rounded-ish box (Minish Cap style)
	canvas.draw_rect(Rect2(base_x, box_y, w, 22), bg_color)
	canvas.draw_rect(Rect2(base_x, box_y, w, 22), border_color, false, 2)
	
	# Small diamond/arrow indicator
	canvas.draw_rect(Rect2(base_x + 4, box_y + 7, 6, 6), text_color)
	
	canvas.draw_string(ThemeDB.fallback_font, Vector2(base_x + 14, box_y + 16), game.current_quest, HORIZONTAL_ALIGNMENT_LEFT, w - 18, 11, text_color)

# ===========================================
# BACKPACK ICON (Top-Left Corner)
# ===========================================

func draw_backpack_icon():
	var bx = 10  # Top left corner
	var by = 8
	
	# Cleaner backpack shape
	canvas.draw_rect(Rect2(bx, by + 3, 22, 18), Color(0.65, 0.25, 0.2))
	canvas.draw_rect(Rect2(bx + 2, by + 5, 18, 14), Color(0.8, 0.35, 0.28))
	canvas.draw_rect(Rect2(bx + 6, by, 10, 5), Color(0.6, 0.22, 0.18))
	canvas.draw_rect(Rect2(bx + 7, by + 10, 8, 6), Color(0.55, 0.2, 0.15))
	
	# Gadget count badge
	if game.gadgets.size() > 0:
		canvas.draw_circle(Vector2(bx + 20, by + 4), 7, Color(0.2, 0.6, 0.55))
		canvas.draw_string(ThemeDB.fallback_font, Vector2(bx + 16, by + 8), str(game.gadgets.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

# ===========================================
# LOCATION INDICATOR (Top-Right, under objective)
# ===========================================

func draw_area_indicator():
	var area_name = ""
	match game.current_area:
		game.Area.FARM: area_name = "FARM"
		game.Area.CORNFIELD: area_name = "CORNFIELD"
		game.Area.LAKESIDE: area_name = "LAKESIDE"
		game.Area.TOWN_CENTER: area_name = "TOWN"
	
	var w = area_name.length() * 7 + 8
	var ax = 472 - w  # Right-aligned under quest box
	var ay = 34  # Below quest box
	
	# Light blue text, minimal background
	canvas.draw_rect(Rect2(ax, ay, w, 18), Color(0.05, 0.1, 0.15, 0.8))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(ax + 4, ay + 13), area_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.85, 1.0))

# ===========================================
# EQUIPPED GADGET (Top-Left, under backpack)
# ===========================================

func draw_equipped_gadget_indicator():
	if game.equipped_gadget == "":
		return

	var gx = 10  # Left side
	var gy = 36  # Below backpack

	# Pill-shaped slot (Minish Cap style)
	canvas.draw_rect(Rect2(gx, gy, 30, 26), Color(0.05, 0.1, 0.12, 0.9))
	canvas.draw_rect(Rect2(gx, gy, 30, 26), Color(0.2, 0.5, 0.55), false, 2)

	# Use actual texture sprites like the backpack
	var tex: Texture2D = null
	match game.equipped_gadget:
		"led_lamp", "flashlight":
			tex = game.tex_gadget_flashlight
		"dimmer":
			tex = game.tex_gadget_dimmer
		"led_chain":
			tex = game.tex_gadget_led_chain
		"light_sensor":
			tex = game.tex_gadget_light_sensor
		"buzzer_alarm":
			tex = game.tex_gadget_buzzer

	if tex:
		var tex_w = tex.get_width()
		var tex_h = tex.get_height()
		var slot_size = 20  # Available space in slot
		var scale_factor = min(float(slot_size) / tex_w, float(slot_size) / tex_h)
		var draw_w = tex_w * scale_factor
		var draw_h = tex_h * scale_factor
		var cx = gx + 15  # Center of slot
		var cy = gy + 13
		var dest = Rect2(cx - draw_w/2, cy - draw_h/2, draw_w, draw_h)
		canvas.draw_texture_rect(tex, dest, false)
	else:
		# Fallback - draw a simple flashlight icon
		var icon_color = Color(0.5, 0.95, 0.88)
		if game.equipped_gadget == "led_lamp":
			# Flashlight shape
			canvas.draw_rect(Rect2(gx + 10, gy + 4, 10, 14), icon_color)
			canvas.draw_rect(Rect2(gx + 8, gy + 14, 14, 6), icon_color)
		else:
			draw_gadget_mini_icon(game.equipped_gadget, gx + 5, gy + 4, icon_color)

	# R1 label
	canvas.draw_string(ThemeDB.fallback_font, Vector2(gx + 32, gy + 17), "R1", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.65, 0.6))

# ===========================================
# COLLECTIBLES (Top-Left, under gadget)
# ===========================================

func draw_journal_indicator():
	if game.journal_pages_found.is_empty():
		return
	
	var jx = 10
	var jy = 66  # Below gadget
	
	# Small journal icon
	canvas.draw_rect(Rect2(jx, jy, 14, 16), Color(0.85, 0.78, 0.6))
	canvas.draw_rect(Rect2(jx + 2, jy + 2, 10, 12), Color(0.95, 0.9, 0.75))
	for i in range(2):
		canvas.draw_line(Vector2(jx + 4, jy + 5 + i * 4), Vector2(jx + 10, jy + 5 + i * 4), Color(0.5, 0.45, 0.4), 1)
	
	# Count
	canvas.draw_string(ThemeDB.fallback_font, Vector2(jx + 16, jy + 12), str(game.journal_pages_found.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.75, 0.5))

func draw_relics_indicator():
	if game.relics_found.is_empty():
		return
	
	var rx = 10
	var ry = 86  # Below journal
	
	# Gear/relic icon
	canvas.draw_circle(Vector2(rx + 7, ry + 8), 7, Color(0.55, 0.45, 0.3))
	canvas.draw_circle(Vector2(rx + 7, ry + 8), 4, Color(0.35, 0.3, 0.22))
	
	# Count
	canvas.draw_string(ThemeDB.fallback_font, Vector2(rx + 16, ry + 12), str(game.relics_found.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.6, 0.4))

# ===========================================
# FARADAY CREDITS (Bottom-right, clean)
# ===========================================

func draw_faraday_credits():
	if game.faraday_credits <= 0:
		return
	
	var fx = 400
	var fy = 298
	
	# Small lightning bolt icon
	canvas.draw_line(Vector2(fx, fy + 2), Vector2(fx + 6, fy + 8), Color(0.3, 0.8, 0.9), 2)
	canvas.draw_line(Vector2(fx + 6, fy + 8), Vector2(fx + 3, fy + 8), Color(0.3, 0.8, 0.9), 2)
	canvas.draw_line(Vector2(fx + 3, fy + 8), Vector2(fx + 9, fy + 14), Color(0.3, 0.8, 0.9), 2)
	
	# Credit count
	canvas.draw_string(ThemeDB.fallback_font, Vector2(fx + 14, fy + 13), str(game.faraday_credits), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.9, 0.95))

func draw_gadget_mini_icon(gadget_id: String, x: float, y: float, icon_color: Color):
	match gadget_id:
		"led_lamp":
			canvas.draw_rect(Rect2(x + 6, y + 2, 8, 16), icon_color)
			canvas.draw_rect(Rect2(x + 4, y + 14, 12, 4), icon_color)
		"dimmer":
			canvas.draw_rect(Rect2(x + 4, y + 6, 12, 8), icon_color)
			canvas.draw_circle(Vector2(x + 18, y + 10), 3, icon_color)
		"led_chain":
			for i in range(3):
				canvas.draw_circle(Vector2(x + 4 + i * 6, y + 10), 3, icon_color)
		"or_gate":
			canvas.draw_rect(Rect2(x + 2, y + 4, 8, 5), icon_color)
			canvas.draw_rect(Rect2(x + 2, y + 11, 8, 5), icon_color)
			canvas.draw_rect(Rect2(x + 10, y + 7, 8, 6), icon_color)
		"tractor_sensor":
			canvas.draw_rect(Rect2(x + 4, y + 4, 12, 10), icon_color)
			canvas.draw_rect(Rect2(x + 8, y + 14, 4, 4), icon_color)
		"buzzer_alarm":
			canvas.draw_circle(Vector2(x + 10, y + 10), 6, icon_color)
			canvas.draw_circle(Vector2(x + 10, y + 10), 3, icon_color.darkened(0.3))
		"light_sensor":
			canvas.draw_circle(Vector2(x + 10, y + 10), 7, icon_color)
			canvas.draw_rect(Rect2(x + 7, y + 7, 6, 6), icon_color.darkened(0.2))

# ===========================================
# AWARENESS BAR (Stealth)
# ===========================================

func draw_awareness_bar():
	var bar_width = 100
	var bar_height = 8
	var bar_x = 240 - bar_width / 2
	var bar_y = 30
	
	canvas.draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4), Color(0, 0, 0, 0.8))
	
	var fill_width = (game.awareness_level / 100.0) * bar_width
	var bar_color = Color(0.3, 0.8, 0.3)
	if game.awareness_level > 50:
		bar_color = Color(0.9, 0.7, 0.2)
	if game.awareness_level > 80:
		bar_color = Color(0.9, 0.3, 0.3)
	
	canvas.draw_rect(Rect2(bar_x, bar_y, fill_width, bar_height), bar_color)
	canvas.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.5, 0.5, 0.5), false, 1)
	
	# Eye icon
	canvas.draw_circle(Vector2(bar_x - 15, bar_y + 4), 6, Color(0.8, 0.8, 0.8))
	canvas.draw_circle(Vector2(bar_x - 15, bar_y + 4), 3, Color(0.2, 0.2, 0.2))

func draw_detection_overlay():
	var flash = fmod(game.continuous_timer * 4, 1.0)
	if flash < 0.5:
		canvas.draw_rect(Rect2(0, 0, 480, 320), Color(1, 0, 0, 0.3))
	
	canvas.draw_string(ThemeDB.fallback_font, Vector2(180, 160), "DETECTED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

# ===========================================
# SCHEMATIC POPUP
# ===========================================

func draw_schematic_popup():
	var alpha = 0.95

	# Dim background
	canvas.draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.7))

	# Popup box - larger to fit schematic properly
	var popup_x = 40
	var popup_y = 15
	var popup_w = 400
	var popup_h = 290
	canvas.draw_rect(Rect2(popup_x, popup_y, popup_w, popup_h), Color(0.12, 0.15, 0.18, alpha))
	canvas.draw_rect(Rect2(popup_x, popup_y, popup_w, popup_h), Color(0.3, 0.75, 0.68, alpha), false, 3)

	# Title at top
	var data = game.gadget_data.get(game.current_schematic, {})
	var title = data.get("name", "").to_upper() + " - " + data.get("circuit", "")
	canvas.draw_string(ThemeDB.fallback_font, Vector2(popup_x + 15, popup_y + 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.95, 0.88))

	# Schematic image - centered in upper portion
	var schematic_y = popup_y + 32
	game.draw_breadboard_schematic(popup_x + 20, schematic_y, game.current_schematic)

	# Components list - positioned below schematic area (schematic max height is 160)
	var components = data.get("components", [])
	var cy = popup_y + 200  # Fixed position well below schematic
	canvas.draw_string(ThemeDB.fallback_font, Vector2(popup_x + 20, cy), "Components:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.95, 0.88))
	cy += 16
	for comp in components:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(popup_x + 28, cy), "- " + comp, HORIZONTAL_ALIGNMENT_LEFT, 340, 10, Color(0.7, 0.7, 0.7))
		cy += 13

	# Bottom prompt - clear action
	canvas.draw_string(ThemeDB.fallback_font, Vector2(popup_x + 130, popup_y + popup_h - 18), "[X] Close and Build", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.7, 0.6))

# ===========================================
# COMPONENT POPUP
# ===========================================

func draw_component_popup():
	var alpha = clamp(game.component_popup_timer / 0.3, 0.0, 1.0)
	
	canvas.draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.5 * alpha))
	
	var popup_y = 80 + (1.0 - alpha) * 50
	canvas.draw_rect(Rect2(90, popup_y, 300, 160), Color(0.12, 0.15, 0.18, alpha))
	canvas.draw_rect(Rect2(90, popup_y, 300, 160), Color(0.3, 0.75, 0.68, alpha), false, 3)
	
	var comp = game.component_popup_data
	canvas.draw_string(ThemeDB.fallback_font, Vector2(110, popup_y + 30), comp.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 0.95, 0.88, alpha))
	
	var desc_lines = game.wrap_text(comp.get("desc", ""), 38)
	var dy = popup_y + 55
	for line in desc_lines:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(110, dy), line, HORIZONTAL_ALIGNMENT_LEFT, 280, 12, Color(0.8, 0.8, 0.8, alpha))
		dy += 16
	
	canvas.draw_string(ThemeDB.fallback_font, Vector2(170, popup_y + 140), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5, alpha))

# ===========================================
# BACKPACK POPUP
# ===========================================

func draw_backpack_popup():
	var alpha = clamp(game.backpack_anim, 0.0, 1.0)

	canvas.draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.7 * alpha))

	var popup_y = 20 + (1.0 - alpha) * 40
	canvas.draw_rect(Rect2(60, popup_y, 360, 280), Color(0.08, 0.1, 0.12, alpha))
	canvas.draw_rect(Rect2(60, popup_y, 360, 280), Color(0.3, 0.75, 0.68, alpha), false, 3)

	# Tabs
	var tabs = ["GADGETS", "LOOT", "MAP"]
	for i in range(tabs.size()):
		var tab_x = 70 + i * 90
		var is_selected = (game.backpack_tab == i)
		var tab_color = Color(0.2, 0.5, 0.45, alpha) if is_selected else Color(0.15, 0.18, 0.2, alpha)
		canvas.draw_rect(Rect2(tab_x, popup_y + 8, 75, 24), tab_color)
		var text_color = Color(0.5, 0.95, 0.88, alpha) if is_selected else Color(0.4, 0.4, 0.4, alpha)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(tab_x + 8, popup_y + 25), tabs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)

	# Content
	if game.backpack_tab == 0:
		game.draw_backpack_gadgets_tab(popup_y, alpha)
	elif game.backpack_tab == 1:
		game.draw_backpack_loot_tab(popup_y, alpha)
	else:
		game.draw_backpack_map_tab(popup_y, alpha)

	# Show appropriate hint based on tab
	var hint_text = "[L1/R1] Tab  [O] Close"
	if game.backpack_tab == 0:  # Gadgets tab
		hint_text = "[D-Pad] Move  [X] Equip  [O] Close"
	elif game.backpack_tab == 1:  # Loot tab
		hint_text = "[D-Pad] Move  [X] Select  [O] Close"
	else:  # Map tab
		hint_text = "[L1/R1] Tab  [O] Close"
	canvas.draw_string(ThemeDB.fallback_font, Vector2(135, popup_y + 260), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.4, alpha))

# ===========================================
# GADGET & LOOT ICONS
# ===========================================

func draw_gadget_icon(sx: float, sy: float, size: float, gadget_id: String, alpha: float):
	var cx = sx + size / 2
	var cy = sy + size / 2
	
	# Check for texture first
	var tex: Texture2D = null
	match gadget_id:
		"led_lamp", "flashlight":
			tex = game.tex_gadget_flashlight
		"dimmer":
			tex = game.tex_gadget_dimmer
		"led_chain":
			tex = game.tex_gadget_led_chain
		"light_sensor":
			tex = game.tex_gadget_light_sensor
		"buzzer_alarm":
			tex = game.tex_gadget_buzzer

	# If texture exists, draw it
	if tex:
		var tex_w = tex.get_width()
		var tex_h = tex.get_height()
		# Center the texture in the slot, scale to fit
		var scale_factor = min((size - 8) / tex_w, (size - 8) / tex_h)
		var draw_w = tex_w * scale_factor
		var draw_h = tex_h * scale_factor
		var dest = Rect2(cx - draw_w/2, cy - draw_h/2, draw_w, draw_h)
		canvas.draw_texture_rect(tex, dest, false, Color(1, 1, 1, alpha))
		return
	
	# Fallback to procedural drawing
	match gadget_id:
		"led_lamp":
			canvas.draw_rect(Rect2(sx + 12, sy + 4, 20, 38), Color(0.5, 0.5, 0.55, alpha))
			canvas.draw_rect(Rect2(sx + 8, sy + 36, 28, 10), Color(0.45, 0.45, 0.5, alpha))
			canvas.draw_circle(Vector2(cx, sy + 8), 8, Color(1, 0.95, 0.7, alpha * 0.8))
		"dimmer":
			canvas.draw_rect(Rect2(sx + 8, sy + 14, 24, 18), Color(0.3, 0.3, 0.35, alpha))
			canvas.draw_circle(Vector2(sx + 36, sy + 23), 5, Color(0.5, 0.5, 0.55, alpha))
		"led_chain":
			for i in range(3):
				var lx = sx + 8 + i * 14
				canvas.draw_circle(Vector2(lx + 6, cy), 6, Color(0.9, 0.3, 0.3, alpha))
		"or_gate":
			canvas.draw_rect(Rect2(sx + 6, sy + 8, 16, 12), Color(0.3, 0.3, 0.35, alpha))
			canvas.draw_rect(Rect2(sx + 6, sy + 26, 16, 12), Color(0.3, 0.3, 0.35, alpha))
			canvas.draw_rect(Rect2(sx + 22, sy + 15, 18, 16), Color(0.4, 0.4, 0.45, alpha))
		"tractor_sensor":
			canvas.draw_rect(Rect2(sx + 8, sy + 10, 30, 25), Color(0.6, 0.5, 0.35, alpha))
			canvas.draw_rect(Rect2(sx + 12, sy + 14, 22, 17), Color(0.75, 0.65, 0.45, alpha))
		"buzzer_alarm":
			canvas.draw_circle(Vector2(cx, cy), 16, Color(0.3, 0.3, 0.35, alpha))
			canvas.draw_circle(Vector2(cx, cy), 10, Color(0.4, 0.4, 0.45, alpha))

func draw_loot_icon(sx: float, sy: float, size: float, item: String, alpha: float):
	var cx = sx + size / 2
	var cy = sy + size / 2
	var info = game.get_loot_info(item)
	var color = info.get("color", Color(0.5, 0.5, 0.5))
	
	match info.get("type", "misc"):
		"component":
			canvas.draw_rect(Rect2(sx + 8, sy + 8, size - 16, size - 16), Color(color.r, color.g, color.b, alpha))
		"key":
			canvas.draw_rect(Rect2(sx + 16, sy + 8, 12, 20), Color(color.r, color.g, color.b, alpha))
			canvas.draw_circle(Vector2(cx, sy + 32), 8, Color(color.r, color.g, color.b, alpha))
		"ticket":
			# Ticket shape - rectangle with notched edges
			canvas.draw_rect(Rect2(sx + 6, sy + 12, size - 12, size - 24), Color(color.r, color.g, color.b, alpha))
			# Perforated edge indicators
			for i in range(3):
				canvas.draw_circle(Vector2(sx + 6, sy + 18 + i * 8), 2, Color(0.1, 0.1, 0.12, alpha))
				canvas.draw_circle(Vector2(sx + size - 6, sy + 18 + i * 8), 2, Color(0.1, 0.1, 0.12, alpha))
			# Boxing glove icon on ticket
			canvas.draw_circle(Vector2(cx, cy), 6, Color(0.8, 0.25, 0.2, alpha))
		_:
			canvas.draw_circle(Vector2(cx, cy), size / 3, Color(color.r, color.g, color.b, alpha))

# ===========================================
# PAUSE MENU
# ===========================================

func draw_pause_menu():
	game.pause_kaido_bob = sin(game.continuous_timer * 2.0) * 3.0
	
	canvas.draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.85))
	
	# Title
	canvas.draw_string(ThemeDB.fallback_font, Vector2(180, 40), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 0.95, 0.88))
	
	# Menu options
	var menu_x = 180
	var menu_y = 80
	for i in range(game.pause_menu_options.size()):
		var is_selected = (i == game.pause_menu_selection)
		var text_color = Color(0.5, 0.95, 0.88) if is_selected else Color(0.4, 0.4, 0.4)
		var prefix = "> " if is_selected else "  "
		canvas.draw_string(ThemeDB.fallback_font, Vector2(menu_x, menu_y + i * 30), prefix + game.pause_menu_options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, text_color)
	
	# Controls hint
	canvas.draw_string(ThemeDB.fallback_font, Vector2(150, 290), "[UP/DOWN] Select  [X] Confirm", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 0.35, 0.35))

# ===========================================
# STAMINA BAR
# ===========================================

func draw_stamina_bar(pos: Vector2):
	var bar_width = 60
	var bar_height = 4
	
	# Background
	canvas.draw_rect(Rect2(pos.x, pos.y, bar_width, bar_height), Color(0.15, 0.15, 0.2))
	
	# Stamina fill
	var fill_width = int((game.combat_player_stamina / game.combat_player_max_stamina) * bar_width)
	var stam_color = Color(0.3, 0.7, 0.9) if game.combat_player_stamina > 25 else Color(0.9, 0.5, 0.2)
	if fill_width > 0:
		canvas.draw_rect(Rect2(pos.x, pos.y, fill_width, bar_height), stam_color)
