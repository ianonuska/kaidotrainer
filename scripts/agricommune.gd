extends Node2D

# ============================================
# KAIDOTRAINER - AGRICOMMUNE v2
# Full v1.1 - v1.4 Story + Enhanced Features
# ============================================

# Preload dialogue data (keeps main file smaller)
const Dialogue = preload("res://DialogueData.gd")
var dialogue_data = Dialogue.new()

# Preload area drawing (environment rendering)
const AreaDraw = preload("res://AreaDrawing.gd")
var area_draw: RefCounted

# Preload UI drawing (menus, popups, HUD)
const UIDraw = preload("res://UIDrawing.gd")
var ui_draw: RefCounted

# Preload combat system
const CombatSys = preload("res://CombatSystem.gd")
var combat_sys: RefCounted

# Preload stampede system
const StampedeSys = preload("res://StampedeSystem.gd")
var stampede_sys: RefCounted

# Preload interior scenes
const InteriorSc = preload("res://InteriorScenes.gd")
var interior_sc: RefCounted

# Screen and zoom settings
const SCREEN_WIDTH = 480
const SCREEN_HEIGHT = 320
const GAME_ZOOM = 2.0  # 2x zoom for Stardew Valley-like scale

# Game modes
enum GameMode { 
	INTRO, 
	EXPLORATION, 
	SHED_INTERIOR, 
	PHOTOGRAPH, 
	BUILD_SCREEN,
	SCHEMATIC_POPUP,
	BACKPACK_POPUP,
	JOURNAL_VIEW,
	COMBAT,
	RADIOTOWER_INTERIOR,
	RADIOTOWER_VIEW,
	STAMPEDE,  # Left road - animal stampede minigame
	NIGHTFALL,
	ENDING_CUTSCENE,
	REGION_COMPLETE,
	SHOP_INTERIOR,      # Town shop interior
	TOWNHALL_INTERIOR,  # Town hall interior
	BAKERY_INTERIOR,    # Bakery interior
	PAUSE_MENU          # Workbench pause menu
}
var current_mode: GameMode = GameMode.INTRO

# Current area within Agricommune region
enum Area { FARM, CORNFIELD, LAKESIDE, TOWN_CENTER }
var current_area: Area = Area.FARM
var intro_page: int = 0
var intro_char_index: int = 0

# Pause menu state
var pause_menu_selection: int = 0
var pause_menu_options: Array = ["Resume", "Journal", "Settings", "Quit"]
var pause_previous_mode: GameMode = GameMode.EXPLORATION
var pause_kaido_bob: float = 0.0
var intro_text_timer: float = 0.0
var intro_text_speed: float = 0.03
var shed_explore_stage: int = 0
var photo_fade: float = 0.0
var backpack_anim: float = 0.0
var pending_gadget: String = ""
var ending_stage: int = 0
var ending_timer: float = 0.0

# Screen transition effect
var screen_transition_active: bool = false
var screen_transition_alpha: float = 0.0
var screen_transition_phase: int = 0  # 0 = fading out, 1 = fading in
var screen_transition_speed: float = 1.8  # Slower, smoother fade

# Radiotower Interior - Simple 2D Platformer
var tower_player_pos: Vector2 = Vector2(240, 280)
var tower_player_vel: Vector2 = Vector2.ZERO
var tower_player_grounded: bool = false
var tower_player_facing_right: bool = true
var tower_reached_top: bool = false

# Tower platforms - easy jumping layout
var tower_platforms: Array = [
	{"x": 0, "y": 290, "w": 480},       # Ground
	{"x": 30, "y": 240, "w": 130},      # Level 1 left
	{"x": 350, "y": 240, "w": 130},     # Level 1 right
	{"x": 150, "y": 190, "w": 180},     # Level 2 center
	{"x": 20, "y": 140, "w": 120},      # Level 3 left
	{"x": 340, "y": 140, "w": 120},     # Level 3 right
	{"x": 140, "y": 90, "w": 200},      # Level 4 center
	{"x": 100, "y": 45, "w": 280},      # Top - radio
]

# Journal scroll
var journal_scroll: float = 0.0

# ============================================
# NEW AREAS - Cornfield, Lakeside, Town, Stampede
# ============================================

# Cornfield (Up Road) - LED Chain circuit location
var cornfield_npcs: Array = [
	{"pos": Vector2(120, 180), "name": "Farmer Mae", "dialogue": "We heard the warning. Which way to safety?"},
	{"pos": Vector2(350, 220), "name": "Old Chen", "dialogue": "My family has farmed here for generations..."},
	{"pos": Vector2(200, 100), "name": "Young Taro", "dialogue": "Mom says we have to leave tonight."},
]
var cornfield_led_placed: bool = false

# Lakeside (Down Road) - Scenic, fishing, secrets
var lakeside_npcs: Array = [
	{"pos": Vector2(150, 210), "name": "Fisher Bo", "dialogue": "The fish aren't biting today. Bad omen."},
	{"pos": Vector2(280, 290), "name": "Old Mira", "dialogue": "I've seen patrol boats on the lake at night."},
]
var lakeside_secret_found: bool = false

# Town Center (Right Road) - Main village hub
var town_npcs: Array = [
	{"pos": Vector2(140, 230), "name": "Elder Sato", "dialogue": "The commune has survived before. We will again."},
	{"pos": Vector2(340, 250), "name": "Child Mei", "dialogue": "Is Kaido really a robot? That's so cool!"},
	{"pos": Vector2(80, 280), "name": "Guard Tanaka", "dialogue": "I'm supposed to report unusual activity..."},
]
var town_visited: bool = false

# Building entry positions (door locations)
var shop_door_pos: Vector2 = Vector2(70, 95)      # Below shop, in door gap
var townhall_door_pos: Vector2 = Vector2(240, 110) # Below town hall, in door gap
var bakery_door_pos: Vector2 = Vector2(405, 95)   # Below bakery, in door gap

# Building interior NPCs
var shop_npc: Dictionary = {"name": "Shopkeeper Bot-3000", "pos": Vector2(240, 180)}
var mayor_npc: Dictionary = {"name": "Mayor Hiroshi", "pos": Vector2(240, 160)}
var baker_npc: Dictionary = {"name": "Baker Bot-7", "pos": Vector2(240, 180)}

# Building interior dialogue states
var shop_talked: bool = false
var mayor_talked: bool = false
var baker_talked: bool = false

# Stampede (Left Road) - Endless combat minigame
var stampede_active: bool = false
var stampede_player_pos: Vector2 = Vector2(100, 220)
var stampede_player_vel: Vector2 = Vector2.ZERO
var stampede_player_y_vel: float = 0.0  # Vertical velocity for jump
var stampede_player_grounded: bool = true
var stampede_player_jump_start_y: float = 220.0  # Y position when jump started
var stampede_player_hp: int = 3
var stampede_player_max_hp: int = 3
var stampede_player_state: String = "idle"  # idle, attacking, jumping, hit
var stampede_player_state_timer: float = 0.0
var stampede_player_facing_right: bool = true
var stampede_player_is_walking: bool = false  # Track if player is moving horizontally
var stampede_bounce_cooldown: float = 0.0  # Brief cooldown between bounces
var stampede_wave: int = 0
var stampede_animals: Array = []  # [{type, pos, vel, hp, hit_flash, defeated}]
var stampede_spawn_timer: float = 0.0
var stampede_wave_timer: float = 0.0
var stampede_complete: bool = false
var stampede_ground_y: float = 220.0  # Ground level
var stampede_arena_left: float = 30.0
var stampede_arena_right: float = 450.0
var stampede_hit_effects: Array = []  # Floating text effects
var stampede_score: int = 0
var stampede_high_score: int = 0

# Animal/enemy types for stampede
const ANIMAL_CHICKEN = 0
const ANIMAL_COW = 1
const ANIMAL_BULL = 2
const ANIMAL_ROBOT = 3  # Appears at wave 4+
const ANIMAL_ROBOT_HEAVY = 4  # Appears at wave 6+

# Player state
var player_pos: Vector2 = Vector2(240, 180)
var player_speed: float = 100.0
var player_facing: String = "down"
var player_frame: int = 0
var anim_timer: float = 0.0
var is_walking: bool = false

# Stuck detection - push player out if trapped
var player_stuck_timer: float = 0.0
var player_last_pos: Vector2 = Vector2(240, 180)

# ============================================
# COMBAT SYSTEM
# ============================================

# Combat state
var combat_active: bool = false
var combat_player_hp: int = 100
var combat_player_max_hp: int = 100
var combat_player_stamina: float = 100.0
var combat_player_max_stamina: float = 100.0
var combat_player_pos: Vector2 = Vector2(150, 220)
var combat_player_vel: Vector2 = Vector2.ZERO  # Velocity for snappy movement
var combat_player_state: String = "idle"  # idle, attacking, dodging, hit, heavy_attack
var combat_player_state_timer: float = 0.0
var combat_combo_count: int = 0
var combat_combo_timer: float = 0.0
var combat_player_facing_right: bool = true
var combat_player_is_walking: bool = false  # Track if player is moving horizontally
var combat_iframe_active: bool = false

# Slash trail effect
var slash_trails: Array = []  # [{start, end, timer, color, width}]
var combat_move_cancel: bool = false  # Can move during attack recovery

# Robot enemy state
var robot_hp: int = 300
var robot_max_hp: int = 300
var robot_pos: Vector2 = Vector2(330, 220)
var robot_state: String = "idle"  # idle, telegraph, attacking, recovering, hit, defeated
var robot_state_timer: float = 0.0
var robot_current_attack: String = ""  # quick_jab (light), baton_swing (heavy), lunge_grab (heavy), combo_strike, scan_sweep
var robot_phase: int = 1  # 1, 2, 3 based on HP
var robot_defeated: bool = false
var robot_spark_timer: float = 0.0

# Combat arena bounds
var combat_arena_left: float = 60.0
var combat_arena_right: float = 420.0
var combat_arena_y: float = 220.0

# Hit effects
var hit_effects: Array = []  # [{pos, text, timer, color}]
var screen_shake: float = 0.0
var footstep_timer: float = 0.0  # For walking haptics
var hit_flash_timer: float = 0.0
var hit_flash_target: String = ""  # "player" or "robot"
var hit_pause_timer: float = 0.0  # Brief pause on hit for impact feel

# Combat hints
var combat_hint: String = ""
var combat_hint_timer: float = 0.0
var continuous_timer: float = 0.0  # Never resets, for smooth animations

# Arkham-style counter system
var counter_window_active: bool = false  # True when player can counter
var counter_indicator_timer: float = 0.0  # Visual indicator timing
var last_counter_success: bool = false  # For flow into counter-attack

# Camera offset for scrolling
var camera_offset: Vector2 = Vector2.ZERO
var camera_bounds: Rect2 = Rect2(-240, -160, 480, 320)  # Full map pan range for 2x zoom

# Collision rectangles for buildings - matched precisely to sprite edges
var building_collisions: Array = [
	# House: drawn at (275, 35), wall at (x, y+28, 90, 48)
	Rect2(275, 63, 90, 48),     # House wall
	# Shed: collision centered on shed_pos (340, 270)
	Rect2(350, 195, 45, 38),   # Shed body
	# Radiotower: drawn at (30, 20), legs at (x+5, y+30, 8, 60) and (x+37, y+30, 8, 60)
	Rect2(35, 50, 8, 60),       # Radiotower left leg
	Rect2(67, 50, 8, 60),       # Radiotower right leg
	# Pond: drawn at (385, 55), ellipse center (415, 80), radii 42x32
	Rect2(390, 30, 50, 50),     # Pond water area
	# Chicken coop: drawn at chicken_coop_pos (120, 90)
	Rect2(110, 100, 30, 36),    # Chicken coop body

	# Irrigation system: control panel at (70, 210, 35, 30), pipes extending right
		 # Irrigation control panel
	Rect2(105, 230, 42, 20),    # Horizontal pipe (thicker collision)
	Rect2(140, 220, 12, 20),    # Vertical pipe (thicker collision)
	# Crops area - drawn at (35, 200), 4x3 grid - collision matches actual position
	# Trees - trunk collision only (matched to actual trunk rects)
	# Large trees: trunk at (x+12, y+35, 16, 25)
	# Left tree removed
	Rect2(107, 45, 16, 25),     # Large tree at (95, 10) - top left
	Rect2(462, 40, 16, 25),     # Large tree at (450, 5) - top right corner (moved from 420)
	Rect2(12, 255, 16, 25),     # Large tree at (0, 220) - bottom left corner (moved from 430,220)
	# Medium trees: trunk at (x+6, y+28, 12, 16)
	# Medium tree removed
	Rect2(466, 278, 12, 16),    # Medium tree at (460, 250) - bottom right (moved from 350,250)
]

# Flashlight in shed
var flashlight_pos: Vector2 = Vector2(240, 200)
var flashlight_speed: float = 90.0

# NPCs and locations
var grandmother_pos: Vector2 = Vector2(340, 145)
var grandmother_target: Vector2 = Vector2(340, 120)
var kaido_pos: Vector2 = Vector2(220, 165)  # Kaido starts behind player (240-20, 180-15)
var kaido_trail_history: Array = []  # Player position history for Kaido to follow
var kaido_trail_delay: int = 45  # How many frames behind Kaido follows
var kaido_speed: float = 100.0  # Kaido's movement speed
var shed_pos: Vector2 = Vector2(372, 245)  # Door/interaction point
var radiotower_pos: Vector2 = Vector2(55, 105)  # Base of tower where player climbs
var irrigation_pos: Vector2 = Vector2(100, 220)
var tunnel_pos: Vector2 = Vector2(430, 285)  # In lakeside area, rocky outcrop

# Building interior exploration
var interior_player_pos: Vector2 = Vector2(240, 250)  # Player position inside buildings
var interior_kaido_pos: Vector2 = Vector2(220, 250)   # Kaido position inside buildings
var interior_npc_pos: Vector2 = Vector2(240, 120)     # NPC position varies by building
var interior_near_npc: bool = false
var interior_near_exit: bool = false

# Patrol state
var patrol_active: bool = false
var patrol_positions: Array = []
var patrol_timer: float = 0.0

# Stealth/Detection system
var awareness_level: float = 0.0  # 0-100, fills when patrol sees you
var max_awareness: float = 100.0
var awareness_decay_rate: float = 15.0  # How fast it drops when hidden
var awareness_fill_rate: float = 25.0  # How fast it fills when spotted
var is_hiding: bool = false
var hiding_spots: Array = [
	Vector2(95, 50),     # Behind top-left tree
	Vector2(95, 220),    # Behind irrigation
	Vector2(340, 260),   # At the shed (where you build circuits)
	Vector2(325, 235),   # Behind shed
	Vector2(310, 85),    # Behind house
	Vector2(0, 260),     # Behind bottom-left tree
]
var player_detected: bool = false  # Game over state
var kaido_warned_to_hide: bool = false
var kaido_tip_text: String = ""
var kaido_tip_timer: float = 0.0

# Dark areas (explored with flashlight)
var dark_areas: Array = [
	{"pos": Vector2(50, 250), "radius": 45, "name": "Old Storage", "secret": "buried"},  # Near radiotower base
	{"pos": Vector2(450, 60), "radius": 40, "name": "Overgrown Corner", "secret": "pond"},  # Near pond
]
var discovered_areas: Array = []  # Names of areas that have been lit up

# Kid messenger
var kid_visible: bool = false
var kid_pos: Vector2 = Vector2(500, 170)  # Start off-screen right
var kid_target_pos: Vector2 = Vector2(300, 170)
var kid_walking_in: bool = false

# Farmer Wen
var farmer_wen_visible: bool = false
var farmer_wen_pos: Vector2 = Vector2(500, 250)  # Start off-screen right
var farmer_wen_target_pos: Vector2 = Vector2(280, 250)
var farmer_wen_walking_in: bool = false
var farmer_wen_leaving: bool = false
var tractor_pos: Vector2 = Vector2(550, 250)  # Tractor follows farmer
var tractor_target_pos: Vector2 = Vector2(320, 250)
var tractor_visible: bool = false

# Component popup
var showing_component_popup: bool = false
var component_popup_data: Dictionary = {}
var component_popup_timer: float = 0.0

# Tunnel fight - 3 robots at once
var tunnel_fight_active: bool = false
var tunnel_robots: Array = []  # Array of robot dictionaries

# Irrigation state
var water_flowing: bool = false
var water_anim: float = 0.0

# Nightfall state
var is_nightfall: bool = false
var nightfall_alpha: float = 0.0
var lit_buildings: Array = []

# NPC relationship/talk tracking
var npc_talk_count: Dictionary = {
	"grandmother": 0,
	"farmer_wen": 0,
	"kid": 0
}

# Optional side circuits
var side_circuits_done: Dictionary = {
	"chicken_coop": false,
	"well_pump": false
}
var chicken_coop_pos: Vector2 = Vector2(120, 90)
var chicken_coop_interact_pos: Vector2 = Vector2(155, 125)  # Near door/chickens
var well_pos: Vector2 = Vector2(240, 285)  # In town center grass area

# Discoverable secrets
var secrets_found: Array = []
var journal_pages_found: Array = []  # Grandfather's journal
var journal_page_locations: Dictionary = {
	"town_center": Vector2(380, 280),   # In town center near houses
	"cornfield": Vector2(120, 180),     # Hidden in cornfield
	"lakeside": Vector2(280, 260),      # Near the lake shore
	"radiotower": Vector2(70, 95),      # Base of radiotower
	"buried": Vector2(320, 260)         # Buried near tunnel (farm)
}

# Lore collectibles - Resistance Relics
var relics_found: Array = []
var relic_data: Dictionary = {
	"old_radio": {
		"name": "Pre-War Radio",
		"desc": "People used to share music and news freely.",
		"location": "shed"
	},
	"family_photo": {
		"name": "Faded Photograph", 
		"desc": "A family picnic. No robots in sight.",
		"location": "house"
	},
	"circuit_board": {
		"name": "Homemade Circuit",
		"desc": "Someone built this. Teaching was legal then.",
		"location": "radiotower"
	},
	"resistance_patch": {
		"name": "Resistance Patch",
		"desc": "The spark symbol. They never gave up.",
		"location": "tunnel"
	}
}

# Dialogue system
var in_dialogue: bool = false
var dialogue_queue: Array = []
var current_dialogue: Dictionary = {}
var current_dialogue_npc: String = ""
var char_index: int = 0
var text_timer: float = 0.0
var text_speed: float = 0.025

# Quest tracking
var quest_stage: int = 0
var circuits_built: int = 0
var current_quest: String = ""
var quest_anim_timer: float = 0.0
var quest_is_new: bool = false

# Help Meter (battery charge) and Currency
var help_meter: float = 100.0  # 0-100, battery charge level
var help_meter_max: float = 100.0
var faraday_credits: int = 0

# Schematic popup
var current_schematic: String = ""
var schematic_shown: bool = false

# Backpack/Gadget system
var gadgets: Array = []
var backpack_selected: int = 0
var equipped_gadget: String = ""  # Currently equipped gadget
var gadget_use_timer: float = 0.0  # Cooldown/animation timer
var gadget_effect_active: bool = false
var gadget_effect_timer: float = 0.0
var flashlight_on: bool = false  # Toggle state for flashlight
var backpack_tab: int = 0  # 0 = gadgets, 1 = loot
var loot_selected: int = 0  # Selected item in loot tab

# Loot items (collectibles that aren't gadgets)
var loot_items: Array = []  # e.g., ["journal", "map", "key"]

# Punch system (when no gadget equipped)
var punch_cooldown: float = 0.0
var punch_effect_timer: float = 0.0
var punch_direction: String = "right"

# Gadget definitions
var gadget_data = {
	"led_lamp": {
		"name": "LED Flashlight",
		"desc": "Portable light source",
		"adventure_use": "Explore dark caves and tunnels. Reveal hidden loot and secret passages. See traps before you step in them.",
		"icon_color": Color(1.0, 0.3, 0.2),
		"circuit": "LED + Resistor",
		"components": ["1x Red LED", "1x 330 ohm Resistor", "Jumper Wires"]
	},
	"buzzer_alarm": {
		"name": "Silent Buzzer",
		"desc": "Remote distraction device",
		"adventure_use": "Place it, hide, then trigger it to lure enemies away. Create distractions without revealing your position.",
		"icon_color": Color(0.3, 0.3, 0.3),
		"circuit": "Buzzer + Button",
		"components": ["1x Piezo Buzzer", "1x Push Button", "1x 100 ohm Resistor"]
	},
	"dimmer": {
		"name": "Light Dimmer",
		"desc": "Controls brightness smoothly",
		"adventure_use": "Dim lights to sneak past guards. Create mood lighting for secret meetings. Adjust signal strength.",
		"icon_color": Color(0.6, 0.4, 0.8),
		"circuit": "Potentiometer Circuit",
		"components": ["1x Potentiometer", "1x LED", "1x 330Î© Resistor"]
	},
	"light_sensor": {
		"name": "Shadow Detector",
		"desc": "Senses approaching threats",
		"adventure_use": "Know when someone is approaching - their shadow arrives before they do. Detect if you're being followed or watched.",
		"icon_color": Color(0.9, 0.8, 0.3),
		"circuit": "Photoresistor Circuit",
		"components": ["1x Photoresistor", "1x LED", "1x 10k ohm Resistor"]
	},
	"led_chain": {
		"name": "Beacon Signal",
		"desc": "Multi-color path marker",
		"adventure_use": "Mark your path through mazes so you don't get lost. Unlock color-sequence doors with the right R-Y-G pattern.",
		"icon_color": Color(0.3, 0.9, 0.4),
		"circuit": "Series LEDs",
		"components": ["3x LEDs (R,Y,G)", "1x 330 ohm Resistor"]
	},
	"or_gate": {
		"name": "Dual Trigger",
		"desc": "Backup activation paths",
		"adventure_use": "Create backup escape routes - if one exit is blocked, the other still works. Solve puzzles multiple ways.",
		"icon_color": Color(0.3, 0.6, 0.9),
		"circuit": "Diode Logic",
		"components": ["2x Diodes", "2x Push Buttons", "1x LED", "1x Resistor"]
	},
	"tractor_sensor": {
		"name": "Presence Bypass",
		"desc": "Fools occupancy sensors",
		"adventure_use": "Start vehicles without sitting in them. Trigger weight plates remotely. Make machines think someone is still there.",
		"icon_color": Color(0.8, 0.6, 0.3),
		"circuit": "Pressure Bypass",
		"components": ["1x Pressure Sensor Module", "Resistor Network"]
	},
	"well_indicator": {
		"name": "Pump Indicator",
		"desc": "Shows pump status",
		"adventure_use": "Simple LED indicator for the village well pump.",
		"icon_color": Color(0.4, 0.7, 0.9),
		"circuit": "LED + Resistor",
		"components": ["1x Blue LED", "1x 330 ohm Resistor", "Jumper Wires"]
	}
}

# Textures
var tex_player: Texture2D

# Player animation frames (loaded from individual files)
var tex_player_walk_south: Array[Texture2D] = []
var tex_player_walk_north: Array[Texture2D] = []
var tex_player_walk_east: Array[Texture2D] = []
var tex_player_walk_west: Array[Texture2D] = []
var tex_player_idle_south: Texture2D
var tex_player_idle_north: Texture2D
var tex_player_idle_east: Texture2D
var tex_player_idle_west: Texture2D
var player_anim_loaded: bool = false
var tex_grass: Texture2D
var tex_kaido: Texture2D
var tex_grandmother: Texture2D
var tex_kaido_portrait: Texture2D
var tex_grandmother_portrait: Texture2D

# Grandmother animation frames
var tex_grandmother_walk_south: Array[Texture2D] = []
var tex_grandmother_walk_north: Array[Texture2D] = []
var tex_grandmother_walk_east: Array[Texture2D] = []
var tex_grandmother_walk_west: Array[Texture2D] = []
var tex_grandmother_idle_south: Texture2D
var tex_grandmother_idle_north: Texture2D
var tex_grandmother_idle_east: Texture2D
var tex_grandmother_idle_west: Texture2D
var grandmother_anim_loaded: bool = false
var grandmother_facing: String = "down"
var grandmother_is_walking: bool = false
var grandmother_pacing: bool = true  # Paces until first conversation
var grandmother_pace_target: Vector2 = Vector2.ZERO
var grandmother_pace_timer: float = 0.0
var grandmother_frame: int = 0
var grandmother_pause_timer: float = 0.0  # Pause at ends of pacing
var grandmother_pace_speed: float = 30.0  # Variable speed
var grandmother_pace_state: String = "walking"  # walking, pausing, looking

# Player attack animation frames
var tex_player_attack_south: Array[Texture2D] = []
var tex_player_attack_north: Array[Texture2D] = []
var tex_player_attack_east: Array[Texture2D] = []
var tex_player_attack_west: Array[Texture2D] = []
var player_attacking: bool = false
var player_attack_frame: int = 0
var player_attack_timer: float = 0.0

# Tileset textures
var tex_tiled_dirt: Texture2D
var tex_tiled_dirt_wide: Texture2D
var tex_tiled_dirt_wide_v2: Texture2D
var tex_water: Texture2D
var tex_fences: Texture2D
var tex_doors: Texture2D
var tex_hills: Texture2D
var tex_wooden_house: Texture2D
var tex_wooden_house_roof: Texture2D
var tex_wooden_house_walls: Texture2D
var tex_water_panel: Texture2D
var tex_cliff_rock: Texture2D
var tex_lake_sand: Texture2D
var tex_grass_biome: Texture2D
var tex_chicken_house: Texture2D
var tex_shed: Texture2D
var tex_sewer: Texture2D
var tex_chicken_sprites: Texture2D
var tex_cow_sprites: Texture2D

# Gadget icon textures
var tex_gadget_flashlight: Texture2D
var tex_gadget_dimmer: Texture2D
var tex_gadget_led_chain: Texture2D
var tex_gadget_light_sensor: Texture2D
var tex_gadget_buzzer: Texture2D
var tex_basic_tools: Texture2D

# Ninja Adventure animal sprites
var tex_ninja_cat: Texture2D
var tex_ninja_dog: Texture2D
var tex_ninja_cow: Texture2D
var tex_ninja_chicken: Texture2D
var tex_ninja_chicken_black: Texture2D
var tex_ninja_chicken_brown: Texture2D
var tex_ninja_chicken_white: Texture2D
var tex_ninja_horse: Texture2D
var tex_ninja_donkey: Texture2D
var tex_ninja_pig: Texture2D
var tex_ninja_frog: Texture2D
var tex_ninja_fish: Texture2D

# Ninja Adventure character sprites
var tex_ninja_oldwoman: Texture2D
var tex_ninja_villager: Texture2D
var tex_ninja_villager2: Texture2D
var tex_ninja_villager3: Texture2D
var tex_ninja_villager4: Texture2D
var tex_ninja_villager5: Texture2D
var tex_ninja_woman: Texture2D
var tex_ninja_monk: Texture2D
var tex_ninja_monk2: Texture2D
var tex_ninja_master: Texture2D
var tex_ninja_hunter: Texture2D
var tex_ninja_inspector: Texture2D
var tex_villager_elder: Texture2D
var tex_villager_elder_portrait: Texture2D
var tex_baker_robot: Texture2D
var tex_baker_robot_portrait: Texture2D
var tex_shop_robot: Texture2D
var tex_shop_robot_portrait: Texture2D
var tex_farmer_wen: Texture2D
var tex_farmer_wen_portrait: Texture2D
var tex_kid_milo: Texture2D
var tex_kid_milo_portrait: Texture2D
var tex_old_family_photo: Texture2D
var tex_grass_tileset: Texture2D
var tex_grass_tile: Texture2D
var tex_grass_tile_dark: Texture2D
var tex_dirt_tile: Texture2D
var tex_ninja_field: Texture2D  # Ninja Adventure TilesetField.png for ground tiles
var tex_ninja_oldman: Texture2D
var tex_ninja_oldman2: Texture2D
var tex_ninja_princess: Texture2D
var tex_ninja_noble: Texture2D

# Roaming animals data structure
var roaming_animals: Array = []

# Tumbleweeds
var tex_tumbleweed: Texture2D
var tumbleweeds: Array = []

# Asset paths
const SPROUT_PATH = "res://Sprout Lands - Sprites - Basic pack/"
const MYSTIC_PATH = "res://mystic_woods_free_2.2/sprites/"
const NINJA_PATH = "res://Ninja Adventure - Asset Pack/Actor/Characters/"
const NINJA_ANIMALS_PATH = "res://Ninja Adventure - Asset Pack/Actor/Animals/"
const TILESET_PATH = "res://Sprout Lands - Sprites - Basic pack/Tilesets/"
const OBJECTS_PATH = "res://Sprout Lands - Sprites - Basic pack/Objects/"
const PLAYER_ANIM_PATH = "res://player_sprite_and_animations/"
const GRANDMOTHER_ANIM_PATH = "res://elderly_Japanese_farmer_grandmother_sprite_short_g/"

# Combat sprites
var tex_robot_enemy: Texture2D

# Circuit schematic textures
# Circuit schematic textures (5 MVP circuits)
var tex_schematic_led_basic: Texture2D
var tex_schematic_buzzer_button: Texture2D
var tex_schematic_light_sensor: Texture2D
var tex_schematic_series_leds: Texture2D
var tex_schematic_dimmer: Texture2D

# Text wrap settings
const DIALOGUE_MAX_WIDTH = 340
const DIALOGUE_CHAR_WIDTH = 8

func set_quest(new_quest: String):
	if current_quest != new_quest:
		current_quest = new_quest
		quest_is_new = true
		quest_anim_timer = 0.0

func haptic_feedback(intensity: float = 0.3, duration: float = 0.1):
	# Controller rumble only (reduced intensity)
	Input.start_joy_vibration(0, intensity * 0.3, intensity * 0.6, duration)

func haptic_light():
	haptic_feedback(0.15, 0.04)

func haptic_medium():
	haptic_feedback(0.25, 0.07)

func haptic_heavy():
	haptic_feedback(0.45, 0.12)
	# Small screen shake for heavy feedback
	screen_shake = 2.0

func get_terrain_type() -> String:
	# Determine terrain based on area and position
	match current_area:
		Area.TOWN_CENTER:
			# Town center is mostly cobblestone
			if player_pos.x < 100:  # Left grass area near Farm sign
				return "grass"
			return "stone"
		Area.FARM:
			# Road is roughly y > 144 and y < 200
			if player_pos.y > 144 and player_pos.y < 200:
				return "dirt"
			# Near buildings
			if player_pos.y < 100:
				return "dirt"
			return "grass"
		Area.CORNFIELD:
			# Mostly dirt paths between corn
			if player_pos.y > 144 and player_pos.y < 200:
				return "dirt"
			return "grass"
		Area.LAKESIDE:
			# Near water
			if player_pos.y > 200:
				return "sand"
			return "grass"
	return "grass"

func haptic_footstep(delta: float):
	if not is_walking:
		footstep_timer = 0.0
		return
	
	footstep_timer += delta
	
	# Footstep interval based on terrain (reduced intensity)
	var terrain = get_terrain_type()
	var step_interval = 0.25  # Base interval
	var weak_motor = 0.0
	var strong_motor = 0.0
	var duration = 0.025
	
	match terrain:
		"grass":
			# Soft, gentle pulses
			step_interval = 0.28
			weak_motor = 0.08
			strong_motor = 0.03
			duration = 0.03
		"dirt":
			# Firmer steps
			step_interval = 0.25
			weak_motor = 0.12
			strong_motor = 0.05
			duration = 0.025
		"stone":
			# Hard, sharp feedback
			step_interval = 0.22
			weak_motor = 0.18
			strong_motor = 0.1
			duration = 0.02
		"sand":
			# Very soft
			step_interval = 0.3
			weak_motor = 0.05
			strong_motor = 0.01
			duration = 0.035
	
	if footstep_timer >= step_interval:
		footstep_timer = 0.0
		var foot_variation = randf_range(0.85, 1.15)
		Input.start_joy_vibration(0, weak_motor * foot_variation, strong_motor * foot_variation, duration)

# ============================================
# INTRO STORY TEXT
# ============================================

var intro_text = [
	[
		"AGRICOMMUNE",
		"",
		"You live on a small farming compound",
		"at the edge of the known world.",
		"",
		"Life is simple here.",
		"Machines tend the fields.",
		"",
		"In this land, every person is assigned",
		"a Helper robot at birth.",
		"",
		"Yours has been with you as long",
		"as you remember.",
		"",
		"So far, it has never spoken."
	],
	[
		"",
		"Tonight, the power is out.",
		"",
		"Grandmother needs tools",
		"from the storage shed.",
		"",
		"It's dark in there.",
		"You need a gadget to explore it.",
		"",
		"Your Helper flickers.",
		"For the first time, it speaks:",
		"",
		"\"I can help you.",
		"My name is KAIDO.",
		"Let's build an LED lamp.\""
	]
]

# Ending cutscene text
var ending_text = [
	"The tunnel stretches into darkness...",
	"Behind you, flames rise from Agricommune.",
	"Energy Nation's machines sweep through,",
	"searching for the ones who fled.",
	"",
	"Grandmother stayed behind.",
	"To give you time. To protect the others.",
	"",
	"Kaido's light guides the way forward.",
	"Toward New Sumida City.",
	"Toward Professor Ohm.",
	"Toward answers.",
	"",
	"This is just the beginning."
]

func _ready():
	load_sprites()
	# Initialize area drawing helper
	area_draw = AreaDraw.new(self)
	area_draw.set_shared_textures(tex_grass_biome, tex_water, tex_wooden_house, tex_fences, tex_chicken_house)
	# Initialize UI drawing helper
	ui_draw = UIDraw.new(self)
	# Initialize combat system
	combat_sys = CombatSys.new(self)
	# Initialize stampede system
	stampede_sys = StampedeSys.new(self)
	# Initialize interior scenes
	interior_sc = InteriorSc.new(self)
	# Initialize camera centered on player
	center_camera_on_player()
	# Debug: Print connected controllers
	var joypads = Input.get_connected_joypads()
	print("=== CONTROLLER DEBUG ===")
	print("Connected joypads: ", joypads.size())
	for joy_id in joypads:
		print("  Joypad ", joy_id, ": ", Input.get_joy_name(joy_id))
	print("========================")

