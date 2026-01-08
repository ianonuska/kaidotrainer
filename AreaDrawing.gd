extends RefCounted
# AreaDrawing.gd - Environment and area drawing functions
# Usage: var area = AreaDrawing.new(self) in _ready(), then area.draw_X() in _draw()

var canvas: CanvasItem

# Sprite textures for environment objects
var tex_tree: Texture2D
var tex_tree_small: Texture2D
var tex_bush: Texture2D
var tex_rock: Texture2D
var tex_flowers: Texture2D
var tex_house: Texture2D
var tex_shed: Texture2D
var tex_well: Texture2D
var tex_fence: Texture2D
var tex_barrel: Texture2D
var tex_bench: Texture2D
var tex_lamp: Texture2D
var tex_fountain: Texture2D
var tex_market_stall: Texture2D
var tex_dock: Texture2D

# Shared textures (loaded by main script, passed in)
var tex_grass_biome: Texture2D
var tex_water: Texture2D
var tex_wooden_house: Texture2D
var tex_fences: Texture2D
var tex_chicken_house: Texture2D

const SPROUT_PATH = "res://Sprout Lands - Sprites - Basic pack/"
const NINJA_PATH = "res://Ninja Adventure - Asset Pack/"
const OBJECTS_PATH = "res://Sprout Lands - Sprites - Basic pack/Objects/"

func _init(canvas_item: CanvasItem):
	canvas = canvas_item
	load_environment_sprites()

func load_environment_sprites():
	# Try to load environment sprites from asset packs
	var paths = {
		"tree": [
			OBJECTS_PATH + "Tree.png",
			NINJA_PATH + "Backgrounds/Tilesets/TilesetNature.png",
			SPROUT_PATH + "Objects/Basic Grass Biom things 1.png"
		],
		"bush": [OBJECTS_PATH + "Bush.png"],
		"rock": [OBJECTS_PATH + "Rock.png"],
		"well": [OBJECTS_PATH + "Well.png"],
		"barrel": [OBJECTS_PATH + "Barrel.png"],
		"bench": [OBJECTS_PATH + "Bench.png"],
		"fence": [SPROUT_PATH + "Tilesets/Fences.png"],
		"shed": [OBJECTS_PATH + "shed.png"],
	}
	
	for key in paths:
		for path in paths[key]:
			if ResourceLoader.exists(path):
				match key:
					"tree": tex_tree = load(path)
					"bush": tex_bush = load(path)
					"rock": tex_rock = load(path)
					"well": tex_well = load(path)
					"barrel": tex_barrel = load(path)
					"bench": tex_bench = load(path)
					"fence": tex_fence = load(path)
					"shed": tex_shed = load(path)
				break

func set_shared_textures(grass_biome: Texture2D, water: Texture2D, wooden_house: Texture2D, fences: Texture2D, chicken_house: Texture2D):
	tex_grass_biome = grass_biome
	tex_water = water
	tex_wooden_house = wooden_house
	tex_fences = fences
	tex_chicken_house = chicken_house

# ===========================================
# TREES
# ===========================================

func draw_tree_large(x: float, y: float):
	# Use simple procedural tree (grass_biome sprite has mixed content)
	canvas.draw_circle(Vector2(x + 20, y + 58), 6, Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x + 14, y + 40, 12, 20), Color(0.5, 0.35, 0.25))
	canvas.draw_circle(Vector2(x + 20, y + 30), 22, Color(0.4, 0.7, 0.45))
	canvas.draw_circle(Vector2(x + 20, y + 25), 16, Color(0.5, 0.8, 0.5))

func draw_tree_medium(x: float, y: float):
	canvas.draw_rect(Rect2(x + 8, y + 30, 8, 14), Color(0.5, 0.35, 0.25))
	canvas.draw_circle(Vector2(x + 12, y + 24), 16, Color(0.4, 0.7, 0.45))
	canvas.draw_circle(Vector2(x + 12, y + 20), 12, Color(0.5, 0.8, 0.5))

