extends RefCounted
# AreaDrawing.gd - Environment and area drawing functions
# Usage: var area = AreaDrawing.new(self) in _ready(), then area.draw_X() in _draw()

var canvas: CanvasItem
var game  # Reference to main game script for accessing textures

# Sprite textures for environment objects
var tex_tree: Texture2D  # Main tree sprite from Sprout Lands
var tex_tree_loaded: bool = false
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

# Ninja Adventure TilesetNature.png - contains various tree sprites
var tex_nature_tileset: Texture2D
var nature_tileset_loaded: bool = false

# Tree sprite regions from TilesetNature.png (384x336, 16px grid)
# Each tree type has a source Rect2 defining where to extract from tileset
# Based on visual inspection of the tileset layout
var tree_regions: Dictionary = {
	# Large oak trees (green, lush) - bottom left of tileset
	"oak_large": Rect2(0, 240, 64, 96),       # Big green oak at bottom
	"oak_medium": Rect2(64, 0, 48, 48),       # Medium green crown at top
	# Pine/evergreen trees - darker green, from middle area
	"pine_large": Rect2(288, 0, 48, 64),      # Tall dense green tree
	"pine_medium": Rect2(336, 0, 48, 48),     # Medium pine
	# Cherry blossom trees (pink) - top middle area
	"cherry_large": Rect2(160, 0, 48, 48),    # Large pink cherry crown
	"cherry_medium": Rect2(208, 0, 32, 48),   # Medium cherry blossom
	# Autumn trees (orange/brown foliage) - visible at edges
	"autumn_large": Rect2(0, 0, 48, 64),      # Dark red/brown tree (autumn/dead look)
	"autumn_medium": Rect2(0, 48, 32, 48),    # Medium autumn tree
	# Snow-covered trees (white)
	"snow_large": Rect2(96, 0, 64, 64),       # Snow-covered tree
	"snow_medium": Rect2(128, 48, 32, 48),    # Medium snow tree
	# Dead/bare trees - trunks visible in middle
	"dead_tree": Rect2(80, 64, 32, 48),       # Bare trunk
	# Tree stumps
	"stump": Rect2(96, 96, 16, 16),           # Cut stump
	# Bushes - middle section
	"bush_green": Rect2(0, 96, 32, 32),       # Green bush
	"bush_round": Rect2(32, 96, 32, 32),      # Round bush
	# Rocks - bottom middle area
	"rock_large": Rect2(288, 144, 48, 48),    # Large rock
	"rock_small": Rect2(336, 144, 32, 32),    # Small rock
}

# Shared textures (loaded by main script, passed in)
var tex_grass_biome: Texture2D
var tex_water: Texture2D
var tex_wooden_house: Texture2D
var tex_fences: Texture2D
var tex_chicken_house: Texture2D
var tex_farmhouse: Texture2D
var tex_townhall: Texture2D
var tex_shop: Texture2D
var tex_bakery: Texture2D
var tex_well_sprite: Texture2D

const SPROUT_PATH = "res://Sprout Lands - Sprites - Basic pack/"
const NINJA_PATH = "res://Ninja Adventure - Asset Pack/"
const OBJECTS_PATH = "res://Sprout Lands - Sprites - Basic pack/Objects/"

func _init(canvas_item: CanvasItem):
	canvas = canvas_item
	game = canvas_item  # The canvas is the main game script
	load_environment_sprites()