func load_sprites():
	if ResourceLoader.exists(MYSTIC_PATH + "characters/player.png"):
		tex_player = load(MYSTIC_PATH + "characters/player.png")
	
	# Load player animation frames
	load_player_animations()
	
	# Load grandmother animation frames
	load_grandmother_animations()
	
	if ResourceLoader.exists(MYSTIC_PATH + "tilesets/grass.png"):
		tex_grass = load(MYSTIC_PATH + "tilesets/grass.png")
	
	# Load Kaido sprite - prioritize the drawn version
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_sprite_drawn.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido_sprite_drawn.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_small.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido_small.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido.png")

	if ResourceLoader.exists(SPROUT_PATH + "Characters/grandmother.png"):
		tex_grandmother = load(SPROUT_PATH + "Characters/grandmother.png")

	# Load Kaido portrait
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait_drawn.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait_drawn.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait_small.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait_small.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait.png")
	
	if ResourceLoader.exists(SPROUT_PATH + "Characters/grandmother_portrait.png"):
		tex_grandmother_portrait = load(SPROUT_PATH + "Characters/grandmother_portrait.png")
	
	# Load robot enemy sprite from Ninja Adventure
	var robot_paths = [
		NINJA_PATH + "Robot/Robot.png",
		NINJA_PATH + "Robot/SpriteSheet.png",
		NINJA_PATH + "Robots/Robot.png",
		"res://Ninja Adventure - Asset Pack/Actor/Enemies/Robot/Robot.png",
		"res://Ninja Adventure - Asset Pack/Actor/Enemies/Robot/SpriteSheet.png",
		"res://Ninja Adventure - Asset Pack/Enemies/Robot/Robot.png",
	]
	for path in robot_paths:
		if ResourceLoader.exists(path):
			tex_robot_enemy = load(path)
			break
	
	# Load tileset textures
	# Load Ninja Adventure TilesetFloor for ground (384x336, 16x16 tiles)
	var ninja_tileset_path = "res://Ninja Adventure - Asset Pack/Backgrounds/Tilesets/TilesetFloor.png"
	if ResourceLoader.exists(ninja_tileset_path):
		tex_ninja_field = load(ninja_tileset_path)
	if ResourceLoader.exists(TILESET_PATH + "Grass.png"):
		tex_grass = load(TILESET_PATH + "Grass.png")
	if ResourceLoader.exists(TILESET_PATH + "Tilled_Dirt.png"):
		tex_tiled_dirt = load(TILESET_PATH + "Tilled_Dirt.png")
	if ResourceLoader.exists(TILESET_PATH + "Tilled_Dirt_Wide.png"):
		tex_tiled_dirt_wide = load(TILESET_PATH + "Tilled_Dirt_Wide.png")
	if ResourceLoader.exists(TILESET_PATH + "Water.png"):
		tex_water = load(TILESET_PATH + "Water.png")
	if ResourceLoader.exists(TILESET_PATH + "Fences.png"):
		tex_fences = load(TILESET_PATH + "Fences.png")
	if ResourceLoader.exists(TILESET_PATH + "Doors.png"):
		tex_doors = load(TILESET_PATH + "Doors.png")
	if ResourceLoader.exists(TILESET_PATH + "Hills.png"):
		tex_hills = load(TILESET_PATH + "Hills.png")
	if ResourceLoader.exists(TILESET_PATH + "Wooden_House.png"):
		tex_wooden_house = load(TILESET_PATH + "Wooden_House.png")
	if ResourceLoader.exists(TILESET_PATH + "Wooden_House_Roof_Tilset.png"):
		tex_wooden_house_roof = load(TILESET_PATH + "Wooden_House_Roof_Tilset.png")
	if ResourceLoader.exists(TILESET_PATH + "Wooden_House_Walls_Tilset.png"):
		tex_wooden_house_walls = load(TILESET_PATH + "Wooden_House_Walls_Tilset.png")
	if ResourceLoader.exists(TILESET_PATH + "water_panel_sprite.png"):
		tex_water_panel = load(TILESET_PATH + "water_panel_sprite.png")
	if ResourceLoader.exists(TILESET_PATH + "Tilled_Dirt_Wide_v2.png"):
		tex_tiled_dirt_wide_v2 = load(TILESET_PATH + "Tilled_Dirt_Wide_v2.png")
	if ResourceLoader.exists(TILESET_PATH + "cliff_rock.png"):
		tex_cliff_rock = load(TILESET_PATH + "cliff_rock.png")
	if ResourceLoader.exists(TILESET_PATH + "lake_sand.png"):
		tex_lake_sand = load(TILESET_PATH + "lake_sand.png")
	
	# Load grass biome objects (trees, bushes, etc)
	if ResourceLoader.exists(OBJECTS_PATH + "Basic Grass Biom things 1.png"):
		tex_grass_biome = load(OBJECTS_PATH + "Basic Grass Biom things 1.png")
	
	# Load chicken house
	if ResourceLoader.exists(OBJECTS_PATH + "Free_Chicken_House.png"):
		tex_chicken_house = load(OBJECTS_PATH + "Free_Chicken_House.png")
	
	# Load shed
	if ResourceLoader.exists(OBJECTS_PATH + "shed.png"):
		tex_shed = load(OBJECTS_PATH + "shed.png")

	# Load sewer
	if ResourceLoader.exists(OBJECTS_PATH + "sewer.png"):
		tex_sewer = load(OBJECTS_PATH + "sewer.png")

	# Load chicken sprites
	if ResourceLoader.exists(SPROUT_PATH + "Characters/Free Chicken Sprites.png"):
		tex_chicken_sprites = load(SPROUT_PATH + "Characters/Free Chicken Sprites.png")
	
	# Load cow sprites
	if ResourceLoader.exists(SPROUT_PATH + "Characters/Free Cow Sprites.png"):
		tex_cow_sprites = load(SPROUT_PATH + "Characters/Free Cow Sprites.png")
	
	# Load basic tools
	if ResourceLoader.exists(OBJECTS_PATH + "Basic_tools_and_meterials.png"):
		tex_basic_tools = load(OBJECTS_PATH + "Basic_tools_and_meterials.png")
	
	# Load gadget icons
	if ResourceLoader.exists(OBJECTS_PATH + "flashlight.png"):
		tex_gadget_flashlight = load(OBJECTS_PATH + "flashlight.png")
	if ResourceLoader.exists(OBJECTS_PATH + "dimmer.png"):
		tex_gadget_dimmer = load(OBJECTS_PATH + "dimmer.png")
	if ResourceLoader.exists(OBJECTS_PATH + "led_chain.png"):
		tex_gadget_led_chain = load(OBJECTS_PATH + "led_chain.png")
	if ResourceLoader.exists(OBJECTS_PATH + "light_sensor.png"):
		tex_gadget_light_sensor = load(OBJECTS_PATH + "light_sensor.png")
	if ResourceLoader.exists(OBJECTS_PATH + "buzzer.png"):
		tex_gadget_buzzer = load(OBJECTS_PATH + "buzzer.png")
	if ResourceLoader.exists(OBJECTS_PATH + "tumbleweed.png"):
		tex_tumbleweed = load(OBJECTS_PATH + "tumbleweed.png")

	# Load Ninja Adventure animals
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Cat/SpriteSheet.png"):
		tex_ninja_cat = load(NINJA_ANIMALS_PATH + "Cat/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Dog/SpriteSheet.png"):
		tex_ninja_dog = load(NINJA_ANIMALS_PATH + "Dog/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Cow/SpriteSheet.png"):
		tex_ninja_cow = load(NINJA_ANIMALS_PATH + "Cow/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Chicken/SpriteSheet.png"):
		tex_ninja_chicken = load(NINJA_ANIMALS_PATH + "Chicken/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetBlack.png"):
		tex_ninja_chicken_black = load(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetBlack.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetBrown.png"):
		tex_ninja_chicken_brown = load(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetBrown.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetWhite.png"):
		tex_ninja_chicken_white = load(NINJA_ANIMALS_PATH + "Chicken/SpriteSheetWhite.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Horse/SpriteSheet.png"):
		tex_ninja_horse = load(NINJA_ANIMALS_PATH + "Horse/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Donkey/SpriteSheet.png"):
		tex_ninja_donkey = load(NINJA_ANIMALS_PATH + "Donkey/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Frog/SpriteSheet.png"):
		tex_ninja_frog = load(NINJA_ANIMALS_PATH + "Frog/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Fish/SpriteSheet.png"):
		tex_ninja_fish = load(NINJA_ANIMALS_PATH + "Fish/SpriteSheet.png")
	
	# Load Ninja Adventure characters
	if ResourceLoader.exists(NINJA_PATH + "OldWoman/SpriteSheet.png"):
		tex_ninja_oldwoman = load(NINJA_PATH + "OldWoman/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Villager/SpriteSheet.png"):
		tex_ninja_villager = load(NINJA_PATH + "Villager/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Villager2/SpriteSheet.png"):
		tex_ninja_villager2 = load(NINJA_PATH + "Villager2/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Villager3/SpriteSheet.png"):
		tex_ninja_villager3 = load(NINJA_PATH + "Villager3/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Villager4/SpriteSheet.png"):
		tex_ninja_villager4 = load(NINJA_PATH + "Villager4/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Villager5/SpriteSheet.png"):
		tex_ninja_villager5 = load(NINJA_PATH + "Villager5/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Woman/SpriteSheet.png"):
		tex_ninja_woman = load(NINJA_PATH + "Woman/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "OldMan/SpriteSheet.png"):
		tex_ninja_oldman = load(NINJA_PATH + "OldMan/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "OldMan2/SpriteSheet.png"):
		tex_ninja_oldman2 = load(NINJA_PATH + "OldMan2/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Princess/SpriteSheet.png"):
		tex_ninja_princess = load(NINJA_PATH + "Princess/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Noble/SpriteSheet.png"):
		tex_ninja_noble = load(NINJA_PATH + "Noble/SpriteSheet.png")
	
	# V2: Additional villager characters
	if ResourceLoader.exists(NINJA_PATH + "Monk/SpriteSheet.png"):
		tex_ninja_monk = load(NINJA_PATH + "Monk/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Monk2/SpriteSheet.png"):
		tex_ninja_monk2 = load(NINJA_PATH + "Monk2/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Master/SpriteSheet.png"):
		tex_ninja_master = load(NINJA_PATH + "Master/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Hunter/SpriteSheet.png"):
		tex_ninja_hunter = load(NINJA_PATH + "Hunter/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_PATH + "Inspector/SpriteSheet.png"):
		tex_ninja_inspector = load(NINJA_PATH + "Inspector/SpriteSheet.png")
	
	# Load custom villager elder sprite
	if ResourceLoader.exists(SPROUT_PATH + "Characters/villager_elder.png"):
		tex_villager_elder = load(SPROUT_PATH + "Characters/villager_elder.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/villager_elder_portrait.png"):
		tex_villager_elder_portrait = load(SPROUT_PATH + "Characters/villager_elder_portrait.png")
	
	# Load baker robot sprite
	if ResourceLoader.exists(SPROUT_PATH + "Characters/baker_robot.png"):
		tex_baker_robot = load(SPROUT_PATH + "Characters/baker_robot.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/baker_robot_portrait.png"):
		tex_baker_robot_portrait = load(SPROUT_PATH + "Characters/baker_robot_portrait.png")
	
	# Load shop robot sprite
	if ResourceLoader.exists(SPROUT_PATH + "Characters/shop_robot.png"):
		tex_shop_robot = load(SPROUT_PATH + "Characters/shop_robot.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/shop_robot_portrait.png"):
		tex_shop_robot_portrait = load(SPROUT_PATH + "Characters/shop_robot_portrait.png")
	
	# Load Farmer Wen sprite
	if ResourceLoader.exists(SPROUT_PATH + "Characters/farmer_wen.png"):
		tex_farmer_wen = load(SPROUT_PATH + "Characters/farmer_wen.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/farmer_wen_portrait.png"):
		tex_farmer_wen_portrait = load(SPROUT_PATH + "Characters/farmer_wen_portrait.png")
	
	# Load Kid Milo sprite
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kid_milo.png"):
		tex_kid_milo = load(SPROUT_PATH + "Characters/kid_milo.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kid_milo_portrait.png"):
		tex_kid_milo_portrait = load(SPROUT_PATH + "Characters/kid_milo_portrait.png")
	
	# Load old family photo
	if ResourceLoader.exists(SPROUT_PATH + "Characters/old_family_photo.png"):
		tex_old_family_photo = load(SPROUT_PATH + "Characters/old_family_photo.png")
	
	# Load grass tileset
	if ResourceLoader.exists(TILESET_PATH + "grass_tileset.png"):
		tex_grass_tileset = load(TILESET_PATH + "grass_tileset.png")
	if ResourceLoader.exists(TILESET_PATH + "grass_tile.png"):
		tex_grass_tile = load(TILESET_PATH + "grass_tile.png")
	if ResourceLoader.exists(TILESET_PATH + "grass_tile_dark.png"):
		tex_grass_tile_dark = load(TILESET_PATH + "grass_tile_dark.png")
	if ResourceLoader.exists(TILESET_PATH + "dirt_tile.png"):
		tex_dirt_tile = load(TILESET_PATH + "dirt_tile.png")

	# A1: Add Pig to animals
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Pig/SpriteSheet.png"):
		tex_ninja_pig = load(NINJA_ANIMALS_PATH + "Pig/SpriteSheet.png")

	# Load circuit schematic sprites
	# Load circuit schematic sprites (5 MVP circuits)
	# All schematics go in res://Sprout Lands/Schematics/
	if ResourceLoader.exists(SPROUT_PATH + "Schematics/schematic_led_basic.png"):
		tex_schematic_led_basic = load(SPROUT_PATH + "Schematics/schematic_led_basic.png")
	if ResourceLoader.exists(SPROUT_PATH + "Schematics/schematic_buzzer_button.png"):
		tex_schematic_buzzer_button = load(SPROUT_PATH + "Schematics/schematic_buzzer_button.png")
	if ResourceLoader.exists(SPROUT_PATH + "Schematics/schematic_light_sensor.png"):
		tex_schematic_light_sensor = load(SPROUT_PATH + "Schematics/schematic_light_sensor.png")
	if ResourceLoader.exists(SPROUT_PATH + "Schematics/schematic_series_leds.png"):
		tex_schematic_series_leds = load(SPROUT_PATH + "Schematics/schematic_series_leds.png")
	if ResourceLoader.exists(SPROUT_PATH + "Schematics/schematic_dimmer.png"):
		tex_schematic_dimmer = load(SPROUT_PATH + "Schematics/schematic_dimmer.png")
	
	# Initialize roaming animals for each area
	init_roaming_animals()
	init_tumbleweeds()

func load_player_animations():
	# Load walk animations (6 frames each direction)
	var directions = ["south", "north", "east", "west"]
	var frame_count = 6
	
	for dir in directions:
		var frames: Array[Texture2D] = []
		for i in range(frame_count):
			var path = PLAYER_ANIM_PATH + "animations/walk/" + dir + "/frame_%03d.png" % i
			if ResourceLoader.exists(path):
				frames.append(load(path))
		
		match dir:
			"south": tex_player_walk_south = frames
			"north": tex_player_walk_north = frames
			"east": tex_player_walk_east = frames
			"west": tex_player_walk_west = frames
	
	# Load attack/punch animations (cross-punch folder)
	for dir in directions:
		var frames: Array[Texture2D] = []
		for i in range(8):  # Try up to 8 frames
			var path = PLAYER_ANIM_PATH + "animations/cross-punch/" + dir + "/frame_%03d.png" % i
			if ResourceLoader.exists(path):
				frames.append(load(path))
		
		match dir:
			"south": tex_player_attack_south = frames
			"north": tex_player_attack_north = frames
			"east": tex_player_attack_east = frames
			"west": tex_player_attack_west = frames
	
	if tex_player_attack_south.size() > 0:
		print("âœ“ Player attack animations loaded: ", tex_player_attack_south.size(), " frames per direction")
	
	# Load idle/rotation sprites
	if ResourceLoader.exists(PLAYER_ANIM_PATH + "rotations/south.png"):
		tex_player_idle_south = load(PLAYER_ANIM_PATH + "rotations/south.png")
	if ResourceLoader.exists(PLAYER_ANIM_PATH + "rotations/north.png"):
		tex_player_idle_north = load(PLAYER_ANIM_PATH + "rotations/north.png")
	if ResourceLoader.exists(PLAYER_ANIM_PATH + "rotations/east.png"):
		tex_player_idle_east = load(PLAYER_ANIM_PATH + "rotations/east.png")
	if ResourceLoader.exists(PLAYER_ANIM_PATH + "rotations/west.png"):
		tex_player_idle_west = load(PLAYER_ANIM_PATH + "rotations/west.png")
	
	# Check if animations loaded successfully
	if tex_player_walk_south.size() > 0:
		player_anim_loaded = true
		print("âœ“ Player animations loaded: ", tex_player_walk_south.size(), " frames per direction")
	else:
		print("âœ— Player animations not found at: " + PLAYER_ANIM_PATH)

func load_grandmother_animations():
	# Load walk animations (6 frames each direction)
	var directions = ["south", "north", "east", "west"]
	
	for dir in directions:
		var frames: Array[Texture2D] = []
		for i in range(8):  # Try up to 8 frames
			var path = GRANDMOTHER_ANIM_PATH + "animations/walk/" + dir + "/frame_%03d.png" % i
			if ResourceLoader.exists(path):
				frames.append(load(path))
		
		match dir:
			"south": tex_grandmother_walk_south = frames
			"north": tex_grandmother_walk_north = frames
			"east": tex_grandmother_walk_east = frames
			"west": tex_grandmother_walk_west = frames
	
	# Load idle/rotation sprites
	if ResourceLoader.exists(GRANDMOTHER_ANIM_PATH + "rotations/south.png"):
		tex_grandmother_idle_south = load(GRANDMOTHER_ANIM_PATH + "rotations/south.png")
	if ResourceLoader.exists(GRANDMOTHER_ANIM_PATH + "rotations/north.png"):
		tex_grandmother_idle_north = load(GRANDMOTHER_ANIM_PATH + "rotations/north.png")
	if ResourceLoader.exists(GRANDMOTHER_ANIM_PATH + "rotations/east.png"):
		tex_grandmother_idle_east = load(GRANDMOTHER_ANIM_PATH + "rotations/east.png")
	if ResourceLoader.exists(GRANDMOTHER_ANIM_PATH + "rotations/west.png"):
		tex_grandmother_idle_west = load(GRANDMOTHER_ANIM_PATH + "rotations/west.png")
	
	# Check if animations loaded successfully
	if tex_grandmother_walk_south.size() > 0:
		grandmother_anim_loaded = true
		print("âœ“ Grandmother animations loaded: ", tex_grandmother_walk_south.size(), " frames per direction")
	else:
		print("âœ— Grandmother animations not found at: " + GRANDMOTHER_ANIM_PATH)

# ============================================
# GRANDMOTHER PACING & ANIMATION
# ============================================

func update_grandmother(delta: float):
	# Animation frame update
	grandmother_pace_timer += delta
	if grandmother_pace_timer > 0.15:
		grandmother_pace_timer = 0
		grandmother_frame = (grandmother_frame + 1) % 6
	
	# Stop pacing when player gets close (check this first)
	if grandmother_pacing and quest_stage == 0 and player_pos.distance_to(grandmother_pos) < 60:
		grandmother_pacing = false
		grandmother_is_walking = false
		# Face the player
		var to_player = player_pos - grandmother_pos
		if abs(to_player.x) > abs(to_player.y):
			grandmother_facing = "right" if to_player.x > 0 else "left"
		else:
			grandmother_facing = "down" if to_player.y > 0 else "up"
		return
	
	# Pacing behavior - only before first conversation (quest_stage 0)
	if grandmother_pacing and quest_stage == 0 and not in_dialogue:
		# Initialize pacing target
		if grandmother_pace_target == Vector2.ZERO:
			grandmother_pace_target = Vector2(400 + randf_range(-10, 10), 120 + randf_range(-5, 5))
			grandmother_pace_state = "walking"

		# State machine for natural pacing
		match grandmother_pace_state:
			"pausing":
				# Stand still for a moment at each end
				grandmother_pause_timer -= delta
				grandmother_is_walking = false
				if grandmother_pause_timer <= 0:
					# Randomly decide to look around or start walking
					if randf() < 0.3:
						grandmother_pace_state = "looking"
						grandmother_pause_timer = randf_range(0.5, 1.2)
						# Look in a random direction
						grandmother_facing = ["up", "down", "left", "right"][randi() % 4]
					else:
						grandmother_pace_state = "walking"
						grandmother_pace_speed = randf_range(22, 35)

			"looking":
				# Looking around before walking
				grandmother_pause_timer -= delta
				grandmother_is_walking = false
				if grandmother_pause_timer <= 0:
					grandmother_pace_state = "walking"
					grandmother_pace_speed = randf_range(22, 35)

			"walking":
				var dist_to_target = grandmother_pos.distance_to(grandmother_pace_target)
				if dist_to_target > 8:
					var dir = (grandmother_pace_target - grandmother_pos).normalized()
					# Ease speed - slower near endpoints
					var speed_mult = min(1.0, dist_to_target / 40.0)
					speed_mult = max(0.4, speed_mult)
					grandmother_pos += dir * grandmother_pace_speed * speed_mult * delta
					grandmother_is_walking = true

					# Update facing based on movement direction
					if dir.x > 0.1:
						grandmother_facing = "right"
					elif dir.x < -0.1:
						grandmother_facing = "left"
				else:
					# Reached target, pause before turning
					grandmother_pace_state = "pausing"
					grandmother_pause_timer = randf_range(0.8, 2.0)
					grandmother_is_walking = false
					# Set new target with slight randomization
					if grandmother_pace_target.x > 350:
						grandmother_pace_target = Vector2(280 + randf_range(-15, 15), 120 + randf_range(-8, 8))
					else:
						grandmother_pace_target = Vector2(400 + randf_range(-15, 15), 120 + randf_range(-8, 8))
		return
	
	# Quest stage 7: Grandmother leads player to irrigation
	if quest_stage == 7 and not in_dialogue:
		if player_pos.distance_to(grandmother_pos) < 50:
			grandmother_target = Vector2(140, 220)
			if grandmother_pos.distance_to(grandmother_target) > 5:
				set_quest("Fix Irrigation")
	
	# Standard movement toward target (for quest movement like leading to irrigation)
	if grandmother_pos.distance_to(grandmother_target) > 5:
		var dir = (grandmother_target - grandmother_pos).normalized()
		grandmother_pos += dir * 40 * delta
		grandmother_is_walking = true
		
		# Update facing
		if abs(dir.x) > abs(dir.y):
			grandmother_facing = "right" if dir.x > 0 else "left"
		else:
			grandmother_facing = "down" if dir.y > 0 else "up"
	else:
		grandmother_is_walking = false

# ============================================
# ROAMING ANIMALS SYSTEM
# ============================================

func init_roaming_animals():
	roaming_animals.clear()

	# Cornfield area animals
	roaming_animals.append({"area": "cornfield", "type": "chicken", "pos": Vector2(100, 150), "target": Vector2(100, 150), "speed": 6.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "chicken", "pos": Vector2(350, 200), "target": Vector2(350, 200), "speed": 6.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "horse", "pos": Vector2(380, 120), "target": Vector2(380, 120), "speed": 16.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "dog", "pos": Vector2(80, 250), "target": Vector2(80, 250), "speed": 18.0, "timer": 0.0, "dir": 0})
	
	# Lakeside area animals (positions for top-down view)
	roaming_animals.append({"area": "lakeside", "type": "frog", "pos": Vector2(260, 280), "target": Vector2(260, 280), "speed": 20.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "lakeside", "type": "frog", "pos": Vector2(200, 220), "target": Vector2(200, 220), "speed": 20.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "lakeside", "type": "cat", "pos": Vector2(60, 150), "target": Vector2(60, 150), "speed": 15.0, "timer": 0.0, "dir": 0})
	
	# Town center area animals
	roaming_animals.append({"area": "town_center", "type": "dog", "pos": Vector2(100, 200), "target": Vector2(100, 200), "speed": 18.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "cat", "pos": Vector2(380, 150), "target": Vector2(380, 150), "speed": 15.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "chicken", "pos": Vector2(200, 260), "target": Vector2(200, 260), "speed": 6.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "donkey", "pos": Vector2(400, 240), "target": Vector2(400, 240), "speed": 12.0, "timer": 0.0, "dir": 0})

func update_roaming_animals(delta: float):
	for animal in roaming_animals:
		# Update timer
		animal.timer -= delta
		
		# Pick new target when timer expires
		if animal.timer <= 0:
			animal.timer = randf_range(4.0, 10.0)  # Stay in place longer
			# Chickens stay close to their current position, others roam more
			if animal.type == "chicken":
				# Chickens only move small distances (pecking around)
				animal.target = Vector2(
					animal.pos.x + randf_range(-25, 25),
					animal.pos.y + randf_range(-15, 15)
				)
			else:
				# Other animals roam smaller area for smoother movement
				animal.target = Vector2(
					animal.pos.x + randf_range(-60, 60),
					animal.pos.y + randf_range(-40, 40)
				)
				# Clamp to area bounds
				var bounds = get_area_bounds(animal.area)
				animal.target.x = clamp(animal.target.x, bounds.position.x + 20, bounds.position.x + bounds.size.x - 20)
				animal.target.y = clamp(animal.target.y, bounds.position.y + 20, bounds.position.y + bounds.size.y - 20)
		
		# Move towards target smoothly
		var dir = (animal.target - animal.pos)
		if dir.length() > 3:
			dir = dir.normalized()
			animal.pos += dir * animal.speed * delta
			# Update direction for sprite (0=down, 1=left, 2=right, 3=up)
			if abs(dir.x) > abs(dir.y):
				animal.dir = 1 if dir.x < 0 else 2
			else:
				animal.dir = 3 if dir.y < 0 else 0

func get_area_bounds(area: String) -> Rect2:
	match area:
		"farm":
			return Rect2(40, 40, 400, 240)
		"cornfield":
			return Rect2(40, 80, 400, 200)
		"lakeside":
			return Rect2(30, 50, 180, 250)  # Left grassy area, avoiding lake
		"town_center":
			return Rect2(40, 100, 400, 180)
		_:
			return Rect2(40, 40, 400, 240)

func draw_roaming_animals_for_area(area_name: String):
	for animal in roaming_animals:
		if animal.area == area_name:
			draw_ninja_animal(animal.pos, animal.type, animal.dir)

func draw_ninja_animal(pos: Vector2, animal_type: String, direction: int):
	var tex: Texture2D = null

	# Handle chickens specially with color variants
	if animal_type == "chicken":
		var color_idx = int(abs(pos.x * 7 + pos.y * 13)) % 3
		match color_idx:
			0: tex = tex_ninja_chicken_black
			1: tex = tex_ninja_chicken_brown
			2: tex = tex_ninja_chicken_white
		if not tex:
			tex = tex_ninja_chicken

		if tex:
			draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(5, 2), Color(0, 0, 0, 0.25))
			var frame_idx = int(continuous_timer * 4 + pos.x * 0.1) % 2
			var src = Rect2(frame_idx * 16, 0, 16, 16)
			var sprite_size = 24.0
			var dest = Rect2(pos.x - sprite_size / 2, pos.y - sprite_size + 4, sprite_size, sprite_size)
			draw_texture_rect_region(tex, dest, src)
			return

	match animal_type:
		"cat": tex = tex_ninja_cat
		"dog": tex = tex_ninja_dog
		"cow": tex = tex_ninja_cow
		"horse": tex = tex_ninja_horse
		"donkey": tex = tex_ninja_donkey
		"frog": tex = tex_ninja_frog
		"fish": tex = tex_ninja_fish
		"pig": tex = tex_ninja_pig

	if not tex:
		# Draw fallback colored circle if no texture
		var color = Color(0.6, 0.4, 0.3)
		match animal_type:
			"cat": color = Color(0.8, 0.6, 0.4)
			"dog": color = Color(0.7, 0.5, 0.3)
		draw_circle(pos, 8, color)
		return

	# Scale based on animal type
	var scale = 1.5
	match animal_type:
		"cow", "horse": scale = 1.8
		"dog", "cat": scale = 1.4
		"frog": scale = 1.3

	# Draw shadow
	draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(5, 2), Color(0, 0, 0, 0.25))

	# Fixed 16x16 frame from position (0,0) - first frame, no animation
	var src = Rect2(0, 0, 16, 16)
	var sprite_size = 16 * scale
	var dest = Rect2(pos.x - sprite_size / 2, pos.y - sprite_size + 4, sprite_size, sprite_size)
	draw_texture_rect_region(tex, dest, src)

# ============================================
# TUMBLEWEED SYSTEM
# ============================================

func init_tumbleweeds():
	tumbleweeds.clear()
	# All tumbleweeds blow right to left (wind direction)
	# Place them along horizontal path edges
	var y_positions = [
		139,  # Top edge of horizontal path
		197,  # Bottom edge of horizontal path
		280,  # Near bottom of screen
		100,  # Upper area
	]
	for i in range(4):
		tumbleweeds.append({
			"pos": Vector2(randf_range(50, 450), y_positions[i]),
			"base_y": y_positions[i],
			"speed": randf_range(6, 12),
			"rotation": randf_range(0, TAU),
			"bounce_offset": randf_range(0, TAU),
			"size": randf_range(0.5, 0.75)
		})

func update_tumbleweeds(delta: float):
	for weed in tumbleweeds:
		# Move right to left (wind direction)
		weed.pos.x -= weed.speed * delta
		# Small vertical wobble to stay grounded
		weed.pos.y = weed.base_y + sin(continuous_timer * 2 + weed.bounce_offset) * 2
		# Rotate slowly
		weed.rotation += delta * 1.5
		# Wrap around when off-screen left
		if weed.pos.x < -15:
			weed.pos.x = 490
			weed.speed = randf_range(6, 12)

func draw_tumbleweeds():
	for weed in tumbleweeds:
		draw_tumbleweed(weed.pos, weed.rotation, weed.size)

func draw_tumbleweed(pos: Vector2, rotation: float, size_mult: float):
	if tex_tumbleweed:
		var tex_size = tex_tumbleweed.get_size()
		var scale = 0.94 * size_mult
		var dest_size = tex_size * scale
		# Draw with rotation by using transform
		var dest = Rect2(pos.x - dest_size.x / 2, pos.y - dest_size.y / 2, dest_size.x, dest_size.y)
		draw_texture_rect(tex_tumbleweed, dest, false)
	else:
		# Fallback: draw a simple brown circle
		draw_circle(pos, 5 * size_mult, Color(0.6, 0.45, 0.3))

# ============================================
# AUDIO GENERATION FUNCTIONS
# ============================================

func _process(delta):
	anim_timer += delta
	continuous_timer += delta  # Never resets
	if anim_timer > 0.15:
		anim_timer = 0
		player_frame = (player_frame + 1) % 6
	
	# Update player attack animation
	if player_attacking:
		player_attack_timer += delta
		# Advance attack frame (faster than walk)
		if player_attack_timer > 0.08:
			player_attack_timer = 0
			player_attack_frame += 1
			# Attack animation complete after all frames
			var max_frames = tex_player_attack_south.size() if tex_player_attack_south.size() > 0 else 6
			if player_attack_frame >= max_frames:
				player_attacking = false
				player_attack_frame = 0
	
	# Decay screen shake
	if screen_shake > 0:
		screen_shake = max(0, screen_shake - delta * 15.0)
	
	# Update screen transition effect
	if screen_transition_active:
		if screen_transition_phase == 1:  # Fading in (from black)
			screen_transition_alpha -= delta * screen_transition_speed
			if screen_transition_alpha <= 0:
				screen_transition_alpha = 0
				screen_transition_active = false
	
	# Process procedural music
	
	# Update water animation
	if water_flowing:
		water_anim += delta * 3.0
	
	# Update quest animation
	if quest_is_new:
		quest_anim_timer += delta
		if quest_anim_timer > 3.0:  # Animate for 3 seconds
			quest_is_new = false
			quest_anim_timer = 0.0
	
	# Update kaido tip timer
	if kaido_tip_timer > 0:
		kaido_tip_timer -= delta
	
	# Update patrol
	if patrol_active:
		patrol_timer += delta
		update_patrol(delta)
		update_stealth(delta)
	
	# Update grandmother pacing and movement
	update_grandmother(delta)
	
	# Update roaming animals
	update_roaming_animals(delta)

	# Update tumbleweeds on farm
	if current_area == Area.FARM:
		update_tumbleweeds(delta)

	# Grandmother leads player to irrigation at quest stage 7
	if quest_stage == 7 and not in_dialogue:
		# When player gets close, grandmother starts walking to irrigation
		if player_pos.distance_to(grandmother_pos) < 50:
			grandmother_target = Vector2(140, 220)
			# Update quest once she starts moving
			if grandmother_target != grandmother_pos:
				set_quest("Fix Irrigation")
	
	# Update kid walk-in animation
	if kid_visible and kid_walking_in:
		if kid_pos.distance_to(kid_target_pos) > 3:
			var dir = (kid_target_pos - kid_pos).normalized()
			kid_pos += dir * 80 * delta  # Kid runs fast
		else:
			kid_walking_in = false
	
	# Update farmer wen walk-in animation
	if farmer_wen_visible and farmer_wen_walking_in:
		if farmer_wen_pos.distance_to(farmer_wen_target_pos) > 3:
			var dir = (farmer_wen_target_pos - farmer_wen_pos).normalized()
			farmer_wen_pos += dir * 45 * delta  # Farmer walks slower
			# Tractor follows farmer
			var tractor_dir = (tractor_target_pos - tractor_pos).normalized()
			tractor_pos += tractor_dir * 45 * delta
		else:
			farmer_wen_walking_in = false
			tractor_visible = true
	
	# Update farmer wen leaving
	if farmer_wen_visible and farmer_wen_leaving:
		var dir = (farmer_wen_target_pos - farmer_wen_pos).normalized()
		farmer_wen_pos += dir * 60 * delta
		var tractor_dir = (tractor_target_pos - tractor_pos).normalized()
		tractor_pos += tractor_dir * 60 * delta
		# Off screen? Remove
		if farmer_wen_pos.x > 520:
			farmer_wen_visible = false
			farmer_wen_leaving = false
			tractor_visible = false
	
	# Update component popup
	if showing_component_popup:
		component_popup_timer += delta
	
	# Update gadget timers
	update_gadget_timers(delta)
	
	# Update nightfall transition
	if is_nightfall and nightfall_alpha < 0.6:
		nightfall_alpha += delta * 0.3
	
	match current_mode:
		GameMode.INTRO:
			process_intro_text(delta)
		GameMode.EXPLORATION:
			if in_dialogue:
				process_dialogue(delta)
			else:
				process_movement(delta)
			update_kaido_follow(delta)
		GameMode.SHED_INTERIOR:
			process_flashlight(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.PHOTOGRAPH:
			if photo_fade < 1.0:
				photo_fade += delta * 0.8
		GameMode.BUILD_SCREEN, GameMode.SCHEMATIC_POPUP:
			process_dialogue(delta)
		GameMode.BACKPACK_POPUP:
			if backpack_anim < 1.0:
				backpack_anim += delta * 2.0
		GameMode.COMBAT:
			process_combat(delta)
		GameMode.RADIOTOWER_INTERIOR:
			process_radiotower_interior(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.RADIOTOWER_VIEW:
			if in_dialogue:
				process_dialogue(delta)
		GameMode.STAMPEDE:
			process_stampede(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.SHOP_INTERIOR:
			process_building_interior(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.TOWNHALL_INTERIOR:
			process_building_interior(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.BAKERY_INTERIOR:
			process_building_interior(delta)
			if in_dialogue:
				process_dialogue(delta)
		GameMode.ENDING_CUTSCENE:
			ending_timer += delta
			if ending_timer > 3.0:
				ending_timer = 0
				ending_stage += 1
				if ending_stage >= 5:
					current_mode = GameMode.REGION_COMPLETE
	
	queue_redraw()

# ============================================
# UNIFIED INPUT SYSTEM
# ============================================

const INPUT_DEADZONE = 0.3

# Get 4-directional input (for exploration, interiors)
func get_input_4dir() -> Vector2:
	var input = Vector2.ZERO
	
	# Keyboard/action input
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Joystick input (overrides if significant)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_x) > INPUT_DEADZONE:
		input.x = sign(joy_x)
	if abs(joy_y) > INPUT_DEADZONE:
		input.y = sign(joy_y)
	
	return input

# Get horizontal input only (for combat, platforming, stampede)
func get_input_horizontal() -> float:
	var input_x = 0.0
	
	if Input.is_action_pressed("move_left"):
		input_x -= 1
	if Input.is_action_pressed("move_right"):
		input_x += 1
	
	# Joystick
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(joy_x) > INPUT_DEADZONE:
		input_x = sign(joy_x)
	
	return input_x

# Check for jump input (platforming sections)
func is_jump_just_pressed() -> bool:
	if Input.is_action_just_pressed("ui_accept"):
		return true
	if Input.is_action_just_pressed("ui_select"):
		return true
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_SPACE):
		return true
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
		return true
	return false

# Check for attack/interact input
func is_attack_just_pressed() -> bool:
	if Input.is_action_just_pressed("attack"):
		return true
	if Input.is_key_pressed(KEY_X):
		return true
	if Input.is_joy_button_pressed(0, JOY_BUTTON_X):
		return true
	return false

# Check for counter input (combat)
func is_counter_just_pressed() -> bool:
	if Input.is_action_just_pressed("counter"):
		return true
	if Input.is_key_pressed(KEY_C):
		return true
	if Input.is_joy_button_pressed(0, JOY_BUTTON_Y):
		return true
	return false

# Update player facing direction from input
func update_facing_from_input(input: Vector2):
	if input.x > 0.1:
		player_facing = "right"
	elif input.x < -0.1:
		player_facing = "left"
	elif input.y > 0.1:
		player_facing = "down"
	elif input.y < -0.1:
		player_facing = "up"

func process_movement(delta):
	# Can't move if detected
	if player_detected:
		is_walking = false
		return
	
	# Get input using unified system
	var input = get_input_4dir()
	
	# Update facing direction
	if input.length() > 0:
		update_facing_from_input(input)
	
	# If hiding and trying to move, break stealth
	if is_hiding and input.length() > 0:
		is_hiding = false
	
	is_walking = input.length() > 0
	
	if is_walking:
		input = input.normalized()
		var new_pos = player_pos + input * player_speed * delta
		var moved = false
		
		# Terrain-based haptic feedback
		haptic_footstep(delta)
		
		# Check collision with buildings
		if not check_collision(new_pos):
			player_pos = new_pos
			moved = true
		else:
			# Try sliding along walls
			var slide_x = Vector2(player_pos.x + input.x * player_speed * delta, player_pos.y)
			var slide_y = Vector2(player_pos.x, player_pos.y + input.y * player_speed * delta)
			if not check_collision(slide_x):
				player_pos = slide_x
				moved = true
			elif not check_collision(slide_y):
				player_pos = slide_y
				moved = true
		
		# Stuck detection - if trying to move but not moving
		if not moved:
			player_stuck_timer += delta
			if player_stuck_timer > 0.5:
				# Push player out of stuck position
				push_player_out_of_stuck()
				player_stuck_timer = 0.0
		else:
			player_stuck_timer = 0.0
			player_last_pos = player_pos
		
		# Check area transitions based on current area
		check_area_transitions()
		
		# Clamp to current area bounds
		match current_area:
			Area.FARM:
				player_pos.x = clamp(player_pos.x, 15, 465)
				player_pos.y = clamp(player_pos.y, 20, 305)
			Area.CORNFIELD, Area.LAKESIDE, Area.TOWN_CENTER:
				player_pos.x = clamp(player_pos.x, 15, 465)
				player_pos.y = clamp(player_pos.y, 20, 305)
		
		# Update camera offset based on player position
		update_camera()
	else:
		player_stuck_timer = 0.0

func check_area_transitions():
	# Only check transitions in EXPLORATION mode
	if current_mode != GameMode.EXPLORATION:
		return
	
	match current_area:
		Area.FARM:
			# Up = Cornfield - only via vertical path (no longer quest-locked)
			if player_pos.y < 25:
				if player_pos.x > 195 and player_pos.x < 270:  # On the vertical path
					enter_area(Area.CORNFIELD)
					player_pos.y = 290
			# Down = Lakeside - only via vertical path
			if player_pos.y > 300:
				if player_pos.x > 195 and player_pos.x < 270:  # On the vertical path
					enter_area(Area.LAKESIDE)
					player_pos.y = 30
			# Left = Stampede - only via horizontal path
			if player_pos.x < 20:
				if player_pos.y > 140 and player_pos.y < 200:  # On the horizontal path
					start_stampede()
			# Right = Town Center - only via horizontal path
			if player_pos.x > 460:
				if player_pos.y > 140 and player_pos.y < 200:  # On the horizontal path
					enter_area(Area.TOWN_CENTER)
					player_pos.x = 30
					player_pos.y = 160  # Center of town road
		
		Area.CORNFIELD:
			# Down = back to Farm - only via the dirt path
			if player_pos.y > 300:
				if player_pos.x > 195 and player_pos.x < 285:  # On the dirt path (200-280 + margin)
					enter_area(Area.FARM)
					player_pos.y = 30
					player_pos.x = 232  # Center of vertical path
		
		Area.LAKESIDE:
			# Up = back to Farm - only via the shore path area
			if player_pos.y < 25:
				if player_pos.x > 195 and player_pos.x < 285:  # Aligned with farm path
					enter_area(Area.FARM)
					player_pos.y = 290
					player_pos.x = 232  # Center of vertical path
		
		Area.TOWN_CENTER:
			# Left = back to Farm - only via the road
			if player_pos.x < 20:
				if player_pos.y > 125 and player_pos.y < 195:  # On the road (y: 130-190)
					enter_area(Area.FARM)
					player_pos.x = 450
					player_pos.y = 170  # Center of horizontal path

func enter_area(area: Area):
	current_area = area
	
	# Trigger screen transition effect
	screen_transition_active = true
	screen_transition_alpha = 1.0  # Start fully black
	screen_transition_phase = 1  # Fade in from black
	
	# Reset Kaido position and trail history to prevent bouncing
	kaido_trail_history.clear()
	kaido_pos = player_pos + Vector2(-20, -15)
	
	match area:
		Area.FARM:
			pass
		Area.CORNFIELD:
			if not cornfield_led_placed and quest_stage == 12:
				dialogue_queue = [
					{"speaker": "kaido", "text": "The farmers up here need to see the signal."},
					{"speaker": "kaido", "text": "We should place LED markers along the path."},
				]
				next_dialogue()
		Area.LAKESIDE:
			pass
		Area.TOWN_CENTER:
			if not town_visited:
				town_visited = true
				dialogue_queue = [
					{"speaker": "kaido", "text": "The town center. Most villagers live here."},
				]
				next_dialogue()

func check_collision(pos: Vector2) -> bool:
	var player_rect = Rect2(pos.x - 8, pos.y - 5, 16, 10)
	
	# Only check building collisions in farm area
	if current_area == Area.FARM:
		for building in building_collisions:
			if player_rect.intersects(building):
				return true
		
		# Check NPCs (circular collision)
		if grandmother_pos.distance_to(pos) < 18:
			return true
		if farmer_wen_visible and farmer_wen_pos.distance_to(pos) < 20:
			return true
		if kid_visible and kid_pos.distance_to(pos) < 15:
			return true
		# Tractor collision when visible
		if tractor_visible and tractor_pos.distance_to(pos) < 25:
			return true
		# Patrol robot collision when active
		if patrol_active:
			for patrol_pos in patrol_positions:
				if patrol_pos.distance_to(pos) < 20:
					return true
	
	elif current_area == Area.CORNFIELD:
		# Collision with cornfield NPCs
		for npc in cornfield_npcs:
			if npc.pos.distance_to(pos) < 18:
				return true
		# Farmhouse collision
		if player_rect.intersects(Rect2(350, 40, 60, 35)):
			return true
		# Corn field - player can now walk through freely
		# (collision removed for exploration)
		pass
	
	elif current_area == Area.LAKESIDE:
		# Collision with lakeside NPCs
		for npc in lakeside_npcs:
			if npc.pos.distance_to(pos) < 18:
				return true
		# Lake collision (top-down view - organic shape on right side)
		# Main lake body centered around (340, 160)
		var in_lake = false
		if Vector2(340, 160).distance_to(pos) < 110:
			in_lake = true
		if Vector2(380, 140).distance_to(pos) < 80:
			in_lake = true
		if Vector2(300, 190).distance_to(pos) < 70:
			in_lake = true
		# Allow dock area (extends from west shore into lake)
		var on_dock = pos.x > 140 and pos.x < 220 and pos.y > 140 and pos.y < 190
		if in_lake and not on_dock:
			return true
		# Sewer sprite collision (64x64 at draw pos 410, 255)
		# Only block the upper/back portion, allow player to approach from front
		var sewer_draw_x = tunnel_pos.x - 20  # 410
		var sewer_draw_y = tunnel_pos.y - 30  # 255
		# Block walking into the sewer structure (upper 40px of sprite)
		if pos.x > sewer_draw_x and pos.x < sewer_draw_x + 64 and pos.y > sewer_draw_y and pos.y < sewer_draw_y + 40:
			return true
		# Decorative rocks on shore
		if Vector2(80, 200).distance_to(pos) < 15:
			return true
		if Vector2(120, 280).distance_to(pos) < 18:
			return true
		# Trees along edges
		if Vector2(40, 60).distance_to(pos) < 20:
			return true
		if Vector2(30, 280).distance_to(pos) < 20:
			return true
		if Vector2(460, 300).distance_to(pos) < 18:
			return true
	
	elif current_area == Area.TOWN_CENTER:
		# Collision with town NPCs
		for npc in town_npcs:
			if npc.pos.distance_to(pos) < 18:
				return true
		
		# Fountain collision (center of plaza) - smaller radius
		if Vector2(240, 170).distance_to(pos) < 26:
			return true
		
		# Well collision (lower in grass)
		if Vector2(240, 285).distance_to(pos) < 30:
			return true
		
		# Building collisions with door openings
		# Shop - main body, with door opening at bottom center (x: 55-85)
		if player_rect.intersects(Rect2(29, 19, 82, 62)):  # Top portion stops before door
			return true
		if player_rect.intersects(Rect2(29, 81, 26, 10)):  # Left side of door
			return true
		if player_rect.intersects(Rect2(85, 81, 26, 10)):  # Right side of door
			return true
		
		# Town Hall - with center door opening (x: 225-255)
		if player_rect.intersects(Rect2(169, 14, 142, 80)):  # Top portion
			return true
		if player_rect.intersects(Rect2(169, 94, 56, 13)):  # Left of door
			return true
		if player_rect.intersects(Rect2(255, 94, 56, 13)):  # Right of door
			return true
		
		# Bakery - with door opening (x: 395-415)
		if player_rect.intersects(Rect2(369, 24, 72, 58)):  # Top portion
			return true
		if player_rect.intersects(Rect2(369, 82, 26, 10)):  # Left of door
			return true
		if player_rect.intersects(Rect2(415, 82, 26, 10)):  # Right of door
			return true
		
		# House 1 - drawn at (50, 210) with size ~62x52
		if player_rect.intersects(Rect2(49, 209, 62, 52)):
			return true
		# House 2 - drawn at (370, 220) with size ~72x58
		if player_rect.intersects(Rect2(369, 219, 72, 58)):
			return true
		
		# Market stall collision
		if player_rect.intersects(Rect2(380, 140, 60, 50)):
			return true
		
		# Benches
		if player_rect.intersects(Rect2(140, 200, 30, 14)):
			return true
		if player_rect.intersects(Rect2(320, 200, 30, 14)):
			return true
		
		# Lamp posts
		if Vector2(132, 145).distance_to(pos) < 8:
			return true
		if Vector2(352, 145).distance_to(pos) < 8:
			return true
		
		# Barrels
		if Vector2(125, 125).distance_to(pos) < 12:
			return true
		if Vector2(365, 125).distance_to(pos) < 12:
			return true
		if Vector2(125, 230).distance_to(pos) < 12:
			return true
		if Vector2(365, 230).distance_to(pos) < 12:
			return true
		
		# Cherry blossom trees (trunks) - positioned in corners
		if Vector2(25, 25).distance_to(pos) < 15:   # Top left corner
			return true
		if Vector2(465, 25).distance_to(pos) < 15:  # Top right corner
			return true
		if Vector2(25, 275).distance_to(pos) < 15:  # Bottom left corner
			return true
		if Vector2(465, 275).distance_to(pos) < 15: # Bottom right corner
			return true
	
	return false

func push_player_out_of_stuck():
	# Try to find nearest non-colliding position
	# Check in 8 directions at increasing distances
	var directions = [
		Vector2(0, -1),   # Up
		Vector2(0, 1),    # Down
		Vector2(-1, 0),   # Left
		Vector2(1, 0),    # Right
		Vector2(-1, -1).normalized(),  # Up-left
		Vector2(1, -1).normalized(),   # Up-right
		Vector2(-1, 1).normalized(),   # Down-left
		Vector2(1, 1).normalized(),    # Down-right
	]
	
	# Try distances from 25 to 100 pixels
	for dist in [25, 40, 60, 80, 100]:
		for dir in directions:
			var test_pos = player_pos + dir * dist
			if not check_collision(test_pos):
				# Found a clear spot - teleport there
				player_pos = test_pos
				# Clamp to bounds
				player_pos.x = clamp(player_pos.x, 15, 465)
				player_pos.y = clamp(player_pos.y, 20, 305)
				return
	
	# Last resort - move to center of current area
	match current_area:
		Area.FARM:
			player_pos = Vector2(240, 180)
		Area.CORNFIELD:
			player_pos = Vector2(240, 180)
		Area.LAKESIDE:
			player_pos = Vector2(240, 180)
		Area.TOWN_CENTER:
			player_pos = Vector2(240, 180)

func update_camera():
	# Camera follows player, centered on screen
	# At 2x zoom, visible area is 240x160, so we offset to keep player centered
	var screen_center = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
	var visible_width = SCREEN_WIDTH / GAME_ZOOM
	var visible_height = SCREEN_HEIGHT / GAME_ZOOM
	
	# Target offset to center player on screen
	var target_offset = screen_center / GAME_ZOOM - player_pos
	
	# Clamp so we don't show outside the map (0,0 to 480,320)
	# At 2x zoom, we see 240x160 pixels of the world
	var min_x = -(480 - visible_width)  # Can't scroll past right edge
	var max_x = 0  # Can't scroll past left edge
	var min_y = -(320 - visible_height)  # Can't scroll past bottom
	var max_y = 0  # Can't scroll past top
	
	target_offset.x = clamp(target_offset.x, min_x, max_x)
	target_offset.y = clamp(target_offset.y, min_y, max_y)
	
	# Smooth camera - follow player position directly (no lerp jitter)
	camera_offset = target_offset

func update_kaido_follow(delta):
	# Teleport if way too far (after scene transitions) - check FIRST
	if kaido_pos.distance_to(player_pos) > 100:
		kaido_trail_history.clear()
		kaido_pos = player_pos + Vector2(-20, -15)  # Position behind player
		return
	
	# Record player position in trail history
	kaido_trail_history.append(player_pos)
	
	# Keep trail at fixed length (longer = more distance behind)
	while kaido_trail_history.size() > kaido_trail_delay:
		kaido_trail_history.pop_front()
	
	# Get target position (where player was N frames ago)
	var target_pos = player_pos
	if kaido_trail_history.size() > 0:
		target_pos = kaido_trail_history[0]
	
	# Move Kaido toward target smoothly
	kaido_pos = kaido_pos.lerp(target_pos, 0.15)
	
	# ALWAYS ensure minimum separation from player
	var to_kaido = kaido_pos - player_pos
	var dist = to_kaido.length()
	var min_separation = 25  # Minimum distance Kaido should be from player
	
	if dist < min_separation:
		if dist > 1:
			# Push Kaido away in current direction
			var push_dir = to_kaido.normalized()
			kaido_pos = player_pos + push_dir * min_separation
		else:
			# Too close/overlapping, place to upper-left (behind player visually)
			kaido_pos = player_pos + Vector2(-20, -15)

func process_flashlight(delta):
	# Move flashlight with arrow keys in shed
	var input = get_input_4dir()
	
	if input.length() > 0:
		input = input.normalized()
		flashlight_pos += input * flashlight_speed * delta
		flashlight_pos.x = clamp(flashlight_pos.x, 50, 430)
		flashlight_pos.y = clamp(flashlight_pos.y, 50, 280)

func process_dialogue(delta):
	if current_dialogue.is_empty():
		return
	var full_text = current_dialogue.get("text", "")
	if char_index < full_text.length():
		text_timer += delta
		if text_timer >= text_speed:
			text_timer = 0
			char_index += 1

func update_patrol(delta):
	# Move patrol robots through town
	for i in range(patrol_positions.size()):
		patrol_positions[i].x -= 15 * delta
		if patrol_positions[i].x < -50:
			patrol_positions[i].x = 530

func update_stealth(delta):
	if player_detected:
		return  # Already caught
	
	# Don't run detection during building, dialogue, or special modes
	# Player is safe when building circuits at the shed!
	if current_mode != GameMode.EXPLORATION:
		awareness_level = max(0, awareness_level - awareness_decay_rate * delta)
		return
	
	if in_dialogue:
		awareness_level = max(0, awareness_level - awareness_decay_rate * delta)
		return
	
	# Check if player is near a hiding spot
	var near_hiding_spot = false
	for spot in hiding_spots:
		if player_pos.distance_to(spot) < 40:  # Slightly larger radius
			near_hiding_spot = true
			break
	
	# Can only hide if near a hiding spot
	if is_hiding and not near_hiding_spot:
		is_hiding = false
	
	# Check if any patrol robot can see the player
	var being_watched = false
	var closest_distance = 999.0
	
	for patrol_pos in patrol_positions:
		var dist = player_pos.distance_to(patrol_pos)
		if dist < closest_distance:
			closest_distance = dist
		
		# Robots have a vision cone - can see ~120 pixels ahead (they move left)
		var in_vision_range = dist < 120
		var in_front_of_robot = player_pos.x < patrol_pos.x  # Robot faces left
		
		# Safe if hiding OR near a hiding spot (shed protects you)
		var is_protected = is_hiding or near_hiding_spot
		
		if in_vision_range and in_front_of_robot and not is_protected:
			being_watched = true
			# Closer = faster detection
			var detection_multiplier = 1.0 + (120 - dist) / 60.0
			awareness_level += awareness_fill_rate * detection_multiplier * delta
	
	# Decay awareness when not being watched
	if not being_watched or is_hiding or near_hiding_spot:
		awareness_level -= awareness_decay_rate * delta
	
	awareness_level = clamp(awareness_level, 0, max_awareness)
	
	# Kaido warns player when awareness is rising (non-blocking visual only)
	if awareness_level > 30 and not kaido_warned_to_hide:
		kaido_warned_to_hide = true
		# Don't use dialogue - just set a visual tip timer
		kaido_tip_text = "Hide!"
		kaido_tip_timer = 2.0
	
	# Reset warning flag when safe
	if awareness_level < 10:
		kaido_warned_to_hide = false
	
	# Player detected!
	if awareness_level >= max_awareness:
		player_detected = true
		dialogue_queue = [
			{"speaker": "system", "text": "[ DETECTED! ]"},
			{"speaker": "kaido", "text": "They've spotted us!"},
			{"speaker": "system", "text": "The patrol robots surround you..."},
		]
		next_dialogue()
		# Could trigger game over or restart here

func check_near_hiding_spot() -> bool:
	for spot in hiding_spots:
		if player_pos.distance_to(spot) < 40:  # Match the detection radius
			return true
	return false

func restart_after_detection():
	# Reset stealth state
	player_detected = false
	awareness_level = 0
	is_hiding = false
	kaido_warned_to_hide = false
	
	# Move player to safe spot (back near grandmother's house)
	player_pos = Vector2(300, 130)
	
	# Reset Kaido position to the side
	kaido_pos = player_pos + Vector2(-20, -15)
	kaido_trail_history.clear()
	
	# Brief dialogue
	dialogue_queue = [
		{"speaker": "kaido", "text": "That was close! We need to be more careful."},
	]
	next_dialogue()

func _input(event):
	# Debug: Print joypad events
	if event is InputEventJoypadButton:
		print("Joypad BUTTON: ", event.button_index, " pressed=", event.pressed)
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.5:  # Only print significant movement
			print("Joypad AXIS: ", event.axis, " value=", event.axis_value)
	
	# Pause menu toggle - Start button or Escape (when not in intro/combat)
	var pause_toggle = false
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		pause_toggle = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if current_mode != GameMode.PAUSE_MENU:  # Escape also opens pause
			pause_toggle = true
	
	if pause_toggle:
		if current_mode == GameMode.PAUSE_MENU:
			# Resume game
			current_mode = pause_previous_mode
			return
		elif current_mode in [GameMode.EXPLORATION, GameMode.SHED_INTERIOR, GameMode.SHOP_INTERIOR, GameMode.TOWNHALL_INTERIOR, GameMode.BAKERY_INTERIOR]:
			# Open pause menu
			pause_previous_mode = current_mode
			current_mode = GameMode.PAUSE_MENU
			pause_menu_selection = 0
			return
	
	# Handle pause menu input
	if current_mode == GameMode.PAUSE_MENU:
		handle_pause_menu_input(event)
		return
	
	# Handle component popup first
	if showing_component_popup:
		var popup_dismiss = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
			popup_dismiss = true
		if popup_dismiss and component_popup_timer > 1.0:
			showing_component_popup = false
		return
	
	# Accept interact OR ui_accept OR Cross button (for controller support) OR SPACE key
	var interact_pressed = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		interact_pressed = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		interact_pressed = true
	
	if interact_pressed:
		# Handle detection restart first
		if player_detected:
			restart_after_detection()
			return
		
		match current_mode:
			GameMode.INTRO:
				advance_intro()
			GameMode.EXPLORATION:
				if in_dialogue:
					advance_dialogue()
				else:
					check_interactions()
			GameMode.SHED_INTERIOR:
				advance_shed_exploration()
			GameMode.PHOTOGRAPH:
				close_photograph()
			GameMode.BUILD_SCREEN:
				advance_dialogue()
			GameMode.SCHEMATIC_POPUP:
				close_schematic()
			GameMode.BACKPACK_POPUP:
				close_backpack_popup()
			GameMode.RADIOTOWER_VIEW:
				if in_dialogue:
					advance_dialogue()
				elif can_exit_radiotower():
					exit_radiotower()
				else:
					# Need to build circuit - show schematic
					start_radiotower_circuit()
			GameMode.RADIOTOWER_INTERIOR:
				if in_dialogue:
					advance_dialogue()
				elif tower_reached_top:
					# At top - go to radiotower view for circuit building
					# tower_reached_top is true so enter_radiotower goes straight to view
					enter_radiotower()
			GameMode.STAMPEDE:
				if in_dialogue:
					advance_dialogue()
			GameMode.COMBAT:
				pass  # Combat uses different input handling
			GameMode.REGION_COMPLETE:
				pass
			GameMode.SHOP_INTERIOR:
				if in_dialogue:
					advance_dialogue()
				elif interior_near_npc:
					interact_shop_npc()
			GameMode.TOWNHALL_INTERIOR:
				if in_dialogue:
					advance_dialogue()
				elif interior_near_npc:
					interact_mayor_npc()
			GameMode.BAKERY_INTERIOR:
				if in_dialogue:
					advance_dialogue()
				elif interior_near_npc:
					interact_baker_npc()
	
	# Cancel/Back button - Circle or Escape
	var back_pressed = event.is_action_pressed("ui_cancel")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		back_pressed = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		back_pressed = true
	
	if back_pressed:
		match current_mode:
			GameMode.RADIOTOWER_INTERIOR:
				# Can only exit at the bottom
				if tower_player_pos.y > 260:
					exit_radiotower_interior()
			GameMode.RADIOTOWER_VIEW:
				# Can only exit if circuits are done for current stage
				if can_exit_radiotower():
					exit_radiotower()
				else:
					# Show hint that they need to build
					dialogue_queue = [
						{"speaker": "kaido", "text": "We need to finish the circuit first!"},
					]
					next_dialogue()
			GameMode.STAMPEDE:
				# Allow quitting stampede
				end_stampede(false)
			GameMode.SHOP_INTERIOR:
				if interior_near_exit:
					exit_building_interior()
			GameMode.TOWNHALL_INTERIOR:
				if interior_near_exit:
					exit_building_interior()
			GameMode.BAKERY_INTERIOR:
				if interior_near_exit:
					exit_building_interior()
			GameMode.BACKPACK_POPUP:
				close_backpack_popup()
	
	# Backpack navigation
	if current_mode == GameMode.BACKPACK_POPUP:
		# Tab switching - L1/R1 or Q/E
		var switch_left = false
		var switch_right = false
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_Q:
				switch_left = true
			if event.keycode == KEY_E:
				switch_right = true
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
				switch_left = true
			if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
				switch_right = true
		
		if switch_left and backpack_tab > 0:
			backpack_tab -= 1
		if switch_right and backpack_tab < 1:
			backpack_tab += 1
		
		# Navigation within current tab
		if backpack_tab == 0:  # Gadgets tab
			if event.is_action_pressed("move_left"):
				backpack_selected = max(0, backpack_selected - 1)
			if event.is_action_pressed("move_right"):
				backpack_selected = min(gadgets.size() - 1, backpack_selected + 1)
			if event.is_action_pressed("move_up"):
				backpack_selected = max(0, backpack_selected - 3)
			if event.is_action_pressed("move_down"):
				backpack_selected = min(gadgets.size() - 1, backpack_selected + 3)
		else:  # Loot tab
			if event.is_action_pressed("move_left"):
				loot_selected = max(0, loot_selected - 1)
			if event.is_action_pressed("move_right"):
				loot_selected = min(loot_items.size() - 1, loot_selected + 1)
			if event.is_action_pressed("move_up"):
				loot_selected = max(0, loot_selected - 3)
			if event.is_action_pressed("move_down"):
				loot_selected = min(loot_items.size() - 1, loot_selected + 3)
			
			# Select loot item with X button
			var select_loot = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
			if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
				select_loot = true
			if select_loot and loot_items.size() > 0 and loot_selected < loot_items.size():
				var item = loot_items[loot_selected]
				if item == "journal":
					open_journal_view()
	
	# Journal view scrolling
	if current_mode == GameMode.JOURNAL_VIEW:
		if event.is_action_pressed("move_up"):
			journal_scroll = max(0, journal_scroll - 40)
		if event.is_action_pressed("move_down"):
			journal_scroll += 40
		
		# Close journal
		var close_journal = event.is_action_pressed("ui_cancel")
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
			close_journal = true
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			close_journal = true
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			close_journal = true
		if close_journal:
			close_journal_view()
	
	# Tab or Triangle/Y to open backpack (even if empty)
	var backpack_pressed = event.is_action_pressed("ui_focus_next")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		backpack_pressed = true
	if backpack_pressed and current_mode == GameMode.EXPLORATION and not in_dialogue:
		show_backpack_view()
	
	# SPACE or Square to use equipped gadget OR punch if nothing equipped
	# X key for punch/gadget
	var use_gadget_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_X:
		use_gadget_pressed = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		use_gadget_pressed = true
	if use_gadget_pressed and current_mode == GameMode.EXPLORATION and not in_dialogue:
		if equipped_gadget != "" and gadget_use_timer <= 0:
			use_equipped_gadget()
		elif equipped_gadget == "" and punch_cooldown <= 0:
			do_punch()
			haptic_medium()
			# Also trigger the animation
			if not player_attacking:
				player_attacking = true
				player_attack_frame = 0
				player_attack_timer = 0
	
	# R1 to quick-cycle through gadgets
	var cycle_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		cycle_pressed = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		cycle_pressed = true
	if cycle_pressed and current_mode == GameMode.EXPLORATION and not in_dialogue:
		cycle_gadget()
	
	# Q or L1 to unequip gadget
	var unequip_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		unequip_pressed = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_LEFT_SHOULDER:
		unequip_pressed = true
	if unequip_pressed and current_mode == GameMode.EXPLORATION and not in_dialogue:
		unequip_gadget()
	
	# C or Circle to hide (when near hiding spot during patrol)
	var hide_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		hide_pressed = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		hide_pressed = true
	if hide_pressed and current_mode == GameMode.EXPLORATION and patrol_active and not player_detected:
		if check_near_hiding_spot():
			is_hiding = not is_hiding  # Toggle hiding
	
	# Combat inputs
	if current_mode == GameMode.COMBAT:
		# Allow input if tunnel fight active OR single robot not defeated
		if tunnel_fight_active or not robot_defeated:
			handle_combat_input(event)
	
	# Stampede inputs (combat-style)
	if current_mode == GameMode.STAMPEDE:
		if stampede_active and not in_dialogue:
			handle_stampede_input(event)

# ============================================
# COMBAT SYSTEM
# ============================================

func start_combat():
	combat_sys.start_combat()

func start_tunnel_fight():
	combat_sys.start_tunnel_fight()

func get_active_tunnel_robots() -> int:
	return combat_sys.get_active_tunnel_robots()

func get_nearest_tunnel_robot() -> int:
	return combat_sys.get_nearest_tunnel_robot()

func damage_nearest_tunnel_robot(damage: int):
	combat_sys.damage_nearest_tunnel_robot(damage)

func deal_damage_to_tunnel_robot(idx: int, damage: int):
	combat_sys.deal_damage_to_tunnel_robot(idx, damage)

func end_tunnel_fight_victory():
	combat_sys.end_tunnel_fight_victory()

func start_stampede():
	stampede_sys.start_stampede()

func handle_stampede_input(event):
	stampede_sys.handle_stampede_input(event)

func start_stampede_dodge():
	stampede_sys.start_stampede_dodge()

func execute_stampede_counter(animal: Dictionary):
	stampede_sys.execute_stampede_counter(animal)

func use_stampede_gadget():
	stampede_sys.use_stampede_gadget()

func stampede_flashlight_effect():
	stampede_sys.stampede_flashlight_effect()

func stampede_pulse_effect():
	stampede_sys.stampede_pulse_effect()

func start_stampede_attack():
	stampede_sys.start_stampede_attack()

func start_stampede_jump():
	stampede_sys.start_stampede_jump()

func hit_stampede_animal(animal: Dictionary):
	stampede_sys.hit_stampede_animal(animal)

func process_stampede(delta):
	stampede_sys.process_stampede(delta)

func process_stampede_movement(delta):
	stampede_sys.process_stampede_movement(delta)

func update_stampede_animals(delta):
	stampede_sys.update_stampede_animals(delta)

func spawn_stampede_animal():
	stampede_sys.spawn_stampede_animal()

func end_stampede(victory: bool):
	stampede_sys.end_stampede(victory)

func handle_combat_input(event):
	if combat_player_state == "hit":
		return  # Can't act during hit stun
	
	# Gadget cycling - R1 / Tab
	var cycle_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_TAB)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		cycle_pressed = true
	if cycle_pressed:
		cycle_gadget()
		return
	
	# Use gadget in combat - R2 / Q key
	var gadget_use_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_Q)
	# R2 trigger is an axis in Godot 4, not a button
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.5:
		gadget_use_pressed = true
	if gadget_use_pressed and gadget_use_timer <= 0:
		use_combat_gadget()
		return
	
	# Counter - Triangle button / Y key (during enemy telegraph)
	var counter_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_Y)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		counter_pressed = true
	if counter_pressed and counter_window_active:
		execute_counter()
		return
	
	# Can't do other actions during dodge or counter animation
	if combat_player_state in ["dodging", "countering"]:
		return
	
	# Strike - Cross button ([X]) / Z key - main attack
	var attack_pressed = event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_Z)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		attack_pressed = true
	if attack_pressed:
		if combat_player_state == "idle" or combat_player_state == "counter_followup":
			start_player_attack()
	
	# Heavy Strike - Square button ([_]) / X key
	var heavy_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_X)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		heavy_pressed = true
	if heavy_pressed:
		if combat_player_state == "idle" and combat_player_stamina >= 15:
			start_player_heavy_attack()
	
	# Evade - Circle button ([O]) / C key - quick sidestep
	var dodge_pressed = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_C)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		dodge_pressed = true
	if dodge_pressed:
		if combat_player_state == "idle" and combat_player_stamina >= 15:
			start_player_dodge()