func draw_tree_small(x: float, y: float):
	canvas.draw_rect(Rect2(x + 12, y + 32, 6, 12), Color(0.5, 0.35, 0.25))
	canvas.draw_circle(Vector2(x + 15, y + 26), 12, Color(0.45, 0.75, 0.5))

# ===========================================
# BUSHES, ROCKS, FLOWERS
# ===========================================

func draw_bush(x: float, y: float):
	canvas.draw_circle(Vector2(x, y), 10, Color(0.35, 0.6, 0.4))
	canvas.draw_circle(Vector2(x + 8, y - 2), 8, Color(0.4, 0.7, 0.45))
	canvas.draw_circle(Vector2(x - 6, y + 2), 7, Color(0.35, 0.65, 0.4))

func draw_rock_large(x: float, y: float):
	canvas.draw_circle(Vector2(x + 10, y + 8), 12, Color(0.55, 0.52, 0.5))
	canvas.draw_circle(Vector2(x + 8, y + 4), 8, Color(0.65, 0.62, 0.6))

func draw_rock_small(x: float, y: float):
	canvas.draw_circle(Vector2(x + 5, y + 4), 6, Color(0.55, 0.52, 0.5))

func draw_flower_cluster(x: float, y: float):
	var colors = [Color(1, 0.4, 0.5), Color(1, 0.9, 0.3), Color(0.6, 0.4, 0.9), Color(1, 0.6, 0.3)]
	for i in range(4):
		var fx = x + (i % 2) * 8
		var fy = y + (i / 2) * 6
		canvas.draw_circle(Vector2(fx, fy), 3, colors[i])
		canvas.draw_circle(Vector2(fx, fy), 1.5, Color(1, 1, 0.8))

# ===========================================
# BUILDINGS - Simplified
# ===========================================

func draw_house(x: float, y: float):
	if tex_wooden_house:
		var w = tex_wooden_house.get_width()
		var h = tex_wooden_house.get_height()
		canvas.draw_texture_rect(tex_wooden_house, Rect2(x, y, w * 0.8, h * 0.8), false)
		return
	# Simple house shape
	var wall = Color(0.8, 0.7, 0.55)
	var roof = Color(0.55, 0.35, 0.28)
	canvas.draw_ellipse(Vector2(x + 45, y + 80), Vector2(50, 10), Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x, y + 28, 90, 50), wall)
	var roof_pts = PackedVector2Array([Vector2(x - 8, y + 30), Vector2(x + 45, y + 2), Vector2(x + 98, y + 30)])
	canvas.draw_colored_polygon(roof_pts, roof)
	# Door
	canvas.draw_rect(Rect2(x + 36, y + 46, 18, 30), Color(0.45, 0.32, 0.25))
	# Windows
	canvas.draw_rect(Rect2(x + 8, y + 40, 20, 18), Color(0.6, 0.8, 0.95))
	canvas.draw_rect(Rect2(x + 62, y + 40, 20, 18), Color(0.6, 0.8, 0.95))

func draw_shed(x: float, y: float):
	# Small shadow at base
	canvas.draw_ellipse(Vector2(x + 32, y + 60), Vector2(28, 8), Color(0, 0, 0, 0.2))
	
	if tex_shed:
		var w = tex_shed.get_width()
		var h = tex_shed.get_height()
		# Draw sprite at position, scaled if needed
		var dest = Rect2(x, y, w, h)
		canvas.draw_texture_rect(tex_shed, dest, false)
	else:
		# Fallback to procedural drawing
		var wood = Color(0.6, 0.45, 0.35)
		var roof = Color(0.65, 0.42, 0.32)
		canvas.draw_rect(Rect2(x, y + 15, 40, 30), wood)
		var roof_pts = PackedVector2Array([Vector2(x - 4, y + 18), Vector2(x + 20, y + 2), Vector2(x + 44, y + 18)])
		canvas.draw_colored_polygon(roof_pts, roof)
		canvas.draw_rect(Rect2(x + 14, y + 25, 12, 20), Color(0.35, 0.25, 0.2))