func load_environment_sprites():
	# Load tree.png from Sprout Lands Objects folder (primary tree sprite)
	var tree_path = OBJECTS_PATH + "tree.png"
	if ResourceLoader.exists(tree_path):
		tex_tree = load(tree_path)
		tex_tree_loaded = true
		print("[OK] tree.png loaded for all trees")

	# Load Ninja Adventure TilesetNature.png as fallback
	var nature_path = NINJA_PATH + "Backgrounds/Tilesets/TilesetNature.png"
	if ResourceLoader.exists(nature_path):
		tex_nature_tileset = load(nature_path)
		nature_tileset_loaded = true
		print("[OK] TilesetNature.png loaded as fallback")

	# Try to load other environment sprites from asset packs
	var paths = {
		"bush": [OBJECTS_PATH + "Bush.png"],
		"rock": [OBJECTS_PATH + "Rock.png"],
		"well": [OBJECTS_PATH + "Well.png"],
		"barrel": [OBJECTS_PATH + "Barrel.png"],
		"bench": [OBJECTS_PATH + "Bench.png"],
		"fence": [SPROUT_PATH + "Tilesets/Fences.png"],
		"shed": [OBJECTS_PATH + "shed.png"],
		"fountain": [OBJECTS_PATH + "fountain.png"],
		"lamp": [OBJECTS_PATH + "street_lamp.png"],
	}

	for key in paths:
		for path in paths[key]:
			if ResourceLoader.exists(path):
				match key:
					"bush": tex_bush = load(path)
					"rock": tex_rock = load(path)
					"well": tex_well = load(path)
					"barrel": tex_barrel = load(path)
					"bench": tex_bench = load(path)
					"fence": tex_fence = load(path)
					"shed": tex_shed = load(path)
					"fountain": tex_fountain = load(path)
					"lamp": tex_lamp = load(path)
				break

func set_shared_textures(grass_biome: Texture2D, water: Texture2D, wooden_house: Texture2D, fences: Texture2D, chicken_house: Texture2D, farmhouse: Texture2D = null, townhall: Texture2D = null, shop: Texture2D = null, bakery: Texture2D = null, well: Texture2D = null):
	tex_grass_biome = grass_biome
	tex_water = water
	tex_wooden_house = wooden_house
	tex_fences = fences
	tex_chicken_house = chicken_house
	tex_farmhouse = farmhouse
	tex_townhall = townhall
	tex_shop = shop
	tex_bakery = bakery
	tex_well_sprite = well

# ===========================================
# TREES - Using tree.png from Sprout Lands Objects
# ===========================================

# Main tree drawing function - uses tree.png sprite
func draw_tree_sprite(x: float, y: float, scale: float = 1.0):
	if tex_tree_loaded and tex_tree:
		var w = tex_tree.get_width()
		var h = tex_tree.get_height()
		var dest_w = w * scale
		var dest_h = h * scale
		# Draw shadow first
		canvas.draw_ellipse(Vector2(x + dest_w/2, y + dest_h - 5), Vector2(dest_w * 0.4, dest_h * 0.1), Color(0, 0, 0, 0.2))
		# Draw tree sprite
		canvas.draw_texture_rect(tex_tree, Rect2(x, y, dest_w, dest_h), false)
	else:
		# Fallback to procedural
		draw_tree_procedural(x, y, "oak_large")

# Generic tree drawing - now uses tree.png
func draw_tree_from_tileset(x: float, y: float, tree_type: String, scale: float = 1.0):
	# Always use tree.png sprite now
	if tex_tree_loaded and tex_tree:
		draw_tree_sprite(x, y, scale)
	elif nature_tileset_loaded and tex_nature_tileset and tree_type in tree_regions:
		# Fallback to tileset
		var src = tree_regions[tree_type]
		var dest_w = src.size.x * scale
		var dest_h = src.size.y * scale
		var dest = Rect2(x, y, dest_w, dest_h)
		canvas.draw_texture_rect_region(tex_nature_tileset, dest, src)
	else:
		# Fallback to procedural
		draw_tree_procedural(x, y, tree_type)