func use_combat_gadget():
	combat_sys.use_combat_gadget()

func combat_flashlight_effect():
	combat_sys.combat_flashlight_effect()

func combat_pulse_effect():
	combat_sys.combat_pulse_effect()

func execute_counter():
	combat_sys.execute_counter()

func process_combat(delta):
	combat_sys.process_combat(delta)

func process_tunnel_robots(delta):
	combat_sys.process_tunnel_robots(delta)

func resolve_tunnel_robot_collisions():
	combat_sys.resolve_tunnel_robot_collisions()

func process_combat_movement(delta):
	combat_sys.process_combat_movement(delta)

func apply_robot_push():
	combat_sys.apply_robot_push()

func process_player_combat_state(delta):
	combat_sys.process_player_combat_state(delta)

func start_player_attack():
	haptic_light()
	combat_sys.start_player_attack()

func start_player_heavy_attack():
	haptic_medium()
	combat_sys.start_player_heavy_attack()

func add_slash_trail(dir: int, is_heavy: bool = false):
	combat_sys.add_slash_trail(dir, is_heavy)

func start_player_dodge():
	haptic_light()
	combat_sys.start_player_dodge()

func check_player_attack_hit():
	combat_sys.check_player_attack_hit()

func check_player_heavy_hit():
	combat_sys.check_player_heavy_hit()

func interrupt_tunnel_robot(idx: int):
	combat_sys.interrupt_tunnel_robot(idx)

func deal_damage_to_robot(damage: int):
	haptic_medium()
	combat_sys.deal_damage_to_robot(damage)

func update_robot_phase():
	combat_sys.update_robot_phase()

# ============================================
# ROBOT AI
# ============================================

func process_robot_ai(delta):
	combat_sys.process_robot_ai(delta)

func choose_robot_attack():
	combat_sys.choose_robot_attack()

func get_telegraph_time() -> float:
	return combat_sys.get_telegraph_time()

func get_recovery_time() -> float:
	return combat_sys.get_recovery_time()

func execute_robot_attack():
	combat_sys.execute_robot_attack()

func check_robot_attack_hit():
	combat_sys.check_robot_attack_hit()

func get_attack_damage() -> int:
	return combat_sys.get_attack_damage()

func deal_damage_to_player(damage: int):
	haptic_heavy()
	combat_sys.deal_damage_to_player(damage)

func player_defeated():
	combat_sys.player_defeated()

func add_hit_effect(pos: Vector2, text: String, color: Color):
	hit_effects.append({
		"pos": pos,
		"text": text,
		"timer": 0.8,
		"color": color
	})

func end_combat_victory():
	combat_sys.end_combat_victory()

# ============================================
# TEXT WRAPPING UTILITY
# ============================================

func wrap_text(text: String, max_chars: int = 42) -> Array:
	var words = text.split(" ")
	var lines = []
	var current_line = ""
	
	for word in words:
		if current_line.length() + word.length() + 1 <= max_chars:
			if current_line.length() > 0:
				current_line += " "
			current_line += word
		else:
			if current_line.length() > 0:
				lines.append(current_line)
			current_line = word
	
	if current_line.length() > 0:
		lines.append(current_line)
	
	return lines

# ============================================
# INTRO & NAVIGATION
# ============================================

func process_intro_text(delta):
	if intro_page < intro_text.size():
		var full_text = get_intro_page_text()
		if intro_char_index < full_text.length():
			intro_text_timer += delta
			if intro_text_timer >= intro_text_speed:
				intro_text_timer = 0
				intro_char_index += 1

func get_intro_page_text() -> String:
	if intro_page < intro_text.size():
		return "\n".join(intro_text[intro_page])
	return ""

func advance_intro():
	var full_text = get_intro_page_text()
	
	# If text is still typing, skip to end
	if intro_char_index < full_text.length():
		intro_char_index = full_text.length()
		return
	
	# Otherwise advance to next page
	intro_page += 1
	intro_char_index = 0
	intro_text_timer = 0.0
	
	if intro_page >= intro_text.size():
		current_mode = GameMode.EXPLORATION
		# Initialize camera centered on player
		center_camera_on_player()
		start_kaido_awakening()

func center_camera_on_player():
	# Immediately set camera to center on player (no lerp)
	var visible_width = SCREEN_WIDTH / GAME_ZOOM
	var visible_height = SCREEN_HEIGHT / GAME_ZOOM
	
	var target_offset = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2) / GAME_ZOOM - player_pos
	
	# Clamp to map bounds
	var min_x = -(480 - visible_width)
	var max_x = 0
	var min_y = -(320 - visible_height)
	var max_y = 0
	
	target_offset.x = clamp(target_offset.x, min_x, max_x)
	target_offset.y = clamp(target_offset.y, min_y, max_y)
	
	# Direct assignment - no rounding needed
	camera_offset = target_offset
	
	# Also initialize Kaido to the right and behind player
	kaido_pos = player_pos + Vector2(-20, -15)
	kaido_trail_history.clear()

func start_kaido_awakening():
	dialogue_queue = [
		{"speaker": "kaido", "text": "Systems online. I am KAIDO."},
		{"speaker": "kaido", "text": "I've been dormant for years, waiting."},
		{"speaker": "kaido", "text": "The power outage triggered my awakening."},
		{"speaker": "kaido", "text": "I can teach you to build circuits."},
		{"speaker": "kaido", "text": "First, let's talk to your grandmother."},
		{"speaker": "quest", "text": "Talk to Grandmother"},
	]
	next_dialogue()

func check_interactions():
	# Handle interactions based on current area
	match current_area:
		Area.FARM:
			check_farm_interactions()
		Area.CORNFIELD:
			check_cornfield_interactions()
		Area.LAKESIDE:
			check_lakeside_interactions()
		Area.TOWN_CENTER:
			check_town_interactions()

func check_farm_interactions():
	# Main story NPCs
	if player_pos.distance_to(grandmother_pos) < 40:
		interact_grandmother()
		return
	if player_pos.distance_to(shed_pos) < 50:
		interact_shed()
		return
	if quest_stage >= 7 and player_pos.distance_to(irrigation_pos) < 40:
		interact_irrigation()
		return
	if farmer_wen_visible and not farmer_wen_leaving and player_pos.distance_to(farmer_wen_pos) < 40:
		interact_farmer_wen()
		return
	if quest_stage >= 10 and player_pos.distance_to(radiotower_pos) < 50:
		interact_radiotower()
		return

	# Kid NPC (when visible and not walking)
	if kid_visible and not kid_walking_in and player_pos.distance_to(kid_pos) < 35:
		interact_kid()
		return
	
	# Optional side circuits
	if not side_circuits_done.chicken_coop and player_pos.distance_to(chicken_coop_interact_pos) < 30:
		interact_chicken_coop()
		return
	
	# Discoverable secrets - journal pages (only farm area pages)
	var farm_pages = ["radiotower", "buried"]
	for page_name in farm_pages:
		if page_name not in journal_pages_found:
			var page_pos = journal_page_locations[page_name]
			if player_pos.distance_to(page_pos) < 30:
				discover_journal_page(page_name)
				return
	
	# Lore relics (after certain quest stages)
	if quest_stage >= 2:
		check_relic_discovery()

func check_cornfield_interactions():
	# Check NPC interactions
	for npc in cornfield_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			interact_cornfield_npc(npc)
			return
	
	# LED Chain circuit placement (stage 12)
	if quest_stage == 12 and not cornfield_led_placed:
		var led_spot = Vector2(240, 150)
		if player_pos.distance_to(led_spot) < 40:
			start_cornfield_circuit()
			return
	
	# Journal page in cornfield
	if "cornfield" not in journal_pages_found:
		var page_pos = journal_page_locations["cornfield"]
		if player_pos.distance_to(page_pos) < 30:
			discover_journal_page("cornfield")
			return