func draw_well(x: float, y: float):
	var stone = Color(0.6, 0.58, 0.55)
	canvas.draw_ellipse(Vector2(x + 20, y + 45), Vector2(22, 10), Color(0, 0, 0, 0.15))
	canvas.draw_ellipse(Vector2(x + 20, y + 30), Vector2(20, 10), stone)
	canvas.draw_rect(Rect2(x, y + 25, 40, 20), stone)
	# Roof posts and roof
	canvas.draw_rect(Rect2(x + 2, y + 5, 4, 25), Color(0.5, 0.35, 0.25))
	canvas.draw_rect(Rect2(x + 34, y + 5, 4, 25), Color(0.5, 0.35, 0.25))
	canvas.draw_rect(Rect2(x - 2, y, 44, 8), Color(0.55, 0.38, 0.3))

func draw_fence(x: float, y: float, count: int):
	if tex_fences:
		for i in range(count):
			var src = Rect2(0, 0, 16, 16)
			canvas.draw_texture_rect_region(tex_fences, Rect2(x + i * 16, y, 16, 16), src)
		return
	for i in range(count):
		var fx = x + i * 12
		canvas.draw_rect(Rect2(fx, y, 3, 20), Color(0.55, 0.4, 0.3))
		canvas.draw_rect(Rect2(fx + 6, y, 3, 20), Color(0.55, 0.4, 0.3))
		canvas.draw_rect(Rect2(fx - 1, y + 4, 14, 3), Color(0.5, 0.38, 0.28))
		canvas.draw_rect(Rect2(fx - 1, y + 12, 14, 3), Color(0.5, 0.38, 0.28))

# ===========================================
# TOWN BUILDINGS - Simplified
# ===========================================

func draw_town_building_shop(x: float = 30, y: float = 10):
	var wall = Color(0.75, 0.62, 0.5)
	var roof = Color(0.45, 0.32, 0.25)
	canvas.draw_ellipse(Vector2(x + 40, y + 82), Vector2(42, 8), Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x, y + 20, 80, 70), wall)
	canvas.draw_rect(Rect2(x - 5, y + 10, 90, 14), roof)
	# Windows
	canvas.draw_rect(Rect2(x + 8, y + 35, 20, 16), Color(0.5, 0.65, 0.85))
	canvas.draw_rect(Rect2(x + 52, y + 35, 20, 16), Color(0.5, 0.65, 0.85))
	# Door
	canvas.draw_rect(Rect2(x + 30, y + 58, 20, 30), Color(0.4, 0.28, 0.2))
	# Awning stripes
	for i in range(3):
		var c = Color(0.25, 0.5, 0.35) if i % 2 == 0 else Color(0.9, 0.88, 0.82)
		canvas.draw_rect(Rect2(x + 26 + i * 10, y + 52, 10, 7), c)
	# Sign
	canvas.draw_rect(Rect2(x + 20, y + 26, 40, 10), Color(0.55, 0.45, 0.35))

func draw_town_building_hall(x: float = 170, y: float = 5):
	var wall = Color(0.8, 0.73, 0.63)
	var roof = Color(0.48, 0.35, 0.28)
	canvas.draw_ellipse(Vector2(x + 70, y + 97), Vector2(62, 10), Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x, y + 15, 140, 85), wall)
	canvas.draw_rect(Rect2(x - 5, y + 5, 150, 14), roof)
	# Columns
	canvas.draw_rect(Rect2(x + 8, y + 40, 8, 55), Color(0.7, 0.62, 0.52))
	canvas.draw_rect(Rect2(x + 124, y + 40, 8, 55), Color(0.7, 0.62, 0.52))
	# Windows
	for i in range(3):
		canvas.draw_rect(Rect2(x + 22 + i * 35, y + 40, 24, 20), Color(0.5, 0.62, 0.82))
	# Double doors
	canvas.draw_rect(Rect2(x + 48, y + 65, 44, 35), Color(0.38, 0.28, 0.22))
	canvas.draw_rect(Rect2(x + 69, y + 65, 2, 35), Color(0.25, 0.18, 0.15))