func draw_tree_procedural(x: float, y: float, tree_type: String):
	# Procedural fallback based on tree type
	match tree_type:
		"oak_large", "oak_medium":
			canvas.draw_circle(Vector2(x + 24, y + 58), 6, Color(0, 0, 0, 0.15))
			canvas.draw_rect(Rect2(x + 18, y + 40, 12, 20), Color(0.5, 0.35, 0.25))
			canvas.draw_circle(Vector2(x + 24, y + 28), 24, Color(0.35, 0.6, 0.4))
			canvas.draw_circle(Vector2(x + 24, y + 22), 18, Color(0.45, 0.7, 0.45))
		"pine_large", "pine_medium":
			canvas.draw_rect(Rect2(x + 12, y + 48, 8, 16), Color(0.45, 0.3, 0.22))
			# Triangular pine shape
			var pts = PackedVector2Array([Vector2(x + 16, y), Vector2(x + 32, y + 50), Vector2(x, y + 50)])
			canvas.draw_colored_polygon(pts, Color(0.25, 0.45, 0.3))
		"cherry_large", "cherry_medium":
			canvas.draw_rect(Rect2(x + 20, y + 45, 10, 18), Color(0.5, 0.35, 0.28))
			canvas.draw_circle(Vector2(x + 25, y + 30), 26, Color(1, 0.75, 0.82))
			canvas.draw_circle(Vector2(x + 25, y + 24), 20, Color(1, 0.85, 0.88))
		"autumn_large", "autumn_medium":
			canvas.draw_rect(Rect2(x + 18, y + 42, 12, 20), Color(0.5, 0.35, 0.25))
			canvas.draw_circle(Vector2(x + 24, y + 28), 24, Color(0.85, 0.5, 0.25))
			canvas.draw_circle(Vector2(x + 24, y + 22), 18, Color(0.95, 0.6, 0.3))
		"dead_tree":
			canvas.draw_rect(Rect2(x + 12, y + 20, 8, 28), Color(0.4, 0.3, 0.25))
			canvas.draw_rect(Rect2(x + 6, y + 25, 20, 4), Color(0.35, 0.28, 0.22))
			canvas.draw_rect(Rect2(x + 4, y + 35, 8, 3), Color(0.35, 0.28, 0.22))
		_:
			# Default green tree
			canvas.draw_circle(Vector2(x + 20, y + 58), 6, Color(0, 0, 0, 0.15))
			canvas.draw_rect(Rect2(x + 14, y + 40, 12, 20), Color(0.5, 0.35, 0.25))
			canvas.draw_circle(Vector2(x + 20, y + 30), 22, Color(0.4, 0.7, 0.45))

# Convenience functions for common tree types - all use tree.png now
# Scales reduced to be proportional to NPC size
func draw_tree_large(x: float, y: float):
	draw_tree_sprite(x, y, 0.35)

func draw_tree_medium(x: float, y: float):
	draw_tree_sprite(x, y, 0.28)

func draw_tree_small(x: float, y: float):
	draw_tree_sprite(x, y, 0.2)

func draw_oak_tree(x: float, y: float, large: bool = true):
	draw_tree_sprite(x, y, 0.35 if large else 0.25)

func draw_pine_tree(x: float, y: float, large: bool = true):
	draw_tree_sprite(x, y, 0.35 if large else 0.25)

func draw_cherry_tree(x: float, y: float, large: bool = true):
	draw_tree_sprite(x, y, 0.35 if large else 0.25)

func draw_autumn_tree(x: float, y: float, large: bool = true):
	draw_tree_sprite(x, y, 0.35 if large else 0.25)

func draw_dead_tree(x: float, y: float):
	draw_tree_sprite(x, y, 0.28)