func check_lakeside_interactions():
	# Check NPC interactions
	for npc in lakeside_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			interact_lakeside_npc(npc)
			return

	# Sewer entrance (during nightfall escape sequence)
	if is_nightfall and player_pos.distance_to(tunnel_pos) < 40:
		enter_tunnel()
		return

	# Secret discovery near rocks
	if not lakeside_secret_found and player_pos.distance_to(Vector2(310, 275)) < 30:
		discover_lakeside_secret()
		return

	# Journal page at lakeside
	if "lakeside" not in journal_pages_found:
		var page_pos = journal_page_locations["lakeside"]
		if player_pos.distance_to(page_pos) < 30:
			discover_journal_page("lakeside")
			return

func check_town_interactions():
	# Building entry checks
	if player_pos.distance_to(shop_door_pos) < 30:
		enter_shop()
		return
	if player_pos.distance_to(townhall_door_pos) < 30:
		enter_townhall()
		return
	if player_pos.distance_to(bakery_door_pos) < 30:
		enter_bakery()
		return
	
	# Check NPC interactions
	for npc in town_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			interact_town_npc(npc)
			return
	
	# Well circuit in town center
	if not side_circuits_done.well_pump and player_pos.distance_to(well_pos) < 35:
		interact_well()
		return
	
	# Journal page in town center
	if "town_center" not in journal_pages_found:
		var page_pos = journal_page_locations["town_center"]
		if player_pos.distance_to(page_pos) < 30:
			discover_journal_page("town_center")
			return

func enter_shop():
	current_mode = GameMode.SHOP_INTERIOR
	# Set up exploration positions
	interior_player_pos = Vector2(240, 270)  # Start near door
	interior_kaido_pos = Vector2(220, 270)
	interior_npc_pos = Vector2(240, 140)  # Shopkeeper behind counter
	interior_near_npc = false
	interior_near_exit = false
	in_dialogue = false

func enter_townhall():
	current_mode = GameMode.TOWNHALL_INTERIOR
	# Set up exploration positions
	interior_player_pos = Vector2(240, 270)  # Start near door
	interior_kaido_pos = Vector2(220, 270)
	interior_npc_pos = Vector2(240, 120)  # Mayor at desk
	interior_near_npc = false
	interior_near_exit = false
	in_dialogue = false

func enter_bakery():
	current_mode = GameMode.BAKERY_INTERIOR
	# Set up exploration positions
	interior_player_pos = Vector2(240, 270)  # Start near door
	interior_kaido_pos = Vector2(220, 270)
	interior_npc_pos = Vector2(380, 130)  # Baker near right side
	interior_near_npc = false
	interior_near_exit = false
	in_dialogue = false

func exit_building_interior():
	current_mode = GameMode.EXPLORATION
	in_dialogue = false  # Clear any dialogue state
	dialogue_queue.clear()
	current_dialogue = {}

func process_building_interior(delta):
	if in_dialogue:
		return  # Don't move during dialogue
	
	# Get input using unified system
	var input = get_input_4dir()
	
	# Normalize and move
	if input.length() > 0:
		input = input.normalized()
		interior_player_pos += input * 120 * delta
		# Wood floor haptics (reduced)
		footstep_timer += delta
		if footstep_timer >= 0.24:
			footstep_timer = 0.0
			var foot_var = randf_range(0.85, 1.15)
			Input.start_joy_vibration(0, 0.1 * foot_var, 0.05 * foot_var, 0.025)
	else:
		footstep_timer = 0.0
	
	# Bounds for interior (smaller room)
	interior_player_pos.x = clamp(interior_player_pos.x, 40, 440)
	interior_player_pos.y = clamp(interior_player_pos.y, 160, 290)
	
	# Update Kaido to follow
	var to_player = interior_player_pos - interior_kaido_pos
	if to_player.length() > 30:
		interior_kaido_pos += to_player.normalized() * 100 * delta
	
	# Check proximity to NPC
	interior_near_npc = interior_player_pos.distance_to(interior_npc_pos) < 50
	
	# Check proximity to exit (bottom center)
	var exit_pos = Vector2(240, 295)
	interior_near_exit = interior_player_pos.distance_to(exit_pos) < 35

func interact_shop_npc():
	if shop_talked:
		dialogue_queue = dialogue_data.shop_return()
	else:
		shop_talked = true
		dialogue_queue = dialogue_data.shop_intro()
	next_dialogue()

func interact_mayor_npc():
	if mayor_talked:
		dialogue_queue = dialogue_data.mayor_return()
	else:
		mayor_talked = true
		dialogue_queue = dialogue_data.mayor_intro()
	next_dialogue()

func interact_baker_npc():
	current_dialogue_npc = "Baker Bot-7"
	if baker_talked:
		dialogue_queue = dialogue_data.baker_return()
	else:
		baker_talked = true
		dialogue_queue = dialogue_data.baker_intro()
	next_dialogue()

func interact_cornfield_npc(npc: Dictionary):
	current_dialogue_npc = npc.get("name", "Villager")
	dialogue_queue = [
		{"speaker": "villager", "text": npc.dialogue},
	]
	if quest_stage >= 12 and not cornfield_led_placed:
		dialogue_queue.append({"speaker": "kaido", "text": "We're setting up signal lights to guide everyone."})
	next_dialogue()

func interact_lakeside_npc(npc: Dictionary):
	current_dialogue_npc = npc.get("name", "Villager")
	dialogue_queue = [
		{"speaker": "villager", "text": npc.dialogue},
	]
	next_dialogue()

func interact_town_npc(npc: Dictionary):
	current_dialogue_npc = npc.name
	var extra_lines = []
	match npc.name:
		"Elder Sato":
			extra_lines = [
				{"speaker": "kaido", "text": "Sir, do you know about the Resistance?"},
				{"speaker": "villager", "text": "That was a long time ago, little one."},
				{"speaker": "villager", "text": "But some memories never fade."},
			]
		"Child Mei":
			extra_lines = [
				{"speaker": "kaido", "text": "I'm a teaching robot! Want to learn about circuits?"},
				{"speaker": "villager", "text": "Circuits? Like magic electricity stuff?!"},
			]
		"Guard Tanaka":
			extra_lines = [
				{"speaker": "villager", "text": "...But I haven't seen anything unusual."},
				{"speaker": "villager", "text": "Nothing at all."},
			]
		"Baker Yuki":
			extra_lines = [
				{"speaker": "system", "text": "[ Received: Fresh Bread ]"},
			]
	
	dialogue_queue = [{"speaker": "villager", "text": npc.dialogue}]
	dialogue_queue.append_array(extra_lines)
	next_dialogue()

func start_cornfield_circuit():
	cornfield_led_placed = true
	dialogue_queue = [
		{"speaker": "kaido", "text": "This is a good spot for the signal chain."},
		{"speaker": "kaido", "text": "LEDs in series share current."},
		{"speaker": "kaido", "text": "If one fails, all go dark - so we must be careful!"},
	]
	dialogue_queue.append({"speaker": "schematic", "text": "led_chain"})
	next_dialogue()

func discover_lakeside_secret():
	lakeside_secret_found = true
	dialogue_queue = [
		{"speaker": "system", "text": "[ Found something behind the rocks... ]"},
		{"speaker": "relic", "text": "An old circuit board, weathered but intact."},
		{"speaker": "kaido", "text": "This is Resistance tech! From before the takeover."},
		{"speaker": "kaido", "text": "They hid supplies all over the commune."},
	]
	next_dialogue()

# ============================================
# CIRCUIT 1: LED FLASHLIGHT
# ============================================

func interact_grandmother():
	# Stop pacing and face the player when talking
	grandmother_pacing = false
	grandmother_is_walking = false
	var to_player = player_pos - grandmother_pos
	if abs(to_player.x) > abs(to_player.y):
		grandmother_facing = "right" if to_player.x > 0 else "left"
	else:
		grandmother_facing = "down" if to_player.y > 0 else "up"
	
	match quest_stage:
		0:
			dialogue_queue = dialogue_data.grandmother_stage_0()
		1:
			dialogue_queue = dialogue_data.grandmother_stage_1()
		2:
			dialogue_queue = dialogue_data.grandmother_stage_2()
		3:
			dialogue_queue = dialogue_data.grandmother_stage_3()
		4:
			dialogue_queue = dialogue_data.grandmother_stage_4()
			# Kid runs in from off-screen right
			kid_visible = true
			kid_walking_in = true
			kid_pos = Vector2(500, 170)  # Start off-screen
			kid_target_pos = Vector2(320, 170)  # Run to near player
			dialogue_queue.append_array(dialogue_data.grandmother_stage_4_kid_arrives())
		5:
			dialogue_queue = dialogue_data.grandmother_stage_5()
			# Add hint to go to shed
			dialogue_queue.append({"speaker": "quest", "text": "Build Silent Alarm in Shed"})
		6, 7:
			patrol_active = false
			kid_visible = false
			dialogue_queue = dialogue_data.grandmother_stage_6_7()
			if quest_stage == 6:
				dialogue_queue.append({"speaker": "set_stage", "text": "7"})
				dialogue_queue.append({"speaker": "quest", "text": "Follow Grandmother"})
				# Don't move grandmother yet - wait for player
		8, 9:
			dialogue_queue = dialogue_data.grandmother_stage_8_9()
			if quest_stage == 8:
				# Farmer Wen walks in from off-screen right with his tractor
				farmer_wen_visible = true
				farmer_wen_walking_in = true
				tractor_visible = true
				farmer_wen_pos = Vector2(520, 250)  # Start off-screen
				farmer_wen_target_pos = Vector2(280, 250)
				tractor_pos = Vector2(560, 250)  # Tractor follows behind
				tractor_target_pos = Vector2(320, 250)
				dialogue_queue.append({"speaker": "set_stage", "text": "9"})
				dialogue_queue.append({"speaker": "quest", "text": "Help Farmer Wen"})
		10:
			# First deep talk - introduce backstory
			dialogue_queue = [
				{"speaker": "grandmother", "text": "You've learned so much already."},
				{"speaker": "grandmother", "text": "Farmer Wen's tractor needs a light sensor."},
				{"speaker": "grandmother", "text": "The shed has what you need."},
			]
		11:
			# More backstory
			dialogue_queue = [
				{"speaker": "grandmother", "text": "You know, I wasn't always a farmer."},
				{"speaker": "grandmother", "text": "Before the takeover, I was an engineer."},
				{"speaker": "grandmother", "text": "I built the first solar grid for this valley."},
				{"speaker": "grandmother", "text": "Now check on the radiotower when you're ready."},
			]
		12, 13:
			# University story
			dialogue_queue = [
				{"speaker": "grandmother", "text": "Your grandfather and I met at university."},
				{"speaker": "grandmother", "text": "He was brilliant. Always tinkering."},
				{"speaker": "grandmother", "text": "He believed everyone should understand how things work."},
				{"speaker": "grandmother", "text": "That's why they came for him first."},
			]
		14:
			# CARACTACUS revelation
			dialogue_queue = [
				{"speaker": "grandmother", "text": "CARACTACUS... his code name."},
				{"speaker": "grandmother", "text": "He hid Kaido here before they took him."},
				{"speaker": "grandmother", "text": "Said someday, someone would find it."},
				{"speaker": "grandmother", "text": "I waited thirty years for you."},
			]
		_:
			# Post-game deep dialogue
			npc_talk_count.grandmother += 1
			dialogue_queue = dialogue_data.grandmother_deep_talk(npc_talk_count.grandmother)
	next_dialogue()

func interact_shed():
	match quest_stage:
		0:
			dialogue_queue = [
				{"speaker": "kaido", "text": "An old shed. Let's find grandmother first."},
			]
			next_dialogue()
		1:
			# Show Kaido dialogue, then schematic
			dialogue_queue = [
				{"speaker": "kaido", "text": "The parts are here. I will find a schematic in my memory files for the build."},
				{"speaker": "schematic", "text": "led_lamp"},
			]
			next_dialogue()
		2:
			enter_shed_interior()
		5:
			# Circuit 2: Buzzer
			show_schematic("buzzer_alarm")
		_:
			dialogue_queue = [
				{"speaker": "kaido", "text": "We've found everything we need here."},
			]
			next_dialogue()

func show_schematic(circuit_id: String):
	current_schematic = circuit_id
	current_mode = GameMode.SCHEMATIC_POPUP
	schematic_shown = true

func close_schematic():
	current_mode = GameMode.EXPLORATION
	
	# After viewing schematic, start build sequence
	match current_schematic:
		"led_lamp":
			start_build_sequence("led_lamp", [
				{"speaker": "kaido", "text": "Connect the LED's long leg to power."},
				{"speaker": "kaido", "text": "Short leg goes through the resistor to ground."},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "The LED shines bright red!"},
				{"speaker": "kaido", "text": "You built your first circuit!"},
				{"speaker": "set_stage", "text": "2"},
				{"speaker": "quest", "text": "Explore the Shed"},
			])
		"buzzer_alarm":
			start_build_sequence("buzzer_alarm", [
				{"speaker": "kaido", "text": "Connect the buzzer to the button."},
				{"speaker": "kaido", "text": "Press to complete the circuit."},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "The buzzer sounds!"},
				{"speaker": "system", "text": "[ The patrol marches through... ]"},
				{"speaker": "set_stage", "text": "6"},
				{"speaker": "quest", "text": "Talk to Grandmother"},
			])
			# Start patrol
			patrol_active = true
			patrol_positions = [
				Vector2(500, 170),
				Vector2(550, 170),
				Vector2(600, 170)
			]
		"dimmer":
			start_build_sequence("dimmer", [
				{"speaker": "kaido", "text": "The potentiometer controls voltage."},
				{"speaker": "kaido", "text": "Turn the dial to dim the LED!"},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "The dimmer works!"},
				{"speaker": "system", "text": "[ Water flows to the crops! ]"},
				{"speaker": "grandmother", "text": "The fields will live another season."},
				{"speaker": "system", "text": "[ A mechanical whirring approaches... ]"},
				{"speaker": "robot", "text": "CITIZEN DETECTED. SCANNING..."},
				{"speaker": "robot", "text": "UNAUTHORIZED COMPONENTS IDENTIFIED."},
				{"speaker": "robot", "text": "INITIATING COMPLIANCE PROTOCOL."},
				{"speaker": "kaido", "text": "It's going to attack!"},
				{"speaker": "kaido", "text": "Watch its movements - press Ã¢â€“Â³ to Counter!"},
				{"speaker": "start_combat", "text": ""},
			])
			water_flowing = true
		"light_sensor":
			start_build_sequence("light_sensor", [
				{"speaker": "kaido", "text": "The photoresistor changes with light."},
				{"speaker": "kaido", "text": "Less light = more resistance."},
				{"speaker": "kaido", "text": "Cover it to trigger the LED!"},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "Cover sensor - LED lights up!"},
				{"speaker": "kaido", "text": "The beacon will work at night."},
				{"speaker": "set_stage", "text": "12"},
				{"speaker": "quest", "text": "Build Signal Chain"},
			])
		"led_chain":
			start_build_sequence("led_chain", [
				{"speaker": "kaido", "text": "LEDs in series share current."},
				{"speaker": "kaido", "text": "If one fails, all go dark."},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "system", "text": "[ Red. Yellow. Green. ]"},
				{"speaker": "kaido", "text": "The signal chain is ready!"},
				{"speaker": "set_stage", "text": "13"},
				{"speaker": "quest", "text": "Build OR Gate"},
			])
		"or_gate":
			start_build_sequence("or_gate", [
				{"speaker": "kaido", "text": "Diodes let current flow one way."},
				{"speaker": "kaido", "text": "Either input triggers output."},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "Press either button - LED lights!"},
				{"speaker": "kaido", "text": "The warning system is complete."},
				{"speaker": "set_stage", "text": "14"},
				{"speaker": "quest", "text": "The Escape"},
			])
			is_nightfall = true
			lit_buildings = ["radiotower", "barn", "mill"]
	
	current_schematic = ""

# ============================================
# SHED INTERIOR
# ============================================

func enter_shed_interior():
	current_mode = GameMode.SHED_INTERIOR
	shed_explore_stage = 0
	flashlight_pos = Vector2(240, 200)
	dialogue_queue = [
		{"speaker": "system", "text": "[ Use arrow keys to move the flashlight ]"},
		{"speaker": "system", "text": "[ Press [X] to examine objects ]"},
	]
	next_dialogue()

func advance_shed_exploration():
	if in_dialogue:
		advance_dialogue()
		return
	
	# Check what flashlight is pointing at
	if flashlight_pos.distance_to(Vector2(360, 250)) < 40:
		# Found the photograph
		shed_explore_stage = 3
		show_photograph()
	elif flashlight_pos.distance_to(Vector2(100, 80)) < 40:
		dialogue_queue = [
			{"speaker": "system", "text": "Old tools hang on the wall."},
			{"speaker": "system", "text": "Covered in dust and cobwebs."},
		]
		next_dialogue()
	elif flashlight_pos.distance_to(Vector2(300, 100)) < 40:
		dialogue_queue = [
			{"speaker": "system", "text": "Electronic components in jars."},
			{"speaker": "system", "text": "Resistors, capacitors, LEDs..."},
		]
		next_dialogue()
	else:
		dialogue_queue = [
			{"speaker": "system", "text": "Keep searching with the flashlight."},
		]
		next_dialogue()

func show_photograph():
	current_mode = GameMode.PHOTOGRAPH
	photo_fade = 0.0
	# Find the family_photo relic
	if "family_photo" not in relics_found:
		relics_found.append("family_photo")

func close_photograph():
	if photo_fade < 1.0:
		photo_fade = 1.0
		return
	
	current_mode = GameMode.EXPLORATION
	quest_stage = 3
	dialogue_queue = [
		{"speaker": "system", "text": "An old photograph..."},
		{"speaker": "system", "text": "Your grandmother, years younger."},
		{"speaker": "system", "text": "With a group of people and robots."},
		{"speaker": "system", "text": "On the back: THE RESISTANCE"},
		{"speaker": "relic", "text": "Faded Photograph"},
		{"speaker": "journal", "text": "A family picnic. No robots in sight."},
		{"speaker": "quest", "text": "Ask about THE RESISTANCE"},
	]
	next_dialogue()

# ============================================
# CIRCUIT 3: IRRIGATION / DIMMER
# ============================================

func interact_irrigation():
	if quest_stage == 7:
		dialogue_queue = [
			{"speaker": "grandmother", "text": "The water pump needs precise control."},
			{"speaker": "grandmother", "text": "Too much floods the roots."},
			{"speaker": "grandmother", "text": "Too little and the crops die."},
			{"speaker": "kaido", "text": "We need a dimmer circuit!"},
			{"speaker": "kaido", "text": "It will let us control the flow precisely."},
		]
		next_dialogue()
		# Show schematic after dialogue
		dialogue_queue.append({"speaker": "schematic", "text": "dimmer"})
	else:
		dialogue_queue = [
			{"speaker": "kaido", "text": "The irrigation is working now."},
			{"speaker": "kaido", "text": "Water flows to the dry fields."},
		]
		next_dialogue()

# ============================================
# CIRCUIT 4: FARMER WEN / TRACTOR
# ============================================

func interact_farmer_wen():
	if quest_stage == 9:
		npc_talk_count.farmer_wen += 1
		var talks = npc_talk_count.farmer_wen
		
		if talks == 1:
			dialogue_queue = [
				{"speaker": "farmer_wen", "text": "My tractor won't start!"},
				{"speaker": "farmer_wen", "text": "The seat sensor is broken."},
				{"speaker": "farmer_wen", "text": "It thinks no one is sitting."},
				{"speaker": "kaido", "text": "The sensor outputs LOW when empty."},
				{"speaker": "kaido", "text": "We need to adjust the signal strength!"},
				{"speaker": "kaido", "text": "The dimmer can fine-tune the voltage."},
			]
			next_dialogue()
			start_build_sequence("dimmer", [], [
				{"speaker": "system", "text": "[ The tractor roars to life! ]"},
				{"speaker": "farmer_wen", "text": "Amazing! You've got real talent."},
				{"speaker": "farmer_wen", "text": "Here - take this. It's from before."},
				{"speaker": "show_component", "text": "tractor_sensor"},
				{"speaker": "farmer_wen", "text": "I need to get the harvest in."},
				{"speaker": "farmer_wen", "text": "Thank you, young one. Stay safe."},
				{"speaker": "farmer_wen_leave", "text": ""},
				{"speaker": "set_stage", "text": "10"},
				{"speaker": "quest", "text": "Check Radiotower"},
			])
		else:
			# Backstory before fixing tractor
			dialogue_queue = [
				{"speaker": "farmer_wen", "text": "My daughter is in New Sumida City."},
				{"speaker": "farmer_wen", "text": "She's sick. Medicine is expensive."},
				{"speaker": "farmer_wen", "text": "That's why I can't leave. The harvest..."},
				{"speaker": "farmer_wen", "text": "It's all I have to trade for her treatment."},
				{"speaker": "farmer_wen", "text": "Please, can you help with the tractor?"},
			]
			next_dialogue()
	else:
		dialogue_queue = [
			{"speaker": "farmer_wen", "text": "Good luck out there!"},
		]
		next_dialogue()

func interact_kid():
	npc_talk_count.kid += 1
	dialogue_queue = dialogue_data.kid_talk(npc_talk_count.kid)
	next_dialogue()

# ============================================
# OPTIONAL SIDE CIRCUITS
# ============================================

func interact_chicken_coop():
	if side_circuits_done.chicken_coop:
		dialogue_queue = [
			{"speaker": "kaido", "text": "The coop door works perfectly now."},
			{"speaker": "kaido", "text": "Chickens safe, foxes out!"},
		]
		next_dialogue()
		return
	
	if quest_stage < 3:
		dialogue_queue = [
			{"speaker": "kaido", "text": "A chicken coop. The door sensor is broken."},
			{"speaker": "kaido", "text": "Maybe we can fix it later."},
		]
		next_dialogue()
	else:
		start_build_sequence("light_sensor", 
			[
				{"speaker": "kaido", "text": "The coop door won't close at night."},
				{"speaker": "kaido", "text": "Foxes have been getting the chickens."},
				{"speaker": "kaido", "text": "A light sensor could auto-close it at dusk!"},
			], 
			[
				{"speaker": "system", "text": "[ The coop door clicks shut! ]"},
				{"speaker": "kaido", "text": "The chickens are safe now."},
				{"speaker": "kaido", "text": "Every circuit helps someone."},
			]
		)

func interact_well():
	if side_circuits_done.well_pump:
		dialogue_queue = [
			{"speaker": "kaido", "text": "The pump indicator glows steady."},
			{"speaker": "kaido", "text": "Everyone can see when water flows."},
		]
		next_dialogue()
		return
	
	if quest_stage < 5:
		dialogue_queue = [
			{"speaker": "kaido", "text": "An old well. The pump indicator is dark."},
		]
		next_dialogue()
	else:
		# This is a simple LED circuit - same as first one
		# We'll mark it done and use well_indicator as the gadget_id
		start_build_sequence("well_indicator",
			[
				{"speaker": "kaido", "text": "The villagers can't tell if the pump is running."},
				{"speaker": "kaido", "text": "They waste time checking manually."},
				{"speaker": "kaido", "text": "An LED indicator would help!"},
			],
			[
				{"speaker": "system", "text": "[ The pump light glows steady! ]"},
				{"speaker": "kaido", "text": "Now everyone knows when water flows."},
				{"speaker": "kaido", "text": "Simple solutions save time."},
			]
		)

# ============================================
# DISCOVERABLE SECRETS
# ============================================

func discover_journal_page(page_name: String):
	journal_pages_found.append(page_name)
	
	# Add journal to loot on first page found
	if "journal" not in loot_items:
		loot_items.append("journal")
	
	var page_content = get_journal_page_content()
	var page = page_content.get(page_name, {"title": "???", "text": "..."})
	
	dialogue_queue = [
		{"speaker": "system", "text": "[ You found a torn page... ]"},
		{"speaker": "system", "text": "[ " + page.title + " ]"},
		{"speaker": "journal", "text": page.text},
	]
	
	if journal_pages_found.size() == 5:
		dialogue_queue.append({"speaker": "kaido", "text": "That's all the journal pages!"})
		dialogue_queue.append({"speaker": "kaido", "text": "CARACTACUS... he knew this day would come."})
	else:
		var remaining = 5 - journal_pages_found.size()
		dialogue_queue.append({"speaker": "kaido", "text": str(remaining) + " more pages somewhere..."})
	
	next_dialogue()

func get_journal_page_content() -> Dictionary:
	return {
		"shed": {
			"title": "Journal Entry #1",
			"text": "The children learn so quickly. Today we built their first circuits. Their eyes when the LED lit up..."
		},
		"pond": {
			"title": "Journal Entry #2", 
			"text": "Energy Nation passed the Knowledge Control Act. Teaching without license is now illegal. We must hide the workshop."
		},
		"tree": {
			"title": "Journal Entry #3",
			"text": "I've hidden KAIDO in the shed. If they find me, at least the knowledge survives. Someone will continue."
		},
		"radiotower": {
			"title": "Journal Entry #4",
			"text": "The resistance grows. We communicate through the old radio tower. They can't monitor everything."
		},
		"buried": {
			"title": "Journal Entry #5",
			"text": "To whoever finds this: the truth cannot be erased. Build. Teach. Remember. - CARACTACUS"
		}
	}

func check_relic_discovery():
	# Relics are found at specific story moments and locations
	# This gets called during exploration
	
	# Old radio - found in shed after building flashlight
	if "old_radio" not in relics_found:
		if current_mode == GameMode.SHED_INTERIOR and quest_stage >= 2:
			find_relic("old_radio")
			return
	
	# Circuit board - found at radiotower base
	if "circuit_board" not in relics_found:
		if player_pos.distance_to(radiotower_pos) < 35 and quest_stage >= 10:
			find_relic("circuit_board")
			return
	
	# Resistance patch - found near tunnel entrance
	if "resistance_patch" not in relics_found:
		if player_pos.distance_to(tunnel_pos) < 35 and is_nightfall:
			find_relic("resistance_patch")
			return

func find_relic(relic_id: String):
	if relic_id in relics_found:
		return
	
	relics_found.append(relic_id)
	var relic = relic_data.get(relic_id, {})
	
	dialogue_queue = [
		{"speaker": "system", "text": "[ You found something... ]"},
		{"speaker": "relic", "text": relic.get("name", "Unknown")},
		{"speaker": "journal", "text": relic.get("desc", "...")},
	]
	
	if relics_found.size() == relic_data.size():
		dialogue_queue.append({"speaker": "kaido", "text": "We've found all the relics."})
		dialogue_queue.append({"speaker": "kaido", "text": "Each one a piece of what was lost."})
	else:
		var remaining = relic_data.size() - relics_found.size()
		dialogue_queue.append({"speaker": "kaido", "text": "A piece of history... " + str(remaining) + " more out there."})
	
	next_dialogue()

func farmer_wen_drive_away():
	farmer_wen_leaving = true
	farmer_wen_target_pos = Vector2(550, farmer_wen_pos.y)
	tractor_target_pos = Vector2(600, tractor_pos.y)

func show_component_popup(component_id: String):
	showing_component_popup = true
	component_popup_timer = 0.0
	component_popup_data = gadget_data.get(component_id, {
		"name": component_id,
		"desc": "A useful component",
		"adventure_use": "This will help on your journey."
	})
	# Add to inventory
	if component_id not in gadgets:
		gadgets.append(component_id)

# ============================================
# CIRCUIT 5+: RADIOTOWER
# ============================================

func interact_radiotower():
	# Stage 10: First time at radiotower - intercept the transmission
	if quest_stage == 10:
		dialogue_queue = [
			{"speaker": "system", "text": "[ The radio crackles to life... ]"},
			{"speaker": "system", "text": "[ ENCRYPTED TRANSMISSION ]"},
			{"speaker": "system", "text": "\"Energy Nation intercepted signal.\""},
			{"speaker": "system", "text": "\"They know about the helper robot.\""},
			{"speaker": "system", "text": "\"Unit KAIDO-7 is now classified OUTLAW.\""},
			{"speaker": "system", "text": "\"All who harbor it: OUTLAWS.\""},
			{"speaker": "system", "text": "\"Raid squad dispatched. ETA: nightfall.\""},
			{"speaker": "kaido", "text": "...Outlaw?"},
			{"speaker": "grandmother", "text": "They're coming for you, Kaido."},
			{"speaker": "grandmother", "text": "And for anyone who helped hide you."},
			{"speaker": "kaido", "text": "I'm sorry... I never meant toÃ¢â‚¬â€"},
			{"speaker": "grandmother", "text": "Don't apologize. We made our choice."},
			{"speaker": "grandmother", "text": "Now we survive. Together."},
			{"speaker": "kaido", "text": "We need to evacuate!"},
			{"speaker": "grandmother", "text": "The old escape tunnel leads to Sumida."},
			{"speaker": "grandmother", "text": "But it's pitch black down there."},
			{"speaker": "kaido", "text": "I can build a beacon that activates in darkness!"},
			{"speaker": "kaido", "text": "Let me climb up to the radio equipment."},
			{"speaker": "set_stage", "text": "11"},
		]
		next_dialogue()
	elif quest_stage >= 11:
		# Need to climb tower first, then build circuits
		enter_radiotower()

func enter_radiotower():
	# Must climb to top first time
	if not tower_reached_top:
		enter_radiotower_interior()
		return
	
	# Already climbed - go to circuit building view
	current_mode = GameMode.RADIOTOWER_VIEW
	start_radiotower_circuit()

func start_radiotower_circuit():
	# Start the appropriate circuit based on quest stage
	if quest_stage == 11:
		dialogue_queue = [
			{"speaker": "kaido", "text": "Made it to the radio equipment!"},
			{"speaker": "kaido", "text": "Now for a light sensor circuit."},
			{"speaker": "kaido", "text": "When darkness comes, the LED turns on."},
			{"speaker": "kaido", "text": "Perfect for the tunnel beacons!"},
		]
		dialogue_queue.append({"speaker": "schematic", "text": "light_sensor"})
		next_dialogue()
	elif quest_stage == 12:
		# LED chain is built in cornfield now
		if not cornfield_led_placed:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "One beacon won't be enough."},
				{"speaker": "kaido", "text": "The farmers up north need signals too."},
				{"speaker": "kaido", "text": "I should head to the cornfield."},
			]
			next_dialogue()
		else:
			# Already built in cornfield
			dialogue_queue = [
				{"speaker": "kaido", "text": "LED chain is set up in the cornfield."},
				{"speaker": "kaido", "text": "Now we need warning signals."},
			]
			next_dialogue()
	elif quest_stage == 13:
		dialogue_queue = [
			{"speaker": "grandmother", "text": "We need warning signals too."},
			{"speaker": "grandmother", "text": "Two lookout points - if either sees danger..."},
			{"speaker": "kaido", "text": "An OR gate! Either input triggers the alarm!"},
		]
		dialogue_queue.append({"speaker": "schematic", "text": "or_gate"})
		next_dialogue()
	elif quest_stage >= 14:
		dialogue_queue = [
			{"speaker": "kaido", "text": "All the beacons are ready."},
			{"speaker": "kaido", "text": "Time to lead everyone to safety."},
			{"speaker": "kaido", "text": "Press [O] to climb down."},
		]
		next_dialogue()
	else:
		# Shouldn't happen, but fallback
		dialogue_queue = [
			{"speaker": "kaido", "text": "The radio equipment is up here."},
			{"speaker": "kaido", "text": "Press [O] to climb down."},
		]
		next_dialogue()

func enter_radiotower_interior():
	current_mode = GameMode.RADIOTOWER_INTERIOR
	tower_player_pos = Vector2(240, 280)
	tower_player_vel = Vector2.ZERO
	tower_player_grounded = true
	
	# Only show climb dialogue the first time
	if not tower_reached_top:
		dialogue_queue = [
			{"speaker": "kaido", "text": "The radio equipment is at the top."},
			{"speaker": "kaido", "text": "Use <--> to move, [X]/Z to jump!"},
		]
		next_dialogue()

func exit_radiotower():
	current_mode = GameMode.EXPLORATION

func can_exit_radiotower() -> bool:
	# Can exit once the current tower circuit is built
	# Stage 11: Must build light_sensor first (can't exit)
	# Stage 12: Can exit - LED chain is built in cornfield, not here
	# Stage 13: Must build OR gate first (can't exit)
	# Stage 14+: All done, can exit
	
	if quest_stage == 11:
		return false  # Must build light sensor
	if quest_stage == 12:
		return true  # Go to cornfield for LED chain
	if quest_stage == 13:
		return false  # Must build OR gate
	return true  # Stage 14+ or before 11

func exit_radiotower_interior():
	current_mode = GameMode.EXPLORATION

func process_radiotower_interior(delta):
	if in_dialogue:
		return
	
	# Constants
	var MOVE_SPEED = 150.0
	var GRAVITY = 800.0
	var JUMP_FORCE = 320.0
	
	# Get horizontal input using unified system
	var input_x = get_input_horizontal()
	
	# Only update facing when there's actual input
	if input_x < 0:
		tower_player_facing_right = false
	elif input_x > 0:
		tower_player_facing_right = true
	
	# Check for jump input using unified system
	var jump_pressed = is_jump_just_pressed() and tower_player_grounded
	
	# Horizontal movement
	tower_player_vel.x = input_x * MOVE_SPEED
	
	# Metal platform footstep haptics (reduced)
	if input_x != 0 and tower_player_grounded:
		footstep_timer += delta
		if footstep_timer >= 0.2:
			footstep_timer = 0.0
			var foot_var = randf_range(0.9, 1.1)
			Input.start_joy_vibration(0, 0.14 * foot_var, 0.1 * foot_var, 0.02)
	elif input_x == 0:
		footstep_timer = 0.0
	
	# Gravity
	tower_player_vel.y += GRAVITY * delta
	tower_player_vel.y = min(tower_player_vel.y, 600)
	
	# Jump
	if jump_pressed:
		tower_player_vel.y = -JUMP_FORCE
		tower_player_grounded = false
		# Jump haptic (reduced)
		Input.start_joy_vibration(0, 0.18, 0.12, 0.04)
	
	# Apply movement
	tower_player_pos.x += tower_player_vel.x * delta
	tower_player_pos.y += tower_player_vel.y * delta
	
	# Platform collision
	tower_player_grounded = false
	for plat in tower_platforms:
		var left = plat.x
		var right = plat.x + plat.w
		var top = plat.y
		
		if tower_player_pos.x >= left - 10 and tower_player_pos.x <= right + 10:
			if tower_player_vel.y > 0 and tower_player_pos.y >= top - 5 and tower_player_pos.y <= top + 20:
				tower_player_pos.y = top
				# Landing haptic (reduced)
				if not tower_player_grounded:
					Input.start_joy_vibration(0, 0.2, 0.15, 0.05)
				tower_player_vel.y = 0
				tower_player_grounded = true
				break
	
	# Screen bounds
	tower_player_pos.x = clamp(tower_player_pos.x, 20, 460)
	tower_player_pos.y = clamp(tower_player_pos.y, 30, 295)
	
	# Safety net
	if tower_player_pos.y >= 290:
		tower_player_pos.y = 290
		tower_player_vel.y = 0
		tower_player_grounded = true
	
	# Reached top platform - auto transition to circuit building
	if tower_player_pos.y <= 50 and not tower_reached_top:
		tower_reached_top = true
		# Auto-transition to radiotower view for circuit building
		current_mode = GameMode.RADIOTOWER_VIEW
		start_radiotower_circuit()

func draw_radiotower_interior():
	interior_sc.draw_radiotower_interior()

func draw_tower_player_combat_style():
	interior_sc.draw_tower_player_combat_style()

# ============================================
# ENDING SEQUENCE
# ============================================

func enter_tunnel():
	dialogue_queue = [
		{"speaker": "system", "text": "[ NIGHTFALL ]"},
		{"speaker": "system", "text": "[ You approach the tunnel entrance. ]"},
		{"speaker": "system", "text": "[ Three robots emerge from the shadows! ]"},
		{"speaker": "robot", "text": "UNAUTHORIZED EXIT DETECTED."},
		{"speaker": "robot", "text": "INITIATING CONTAINMENT PROTOCOL."},
		{"speaker": "kaido", "text": "They're blocking our escape!"},
		{"speaker": "grandmother", "text": "Fight through them! I'll distract the others!"},
		{"speaker": "start_tunnel_fight", "text": ""},
	]
	next_dialogue()

func start_ending_cutscene():
	current_mode = GameMode.ENDING_CUTSCENE
	ending_stage = 0
	ending_timer = 0.0