func draw_town_building_bakery(x: float = 335, y: float = 10):
	var wall = Color(0.95, 0.9, 0.82)
	var roof = Color(0.7, 0.45, 0.35)
	canvas.draw_ellipse(Vector2(x + 35, y + 82), Vector2(38, 8), Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x, y + 20, 70, 70), wall)
	canvas.draw_rect(Rect2(x - 4, y + 10, 78, 14), roof)
	# Window
	canvas.draw_rect(Rect2(x + 8, y + 35, 22, 18), Color(0.5, 0.65, 0.85))
	# Door
	canvas.draw_rect(Rect2(x + 40, y + 55, 20, 33), Color(0.4, 0.28, 0.2))
	# Awning
	canvas.draw_rect(Rect2(x + 4, y + 53, 30, 6), Color(0.85, 0.35, 0.3))

func draw_town_building_house1(x: float = 410, y: float = 60):
	var wall = Color(0.72, 0.58, 0.48)
	var roof = Color(0.5, 0.35, 0.28)
	canvas.draw_rect(Rect2(x, y + 15, 55, 50), wall)
	var roof_pts = PackedVector2Array([Vector2(x - 4, y + 18), Vector2(x + 27, y), Vector2(x + 59, y + 18)])
	canvas.draw_colored_polygon(roof_pts, roof)
	canvas.draw_rect(Rect2(x + 8, y + 28, 16, 14), Color(0.5, 0.65, 0.85))
	canvas.draw_rect(Rect2(x + 20, y + 42, 14, 22), Color(0.4, 0.3, 0.22))

func draw_town_building_house2(x: float = 410, y: float = 145):
	var wall = Color(0.85, 0.78, 0.65)
	var roof = Color(0.45, 0.38, 0.32)
	canvas.draw_rect(Rect2(x, y + 15, 55, 45), wall)
	canvas.draw_rect(Rect2(x - 3, y + 8, 61, 10), roof)
	canvas.draw_rect(Rect2(x + 8, y + 26, 14, 12), Color(0.5, 0.65, 0.85))
	canvas.draw_rect(Rect2(x + 33, y + 26, 14, 12), Color(0.5, 0.65, 0.85))
	canvas.draw_rect(Rect2(x + 20, y + 40, 14, 20), Color(0.42, 0.32, 0.25))

# ===========================================
# TOWN FURNITURE
# ===========================================

func draw_bench(x: float, y: float):
	canvas.draw_rect(Rect2(x, y + 8, 30, 4), Color(0.55, 0.4, 0.3))
	canvas.draw_rect(Rect2(x + 2, y + 12, 4, 8), Color(0.5, 0.38, 0.28))
	canvas.draw_rect(Rect2(x + 24, y + 12, 4, 8), Color(0.5, 0.38, 0.28))

func draw_barrel(x: float, y: float):
	canvas.draw_ellipse(Vector2(x + 8, y + 18), Vector2(9, 4), Color(0, 0, 0, 0.15))
	canvas.draw_rect(Rect2(x, y, 16, 18), Color(0.55, 0.4, 0.3))
	canvas.draw_rect(Rect2(x, y + 4, 16, 2), Color(0.4, 0.35, 0.3))
	canvas.draw_rect(Rect2(x, y + 12, 16, 2), Color(0.4, 0.35, 0.3))
	canvas.draw_ellipse(Vector2(x + 8, y), Vector2(8, 3), Color(0.45, 0.35, 0.28))

func draw_lamp_post(x: float, y: float):
	canvas.draw_rect(Rect2(x + 2, y + 10, 4, 30), Color(0.25, 0.22, 0.2))
	canvas.draw_rect(Rect2(x - 2, y, 12, 12), Color(0.3, 0.28, 0.25))
	canvas.draw_circle(Vector2(x + 4, y + 5), 4, Color(1, 0.95, 0.7, 0.8))