func draw_snow_tree(x: float, y: float, large: bool = true):
	draw_tree_sprite(x, y, 0.35 if large else 0.25)

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
	# Draw farmhouse sprite only
	if tex_farmhouse:
		var w = tex_farmhouse.get_width()
		var h = tex_farmhouse.get_height()
		canvas.draw_texture_rect(tex_farmhouse, Rect2(x, y, w, h), false)

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
	if tex_well_sprite:
		var w = tex_well_sprite.get_width()
		var h = tex_well_sprite.get_height()
		canvas.draw_texture_rect(tex_well_sprite, Rect2(x, y, w, h), false)
		return
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
	if tex_shop:
		var w = tex_shop.get_width()
		var h = tex_shop.get_height()
		canvas.draw_texture_rect(tex_shop, Rect2(x, y, w, h), false)
		return
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
	if tex_townhall:
		var w = tex_townhall.get_width()
		var h = tex_townhall.get_height()
		canvas.draw_texture_rect(tex_townhall, Rect2(x, y, w, h), false)
		return
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
	if tex_bakery:
		var w = tex_bakery.get_width()
		var h = tex_bakery.get_height()
		canvas.draw_texture_rect(tex_bakery, Rect2(x, y, w, h), false)
		return
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
	# Use street_lamp.png sprite
	if tex_lamp:
		var tex_w = tex_lamp.get_width()
		var tex_h = tex_lamp.get_height()
		var scale = 0.5  # Adjust scale as needed
		var dest_w = tex_w * scale
		var dest_h = tex_h * scale
		var dest = Rect2(x - dest_w / 2, y - dest_h + 10, dest_w, dest_h)
		canvas.draw_texture_rect(tex_lamp, dest, false)
	else:
		# Procedural fallback
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
	# Use fountain.png sprite at 60% scale (40% smaller)
	if tex_fountain:
		var tex_w = tex_fountain.get_width()
		var tex_h = tex_fountain.get_height()
		var scale = 0.15  # 15% of original size
		var dest_w = tex_w * scale
		var dest_h = tex_h * scale
		var dest = Rect2(x - dest_w / 2, y - dest_h / 2, dest_w, dest_h)
		canvas.draw_texture_rect(tex_fountain, dest, false)
	else:
		# Procedural fallback
		canvas.draw_ellipse(Vector2(x, y + 20), Vector2(35, 12), Color(0.55, 0.52, 0.5))
		canvas.draw_ellipse(Vector2(x, y + 10), Vector2(30, 10), Color(0.4, 0.6, 0.8, 0.6))
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
	# Use irrigation sprite if available
	if game.tex_irrigation:
		var w = game.tex_irrigation.get_width()
		var h = game.tex_irrigation.get_height()
		var dest = Rect2(x, y, w, h)
		canvas.draw_texture_rect(game.tex_irrigation, dest, false)

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
	# Draw a proper wooden pier/dock extending into the water
	var wood_light = Color(0.62, 0.48, 0.35)
	var wood_mid = Color(0.52, 0.40, 0.30)
	var wood_dark = Color(0.42, 0.32, 0.22)
	var wood_shadow = Color(0.32, 0.24, 0.18)
	var post_color = Color(0.38, 0.28, 0.20)

	var dock_width = 70
	var dock_length = 85
	var plank_height = 6

	# Support posts going into water (draw first, behind dock)
	# Left side posts
	canvas.draw_rect(Rect2(x + 4, y + 20, 8, 35), post_color)
	canvas.draw_rect(Rect2(x + 4, y + 50, 8, 30), wood_shadow)  # Shadow in water
	# Right side posts
	canvas.draw_rect(Rect2(x + dock_width - 12, y + 20, 8, 35), post_color)
	canvas.draw_rect(Rect2(x + dock_width - 12, y + 50, 8, 30), wood_shadow)
	# Middle support post
	canvas.draw_rect(Rect2(x + dock_width/2 - 4, y + 35, 8, 25), post_color)
	canvas.draw_rect(Rect2(x + dock_width/2 - 4, y + 55, 8, 25), wood_shadow)
	# Far end post
	canvas.draw_rect(Rect2(x + 4, y + dock_length - 15, 8, 20), post_color)
	canvas.draw_rect(Rect2(x + dock_width - 12, y + dock_length - 15, 8, 20), post_color)

	# Main deck planks (horizontal boards)
	var num_planks = 12
	for i in range(num_planks):
		var plank_y = y + i * plank_height
		var shade = wood_light if i % 3 == 0 else (wood_mid if i % 3 == 1 else wood_dark)
		# Main plank
		canvas.draw_rect(Rect2(x, plank_y, dock_width, plank_height - 1), shade)
		# Plank edge shadow
		canvas.draw_rect(Rect2(x, plank_y + plank_height - 2, dock_width, 1), wood_shadow)

	# Side railings/edge trim
	canvas.draw_rect(Rect2(x - 2, y, 4, dock_length - 10), wood_dark)
	canvas.draw_rect(Rect2(x + dock_width - 2, y, 4, dock_length - 10), wood_dark)

	# Railing posts at corners
	canvas.draw_rect(Rect2(x - 3, y - 2, 6, 8), wood_mid)
	canvas.draw_rect(Rect2(x + dock_width - 3, y - 2, 6, 8), wood_mid)
	# Railing posts at end
	canvas.draw_rect(Rect2(x - 3, y + dock_length - 18, 6, 10), wood_mid)
	canvas.draw_rect(Rect2(x + dock_width - 3, y + dock_length - 18, 6, 10), wood_mid)

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