# ============================================
# BUILD SEQUENCE SYSTEM
# ============================================

func start_build_sequence(gadget_id: String, intro_dialogue: Array, success_dialogue: Array):
	pending_gadget = gadget_id
	dialogue_queue = intro_dialogue.duplicate()
	dialogue_queue.append({"speaker": "build", "text": "[ BUILDING... ]", "gadget": gadget_id})
	dialogue_queue.append_array(success_dialogue)
	dialogue_queue.append({"speaker": "gadget_complete", "text": "", "gadget": gadget_id})
	next_dialogue()

# ============================================
# BACKPACK / GADGET SYSTEM
# ============================================

# Only these circuits become actual gadgets you keep
const REAL_GADGETS = ["led_lamp", "dimmer"]

func add_gadget(gadget_id: String):
	circuits_built += 1
	
	# Check for side circuit completions
	if gadget_id == "light_sensor" and not side_circuits_done.chicken_coop:
		side_circuits_done.chicken_coop = true
	if gadget_id == "well_indicator":
		side_circuits_done.well_pump = true
	
	# Only add to backpack if it's a real gadget
	if gadget_id in REAL_GADGETS:
		if not gadget_id in gadgets:
			gadgets.append(gadget_id)
		pending_gadget = gadget_id
		backpack_anim = 0.0
		backpack_selected = gadgets.find(gadget_id)
		current_mode = GameMode.BACKPACK_POPUP
	else:
		# Just a build - show success message but no backpack
		pending_gadget = ""
		# Stay in exploration mode

func close_backpack_popup():
	if backpack_anim < 1.0:
		backpack_anim = 1.0
		return
	# Equip the selected gadget when closing
	if gadgets.size() > 0 and backpack_selected >= 0 and backpack_selected < gadgets.size():
		var new_gadget = gadgets[backpack_selected]
		# If switching away from flashlight, turn it off
		if equipped_gadget == "led_lamp" and new_gadget != "led_lamp":
			flashlight_on = false
			gadget_effect_active = false
		equipped_gadget = new_gadget
	current_mode = GameMode.EXPLORATION
	pending_gadget = ""

func unequip_gadget():
	# Turn off flashlight if it was on
	if equipped_gadget == "led_lamp":
		flashlight_on = false
		gadget_effect_active = false
	equipped_gadget = ""

func show_backpack_view():
	pending_gadget = ""
	backpack_anim = 1.0
	backpack_tab = 0  # Default to gadgets tab
	if gadgets.size() > 0:
		backpack_selected = clamp(backpack_selected, 0, gadgets.size() - 1)
	if loot_items.size() > 0:
		loot_selected = clamp(loot_selected, 0, loot_items.size() - 1)
	current_mode = GameMode.BACKPACK_POPUP

func open_journal_view():
	journal_scroll = 0
	current_mode = GameMode.JOURNAL_VIEW

func close_journal_view():
	current_mode = GameMode.BACKPACK_POPUP

# ============================================
# GADGET USE SYSTEM
# ============================================

func use_equipped_gadget():
	if equipped_gadget == "":
		return
	
	match equipped_gadget:
		"led_lamp":
			use_flashlight_gadget()
		"dimmer":
			use_dimmer_gadget()
		_:
			# Generic gadget - just a brief effect, no dialogue
			gadget_use_timer = 0.5
			gadget_effect_active = true
			gadget_effect_timer = 1.0

func use_flashlight_gadget():
	# Toggle flashlight on/off
	flashlight_on = not flashlight_on
	
	if flashlight_on:
		gadget_effect_active = true
	else:
		gadget_effect_active = false
		gadget_effect_timer = 0.0

func get_flashlight_pos() -> Vector2:
	# Returns position where flashlight is shining
	var light_offset = Vector2.ZERO
	match player_facing:
		"up": light_offset = Vector2(0, -45)
		"down": light_offset = Vector2(0, 35)
		"left": light_offset = Vector2(-45, 0)
		"right": light_offset = Vector2(45, 0)
	return player_pos + light_offset

func use_dimmer_gadget():
	gadget_use_timer = 0.5
	gadget_effect_active = true
	gadget_effect_timer = 2.0
	
	# Only show dialogue if we actually affect something
	
	# If patrol is active and nearby, scramble them
	if patrol_active and patrol_positions.size() > 0:
		for patrol_pos in patrol_positions:
			if player_pos.distance_to(patrol_pos) < 100:
				dialogue_queue = [
					{"speaker": "system", "text": "[ The patrol robots lose sight of you in the dim light! ]"},
				]
				# Push patrols away
				for i in range(patrol_positions.size()):
					patrol_positions[i].x += 100
				next_dialogue()
				return
	
	# Otherwise just the visual effect, no dialogue

func update_gadget_timers(delta):
	if gadget_use_timer > 0:
		gadget_use_timer -= delta
	# Don't time out the effect if flashlight is on
	if gadget_effect_timer > 0 and not flashlight_on:
		gadget_effect_timer -= delta
		if gadget_effect_timer <= 0:
			gadget_effect_active = false
	# Punch cooldown
	if punch_cooldown > 0:
		punch_cooldown -= delta
	if punch_effect_timer > 0:
		punch_effect_timer -= delta

func do_punch():
	punch_cooldown = 0.4
	punch_effect_timer = 0.2
	punch_direction = player_facing
	
	# Check if we hit anything interactable
	var punch_offset = Vector2.ZERO
	match player_facing:
		"up": punch_offset = Vector2(0, -30)
		"down": punch_offset = Vector2(0, 30)
		"left": punch_offset = Vector2(-30, 0)
		"right": punch_offset = Vector2(30, 0)
	
	var punch_pos = player_pos + punch_offset
	
	# Can punch trees for fun (no effect yet, just feedback)
	# Could add: shake trees, scare chickens, etc.

func cycle_gadget():
	if gadgets.size() == 0:
		return
	
	# Turn off flashlight if switching away from it
	if equipped_gadget == "led_lamp" and flashlight_on:
		flashlight_on = false
		gadget_effect_active = false
	
	if equipped_gadget == "":
		# Equip first gadget
		equipped_gadget = gadgets[0]
		backpack_selected = 0
	else:
		# Find current index and go to next
		var current_index = gadgets.find(equipped_gadget)
		if current_index == -1:
			current_index = 0
		else:
			current_index = (current_index + 1) % gadgets.size()
		equipped_gadget = gadgets[current_index]
		backpack_selected = current_index

# ============================================
# DIALOGUE SYSTEM
# ============================================

func next_dialogue():
	if dialogue_queue.size() > 0:
		current_dialogue = dialogue_queue.pop_front()
		char_index = 0
		text_timer = 0
		# Haptic when dialogue starts
		if not in_dialogue:
			haptic_light()
		in_dialogue = true
		
		# Handle special dialogue types
		if current_dialogue.get("speaker") == "gadget_complete":
			var gadget_id = current_dialogue.get("gadget", "")
			if gadget_id != "":
				haptic_heavy()
				add_gadget(gadget_id)
			in_dialogue = false
			next_dialogue()
			return
		
		if current_dialogue.get("speaker") == "schematic":
			var circuit = current_dialogue.get("text", "")
			show_schematic(circuit)
			in_dialogue = false
			return
		
		if current_dialogue.get("speaker") == "start_ending":
			start_ending_cutscene()
			in_dialogue = false
			return
		
		if current_dialogue.get("speaker") == "start_combat":
			start_combat()
			in_dialogue = false
			return
		
		if current_dialogue.get("speaker") == "show_component":
			var component_id = current_dialogue.get("text", "")
			show_component_popup(component_id)
			in_dialogue = false
			next_dialogue()
			return
		
		if current_dialogue.get("speaker") == "farmer_wen_leave":
			farmer_wen_drive_away()
			in_dialogue = false
			next_dialogue()
			return
		
		if current_dialogue.get("speaker") == "start_tunnel_fight":
			start_tunnel_fight()
			in_dialogue = false
			return
		
		if current_dialogue.get("speaker") == "quest":
			var new_quest = current_dialogue.get("text", "")
			set_quest(new_quest)
			in_dialogue = false
			next_dialogue()
			return
		
		if current_dialogue.get("speaker") == "set_stage":
			quest_stage = int(current_dialogue.get("text", "0"))
			in_dialogue = false
			next_dialogue()
			return
	else:
		current_dialogue = {}
		current_dialogue_npc = ""
		in_dialogue = false

func advance_dialogue():
	haptic_light()
	var full_text = current_dialogue.get("text", "")
	if char_index < full_text.length():
		char_index = full_text.length()
	else:
		next_dialogue()

# ============================================
# DRAWING
# ============================================

func apply_zoom():
	# Scale and translate to follow player
	# camera_offset moves the world so player stays centered
	var offset = camera_offset * GAME_ZOOM
	draw_set_transform(offset, 0, Vector2(GAME_ZOOM, GAME_ZOOM))

func reset_zoom():
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw():
	# Each drawing function handles zoom internally
	# World elements get zoomed, UI elements stay normal size
	
	match current_mode:
		GameMode.INTRO:
			draw_intro_screen()
		GameMode.EXPLORATION:
			draw_exploration()
		GameMode.SHED_INTERIOR:
			draw_shed_interior()
		GameMode.PHOTOGRAPH:
			draw_photograph_reveal()
		GameMode.BUILD_SCREEN:
			draw_exploration()
		GameMode.SCHEMATIC_POPUP:
			draw_exploration()
			draw_schematic_popup()
		GameMode.BACKPACK_POPUP:
			draw_exploration()
			draw_backpack_popup()
		GameMode.JOURNAL_VIEW:
			draw_exploration()
			draw_journal_view()
		GameMode.COMBAT:
			draw_combat_arena()
		GameMode.RADIOTOWER_INTERIOR:
			draw_radiotower_interior()
		GameMode.RADIOTOWER_VIEW:
			draw_radiotower_view()
		GameMode.STAMPEDE:
			draw_stampede()
		GameMode.ENDING_CUTSCENE:
			draw_ending_cutscene()
		GameMode.REGION_COMPLETE:
			draw_region_complete()
		GameMode.SHOP_INTERIOR:
			draw_shop_interior()
		GameMode.TOWNHALL_INTERIOR:
			draw_townhall_interior()
		GameMode.BAKERY_INTERIOR:
			draw_bakery_interior()
		GameMode.PAUSE_MENU:
			# Draw the previous mode in background, then overlay pause menu
			match pause_previous_mode:
				GameMode.EXPLORATION:
					draw_exploration()
				GameMode.SHED_INTERIOR:
					draw_shed_interior()
				GameMode.SHOP_INTERIOR:
					draw_shop_interior()
				GameMode.TOWNHALL_INTERIOR:
					draw_townhall_interior()
				GameMode.BAKERY_INTERIOR:
					draw_bakery_interior()
			draw_pause_menu()
	
	# Nightfall overlay (no zoom - covers full screen)
	if is_nightfall and current_mode == GameMode.EXPLORATION:
		draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0.05, 0.05, 0.15, nightfall_alpha))
		apply_zoom()
		draw_lit_buildings()
		reset_zoom()
	
	# Screen transition overlay (fade effect between areas)
	if screen_transition_active and screen_transition_alpha > 0:
		draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0, 0, 0, screen_transition_alpha))