func draw_market_stall(x: float, y: float):
	# Posts
	canvas.draw_rect(Rect2(x, y + 8, 4, 28), Color(0.5, 0.38, 0.28))
	canvas.draw_rect(Rect2(x + 36, y + 8, 4, 28), Color(0.5, 0.38, 0.28))
	# Counter
	canvas.draw_rect(Rect2(x - 2, y + 20, 44, 16), Color(0.6, 0.48, 0.38))
	# Awning
	for i in range(4):
		var c = Color(0.85, 0.25, 0.2) if i % 2 == 0 else Color(0.95, 0.9, 0.85)
		canvas.draw_rect(Rect2(x - 4 + i * 12, y, 12, 10), c)

func draw_town_fountain(x: float = 300, y: float = 180):
	# Base
	canvas.draw_ellipse(Vector2(x, y + 20), Vector2(35, 12), Color(0.55, 0.52, 0.5))
	canvas.draw_ellipse(Vector2(x, y + 10), Vector2(30, 10), Color(0.4, 0.6, 0.8, 0.6))
	# Center pillar
	canvas.draw_rect(Rect2(x - 5, y - 15, 10, 30), Color(0.6, 0.58, 0.55))
	canvas.draw_ellipse(Vector2(x, y - 15), Vector2(8, 4), Color(0.65, 0.62, 0.6))

func draw_flower_bed(x: float, y: float, count: int):
	canvas.draw_rect(Rect2(x, y, count * 10, 8), Color(0.45, 0.35, 0.25))
	for i in range(count):
		var c = [Color(1, 0.4, 0.5), Color(1, 0.9, 0.3), Color(0.8, 0.4, 0.8)][i % 3]
		canvas.draw_circle(Vector2(x + 5 + i * 10, y - 2), 4, c)

# ===========================================
# WATER & POND
# ===========================================

func draw_water_pond(x: float, y: float):
	canvas.draw_ellipse(Vector2(x + 35, y + 25), Vector2(40, 28), Color(0.3, 0.5, 0.7))
	canvas.draw_ellipse(Vector2(x + 35, y + 22), Vector2(35, 22), Color(0.4, 0.6, 0.8))
	canvas.draw_ellipse(Vector2(x + 30, y + 18), Vector2(20, 12), Color(0.5, 0.7, 0.9, 0.5))

# ===========================================
# SPECIAL STRUCTURES
# ===========================================

func draw_radiotower_large(x: float, y: float):
	var metal = Color(0.5, 0.48, 0.45)
	var dark = Color(0.35, 0.32, 0.3)
	# Base
	canvas.draw_rect(Rect2(x + 15, y + 80, 30, 15), dark)
	# Main tower structure
	canvas.draw_rect(Rect2(x + 22, y + 10, 6, 75), metal)
	canvas.draw_rect(Rect2(x + 32, y + 10, 6, 75), metal)
	# Cross beams
	for i in range(6):
		var by = y + 20 + i * 12
		canvas.draw_line(Vector2(x + 22, by), Vector2(x + 38, by + 10), dark, 2)
		canvas.draw_line(Vector2(x + 38, by), Vector2(x + 22, by + 10), dark, 2)
	# Antenna
	canvas.draw_rect(Rect2(x + 28, y - 10, 4, 22), metal)
	canvas.draw_circle(Vector2(x + 30, y - 12), 4, Color(1, 0.3, 0.2))

func draw_tunnel_entrance(x: float, y: float):
	var stone = Color(0.4, 0.38, 0.35)
	var dark = Color(0.1, 0.08, 0.08)
	# Stone arch
	canvas.draw_rect(Rect2(x, y + 10, 45, 35), stone)
	canvas.draw_rect(Rect2(x + 5, y + 15, 35, 30), dark)
	# Arch top
	canvas.draw_circle(Vector2(x + 22, y + 15), 18, stone)
	canvas.draw_circle(Vector2(x + 22, y + 15), 13, dark)
	# Warning stripes
	for i in range(3):
		canvas.draw_rect(Rect2(x + 8 + i * 12, y + 8, 6, 4), Color(0.9, 0.7, 0.2))