func draw_intro_screen():
	draw_rect(Rect2(0, 0, 480, 320), Color(0.0, 0.3, 0.35))  # Teal outer background
	draw_rect(Rect2(20, 20, 440, 280), Color(0.0, 0.4, 0.45))  # Teal inner background
	draw_rect(Rect2(20, 20, 440, 280), Color(0.3, 0.8, 0.8), false, 2)  # Light teal border
	
	if intro_page < intro_text.size():
		var lines = intro_text[intro_page]
		var full_text = get_intro_page_text()
		var shown_text = full_text.substr(0, intro_char_index)
		var shown_lines = shown_text.split("\n")
		
		var y = 45
		for i in range(shown_lines.size()):
			var line = shown_lines[i]
			var color = Color.WHITE
			var size = 14
			
			# Check original line for formatting (title, quotes)
			var original_line = ""
			if i < lines.size():
				original_line = lines[i]
			
			if i == 0 and original_line == "AGRICOMMUNE":
				color = Color(0.5, 0.95, 0.85)
				size = 20
				draw_string(ThemeDB.fallback_font, Vector2(175, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			elif original_line.begins_with("\""):
				color = Color(0.5, 0.9, 0.85)
				draw_string(ThemeDB.fallback_font, Vector2(40, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			else:
				draw_string(ThemeDB.fallback_font, Vector2(40, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			y += 18
	
	# Show prompt based on state
	var is_complete = intro_char_index >= get_intro_page_text().length()
	if is_complete:
		draw_string(ThemeDB.fallback_font, Vector2(380, 285), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.5))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(380, 285), "[X] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.4))
	
	var page_text = str(intro_page + 1) + "/" + str(intro_text.size())
	draw_string(ThemeDB.fallback_font, Vector2(40, 285), page_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.4))

func draw_exploration():
	# Zoom the game world
	apply_zoom()
	
	# Draw based on current area (background only)
	match current_area:
		Area.FARM:
			draw_farm_area()
		Area.CORNFIELD:
			draw_cornfield_area_background()
		Area.LAKESIDE:
			draw_lakeside_area_background()
		Area.TOWN_CENTER:
			draw_town_center_area_background()
	
	# Draw all entities Y-sorted (player, Kaido, NPCs)
	draw_entities_y_sorted()
	
	# Draw area overlays (sparkles, indicators, exit hints)
	match current_area:
		Area.FARM:
			draw_farm_area_overlay()
		Area.CORNFIELD:
			draw_cornfield_area_overlay()
		Area.LAKESIDE:
			draw_lakeside_area_overlay()
		Area.TOWN_CENTER:
			draw_town_center_area_overlay()
	
	# Draw world-space effects (with zoom)
	if punch_effect_timer > 0:
		draw_punch_effect()
	if gadget_effect_active or flashlight_on:
		draw_gadget_effect()
	if patrol_active and current_area == Area.FARM:
		draw_hiding_spots()
	
	# Reset zoom for UI elements
	reset_zoom()
	draw_ui()

func draw_entities_y_sorted():
	# =============================================================================
	# Y-SORTED ENTITY DRAWING SYSTEM
	# =============================================================================
	# All entities (NPCs, buildings, trees, objects) that the player can walk
	# in front of or behind must be added here for proper visual layering.
	#
	# HOW IT WORKS:
	# - Each entity has a "pos" with a Y value representing its "foot" position
	# - Lower Y = higher on screen = drawn first = appears BEHIND other entities
	# - Higher Y = lower on screen = drawn last = appears IN FRONT
	#
	# TO ADD NEW BUILDINGS/OBJECTS:
	# 1. Create a draw function: func draw_my_building()
	# 2. Add to entities array with foot Y position:
	#    entities.append({"type": "my_building", "pos": Vector2(x, foot_y)})
	# 3. Add match case in drawing section:
	#    "my_building": draw_my_building()
	#
	# FOOT Y CALCULATION:
	# - For buildings: foot_y = building_top_y + building_height
	# - For trees: foot_y = tree_y + ~60 (large) or ~44 (medium)
	# - For NPCs: foot_y = their pos.y (already at feet)
	#
	# WHAT GOES HERE vs BACKGROUND:
	# - HERE: Buildings, trees, NPCs, objects player walks around
	# - BACKGROUND: Ground tiles, paths, water, flat decorations (flowers, bushes)
	# =============================================================================
	
	var entities = []
	
	# Player and Kaido always present
	entities.append({"type": "player", "pos": player_pos})
	entities.append({"type": "kaido", "pos": kaido_pos})
	
	# Add area-specific NPCs and buildings
	match current_area:
		Area.FARM:
			# NPCs
			entities.append({"type": "grandmother", "pos": grandmother_pos})
			if farmer_wen_visible:
				entities.append({"type": "farmer_wen", "pos": farmer_wen_pos})
			if kid_visible:
				entities.append({"type": "kid", "pos": kid_pos})
			# Buildings (foot Y = where player stands in front)
			# Trees - large trees foot at y+60, medium at y+44
			# Positioned to avoid overlapping with buildings
			entities.append({"type": "farm_tree_large", "pos": Vector2(95, 70), "draw_pos": Vector2(95, 10)})      # Top left - clear
			entities.append({"type": "farm_tree_large", "pos": Vector2(450, 65), "draw_pos": Vector2(450, 5)})     # Top right corner
			entities.append({"type": "farm_tree_large", "pos": Vector2(0, 280), "draw_pos": Vector2(0, 220)})      # Bottom left corner
			# Medium tree in bottom right (away from shed/tunnel)
			entities.append({"type": "farm_tree_medium", "pos": Vector2(460, 294), "draw_pos": Vector2(460, 250)})
			# Main buildings
			entities.append({"type": "farm_house", "pos": Vector2(320, 111)})  # foot at bottom
			entities.append({"type": "farm_shed", "pos": Vector2(300, 235)})
			entities.append({"type": "farm_chicken_coop", "pos": Vector2(140, 130)})
			entities.append({"type": "farm_radiotower", "pos": Vector2(55, 110)})
			# Tractor if visible
			if tractor_visible:
				entities.append({"type": "farm_tractor", "pos": tractor_pos})
			# Patrol robots if active
			if patrol_active:
				for patrol in patrol_positions:
					entities.append({"type": "farm_patrol", "pos": patrol})
		
		Area.CORNFIELD:
			# Farmhouse in distance (always behind, but include for consistency)
			entities.append({"type": "cornfield_farmhouse", "pos": Vector2(380, 75)})
			# NPCs
			for npc in cornfield_npcs:
				entities.append({"type": "generic_npc", "pos": npc.pos, "name": npc.name})
		
		Area.LAKESIDE:
			# Trees along edges
			entities.append({"type": "lakeside_tree1", "pos": Vector2(40, 90), "draw_pos": Vector2(20, 40)})
			entities.append({"type": "lakeside_tree2", "pos": Vector2(30, 300), "draw_pos": Vector2(10, 250)})
			entities.append({"type": "lakeside_tree3", "pos": Vector2(460, 310), "draw_pos": Vector2(440, 260)})
			# Dock structure (west shore of lake)
			entities.append({"type": "lakeside_dock", "pos": Vector2(180, 190)})
			# Rocks on shore
			entities.append({"type": "lakeside_rock1", "pos": Vector2(80, 200)})
			entities.append({"type": "lakeside_rock2", "pos": Vector2(120, 280)})
			# Sewer entrance in rocky outcrop (bottom-right)
			# Y-sort at top of doorway so player appears in front when below
			entities.append({"type": "lakeside_sewer", "pos": Vector2(tunnel_pos.x, tunnel_pos.y - 10)})
			# NPCs
			for npc in lakeside_npcs:
				entities.append({"type": "generic_npc", "pos": npc.pos, "name": npc.name})
		
		Area.TOWN_CENTER:
			# Cherry blossom trees - positioned in corners away from buildings
			entities.append({"type": "cherry_tree", "pos": Vector2(25, 45), "draw_pos": Vector2(0, 0)})       # Top left corner
			entities.append({"type": "cherry_tree", "pos": Vector2(465, 45), "draw_pos": Vector2(440, 0)})    # Top right corner (away from bakery)
			entities.append({"type": "cherry_tree", "pos": Vector2(25, 295), "draw_pos": Vector2(0, 250)})    # Bottom left corner
			entities.append({"type": "cherry_tree", "pos": Vector2(465, 295), "draw_pos": Vector2(440, 250)}) # Bottom right corner
			# Buildings with their foot Y positions
			entities.append({"type": "town_shop", "pos": Vector2(70, 92)})
			entities.append({"type": "town_hall", "pos": Vector2(240, 107)})
			entities.append({"type": "town_bakery", "pos": Vector2(405, 92)})
			entities.append({"type": "town_house1", "pos": Vector2(80, 262)})
			entities.append({"type": "town_well", "pos": Vector2(240, 305)})
			entities.append({"type": "town_house2", "pos": Vector2(405, 277)})
			# NPCs
			for npc in town_npcs:
				entities.append({"type": "generic_npc", "pos": npc.pos, "name": npc.name})
	
	# Sort by Y position (lower Y drawn first, appears behind)
	entities.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	
	# Draw in sorted order
	for e in entities:
		match e.type:
			# Characters
			"player": draw_player(e.pos)
			"kaido": draw_kaido(e.pos)
			"grandmother": draw_grandmother(e.pos)
			"farmer_wen": draw_farmer_wen(e.pos)
			"kid": draw_kid(e.pos)
			"generic_npc": draw_generic_npc(e.pos, e.name)
			# Farm buildings
			"farm_tree_large": draw_tree_large(e.draw_pos.x, e.draw_pos.y)
			"farm_tree_medium": draw_tree_medium(e.draw_pos.x, e.draw_pos.y)
			"farm_house": draw_house(275, 35)
			"farm_shed": draw_shed_sprite(e.pos.x - 25, e.pos.y - 60)
			"farm_chicken_coop": draw_chicken_coop(chicken_coop_pos.x, chicken_coop_pos.y)
			"farm_radiotower": draw_radiotower_large(30, 20)
			"farm_tractor": draw_tractor(tractor_pos.x, tractor_pos.y)
			"farm_patrol": draw_robot_soldier(e.pos)
			# Cornfield
			"cornfield_farmhouse": draw_cornfield_farmhouse()
			# Lakeside
			"lakeside_tree1": draw_tree_large(e.draw_pos.x, e.draw_pos.y)
			"lakeside_tree2": draw_tree_medium(e.draw_pos.x, e.draw_pos.y)
			"lakeside_tree3": draw_tree_small(e.draw_pos.x, e.draw_pos.y)
			"lakeside_dock": draw_lakeside_dock_topdown(160, 155)
			"lakeside_sewer": draw_tunnel_entrance(tunnel_pos.x - 20, tunnel_pos.y - 30)
			"lakeside_rock1": draw_rock_cluster(80, 195)
			"lakeside_rock2": draw_rock_cluster(120, 275)
			# Town buildings
			"cherry_tree": draw_cherry_blossom_tree(e.draw_pos.x, e.draw_pos.y)
			"town_shop": draw_town_building_shop()
			"town_hall": draw_town_building_hall()
			"town_bakery": draw_town_building_bakery()
			"town_well": draw_town_building_well()
			"town_house1": draw_town_building_house1()
			"town_house2": draw_town_building_house2()

func draw_farm_area():
	# Draw farm background only (buildings handled by Y-sorted entity drawing)
	draw_ground_tiles()
	draw_dirt_paths()
	# Background elements that don't need Y-sorting
	draw_water_pond(385, 30)  # Water is always background
	draw_bushes()
	draw_rocks()
	draw_flowers()
	draw_fence(30, 275, 6)
	draw_farm_plot(35, 200, 4, 3)
	draw_irrigation_system(70, 210)
	draw_secret_sparkles()
	draw_dark_areas()
	# Note: Buildings, trees, NPCs drawn by draw_entities_y_sorted()

func draw_farm_area_overlay():
	# Wooden road signs in grass areas (well off pathways)
	# Right sign pointing to Town Center (in grass, not on road)
	draw_road_sign(425, 110, "Town ->", true)
	
	# Left sign pointing to Minigame (in grass, not on road)
	draw_road_sign(5, 110, "<- Game", false)
	
	# Up sign pointing to Cornfield (on grass left of vertical path)
	draw_road_sign_vertical(140, 10, "Cornfield", true)
	
	# Down sign pointing to Lakeside (on grass left of vertical path)
	draw_road_sign_vertical(145, 290, "Lakeside", false)
	
	# Draw tumbleweeds blowing across the farm
	draw_tumbleweeds()
	

func draw_road_sign(x: float, y: float, text: String, arrow_right: bool):
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	var outline = Color(0.0, 0.0, 0.0)

	# Post
	draw_rect(Rect2(x + 10, y + 12, 5, 20), outline)
	draw_rect(Rect2(x + 11, y + 13, 3, 18), wood_dark)

	# Sign board - minimal padding
	var sign_w = text.length() * 5 + 4
	draw_rect(Rect2(x - 1, y - 1, sign_w + 2, 14), outline)
	draw_rect(Rect2(x, y, sign_w, 12), wood)
	draw_rect(Rect2(x + 1, y + 1, sign_w - 2, 10), Color(0.62, 0.48, 0.36))

	# Text
	draw_string(ThemeDB.fallback_font, Vector2(x + 2, y + 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.15, 0.1))

func draw_road_sign_vertical(x: float, y: float, text: String, arrow_up: bool):
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	var outline = Color(0.0, 0.0, 0.0)

	# Post - at bottom of sign
	var post_y = y + 12
	draw_rect(Rect2(x + 14, post_y, 5, 18), outline)
	draw_rect(Rect2(x + 15, post_y + 1, 3, 16), wood_dark)

	# Sign board - minimal padding
	var arrow_text = "^ " + text if arrow_up else "v " + text
	var sign_w = arrow_text.length() * 5 + 4
	draw_rect(Rect2(x - 1, y - 1, sign_w + 2, 14), outline)
	draw_rect(Rect2(x, y, sign_w, 12), wood)
	draw_rect(Rect2(x + 1, y + 1, sign_w - 2, 10), Color(0.62, 0.48, 0.36))

	# Text
	draw_string(ThemeDB.fallback_font, Vector2(x + 2, y + 10), arrow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.15, 0.1))

func draw_ground_tiles():
	# Use Sprout Lands grass_tile.png - simple solid grass texture
	if tex_grass_tile:
		var tile_w = tex_grass_tile.get_width()
		var tile_h = tex_grass_tile.get_height()
		for x in range(0, 480, tile_w):
			for y in range(0, 320, tile_h):
				draw_texture(tex_grass_tile, Vector2(x, y))
	else:
		# Fallback to colored rectangles
		var grass_mid = Color(0.55, 0.85, 0.5)
		for x in range(0, 480, 16):
			for y in range(0, 320, 16):
				draw_rect(Rect2(x, y, 16, 16), grass_mid)

func draw_dirt_paths():
	# Use simple dirt_tile.png for paths
	if tex_dirt_tile:
		var tile_w = tex_dirt_tile.get_width()
		var tile_h = tex_dirt_tile.get_height()

		# Define path regions
		var v_path_left = 200
		var v_path_right = 264
		var h_path_top = 144
		var h_path_bottom = 192

		# Draw vertical path (north-south)
		for ty in range(0, 320, tile_h):
			for tx in range(v_path_left, v_path_right, tile_w):
				draw_texture(tex_dirt_tile, Vector2(tx, ty))

		# Draw horizontal path (east-west)
		for ty in range(h_path_top, h_path_bottom, tile_h):
			for tx in range(0, 480, tile_w):
				draw_texture(tex_dirt_tile, Vector2(tx, ty))

# DEPRECATED: This function is no longer used. 
# All buildings/trees are now drawn via draw_entities_y_sorted() for proper layering.
# Kept for reference only.
func _deprecated_draw_environment():
	draw_water_pond(385, 55)
	draw_trees()
	draw_bushes()
	draw_rocks()
	draw_flowers()
	draw_house(275, 35)
	draw_shed_sprite(315, 210)  # Shed in grass (shed_pos - offset)
	draw_fence(30, 275, 6)
	draw_farm_plot(35, 200, 4, 3)
	
	# Chicken coop drawn by Y-sorted entity system, not here
	
	# Journal page sparkles (undiscovered only)
	draw_secret_sparkles()
	
	# Always visible from the start
	draw_irrigation_system(70, 210)
	draw_radiotower_large(30, 20)
	
	# Tunnel/sewer entrance always visible
	draw_tunnel_entrance(tunnel_pos.x - 20, tunnel_pos.y - 30)
	
	# Draw dark areas (revealed by flashlight)
	draw_dark_areas()
	
	# Draw tractor (before characters so it's behind)
	if tractor_visible:
		draw_tractor(tractor_pos.x, tractor_pos.y)
	
	# Draw patrol if active
	if patrol_active:
		draw_patrol()
	
	# Draw kid if visible (walks in from right)
	if kid_visible:
		draw_kid(kid_pos)

func draw_chicken_coop(x: float, y: float):
	if tex_chicken_house:
		var tex_width = tex_chicken_house.get_width()
		var tex_height = tex_chicken_house.get_height()
		var scale = 1.05  # 20% larger than original 0.875
		var dest = Rect2(x - 18, y - tex_height * scale + 50, tex_width * scale, tex_height * scale)
		draw_texture_rect(tex_chicken_house, dest, false)
	
	# Chickens!
	draw_chicken(x + 55, y + 38, true)
	if not side_circuits_done.chicken_coop:
		draw_chicken(x + 35, y + 42, true)
		draw_chicken(x + 65, y + 45, true)
	
	# Fixed indicator
	if side_circuits_done.chicken_coop:
		var glow = (sin(continuous_timer * 3) * 0.3 + 0.7)
		draw_circle(Vector2(x + 40, y + 18), 4, Color(0.3, 0.9, 0.4, glow))

func draw_chicken(x: float, y: float, small: bool):
	# Use Ninja Adventure chicken sprites (black, brown, white variants)
	var chicken_tex: Texture2D = null
	# Pick color based on position for consistency
	var color_idx = int(abs(x * 7 + y * 13)) % 3
	match color_idx:
		0: chicken_tex = tex_ninja_chicken_black
		1: chicken_tex = tex_ninja_chicken_brown
		2: chicken_tex = tex_ninja_chicken_white

	if not chicken_tex:
		chicken_tex = tex_ninja_chicken
	if not chicken_tex:
		return

	var size_mult = 0.6 if small else 1.0
	var phase = x * 0.1 + y * 0.07
	var idle_bob = sin(continuous_timer * 2.5 + phase) * 1.5
	var idle_sway = sin(continuous_timer * 1.5 + phase) * 1.0

	# Ninja chicken spritesheets are 2 frames (32x16 total, 16x16 each)
	var frame_idx = int(continuous_timer * 4 + phase) % 2
	var src = Rect2(frame_idx * 16, 0, 16, 16)
	var dest_size = 28 * size_mult
	var dest = Rect2(x - dest_size / 2 + idle_sway, y - dest_size + 8 + idle_bob, dest_size, dest_size)
	draw_texture_rect_region(chicken_tex, dest, src)

func draw_cow(x: float, y: float, facing_left: bool = false):
	if not tex_cow_sprites:
		return
	
	var phase = x * 0.05 + y * 0.03
	var idle_bob = sin(continuous_timer * 1.5 + phase) * 2.0
	
	var frame_w = 32
	var frame_h = 32
	var frame_idx = int(fmod(continuous_timer * 2 + phase, 5))
	var frame_col = frame_idx % 3
	var frame_row = frame_idx / 3
	
	var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
	var dest_w = frame_w * 1.2
	var dest_h = frame_h * 1.2
	var dest = Rect2(x - dest_w / 2, y - dest_h + 8 + idle_bob, dest_w, dest_h)
	
	if facing_left:
		dest = Rect2(x + dest_w / 2, y - dest_h + 8 + idle_bob, -dest_w, dest_h)
	draw_texture_rect_region(tex_cow_sprites, dest, src)

func draw_tool(x: float, y: float, tool_type: int):
	if not tex_basic_tools:
		return
	
	var frame_size = 32
	var col = tool_type % 3
	var row = tool_type / 3
	var src = Rect2(col * frame_size, row * frame_size, frame_size, frame_size)
	var dest = Rect2(x - 12, y - 12, 24, 24)
	draw_texture_rect_region(tex_basic_tools, dest, src)

func draw_well(x: float, y: float):
	# High-quality hand-drawn well
	var stone_base = Color(0.62, 0.58, 0.52)
	var stone_mid = Color(0.55, 0.5, 0.45)
	var stone_dark = Color(0.42, 0.38, 0.35)
	var stone_highlight = Color(0.72, 0.68, 0.62)
	var wood_main = Color(0.58, 0.42, 0.32)
	var wood_dark = Color(0.42, 0.32, 0.25)
	var wood_light = Color(0.68, 0.52, 0.4)
	var roof_main = Color(0.5, 0.35, 0.28)
	var roof_dark = Color(0.38, 0.25, 0.2)
	var water_deep = Color(0.15, 0.25, 0.35)
	var water_surface = Color(0.3, 0.45, 0.6)
	var outline = Color(0.1, 0.08, 0.06)
	
	# Shadow
	draw_ellipse_shape(Vector2(x + 15, y + 42), Vector2(24, 8), Color(0, 0, 0, 0.25))
	
	# === STONE BASE ===
	# Outer stone ring
	draw_circle(Vector2(x + 15, y + 30), 20, outline)
	draw_circle(Vector2(x + 15, y + 30), 18, stone_base)
	
	# Stone texture (blocks)
	for i in range(8):
		var angle = i * TAU / 8
		var bx = x + 15 + cos(angle) * 14
		var by = y + 30 + sin(angle) * 10
		draw_rect(Rect2(bx - 4, by - 3, 8, 6), stone_mid)
		draw_rect(Rect2(bx - 4, by - 3, 8, 1), stone_highlight)
	
	# Inner stone ring
	draw_circle(Vector2(x + 15, y + 29), 14, stone_dark)
	
	# Water inside
	draw_circle(Vector2(x + 15, y + 29), 11, water_deep)
	draw_circle(Vector2(x + 15, y + 28), 8, water_surface)
	
	# Water reflection/ripple
	var ripple = sin(continuous_timer * 2.5) * 1.5
	draw_circle(Vector2(x + 15 + ripple, y + 27), 4, Color(0.5, 0.65, 0.8, 0.4))
	
	# === WOODEN FRAME ===
	# Left post
	draw_rect(Rect2(x - 3, y + 2, 7, 32), outline)
	draw_rect(Rect2(x - 2, y + 3, 5, 30), wood_main)
	draw_rect(Rect2(x - 2, y + 3, 2, 30), wood_light)
	draw_rect(Rect2(x + 1, y + 3, 2, 30), wood_dark)
	
	# Right post
	draw_rect(Rect2(x + 26, y + 2, 7, 32), outline)
	draw_rect(Rect2(x + 27, y + 3, 5, 30), wood_main)
	draw_rect(Rect2(x + 27, y + 3, 2, 30), wood_light)
	draw_rect(Rect2(x + 30, y + 3, 2, 30), wood_dark)
	
	# Cross beam
	draw_rect(Rect2(x - 4, y + 2, 38, 5), outline)
	draw_rect(Rect2(x - 3, y + 3, 36, 3), wood_main)
	draw_rect(Rect2(x - 3, y + 3, 36, 1), wood_light)
	
	# === ROOF ===
	var roof_pts = PackedVector2Array([
		Vector2(x - 6, y + 5),
		Vector2(x + 15, y - 8),
		Vector2(x + 36, y + 5)
	])
	draw_colored_polygon(roof_pts, outline)
	
	var roof_left = PackedVector2Array([
		Vector2(x - 4, y + 3),
		Vector2(x + 15, y - 6),
		Vector2(x + 15, y + 3)
	])
	draw_colored_polygon(roof_left, roof_dark)
	
	var roof_right = PackedVector2Array([
		Vector2(x + 15, y - 6),
		Vector2(x + 34, y + 3),
		Vector2(x + 15, y + 3)
	])
	draw_colored_polygon(roof_right, roof_main)
	
	# Roof peak cap
	draw_rect(Rect2(x + 13, y - 8, 4, 3), wood_dark)
	
	# === WINCH/CRANK ===
	# Horizontal bar
	draw_rect(Rect2(x + 2, y + 12, 26, 4), outline)
	draw_rect(Rect2(x + 3, y + 13, 24, 2), wood_main)
	
	# Crank handle (right side)
	draw_rect(Rect2(x + 30, y + 10, 6, 3), outline)
	draw_rect(Rect2(x + 31, y + 11, 4, 1), Color(0.5, 0.45, 0.42))
	draw_rect(Rect2(x + 34, y + 8, 3, 8), outline)
	draw_rect(Rect2(x + 35, y + 9, 1, 6), Color(0.5, 0.45, 0.42))
	
	# === BUCKET ===
	# Rope
	draw_line(Vector2(x + 15, y + 14), Vector2(x + 15, y + 20), Color(0.6, 0.5, 0.35), 1)
	
	# Bucket
	draw_rect(Rect2(x + 10, y + 18, 10, 10), outline)
	draw_rect(Rect2(x + 11, y + 19, 8, 8), Color(0.55, 0.42, 0.32))
	draw_rect(Rect2(x + 11, y + 19, 8, 2), Color(0.45, 0.35, 0.28))
	# Bucket bands
	draw_rect(Rect2(x + 10, y + 21, 10, 1), Color(0.4, 0.35, 0.32))
	draw_rect(Rect2(x + 10, y + 25, 10, 1), Color(0.4, 0.35, 0.32))
	
	# Fixed indicator LED
	if side_circuits_done.well_pump:
		var glow = (sin(continuous_timer * 2) * 0.3 + 0.7)
		draw_circle(Vector2(x + 15, y - 2), 4, Color(0.2, 0.9, 1.0, glow * 0.5))
		draw_circle(Vector2(x + 15, y - 2), 2, Color(0.4, 1.0, 1.0, glow))

func draw_secret_sparkles():
	# Draw torn journal pages at undiscovered locations (farm area only)
	var farm_pages = ["radiotower", "buried"]
	for page_name in farm_pages:
		if page_name in journal_pages_found:
			continue

		var pos = journal_page_locations[page_name]
		var dist = player_pos.distance_to(pos)

		# Use flashlight position if on, otherwise player position
		var check_pos = get_flashlight_pos() if flashlight_on else player_pos
		var light_dist = check_pos.distance_to(pos)

		# Fully bright when close or flashlight shining on it
		if flashlight_on and light_dist < 50:
			draw_journal_page_item(pos, 1.0)
		elif dist < 40:
			# Very close - fully visible and bright
			draw_journal_page_item(pos, 1.0)
		elif dist < 120:
			# Fade in as player approaches (closer = more visible)
			var alpha = 1.0 - ((dist - 40) / 80.0)
			draw_journal_page_item(pos, alpha)

func draw_area_journal_sparkles(page_name: String):
	# Draw journal page sparkle for a specific area
	if page_name in journal_pages_found:
		return

	var pos = journal_page_locations[page_name]
	var dist = player_pos.distance_to(pos)

	if dist < 40:
		# Very close - fully visible and bright
		draw_journal_page_item(pos, 1.0)
	elif dist < 120:
		# Fade in as player approaches (closer = more visible)
		var alpha = 1.0 - ((dist - 40) / 80.0)
		draw_journal_page_item(pos, alpha)

func draw_journal_page_item(pos: Vector2, alpha: float):
	var outline = Color(0, 0, 0, alpha)
	var paper = Color(0.95, 0.9, 0.8, alpha)
	var paper_dark = Color(0.85, 0.8, 0.7, alpha)
	var ink = Color(0.3, 0.25, 0.2, alpha)
	
	# Torn page shape with outline
	var page_pts_outline = PackedVector2Array([
		Vector2(pos.x - 9, pos.y - 12),
		Vector2(pos.x + 7, pos.y - 11),
		Vector2(pos.x + 9, pos.y - 8),
		Vector2(pos.x + 8, pos.y + 8),
		Vector2(pos.x + 5, pos.y + 10),
		Vector2(pos.x - 6, pos.y + 11),
		Vector2(pos.x - 8, pos.y + 7),
		Vector2(pos.x - 10, pos.y - 5)
	])
	draw_colored_polygon(page_pts_outline, outline)
	
	var page_pts = PackedVector2Array([
		Vector2(pos.x - 8, pos.y - 11),
		Vector2(pos.x + 6, pos.y - 10),
		Vector2(pos.x + 8, pos.y - 7),
		Vector2(pos.x + 7, pos.y + 7),
		Vector2(pos.x + 4, pos.y + 9),
		Vector2(pos.x - 5, pos.y + 10),
		Vector2(pos.x - 7, pos.y + 6),
		Vector2(pos.x - 9, pos.y - 4)
	])
	draw_colored_polygon(page_pts, paper)
	
	# Fold/crease
	draw_line(Vector2(pos.x - 4, pos.y - 9), Vector2(pos.x + 2, pos.y + 8), paper_dark, 1)
	
	# Text lines (scribbles)
	for i in range(4):
		var ly = pos.y - 6 + i * 4
		var lx = pos.x - 5
		var lw = 8 + (i % 2) * 3
		draw_line(Vector2(lx, ly), Vector2(lx + lw, ly), ink, 1)
	
	# Sparkle effect
	var sparkle = (sin(continuous_timer * 3 + pos.x) * 0.3 + 0.6)
	draw_circle(pos + Vector2(6, -8), 3, Color(1, 1, 0.7, sparkle * alpha))
	draw_circle(pos + Vector2(-5, 7), 2, Color(1, 1, 0.8, sparkle * alpha * 0.6))

func draw_water_pond(x: float, y: float):
	area_draw.draw_water_pond(x, y)

func draw_trees():
	# Trees repositioned to corners to avoid overlapping with buildings
	draw_tree_large(95, 10)    # Top left
	draw_tree_large(450, 5)    # Top right corner
	draw_tree_large(0, 220)    # Bottom left corner
	draw_tree_medium(460, 250) # Bottom right

func draw_tree_large(x: float, y: float):
	area_draw.draw_tree_large(x, y)

func draw_tree_medium(x: float, y: float):
	area_draw.draw_tree_medium(x, y)

func draw_tree_small(x: float, y: float):
	area_draw.draw_tree_small(x, y)

func draw_bushes():
	# Removed - keeping paths clear
	pass

func draw_bush(x: float, y: float):
	area_draw.draw_bush(x, y)

func draw_rocks():
	# Removed - keeping paths clear
	pass

func draw_rock_large(x: float, y: float):
	area_draw.draw_rock_large(x, y)

func draw_rock_small(x: float, y: float):
	area_draw.draw_rock_small(x, y)

func draw_flowers():
	# Removed - keeping paths clear
	pass

func draw_flower_cluster(x: float, y: float):
	area_draw.draw_flower_cluster(x, y)

func draw_house(x: float, y: float):
	area_draw.draw_house(x, y)

func draw_shed(x: float, y: float):
	area_draw.draw_shed(x, y)

func draw_shed_sprite(x: float, y: float):
	# Draw shed using sprite if available, fallback to procedural
	if tex_shed:
		var tex_width = tex_shed.get_width()
		var tex_height = tex_shed.get_height()
		var dest = Rect2(x, y, tex_width, tex_height)
		draw_texture_rect(tex_shed, dest, false)
	else:
		# Fallback to procedural drawing
		var wood = Color(0.65, 0.5, 0.38)
		var roof = Color(0.68, 0.45, 0.35)
		var outline = Color(0.0, 0.0, 0.0)
		
		# Body outline
		draw_rect(Rect2(x - 1, y + 14, 54, 37), outline)
		draw_rect(Rect2(x, y + 15, 52, 35), wood)
		
		# Roof outline
		draw_rect(Rect2(x - 5, y + 4, 62, 16), outline)
		draw_rect(Rect2(x - 4, y + 5, 60, 14), roof)
		
		# Door outline
		draw_rect(Rect2(x + 15, y + 27, 22, 24), outline)
		draw_rect(Rect2(x + 16, y + 28, 20, 22), Color(0.35, 0.26, 0.20))

func draw_fence(x: float, y: float, count: int):
	area_draw.draw_fence(x, y, count)

func draw_farm_plot(x: float, y: float, cols: int, rows: int):
	area_draw.draw_farm_plot(x, y, cols, rows)

func draw_irrigation_system(x: float, y: float):
	area_draw.draw_irrigation_system(x, y)

func draw_crops(x: float, y: float, healthy: bool):
	area_draw.draw_crops(x, y, healthy)

func draw_radiotower_large(x: float, y: float):
	var wood = Color(0.6, 0.48, 0.38)
	var wood_dark = Color(0.5, 0.38, 0.3)
	var roof = Color(0.7, 0.45, 0.35)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Tall legs outline
	draw_rect(Rect2(x + 4, y + 29, 10, 62), outline)
	draw_rect(Rect2(x + 36, y + 29, 10, 62), outline)
	draw_rect(Rect2(x + 5, y + 30, 8, 60), wood)
	draw_rect(Rect2(x + 37, y + 30, 8, 60), wood)
	
	# Cross braces
	draw_line(Vector2(x + 9, y + 40), Vector2(x + 41, y + 70), wood_dark, 3)
	draw_line(Vector2(x + 9, y + 70), Vector2(x + 41, y + 40), wood_dark, 3)
	
	# Platform outline
	draw_rect(Rect2(x - 6, y + 24, 62, 10), outline)
	draw_rect(Rect2(x - 5, y + 25, 60, 8), wood)
	
	# Cabin outline
	draw_rect(Rect2(x - 1, y - 1, 52, 30), outline)
	draw_rect(Rect2(x, y, 50, 28), wood)
	draw_rect(Rect2(x, y, 6, 28), wood_dark)
	
	# Roof outline
	var roof_outline_pts = PackedVector2Array([
		Vector2(x - 7, y + 3),
		Vector2(x + 25, y - 14),
		Vector2(x + 57, y + 3)
	])
	draw_colored_polygon(roof_outline_pts, outline)
	var roof_pts = PackedVector2Array([
		Vector2(x - 5, y + 2),
		Vector2(x + 25, y - 12),
		Vector2(x + 55, y + 2)
	])
	draw_colored_polygon(roof_pts, roof)
	
	# Window
	draw_rect(Rect2(x + 14, y + 7, 22, 16), outline)
	draw_rect(Rect2(x + 15, y + 8, 20, 14), Color(0.3, 0.4, 0.5))
	
	# Beacon
	if quest_stage >= 12 or is_nightfall:
		var beacon_alpha = (sin(anim_timer * 4) * 0.3 + 0.7)
		draw_circle(Vector2(x + 25, y - 5), 8, Color(1.0, 0.9, 0.3, beacon_alpha))
		draw_circle(Vector2(x + 25, y - 5), 4, Color(1.0, 1.0, 0.9))

func draw_tunnel_entrance(x: float, y: float):
	# Draw sewer sprite
	if tex_sewer:
		var w = tex_sewer.get_width()
		var h = tex_sewer.get_height()
		draw_texture_rect(tex_sewer, Rect2(x, y, w, h), false)

func draw_dark_areas():
	for area in dark_areas:
		var pos = area.pos
		var radius = area.radius
		var area_name = area.name
		
		# Check if already discovered
		var already_discovered = area_name in discovered_areas
		
		# Check if flashlight beam is hitting this area
		var light_pos = get_flashlight_pos() if flashlight_on else player_pos
		var is_being_lit = flashlight_on and light_pos.distance_to(pos) < radius + 30
		
		# Mark as discovered when lit
		if is_being_lit and not already_discovered:
			discovered_areas.append(area_name)
			already_discovered = true
		
		if already_discovered:
			# Permanently revealed - show the area clearly
			draw_circle(pos, radius, Color(0.3, 0.28, 0.22, 0.4))
			# Show what's inside
			draw_string(ThemeDB.fallback_font, Vector2(pos.x - 30, pos.y + 5), area_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.55, 0.45))
			# Sparkle if there's a secret nearby
			if area.secret != "" and area.secret not in journal_pages_found:
				var sparkle_alpha = sin(continuous_timer * 4) * 0.3 + 0.5
				draw_circle(pos + Vector2(10, -5), 3, Color(1, 0.9, 0.5, sparkle_alpha))
		else:
			# Dark - mysterious shadow
			draw_circle(pos, radius + 3, Color(0, 0, 0, 0.9))
			draw_circle(pos, radius, Color(0.08, 0.06, 0.05, 0.95))
			# Question mark
			var pulse = sin(continuous_timer * 2) * 0.2 + 0.6
			draw_string(ThemeDB.fallback_font, Vector2(pos.x - 4, pos.y + 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.35, 0.3, pulse))

func draw_patrol():
	for pos in patrol_positions:
		if pos.x > 0 and pos.x < 480:
			draw_robot_soldier(pos)

func draw_robot_soldier(pos: Vector2):
	# Robot body - menacing red/black
	var body_color = Color(0.35, 0.18, 0.18)
	var accent = Color(1.0, 0.25, 0.25)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Body outline
	draw_rect(Rect2(pos.x - 9, pos.y - 21, 18, 24), outline)
	draw_rect(Rect2(pos.x - 11, pos.y - 25, 22, 8), outline)
	
	# Body
	draw_rect(Rect2(pos.x - 8, pos.y - 20, 16, 22), body_color)
	draw_rect(Rect2(pos.x - 10, pos.y - 24, 20, 6), body_color)
	
	# Red visor
	draw_rect(Rect2(pos.x - 6, pos.y - 22, 12, 3), accent)
	
	# Legs (marching) with outline
	var leg_offset = sin(anim_timer * 8) * 3
	draw_rect(Rect2(pos.x - 7, pos.y + 1, 6, 12 + leg_offset), outline)
	draw_rect(Rect2(pos.x + 1, pos.y + 1, 6, 12 - leg_offset), outline)
	draw_rect(Rect2(pos.x - 6, pos.y + 2, 4, 10 + leg_offset), body_color)
	draw_rect(Rect2(pos.x + 2, pos.y + 2, 4, 10 - leg_offset), body_color)

func draw_kid(pos: Vector2):
	# Shadow
	draw_ellipse_shape(Vector2(pos.x, pos.y + 3), Vector2(8, 3), Color(0, 0, 0, 0.25))
	
	# Use custom Kid Milo sprite if available
	if tex_kid_milo:
		var w = tex_kid_milo.get_width()
		var h = tex_kid_milo.get_height()
		var dest = Rect2(pos.x - w/2, pos.y - h + 6, w, h)
		draw_texture_rect(tex_kid_milo, dest, false)
	elif tex_ninja_villager2:
		var src = Rect2(0, 0, 16, 16)
		var dest = Rect2(pos.x - 10, pos.y - 24, 20, 20)
		draw_texture_rect_region(tex_ninja_villager2, dest, src)

func draw_ellipse_shape(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func draw_characters():
	var entities = [
		{"type": "grandmother", "pos": grandmother_pos},
		{"type": "player", "pos": player_pos},
		{"type": "kaido", "pos": kaido_pos}
	]
	
	if farmer_wen_visible:
		entities.append({"type": "farmer_wen", "pos": farmer_wen_pos})
	
	entities.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	
	for e in entities:
		match e.type:
			"grandmother": draw_grandmother(e.pos)
			"player": draw_player(e.pos)
			"kaido": draw_kaido(e.pos)
			"farmer_wen": draw_farmer_wen(e.pos)

func draw_farm_npcs():
	# Draw grandmother and other farm NPCs
	if grandmother_pos.y < player_pos.y:
		draw_grandmother(grandmother_pos)
	if farmer_wen_visible and farmer_wen_pos.y < player_pos.y:
		draw_farmer_wen(farmer_wen_pos)
	if kid_visible and kid_pos.y < player_pos.y:
		draw_kid(kid_pos)

func draw_player_character():
	draw_player(player_pos)

func draw_kaido_character():
	draw_kaido(kaido_pos)
	# Draw NPCs that should be in front of player
	if current_area == Area.FARM:
		if grandmother_pos.y >= player_pos.y:
			draw_grandmother(grandmother_pos)
		if farmer_wen_visible and farmer_wen_pos.y >= player_pos.y:
			draw_farmer_wen(farmer_wen_pos)
		if kid_visible and kid_pos.y >= player_pos.y:
			draw_kid(kid_pos)

func draw_cornfield_area_background():
	# Draw cornfield background (no NPCs or farmhouse - those are Y-sorted)
	var corn_yellow = Color(0.85, 0.75, 0.35)
	var corn_green = Color(0.45, 0.65, 0.35)
	var corn_dark = Color(0.35, 0.5, 0.28)
	var dirt = Color(0.65, 0.5, 0.35)
	var dirt_dark = Color(0.5, 0.4, 0.28)
	var sky = Color(0.5, 0.65, 0.85)
	
	# Sky at top
	draw_rect(Rect2(0, 0, 480, 60), sky)
	
	# Ground
	draw_rect(Rect2(0, 60, 480, 260), Color(0.55, 0.45, 0.3))
	
	# Corn rows with better detail
	for row in range(8):
		var y = 80 + row * 30
		for col in range(12):
			var x = 20 + col * 40 + (row % 2) * 20
			# Skip corn in path area
			if x > 195 and x < 285:
				continue
			# Corn stalk with shading
			draw_rect(Rect2(x - 1, y, 6, 35), corn_dark)
			draw_rect(Rect2(x, y, 4, 35), corn_green)
			draw_rect(Rect2(x, y, 1, 35), Color(0.55, 0.75, 0.45))
			# Corn cob
			draw_rect(Rect2(x - 4, y + 10, 12, 15), Color(0.75, 0.65, 0.28))
			draw_rect(Rect2(x - 3, y + 11, 10, 13), corn_yellow)
			# Leaves
			draw_rect(Rect2(x - 10, y + 5, 10, 3), corn_green)
			draw_rect(Rect2(x - 10, y + 5, 10, 1), Color(0.55, 0.75, 0.45))
			draw_rect(Rect2(x + 4, y + 8, 10, 3), corn_green)
	
	# Path through corn
	draw_rect(Rect2(200, 60, 80, 260), dirt)
	draw_rect(Rect2(200, 60, 6, 260), dirt_dark)
	draw_rect(Rect2(274, 60, 6, 260), dirt_dark)
	draw_rect(Rect2(235, 60, 10, 260), Color(0.75, 0.6, 0.45))
	# Note: Farmhouse drawn by Y-sorted entity system

func draw_cornfield_area_overlay():
	# LED chain placement indicator
	if quest_stage == 12 and not cornfield_led_placed:
		var pulse = (sin(continuous_timer * 3) * 0.3 + 0.7)
		draw_circle(Vector2(240, 150), 20, Color(0.2, 0.8, 0.3, pulse * 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(200, 180), "Place LED Chain", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, pulse))
	
	# Journal page sparkle
	draw_area_journal_sparkles("cornfield")
	
	# Exit sign (in grass on left side of path)
	draw_road_sign_vertical(165, 290, "Farm", false)
	
	# Draw roaming animals
	draw_roaming_animals_for_area("cornfield")
	

# Keep old function for compatibility
func draw_cornfield_area():
	draw_cornfield_area_background()
	# Draw farmhouse
	draw_cornfield_farmhouse()
	# Draw NPCs
	for npc in cornfield_npcs:
		draw_generic_npc(npc.pos, npc.name)
	draw_cornfield_area_overlay()

func draw_lakeside_area_background():
	# Top-down view of lakeside area with lake on right side
	# Using tileset sprites for water, sand, and rocks

	var grass_base = Color(0.35, 0.55, 0.32)
	var dirt_path = Color(0.55, 0.45, 0.35)
	var dirt_path_light = Color(0.62, 0.52, 0.42)

	# Base grass layer
	draw_rect(Rect2(0, 0, 480, 320), grass_base)

	# Draw grass tiles if available
	if tex_grass_tile and tex_grass_tile_dark:
		for x in range(0, 480, 32):
			for y in range(0, 320, 32):
				var variation = int(fmod((x / 32 + y / 32), 2))
				var tex = tex_grass_tile if variation == 0 else tex_grass_tile_dark
				draw_texture_rect(tex, Rect2(x, y, 32, 32), false)

	# Draw lake using water panel sprite or water tiles
	if tex_water_panel:
		# Draw large water body using water panel (tiled)
		# Lake area roughly x: 240-480, y: 40-280
		for wx in range(240, 480, 32):
			for wy in range(50, 260, 32):
				# Check if this tile is within the lake shape
				var tile_center = Vector2(wx + 16, wy + 16)
				var in_lake = false
				if Vector2(340, 160).distance_to(tile_center) < 125:
					in_lake = true
				if Vector2(380, 140).distance_to(tile_center) < 95:
					in_lake = true
				if Vector2(300, 190).distance_to(tile_center) < 85:
					in_lake = true
				if in_lake:
					# Use animated frame from water texture
					var frame = int(continuous_timer * 3) % 4
					var src = Rect2(frame * 16, 0, 16, 16)
					if tex_water:
						draw_texture_rect_region(tex_water, Rect2(wx, wy, 32, 32), src)
					else:
						draw_texture_rect(tex_water_panel, Rect2(wx, wy, 32, 32), false)
	else:
		# Fallback: procedural water
		var water_deep = Color(0.22, 0.40, 0.58)
		var water_mid = Color(0.32, 0.52, 0.72)
		draw_circle(Vector2(340, 160), 120, water_deep)
		draw_circle(Vector2(380, 140), 90, water_deep)
		draw_circle(Vector2(300, 190), 80, water_deep)
		draw_circle(Vector2(345, 155), 85, water_mid)

	# Draw sandy shore using lake_sand tiles - overlapping for seamless coverage
	if tex_lake_sand:
		# West shore (near dock) - overlapping tiles (step 16 for 32px tiles)
		for sx in range(144, 256, 16):
			for sy in range(80, 224, 16):
				draw_texture_rect(tex_lake_sand, Rect2(sx, sy, 32, 32), false)
		# South shore - overlapping tiles
		for sx in range(208, 432, 16):
			for sy in range(208, 320, 16):
				draw_texture_rect(tex_lake_sand, Rect2(sx, sy, 32, 32), false)
		# North shore - overlapping tiles
		for sx in range(272, 464, 16):
			for sy in range(-16, 64, 16):
				draw_texture_rect(tex_lake_sand, Rect2(sx, sy, 32, 32), false)
	else:
		# Fallback: procedural sand
		var sand = Color(0.78, 0.70, 0.55)
		draw_rect(Rect2(144, 80, 112, 144), sand)
		draw_rect(Rect2(208, 208, 224, 112), sand)
		draw_rect(Rect2(272, 0, 192, 64), sand)

	# Dirt path from top (farm exit)
	draw_rect(Rect2(215, 0, 50, 100), dirt_path)
	draw_rect(Rect2(220, 0, 40, 100), dirt_path_light)
	draw_circle(Vector2(240, 100), 30, dirt_path)
	draw_circle(Vector2(230, 120), 25, dirt_path_light)

	# Rocky outcrop in bottom-right (near sewer) - overlapping tiles
	if tex_cliff_rock:
		for rx in range(352, 480, 16):
			for ry in range(208, 320, 16):
				draw_texture_rect(tex_cliff_rock, Rect2(rx, ry, 32, 32), false)
	else:
		# Fallback: procedural rocks
		var rock_color = Color(0.48, 0.45, 0.42)
		draw_rect(Rect2(352, 208, 128, 112), rock_color)

	# Note: Dock, rocks, trees, sewer drawn by Y-sorted entity system

func draw_lakeside_area_overlay():
	# Journal page sparkle
	draw_area_journal_sparkles("lakeside")

	# Exit sign (next to path at top, pointing up to farm)
	draw_road_sign_vertical(270, 30, "Farm", true)

	# Draw roaming animals
	draw_roaming_animals_for_area("lakeside")

# Keep old function for compatibility
func draw_lakeside_area():
	draw_lakeside_area_background()
	# Draw dock and rocks
	draw_lakeside_dock()
	draw_circle(Vector2(100, 260), 15, Color(0.5, 0.48, 0.45))
	draw_circle(Vector2(300, 280), 20, Color(0.55, 0.5, 0.48))
	draw_circle(Vector2(320, 270), 12, Color(0.5, 0.47, 0.43))
	# Draw NPCs
	for npc in lakeside_npcs:
		draw_generic_npc(npc.pos, npc.name)
	draw_lakeside_area_overlay()

func draw_town_center_area_background():
	# Beautiful town center with grass, cobblestone plaza, and decorations
	
	# ALWAYS draw solid grass base first (prevents any gaps)
	draw_rect(Rect2(0, 0, 480, 320), Color(0.32, 0.52, 0.30))
	
	# Draw grass tiles on top if available
	if tex_grass_tile and tex_grass_tile_dark:
		for x in range(0, 480, 32):
			for y in range(0, 320, 32):
				# Alternate between light and dark grass tiles for variety
				var variation = int(fmod((x / 32 + y / 32), 2))
				var tex = tex_grass_tile if variation == 0 else tex_grass_tile_dark
				draw_texture_rect(tex, Rect2(x, y, 32, 32), false)
	
	# Cobblestone plaza in center
	var stone_base = Color(0.72, 0.68, 0.62)
	var stone_dark = Color(0.58, 0.54, 0.48)
	var stone_light = Color(0.82, 0.78, 0.72)
	
	# Main plaza area
	draw_rect(Rect2(120, 100, 240, 140), stone_base)
	
	# Cobblestone pattern
	for x in range(120, 360, 16):
		for y in range(100, 240, 16):
			var shade = fmod((x + y), 32)
			var color = stone_dark if shade < 16 else stone_light
			draw_rect(Rect2(x + 1, y + 1, 14, 14), color)
			# Stone edges
			draw_rect(Rect2(x, y, 16, 1), stone_dark)
			draw_rect(Rect2(x, y, 1, 16), stone_dark)
	
	# Main road from left (to Farm)
	draw_rect(Rect2(0, 135, 120, 50), stone_base)
	for x in range(0, 120, 16):
		for y in range(135, 185, 16):
			var shade = fmod((x + y), 32)
			draw_rect(Rect2(x + 1, y + 1, 14, 14), stone_dark if shade < 16 else stone_light)
	
	# Colorful festival bunting across the top
	var bunting_colors = [Color(0.9, 0.3, 0.3), Color(0.3, 0.7, 0.9), Color(0.9, 0.8, 0.3), Color(0.5, 0.8, 0.4), Color(0.8, 0.5, 0.8)]
	for i in range(24):
		var bx = 20 + i * 20
		var by = 95 + sin(i * 0.8) * 3
		var color = bunting_colors[i % bunting_colors.size()]
		# Triangle flag
		var points = PackedVector2Array([
			Vector2(bx, by),
			Vector2(bx + 8, by),
			Vector2(bx + 4, by + 12)
		])
		draw_colored_polygon(points, color)
	# Bunting string
	draw_line(Vector2(10, 95), Vector2(470, 95), Color(0.4, 0.3, 0.25), 2)
	
	# Central fountain
	draw_town_fountain()
	
	# Flower beds around plaza edges
	draw_flower_bed(125, 235, 8)
	draw_flower_bed(280, 235, 8)
	draw_flower_bed(125, 95, 6)
	draw_flower_bed(300, 95, 6)
	
	# Decorative barrels
	draw_barrel(115, 115)
	draw_barrel(355, 115)
	draw_barrel(115, 220)
	draw_barrel(355, 220)
	
	# Market stall on the right side
	draw_market_stall(380, 140)
	
	# Benches
	draw_bench(140, 200)
	draw_bench(320, 200)
	
	# Lamp posts
	draw_lamp_post(130, 130)
	draw_lamp_post(350, 130)

func draw_town_fountain():
	area_draw.draw_town_fountain(300, 180)

func draw_flower_bed(x: float, y: float, count: int):
	area_draw.draw_flower_bed(x, y, count)

func draw_barrel(x: float, y: float):
	area_draw.draw_barrel(x, y)

func draw_market_stall(x: float, y: float):
	area_draw.draw_market_stall(x, y)

func draw_bench(x: float, y: float):
	area_draw.draw_bench(x, y)

func draw_lamp_post(x: float, y: float):
	area_draw.draw_lamp_post(x, y)

func draw_town_building_shop():
	area_draw.draw_town_building_shop()

func draw_town_building_hall():
	area_draw.draw_town_building_hall()

func draw_town_building_bakery():
	area_draw.draw_town_building_bakery()

func draw_town_building_well():
	# Well has custom position logic, keep some local drawing
	area_draw.draw_well(350, 190)

func draw_town_building_house1():
	area_draw.draw_town_building_house1()

func draw_town_building_house2():
	area_draw.draw_town_building_house2()

func draw_cornfield_farmhouse():
	area_draw.draw_cornfield_farmhouse(50, 30)

func draw_lakeside_dock():
	area_draw.draw_lakeside_dock(180, 220)

func draw_lakeside_dock_topdown(x: float, y: float):
	# Top-down dock extending east into the lake
	var wood = Color(0.55, 0.42, 0.32)
	var wood_dark = Color(0.45, 0.35, 0.25)
	var wood_light = Color(0.62, 0.50, 0.40)
	# Main dock planks (horizontal, extending into water)
	for i in range(10):
		var plank_color = wood if i % 2 == 0 else wood_dark
		draw_rect(Rect2(x + i * 7, y, 6, 35), plank_color)
	# Side rails
	draw_rect(Rect2(x, y - 2, 70, 3), wood_light)
	draw_rect(Rect2(x, y + 34, 70, 3), wood_light)
	# Support posts (at start and end)
	draw_circle(Vector2(x + 5, y + 17), 4, wood_dark)
	draw_circle(Vector2(x + 65, y + 17), 4, wood_dark)

func draw_rock_cluster(x: float, y: float):
	# Small cluster of rocks
	var rock1 = Color(0.52, 0.48, 0.45)
	var rock2 = Color(0.45, 0.42, 0.40)
	var rock3 = Color(0.58, 0.55, 0.50)
	draw_circle(Vector2(x, y), 12, rock1)
	draw_circle(Vector2(x + 10, y - 5), 8, rock2)
	draw_circle(Vector2(x - 5, y + 8), 6, rock3)
	# Highlight
	draw_circle(Vector2(x - 2, y - 3), 4, Color(0.65, 0.62, 0.58))

func draw_cherry_blossom_tree(x: float, y: float):
	area_draw.draw_cherry_blossom_tree(x, y)

func draw_town_center_area_overlay():
	# Journal page sparkle
	draw_area_journal_sparkles("town_center")
	
	# Exit road sign (in grass below the road entrance)
	draw_road_sign(5, 210, "<- Farm", false)
	
	# Draw roaming animals
	draw_roaming_animals_for_area("town_center")
	
	# Tools and materials around town
	# Tools removed

# Keep old function for compatibility
func draw_town_center_area():
	draw_town_center_area_background()
	# Draw all buildings
	draw_town_building_shop()
	draw_town_building_hall()
	draw_town_building_bakery()
	draw_town_building_house1()
	draw_town_building_well()
	draw_town_building_house2()
	# Draw NPCs
	for npc in town_npcs:
		draw_generic_npc(npc.pos, npc.name)
	draw_town_center_area_overlay()

func draw_generic_npc(pos: Vector2, npc_name: String):
	# Idle animation
	var idle_bob = sin(continuous_timer * 2.0 + pos.x * 0.05) * 1.5
	var anim_pos = Vector2(pos.x, pos.y + idle_bob)
	
	# Shadow
	draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(7, 3), Color(0, 0, 0, 0.2))
	
	# Use custom elder sprite for Elder Sato
	if npc_name == "Elder Sato" and tex_villager_elder:
		var w = tex_villager_elder.get_width()
		var h = tex_villager_elder.get_height()
		var dest = Rect2(anim_pos.x - w/2, anim_pos.y - h + 4, w, h)
		draw_texture_rect(tex_villager_elder, dest, false)
		return
	
	# Select sprite based on NPC name hash
	var tex: Texture2D = null
	var hash_val = npc_name.hash() % 11
	
	match hash_val:
		0: tex = tex_ninja_villager
		1: tex = tex_ninja_villager2
		2: tex = tex_ninja_villager3
		3: tex = tex_ninja_woman
		4: tex = tex_ninja_princess
		5: tex = tex_ninja_noble
		6: tex = tex_ninja_monk
		7: tex = tex_ninja_monk2
		8: tex = tex_ninja_master
		9: tex = tex_ninja_hunter
		10: tex = tex_ninja_inspector
		_: tex = tex_ninja_villager
	
	if tex:
		var frame_size = 16
		var frame = int(fmod(continuous_timer * 2 + pos.x * 0.1, 4))
		var src = Rect2(frame * frame_size, 0, frame_size, frame_size)
		var scale = 1.4
		var dest = Rect2(anim_pos.x - frame_size * scale / 2, anim_pos.y - frame_size * scale + 4, frame_size * scale, frame_size * scale)
		draw_texture_rect_region(tex, dest, src)

func draw_stampede():
	# Combat-style arena background
	var shake_offset = Vector2.ZERO
	if screen_shake > 0:
		shake_offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	
	# Sky gradient
	draw_rect(Rect2(0, 0, 480, 100), Color(0.5, 0.65, 0.85))
	draw_rect(Rect2(0, 100, 480, 50), Color(0.55, 0.7, 0.75))
	
	# Distant hills
	var hill_pts = PackedVector2Array([
		Vector2(0, 150), Vector2(80, 120), Vector2(160, 140),
		Vector2(240, 110), Vector2(320, 135), Vector2(400, 115),
		Vector2(480, 145), Vector2(480, 150), Vector2(0, 150)
	])
	draw_colored_polygon(hill_pts, Color(0.4, 0.55, 0.4))
	
	# Grass field
	draw_rect(Rect2(0, 150, 480, 70), Color(0.45, 0.65, 0.4))
	
	# Ground/arena floor
	var ground_y = int(stampede_ground_y)
	draw_rect(Rect2(0, ground_y, 480, 100), Color(0.6, 0.5, 0.38))
	draw_rect(Rect2(0, ground_y, 480, 4), Color(0.5, 0.4, 0.3))
	
	# Fence in background
	for i in range(10):
		var fx = 30 + i * 50
		draw_rect(Rect2(fx + shake_offset.x, 165 + shake_offset.y, 6, 55), Color(0.55, 0.42, 0.32))
	draw_rect(Rect2(0 + shake_offset.x, 175 + shake_offset.y, 480, 4), Color(0.6, 0.48, 0.38))
	draw_rect(Rect2(0 + shake_offset.x, 200 + shake_offset.y, 480, 4), Color(0.6, 0.48, 0.38))
	
	# Draw all animals first
	for animal in stampede_animals:
		if not animal.defeated:
			draw_stampede_animal_new(animal, shake_offset)

	# Draw player on top
	draw_stampede_player(stampede_player_pos + shake_offset)
	
	# Draw hit effects (floating text)
	for effect in stampede_hit_effects:
		var alpha = effect.timer / 0.6
		draw_string(ThemeDB.fallback_font, effect.pos + shake_offset, effect.text, 
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(effect.color.r, effect.color.g, effect.color.b, alpha))
	
	# UI - Health bar (combat style)
	draw_stampede_health_bar()
	
	# Wave indicator
	draw_rect(Rect2(350, 8, 120, 22), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(360, 24), "Wave " + str(stampede_wave), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	# Score display
	draw_rect(Rect2(180, 8, 120, 22), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(190, 24), "Score: " + str(stampede_score), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.9, 0.3))
	
	# High score (if any)
	if stampede_high_score > 0:
		draw_string(ThemeDB.fallback_font, Vector2(190, 40), "Best: " + str(stampede_high_score), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))
	
	# Controls hint
	draw_rect(Rect2(60, 295, 360, 22), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(70, 310), "[X]/Z=Jump  [_]/X=Punch  [O]/C=Dodge  Q/R2=Gadget", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.9, 0.9))

	# Show equipped gadget
	if equipped_gadget != "":
		draw_rect(Rect2(10, 50, 80, 20), Color(0, 0, 0, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(15, 65), equipped_gadget, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.95, 0.88))
	
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()

func draw_stampede_player(pos: Vector2):
	var flash_mod = Color(1, 1, 1, 1)
	if stampede_player_state == "hit":
		flash_mod = Color(2, 1.5, 1.5, 1)
	
	var idle_bob = 0.0
	if stampede_player_state == "idle" and stampede_player_grounded:
		idle_bob = sin(continuous_timer * 3) * 2
	
	# Shadow at ground level
	if stampede_player_grounded:
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 5), Vector2(15, 5), Color(0, 0, 0, 0.3))
	else:
		# When jumping, shadow stays on ground but shrinks based on height
		var jump_height = stampede_ground_y - pos.y
		var shadow_scale = clamp(1.0 - jump_height / 80.0, 0.3, 1.0)
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 5), Vector2(15 * shadow_scale, 5 * shadow_scale), Color(0, 0, 0, 0.2))
	
	# Use new animation system if available
	if player_anim_loaded:
		var tex: Texture2D = null
		var frame = int(continuous_timer * 10) % 6  # Smoother animation timing
		var scale_factor = 1.8  # Larger for stampede view
		var flip_h = not stampede_player_facing_right  # Flip sprite when facing left

		# Determine which sprite to use based on state and movement
		match stampede_player_state:
			"idle":
				# Check if player is walking while in idle state
				if stampede_player_is_walking:
					# Walking animation with correct direction
					var walk_frames = tex_player_walk_east if stampede_player_facing_right else tex_player_walk_west
					if walk_frames.size() > frame:
						tex = walk_frames[frame]
						flip_h = false  # Don't flip - we have directional sprites
				else:
					# Standing idle - face the direction we're looking
					tex = tex_player_idle_east if stampede_player_facing_right else tex_player_idle_west
					if not tex:
						tex = tex_player_idle_south
					flip_h = false
			"jumping":
				# Use mid-walk frame for jumping, facing correct direction
				var walk_frames = tex_player_walk_east if stampede_player_facing_right else tex_player_walk_west
				if walk_frames.size() > 2:
					tex = walk_frames[2]
					flip_h = false
				elif tex_player_walk_south.size() > 2:
					tex = tex_player_walk_south[2]
			"dodging":
				# Dodge animation with correct direction
				var walk_frames = tex_player_walk_east if stampede_player_facing_right else tex_player_walk_west
				if walk_frames.size() > frame:
					tex = walk_frames[frame]
					flip_h = false
			"attacking":
				# Use attack animation frames with correct direction
				var attack_frames = tex_player_attack_east if stampede_player_facing_right else tex_player_attack_west
				if attack_frames.size() > 0:
					var attack_frame = int((0.25 - stampede_player_state_timer) * 24) % attack_frames.size()
					attack_frame = clamp(attack_frame, 0, attack_frames.size() - 1)
					tex = attack_frames[attack_frame]
					flip_h = false
				elif tex_player_attack_south.size() > 0:
					var attack_frame = int((0.25 - stampede_player_state_timer) * 24) % tex_player_attack_south.size()
					attack_frame = clamp(attack_frame, 0, tex_player_attack_south.size() - 1)
					tex = tex_player_attack_south[attack_frame]
			"hit":
				tex = tex_player_idle_east if stampede_player_facing_right else tex_player_idle_west
				if not tex:
					tex = tex_player_idle_south
				flip_h = false
			_:
				var walk_frames = tex_player_walk_east if stampede_player_facing_right else tex_player_walk_west
				if walk_frames.size() > frame:
					tex = walk_frames[frame]
					flip_h = false

		if not tex and tex_player_idle_south:
			tex = tex_player_idle_south

		if tex:
			var w = tex.get_width() * scale_factor
			var h = tex.get_height() * scale_factor
			var dest = Rect2(pos.x - w/2, pos.y - h + 10 + idle_bob, w, h)
			# Handle sprite flipping if needed
			if flip_h:
				dest.position.x = pos.x + w/2
				dest.size.x = -w
			draw_texture_rect(tex, dest, false, flash_mod)
			
			# Attack swing effect
			if stampede_player_state == "attacking":
				var swing_alpha = 0.8 if stampede_player_state_timer > 0.15 else 0.4
				draw_arc(Vector2(pos.x - 40, pos.y - 15), 35, deg_to_rad(120), deg_to_rad(240), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
				draw_arc(Vector2(pos.x + 40, pos.y - 15), 35, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
				if stampede_player_state_timer > 0.18:
					draw_circle(Vector2(pos.x, pos.y - 20), 45, Color(1, 1, 0.7, 0.3))
			return
	
	# Fallback to old system
	if not tex_player:
		return
	
	var row = 0
	var frame = player_frame % 6
	var scale_factor = 1.5
	
	match stampede_player_state:
		"idle":
			row = 0
			frame = int(continuous_timer * 2) % 3
		"attacking":
			row = 3
			frame = 2 + int((0.25 - stampede_player_state_timer) * 12) % 3
		"jumping":
			row = 3
			frame = 1
		"dodging":
			row = 3
			frame = 3
		"countering":
			row = 3
			frame = 4
		"hit":
			row = 0
	
	var src = Rect2(frame * 48, row * 48, 48, 48)
	var sprite_size = 48 * scale_factor
	var dest = Rect2(pos.x - sprite_size/2, pos.y - sprite_size + 10 + idle_bob, sprite_size, sprite_size)
	draw_texture_rect_region(tex_player, dest, src, flash_mod)
	
	# Attack swing effect
	if stampede_player_state == "attacking":
		var swing_alpha = 0.8 if stampede_player_state_timer > 0.15 else 0.4
		draw_arc(Vector2(pos.x - 40, pos.y - 15), 35, deg_to_rad(120), deg_to_rad(240), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
		draw_arc(Vector2(pos.x + 40, pos.y - 15), 35, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
		if stampede_player_state_timer > 0.18:
			draw_circle(Vector2(pos.x, pos.y - 20), 45, Color(1, 1, 0.7, 0.3))

func draw_stampede_animal_new(animal: Dictionary, offset: Vector2):
	var pos = animal.pos + offset
	var animal_type = animal.type
	var is_defeated = animal.defeated
	
	# Flash white if recently hit
	var tint = Color(1, 1, 1)
	if animal.hit_flash > 0:
		tint = Color(2, 2, 2)
	if is_defeated:
		tint = Color(0.5, 0.5, 0.5, 0.6)
	
	# Shadow at ground level
	if not is_defeated:
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 3), Vector2(18, 5), Color(0, 0, 0, 0.25))
	
	match animal_type:
		"chicken":
			# Use Ninja Adventure chicken sprites (black, brown, white variants)
			var chicken_tex: Texture2D = null
			# Pick color based on animal position hash for consistency
			var color_idx = int(abs(animal.pos.x * 7 + animal.pos.y * 13)) % 3
			match color_idx:
				0: chicken_tex = tex_ninja_chicken_black
				1: chicken_tex = tex_ninja_chicken_brown
				2: chicken_tex = tex_ninja_chicken_white

			if not chicken_tex:
				chicken_tex = tex_ninja_chicken  # Fallback to default

			if chicken_tex:
				# Ninja chicken spritesheets are 2 frames (32x16 total, 16x16 each)
				var frame_idx = int(continuous_timer * 4) % 2
				var src = Rect2(frame_idx * 16, 0, 16, 16)
				var dest = Rect2(pos.x - 20, pos.y - 32, 40, 40)
				draw_texture_rect_region(chicken_tex, dest, src, tint)
			else:
				# Fallback chicken - simple rectangles
				var body_col = Color(1.0, 0.95, 0.8)
				var comb_col = Color(0.9, 0.25, 0.2)
				if tint.r > 1.5:  # Hit flash
					body_col = Color(1.5, 1.5, 1.5)
					comb_col = Color(1.5, 1.0, 1.0)
				draw_rect(Rect2(pos.x - 10, pos.y - 20, 20, 16), body_col)
				draw_rect(Rect2(pos.x - 4, pos.y - 26, 8, 8), body_col)
				draw_rect(Rect2(pos.x - 2, pos.y - 30, 4, 5), comb_col)
				draw_rect(Rect2(pos.x + 4, pos.y - 24, 4, 3), Color(1.0, 0.6, 0.2))

			if not is_defeated:
				draw_animal_hp_bar(pos, animal)

		"cow":
			if tex_cow_sprites:
				var frame_w = 32
				var frame_h = 32
				var frame_idx = int(fmod(continuous_timer * 4 + pos.x * 0.1, 5))
				var frame_col = frame_idx % 3
				var frame_row = frame_idx / 3
				var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
				var dest = Rect2(pos.x - 28, pos.y - 36, 56, 44)
				draw_texture_rect_region(tex_cow_sprites, dest, src, tint)
			else:
				# Fallback cow
				draw_rect(Rect2(pos.x - 20, pos.y - 28, 40, 24), Color(0.9 * tint.r, 0.9 * tint.g, 0.85 * tint.b))
				draw_rect(Rect2(pos.x + 15, pos.y - 32, 12, 14), Color(0.85 * tint.r, 0.85 * tint.g, 0.8 * tint.b))
				draw_circle(Vector2(pos.x + 20, pos.y - 26), 2, Color(0.1, 0.1, 0.1))
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)

		"bull":
			# Body - brown
			draw_rect(Rect2(pos.x - 28, pos.y - 32, 56, 32), Color(0.5 * tint.r, 0.32 * tint.g, 0.22 * tint.b))
			# Head
			draw_rect(Rect2(pos.x + 22, pos.y - 38, 24, 28), Color(0.5 * tint.r, 0.32 * tint.g, 0.22 * tint.b))
			# Horns
			draw_rect(Rect2(pos.x + 22, pos.y - 46, 7, 12), Color(0.9, 0.85, 0.75))
			draw_rect(Rect2(pos.x + 39, pos.y - 46, 7, 12), Color(0.9, 0.85, 0.75))
			# Snout
			draw_rect(Rect2(pos.x + 40, pos.y - 28, 12, 14), Color(0.6, 0.45, 0.4))
			# Eye - angry!
			draw_circle(Vector2(pos.x + 32, pos.y - 32), 4, Color(0.95, 0.2, 0.2))
			# Legs
			draw_rect(Rect2(pos.x - 20, pos.y - 5, 7, 10), Color(0.45, 0.3, 0.2))
			draw_rect(Rect2(pos.x + 14, pos.y - 5, 7, 10), Color(0.45, 0.3, 0.2))
			# HP bar
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)
		
		"robot":
			# Small patrol robot
			var metal = Color(0.5 * tint.r, 0.55 * tint.g, 0.6 * tint.b)
			var dark_metal = Color(0.3 * tint.r, 0.35 * tint.g, 0.4 * tint.b)
			var eye_color = Color(1.0, 0.2, 0.1) if not is_defeated else Color(0.3, 0.1, 0.1)

			# Body
			draw_rect(Rect2(pos.x - 15, pos.y - 30, 30, 25), dark_metal)
			draw_rect(Rect2(pos.x - 13, pos.y - 28, 26, 21), metal)
			# Head
			draw_rect(Rect2(pos.x - 10, pos.y - 42, 20, 14), dark_metal)
			draw_rect(Rect2(pos.x - 8, pos.y - 40, 16, 10), metal)
			# Eye visor
			draw_rect(Rect2(pos.x - 7, pos.y - 38, 14, 5), eye_color)
			# Antenna
			draw_rect(Rect2(pos.x - 2, pos.y - 48, 4, 8), dark_metal)
			draw_circle(Vector2(pos.x, pos.y - 50), 3, eye_color)
			# Legs/treads
			draw_rect(Rect2(pos.x - 12, pos.y - 8, 8, 10), dark_metal)
			draw_rect(Rect2(pos.x + 4, pos.y - 8, 8, 10), dark_metal)
			# HP bar
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)

		"heavy_robot":
			# Heavy enforcer robot
			var metal = Color(0.4 * tint.r, 0.4 * tint.g, 0.45 * tint.b)
			var dark_metal = Color(0.25 * tint.r, 0.25 * tint.g, 0.3 * tint.b)
			var accent = Color(0.6 * tint.r, 0.15 * tint.g, 0.1 * tint.b)
			var eye_color = Color(1.0, 0.1, 0.3) if not is_defeated else Color(0.3, 0.05, 0.1)
			
			# Body - larger
			draw_rect(Rect2(pos.x - 24, pos.y - 38, 48, 35), dark_metal)
			draw_rect(Rect2(pos.x - 22, pos.y - 36, 44, 31), metal)
			# Danger stripes
			for i in range(4):
				draw_rect(Rect2(pos.x - 20 + i * 12, pos.y - 32, 6, 3), accent)
			# Head
			draw_rect(Rect2(pos.x - 14, pos.y - 52, 28, 16), dark_metal)
			draw_rect(Rect2(pos.x - 12, pos.y - 50, 24, 12), metal)
			# Eye visor - menacing
			draw_rect(Rect2(pos.x - 10, pos.y - 47, 20, 6), eye_color)
			# Shoulder plates
			draw_rect(Rect2(pos.x - 30, pos.y - 35, 8, 18), dark_metal)
			draw_rect(Rect2(pos.x + 22, pos.y - 35, 8, 18), dark_metal)
			# Legs
			draw_rect(Rect2(pos.x - 18, pos.y - 8, 12, 12), dark_metal)
			draw_rect(Rect2(pos.x + 6, pos.y - 8, 12, 12), dark_metal)
			# HP bar
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)

func draw_animal_hp_bar(pos: Vector2, animal: Dictionary):
	var bar_width = 30
	var bar_height = 4
	var hp_ratio = float(animal.hp) / float(animal.max_hp)
	
	# Background
	draw_rect(Rect2(pos.x - bar_width/2, pos.y - 45, bar_width, bar_height), Color(0.2, 0.2, 0.2))
	# HP fill
	var hp_color = Color(0.2, 0.8, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.7, 0.2) if hp_ratio > 0.25 else Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(pos.x - bar_width/2, pos.y - 45, bar_width * hp_ratio, bar_height), hp_color)

func draw_stampede_health_bar():
	# Player health bar (combat style)
	var bar_x = 20
	var bar_y = 15
	var bar_width = 120
	var bar_height = 16
	
	# Background
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4), Color(0, 0, 0))
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.25, 0.15, 0.15))
	
	# HP fill
	var hp_ratio = float(stampede_player_hp) / float(stampede_player_max_hp)
	var hp_color = Color(0.2, 0.85, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.75, 0.2) if hp_ratio > 0.25 else Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height), hp_color)
	
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + 5, bar_y + 13), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func draw_player(pos: Vector2):
	# Use new animation system if loaded
	if player_anim_loaded:
		draw_player_animated(pos)
		return
	
	if not tex_player:
		return
	
	var tex_width = tex_player.get_width()
	var tex_height = tex_player.get_height()
	
	# Spritesheet format (6 frames * 48px = 288px wide)
	if tex_width >= 288 and tex_height >= 240:
		var row = 0
		# Player faces camera (front) for down/left/right, back only for up
		# No flip - sprite stays consistent to avoid position shifting
		if is_walking:
			match player_facing:
				"down", "left", "right": row = 3  # Walk front
				"up": row = 4  # Walk up (back)
		else:
			match player_facing:
				"down", "left", "right": row = 0  # Idle front
				"up": row = 1  # Idle up (back)
		
		var frame = player_frame % 6
		var src = Rect2(frame * 48, row * 48, 48, 48)
		var dest = Rect2(pos.x - 24, pos.y - 40, 48, 48)
		draw_texture_rect_region(tex_player, dest, src)
		
		if is_hiding:
			draw_circle(pos, 20, Color(0.2, 0.4, 0.3, 0.4))
	else:
		# Single sprite with walk animation
		var bob_offset = 0.0
		var squash = 1.0
		
		if is_walking:
			# Bobbing motion when walking (up-down bounce)
			bob_offset = abs(sin(continuous_timer * 12)) * 3
			# Slight squash/stretch
			squash = 1.0 + sin(continuous_timer * 12) * 0.05
		
		# Shadow
		draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(10, 4), Color(0, 0, 0, 0.25))
		
		# Draw sprite with animation
		var draw_height = 32 * squash
		var draw_width = 32 / squash
		var dest = Rect2(pos.x - draw_width/2, pos.y - draw_height - bob_offset + 4, draw_width, draw_height)
		
		# Flip sprite based on facing direction
		if player_facing == "left":
			# Flip horizontally by using negative width
			dest = Rect2(pos.x + draw_width/2, pos.y - draw_height - bob_offset + 4, -draw_width, draw_height)
		
		draw_texture_rect(tex_player, dest, false)

func draw_player_animated(pos: Vector2):
	# Shadow
	draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(10, 4), Color(0, 0, 0, 0.25))
	
	var tex: Texture2D = null
	var frame = player_frame % 6
	
	# Priority 1: Attack animation
	if player_attacking:
		var attack_frame = player_attack_frame % 6
		match player_facing:
			"down":
				if tex_player_attack_south.size() > attack_frame:
					tex = tex_player_attack_south[attack_frame]
			"up":
				if tex_player_attack_north.size() > attack_frame:
					tex = tex_player_attack_north[attack_frame]
			"left":
				if tex_player_attack_west.size() > attack_frame:
					tex = tex_player_attack_west[attack_frame]
			"right":
				if tex_player_attack_east.size() > attack_frame:
					tex = tex_player_attack_east[attack_frame]
		# Fallback to walk frame if attack not loaded
		if not tex and tex_player_walk_south.size() > 0:
			tex = tex_player_walk_south[frame]
	elif is_walking:
		# Get walk frame based on direction
		match player_facing:
			"down":
				if tex_player_walk_south.size() > frame:
					tex = tex_player_walk_south[frame]
			"up":
				if tex_player_walk_north.size() > frame:
					tex = tex_player_walk_north[frame]
			"left":
				if tex_player_walk_west.size() > frame:
					tex = tex_player_walk_west[frame]
			"right":
				if tex_player_walk_east.size() > frame:
					tex = tex_player_walk_east[frame]
	else:
		# Get idle sprite based on direction
		match player_facing:
			"down": tex = tex_player_idle_south
			"up": tex = tex_player_idle_north
			"left": tex = tex_player_idle_west
			"right": tex = tex_player_idle_east
	
	# Fallback to first walk frame if idle not loaded
	if not tex:
		if tex_player_walk_south.size() > 0:
			tex = tex_player_walk_south[0]
		elif tex_player:
			# Ultimate fallback to old single sprite
			draw_texture_rect(tex_player, Rect2(pos.x - 16, pos.y - 28, 32, 32), false)
			return
	
	if tex:
		var w = tex.get_width()
		var h = tex.get_height()
		# Center sprite at feet position
		var dest = Rect2(pos.x - w/2, pos.y - h + 4, w, h)
		draw_texture_rect(tex, dest, false)
	
	if is_hiding:
		draw_circle(pos, 20, Color(0.2, 0.4, 0.3, 0.4))

func draw_grandmother(pos: Vector2):
	# Shadow
	draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(10, 4), Color(0, 0, 0, 0.3))
	
	# Use new animation system if available
	if grandmother_anim_loaded:
		var tex: Texture2D = null
		var frame = grandmother_frame % 6
		
		if grandmother_is_walking:
			# Get walk frame based on direction
			match grandmother_facing:
				"down":
					if tex_grandmother_walk_south.size() > frame:
						tex = tex_grandmother_walk_south[frame]
				"up":
					if tex_grandmother_walk_north.size() > frame:
						tex = tex_grandmother_walk_north[frame]
				"left":
					if tex_grandmother_walk_west.size() > frame:
						tex = tex_grandmother_walk_west[frame]
				"right":
					if tex_grandmother_walk_east.size() > frame:
						tex = tex_grandmother_walk_east[frame]
		else:
			# Get idle sprite based on direction
			match grandmother_facing:
				"down": tex = tex_grandmother_idle_south
				"up": tex = tex_grandmother_idle_north
				"left": tex = tex_grandmother_idle_west
				"right": tex = tex_grandmother_idle_east
		
		# Fallback to first walk frame if idle not loaded
		if not tex:
			if tex_grandmother_walk_south.size() > 0:
				tex = tex_grandmother_walk_south[0]
		
		if tex:
			var w = tex.get_width()
			var h = tex.get_height()
			# Idle bob when not walking
			var idle_bob = 0.0
			if not grandmother_is_walking:
				idle_bob = sin(continuous_timer * 1.2) * 0.5
			var dest = Rect2(pos.x - w/2, pos.y - h + 4 + idle_bob, w, h)
			draw_texture_rect(tex, dest, false)
			return
	
	# Fallback to old sprite
	if tex_grandmother:
		var idle_bob = sin(continuous_timer * 1.2) * 0.5
		var w = tex_grandmother.get_width()
		var h = tex_grandmother.get_height()
		var dest = Rect2(pos.x - w/2, pos.y - h + 4 + idle_bob, w, h)
		draw_texture_rect(tex_grandmother, dest, false)
	elif tex_ninja_oldwoman:
		var src = Rect2(0, 0, 16, 16)
		var dest = Rect2(pos.x - 10, pos.y - 17, 20, 20)
		draw_texture_rect_region(tex_ninja_oldwoman, dest, src)

func draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func draw_kaido(pos: Vector2):
	# Idle animation - gentle floating/bobbing motion (vertical only)
	var idle_float = sin(continuous_timer * 2.5) * 2.0

	# Small shadow underneath
	draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(8, 3), Color(0, 0, 0, 0.25))

	if tex_kaido:
		var w = tex_kaido.get_width()
		var h = tex_kaido.get_height()
		# Scale down large sprites - use integer scale for clean pixels
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
		var dest = Rect2(pos.x - draw_w / 2, pos.y - draw_h + 3 + idle_float, draw_w, draw_h)
		draw_texture_rect(tex_kaido, dest, false)

func draw_farmer_wen(pos: Vector2):
	# Shadow
	draw_ellipse_shape(Vector2(pos.x, pos.y + 5), Vector2(14, 5), Color(0, 0, 0, 0.3))
	
	# Use custom Farmer Wen sprite if available
	if tex_farmer_wen:
		var w = tex_farmer_wen.get_width()
		var h = tex_farmer_wen.get_height()
		var dest = Rect2(pos.x - w/2, pos.y - h + 8, w, h)
		draw_texture_rect(tex_farmer_wen, dest, false)
	elif tex_ninja_villager:
		var src = Rect2(0, 0, 16, 16)
		var dest = Rect2(pos.x - 12, pos.y - 28, 24, 24)
		draw_texture_rect_region(tex_ninja_villager, dest, src)

func draw_tractor(x: float, y: float):
	# Simple tractor shape with outlines
	var body = Color(0.9, 0.35, 0.28)
	var wheel = Color(0.25, 0.25, 0.28)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Body outline
	draw_rect(Rect2(x - 1, y - 16, 37, 22), outline)
	draw_rect(Rect2(x + 29, y - 26, 17, 17), outline)
	
	# Body
	draw_rect(Rect2(x, y - 15, 35, 20), body)
	draw_rect(Rect2(x + 30, y - 25, 15, 15), body)
	
	# Wheels with outline
	draw_circle(Vector2(x + 8, y + 8), 11, outline)
	draw_circle(Vector2(x + 8, y + 8), 10, wheel)
	draw_circle(Vector2(x + 8, y + 8), 4, Color(0.4, 0.4, 0.42))
	
	draw_circle(Vector2(x + 35, y + 5), 8, outline)
	draw_circle(Vector2(x + 35, y + 5), 7, wheel)
	draw_circle(Vector2(x + 35, y + 5), 3, Color(0.4, 0.4, 0.42))
	
	# Exhaust with outline
	draw_rect(Rect2(x + 37, y - 31, 6, 12), outline)
	draw_rect(Rect2(x + 38, y - 30, 4, 10), Color(0.3, 0.3, 0.32))

func draw_lit_buildings():
	# Draw glowing lights on buildings during nightfall
	if "radiotower" in lit_buildings:
		var glow = (sin(anim_timer * 2) * 0.2 + 0.8)
		draw_circle(Vector2(55, 15), 15, Color(1.0, 0.9, 0.3, glow * 0.3))
	
	if "barn" in lit_buildings:
		draw_circle(Vector2(150, 180), 10, Color(1.0, 0.8, 0.3, 0.4))
	
	if "mill" in lit_buildings:
		draw_circle(Vector2(420, 100), 10, Color(1.0, 0.8, 0.3, 0.4))
	
	# Path of lights to tunnel
	for i in range(5):
		var lx = 300 + i * 25
		var ly = 200 + i * 15
		var flicker = (sin(anim_timer * 3 + i) * 0.2 + 0.8)
		draw_circle(Vector2(lx, ly), 5, Color(0.3, 0.9, 0.4, flicker * 0.6))

func draw_ui():
	# Help Meter (top-left battery)
	draw_help_meter()
	
	# DEBUG: Show quest stage (remove this line later)
	draw_string(ThemeDB.fallback_font, Vector2(400, 310), "Stage: " + str(quest_stage), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0, 0.7))
	
	# Top-right HUD stack (backpack, location, quest, gadget, collectibles)
	draw_backpack_icon()
	draw_area_indicator()
	draw_quest_box()
	draw_equipped_gadget_indicator()
	draw_journal_indicator()
	draw_relics_indicator()
	
	# Bottom-right currency
	draw_faraday_credits()
	
	# Interaction prompts (bottom-center)
	if not in_dialogue:
		match current_area:
			Area.FARM:
				draw_farm_prompts()
			Area.CORNFIELD:
				draw_cornfield_prompts()
			Area.LAKESIDE:
				draw_lakeside_prompts()
			Area.TOWN_CENTER:
				draw_town_prompts()
	
	# Draw stealth UI when patrol is active (awareness bar only - hiding spots drawn with zoom)
	if patrol_active and current_area == Area.FARM:
		draw_awareness_bar()
	
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()
	
	# Component popup overlay
	if showing_component_popup:
		draw_component_popup()
	
	# Detection failure overlay
	if player_detected:
		draw_detection_overlay()

func draw_farm_prompts():
	# Main story interactions
	if player_pos.distance_to(grandmother_pos) < 40:
		draw_prompt("Talk")
	elif player_pos.distance_to(shed_pos) < 50:
		draw_prompt("Enter")
	elif quest_stage >= 7 and player_pos.distance_to(irrigation_pos) < 40:
		draw_prompt("Fix")
	elif farmer_wen_visible and not farmer_wen_leaving and player_pos.distance_to(farmer_wen_pos) < 40:
		draw_prompt("Help")
	elif quest_stage >= 10 and player_pos.distance_to(radiotower_pos) < 50:
		draw_prompt("Climb")
	elif player_pos.distance_to(tunnel_pos) < 40:
		if is_nightfall:
			draw_prompt("Enter Sewers")
		else:
			draw_prompt("Sewers (Locked)")
	# Kid NPC
	elif kid_visible and not kid_walking_in and player_pos.distance_to(kid_pos) < 35:
		draw_prompt("Talk")
	# Optional side circuits
	elif not side_circuits_done.chicken_coop and player_pos.distance_to(chicken_coop_interact_pos) < 30:
		draw_prompt("Examine Coop")
	# Journal pages
	else:
		for page_name in journal_page_locations:
			if page_name not in journal_pages_found:
				var page_pos = journal_page_locations[page_name]
				if player_pos.distance_to(page_pos) < 30:
					draw_prompt("Search")
					break

func draw_cornfield_prompts():
	# NPC prompts
	for npc in cornfield_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			draw_prompt("Talk")
			return
	# LED Chain placement
	if quest_stage == 12 and not cornfield_led_placed:
		var led_spot = Vector2(240, 150)
		if player_pos.distance_to(led_spot) < 40:
			draw_prompt("Place Signals")
			return
	# Journal page
	if "cornfield" not in journal_pages_found:
		var page_pos = journal_page_locations["cornfield"]
		if player_pos.distance_to(page_pos) < 30:
			draw_prompt("Search")
			return

func draw_lakeside_prompts():
	# NPC prompts
	for npc in lakeside_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			draw_prompt("Talk")
			return
	# Secret
	if not lakeside_secret_found and player_pos.distance_to(Vector2(310, 275)) < 30:
		draw_prompt("Search")
		return
	# Journal page
	if "lakeside" not in journal_pages_found:
		var page_pos = journal_page_locations["lakeside"]
		if player_pos.distance_to(page_pos) < 30:
			draw_prompt("Search")
			return

func draw_town_prompts():
	# Building entry prompts
	if player_pos.distance_to(shop_door_pos) < 30:
		draw_prompt("Enter Shop")
		return
	if player_pos.distance_to(townhall_door_pos) < 30:
		draw_prompt("Enter Town Hall")
		return
	if player_pos.distance_to(bakery_door_pos) < 30:
		draw_prompt("Enter Bakery")
		return
	# NPC prompts
	for npc in town_npcs:
		if player_pos.distance_to(npc.pos) < 35:
			draw_prompt("Talk")
			return
	# Well circuit (now lower in grass)
	if not side_circuits_done.well_pump and player_pos.distance_to(well_pos) < 35:
		draw_prompt("Examine Well")
		return
	# Journal page
	if "town_center" not in journal_pages_found:
		var page_pos = journal_page_locations["town_center"]
		if player_pos.distance_to(page_pos) < 30:
			draw_prompt("Search")
			return

func draw_area_indicator():
	ui_draw.draw_area_indicator()

func draw_detection_overlay():
	ui_draw.draw_detection_overlay()

func draw_journal_indicator():
	ui_draw.draw_journal_indicator()

func draw_relics_indicator():
	ui_draw.draw_relics_indicator()

func draw_equipped_gadget_indicator():
	ui_draw.draw_equipped_gadget_indicator()

func draw_awareness_bar():
	ui_draw.draw_awareness_bar()