func draw_chicken_coop(x: float, y: float, tex: Texture2D):
	if tex:
		var w = tex.get_width()
		var h = tex.get_height()
		var scale = 0.875
		canvas.draw_texture_rect(tex, Rect2(x - 15, y - h * scale + 45, w * scale, h * scale), false)

func draw_farm_plot(x: float, y: float, cols: int, rows: int):
	var dirt = Color(0.5, 0.38, 0.28)
	var dirt_light = Color(0.6, 0.48, 0.38)
	canvas.draw_rect(Rect2(x - 2, y - 2, cols * 16 + 4, rows * 12 + 4), dirt)
	for row in range(rows):
		for col in range(cols):
			var px = x + col * 16
			var py = y + row * 12
			canvas.draw_rect(Rect2(px, py, 14, 10), dirt_light)

func draw_irrigation_system(x: float, y: float):
	var pipe = Color(0.45, 0.42, 0.4)
	# Main pipe
	canvas.draw_rect(Rect2(x, y + 20, 80, 6), pipe)
	# Vertical pipes
	for i in range(4):
		canvas.draw_rect(Rect2(x + 10 + i * 20, y + 20, 4, 25), pipe)
	# Control box
	canvas.draw_rect(Rect2(x + 75, y + 10, 15, 18), Color(0.5, 0.5, 0.55))
	canvas.draw_circle(Vector2(x + 82, y + 18), 3, Color(0.3, 0.8, 0.4))

func draw_crops(x: float, y: float, healthy: bool):
	var leaf = Color(0.4, 0.7, 0.45) if healthy else Color(0.6, 0.55, 0.35)
	for i in range(6):
		var cx = x + 8 + (i % 3) * 20
		var cy = y + 5 + (i / 3) * 15
		canvas.draw_rect(Rect2(cx, cy + 5, 2, 10), Color(0.45, 0.55, 0.35))
		canvas.draw_circle(Vector2(cx + 1, cy + 3), 5, leaf)

# ===========================================
# LAKESIDE & CORNFIELD SPECIFIC
# ===========================================

func draw_lakeside_dock(x: float, y: float):
	var wood = Color(0.55, 0.42, 0.32)
	var wood_dark = Color(0.45, 0.35, 0.25)
	# Planks
	for i in range(8):
		canvas.draw_rect(Rect2(x + i * 8, y, 7, 40), wood if i % 2 == 0 else wood_dark)
	# Posts
	canvas.draw_rect(Rect2(x - 2, y + 35, 6, 12), wood_dark)
	canvas.draw_rect(Rect2(x + 60, y + 35, 6, 12), wood_dark)

func draw_cornfield_farmhouse(x: float, y: float):
	draw_house(x, y)  # Reuse house drawing

func draw_cherry_blossom_tree(x: float, y: float):
	var trunk = Color(0.5, 0.35, 0.28)
	var blossoms = Color(1, 0.75, 0.8)
	var blossoms_light = Color(1, 0.85, 0.88)
	canvas.draw_rect(Rect2(x + 18, y + 45, 14, 25), trunk)
	canvas.draw_circle(Vector2(x + 25, y + 35), 28, blossoms)
	canvas.draw_circle(Vector2(x + 15, y + 30), 20, blossoms)
	canvas.draw_circle(Vector2(x + 35, y + 32), 18, blossoms)
	canvas.draw_circle(Vector2(x + 25, y + 25), 22, blossoms_light)

# ===========================================
# HELPER
# ===========================================

func draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(24):
		var angle = i * TAU / 24
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	canvas.draw_colored_polygon(points, color)