func draw_hiding_spots():
	# Show hiding spot indicators when patrol is active
	for spot in hiding_spots:
		var dist = player_pos.distance_to(spot)
		
		# Only show nearby spots
		if dist < 80:
			var alpha = 1.0 - (dist / 80.0)
			alpha *= 0.6
			
			# Bush/cover indicator
			draw_circle(spot, 18, Color(0.2, 0.4, 0.25, alpha * 0.5))
			draw_circle(spot, 12, Color(0.3, 0.55, 0.35, alpha * 0.7))
			
			# Can hide here prompt - show within hiding range
			if dist < 40:
				var pulse = sin(continuous_timer * 3) * 0.2 + 0.8
				if is_hiding:
					draw_string(ThemeDB.fallback_font, Vector2(spot.x - 20, spot.y + 25), "HIDING", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.3, 0.9, 0.4, pulse))
				else:
					# Show "SAFE" if near a spot even without pressing hide
					draw_string(ThemeDB.fallback_font, Vector2(spot.x - 15, spot.y + 25), "SAFE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 0.8, 0.6, pulse))

func draw_gadget_mini_icon(gadget_id: String, x: float, y: float, icon_color: Color):
	ui_draw.draw_gadget_mini_icon(gadget_id, x, y, icon_color)

func draw_gadget_effect():
	# Visual overlay when gadget is active
	
	match equipped_gadget:
		"led_lamp":
			if flashlight_on:
				# Calculate light position in front of player based on facing
				var light_offset = Vector2.ZERO
				match player_facing:
					"up": light_offset = Vector2(0, -45)
					"down": light_offset = Vector2(0, 35)
					"left": light_offset = Vector2(-45, 0)
					"right": light_offset = Vector2(45, 0)
				
				var light_pos = player_pos + light_offset
				
				# Simple soft spotlight in front
				draw_circle(light_pos, 35, Color(1, 0.95, 0.8, 0.15))
				draw_circle(light_pos, 22, Color(1, 0.95, 0.85, 0.2))
				draw_circle(light_pos, 10, Color(1, 0.98, 0.9, 0.25))
		"dimmer":
			# Inversion wave effect (fades out)
			if gadget_effect_timer > 0:
				var alpha = min(gadget_effect_timer / 2.0, 0.4)
				var wave_radius = (2.0 - gadget_effect_timer) * 80
				draw_arc(player_pos, wave_radius, 0, TAU, 32, Color(0.6, 0.4, 0.9, alpha), 3)
				draw_arc(player_pos, wave_radius * 0.6, 0, TAU, 32, Color(0.8, 0.5, 1.0, alpha * 0.5), 2)

func draw_punch_effect():
	var punch_offset = Vector2.ZERO
	match punch_direction:
		"up": punch_offset = Vector2(0, -25)
		"down": punch_offset = Vector2(0, 25)
		"left": punch_offset = Vector2(-25, 0)
		"right": punch_offset = Vector2(25, 0)
	
	var punch_pos = player_pos + punch_offset
	var alpha = punch_effect_timer / 0.2  # Fade out
	
	# Impact burst
	draw_circle(punch_pos, 12 * (1.0 - alpha) + 8, Color(1, 0.9, 0.6, alpha * 0.6))
	draw_circle(punch_pos, 6, Color(1, 1, 1, alpha * 0.8))
	
	# Motion lines
	var line_length = 15 * alpha
	match punch_direction:
		"up":
			draw_line(punch_pos + Vector2(-8, 5), punch_pos + Vector2(-8, 5 + line_length), Color(1, 1, 1, alpha * 0.5), 2)
			draw_line(punch_pos + Vector2(8, 5), punch_pos + Vector2(8, 5 + line_length), Color(1, 1, 1, alpha * 0.5), 2)
		"down":
			draw_line(punch_pos + Vector2(-8, -5), punch_pos + Vector2(-8, -5 - line_length), Color(1, 1, 1, alpha * 0.5), 2)
			draw_line(punch_pos + Vector2(8, -5), punch_pos + Vector2(8, -5 - line_length), Color(1, 1, 1, alpha * 0.5), 2)
		"left":
			draw_line(punch_pos + Vector2(5, -8), punch_pos + Vector2(5 + line_length, -8), Color(1, 1, 1, alpha * 0.5), 2)
			draw_line(punch_pos + Vector2(5, 8), punch_pos + Vector2(5 + line_length, 8), Color(1, 1, 1, alpha * 0.5), 2)
		"right":
			draw_line(punch_pos + Vector2(-5, -8), punch_pos + Vector2(-5 - line_length, -8), Color(1, 1, 1, alpha * 0.5), 2)
			draw_line(punch_pos + Vector2(-5, 8), punch_pos + Vector2(-5 - line_length, 8), Color(1, 1, 1, alpha * 0.5), 2)

func draw_component_popup():
	ui_draw.draw_component_popup()

func draw_prompt(text: String):
	ui_draw.draw_prompt(text)

func draw_quest_box():
	ui_draw.draw_quest_box()

func draw_backpack_icon():
	ui_draw.draw_backpack_icon()

func draw_help_meter():
	ui_draw.draw_help_meter()

func draw_faraday_credits():
	ui_draw.draw_faraday_credits()

func draw_dialogue_box():
	var box_y = 218
	
	draw_rect(Rect2(10, box_y, 460, 92), Color(0.06, 0.08, 0.12, 0.95))
	draw_rect(Rect2(10, box_y, 460, 92), Color(0.3, 0.75, 0.68), false, 3)
	
	var speaker = current_dialogue.get("speaker", "")
	draw_rect(Rect2(18, box_y + 8, 64, 64), Color(0.12, 0.18, 0.15))
	draw_rect(Rect2(18, box_y + 8, 64, 64), Color(0.25, 0.55, 0.5), false, 2)
	
	# Portrait based on speaker
	draw_speaker_portrait(speaker, box_y)
	
	var name_text = speaker.replace("_", " ").capitalize()
	match speaker:
		"system", "build":
			name_text = "System"
		"kid":
			name_text = "Milo"
		"journal":
			name_text = "Journal"
		"relic":
			name_text = "Relic Found"
		"farmer_wen":
			name_text = "Farmer Wen"
		"villager":
			if current_dialogue_npc != "":
				name_text = current_dialogue_npc
			else:
				name_text = "Villager"
		"robot":
			if current_dialogue_npc != "":
				name_text = current_dialogue_npc
			else:
				name_text = "Robot"
	# Name plate - width based on name length
	var name_width = max(90, name_text.length() * 8 + 12)
	draw_rect(Rect2(90, box_y + 6, name_width, 20), Color(0.12, 0.18, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(96, box_y + 21), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.95, 0.88))
	
	# Text with wrapping
	var full_text = current_dialogue.get("text", "")
	var shown_text = full_text.substr(0, char_index)
	var lines = wrap_text(shown_text, 42)
	var text_y = box_y + 45
	for line in lines:
		draw_string(ThemeDB.fallback_font, Vector2(92, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, 360, 14, Color.WHITE)
		text_y += 16
	
	if char_index >= full_text.length():
		draw_string(ThemeDB.fallback_font, Vector2(438, box_y + 78), "[X]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.45, 0.45, 0.45))

func draw_speaker_portrait(speaker: String, box_y: float):
	match speaker:
		"kaido":
			if tex_kaido_portrait:
				# Portrait version - fit in box maintaining aspect
				draw_texture_rect(tex_kaido_portrait, Rect2(22, box_y + 12, 56, 56), false)
			elif tex_kaido:
				# Use main sprite as portrait
				var pw = 36
				var ph = 58
				draw_texture_rect(tex_kaido, Rect2(32, box_y + 8, pw, ph), false)
		"grandmother":
			if tex_ninja_oldwoman:
				var src = Rect2(0, 0, 16, 16)
				draw_texture_rect_region(tex_ninja_oldwoman, Rect2(22, box_y + 12, 56, 56), src)
			elif tex_grandmother_portrait:
				draw_texture_rect(tex_grandmother_portrait, Rect2(22, box_y + 12, 56, 56), false)
		"system", "build":
			draw_rect(Rect2(30, box_y + 20, 40, 40), Color(0.25, 0.25, 0.35))
			draw_string(ThemeDB.fallback_font, Vector2(42, box_y + 50), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.9, 0.8, 0.3))
		"farmer_wen":
			if tex_farmer_wen_portrait:
				draw_texture_rect(tex_farmer_wen_portrait, Rect2(20, box_y + 10, 60, 60), false)
			else:
				draw_rect(Rect2(30, box_y + 20, 40, 40), Color(0.55, 0.45, 0.35))
				draw_circle(Vector2(50, box_y + 35), 12, Color(0.9, 0.8, 0.65))
				# Hat
				var hat_pts = PackedVector2Array([
					Vector2(38, box_y + 28),
					Vector2(50, box_y + 18),
					Vector2(62, box_y + 28)
				])
				draw_colored_polygon(hat_pts, Color(0.85, 0.78, 0.55))
		"kid":
			if tex_kid_milo_portrait:
				draw_texture_rect(tex_kid_milo_portrait, Rect2(20, box_y + 10, 60, 60), false)
			else:
				draw_rect(Rect2(35, box_y + 25, 30, 35), Color(0.5, 0.6, 0.7))
				draw_circle(Vector2(50, box_y + 22), 10, Color(0.9, 0.8, 0.7))
		"journal":
			# Grandfather's journal - old paper look
			draw_rect(Rect2(28, box_y + 16, 44, 48), Color(0.85, 0.8, 0.65))
			draw_rect(Rect2(30, box_y + 18, 40, 44), Color(0.9, 0.85, 0.7))
			# Lines on paper
			for i in range(4):
				draw_line(Vector2(33, box_y + 26 + i * 10), Vector2(67, box_y + 26 + i * 10), Color(0.6, 0.55, 0.5), 1)
			# Quill/pen mark
			draw_line(Vector2(60, box_y + 22), Vector2(65, box_y + 58), Color(0.3, 0.25, 0.2), 2)
		"robot":
			# Check for baker robot portrait
			if tex_baker_robot_portrait and current_dialogue_npc == "Baker Bot-7":
				draw_texture_rect(tex_baker_robot_portrait, Rect2(20, box_y + 10, 60, 60), false)
			else:
				# Enemy robot portrait
				draw_rect(Rect2(28, box_y + 18, 44, 44), Color(0.2, 0.1, 0.1))
				draw_rect(Rect2(30, box_y + 20, 40, 40), Color(0.35, 0.18, 0.18))
				# Visor
				draw_rect(Rect2(35, box_y + 28, 30, 8), Color(1.0, 0.25, 0.25))
				# Body
				draw_rect(Rect2(38, box_y + 40, 24, 18), Color(0.3, 0.15, 0.15))
		"relic":
			# Resistance relic - gear/artifact look
			draw_rect(Rect2(28, box_y + 18, 44, 44), Color(0.25, 0.22, 0.2))
			# Gear icon
			draw_circle(Vector2(50, box_y + 40), 16, Color(0.6, 0.5, 0.35))
			draw_circle(Vector2(50, box_y + 40), 10, Color(0.4, 0.35, 0.28))
			draw_circle(Vector2(50, box_y + 40), 4, Color(0.2, 0.18, 0.15))
			# Gear teeth
			for i in range(8):
				var angle = i * PI / 4
				var tx = 50 + cos(angle) * 18
				var ty = box_y + 40 + sin(angle) * 18
				draw_circle(Vector2(tx, ty), 3, Color(0.6, 0.5, 0.35))
			# Sparkle
			var sparkle = (sin(continuous_timer * 4) * 0.3 + 0.7)
			draw_circle(Vector2(58, box_y + 30), 3, Color(1, 0.9, 0.6, sparkle))
		"villager":
			# Check for Elder Sato portrait
			if tex_villager_elder_portrait and current_dialogue_npc == "Elder Sato":
				draw_texture_rect(tex_villager_elder_portrait, Rect2(20, box_y + 10, 60, 60), false)
			else:
				# Generic villager portrait
				draw_rect(Rect2(28, box_y + 18, 44, 44), Color(0.4, 0.5, 0.45))
				# Head
				draw_circle(Vector2(50, box_y + 32), 14, Color(0.95, 0.85, 0.75))
				# Body
				draw_rect(Rect2(38, box_y + 44, 24, 16), Color(0.5, 0.55, 0.6))
				# Eyes
				draw_circle(Vector2(45, box_y + 30), 2, Color(0.2, 0.2, 0.2))
				draw_circle(Vector2(55, box_y + 30), 2, Color(0.2, 0.2, 0.2))
				# Hair
				draw_rect(Rect2(40, box_y + 18, 20, 8), Color(0.35, 0.28, 0.22))

# ============================================
# SCHEMATIC POPUP
# ============================================


# ============================================
# PAUSE MENU - WORKBENCH STYLE
# ============================================

func handle_pause_menu_input(event):
	# Navigation
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		pause_menu_selection = max(0, pause_menu_selection - 1)
		haptic_light()
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		pause_menu_selection = min(pause_menu_options.size() - 1, pause_menu_selection + 1)
		haptic_light()
	
	# Selection
	var select_pressed = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		select_pressed = true
	
	if select_pressed:
		haptic_medium()
		match pause_menu_selection:
			0:  # Resume
				current_mode = pause_previous_mode
			1:  # Journal
				current_mode = GameMode.JOURNAL_VIEW
			2:  # Settings (placeholder for now)
				pass
			3:  # Quit
				get_tree().quit()

func draw_pause_menu():
	# Update Kaido bob animation
	pause_kaido_bob = sin(continuous_timer * 2.0) * 3.0
	
	# Dim overlay
	draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.6))
	
	# === WORKBENCH ===
	var bench_x = 20
	var bench_y = 80
	var bench_w = 340
	var bench_h = 180
	
	# Workbench surface (wood grain effect)
	var wood_base = Color(0.55, 0.38, 0.25)
	var wood_light = Color(0.65, 0.48, 0.32)
	var wood_dark = Color(0.42, 0.28, 0.18)
	
	# Main bench top
	draw_rect(Rect2(bench_x, bench_y, bench_w, bench_h), wood_base)
	
	# Wood grain lines
	for i in range(12):
		var grain_y = bench_y + 15 + i * 15
		var grain_color = wood_light if i % 2 == 0 else wood_dark
		draw_line(Vector2(bench_x, grain_y), Vector2(bench_x + bench_w, grain_y), Color(grain_color.r, grain_color.g, grain_color.b, 0.3), 1)
	
	# Bench edge (front)
	draw_rect(Rect2(bench_x, bench_y + bench_h, bench_w, 12), wood_dark)
	draw_rect(Rect2(bench_x, bench_y + bench_h, bench_w, 3), wood_light)
	
	# Bench legs
	draw_rect(Rect2(bench_x + 10, bench_y + bench_h + 12, 20, 30), wood_dark)
	draw_rect(Rect2(bench_x + bench_w - 30, bench_y + bench_h + 12, 20, 30), wood_dark)
	
	# === SCATTERED COMPONENTS ON BENCH ===
	draw_bench_components(bench_x, bench_y)
	
	# === KAIDO ON WORKBENCH ===
	var kaido_x = bench_x + bench_w - 50
	var kaido_y = bench_y + 40 + pause_kaido_bob
	draw_kaido_on_bench(kaido_x, kaido_y)
	
	# === MENU OPTIONS AS TOOLS ===
	var menu_x = bench_x + 30
	var menu_y = bench_y + 30
	
	for i in range(pause_menu_options.size()):
		var option = pause_menu_options[i]
		var item_y = menu_y + i * 38
		var is_selected = i == pause_menu_selection
		
		# Draw tool icon based on option
		draw_menu_tool(menu_x, item_y, i, is_selected)
		
		# Draw label
		var label_color = Color(1.0, 0.95, 0.85) if is_selected else Color(0.7, 0.6, 0.5)
		var label_size = 14 if is_selected else 12
		
		if is_selected:
			# Glowing selection indicator
			draw_rect(Rect2(menu_x + 40, item_y + 2, 100, 22), Color(0.3, 0.7, 0.6, 0.3))
			draw_rect(Rect2(menu_x + 40, item_y + 2, 100, 22), Color(0.4, 0.9, 0.8), false, 2)
		
		draw_string(ThemeDB.fallback_font, Vector2(menu_x + 45, item_y + 18), option, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_color)
	
	# === TITLE ===
	draw_rect(Rect2(100, 35, 160, 30), Color(0.2, 0.15, 0.1, 0.9))
	draw_rect(Rect2(100, 35, 160, 30), Color(0.5, 0.4, 0.3), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(125, 57), "- PAUSED -", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.85, 0.7))
	
	# === BUTTON HINTS ===
	draw_string(ThemeDB.fallback_font, Vector2(90, 300), "[X] Select    [O] Resume    [START] Resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.55, 0.5))

func draw_bench_components(bench_x: float, bench_y: float):
	# Scattered LEDs
	draw_circle(Vector2(bench_x + 180, bench_y + 60), 4, Color(1.0, 0.2, 0.2))
	draw_circle(Vector2(bench_x + 180, bench_y + 60), 2, Color(1.0, 0.5, 0.5))
	draw_circle(Vector2(bench_x + 200, bench_y + 55), 4, Color(0.2, 1.0, 0.2))
	draw_circle(Vector2(bench_x + 200, bench_y + 55), 2, Color(0.5, 1.0, 0.5))
	draw_circle(Vector2(bench_x + 220, bench_y + 62), 4, Color(1.0, 1.0, 0.2))
	
	# Resistors
	draw_rect(Rect2(bench_x + 240, bench_y + 90, 20, 6), Color(0.7, 0.55, 0.4))
	draw_rect(Rect2(bench_x + 243, bench_y + 90, 3, 6), Color(0.9, 0.3, 0.1))
	draw_rect(Rect2(bench_x + 248, bench_y + 90, 3, 6), Color(0.9, 0.3, 0.1))
	draw_rect(Rect2(bench_x + 253, bench_y + 90, 3, 6), Color(0.4, 0.25, 0.1))
	
	draw_rect(Rect2(bench_x + 170, bench_y + 120, 18, 5), Color(0.7, 0.55, 0.4))
	
	# Jumper wires (coiled)
	draw_line(Vector2(bench_x + 250, bench_y + 110), Vector2(bench_x + 270, bench_y + 115), Color(0.9, 0.2, 0.2), 2)
	draw_line(Vector2(bench_x + 270, bench_y + 115), Vector2(bench_x + 265, bench_y + 125), Color(0.9, 0.2, 0.2), 2)
	draw_line(Vector2(bench_x + 200, bench_y + 130), Vector2(bench_x + 220, bench_y + 135), Color(0.1, 0.1, 0.1), 2)
	draw_line(Vector2(bench_x + 220, bench_y + 135), Vector2(bench_x + 210, bench_y + 145), Color(0.1, 0.1, 0.1), 2)
	
	# Small breadboard piece
	draw_rect(Rect2(bench_x + 240, bench_y + 140, 50, 30), Color(0.95, 0.95, 0.9))
	draw_rect(Rect2(bench_x + 240, bench_y + 140, 50, 30), Color(0.7, 0.65, 0.6), false, 1)
	for row in range(3):
		for col in range(5):
			draw_circle(Vector2(bench_x + 248 + col * 9, bench_y + 148 + row * 9), 1.5, Color(0.3, 0.3, 0.35))

func draw_menu_tool(x: float, y: float, tool_idx: int, is_selected: bool):
	var glow = 0.3 if is_selected else 0.0
	var bob = sin(continuous_timer * 3.0 + tool_idx) * 2.0 if is_selected else 0.0
	
	match tool_idx:
		0:  # Resume - Soldering iron
			var tip_glow = sin(continuous_timer * 4.0) * 0.3 + 0.7 if is_selected else 0.3
			# Handle
			draw_rect(Rect2(x + bob, y + 5, 25, 8), Color(0.3, 0.3, 0.35))
			draw_rect(Rect2(x + bob, y + 6, 25, 6), Color(0.4, 0.4, 0.45))
			# Shaft
			draw_rect(Rect2(x + 25 + bob, y + 8, 12, 4), Color(0.7, 0.7, 0.75))
			# Tip (glowing when selected)
			draw_rect(Rect2(x + 35 + bob, y + 9, 6, 2), Color(1.0, 0.5 + tip_glow * 0.3, 0.2, 0.8 + tip_glow * 0.2))
			if is_selected:
				draw_circle(Vector2(x + 40 + bob, y + 10), 4, Color(1.0, 0.6, 0.2, 0.3))
		
		1:  # Journal - Notebook
			# Cover
			draw_rect(Rect2(x + 2 + bob, y + 2, 28, 20), Color(0.6, 0.45, 0.3))
			draw_rect(Rect2(x + 4 + bob, y + 4, 24, 16), Color(0.7, 0.55, 0.4))
			# Spine
			draw_rect(Rect2(x + 2 + bob, y + 2, 4, 20), Color(0.5, 0.35, 0.25))
			# Pages
			draw_rect(Rect2(x + 6 + bob, y + 4, 22, 2), Color(0.95, 0.92, 0.85))
			draw_rect(Rect2(x + 6 + bob, y + 18, 22, 2), Color(0.95, 0.92, 0.85))
			# Bookmark
			if is_selected:
				draw_rect(Rect2(x + 26 + bob, y, 3, 8), Color(0.9, 0.3, 0.3))
		
		2:  # Settings - Multimeter
			# Body
			draw_rect(Rect2(x + 4 + bob, y + 2, 24, 20), Color(0.2, 0.2, 0.25))
			draw_rect(Rect2(x + 6 + bob, y + 4, 20, 10), Color(0.15, 0.4, 0.15))  # Screen
			# Display text
			if is_selected:
				draw_string(ThemeDB.fallback_font, Vector2(x + 8 + bob, y + 12), "5.0V", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.3, 1.0, 0.3))
			# Dial
			draw_circle(Vector2(x + 16 + bob, y + 18), 4, Color(0.5, 0.5, 0.55))
			draw_circle(Vector2(x + 16 + bob, y + 18), 2, Color(0.3, 0.3, 0.35))
		
		3:  # Quit - Door/Exit
			# Door frame
			draw_rect(Rect2(x + 6 + bob, y + 2, 22, 20), Color(0.5, 0.38, 0.28))
			draw_rect(Rect2(x + 8 + bob, y + 4, 18, 16), Color(0.6, 0.45, 0.35))
			# Door handle
			draw_circle(Vector2(x + 22 + bob, y + 12), 2, Color(0.8, 0.7, 0.3))
			# Arrow out
			if is_selected:
				draw_line(Vector2(x + 30 + bob, y + 12), Vector2(x + 38 + bob, y + 12), Color(1.0, 0.5, 0.3), 2)
				draw_line(Vector2(x + 35 + bob, y + 8), Vector2(x + 38 + bob, y + 12), Color(1.0, 0.5, 0.3), 2)
				draw_line(Vector2(x + 35 + bob, y + 16), Vector2(x + 38 + bob, y + 12), Color(1.0, 0.5, 0.3), 2)

func draw_kaido_on_bench(x: float, y: float):
	# Shadow on bench
	draw_ellipse_shape(Vector2(x, y + 45), Vector2(20, 6), Color(0, 0, 0, 0.2))

	if tex_kaido:
		var tex_w = tex_kaido.get_width()
		var tex_h = tex_kaido.get_height()
		var target_h = 70.0
		var scale = target_h / tex_h
		var final_w = tex_w * scale
		var final_h = tex_h * scale
		var dest = Rect2(x - final_w / 2, y - final_h / 2, final_w, final_h)
		draw_texture_rect(tex_kaido, dest, false)
	
	# Speech bubble with circuit tip
	var bubble_w = 145
	var bubble_h = 38
	var bubble_x = x - 20
	var bubble_y = y - 70
	
	draw_rect(Rect2(bubble_x, bubble_y, bubble_w, bubble_h), Color(1, 1, 1, 0.95))
	draw_rect(Rect2(bubble_x, bubble_y, bubble_w, bubble_h), Color(0.3, 0.3, 0.35), false, 2)
	draw_polygon(PackedVector2Array([
		Vector2(bubble_x + 15, bubble_y + bubble_h),
		Vector2(bubble_x + 25, bubble_y + bubble_h),
		Vector2(x, y - 35)
	]), PackedColorArray([Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95)]))
	
	var tips = [
		"LED long leg goes|to positive (+)!",
		"Resistors protect LEDs|from burning out!",
		"Always check your|connections twice!",
		"Current flows from|positive to negative.",
		"Match color bands to|find resistor values!"
	]
	var tip_idx = int(fmod(continuous_timer * 0.25, tips.size()))
	var tip_lines = tips[tip_idx].split("|")
	var line_y = bubble_y + 13
	for line in tip_lines:
		draw_string(ThemeDB.fallback_font, Vector2(bubble_x + 8, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.2, 0.2, 0.25))
		line_y += 14

func draw_schematic_popup():
	ui_draw.draw_schematic_popup()

func draw_breadboard_schematic(x: float, y: float, circuit: String):
	var tex: Texture2D = null
	match circuit:
		"led_lamp", "led_basic": tex = tex_schematic_led_basic
		"buzzer_alarm", "buzzer_button": tex = tex_schematic_buzzer_button
		"dimmer": tex = tex_schematic_dimmer
		"light_sensor": tex = tex_schematic_light_sensor
		"led_chain", "series_leds": tex = tex_schematic_series_leds
	
	if tex:
		var tex_size = tex.get_size()
		var scale_factor = min(220.0 / tex_size.x, 165.0 / tex_size.y)
		var w = tex_size.x * scale_factor
		var h = tex_size.y * scale_factor
		draw_texture_rect(tex, Rect2(x, y, w, h), false)
	else:
		# Fallback: draw procedural schematic
		draw_procedural_schematic(x, y, circuit)

func draw_procedural_schematic(x: float, y: float, circuit: String):
	# Breadboard background
	draw_rect(Rect2(x, y, 200, 130), Color(0.9, 0.9, 0.88))
	draw_rect(Rect2(x, y, 200, 130), Color(0.5, 0.45, 0.4), false, 2)
	
	# Power rails
	draw_line(Vector2(x + 10, y + 15), Vector2(x + 190, y + 15), Color(0.8, 0.2, 0.2), 2)
	draw_line(Vector2(x + 10, y + 115), Vector2(x + 190, y + 115), Color(0.2, 0.2, 0.2), 2)
	
	match circuit:
		"led_lamp", "led_basic":
			# LED
			draw_circle(Vector2(x + 100, y + 50), 12, Color(1.0, 0.3, 0.2))
			draw_circle(Vector2(x + 100, y + 50), 6, Color(1.0, 0.6, 0.5))
			# Resistor
			draw_rect(Rect2(x + 70, y + 75, 30, 10), Color(0.7, 0.55, 0.4))
			draw_rect(Rect2(x + 75, y + 75, 5, 10), Color(0.6, 0.3, 0.1))
			draw_rect(Rect2(x + 82, y + 75, 5, 10), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(x + 89, y + 75, 5, 10), Color(1.0, 0.5, 0.0))
			# Wires
			draw_line(Vector2(x + 100, y + 15), Vector2(x + 100, y + 38), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 100, y + 62), Vector2(x + 100, y + 75), Color(0.2, 0.2, 0.2), 2)
			draw_line(Vector2(x + 85, y + 85), Vector2(x + 85, y + 115), Color(0.2, 0.2, 0.2), 2)
		
		"buzzer_alarm", "buzzer_button":
			# Button
			draw_rect(Rect2(x + 55, y + 40, 20, 15), Color(0.3, 0.3, 0.35))
			draw_circle(Vector2(x + 65, y + 47), 5, Color(0.2, 0.2, 0.25))
			# Buzzer
			draw_circle(Vector2(x + 120, y + 70), 20, Color(0.15, 0.15, 0.18))
			draw_circle(Vector2(x + 120, y + 70), 8, Color(0.7, 0.65, 0.4))
			# Resistor
			draw_rect(Rect2(x + 50, y + 80, 25, 8), Color(0.7, 0.55, 0.4))
			# Wires
			draw_line(Vector2(x + 65, y + 15), Vector2(x + 65, y + 40), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 120, y + 90), Vector2(x + 120, y + 115), Color(0.2, 0.2, 0.2), 2)
		
		"dimmer":
			# Potentiometer (big dial)
			draw_circle(Vector2(x + 80, y + 65), 25, Color(0.3, 0.5, 0.7))
			draw_circle(Vector2(x + 80, y + 65), 20, Color(0.4, 0.6, 0.8))
			draw_line(Vector2(x + 80, y + 65), Vector2(x + 90, y + 55), Color(0.2, 0.2, 0.25), 3)
			# LED
			draw_circle(Vector2(x + 145, y + 55), 10, Color(0.2, 0.4, 0.7))
			draw_circle(Vector2(x + 145, y + 55), 5, Color(0.4, 0.6, 0.9))
			# Resistor
			draw_rect(Rect2(x + 130, y + 75, 25, 8), Color(0.7, 0.55, 0.4))
			# Wires
			draw_line(Vector2(x + 80, y + 15), Vector2(x + 80, y + 40), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 105, y + 65), Vector2(x + 135, y + 65), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 145, y + 83), Vector2(x + 145, y + 115), Color(0.2, 0.2, 0.2), 2)
		
		"light_sensor":
			# Photoresistor (LDR)
			draw_circle(Vector2(x + 70, y + 55), 15, Color(0.85, 0.75, 0.4))
			draw_circle(Vector2(x + 70, y + 55), 10, Color(0.7, 0.6, 0.3))
			draw_line(Vector2(x + 65, y + 52), Vector2(x + 75, y + 58), Color(0.5, 0.4, 0.2), 2)
			# LED
			draw_circle(Vector2(x + 140, y + 55), 10, Color(0.2, 0.4, 0.7))
			# Resistor
			draw_rect(Rect2(x + 100, y + 75, 25, 8), Color(0.7, 0.55, 0.4))
			# Wires
			draw_line(Vector2(x + 70, y + 15), Vector2(x + 70, y + 40), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 85, y + 55), Vector2(x + 130, y + 55), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 140, y + 65), Vector2(x + 140, y + 115), Color(0.2, 0.2, 0.2), 2)
		
		"led_chain", "series_leds":
			# Three LEDs in series
			draw_circle(Vector2(x + 50, y + 55), 10, Color(1.0, 0.3, 0.3))
			draw_circle(Vector2(x + 50, y + 55), 5, Color(1.0, 0.6, 0.6))
			draw_circle(Vector2(x + 100, y + 55), 10, Color(1.0, 1.0, 0.3))
			draw_circle(Vector2(x + 100, y + 55), 5, Color(1.0, 1.0, 0.6))
			draw_circle(Vector2(x + 150, y + 55), 10, Color(0.3, 1.0, 0.3))
			draw_circle(Vector2(x + 150, y + 55), 5, Color(0.6, 1.0, 0.6))
			# Connecting wires
			draw_line(Vector2(x + 60, y + 55), Vector2(x + 90, y + 55), Color(0.3, 0.3, 0.3), 2)
			draw_line(Vector2(x + 110, y + 55), Vector2(x + 140, y + 55), Color(0.3, 0.3, 0.3), 2)
			# Resistor
			draw_rect(Rect2(x + 80, y + 80, 25, 8), Color(0.7, 0.55, 0.4))
			# Wires to rails
			draw_line(Vector2(x + 50, y + 15), Vector2(x + 50, y + 45), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 150, y + 65), Vector2(x + 150, y + 115), Color(0.2, 0.2, 0.2), 2)
		
		_:
			# Unknown circuit - just show placeholder
			draw_string(ThemeDB.fallback_font, Vector2(x + 50, y + 70), "SCHEMATIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.4, 0.4))

func draw_backpack_popup():
	ui_draw.draw_backpack_popup()

func draw_backpack_gadgets_tab(popup_y: float, alpha: float):
	# Gadget slots
	var slot_start_x = 90
	var slot_start_y = popup_y + 45
	var slot_size = 45
	var cols = 3
	
	for i in range(6):
		var sx = slot_start_x + (i % cols) * (slot_size + 12)
		var sy = slot_start_y + (i / cols) * (slot_size + 12)
		
		var slot_color = Color(0.25, 0.22, 0.2, alpha)
		var is_selected = (i == backpack_selected and i < gadgets.size())
		
		if i < gadgets.size():
			slot_color = Color(0.35, 0.32, 0.28, alpha)
		
		draw_rect(Rect2(sx, sy, slot_size, slot_size), slot_color)
		
		# Selection highlight
		if is_selected:
			var pulse = (sin(continuous_timer * 4) * 0.2 + 0.8)
			draw_rect(Rect2(sx - 3, sy - 3, slot_size + 6, slot_size + 6), Color(0.3, 0.8, 0.7, pulse * alpha), false, 3)
		else:
			draw_rect(Rect2(sx, sy, slot_size, slot_size), Color(0.5, 0.45, 0.4, alpha), false, 2)
		
		if i < gadgets.size():
			draw_gadget_icon(sx, sy, slot_size, gadgets[i], alpha)
	
	# Selected gadget info panel on the right
	var info_x = 270
	var info_y = popup_y + 45
	draw_rect(Rect2(info_x, info_y, 130, 125), Color(0.2, 0.18, 0.16, alpha))
	draw_rect(Rect2(info_x, info_y, 130, 125), Color(0.4, 0.35, 0.3, alpha), false, 2)
	
	if gadgets.size() == 0:
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 30), "No gadgets", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.6, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 50), "Build circuits", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.7, 0.65, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 62), "to get gadgets!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.7, 0.65, alpha))
	elif gadgets.size() > 0 and backpack_selected < gadgets.size():
		var gadget_id = gadgets[backpack_selected]
		var data = gadget_data.get(gadget_id, {})
		
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, info_y + 18), data.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.8, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, info_y + 34), data.get("desc", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, alpha))
		
		var adventure_text = data.get("adventure_use", "")
		var wrapped = wrap_text(adventure_text, 18)
		var ty = info_y + 52
		draw_rect(Rect2(info_x + 4, info_y + 42, 122, 78), Color(0.15, 0.25, 0.2, alpha * 0.5))
		for line in wrapped:
			draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, ty), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.85, 0.75, alpha))
			ty += 11
			if ty > info_y + 118:
				break
	
	# New gadget highlight
	if pending_gadget != "" and pending_gadget in gadgets:
		var idx = gadgets.find(pending_gadget)
		var sx = slot_start_x + (idx % cols) * (slot_size + 12)
		var sy = slot_start_y + (idx / cols) * (slot_size + 12)
		draw_string(ThemeDB.fallback_font, Vector2(sx + 8, sy + slot_size + 12), "NEW!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.9, 0.3, alpha))

func draw_backpack_loot_tab(popup_y: float, alpha: float):
	# Loot item slots
	var slot_start_x = 90
	var slot_start_y = popup_y + 45
	var slot_size = 45
	var cols = 3
	
	for i in range(6):
		var sx = slot_start_x + (i % cols) * (slot_size + 12)
		var sy = slot_start_y + (i / cols) * (slot_size + 12)
		
		var slot_color = Color(0.25, 0.22, 0.2, alpha)
		var is_selected = (i == loot_selected and i < loot_items.size())
		
		if i < loot_items.size():
			slot_color = Color(0.35, 0.32, 0.28, alpha)
		
		draw_rect(Rect2(sx, sy, slot_size, slot_size), slot_color)
		
		if is_selected:
			var pulse = (sin(continuous_timer * 4) * 0.2 + 0.8)
			draw_rect(Rect2(sx - 3, sy - 3, slot_size + 6, slot_size + 6), Color(0.8, 0.7, 0.3, pulse * alpha), false, 3)
		else:
			draw_rect(Rect2(sx, sy, slot_size, slot_size), Color(0.5, 0.45, 0.4, alpha), false, 2)
		
		if i < loot_items.size():
			draw_loot_icon(sx, sy, slot_size, loot_items[i], alpha)
	
	# Selected loot info panel
	var info_x = 270
	var info_y = popup_y + 45
	draw_rect(Rect2(info_x, info_y, 130, 125), Color(0.2, 0.18, 0.16, alpha))
	draw_rect(Rect2(info_x, info_y, 130, 125), Color(0.4, 0.35, 0.3, alpha), false, 2)
	
	if loot_items.size() == 0:
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 30), "No loot", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.6, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 50), "Explore to", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.5, 0.4, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 10, info_y + 62), "find items!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.5, 0.4, alpha))
	elif loot_items.size() > 0 and loot_selected < loot_items.size():
		var item = loot_items[loot_selected]
		var loot_info = get_loot_info(item)
		
		draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, info_y + 18), loot_info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.8, alpha))
		
		var wrapped = wrap_text(loot_info.desc, 18)
		var ty = info_y + 38
		for line in wrapped:
			draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, ty), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, alpha))
			ty += 12
			if ty > info_y + 80:
				break
		
		# Action hint
		if item == "journal":
			draw_rect(Rect2(info_x + 4, info_y + 85, 122, 35), Color(0.2, 0.25, 0.15, alpha * 0.5))
			draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, info_y + 100), "[X] Read Journal", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.85, 0.5, alpha))
			draw_string(ThemeDB.fallback_font, Vector2(info_x + 8, info_y + 115), str(journal_pages_found.size()) + "/5 pages", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.5, alpha))

func get_loot_info(item: String) -> Dictionary:
	match item:
		"journal":
			return {
				"name": "Grandfather's Journal",
				"desc": "Torn pages from CARACTACUS's journal. Contains memories of the resistance."
			}
		_:
			return {"name": item, "desc": "Unknown item."}

func draw_loot_icon(sx: float, sy: float, size: float, item: String, alpha: float):
	ui_draw.draw_loot_icon(sx, sy, size, item, alpha)

func draw_gadget_icon(sx: float, sy: float, size: float, gadget_id: String, alpha: float):
	ui_draw.draw_gadget_icon(sx, sy, size, gadget_id, alpha)

func draw_journal_view():
	# Full-screen journal with all pages scrollable
	draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.9))
	
	# Journal background - old paper look
	draw_rect(Rect2(30, 15, 420, 290), Color(0.0, 0.0, 0.0))
	draw_rect(Rect2(32, 17, 416, 286), Color(0.85, 0.8, 0.7))
	
	# Clip area for scrolling content
	var content_top = 60
	var content_bottom = 280
	var content_height = content_bottom - content_top
	
	# Title (fixed, doesn't scroll)
	draw_rect(Rect2(32, 17, 416, 40), Color(0.82, 0.77, 0.67))
	draw_string(ThemeDB.fallback_font, Vector2(120, 42), "GRANDFATHER'S JOURNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.3, 0.25, 0.2))
	draw_line(Vector2(120, 48), Vector2(360, 48), Color(0.4, 0.35, 0.3), 2)
	
	if journal_pages_found.size() == 0:
		draw_string(ThemeDB.fallback_font, Vector2(150, 150), "No pages found yet...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.45, 0.4))
	else:
		# Build all content
		var page_order = ["shed", "pond", "tree", "radiotower", "buried"]
		var page_content = get_journal_page_content()
		
		# Calculate total content height needed
		var total_height = 0
		var entries = []
		for page_name in page_order:
			if page_name in journal_pages_found:
				var page = page_content.get(page_name, {"title": "???", "text": "..."})
				entries.append(page)
				total_height += 80  # Space for each entry
		
		# Clamp scroll
		var max_scroll = max(0, total_height - content_height + 40)
		journal_scroll = clamp(journal_scroll, 0, max_scroll)
		
		# Draw entries with scroll offset
		var y_pos = content_top - journal_scroll
		var entry_num = 1
		
		for page in entries:
			# Only draw if visible
			if y_pos > content_top - 80 and y_pos < content_bottom + 20:
				# Entry separator line
				if entry_num > 1:
					draw_line(Vector2(60, y_pos - 5), Vector2(420, y_pos - 5), Color(0.7, 0.65, 0.55, 0.5), 1)
				
				# Entry title
				draw_string(ThemeDB.fallback_font, Vector2(50, y_pos + 15), page.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.35, 0.3, 0.25))
				
				# Entry text
				var wrapped = wrap_text(page.text, 48)
				var text_y = y_pos + 35
				for line in wrapped:
					if text_y > content_top - 20 and text_y < content_bottom + 10:
						draw_string(ThemeDB.fallback_font, Vector2(50, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.25, 0.2, 0.18))
					text_y += 18
			
			y_pos += 80
			entry_num += 1
		
		# Signature at end
		var sig_y = content_top - journal_scroll + total_height + 10
		if sig_y > content_top and sig_y < content_bottom:
			draw_string(ThemeDB.fallback_font, Vector2(280, sig_y), "Ã¢â‚¬â€ CARACTACUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.35, 0.3))
		
		# Scroll indicator
		if max_scroll > 0:
			var scroll_pct = journal_scroll / max_scroll
			var bar_height = 200
			var bar_y = 65 + scroll_pct * (bar_height - 40)
			draw_rect(Rect2(432, 65, 8, bar_height), Color(0.7, 0.65, 0.55, 0.3))
			draw_rect(Rect2(432, bar_y, 8, 40), Color(0.5, 0.45, 0.35, 0.8))
		
		# Page count
		draw_string(ThemeDB.fallback_font, Vector2(380, 42), str(journal_pages_found.size()) + "/5", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.45, 0.4))
	
	# Controls bar (fixed at bottom)
	draw_rect(Rect2(32, 285, 416, 18), Color(0.75, 0.7, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(180, 298), "^v Scroll    [O]/[X] Close", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.35, 0.3))

# ============================================
# SHED INTERIOR
# ============================================

func draw_shed_interior():
	interior_sc.draw_shed_interior()

func draw_shed_objects(light_pos: Vector2):
	interior_sc.draw_shed_objects(light_pos)

# ============================================
# PHOTOGRAPH REVEAL
# ============================================

func draw_photograph_reveal():
	interior_sc.draw_photograph_reveal()

# ============================================
# RADIOTOWER VIEW
# ============================================

func draw_radiotower_view():
	interior_sc.draw_radiotower_view()

# ============================================
# ENDING CUTSCENE
# ============================================

func draw_ending_cutscene():
	interior_sc.draw_ending_cutscene()

# ============================================
# COMBAT DRAWING
# ============================================

func draw_combat_arena():
	combat_sys.draw_combat_arena()

func draw_combat_gadget_indicator():
	combat_sys.draw_combat_gadget_indicator()

func draw_combat_player(pos: Vector2):
	combat_sys.draw_combat_player(pos)

func draw_combat_robot(pos: Vector2):
	combat_sys.draw_combat_robot(pos)

func draw_robot_telegraph_effects(pos: Vector2, body_color: Color, accent: Color, outline: Color):
	pass  # Removed - using sprites

func draw_robot_attack_effects(pos: Vector2):
	combat_sys.draw_robot_attack_effects(pos)

func draw_tunnel_robot(robot: Dictionary, shake_offset: Vector2, index: int):
	combat_sys.draw_tunnel_robot(robot, shake_offset, index)

func draw_robot_body(pos: Vector2, body_color: Color, accent: Color, outline: Color):
	pass  # Removed - using sprites

func draw_defeated_robot(pos: Vector2):
	combat_sys.draw_defeated_robot(pos)

func draw_combat_health_bar(pos: Vector2, current_hp: int, max_hp: int, color: Color, label: String):
	combat_sys.draw_combat_health_bar(pos, current_hp, max_hp, color, label)

func draw_stamina_bar(pos: Vector2):
	ui_draw.draw_stamina_bar(pos)

# ============================================
# REGION COMPLETE
# ============================================

func draw_region_complete():
	interior_sc.draw_region_complete()

func draw_shop_interior():
	interior_sc.draw_shop_interior()

func draw_townhall_interior():
	interior_sc.draw_townhall_interior()

func draw_bakery_interior():
	interior_sc.draw_bakery_interior()

func draw_robot_npc(x: float, y: float, type: String):
	# Use custom sprites if available
	if type == "baker" and tex_baker_robot:
		var w = tex_baker_robot.get_width()
		var h = tex_baker_robot.get_height()
		var dest = Rect2(x - w/2, y - h + 8, w, h)
		draw_texture_rect(tex_baker_robot, dest, false)
		return
	
	if type == "shop" and tex_shop_robot:
		var w = tex_shop_robot.get_width()
		var h = tex_shop_robot.get_height()
		var dest = Rect2(x - w/2, y - h + 8, w, h)
		draw_texture_rect(tex_shop_robot, dest, false)
		return
	
	# Fallback to inspector/monk sprite for robots
	var tex = tex_ninja_inspector if type == "shop" else tex_ninja_monk
	if tex:
		var src = Rect2(0, 0, 16, 16)
		var dest = Rect2(x - 16, y - 8, 32, 32)
		draw_texture_rect_region(tex, dest, src)

func draw_mayor_npc(x: float, y: float):
	# Use oldman sprite for mayor
	if tex_ninja_oldman:
		var src = Rect2(0, 0, 16, 16)
		var dest = Rect2(x - 16, y - 16, 32, 32)
		draw_texture_rect_region(tex_ninja_oldman, dest, src)

func draw_interior_player(pos: Vector2):
	# Use new animation system if available
	if player_anim_loaded:
		var tex: Texture2D = null
		var frame = player_frame % 6
		
		if is_walking:
			match player_facing:
				"down":
					if tex_player_walk_south.size() > frame:
						tex = tex_player_walk_south[frame]
				"up":
					if tex_player_walk_north.size() > frame:
						tex = tex_player_walk_north[frame]
				"left":
					if tex_player_walk_west.size() > frame:
						tex = tex_player_walk_west[frame]
				"right":
					if tex_player_walk_east.size() > frame:
						tex = tex_player_walk_east[frame]
		else:
			match player_facing:
				"down": tex = tex_player_idle_south
				"up": tex = tex_player_idle_north
				"left": tex = tex_player_idle_west
				"right": tex = tex_player_idle_east
		
		if not tex and tex_player_idle_south:
			tex = tex_player_idle_south
		
		if tex:
			var w = tex.get_width()
			var h = tex.get_height()
			var dest = Rect2(pos.x - w/2, pos.y - h + 4, w, h)
			draw_texture_rect(tex, dest, false)
			return
	
	# Fallback
	if not tex_player:
		return
	var src = Rect2(0, 0, 48, 48)
	var dest = Rect2(pos.x - 24, pos.y - 40, 48, 48)
	draw_texture_rect_region(tex_player, dest, src)
