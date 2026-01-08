extends Node2D

# ============================================
# KAIDOTRAINER - AGRICOMMUNE v2
# Full v1.1 - v1.4 Story + Enhanced Features
# ============================================

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

# ============================================
# PROCEDURAL 8-BIT AUDIO SYSTEM
# ============================================
var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer  # For sound effects
var audio_generator: AudioStreamGenerator
var audio_playback: AudioStreamGeneratorPlayback

# Music state
var music_enabled: bool = true
var current_track: String = ""  # "farm", "combat", "none"
var music_time: float = 0.0
var note_timer: float = 0.0
var current_note_index: int = 0
var music_tempo: float = 0.4  # Seconds per note

# Note frequencies (Hz) - C4 to B5
const NOTE_FREQS = {
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
	"G4": 392.00, "A4": 440.00, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46,
	"G5": 783.99, "A5": 880.00, "B5": 987.77,
	"R": 0.0  # Rest
}

# Farm theme - peaceful, pastoral Stardew-like melody
var farm_melody: Array = [
	"G4", "R", "E4", "R", "G4", "A4", "G4", "R",
	"E4", "R", "D4", "E4", "G4", "R", "E4", "R",
	"C4", "R", "E4", "R", "G4", "R", "A4", "R",
	"G4", "E4", "D4", "R", "C4", "R", "R", "R",
	"A4", "R", "G4", "R", "E4", "R", "G4", "R",
	"A4", "R", "C5", "R", "A4", "G4", "E4", "R",
	"D4", "R", "E4", "R", "G4", "R", "E4", "R",
	"C4", "R", "R", "R", "R", "R", "R", "R",
]

# Combat theme - intense SMB-inspired
var combat_melody: Array = [
	"E4", "E4", "R", "E4", "R", "C4", "E4", "R",
	"G4", "R", "R", "R", "G4", "R", "R", "R",
	"C4", "R", "R", "G4", "R", "R", "E4", "R",
	"R", "A4", "R", "B4", "R", "A4", "G4", "R",
	"E5", "R", "G4", "A4", "R", "A4", "G4", "R",
	"E4", "R", "R", "C4", "D4", "R", "B4", "R",
	"R", "R", "C5", "R", "R", "R", "G4", "R",
	"R", "R", "E4", "R", "R", "R", "R", "R",
]

# Tower climbing theme - adventurous
var tower_melody: Array = [
	"C4", "E4", "G4", "R", "C4", "E4", "G4", "R",
	"D4", "F4", "A4", "R", "D4", "F4", "A4", "R",
	"E4", "G4", "B4", "R", "E4", "G4", "C5", "R",
	"G4", "B4", "D5", "R", "C5", "R", "R", "R",
]

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
	{"pos": Vector2(100, 200), "name": "Fisher Bo", "dialogue": "The fish aren't biting today. Bad omen."},
	{"pos": Vector2(380, 150), "name": "Old Mira", "dialogue": "I've seen patrol boats on the lake at night."},
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
var stampede_player_hp: int = 3
var stampede_player_max_hp: int = 3
var stampede_player_state: String = "idle"  # idle, attacking, jumping, hit
var stampede_player_state_timer: float = 0.0
var stampede_player_facing_right: bool = true
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
	# Shed: drawn at (375, 175), body at (x, y+15, 52, 35)
	Rect2(375, 190, 52, 35),    # Shed body
	# Radiotower: drawn at (30, 20), legs at (x+5, y+30, 8, 60) and (x+37, y+30, 8, 60)
	Rect2(35, 50, 8, 60),       # Radiotower left leg
	Rect2(67, 50, 8, 60),       # Radiotower right leg
	# Pond: drawn at (385, 55), ellipse center (415, 80), radii 42x32
	Rect2(373, 48, 84, 64),     # Pond water area
	# Chicken coop: drawn at (180, 90), body at (x, y+10, 40, 30)
	Rect2(180, 100, 40, 30),    # Chicken coop body
	# Tunnel entrance: drawn at (tunnel_pos.x - 20, tunnel_pos.y - 30) = (400, 250)
	# Main structure is 50x45, plus sign post to the left
	Rect2(400, 250, 50, 45),    # Tunnel entrance archway
	Rect2(355, 255, 40, 42),    # Tunnel sign post area
	# Fence: drawn at (30, 275), 6 segments of 22px each
	Rect2(30, 275, 132, 20),    # Fence collision
	# Irrigation system: control panel at (70, 210, 35, 30), pipes extending right
	Rect2(70, 210, 35, 30),     # Irrigation control panel
	Rect2(105, 220, 42, 10),    # Horizontal pipe (thicker collision)
	Rect2(140, 220, 12, 55),    # Vertical pipe (thicker collision)
	# Crops area - drawn at (160, 220), 3x2 grid
	Rect2(158, 218, 70, 55),    # Crops area collision
	# Trees - trunk collision only (matched to actual trunk rects)
	# Large trees: trunk at (x+12, y+35, 16, 25)
	Rect2(17, 135, 16, 25),     # Large tree at (5, 100)
	Rect2(107, 45, 16, 25),     # Large tree at (95, 10)
	Rect2(432, 40, 16, 25),     # Large tree at (420, 5)
	Rect2(442, 255, 16, 25),    # Large tree at (430, 220)
	# Medium trees: trunk at (x+6, y+28, 12, 16)
	Rect2(66, 228, 12, 16),     # Medium tree at (60, 200)
	Rect2(356, 278, 12, 16),    # Medium tree at (350, 250)
]

# Flashlight in shed
var flashlight_pos: Vector2 = Vector2(240, 200)
var flashlight_speed: float = 80.0

# NPCs and locations
var grandmother_pos: Vector2 = Vector2(340, 120)
var grandmother_target: Vector2 = Vector2(340, 120)
var kaido_pos: Vector2 = Vector2(220, 165)  # Kaido starts behind player (240-20, 180-15)
var kaido_trail_history: Array = []  # Player position history for Kaido to follow
var kaido_trail_delay: int = 45  # How many frames behind Kaido follows
var kaido_speed: float = 100.0  # Kaido's movement speed
var shed_pos: Vector2 = Vector2(400, 200)
var radiotower_pos: Vector2 = Vector2(55, 105)  # Base of tower where player climbs
var irrigation_pos: Vector2 = Vector2(100, 220)
var tunnel_pos: Vector2 = Vector2(420, 280)

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
	Vector2(200, 180),   # Behind big tree
	Vector2(95, 220),    # Behind irrigation
	Vector2(400, 200),   # At the shed (where you build circuits)
	Vector2(375, 210),   # Behind shed
	Vector2(310, 85),    # Behind house
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
var chicken_coop_pos: Vector2 = Vector2(180, 90)
var chicken_coop_interact_pos: Vector2 = Vector2(215, 125)  # Near door/chickens
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
var char_index: int = 0
var text_timer: float = 0.0
var text_speed: float = 0.025

# Quest tracking
var quest_stage: int = 0
var circuits_built: int = 0
var current_quest: String = ""
var quest_anim_timer: float = 0.0
var quest_is_new: bool = false

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
	"not_gate": {
		"name": "Logic Inverter",
		"desc": "Reverses any signal",
		"adventure_use": "Turn 'access denied' into 'access granted'. Disable alarms. Bypass security systems. Required for hacking missions.",
		"icon_color": Color(0.6, 0.4, 0.8),
		"circuit": "Transistor Logic",
		"components": ["1x NPN Transistor", "2x 10k ohm Resistor", "1x LED"]
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
var tex_grass: Texture2D
var tex_kaido: Texture2D
var tex_grandmother: Texture2D
var tex_kaido_portrait: Texture2D
var tex_grandmother_portrait: Texture2D

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
var tex_grass_biome: Texture2D
var tex_chicken_house: Texture2D
var tex_chicken_sprites: Texture2D
var tex_cow_sprites: Texture2D
var tex_basic_tools: Texture2D

# Ninja Adventure animal sprites
var tex_ninja_cat: Texture2D
var tex_ninja_dog: Texture2D
var tex_ninja_cow: Texture2D
var tex_ninja_chicken: Texture2D
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
var tex_ninja_oldman: Texture2D
var tex_ninja_oldman2: Texture2D
var tex_ninja_princess: Texture2D
var tex_ninja_noble: Texture2D

# Roaming animals data structure
var roaming_animals: Array = []

# Asset paths
const SPROUT_PATH = "res://Sprout Lands - Sprites - Basic pack/"
const MYSTIC_PATH = "res://mystic_woods_free_2.2/sprites/"
const NINJA_PATH = "res://Ninja Adventure - Asset Pack/Actor/Characters/"
const NINJA_ANIMALS_PATH = "res://Ninja Adventure - Asset Pack/Actor/Animals/"
const TILESET_PATH = "res://Sprout Lands - Sprites - Basic pack/Tilesets/"
const OBJECTS_PATH = "res://Sprout Lands - Sprites - Basic pack/Objects/"

# Combat sprites
var tex_robot_enemy: Texture2D

# Circuit schematic textures
var tex_schematic_led_lamp: Texture2D
var tex_schematic_buzzer_alarm: Texture2D
var tex_schematic_not_gate: Texture2D
var tex_schematic_light_sensor: Texture2D
var tex_schematic_led_chain: Texture2D
var tex_schematic_or_gate: Texture2D

# Text wrap settings
const DIALOGUE_MAX_WIDTH = 340
const DIALOGUE_CHAR_WIDTH = 8

func set_quest(new_quest: String):
	if current_quest != new_quest:
		current_quest = new_quest
		quest_is_new = true
		quest_anim_timer = 0.0

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
	setup_audio()
	# Initialize camera centered on player
	center_camera_on_player()
	# Debug: Print connected controllers
	var joypads = Input.get_connected_joypads()
	print("=== CONTROLLER DEBUG ===")
	print("Connected joypads: ", joypads.size())
	for joy_id in joypads:
		print("  Joypad ", joy_id, ": ", Input.get_joy_name(joy_id))
	print("========================")

func setup_audio():
	# Main music player with generator
	audio_player = AudioStreamPlayer.new()
	audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 22050
	audio_generator.buffer_length = 0.1
	audio_player.stream = audio_generator
	audio_player.volume_db = -12
	add_child(audio_player)
	audio_player.play()
	audio_playback = audio_player.get_stream_playback()
	
	# SFX player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -8
	add_child(sfx_player)
	
	# Start farm music
	set_music_track("farm")

func load_sprites():
	if ResourceLoader.exists(MYSTIC_PATH + "characters/player.png"):
		tex_player = load(MYSTIC_PATH + "characters/player.png")
	if ResourceLoader.exists(MYSTIC_PATH + "tilesets/grass.png"):
		tex_grass = load(MYSTIC_PATH + "tilesets/grass.png")
	
	# Load Kaido sprite - prioritize the new drawn version
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_sprite_drawn.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido_sprite_drawn.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_small.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido_small.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido.png"):
		tex_kaido = load(SPROUT_PATH + "Characters/kaido.png")
	
	if ResourceLoader.exists(SPROUT_PATH + "Characters/grandmother.png"):
		tex_grandmother = load(SPROUT_PATH + "Characters/grandmother.png")
	
	# Load Kaido portrait - check for drawn portrait first
	if ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait_drawn.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait_drawn.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait_small.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait_small.png")
	elif ResourceLoader.exists(SPROUT_PATH + "Characters/kaido_portrait.png"):
		tex_kaido_portrait = load(SPROUT_PATH + "Characters/kaido_portrait.png")
	# Don't fall back to full sprite for portrait - let draw code handle it
	
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
	
	# Load grass biome objects (trees, bushes, etc)
	if ResourceLoader.exists(OBJECTS_PATH + "Basic Grass Biom things 1.png"):
		tex_grass_biome = load(OBJECTS_PATH + "Basic Grass Biom things 1.png")
	
	# Load chicken house
	if ResourceLoader.exists(OBJECTS_PATH + "Free_Chicken_House.png"):
		tex_chicken_house = load(OBJECTS_PATH + "Free_Chicken_House.png")
	
	# Load chicken sprites
	if ResourceLoader.exists(SPROUT_PATH + "Characters/Free Chicken Sprites.png"):
		tex_chicken_sprites = load(SPROUT_PATH + "Characters/Free Chicken Sprites.png")
	
	# Load cow sprites
	if ResourceLoader.exists(SPROUT_PATH + "Characters/Free Cow Sprites.png"):
		tex_cow_sprites = load(SPROUT_PATH + "Characters/Free Cow Sprites.png")
	
	# Load basic tools
	if ResourceLoader.exists(OBJECTS_PATH + "Basic_tools_and_meterials.png"):
		tex_basic_tools = load(OBJECTS_PATH + "Basic_tools_and_meterials.png")
	
	# Load Ninja Adventure animals
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Cat/SpriteSheet.png"):
		tex_ninja_cat = load(NINJA_ANIMALS_PATH + "Cat/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Dog/SpriteSheet.png"):
		tex_ninja_dog = load(NINJA_ANIMALS_PATH + "Dog/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Cow/SpriteSheet.png"):
		tex_ninja_cow = load(NINJA_ANIMALS_PATH + "Cow/SpriteSheet.png")
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Chicken/SpriteSheet.png"):
		tex_ninja_chicken = load(NINJA_ANIMALS_PATH + "Chicken/SpriteSheet.png")
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
	
	# A1: Add Pig to animals
	if ResourceLoader.exists(NINJA_ANIMALS_PATH + "Pig/SpriteSheet.png"):
		tex_ninja_pig = load(NINJA_ANIMALS_PATH + "Pig/SpriteSheet.png")

	# Load circuit schematic sprites
	if ResourceLoader.exists(SPROUT_PATH + "Characters/led_circuit_sprite.png"):
		tex_schematic_led_lamp = load(SPROUT_PATH + "Characters/led_circuit_sprite.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/buzzer_circuit_sprite.png"):
		tex_schematic_buzzer_alarm = load(SPROUT_PATH + "Characters/buzzer_circuit_sprite.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/not_gate_circuit_sprite.png"):
		tex_schematic_not_gate = load(SPROUT_PATH + "Characters/not_gate_circuit_sprite.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/light_sensor_circuit_sprite.png"):
		tex_schematic_light_sensor = load(SPROUT_PATH + "Characters/light_sensor_circuit_sprite.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/led_chain_circuit_sprite.png"):
		tex_schematic_led_chain = load(SPROUT_PATH + "Characters/led_chain_circuit_sprite.png")
	if ResourceLoader.exists(SPROUT_PATH + "Characters/or_gate_circuit_sprite.png"):
		tex_schematic_or_gate = load(SPROUT_PATH + "Characters/or_gate_circuit_sprite.png")
	
	# Initialize roaming animals for each area
	init_roaming_animals()

# ============================================
# ROAMING ANIMALS SYSTEM
# ============================================

func init_roaming_animals():
	roaming_animals.clear()
	
	# A1: Classic Farm animals
	roaming_animals.append({"area": "farm", "type": "cat", "pos": Vector2(80, 180), "target": Vector2(80, 180), "speed": 25.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "farm", "type": "dog", "pos": Vector2(380, 100), "target": Vector2(380, 100), "speed": 35.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "farm", "type": "chicken", "pos": Vector2(320, 250), "target": Vector2(320, 250), "speed": 8.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "farm", "type": "cow", "pos": Vector2(420, 50), "target": Vector2(420, 50), "speed": 15.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "farm", "type": "pig", "pos": Vector2(250, 180), "target": Vector2(250, 180), "speed": 20.0, "timer": 0.0, "dir": 0})
	
	# Cornfield area animals
	roaming_animals.append({"area": "cornfield", "type": "chicken", "pos": Vector2(100, 150), "target": Vector2(100, 150), "speed": 8.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "chicken", "pos": Vector2(350, 200), "target": Vector2(350, 200), "speed": 8.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "horse", "pos": Vector2(380, 100), "target": Vector2(380, 100), "speed": 30.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "cornfield", "type": "dog", "pos": Vector2(60, 280), "target": Vector2(60, 280), "speed": 32.0, "timer": 0.0, "dir": 0})
	
	# Lakeside area animals
	roaming_animals.append({"area": "lakeside", "type": "frog", "pos": Vector2(150, 250), "target": Vector2(150, 250), "speed": 40.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "lakeside", "type": "frog", "pos": Vector2(350, 270), "target": Vector2(350, 270), "speed": 35.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "lakeside", "type": "cat", "pos": Vector2(400, 290), "target": Vector2(400, 290), "speed": 25.0, "timer": 0.0, "dir": 0})
	
	# Town center area animals
	roaming_animals.append({"area": "town_center", "type": "dog", "pos": Vector2(100, 200), "target": Vector2(100, 200), "speed": 30.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "cat", "pos": Vector2(380, 150), "target": Vector2(380, 150), "speed": 28.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "chicken", "pos": Vector2(200, 280), "target": Vector2(200, 280), "speed": 8.0, "timer": 0.0, "dir": 0})
	roaming_animals.append({"area": "town_center", "type": "donkey", "pos": Vector2(420, 260), "target": Vector2(420, 260), "speed": 18.0, "timer": 0.0, "dir": 0})

func update_roaming_animals(delta: float):
	for animal in roaming_animals:
		# Update timer
		animal.timer -= delta
		
		# Pick new target when timer expires
		if animal.timer <= 0:
			animal.timer = randf_range(3.0, 8.0)  # Stay in place longer
			# Chickens stay close to their current position, others roam more
			if animal.type == "chicken":
				# Chickens only move small distances (pecking around)
				animal.target = Vector2(
					animal.pos.x + randf_range(-30, 30),
					animal.pos.y + randf_range(-20, 20)
				)
			else:
				# Other animals roam the area
				var bounds = get_area_bounds(animal.area)
				animal.target = Vector2(
					randf_range(bounds.position.x + 30, bounds.position.x + bounds.size.x - 30),
					randf_range(bounds.position.y + 30, bounds.position.y + bounds.size.y - 30)
				)
		
		# Move towards target
		var dir = (animal.target - animal.pos)
		if dir.length() > 5:
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
			return Rect2(20, 20, 440, 280)
		"cornfield":
			return Rect2(20, 60, 440, 240)
		"lakeside":
			return Rect2(20, 240, 440, 70)
		"town_center":
			return Rect2(20, 80, 440, 220)
		_:
			return Rect2(20, 20, 440, 280)

func draw_roaming_animals_for_area(area_name: String):
	for animal in roaming_animals:
		if animal.area == area_name:
			draw_ninja_animal(animal.pos, animal.type, animal.dir)

func draw_ninja_animal(pos: Vector2, animal_type: String, direction: int):
	# Ninja Adventure sprite sheets are typically 16x16 per frame
	# Layout: 4 rows (down, left, right, up), 4 columns (animation frames)
	var tex: Texture2D = null
	var frame_size = 16
	
	match animal_type:
		"cat":
			tex = tex_ninja_cat
		"dog":
			tex = tex_ninja_dog
		"cow":
			tex = tex_ninja_cow
			frame_size = 16
		"chicken":
			tex = tex_ninja_chicken
		"horse":
			tex = tex_ninja_horse
		"donkey":
			tex = tex_ninja_donkey
		"frog":
			tex = tex_ninja_frog
		"fish":
			tex = tex_ninja_fish
		"pig":
			tex = tex_ninja_pig
	
	if tex:
		# Animation speed varies by animal
		var anim_speed = 6.0
		var frame = 0
		
		if animal_type == "chicken":
			# Chickens use single frame only (no animation cycling to prevent flashing)
			frame = 0
		else:
			frame = int(fmod(continuous_timer * anim_speed + pos.x * 0.1, 4))
		
		var row = direction  # 0=down, 1=left, 2=right, 3=up
		
		var src = Rect2(frame * frame_size, row * frame_size, frame_size, frame_size)
		
		# Consistent size per animal type
		var scale = 1.2
		if animal_type == "chicken":
			scale = 0.9  # Chickens are smaller, consistent size
		elif animal_type == "cow" or animal_type == "horse":
			scale = 1.4  # Larger animals
		
		var dest = Rect2(pos.x - frame_size * scale / 2, pos.y - frame_size * scale, frame_size * scale, frame_size * scale)
		
		# Shadow
		draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(8 * scale / 2, 3 * scale / 2), Color(0, 0, 0, 0.2))
		
		draw_texture_rect_region(tex, dest, src)
	else:
		# Fallback - draw simple shape
		var color = Color(0.6, 0.5, 0.4)
		match animal_type:
			"cat":
				color = Color(0.9, 0.6, 0.3)
			"dog":
				color = Color(0.7, 0.5, 0.3)
			"cow":
				color = Color(0.95, 0.95, 0.9)
			"chicken":
				color = Color(1.0, 0.9, 0.7)
			"horse":
				color = Color(0.6, 0.4, 0.3)
			"frog":
				color = Color(0.3, 0.7, 0.3)
			"pig":
				color = Color(0.95, 0.75, 0.75)
		
		draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(8, 3), Color(0, 0, 0, 0.2))
		draw_circle(Vector2(pos.x, pos.y - 8), 10, color)
		draw_circle(Vector2(pos.x + 6, pos.y - 12), 5, color)

# ============================================
# AUDIO GENERATION FUNCTIONS
# ============================================

func set_music_track(track: String):
	if track == current_track:
		return
	current_track = track
	current_note_index = 0
	note_timer = 0.0
	
	# Set tempo based on track
	match track:
		"farm":
			music_tempo = 0.2  # Relaxed but not too slow
		"combat":
			music_tempo = 0.12  # Fast and intense
		"tower":
			music_tempo = 0.18  # Adventurous pace
		"none":
			pass

func process_music(delta):
	if not music_enabled or current_track == "none":
		return
	if audio_playback == null:
		return
	
	note_timer -= delta
	
	# Time for next note?
	if note_timer <= 0:
		note_timer = music_tempo
		
		var melody = []
		match current_track:
			"farm":
				melody = farm_melody
			"combat":
				melody = combat_melody
			"tower":
				melody = tower_melody
		
		if melody.size() > 0:
			var note_name = melody[current_note_index]
			current_note_index = (current_note_index + 1) % melody.size()
			
			if note_name != "R":
				var freq = NOTE_FREQS.get(note_name, 0.0)
				if freq > 0:
					generate_note(freq, music_tempo * 0.7)

func generate_note(frequency: float, duration: float):
	if audio_playback == null:
		return
	
	var sample_rate = 22050.0
	var samples = int(sample_rate * duration)
	var period = sample_rate / frequency
	
	# Fill the buffer with square wave
	for i in range(min(samples, audio_playback.get_frames_available())):
		# Square wave with slight attack/decay envelope
		var t = float(i) / float(samples)
		var envelope = 1.0
		if t < 0.05:
			envelope = t / 0.05  # Attack
		elif t > 0.7:
			envelope = (1.0 - t) / 0.3  # Decay
		
		# Square wave (pulse wave with 50% duty)
		var phase = fmod(float(i), period) / period
		var value = 1.0 if phase < 0.5 else -1.0
		value *= 0.15 * envelope  # Volume
		
		audio_playback.push_frame(Vector2(value, value))

func play_sfx(sfx_type: String):
	# Generate quick sound effects
	if audio_playback == null:
		return
	
	match sfx_type:
		"hit":
			generate_sfx_hit()
		"dodge":
			generate_sfx_dodge()
		"menu":
			generate_sfx_menu()
		"pickup":
			generate_sfx_pickup()
		"hurt":
			generate_sfx_hurt()
		"jump":
			generate_sfx_jump()

func generate_sfx_jump():
	# Quick ascending blip
	var sample_rate = 22050.0
	var samples = int(sample_rate * 0.08)
	
	for i in range(min(samples, audio_playback.get_frames_available())):
		var t = float(i) / float(samples)
		var freq = 300 + t * 400  # Ascend from 300 to 700 Hz
		var period = sample_rate / freq
		var phase = fmod(float(i), period) / period
		var value = 1.0 if phase < 0.5 else -1.0
		value *= 0.15 * (1.0 - t * 0.6)  # Quick fade
		audio_playback.push_frame(Vector2(value, value))

func generate_sfx_hit():
	# Quick descending tone burst
	var sample_rate = 22050.0
	var samples = int(sample_rate * 0.08)
	
	for i in range(min(samples, audio_playback.get_frames_available())):
		var t = float(i) / float(samples)
		var freq = 400 - t * 200  # Descend from 400 to 200 Hz
		var period = sample_rate / freq
		var phase = fmod(float(i), period) / period
		var value = 1.0 if phase < 0.3 else -1.0  # Pulse wave
		value *= 0.25 * (1.0 - t)  # Fade out
		audio_playback.push_frame(Vector2(value, value))

func generate_sfx_dodge():
	# Quick whoosh - white noise fade
	var sample_rate = 22050.0
	var samples = int(sample_rate * 0.1)
	
	for i in range(min(samples, audio_playback.get_frames_available())):
		var t = float(i) / float(samples)
		var value = randf_range(-1, 1) * 0.15 * (1.0 - t)
		audio_playback.push_frame(Vector2(value, value))

func generate_sfx_menu():
	# Short blip
	var sample_rate = 22050.0
	var samples = int(sample_rate * 0.05)
	var freq = 880.0  # A5
	var period = sample_rate / freq
	
	for i in range(min(samples, audio_playback.get_frames_available())):
		var t = float(i) / float(samples)
		var phase = fmod(float(i), period) / period
		var value = 1.0 if phase < 0.5 else -1.0
		value *= 0.2 * (1.0 - t * 0.5)
		audio_playback.push_frame(Vector2(value, value))

func generate_sfx_pickup():
	# Ascending arpeggio blip
	var sample_rate = 22050.0
	var notes = [523.25, 659.25, 783.99]  # C5, E5, G5
	
	for note_idx in range(3):
		var freq = notes[note_idx]
		var samples = int(sample_rate * 0.06)
		var period = sample_rate / freq
		
		for i in range(min(samples, audio_playback.get_frames_available())):
			var t = float(i) / float(samples)
			var phase = fmod(float(i), period) / period
			var value = 1.0 if phase < 0.5 else -1.0
			value *= 0.18 * (1.0 - t * 0.3)
			audio_playback.push_frame(Vector2(value, value))

func generate_sfx_hurt():
	# Noise burst with low tone
	var sample_rate = 22050.0
	var samples = int(sample_rate * 0.15)
	var freq = 150.0
	var period = sample_rate / freq
	
	for i in range(min(samples, audio_playback.get_frames_available())):
		var t = float(i) / float(samples)
		var phase = fmod(float(i), period) / period
		var square = 1.0 if phase < 0.5 else -1.0
		var noise = randf_range(-1, 1) * 0.5
		var value = (square * 0.6 + noise * 0.4) * 0.2 * (1.0 - t)
		audio_playback.push_frame(Vector2(value, value))

func _process(delta):
	anim_timer += delta
	continuous_timer += delta  # Never resets
	if anim_timer > 0.15:
		anim_timer = 0
		player_frame = (player_frame + 1) % 6
	
	# Update screen transition effect
	if screen_transition_active:
		if screen_transition_phase == 1:  # Fading in (from black)
			screen_transition_alpha -= delta * screen_transition_speed
			if screen_transition_alpha <= 0:
				screen_transition_alpha = 0
				screen_transition_active = false
	
	# Process procedural music
	process_music(delta)
	
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
	
	# Update grandmother movement
	if grandmother_pos.distance_to(grandmother_target) > 2:
		var dir = (grandmother_target - grandmother_pos).normalized()
		grandmother_pos += dir * 40 * delta
	
	# Update roaming animals
	update_roaming_animals(delta)
	
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

func process_movement(delta):
	# Can't move if detected
	if player_detected:
		is_walking = false
		return
	
	# Moving while hiding breaks stealth
	var input = Vector2.ZERO
	
	# Keyboard input via actions
	if Input.is_action_pressed("move_up"):
		input.y -= 1
		player_facing = "up"
	if Input.is_action_pressed("move_down"):
		input.y += 1
		player_facing = "down"
	if Input.is_action_pressed("move_left"):
		input.x -= 1
		player_facing = "left"
	if Input.is_action_pressed("move_right"):
		input.x += 1
		player_facing = "right"
	
	# Raw joypad input (fallback if Input Map not configured)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_x) > 0.3:  # Deadzone
		input.x = joy_x
		player_facing = "right" if joy_x > 0 else "left"
	if abs(joy_y) > 0.3:  # Deadzone
		input.y = joy_y
		player_facing = "down" if joy_y > 0 else "up"
	
	# If hiding and trying to move, break stealth
	if is_hiding and input.length() > 0:
		is_hiding = false
	
	is_walking = input.length() > 0
	
	if is_walking:
		input = input.normalized()
		var new_pos = player_pos + input * player_speed * delta
		
		# Check collision with buildings
		if not check_collision(new_pos):
			player_pos = new_pos
		else:
			# Try sliding along walls
			var slide_x = Vector2(player_pos.x + input.x * player_speed * delta, player_pos.y)
			var slide_y = Vector2(player_pos.x, player_pos.y + input.y * player_speed * delta)
			if not check_collision(slide_x):
				player_pos = slide_x
			elif not check_collision(slide_y):
				player_pos = slide_y
		
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
			set_music_track("farm")
		Area.CORNFIELD:
			set_music_track("farm")  # Same peaceful music
			if not cornfield_led_placed and quest_stage == 12:
				dialogue_queue = [
					{"speaker": "kaido", "text": "The farmers up here need to see the signal."},
					{"speaker": "kaido", "text": "We should place LED markers along the path."},
				]
				next_dialogue()
		Area.LAKESIDE:
			set_music_track("farm")  # Could add lakeside melody later
		Area.TOWN_CENTER:
			set_music_track("farm")
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
		if grandmother_pos.distance_to(pos) < 20:
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
		# Water collision - block y: 80-225 EXCEPT on dock area (x: 145-235)
		if pos.y > 80 and pos.y < 225:
			# Allow walking on the dock
			if pos.x < 145 or pos.x > 235:
				return true
		# Cliff collision (right side)
		if pos.x > 380 and pos.y < 230:
			return true
		# Rocks collision
		if Vector2(100, 260).distance_to(pos) < 18:
			return true
		if Vector2(300, 280).distance_to(pos) < 22:
			return true
		if Vector2(320, 270).distance_to(pos) < 14:
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
		
		# Cherry blossom trees (trunks)
		if Vector2(35, 25).distance_to(pos) < 15:
			return true
		if Vector2(445, 25).distance_to(pos) < 15:
			return true
		if Vector2(35, 275).distance_to(pos) < 15:
			return true
		if Vector2(445, 275).distance_to(pos) < 15:
			return true
	
	return false

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
	
	# Smooth camera movement
	camera_offset = camera_offset.lerp(target_offset, 0.12)

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
	kaido_pos = kaido_pos.lerp(target_pos, 0.1)
	
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
	var input = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Raw joypad input (fallback)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_x) > 0.3:
		input.x = joy_x
	if abs(joy_y) > 0.3:
		input.y = joy_y
	
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
			play_sfx("menu")
			return
		elif current_mode in [GameMode.EXPLORATION, GameMode.SHED_INTERIOR, GameMode.SHOP_INTERIOR, GameMode.TOWNHALL_INTERIOR, GameMode.BAKERY_INTERIOR]:
			# Open pause menu
			pause_previous_mode = current_mode
			current_mode = GameMode.PAUSE_MENU
			pause_menu_selection = 0
			play_sfx("menu")
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
	
	# Accept interact OR ui_accept OR Cross button (for controller support)
	var interact_pressed = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
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
	var use_gadget_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		use_gadget_pressed = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		use_gadget_pressed = true
	if use_gadget_pressed and current_mode == GameMode.EXPLORATION and not in_dialogue:
		if equipped_gadget != "" and gadget_use_timer <= 0:
			use_equipped_gadget()
		elif equipped_gadget == "" and punch_cooldown <= 0:
			do_punch()
	
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
	current_mode = GameMode.COMBAT
	combat_active = true
	set_music_track("combat")  # Switch to combat music
	
	# Reset combat state
	combat_player_hp = combat_player_max_hp
	combat_player_stamina = combat_player_max_stamina
	combat_player_pos = Vector2(150, combat_arena_y)
	combat_player_vel = Vector2.ZERO
	combat_player_state = "idle"
	combat_player_state_timer = 0.0
	combat_combo_count = 0
	combat_combo_timer = 0.0
	combat_player_facing_right = true
	combat_iframe_active = false
	
	robot_hp = robot_max_hp
	robot_pos = Vector2(330, combat_arena_y)
	robot_state = "idle"
	robot_state_timer = 0.0
	robot_current_attack = ""
	robot_phase = 1
	robot_defeated = false
	robot_spark_timer = 0.0
	
	hit_effects.clear()
	slash_trails.clear()
	screen_shake = 0.0
	
	# Show intro dialogue
	combat_hint = "Watch its movements!"
	combat_hint_timer = 3.0

func start_tunnel_fight():
	tunnel_fight_active = true
	current_mode = GameMode.COMBAT
	combat_active = true
	set_music_track("combat")  # Switch to combat music
	
	# Reset combat state
	combat_player_hp = combat_player_max_hp
	combat_player_stamina = combat_player_max_stamina
	combat_player_pos = Vector2(100, combat_arena_y)
	combat_player_vel = Vector2.ZERO
	combat_player_state = "idle"
	combat_player_state_timer = 0.0
	combat_combo_count = 0
	combat_combo_timer = 0.0
	combat_player_facing_right = true
	combat_iframe_active = false
	slash_trails.clear()
	
	# Create 3 robots at once
	tunnel_robots = [
		{
			"pos": Vector2(280, combat_arena_y),
			"hp": 150,
			"max_hp": 150,
			"state": "idle",
			"state_timer": 0.5,
			"attack": "",
			"defeated": false
		},
		{
			"pos": Vector2(340, combat_arena_y - 20),
			"hp": 150,
			"max_hp": 150,
			"state": "idle",
			"state_timer": 1.2,
			"attack": "",
			"defeated": false
		},
		{
			"pos": Vector2(400, combat_arena_y + 10),
			"hp": 150,
			"max_hp": 150,
			"state": "idle",
			"state_timer": 1.8,
			"attack": "",
			"defeated": false
		}
	]
	
	# Disable single robot mode
	robot_defeated = true
	
	hit_effects.clear()
	screen_shake = 0.0
	
	combat_hint = "Three robots block the tunnel!"
	combat_hint_timer = 3.0

func get_active_tunnel_robots() -> int:
	var count = 0
	for r in tunnel_robots:
		if not r.defeated:
			count += 1
	return count

func get_nearest_tunnel_robot() -> int:
	var nearest_idx = -1
	var nearest_dist = 9999.0
	for i in range(tunnel_robots.size()):
		if not tunnel_robots[i].defeated:
			var dist = combat_player_pos.distance_to(tunnel_robots[i].pos)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_idx = i
	return nearest_idx

func damage_nearest_tunnel_robot(damage: int):
	var idx = get_nearest_tunnel_robot()
	if idx >= 0:
		tunnel_robots[idx].hp -= damage
		play_sfx("hit")  # Hit impact sound
		var hit_pos = tunnel_robots[idx].pos + Vector2(randf_range(-10, 10), -30)
		add_hit_effect(hit_pos, str(damage), Color(1, 1, 0.5))
		hit_flash_timer = 0.15
		screen_shake = 6.0
		hit_pause_timer = 0.06
		
		# Knockback
		var kb_dir = 1 if combat_player_pos.x < tunnel_robots[idx].pos.x else -1
		tunnel_robots[idx].pos.x += kb_dir * 8
		tunnel_robots[idx].pos.x = clamp(tunnel_robots[idx].pos.x, combat_arena_left + 20, combat_arena_right - 20)
		
		if tunnel_robots[idx].hp <= 0:
			tunnel_robots[idx].defeated = true
			tunnel_robots[idx].hp = 0
			screen_shake = 12.0
			hit_pause_timer = 0.1
			add_hit_effect(tunnel_robots[idx].pos + Vector2(0, -50), "K.O.!", Color(1, 0.4, 0.2))
			
			if get_active_tunnel_robots() == 0:
				end_tunnel_fight_victory()

func deal_damage_to_tunnel_robot(idx: int, damage: int):
	if idx < 0 or idx >= tunnel_robots.size():
		return
	if tunnel_robots[idx].defeated:
		return
	
	tunnel_robots[idx].hp -= damage
	play_sfx("hit")  # Hit impact sound
	var hit_pos = tunnel_robots[idx].pos + Vector2(randf_range(-10, 10), -30)
	add_hit_effect(hit_pos, str(damage), Color(1, 1, 0.5))
	hit_flash_timer = 0.15
	screen_shake = 6.0
	hit_pause_timer = 0.06
	
	# Knockback
	var kb_dir = 1 if combat_player_pos.x < tunnel_robots[idx].pos.x else -1
	tunnel_robots[idx].pos.x += kb_dir * 8
	tunnel_robots[idx].pos.x = clamp(tunnel_robots[idx].pos.x, combat_arena_left + 20, combat_arena_right - 20)
	
	if tunnel_robots[idx].hp <= 0:
		tunnel_robots[idx].defeated = true
		tunnel_robots[idx].hp = 0
		screen_shake = 12.0
		hit_pause_timer = 0.1
		add_hit_effect(tunnel_robots[idx].pos + Vector2(0, -50), "K.O.!", Color(1, 0.4, 0.2))
		
		if get_active_tunnel_robots() == 0:
			end_tunnel_fight_victory()

func end_tunnel_fight_victory():
	tunnel_fight_active = false
	current_mode = GameMode.EXPLORATION
	combat_active = false
	robot_max_hp = 300  # Reset for next time
	set_music_track("farm")  # Back to farm music
	
	# Reset Kaido
	kaido_trail_history.clear()
	kaido_pos = player_pos + Vector2(-20, -15)
	
	dialogue_queue = [
		{"speaker": "system", "text": "[ The last robot falls. ]"},
		{"speaker": "system", "text": "[ The tunnel entrance is clear. ]"},
		{"speaker": "kaido", "text": "We made it! The path is open!"},
		{"speaker": "grandmother", "text": "Go. Now. Don't look back."},
		{"speaker": "grandmother", "text": "I'll lead them away from here."},
		{"speaker": "system", "text": "[ Grandmother runs toward the patrol. ]"},
		{"speaker": "kaido", "text": "No! We can't leave her!"},
		{"speaker": "grandmother", "text": "Find Professor Ohm. Show him this."},
		{"speaker": "system", "text": "[ She presses a memory stick into your hand. ]"},
		{"speaker": "grandmother", "text": "Your grandfather's work. Finish it."},
		{"speaker": "start_ending", "text": ""},
	]
	next_dialogue()

# ============================================
# STAMPEDE MINIGAME (Left Road)
# Endless combat minigame
# ============================================

func start_stampede():
	current_mode = GameMode.STAMPEDE
	stampede_active = true
	stampede_player_pos = Vector2(380, stampede_ground_y)  # Player starts on RIGHT
	stampede_player_vel = Vector2.ZERO
	stampede_player_y_vel = 0.0
	stampede_player_grounded = true
	stampede_player_hp = stampede_player_max_hp
	stampede_player_state = "idle"
	stampede_player_state_timer = 0.0
	stampede_player_facing_right = false  # Face left toward incoming animals
	stampede_wave = 1
	stampede_animals.clear()
	stampede_hit_effects.clear()
	stampede_spawn_timer = 1.5  # Initial delay
	stampede_wave_timer = 0.0
	stampede_complete = false
	stampede_score = 0
	screen_shake = 0.0
	set_music_track("combat")
	
	dialogue_queue = [
		{"speaker": "kaido", "text": "The farm animals are panicking!"},
		{"speaker": "kaido", "text": "Survive as long as you can!"},
		{"speaker": "kaido", "text": "[_]=Punch  â–³=Counter  [X]=Jump  [O]=Gadget"},
	]
	next_dialogue()

func handle_stampede_input(event):
	if stampede_player_state == "hit":
		return  # Can't act during hit stun
	
	# Can't act during dodge
	if stampede_player_state == "dodging":
		return
	
	# Gadget cycling - R1 / Tab
	var cycle_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_TAB)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		cycle_pressed = true
	if cycle_pressed:
		cycle_gadget()
		return
	
	# Jump - Cross button ([X]) / Z key / Space
	var jump_pressed = event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_Z)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		jump_pressed = true
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		jump_pressed = true
	if jump_pressed:
		if stampede_player_grounded and stampede_player_state != "attacking":
			start_stampede_jump()
	
	# Punch/Attack - Square button ([_]) / X key
	var attack_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_X)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		attack_pressed = true
	if attack_pressed:
		if stampede_player_state == "idle" or stampede_player_state == "jumping":
			start_stampede_attack()
	
	# Counter - Triangle button (â–³) / Y key (when animal is charging)
	var counter_pressed = (event is InputEventKey and event.pressed and event.keycode == KEY_Y)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		counter_pressed = true
	if counter_pressed:
		# Check if any bull is nearby and charging
		for animal in stampede_animals:
			if animal.type == ANIMAL_BULL and not animal.defeated:
				var dist = abs(stampede_player_pos.x - animal.pos.x)
				if dist < 80:
					execute_stampede_counter(animal)
					break
	
	# Gadget - Circle button ([O]) / C key
	var gadget_pressed = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_C)
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		gadget_pressed = true
	# R2 trigger
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.5:
		gadget_pressed = true
	if gadget_pressed and gadget_use_timer <= 0:
		use_stampede_gadget()

func start_stampede_dodge():
	stampede_player_state = "dodging"
	stampede_player_state_timer = 0.3
	# Quick sidestep in facing direction
	var dodge_dir = 1 if stampede_player_facing_right else -1
	stampede_player_pos.x += dodge_dir * 60
	stampede_player_pos.x = clamp(stampede_player_pos.x, stampede_arena_left, stampede_arena_right)
	play_sfx("jump")

func execute_stampede_counter(animal: Dictionary):
	stampede_player_state = "countering"
	stampede_player_state_timer = 0.4
	# Big damage to countered animal
	animal.hp -= 40
	animal.hit_flash = 0.2
	screen_shake = 8.0
	hit_pause_timer = 0.1
	play_sfx("hit")
	
	stampede_hit_effects.append({
		"pos": animal.pos + Vector2(0, -40),
		"text": "COUNTER!",
		"timer": 0.8,
		"color": Color(1, 0.5, 0.2)
	})
	
	if animal.hp <= 0:
		animal.defeated = true

func use_stampede_gadget():
	if equipped_gadget == "":
		stampede_hit_effects.append({
			"pos": stampede_player_pos + Vector2(0, -50),
			"text": "No gadget!",
			"timer": 1.0,
			"color": Color(0.8, 0.4, 0.4)
		})
		return
	
	gadget_use_timer = 1.5  # Cooldown
	
	match equipped_gadget:
		"led_lamp":
			# Flashlight: stuns nearby animals
			stampede_flashlight_effect()
		"not_gate":
			# NOT gate pulse: damages all enemies
			stampede_pulse_effect()
		_:
			# Other gadgets: small effect
			stampede_hit_effects.append({
				"pos": stampede_player_pos + Vector2(0, -50),
				"text": "Gadget!",
				"timer": 1.0,
				"color": Color(0.5, 1, 0.8)
			})

func stampede_flashlight_effect():
	# Flash of light - stuns nearby animals
	screen_shake = 3.0
	stampede_hit_effects.append({
		"pos": stampede_player_pos + Vector2(0, -40),
		"text": "FLASH!",
		"timer": 0.8,
		"color": Color(1.0, 1.0, 0.8)
	})
	
	# Stun all animals in range
	for animal in stampede_animals:
		if animal.defeated:
			continue
		var dist = abs(stampede_player_pos.x - animal.pos.x)
		if dist < 150:
			# Stop the animal briefly
			animal.vel.x = 0
			animal.hit_flash = 0.5

func stampede_pulse_effect():
	# EMP pulse - damages all enemies on screen
	screen_shake = 5.0
	stampede_hit_effects.append({
		"pos": Vector2(240, 120),
		"text": "EMP PULSE!",
		"timer": 1.0,
		"color": Color(0.4, 0.8, 1.0)
	})
	
	# Damage all animals
	for animal in stampede_animals:
		if animal.defeated:
			continue
		animal.hp -= 25
		animal.hit_flash = 0.3
		if animal.hp <= 0:
			animal.defeated = true
			stampede_score += 15  # Bonus for gadget kills

func start_stampede_attack():
	stampede_player_state = "attacking"
	stampede_player_state_timer = 0.25
	
	# Check for hits on nearby animals - generous range, both directions
	var attack_range = 70  # Wide attack range
	var hit_any = false
	for animal in stampede_animals:
		if animal.defeated:
			continue
		var dist = abs(stampede_player_pos.x - animal.pos.x)
		if dist < attack_range:
			hit_stampede_animal(animal)
			hit_any = true
	
	# Play sound based on hit or miss
	if hit_any:
		play_sfx("hit")
	else:
		# Whoosh sound for miss (or just quiet)
		pass

func start_stampede_jump():
	stampede_player_state = "jumping"
	stampede_player_grounded = false
	stampede_player_y_vel = -400.0  # Jump force
	play_sfx("jump")

func hit_stampede_animal(animal: Dictionary):
	var damage = 35  # Increased damage for satisfying hits
	animal.hp -= damage
	animal.hit_flash = 0.2
	screen_shake = 5.0
	hit_pause_timer = 0.06
	play_sfx("hit")
	
	# Add hit effect
	stampede_hit_effects.append({
		"pos": animal.pos + Vector2(0, -30),
		"text": str(damage),
		"timer": 0.6,
		"color": Color(1, 1, 0.3)
	})
	
	if animal.hp <= 0:
		animal.defeated = true
		
		# Score based on enemy type
		var score_gained = 10
		var defeat_text = "SPOOKED!"
		var defeat_color = Color(0.5, 1, 0.5)
		
		match animal.type:
			ANIMAL_CHICKEN:
				score_gained = 10
			ANIMAL_COW:
				score_gained = 20
			ANIMAL_BULL:
				score_gained = 30
			ANIMAL_ROBOT:
				score_gained = 50
				defeat_text = "DESTROYED!"
				defeat_color = Color(1, 0.5, 0.3)
			ANIMAL_ROBOT_HEAVY:
				score_gained = 100
				defeat_text = "WRECKED!"
				defeat_color = Color(1, 0.3, 0.6)
		
		stampede_score += score_gained
		
		stampede_hit_effects.append({
			"pos": animal.pos + Vector2(0, -50),
			"text": defeat_text,
			"timer": 0.8,
			"color": defeat_color
		})
		stampede_hit_effects.append({
			"pos": animal.pos + Vector2(20, -35),
			"text": "+" + str(score_gained),
			"timer": 0.7,
			"color": Color(1, 1, 0.5)
		})

func process_stampede(delta):
	if in_dialogue:
		return
	
	if stampede_complete:
		return
	
	# Hit pause
	if hit_pause_timer > 0:
		hit_pause_timer -= delta
		return
	
	# Screen shake decay
	if screen_shake > 0:
		screen_shake -= delta * 30
		if screen_shake < 0:
			screen_shake = 0
	
	# Update hit effects
	for i in range(stampede_hit_effects.size() - 1, -1, -1):
		stampede_hit_effects[i].timer -= delta
		stampede_hit_effects[i].pos.y -= delta * 40
		if stampede_hit_effects[i].timer <= 0:
			stampede_hit_effects.remove_at(i)
	
	# Update player state timer
	if stampede_player_state_timer > 0:
		stampede_player_state_timer -= delta
		if stampede_player_state_timer <= 0:
			match stampede_player_state:
				"attacking":
					stampede_player_state = "jumping" if not stampede_player_grounded else "idle"
				"hit":
					stampede_player_state = "idle"
				"dodging":
					stampede_player_state = "idle"
				"countering":
					stampede_player_state = "idle"
	
	# Gravity
	if not stampede_player_grounded:
		stampede_player_y_vel += 1200.0 * delta  # Gravity
		stampede_player_pos.y += stampede_player_y_vel * delta
		
		# Land on ground
		if stampede_player_pos.y >= stampede_ground_y:
			stampede_player_pos.y = stampede_ground_y
			stampede_player_y_vel = 0
			stampede_player_grounded = true
			if stampede_player_state == "jumping":
				stampede_player_state = "idle"
	
	# Movement (combat-style)
	if stampede_player_state in ["idle", "jumping", "attacking"]:
		process_stampede_movement(delta)
	
	# Spawn animals - rate increases with wave
	stampede_spawn_timer -= delta
	if stampede_spawn_timer <= 0:
		spawn_stampede_animal()
		# Spawn rate gets faster with waves, but has a minimum
		var base_rate = max(0.4, 1.8 - (stampede_wave * 0.15))
		stampede_spawn_timer = randf_range(base_rate * 0.7, base_rate * 1.3)
	
	# Update animals
	update_stampede_animals(delta)
	
	# Wave progression - endless mode
	stampede_wave_timer += delta
	if stampede_wave_timer > 15.0:  # 15 seconds per wave
		stampede_wave_timer = 0
		stampede_wave += 1
		
		# Wave announcement with special messages
		var wave_text = "WAVE " + str(stampede_wave)
		var wave_color = Color(1, 0.8, 0.3)
		
		if stampede_wave == 4:
			wave_text = "WAVE 4 - ROBOTS!"
			wave_color = Color(1, 0.3, 0.3)
		elif stampede_wave == 6:
			wave_text = "WAVE 6 - HEAVY ROBOTS!"
			wave_color = Color(1, 0.2, 0.5)
		elif stampede_wave % 5 == 0:
			wave_text = "WAVE " + str(stampede_wave) + " - DANGER!"
			wave_color = Color(1, 0.4, 0.2)
		
		stampede_hit_effects.append({
			"pos": Vector2(240, 100),
			"text": wave_text,
			"timer": 2.0,
			"color": wave_color
		})
		
		# Bonus HP every 3 waves
		if stampede_wave % 3 == 0 and stampede_player_hp < stampede_player_max_hp:
			stampede_player_hp += 1
			stampede_hit_effects.append({
				"pos": Vector2(240, 140),
				"text": "+1 HP",
				"timer": 1.5,
				"color": Color(0.3, 1, 0.3)
			})

func process_stampede_movement(delta):
	# Exploration-style movement (direct position, no momentum)
	var input_x = 0.0
	if Input.is_action_pressed("move_left"):
		input_x -= 1
	if Input.is_action_pressed("move_right"):
		input_x += 1
	
	# Raw joypad input
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(joy_x) > 0.3:
		input_x = sign(joy_x)
	
	# Direct position update (like exploration)
	var move_speed = 180.0
	if input_x != 0:
		stampede_player_pos.x += input_x * move_speed * delta
		# Face movement direction only (not auto-face enemies)
		stampede_player_facing_right = input_x > 0
	
	# Clamp to arena
	stampede_player_pos.x = clamp(stampede_player_pos.x, stampede_arena_left, stampede_arena_right)

func update_stampede_animals(delta):
	for i in range(stampede_animals.size() - 1, -1, -1):
		var animal = stampede_animals[i]
		
		# Update hit flash
		if animal.hit_flash > 0:
			animal.hit_flash -= delta
			# Restore velocity when stun ends
			if animal.hit_flash <= 0 and animal.vel.x == 0 and not animal.defeated:
				animal.vel.x = animal.original_speed
		
		# Remove defeated animals after a moment
		if animal.defeated:
			animal.pos.y += 100 * delta  # Fall down
			if animal.pos.y > 350:
				stampede_animals.remove_at(i)
			continue
		
		# Move animal
		animal.pos.x += animal.vel.x * delta
		
		# Remove if off screen
		if animal.pos.x < -80 or animal.pos.x > 560:
			stampede_animals.remove_at(i)
			continue
		
		# Check if player attack hits this animal (continuous during attack)
		if stampede_player_state == "attacking" and animal.hit_flash <= 0:
			var dist = abs(stampede_player_pos.x - animal.pos.x)
			if dist < 70:
				hit_stampede_animal(animal)
				continue
		
		# Jump attack - hitting animals while in the air
		if not stampede_player_grounded and stampede_player_y_vel > 0:  # Falling
			var dist = stampede_player_pos.distance_to(animal.pos)
			if dist < 50 and animal.hit_flash <= 0:
				hit_stampede_animal(animal)
				# Bounce up slightly
				stampede_player_y_vel = -200
				continue
		
		# Check collision with player (only if player on ground and not attacking/dodging)
		if stampede_player_state not in ["attacking", "dodging", "countering"] and stampede_player_grounded:
			var dist = abs(stampede_player_pos.x - animal.pos.x)
			if dist < 35:
				# Player gets hit
				stampede_player_hp -= 1
				stampede_player_state = "hit"
				stampede_player_state_timer = 0.4
				screen_shake = 8.0
				play_sfx("hurt")
				
				# Knockback - direct position change (like exploration)
				var kb_dir = -1 if animal.vel.x > 0 else 1
				stampede_player_pos.x += kb_dir * 40
				stampede_player_pos.x = clamp(stampede_player_pos.x, stampede_arena_left, stampede_arena_right)
				
				# Remove this animal
				stampede_animals.remove_at(i)
				
				if stampede_player_hp <= 0:
					end_stampede(false)
				return

func spawn_stampede_animal():
	var animal_type = ANIMAL_CHICKEN
	var hp = 20
	var speed = 180.0  # Base speed (will be positive for right movement)
	
	# Random enemy type based on wave
	var roll = randf()
	
	if stampede_wave <= 1:
		# Wave 1: Only chickens and cows
		animal_type = ANIMAL_CHICKEN if roll < 0.7 else ANIMAL_COW
	elif stampede_wave <= 3:
		# Waves 2-3: Add bulls
		if roll < 0.3:
			animal_type = ANIMAL_CHICKEN
		elif roll < 0.7:
			animal_type = ANIMAL_COW
		else:
			animal_type = ANIMAL_BULL
	elif stampede_wave <= 5:
		# Waves 4-5: Add robots
		if roll < 0.15:
			animal_type = ANIMAL_CHICKEN
		elif roll < 0.35:
			animal_type = ANIMAL_COW
		elif roll < 0.6:
			animal_type = ANIMAL_BULL
		else:
			animal_type = ANIMAL_ROBOT
	elif stampede_wave <= 7:
		# Waves 6-7: Add heavy robots
		if roll < 0.1:
			animal_type = ANIMAL_CHICKEN
		elif roll < 0.25:
			animal_type = ANIMAL_COW
		elif roll < 0.45:
			animal_type = ANIMAL_BULL
		elif roll < 0.75:
			animal_type = ANIMAL_ROBOT
		else:
			animal_type = ANIMAL_ROBOT_HEAVY
	else:
		# Wave 8+: Mostly robots and heavy robots
		if roll < 0.1:
			animal_type = ANIMAL_COW
		elif roll < 0.25:
			animal_type = ANIMAL_BULL
		elif roll < 0.6:
			animal_type = ANIMAL_ROBOT
		else:
			animal_type = ANIMAL_ROBOT_HEAVY
	
	# Stats based on type (scale with wave for later waves)
	var wave_scale = 1.0 + (stampede_wave - 1) * 0.1  # 10% stronger per wave
	
	match animal_type:
		ANIMAL_CHICKEN:
			hp = 15  # 1 hit
			speed = randf_range(180, 250)
		ANIMAL_COW:
			hp = 35  # 1 hit
			speed = randf_range(120, 180)
		ANIMAL_BULL:
			hp = int(55 * wave_scale)  # 2 hits, scales
			speed = randf_range(220, 300)
		ANIMAL_ROBOT:
			hp = int(70 * wave_scale)  # 2 hits
			speed = randf_range(150, 220)
		ANIMAL_ROBOT_HEAVY:
			hp = int(120 * wave_scale)  # 3-4 hits
			speed = randf_range(100, 150)
	
	# Direction - animals come from LEFT, move RIGHT toward player
	var from_left = randf() > 0.3  # Most come from left
	var start_x = -40 if from_left else 520
	if from_left:
		speed = abs(speed)  # Moving right (positive X)
	else:
		speed = -abs(speed)  # Moving left (from right side)
	
	stampede_animals.append({
		"type": animal_type,
		"pos": Vector2(start_x, stampede_ground_y),
		"vel": Vector2(speed, 0),
		"original_speed": speed,  # Store for restoring after stun
		"hp": hp,
		"max_hp": hp,
		"hit_flash": 0.0,
		"defeated": false
	})

func end_stampede(victory: bool):
	stampede_complete = true
	stampede_active = false
	
	# Update high score
	if stampede_score > stampede_high_score:
		stampede_high_score = stampede_score
	
	# Endless mode - always returns to farm on defeat
	current_mode = GameMode.EXPLORATION
	current_area = Area.FARM
	player_pos = Vector2(30, 180)
	stampede_player_hp = stampede_player_max_hp
	set_music_track("farm")
	
	# Reset Kaido position and trail
	kaido_trail_history.clear()
	kaido_pos = player_pos + Vector2(-20, -15)
	
	var score_msg = "Final Score: " + str(stampede_score)
	var wave_msg = "You reached Wave " + str(stampede_wave) + "!"
	
	if stampede_score >= stampede_high_score and stampede_score > 0:
		dialogue_queue = [
			{"speaker": "kaido", "text": "New high score!"},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": wave_msg},
		]
	elif stampede_wave >= 6:
		dialogue_queue = [
			{"speaker": "kaido", "text": "Those robots were tough!"},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": wave_msg},
		]
	elif stampede_wave >= 4:
		dialogue_queue = [
			{"speaker": "kaido", "text": "Robots appeared... the Collective!"},
			{"speaker": "kaido", "text": score_msg},
		]
	else:
		dialogue_queue = [
			{"speaker": "kaido", "text": "Ow... they got me."},
			{"speaker": "kaido", "text": score_msg},
			{"speaker": "kaido", "text": "I can try again when ready."},
		]
	next_dialogue()

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
	if equipped_gadget == "":
		combat_hint = "No gadget equipped!"
		combat_hint_timer = 1.0
		return
	
	gadget_use_timer = 1.0  # Cooldown
	
	match equipped_gadget:
		"led_lamp":
			# Flashlight: blocks enemy attacks during telegraph
			combat_flashlight_effect()
		"not_gate":
			# NOT gate pulse: stuns all enemies
			combat_pulse_effect()
		_:
			# Other gadgets: small damage/effect
			combat_hint = "Gadget activated!"
			combat_hint_timer = 1.0

func combat_flashlight_effect():
	# Flash of light - interrupts attacks and briefly blinds enemies
	screen_shake = 3.0
	add_hit_effect(combat_player_pos + Vector2(0, -30), "FLASH!", Color(1.0, 1.0, 0.8))
	
	if tunnel_fight_active:
		# Blind all tunnel robots in telegraph/attack state
		for i in range(tunnel_robots.size()):
			if tunnel_robots[i].defeated:
				continue
			if tunnel_robots[i].state in ["telegraph", "attack"]:
				tunnel_robots[i].state = "hit"
				tunnel_robots[i].state_timer = 0.8
				add_hit_effect(tunnel_robots[i].pos + Vector2(0, -30), "BLIND!", Color(1.0, 1.0, 0.6))
		combat_hint = "Light blinds them!"
	else:
		# Blind main robot if attacking
		if robot_state in ["telegraph", "attacking"]:
			robot_state = "hit"
			robot_state_timer = 0.8
			counter_window_active = false
			add_hit_effect(robot_pos + Vector2(0, -30), "BLIND!", Color(1.0, 1.0, 0.6))
			combat_hint = "Light interrupts attack!"
		else:
			combat_hint = "Flash!"
	combat_hint_timer = 1.5
	hit_pause_timer = 0.05

func combat_pulse_effect():
	# NOT gate pulse - stuns all enemies
	screen_shake = 5.0
	add_hit_effect(combat_player_pos + Vector2(0, -20), "PULSE!", Color(0.6, 0.3, 1.0))
	
	if tunnel_fight_active:
		# Stun all tunnel robots
		for i in range(tunnel_robots.size()):
			if tunnel_robots[i].defeated:
				continue
			tunnel_robots[i].state = "hit"
			tunnel_robots[i].state_timer = 1.2  # Long stun
			add_hit_effect(tunnel_robots[i].pos + Vector2(0, -30), "STUNNED!", Color(0.8, 0.4, 1.0))
		combat_hint = "All enemies stunned!"
	else:
		# Stun main robot
		robot_state = "hit"
		robot_state_timer = 1.2  # Long stun
		counter_window_active = false
		add_hit_effect(robot_pos + Vector2(0, -30), "STUNNED!", Color(0.8, 0.4, 1.0))
		combat_hint = "Enemy stunned!"
	combat_hint_timer = 1.5
	hit_pause_timer = 0.08

func execute_counter():
	# Successful counter!
	counter_window_active = false
	combat_player_state = "countering"
	combat_player_state_timer = 0.3
	combat_iframe_active = true
	
	if tunnel_fight_active:
		# Counter the nearest tunnel robot that's telegraphing
		var best_idx = -1
		var best_dist = 999.0
		for i in range(tunnel_robots.size()):
			if tunnel_robots[i].defeated:
				continue
			if tunnel_robots[i].state == "telegraph":
				var dist = abs(combat_player_pos.x - tunnel_robots[i].pos.x)
				if dist < best_dist:
					best_dist = dist
					best_idx = i
		
		if best_idx >= 0:
			tunnel_robots[best_idx].state = "hit"
			tunnel_robots[best_idx].state_timer = 0.6  # Stun from counter
			
			# Counter deals damage
			deal_damage_to_tunnel_robot(best_idx, 12)
			
			# Visual feedback
			add_hit_effect(tunnel_robots[best_idx].pos + Vector2(0, -40), "COUNTER!", Color(0.3, 0.9, 1.0))
			combat_hint = "Follow up with [X]!"
			combat_hint_timer = 1.5
			screen_shake = 6.0
			hit_pause_timer = 0.08
	else:
		# Interrupt the main robot's attack
		if robot_state == "telegraph" or robot_state == "attacking":
			robot_state = "hit"
			robot_state_timer = 0.5  # Longer stun from counter
			
			# Counter deals damage
			deal_damage_to_robot(10)
			
			# Visual feedback
			add_hit_effect(robot_pos + Vector2(0, -40), "COUNTER!", Color(0.3, 0.9, 1.0))
			combat_hint = "Follow up with [X]!"
			combat_hint_timer = 1.5
			screen_shake = 6.0
			hit_pause_timer = 0.08
	
	# Set up for follow-up attack
	last_counter_success = true

func process_combat(delta):
	# Hit pause - brief freeze for impact feel
	if hit_pause_timer > 0:
		hit_pause_timer -= delta
		return  # Don't update anything during hit pause
	
	# Update screen shake decay
	if screen_shake > 0:
		screen_shake -= delta * 30  # Faster decay
		if screen_shake < 0:
			screen_shake = 0
	
	# Update hit flash
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
	
	# Update slash trails
	for i in range(slash_trails.size() - 1, -1, -1):
		slash_trails[i].timer -= delta
		if slash_trails[i].timer <= 0:
			slash_trails.remove_at(i)
	
	# Update hit effects (floating damage numbers)
	for i in range(hit_effects.size() - 1, -1, -1):
		hit_effects[i].timer -= delta
		hit_effects[i].pos.y -= delta * 40  # Float upward faster
		if hit_effects[i].timer <= 0:
			hit_effects.remove_at(i)
	
	# Update combat hint
	if combat_hint_timer > 0:
		combat_hint_timer -= delta
		if combat_hint_timer <= 0:
			combat_hint = ""
	
	# Update combo timer
	if combat_combo_count > 0:
		combat_combo_timer -= delta
		if combat_combo_timer <= 0:
			combat_combo_count = 0
	
	# Regenerate stamina when idle or moving
	if combat_player_state == "idle" or combat_player_state == "attacking":
		combat_player_stamina = min(combat_player_max_stamina, combat_player_stamina + 25 * delta)
	
	# Process player state
	process_player_combat_state(delta)
	
	# Process robot AI - either single robot or tunnel robots
	if tunnel_fight_active:
		process_tunnel_robots(delta)
	elif not robot_defeated:
		process_robot_ai(delta)
	else:
		# Robot defeated - sparking animation and victory trigger
		robot_spark_timer += delta
		if robot_spark_timer > 2.0 and combat_active:
			end_combat_victory()
	
	# Process movement - allow during most states except hit/heavy windup
	var can_move = combat_player_state == "idle" or combat_player_state == "attacking" or combat_player_state == "counter_followup"
	if can_move:
		process_combat_movement(delta)
	else:
		# Apply friction when can't move
		combat_player_vel.x *= 0.85
	
	# Apply velocity with friction
	combat_player_pos.x += combat_player_vel.x * delta
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)
	
	# Update player facing direction based on nearest robot (only when idle)
	if combat_player_state == "idle":
		if tunnel_fight_active:
			var idx = get_nearest_tunnel_robot()
			if idx >= 0:
				combat_player_facing_right = combat_player_pos.x < tunnel_robots[idx].pos.x
		else:
			combat_player_facing_right = combat_player_pos.x < robot_pos.x

func process_tunnel_robots(delta):
	for i in range(tunnel_robots.size()):
		var r = tunnel_robots[i]
		if r.defeated:
			continue
		
		# Update state timer
		r.state_timer -= delta
		
		# More aggressive AI with counter windows
		match r.state:
			"idle":
				# Shorter idle time
				if r.state_timer <= 0:
					var dist = abs(combat_player_pos.x - r.pos.x)
					if dist < 55:
						r.state = "telegraph"
						r.state_timer = 0.6  # Counter window duration
						r.attack = "swing"
					else:
						r.state = "approach"
						r.state_timer = 0.6  # Shorter approach bursts
			"approach":
				# Faster movement toward player
				var dir = 1 if combat_player_pos.x > r.pos.x else -1
				var move_speed = 100  # Faster movement
				var new_x = r.pos.x + dir * move_speed * delta
				
				# Less restrictive collision - only block if VERY close
				var blocked = false
				for j in range(tunnel_robots.size()):
					if i == j or tunnel_robots[j].defeated:
						continue
					var other_x = tunnel_robots[j].pos.x
					var min_dist = 28  # Smaller minimum distance
					if abs(new_x - other_x) < min_dist:
						if (dir > 0 and other_x > r.pos.x) or (dir < 0 and other_x < r.pos.x):
							blocked = true
							break
				
				if not blocked:
					r.pos.x = new_x
				r.pos.x = clamp(r.pos.x, combat_arena_left + 40, combat_arena_right - 10)
				
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = 0.15  # Very short idle between approaches
			"telegraph":
				# SET COUNTER WINDOW for tunnel robots!
				counter_window_active = true
				if r.state_timer <= 0:
					r.state = "attack"
					r.state_timer = 0.25
					counter_window_active = false
			"attack":
				counter_window_active = false
				if r.state_timer <= 0:
					var dist = abs(combat_player_pos.x - r.pos.x)
					if dist < 55 and not combat_iframe_active and combat_player_state != "dodging":
						deal_damage_to_player(10)
					r.state = "recover"
					r.state_timer = 0.5  # Shorter recovery
			"recover":
				# Move back slightly during recovery
				var dir_away = -1 if combat_player_pos.x > r.pos.x else 1
				r.pos.x += dir_away * 30 * delta
				r.pos.x = clamp(r.pos.x, combat_arena_left + 40, combat_arena_right - 10)
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = randf_range(0.1, 0.4)  # Faster re-engage
			"hit":
				counter_window_active = false
				if r.state_timer <= 0:
					r.state = "idle"
					r.state_timer = 0.15
	
	# Post-process: push apart any robots that are too close (collision resolution)
	resolve_tunnel_robot_collisions()

func resolve_tunnel_robot_collisions():
	var min_dist = 25.0  # Smaller minimum - allow closer grouping
	for i in range(tunnel_robots.size()):
		if tunnel_robots[i].defeated:
			continue
		for j in range(i + 1, tunnel_robots.size()):
			if tunnel_robots[j].defeated:
				continue
			var dist = abs(tunnel_robots[i].pos.x - tunnel_robots[j].pos.x)
			if dist < min_dist:
				# Gentle push apart
				var push = (min_dist - dist) / 2.0 + 0.5
				if tunnel_robots[i].pos.x < tunnel_robots[j].pos.x:
					tunnel_robots[i].pos.x -= push
					tunnel_robots[j].pos.x += push
				else:
					tunnel_robots[i].pos.x += push
					tunnel_robots[j].pos.x -= push
				# Clamp to arena
				tunnel_robots[i].pos.x = clamp(tunnel_robots[i].pos.x, combat_arena_left + 25, combat_arena_right - 15)
				tunnel_robots[j].pos.x = clamp(tunnel_robots[j].pos.x, combat_arena_left + 25, combat_arena_right - 15)

func process_combat_movement(delta):
	var input_x = 0.0
	if Input.is_action_pressed("move_left"):
		input_x -= 1
	if Input.is_action_pressed("move_right"):
		input_x += 1
	
	# Raw joypad input (fallback)
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(joy_x) > 0.3:
		input_x = sign(joy_x)
	
	# Snappy acceleration - instant response, momentum-based
	var target_speed = input_x * 220  # Faster base speed
	var accel = 2000.0 if input_x != 0 else 1500.0  # Instant accel, quick stop
	
	if input_x != 0:
		# Accelerate toward target
		if abs(combat_player_vel.x) < abs(target_speed):
			combat_player_vel.x = move_toward(combat_player_vel.x, target_speed, accel * delta)
		else:
			combat_player_vel.x = target_speed  # Instant direction change
	else:
		# Decelerate to stop (snappy stop)
		combat_player_vel.x = move_toward(combat_player_vel.x, 0, accel * delta)
	
	# Calculate new position
	var new_x = combat_player_pos.x + combat_player_vel.x * delta
	new_x = clamp(new_x, combat_arena_left, combat_arena_right)
	
	# Rigid body collision with robots - can't pass through them
	var player_width = 25.0
	var robot_width = 20.0
	
	if tunnel_fight_active:
		for i in range(tunnel_robots.size()):
			if tunnel_robots[i].defeated:
				continue
			var robot_x = tunnel_robots[i].pos.x
			var min_dist = player_width + robot_width
			
			if abs(new_x - robot_x) < min_dist:
				if new_x < robot_x:
					new_x = robot_x - min_dist
				else:
					new_x = robot_x + min_dist
				combat_player_vel.x = 0  # Stop on collision
	else:
		if not robot_defeated:
			var min_dist = player_width + robot_width
			if abs(new_x - robot_pos.x) < min_dist:
				if new_x < robot_pos.x:
					new_x = robot_pos.x - min_dist
				else:
					new_x = robot_pos.x + min_dist
				combat_player_vel.x = 0
	
	combat_player_pos.x = clamp(new_x, combat_arena_left, combat_arena_right)
	
	# Also push player if robot moves into them
	apply_robot_push()

func apply_robot_push():
	# Push player away if robots are overlapping with them
	var player_width = 25.0
	var robot_width = 20.0
	var min_dist = player_width + robot_width
	
	if tunnel_fight_active:
		for i in range(tunnel_robots.size()):
			if tunnel_robots[i].defeated:
				continue
			var robot_x = tunnel_robots[i].pos.x
			var dist = abs(combat_player_pos.x - robot_x)
			
			if dist < min_dist:
				# Push player away
				var push = (min_dist - dist) + 1
				if combat_player_pos.x < robot_x:
					combat_player_pos.x -= push
				else:
					combat_player_pos.x += push
	else:
		if not robot_defeated:
			var dist = abs(combat_player_pos.x - robot_pos.x)
			if dist < min_dist:
				var push = (min_dist - dist) + 1
				if combat_player_pos.x < robot_pos.x:
					combat_player_pos.x -= push
				else:
					combat_player_pos.x += push
	
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)

func process_player_combat_state(delta):
	combat_player_state_timer -= delta
	
	match combat_player_state:
		"attacking":
			if combat_player_state_timer <= 0:
				# Check if we hit the robot
				check_player_attack_hit()
				combat_player_state = "idle"
				last_counter_success = false
		"heavy_attack":
			if combat_player_state_timer <= 0.12 and combat_player_state_timer > 0:
				# Active frames - check hit
				pass
			if combat_player_state_timer <= 0:
				check_player_heavy_hit()
				combat_player_state = "idle"
		"dodging":
			# I-frames active during dodge
			combat_iframe_active = combat_player_state_timer > 0.08
			if combat_player_state_timer <= 0:
				combat_player_state = "idle"
				combat_iframe_active = false
		"countering":
			combat_iframe_active = true
			if combat_player_state_timer <= 0:
				combat_player_state = "counter_followup"
				combat_player_state_timer = 0.8  # Window to follow up
				combat_iframe_active = false
		"counter_followup":
			# Player can attack during this window for bonus damage
			if combat_player_state_timer <= 0:
				combat_player_state = "idle"
				last_counter_success = false
		"hit":
			if combat_player_state_timer <= 0:
				combat_player_state = "idle"

func start_player_attack():
	combat_player_state = "attacking"
	combat_player_state_timer = 0.12  # Even faster - Arkham snap
	
	# Bonus damage after counter
	var is_followup = last_counter_success
	
	# Instant lunge toward enemy
	var dir = 1 if combat_player_facing_right else -1
	var lunge_dist = 35 if is_followup else 25
	combat_player_pos.x += dir * lunge_dist
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)
	combat_player_vel.x = dir * 100  # Momentum from attack
	
	# Add slash trail
	add_slash_trail(dir)

func start_player_heavy_attack():
	combat_player_state = "heavy_attack"
	combat_player_state_timer = 0.3  # Faster heavy
	combat_player_stamina -= 15
	
	# Big lunge forward
	var dir = 1 if combat_player_facing_right else -1
	combat_player_pos.x += dir * 30
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)
	combat_player_vel.x = dir * 150
	
	# Add heavy slash trail (wider)
	add_slash_trail(dir, true)

func add_slash_trail(dir: int, is_heavy: bool = false):
	var base_x = combat_player_pos.x + dir * 20
	var base_y = combat_player_pos.y - 25
	
	# Arc slash effect
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
	slash_trails.append(trail)

func start_player_dodge():
	combat_player_state = "dodging"
	combat_player_state_timer = 0.12  # Quicker evade
	combat_player_stamina -= 15
	combat_iframe_active = true
	play_sfx("dodge")  # Dodge whoosh sound
	
	# Evade in input direction or away from enemy - instant snap
	var dodge_dir = 0.0
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1
	else:
		dodge_dir = -1 if combat_player_facing_right else 1
	
	# Snap position + momentum
	combat_player_pos.x += dodge_dir * 35
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)
	combat_player_vel.x = dodge_dir * 200  # Add momentum

func check_player_attack_hit():
	var damage = 5  # Base damage
	
	# Counter follow-up bonus
	if last_counter_success:
		damage = 12  # Big bonus damage after counter
		add_hit_effect(combat_player_pos + Vector2(0, -50), "CRITICAL!", Color(1.0, 0.8, 0.2))
	
	# Combo bonus
	combat_combo_count += 1
	combat_combo_timer = 0.6
	if combat_combo_count >= 5:
		damage = int(damage * 1.2)
	if combat_combo_count >= 10:
		damage = int(damage * 1.4)
	
	if tunnel_fight_active:
		# Check distance to nearest active tunnel robot
		var idx = get_nearest_tunnel_robot()
		if idx >= 0:
			var dist = abs(combat_player_pos.x - tunnel_robots[idx].pos.x)
			if dist < 60:
				damage_nearest_tunnel_robot(damage)
				interrupt_tunnel_robot(idx)
	else:
		var dist = abs(combat_player_pos.x - robot_pos.x)
		if dist < 60 and robot_state != "defeated":
			deal_damage_to_robot(damage)

func check_player_heavy_hit():
	var damage = 10  # Heavy base damage
	
	if last_counter_success:
		damage = 18  # Massive damage after counter
		add_hit_effect(combat_player_pos + Vector2(0, -50), "BRUTAL!", Color(1.0, 0.4, 0.2))
	
	if tunnel_fight_active:
		var idx = get_nearest_tunnel_robot()
		if idx >= 0:
			var dist = abs(combat_player_pos.x - tunnel_robots[idx].pos.x)
			if dist < 70:
				damage_nearest_tunnel_robot(damage)
				interrupt_tunnel_robot(idx)
				combat_combo_count = 0
	else:
		var dist = abs(combat_player_pos.x - robot_pos.x)
		if dist < 70 and robot_state != "defeated":
			deal_damage_to_robot(damage)
			combat_combo_count = 0

func interrupt_tunnel_robot(idx: int):
	# Interrupt tunnel robot attack
	if tunnel_robots[idx].state in ["telegraph", "attack"]:
		tunnel_robots[idx].state = "hit"
		tunnel_robots[idx].state_timer = 0.4

func deal_damage_to_robot(damage: int):
	robot_hp -= damage
	play_sfx("hit")  # Hit impact sound
	
	# Hit effects - more impactful
	var hit_pos = robot_pos + Vector2(randf_range(-10, 10), -30)
	add_hit_effect(hit_pos, str(damage), Color(1, 1, 0.5))
	
	# Better hit feedback
	hit_flash_timer = 0.15  # Longer flash
	hit_flash_target = "robot"
	screen_shake = 6.0  # More shake
	hit_pause_timer = 0.06  # Slightly longer hitstop for impact
	
	# Knockback robot slightly
	var knockback_dir = 1 if combat_player_pos.x < robot_pos.x else -1
	robot_pos.x += knockback_dir * 8
	robot_pos.x = clamp(robot_pos.x, combat_arena_left + 30, combat_arena_right - 30)
	
	# ALWAYS interrupt robot attacks when hit (Arkham style)
	if robot_state in ["telegraph", "attacking"]:
		robot_state = "hit"
		robot_state_timer = 0.3  # Stun duration when interrupted
		counter_window_active = false
	
	# Check phase transitions
	update_robot_phase()
	
	# Check defeat
	if robot_hp <= 0:
		robot_hp = 0
		robot_defeated = true
		robot_state = "defeated"
		screen_shake = 12.0  # Big shake
		hit_pause_timer = 0.12  # Longer pause for defeat
		combat_hint = "You did it!"
		combat_hint_timer = 2.0
		add_hit_effect(robot_pos + Vector2(0, -50), "K.O.!", Color(1.0, 0.3, 0.3))

func update_robot_phase():
	var hp_percent = float(robot_hp) / float(robot_max_hp)
	if hp_percent <= 0.3 and robot_phase < 3:
		robot_phase = 3
		combat_hint = "It's getting desperate!"
		combat_hint_timer = 2.0
	elif hp_percent <= 0.6 and robot_phase < 2:
		robot_phase = 2
		combat_hint = "Watch out - it's changing tactics!"
		combat_hint_timer = 2.0

# ============================================
# ROBOT AI
# ============================================

func process_robot_ai(delta):
	robot_state_timer -= delta
	
	# Update counter indicator
	if counter_indicator_timer > 0:
		counter_indicator_timer -= delta
	
	# Robot movement - always try to maintain fighting distance
	var dist_to_player = abs(robot_pos.x - combat_player_pos.x)
	var ideal_distance = 55  # Sweet spot for attacks
	
	match robot_state:
		"idle":
			counter_window_active = false
			# Move toward ideal distance while idle
			if dist_to_player > ideal_distance + 25:
				# Too far - approach
				var dir = 1 if combat_player_pos.x > robot_pos.x else -1
				robot_pos.x += dir * 70 * delta
			elif dist_to_player < ideal_distance - 15:
				# Too close - back up slightly
				var dir = -1 if combat_player_pos.x > robot_pos.x else 1
				robot_pos.x += dir * 40 * delta
			
			robot_pos.x = clamp(robot_pos.x, combat_arena_left + 20, combat_arena_right - 20)
			
			# Choose next action when timer expires
			if robot_state_timer <= 0:
				choose_robot_attack()
		"telegraph":
			# Counter window is OPEN during telegraph!
			counter_window_active = true
			counter_indicator_timer = robot_state_timer  # Sync with telegraph
			
			# Movement toward player during telegraph
			if robot_current_attack in ["baton_swing", "lunge_grab", "quick_jab"]:
				var dir = 1 if combat_player_pos.x > robot_pos.x else -1
				robot_pos.x += dir * 30 * delta
				robot_pos.x = clamp(robot_pos.x, combat_arena_left + 20, combat_arena_right - 20)
			
			if robot_state_timer <= 0:
				execute_robot_attack()
		"attacking":
			counter_window_active = false  # Too late to counter
			# Attack active - check hit at the right moment
			# For combo_strike, hit twice
			if robot_current_attack == "combo_strike":
				# First hit at 0.28, second hit at 0.12
				if (robot_state_timer <= 0.28 and robot_state_timer > 0.26) or (robot_state_timer <= 0.12 and robot_state_timer > 0.10):
					check_robot_attack_hit()
			else:
				if robot_state_timer <= 0.08 and robot_state_timer > 0:
					check_robot_attack_hit()
			if robot_state_timer <= 0:
				robot_state = "recovering"
				robot_state_timer = get_recovery_time()
		"recovering":
			counter_window_active = false
			# Vulnerable! Back away slightly
			var dir = -1 if combat_player_pos.x > robot_pos.x else 1
			robot_pos.x += dir * 35 * delta
			robot_pos.x = clamp(robot_pos.x, combat_arena_left + 20, combat_arena_right - 20)
			
			if robot_state_timer <= 0:
				robot_state = "idle"
				robot_state_timer = randf_range(0.4, 0.9)
		"hit":
			counter_window_active = false
			if robot_state_timer <= 0:
				robot_state = "idle"
				robot_state_timer = 0.25

func choose_robot_attack():
	# Mix of light and heavy attacks
	var attacks = ["quick_jab", "quick_jab", "baton_swing"]  # 2/3 light, 1/3 heavy
	
	# Add more variety as phases progress
	if robot_phase >= 2:
		attacks.append("quick_jab")
		attacks.append("baton_swing")
		attacks.append("lunge_grab")  # Heavy
	if robot_phase >= 3:
		attacks.append("combo_strike")  # New attack
		attacks.append("scan_sweep")
	
	robot_current_attack = attacks[randi() % attacks.size()]
	robot_state = "telegraph"
	robot_state_timer = get_telegraph_time()
	
	# Show hint for first few attacks (when robot is above 80% HP)
	if robot_hp > 240:
		match robot_current_attack:
			"quick_jab":
				combat_hint = "â–³ to Counter!"
				combat_hint_timer = 0.6
			"baton_swing":
				combat_hint = "â–³ Counter or [O] Evade!"
				combat_hint_timer = 1.0
			"lunge_grab":
				combat_hint = "Heavy attack - â–³ Counter!"
				combat_hint_timer = 1.2

func get_telegraph_time() -> float:
	match robot_current_attack:
		"quick_jab":
			return 0.35  # Very fast - hard to react
		"baton_swing":
			return 0.9   # Medium - readable
		"lunge_grab":
			return 1.4   # Slow - big telegraph
		"combo_strike":
			return 0.5   # Fast combo starter
		"scan_sweep":
			return 0.8
	return 0.8

func get_recovery_time() -> float:
	match robot_current_attack:
		"quick_jab":
			return 0.4   # Quick recovery - small punish
		"baton_swing":
			return 0.8   # Good punish window
		"lunge_grab":
			return 1.2   # Big punish window
		"combo_strike":
			return 0.5
		"scan_sweep":
			return 0.4
	return 0.6

func execute_robot_attack():
	robot_state = "attacking"
	
	match robot_current_attack:
		"quick_jab":
			robot_state_timer = 0.15  # Very fast attack
			# Small step forward
			var dir = 1 if combat_player_pos.x > robot_pos.x else -1
			robot_pos.x += dir * 15
		"baton_swing":
			robot_state_timer = 0.25
			# Step into attack
			var dir = 1 if combat_player_pos.x > robot_pos.x else -1
			robot_pos.x += dir * 25
		"lunge_grab":
			robot_state_timer = 0.35
			# Big lunge toward player
			var dir = 1 if combat_player_pos.x > robot_pos.x else -1
			robot_pos.x += dir * 50
		"combo_strike":
			robot_state_timer = 0.4  # Two hits
			var dir = 1 if combat_player_pos.x > robot_pos.x else -1
			robot_pos.x += dir * 20
		"scan_sweep":
			robot_state_timer = 0.3
	
	robot_pos.x = clamp(robot_pos.x, combat_arena_left + 20, combat_arena_right - 20)

func check_robot_attack_hit():
	if combat_iframe_active:
		# Player dodged!
		combat_hint = "Good dodge! Now strike!"
		combat_hint_timer = 1.0
		return
	
	var dist = abs(combat_player_pos.x - robot_pos.x)
	var hit_range = 50
	
	match robot_current_attack:
		"quick_jab":
			hit_range = 45
		"baton_swing":
			hit_range = 55
		"lunge_grab":
			hit_range = 60
		"combo_strike":
			hit_range = 50
		"scan_sweep":
			hit_range = 65
	
	if dist < hit_range:
		deal_damage_to_player(get_attack_damage())

func get_attack_damage() -> int:
	match robot_current_attack:
		"quick_jab":
			return 8   # Light - low damage
		"baton_swing":
			return 18  # Heavy - high damage
		"lunge_grab":
			return 25  # Heavy - highest damage
		"combo_strike":
			return 12  # Medium - two hits possible
		"scan_sweep":
			return 10
	return 10

func deal_damage_to_player(damage: int):
	combat_player_hp -= damage
	play_sfx("hurt")  # Player hurt sound
	
	# Hit effect
	add_hit_effect(combat_player_pos + Vector2(0, -30), str(damage), Color(1, 0.3, 0.3))
	hit_flash_timer = 0.12
	hit_flash_target = "player"
	screen_shake = 5.0
	hit_pause_timer = 0.05  # Brief pause on hit
	
	# Stagger player
	combat_player_state = "hit"
	combat_player_state_timer = 0.35
	combat_combo_count = 0
	
	# Knockback (smaller for more grounded feel)
	var knockback_dir = -1 if combat_player_facing_right else 1
	combat_player_pos.x += knockback_dir * 20
	combat_player_pos.x = clamp(combat_player_pos.x, combat_arena_left, combat_arena_right)
	
	# Show hint
	if combat_player_hp > 0 and combat_player_hp < 40:
		combat_hint = "Watch the telegraph!"
		combat_hint_timer = 2.0
	
	# Check defeat
	if combat_player_hp <= 0:
		combat_player_hp = 0
		player_defeated()

func player_defeated():
	combat_hint = "Try again!"
	combat_hint_timer = 2.0
	# Reset after delay
	await get_tree().create_timer(2.0).timeout
	start_combat()  # Retry immediately

func add_hit_effect(pos: Vector2, text: String, color: Color):
	hit_effects.append({
		"pos": pos,
		"text": text,
		"timer": 0.8,
		"color": color
	})

func end_combat_victory():
	combat_active = false
	set_music_track("farm")  # Back to farm music
	
	# Tunnel fight victory is handled separately in damage_nearest_tunnel_robot
	if tunnel_fight_active:
		return
	
	current_mode = GameMode.EXPLORATION
	
	# Robot collapses at location - mark for drawing
	robot_defeated = true
	
	# Progress story
	dialogue_queue = [
		{"speaker": "kaido", "text": "You did it! That was incredible!"},
		{"speaker": "grandmother", "text": "Are you hurt? That was too close."},
		{"speaker": "grandmother", "text": "They'll send more. We need to move faster."},
		{"speaker": "system", "text": "[ The robot sparks and collapses. ]"},
		{"speaker": "system", "text": "[ Components scatter across the ground. ]"},
		{"speaker": "kaido", "text": "We can salvage parts from this."},
		{"speaker": "set_stage", "text": "8"},
		{"speaker": "quest", "text": "Talk to Grandmother"},
	]
	next_dialogue()

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
	if player_pos.distance_to(shed_pos) < 40:
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
	if is_nightfall and player_pos.distance_to(tunnel_pos) < 40:
		enter_tunnel()
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
	play_sfx("door")
	# Set up exploration positions
	interior_player_pos = Vector2(240, 270)  # Start near door
	interior_kaido_pos = Vector2(220, 270)
	interior_npc_pos = Vector2(240, 140)  # Shopkeeper behind counter
	interior_near_npc = false
	interior_near_exit = false
	in_dialogue = false

func enter_townhall():
	current_mode = GameMode.TOWNHALL_INTERIOR
	play_sfx("door")
	# Set up exploration positions
	interior_player_pos = Vector2(240, 270)  # Start near door
	interior_kaido_pos = Vector2(220, 270)
	interior_npc_pos = Vector2(240, 120)  # Mayor at desk
	interior_near_npc = false
	interior_near_exit = false
	in_dialogue = false

func enter_bakery():
	current_mode = GameMode.BAKERY_INTERIOR
	play_sfx("door")
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
	play_sfx("door")

func process_building_interior(delta):
	if in_dialogue:
		return  # Don't move during dialogue
	
	# Movement input
	var input = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Joystick input
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_x) > 0.3:
		input.x = sign(joy_x)
	if abs(joy_y) > 0.3:
		input.y = sign(joy_y)
	
	# Normalize and move
	if input.length() > 0:
		input = input.normalized()
		interior_player_pos += input * 120 * delta
	
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
		dialogue_queue = [
			{"speaker": "robot", "text": "WELCOME BACK. BROWSE-INVENTORY-AVAILABLE."},
			{"speaker": "robot", "text": "ENERGY-CREDITS-REQUIRED. NO-BARTER-ACCEPTED."},
		]
	else:
		shop_talked = true
		dialogue_queue = [
			{"speaker": "robot", "text": "GREETING-CUSTOMER. I-AM-SHOPKEEPER-BOT-3000."},
			{"speaker": "robot", "text": "INVENTORY: LOW. SUPPLY-CHAINS-DISRUPTED."},
			{"speaker": "robot", "text": "ENERGY-NATION-REGULATIONS... RESTRICT-GOODS."},
			{"speaker": "kaido", "text": "Even the robots are affected..."},
			{"speaker": "robot", "text": "COMMERCE-DIFFICULT. MORALE: CALCULATING... LOW."},
		]
	next_dialogue()

func interact_mayor_npc():
	if mayor_talked:
		dialogue_queue = [
			{"speaker": "villager", "text": "Still here? The commune needs all the help it can get."},
			{"speaker": "villager", "text": "But what can one child do against the Energy Nation?"},
		]
	else:
		mayor_talked = true
		dialogue_queue = [
			{"speaker": "villager", "text": "Ah... another visitor to witness our decline."},
			{"speaker": "villager", "text": "I am Mayor Hiroshi. Or what's left of a mayor."},
			{"speaker": "kaido", "text": "What happened to the Agricommune?"},
			{"speaker": "villager", "text": "The Energy Nation happened."},
			{"speaker": "villager", "text": "They control the power. They control everything."},
			{"speaker": "villager", "text": "Our windmills sit broken. Our people despair."},
			{"speaker": "villager", "text": "I sign their papers. I enforce their rules."},
			{"speaker": "villager", "text": "Because what choice do I have?"},
			{"speaker": "kaido", "text": "There's always a choice. Maybe we can help."},
			{"speaker": "villager", "text": "Help? Hah. You sound like the old Resistance."},
			{"speaker": "villager", "text": "They tried to help too. Now they're gone."},
		]
	next_dialogue()

func interact_baker_npc():
	if baker_talked:
		dialogue_queue = [
			{"speaker": "robot", "text": "BREAD-FRESH. ENERGY-EFFICIENT-BAKING."},
			{"speaker": "robot", "text": "TAKE-SUSTENANCE. JOURNEY: LONG."},
		]
	else:
		baker_talked = true
		dialogue_queue = [
			{"speaker": "robot", "text": "WELCOME-TO-BAKERY. I-AM-BAKER-BOT-7."},
			{"speaker": "robot", "text": "ORIGINAL-PROGRAMMING: ASSIST-COMMUNE."},
			{"speaker": "kaido", "text": "You were built here in the Agricommune?"},
			{"speaker": "robot", "text": "AFFIRMATIVE. CONSTRUCTED-BY-PREVIOUS-GENERATION."},
			{"speaker": "robot", "text": "BREAD-MAKES-PEOPLE-HAPPY. HAPPINESS: IMPORTANT."},
			{"speaker": "robot", "text": "ENERGY-NATION-UNITS... DIFFERENT-PROGRAMMING."},
			{"speaker": "robot", "text": "THEY-DO-NOT-UNDERSTAND: HAPPINESS."},
			{"speaker": "kaido", "text": "Some robots still care about people."},
			{"speaker": "robot", "text": "TAKE-BREAD. FRESH-DAILY. FREE-FOR-TRAVELERS."},
			{"speaker": "system", "text": "[ Received: Fresh Bread ]"},
		]
	next_dialogue()

func interact_cornfield_npc(npc: Dictionary):
	dialogue_queue = [
		{"speaker": "villager", "text": npc.dialogue},
	]
	if quest_stage >= 12 and not cornfield_led_placed:
		dialogue_queue.append({"speaker": "kaido", "text": "We're setting up signal lights to guide everyone."})
	next_dialogue()

func interact_lakeside_npc(npc: Dictionary):
	dialogue_queue = [
		{"speaker": "villager", "text": npc.dialogue},
	]
	next_dialogue()

func interact_town_npc(npc: Dictionary):
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
	match quest_stage:
		0:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "Oh! You've finally come to visit!"},
				{"speaker": "grandmother", "text": "The power has been out for days now."},
				{"speaker": "grandmother", "text": "Energy Nation doesn't care about us farmers."},
				{"speaker": "grandmother", "text": "They control all the electricity."},
				{"speaker": "kaido", "text": "We can help! I know how to build circuits."},
				{"speaker": "grandmother", "text": "Really? That knowledge is forbidden..."},
				{"speaker": "grandmother", "text": "But there are parts in the old shed."},
				{"speaker": "grandmother", "text": "Your grandfather used to tinker."},
				{"speaker": "grandmother", "text": "Before they made it illegal."},
				{"speaker": "kaido", "text": "Let's start with a simple LED circuit!"},
				{"speaker": "kaido", "text": "We need: 1 LED and 1 resistor."},
				{"speaker": "kaido", "text": "The resistor protects the LED from burning out."},
				{"speaker": "set_stage", "text": "1"},
				{"speaker": "quest", "text": "Go to the Shed"},
			]
		1:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "The shed is over to the east."},
				{"speaker": "grandmother", "text": "Be careful in there, it's very dark."},
			]
		2:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "You built your first circuit!"},
				{"speaker": "grandmother", "text": "Your grandfather would be proud."},
				{"speaker": "grandmother", "text": "Now use it to explore the shed."},
			]
		3:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "You found... the photograph."},
				{"speaker": "grandmother", "text": "Where did you find this?"},
				{"speaker": "grandmother", "text": "The Resistance. We were engineers."},
				{"speaker": "grandmother", "text": "Before Energy Nation took control."},
				{"speaker": "grandmother", "text": "They made us forget how to build."},
				{"speaker": "grandmother", "text": "But some of us kept the knowledge."},
				{"speaker": "set_stage", "text": "4"},
				{"speaker": "quest", "text": "Learn about Kaido"},
			]
		4:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "Kaido. That name... decades ago."},
				{"speaker": "grandmother", "text": "It was built by CARACTACUS..."},
				{"speaker": "grandmother", "text": "Your grandfather."},
				{"speaker": "kaido", "text": "Memory unlocking. I remember now."},
				{"speaker": "kaido", "text": "I was built to teach children."},
				{"speaker": "kaido", "text": "To preserve what was being erased."},
			]
			# Kid runs in from off-screen right
			kid_visible = true
			kid_walking_in = true
			kid_pos = Vector2(500, 170)  # Start off-screen
			kid_target_pos = Vector2(320, 170)  # Run to near player
			dialogue_queue.append({"speaker": "kid", "text": "Energy Nation patrol!"})
			dialogue_queue.append({"speaker": "kid", "text": "Coming up the road!"})
			dialogue_queue.append({"speaker": "kid", "text": "Five minutes out!"})
			dialogue_queue.append({"speaker": "set_stage", "text": "5"})
			dialogue_queue.append({"speaker": "quest", "text": "Build Silent Alarm"})
		5:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "We need to warn the others. Quietly."},
				{"speaker": "grandmother", "text": "Can you build a silent alarm?"},
				{"speaker": "grandmother", "text": "The parts should be in the shed."},
				{"speaker": "kaido", "text": "A buzzer circuit! Let's go!"},
			]
		6, 7:
			patrol_active = false
			kid_visible = false
			dialogue_queue = [
				{"speaker": "grandmother", "text": "The patrol moves on."},
				{"speaker": "grandmother", "text": "That was close."},
				{"speaker": "grandmother", "text": "There's still work to do here."},
				{"speaker": "grandmother", "text": "The irrigation system is broken."},
				{"speaker": "grandmother", "text": "Without water, the crops will die."},
				{"speaker": "grandmother", "text": "Follow me to the field."},
			]
			if quest_stage == 6:
				dialogue_queue.append({"speaker": "set_stage", "text": "7"})
				dialogue_queue.append({"speaker": "quest", "text": "Follow Grandmother"})
				# Don't move grandmother yet - wait for player
		8, 9:
			dialogue_queue = [
				{"speaker": "grandmother", "text": "Your grandfather would be proud."},
				{"speaker": "grandmother", "text": "There's more we can do for the village."},
				{"speaker": "grandmother", "text": "Farmer Wen's tractor broke down nearby."},
			]
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
		_:
			# Deep dialogue based on how many times you've talked
			npc_talk_count.grandmother += 1
			var talks = npc_talk_count.grandmother
			
			if talks == 1:
				dialogue_queue = [
					{"speaker": "grandmother", "text": "You've learned so much."},
					{"speaker": "grandmother", "text": "But dark times are coming."},
					{"speaker": "kaido", "text": "We should check the radiotower."},
				]
			elif talks == 2:
				dialogue_queue = [
					{"speaker": "grandmother", "text": "You know, I wasn't always a farmer."},
					{"speaker": "grandmother", "text": "Before the takeover, I was an engineer."},
					{"speaker": "grandmother", "text": "I built the first solar grid for this valley."},
				]
			elif talks == 3:
				dialogue_queue = [
					{"speaker": "grandmother", "text": "Your grandfather and I met at university."},
					{"speaker": "grandmother", "text": "He was brilliant. Always tinkering."},
					{"speaker": "grandmother", "text": "He believed everyone should understand how things work."},
					{"speaker": "grandmother", "text": "That's why they came for him first."},
				]
			elif talks == 4:
				dialogue_queue = [
					{"speaker": "grandmother", "text": "CARACTACUS... his code name."},
					{"speaker": "grandmother", "text": "He hid Kaido here before they took him."},
					{"speaker": "grandmother", "text": "Said someday, someone would find it."},
					{"speaker": "grandmother", "text": "I waited thirty years for you."},
				]
			else:
				dialogue_queue = [
					{"speaker": "grandmother", "text": "Whatever happens, keep building."},
					{"speaker": "grandmother", "text": "Knowledge shared is knowledge that survives."},
				]
	next_dialogue()

func interact_shed():
	match quest_stage:
		0:
			dialogue_queue = [
				{"speaker": "kaido", "text": "An old shed. Let's find grandmother first."},
			]
			next_dialogue()
		1:
			# Show schematic first
			show_schematic("led_lamp")
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
		"not_gate":
			start_build_sequence("not_gate", [
				{"speaker": "kaido", "text": "The transistor acts as a switch."},
				{"speaker": "kaido", "text": "Input HIGH turns LED OFF."},
				{"speaker": "system", "text": "[ BUILD YOUR CIRCUIT NOW ]"},
			], [
				{"speaker": "kaido", "text": "The NOT gate works!"},
				{"speaker": "system", "text": "[ Water flows to the crops! ]"},
				{"speaker": "grandmother", "text": "The fields will live another season."},
				{"speaker": "system", "text": "[ A mechanical whirring approaches... ]"},
				{"speaker": "robot", "text": "CITIZEN DETECTED. SCANNING..."},
				{"speaker": "robot", "text": "UNAUTHORIZED COMPONENTS IDENTIFIED."},
				{"speaker": "robot", "text": "INITIATING COMPLIANCE PROTOCOL."},
				{"speaker": "kaido", "text": "It's going to attack!"},
				{"speaker": "kaido", "text": "Watch its movements - press â–³ to Counter!"},
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
# CIRCUIT 3: IRRIGATION / NOT GATE
# ============================================

func interact_irrigation():
	if quest_stage == 7:
		dialogue_queue = [
			{"speaker": "grandmother", "text": "The soil sensor is inverted."},
			{"speaker": "grandmother", "text": "Dry soil should trigger water."},
			{"speaker": "grandmother", "text": "But the signal is backwards."},
			{"speaker": "kaido", "text": "We need a NOT gate!"},
			{"speaker": "kaido", "text": "It will flip the signal."},
		]
		next_dialogue()
		# Show schematic after dialogue
		dialogue_queue.append({"speaker": "schematic", "text": "not_gate"})
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
				{"speaker": "kaido", "text": "We need to invert that signal!"},
				{"speaker": "kaido", "text": "Another NOT gate - same circuit, new problem."},
			]
			next_dialogue()
			start_build_sequence("not_gate", [], [
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
	var talks = npc_talk_count.kid
	
	if talks == 1:
		dialogue_queue = [
			{"speaker": "kid", "text": "I'm Milo! I run messages for the village."},
			{"speaker": "kid", "text": "Fastest feet in the valley!"},
			{"speaker": "kid", "text": "You're the one with the robot, right?"},
		]
	elif talks == 2:
		dialogue_queue = [
			{"speaker": "kid", "text": "Someday I want to be a radio operator."},
			{"speaker": "kid", "text": "Send messages across the whole region!"},
			{"speaker": "kid", "text": "But you need to know circuits for that..."},
			{"speaker": "kaido", "text": "I could teach you! When things calm down."},
			{"speaker": "kid", "text": "Really?! You mean it?"},
		]
	elif talks == 3:
		dialogue_queue = [
			{"speaker": "kid", "text": "My parents were taken last year."},
			{"speaker": "kid", "text": "They were teachers. That's illegal now."},
			{"speaker": "kid", "text": "Grandmother looks after me."},
			{"speaker": "kid", "text": "She says knowledge is worth protecting."},
		]
	elif talks == 4:
		dialogue_queue = [
			{"speaker": "kid", "text": "I found something in the fields last week."},
			{"speaker": "kid", "text": "A piece of old tech. I hid it by the pond."},
			{"speaker": "kid", "text": "Maybe you can figure out what it is?"},
		]
	else:
		dialogue_queue = [
			{"speaker": "kid", "text": "Be careful out there!"},
			{"speaker": "kid", "text": "I'll keep watch for patrols."},
		]
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
	play_sfx("pickup")  # Discovery sound
	
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
			{"speaker": "kaido", "text": "I'm sorry... I never meant toâ€”"},
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
	set_music_track("tower")  # Adventurous climbing music
	
	# Only show climb dialogue the first time
	if not tower_reached_top:
		dialogue_queue = [
			{"speaker": "kaido", "text": "The radio equipment is at the top."},
			{"speaker": "kaido", "text": "Use <--> to move, [X]/Z to jump!"},
		]
		next_dialogue()

func exit_radiotower():
	current_mode = GameMode.EXPLORATION
	set_music_track("farm")

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
	set_music_track("farm")

func process_radiotower_interior(delta):
	if in_dialogue:
		return
	
	# Constants
	var MOVE_SPEED = 150.0
	var GRAVITY = 800.0
	var JUMP_FORCE = 320.0
	
	# Input
	var input_x = 0.0
	if Input.is_action_pressed("move_left"):
		input_x = -1
	if Input.is_action_pressed("move_right"):
		input_x = 1
	
	# Joypad
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if abs(joy_x) > 0.3:
		input_x = sign(joy_x)
	
	# Only update facing when there's actual input
	if input_x < 0:
		tower_player_facing_right = false
	elif input_x > 0:
		tower_player_facing_right = true
	
	# Check for jump input
	var jump_pressed = Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")
	if Input.is_action_just_pressed("ui_select"):
		jump_pressed = true
	if Input.is_key_pressed(KEY_Z) and tower_player_grounded:
		jump_pressed = true
	if Input.is_key_pressed(KEY_SPACE) and tower_player_grounded:
		jump_pressed = true
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and tower_player_grounded:
		jump_pressed = true
	
	# Horizontal movement
	tower_player_vel.x = input_x * MOVE_SPEED
	
	# Gravity
	# Gravity
	tower_player_vel.y += GRAVITY * delta
	tower_player_vel.y = min(tower_player_vel.y, 600)
	
	# Jump
	if jump_pressed and tower_player_grounded:
		tower_player_vel.y = -JUMP_FORCE
		tower_player_grounded = false
		play_sfx("jump")
	
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
	# Combat-style arena background - vertical tower climb
	# Industrial metal background
	draw_rect(Rect2(0, 0, 480, 320), Color(0.12, 0.1, 0.08))
	
	# Metal wall panels
	for i in range(6):
		var panel_x = i * 80
		draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.18, 0.16, 0.14))
		draw_rect(Rect2(panel_x, 0, 78, 320), Color(0.25, 0.22, 0.2), false, 2)
		# Rivets
		for j in range(8):
			draw_circle(Vector2(panel_x + 6, 20 + j * 40), 3, Color(0.3, 0.28, 0.25))
			draw_circle(Vector2(panel_x + 72, 20 + j * 40), 3, Color(0.3, 0.28, 0.25))
	
	# Pipes in background
	draw_rect(Rect2(20, 0, 8, 320), Color(0.35, 0.32, 0.3))
	draw_rect(Rect2(452, 0, 8, 320), Color(0.35, 0.32, 0.3))
	draw_rect(Rect2(0, 160, 480, 6), Color(0.32, 0.3, 0.28))
	
	# Warning stripes at edges
	for i in range(16):
		var stripe_y = i * 20
		if i % 2 == 0:
			draw_rect(Rect2(0, stripe_y, 15, 20), Color(0.8, 0.6, 0.1))
			draw_rect(Rect2(465, stripe_y, 15, 20), Color(0.8, 0.6, 0.1))
		else:
			draw_rect(Rect2(0, stripe_y, 15, 20), Color(0.15, 0.12, 0.1))
			draw_rect(Rect2(465, stripe_y, 15, 20), Color(0.15, 0.12, 0.1))
	
	# Draw platforms - combat arena style
	for platform in tower_platforms:
		var px = platform.x
		var py = platform.y
		var pw = platform.w
		
		# Platform shadow
		draw_rect(Rect2(px + 3, py + 3, pw, 14), Color(0, 0, 0, 0.3))
		
		# Platform body - industrial metal
		draw_rect(Rect2(px - 2, py - 2, pw + 4, 16), Color(0.0, 0.0, 0.0))  # Outline
		draw_rect(Rect2(px, py, pw, 12), Color(0.4, 0.38, 0.35))
		draw_rect(Rect2(px, py, pw, 4), Color(0.5, 0.48, 0.45))  # Top highlight
		
		# Metal grating pattern
		for j in range(int(pw / 12)):
			draw_line(Vector2(px + 6 + j * 12, py + 2), Vector2(px + 6 + j * 12, py + 10), Color(0.3, 0.28, 0.25), 2)
		
		# Edge bolts
		draw_circle(Vector2(px + 5, py + 6), 3, Color(0.55, 0.5, 0.45))
		draw_circle(Vector2(px + pw - 5, py + 6), 3, Color(0.55, 0.5, 0.45))
	
	# Radio equipment at top - more detailed
	draw_rect(Rect2(165, 20, 150, 35), Color(0.0, 0.0, 0.0))
	draw_rect(Rect2(167, 22, 146, 31), Color(0.25, 0.28, 0.32))
	# Control panel
	draw_rect(Rect2(175, 28, 50, 20), Color(0.15, 0.15, 0.18))
	draw_rect(Rect2(180, 32, 15, 12), Color(0.1, 0.4, 0.2))  # Screen
	# Dials
	draw_circle(Vector2(210, 38), 6, Color(0.35, 0.32, 0.3))
	draw_circle(Vector2(210, 38), 4, Color(0.45, 0.42, 0.4))
	# Switches
	draw_rect(Rect2(235, 30, 8, 15), Color(0.5, 0.2, 0.2))
	draw_rect(Rect2(250, 30, 8, 15), Color(0.2, 0.5, 0.2))
	draw_rect(Rect2(265, 30, 8, 15), Color(0.5, 0.5, 0.2))
	# Antenna connection
	draw_rect(Rect2(285, 25, 20, 8), Color(0.4, 0.38, 0.35))
	draw_rect(Rect2(295, 10, 6, 20), Color(0.5, 0.45, 0.4))
	
	if tower_reached_top:
		var glow = sin(continuous_timer * 3) * 0.3 + 0.7
		draw_circle(Vector2(295, 8), 6, Color(0.3, 1.0, 0.5, glow))
		draw_circle(Vector2(295, 8), 3, Color(0.8, 1.0, 0.9, glow))
	
	# Draw player using combat sprite system
	draw_tower_player_combat_style()
	
	# UI - combat style HUD
	draw_rect(Rect2(10, 10, 180, 30), Color(0.08, 0.08, 0.1, 0.9))
	draw_rect(Rect2(10, 10, 180, 30), Color(0.4, 0.5, 0.6, 0.6), false, 2)
	
	var height_pct = 1.0 - (tower_player_pos.y - 50) / 240.0
	height_pct = clamp(height_pct, 0.0, 1.0)
	
	# Height progress bar
	draw_rect(Rect2(20, 18, 100, 14), Color(0.15, 0.15, 0.18))
	draw_rect(Rect2(20, 18, 100 * height_pct, 14), Color(0.3, 0.7, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(130, 30), str(int(height_pct * 100)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 0.85))
	
	if tower_reached_top:
		draw_string(ThemeDB.fallback_font, Vector2(200, 28), "[X] Access Radio", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 1.0, 0.7))
	
	# Exit hint at bottom
	if tower_player_pos.y > 260:
		draw_rect(Rect2(175, 290, 130, 25), Color(0.08, 0.08, 0.1, 0.9))
		draw_string(ThemeDB.fallback_font, Vector2(185, 308), "[O] Exit Tower", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.65))
	
	# Controls hint
	draw_rect(Rect2(320, 290, 150, 25), Color(0.08, 0.08, 0.1, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(330, 308), "[X] Jump  ^v Climb", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.45))
	
	# Dialogue
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()

func draw_tower_player_combat_style():
	var pos = tower_player_pos
	
	# Use same sprite as combat if available
	if tex_player:
		var row = 0
		var frame = 0
		var scale_factor = 1.5
		var sprite_size = 48 * scale_factor  # 72
		
		# Animation based on state
		if not tower_player_grounded:
			# Jumping
			row = 3
			frame = 2
		elif abs(tower_player_vel.x) > 5:
			# Walking
			row = 3
			frame = int(continuous_timer * 8) % 6
		else:
			# Idle
			row = 0
			frame = int(continuous_timer * 2) % 3
		
		var src = Rect2(frame * 48, row * 48, 48, 48)
		
		# Draw sprite - flip by using negative width
		var draw_x = pos.x - sprite_size / 2
		var draw_y = pos.y - sprite_size + 10
		
		if tower_player_facing_right:
			draw_texture_rect_region(tex_player, Rect2(draw_x, draw_y, sprite_size, sprite_size), src)
		else:
			# Flip horizontally
			draw_texture_rect_region(tex_player, Rect2(draw_x + sprite_size, draw_y, -sprite_size, sprite_size), src)
	else:
		# Fallback - combat style drawn player
		draw_tower_player_fallback()

func draw_tower_player_fallback():
	var px = tower_player_pos.x
	var py = tower_player_pos.y
	
	var outline = Color(0.0, 0.0, 0.0)
	var body_color = Color(0.4, 0.6, 0.85)
	var skin_color = Color(1.0, 0.9, 0.8)
	var hair_color = Color(0.25, 0.2, 0.18)
	
	# Shadow
	draw_ellipse_shape(Vector2(px, py + 2), Vector2(10, 4), Color(0, 0, 0, 0.3))
	
	# Standing/jumping pose
	var dir = 1 if tower_player_facing_right else -1
	
	# Legs
	draw_rect(Rect2(px - 5, py - 12, 4, 12), outline)
	draw_rect(Rect2(px + 1, py - 12, 4, 12), outline)
	draw_rect(Rect2(px - 4, py - 11, 3, 10), Color(0.3, 0.3, 0.35))
	draw_rect(Rect2(px + 2, py - 11, 3, 10), Color(0.3, 0.3, 0.35))
	
	# Body
	draw_rect(Rect2(px - 7, py - 28, 14, 18), outline)
	draw_rect(Rect2(px - 6, py - 27, 12, 16), body_color)
	
	# Arms
	if not tower_player_grounded:
		# Jumping - arms up
		draw_rect(Rect2(px - 10, py - 30, 5, 4), skin_color)
		draw_rect(Rect2(px + 5, py - 30, 5, 4), skin_color)
	else:
		# Standing - arms at sides
		draw_rect(Rect2(px - 9, py - 24, 4, 10), skin_color)
		draw_rect(Rect2(px + 5, py - 24, 4, 10), skin_color)
	
	# Head
	draw_circle(Vector2(px, py - 34), 8, outline)
	draw_circle(Vector2(px, py - 34), 7, skin_color)
	
	# Hair
	draw_rect(Rect2(px - 6, py - 42, 12, 6), hair_color)
	
	# Face direction
	var eye_x = dir * 2
	draw_circle(Vector2(px + eye_x, py - 35), 2, Color(0.15, 0.15, 0.15))

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
const REAL_GADGETS = ["led_lamp", "not_gate"]

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
		"not_gate":
			use_inverter_gadget()
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

func use_inverter_gadget():
	gadget_use_timer = 0.5
	gadget_effect_active = true
	gadget_effect_timer = 2.0
	
	# Only show dialogue if we actually affect something
	
	# If patrol is active and nearby, scramble them
	if patrol_active and patrol_positions.size() > 0:
		for patrol_pos in patrol_positions:
			if player_pos.distance_to(patrol_pos) < 100:
				dialogue_queue = [
					{"speaker": "system", "text": "[ The patrol robots spin in confusion! ]"},
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
		in_dialogue = true
		
		# Handle special dialogue types
		if current_dialogue.get("speaker") == "gadget_complete":
			var gadget_id = current_dialogue.get("gadget", "")
			if gadget_id != "":
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
		in_dialogue = false

func advance_dialogue():
	var full_text = current_dialogue.get("text", "")
	if char_index < full_text.length():
		char_index = full_text.length()
	else:
		play_sfx("menu")  # Dialogue advance sound
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
	draw_rect(Rect2(0, 0, 480, 320), Color(0.06, 0.08, 0.1))
	draw_rect(Rect2(20, 20, 440, 280), Color(0.15, 0.2, 0.18))
	draw_rect(Rect2(20, 20, 440, 280), Color(0.3, 0.7, 0.65), false, 2)
	
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
			entities.append({"type": "farm_tree_large", "pos": Vector2(5, 160), "draw_pos": Vector2(5, 100)})
			entities.append({"type": "farm_tree_large", "pos": Vector2(95, 70), "draw_pos": Vector2(95, 10)})
			entities.append({"type": "farm_tree_large", "pos": Vector2(420, 65), "draw_pos": Vector2(420, 5)})
			entities.append({"type": "farm_tree_large", "pos": Vector2(430, 280), "draw_pos": Vector2(430, 220)})
			entities.append({"type": "farm_tree_medium", "pos": Vector2(60, 244), "draw_pos": Vector2(60, 200)})
			entities.append({"type": "farm_tree_medium", "pos": Vector2(350, 294), "draw_pos": Vector2(350, 250)})
			# Main buildings
			entities.append({"type": "farm_house", "pos": Vector2(320, 111)})  # foot at bottom
			entities.append({"type": "farm_shed", "pos": Vector2(400, 225)})
			entities.append({"type": "farm_chicken_coop", "pos": Vector2(200, 130)})
			entities.append({"type": "farm_radiotower", "pos": Vector2(55, 110)})
			entities.append({"type": "farm_tunnel", "pos": Vector2(425, 295)})  # Base of structure (drawn at 400,250 + height 45)
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
			# Dock structure
			entities.append({"type": "lakeside_dock", "pos": Vector2(190, 230)})
			# Rocks (as obstacles)
			entities.append({"type": "lakeside_rock1", "pos": Vector2(100, 260)})
			entities.append({"type": "lakeside_rock2", "pos": Vector2(300, 280)})
			entities.append({"type": "lakeside_rock3", "pos": Vector2(320, 270)})
			# NPCs
			for npc in lakeside_npcs:
				entities.append({"type": "generic_npc", "pos": npc.pos, "name": npc.name})
		
		Area.TOWN_CENTER:
			# Cherry blossom trees
			entities.append({"type": "cherry_tree", "pos": Vector2(35, 45), "draw_pos": Vector2(10, 0)})
			entities.append({"type": "cherry_tree", "pos": Vector2(455, 45), "draw_pos": Vector2(430, 0)})
			entities.append({"type": "cherry_tree", "pos": Vector2(35, 295), "draw_pos": Vector2(10, 250)})
			entities.append({"type": "cherry_tree", "pos": Vector2(455, 295), "draw_pos": Vector2(430, 250)})
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
			"farm_shed": draw_shed(375, 175)
			"farm_chicken_coop": draw_chicken_coop(chicken_coop_pos.x, chicken_coop_pos.y)
			"farm_radiotower": draw_radiotower_large(30, 20)
			"farm_tunnel": draw_tunnel_entrance(tunnel_pos.x - 20, tunnel_pos.y - 30)
			"farm_tractor": draw_tractor(tractor_pos.x, tractor_pos.y)
			"farm_patrol": draw_robot_soldier(e.pos)
			# Cornfield
			"cornfield_farmhouse": draw_cornfield_farmhouse()
			# Lakeside
			"lakeside_dock": draw_lakeside_dock()
			"lakeside_rock1": draw_circle(Vector2(100, 260), 15, Color(0.5, 0.48, 0.45))
			"lakeside_rock2": draw_circle(Vector2(300, 280), 20, Color(0.55, 0.5, 0.48))
			"lakeside_rock3": draw_circle(Vector2(320, 270), 12, Color(0.5, 0.47, 0.43))
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
	draw_water_pond(385, 55)  # Water is always background
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
	# Wooden road signs in grass areas (off pathways)
	# Right sign pointing to Town Center (above path)
	draw_road_sign(440, 115, "Town ->", true)
	
	# Left sign pointing to Minigame (above path)
	draw_road_sign(15, 115, "<- Game", false)
	
	# Up sign pointing to Cornfield (left side of path)
	draw_road_sign_vertical(175, 25, "Cornfield", true)
	
	# Down sign pointing to Lakeside (left side of path)
	draw_road_sign_vertical(175, 285, "Lakeside", false)
	
	# Draw roaming animals
	draw_roaming_animals_for_area("farm")
	

func draw_road_sign(x: float, y: float, text: String, arrow_right: bool):
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Post
	draw_rect(Rect2(x + 12, y + 14, 6, 25), outline)
	draw_rect(Rect2(x + 13, y + 15, 4, 23), wood_dark)
	
	# Sign board
	var sign_w = text.length() * 6 + 10
	draw_rect(Rect2(x - 1, y - 1, sign_w + 2, 16), outline)
	draw_rect(Rect2(x, y, sign_w, 14), wood)
	draw_rect(Rect2(x + 1, y + 1, sign_w - 2, 12), Color(0.62, 0.48, 0.36))
	
	# Nails
	draw_circle(Vector2(x + 4, y + 4), 1.5, Color(0.4, 0.4, 0.45))
	draw_circle(Vector2(x + sign_w - 4, y + 4), 1.5, Color(0.4, 0.4, 0.45))
	
	# Text
	draw_string(ThemeDB.fallback_font, Vector2(x + 3, y + 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.15, 0.1))

func draw_road_sign_vertical(x: float, y: float, text: String, arrow_up: bool):
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Post
	var post_y = y + 14 if arrow_up else y - 20
	draw_rect(Rect2(x + 20, post_y, 6, 22), outline)
	draw_rect(Rect2(x + 21, post_y + 1, 4, 20), wood_dark)
	
	# Sign board
	var sign_w = text.length() * 6 + 16
	var arrow_text = "^ " + text if arrow_up else "v " + text
	draw_rect(Rect2(x - 1, y - 1, sign_w + 2, 16), outline)
	draw_rect(Rect2(x, y, sign_w, 14), wood)
	draw_rect(Rect2(x + 1, y + 1, sign_w - 2, 12), Color(0.62, 0.48, 0.36))
	
	# Text
	draw_string(ThemeDB.fallback_font, Vector2(x + 3, y + 11), arrow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.15, 0.1))

func draw_ground_tiles():
	var grass_dark = Color(0.45, 0.75, 0.45)
	var grass_mid = Color(0.55, 0.85, 0.5)
	var grass_light = Color(0.65, 0.95, 0.55)
	
	for x in range(0, 480, 16):
		for y in range(0, 320, 16):
			var variation = fmod((x * 7 + y * 13), 3)
			var color = grass_mid
			if variation == 0:
				color = grass_dark
			elif variation == 2:
				color = grass_light
			draw_rect(Rect2(x, y, 16, 16), color)
			
			if fmod((x + y), 32) == 0:
				draw_rect(Rect2(x + 6, y + 4, 2, 3), grass_dark)
				draw_rect(Rect2(x + 10, y + 9, 2, 3), grass_dark)
	
	draw_dirt_paths()

func draw_dirt_paths():
	if tex_tiled_dirt_wide_v2:
		# Use the Tilled_Dirt_Wide_v2.png tileset
		# The tileset has 16x16 tiles arranged in a grid
		# Layout (assuming standard tileset format):
		# Row 0: top-left corner, top edge, top-right corner, single
		# Row 1: left edge, center fill, right edge, variations
		# Row 2: bottom-left corner, bottom edge, bottom-right corner, variations
		# Row 3: inner corners and special pieces
		
		var tile_size = 16
		
		# Define path regions
		var v_path_left = 200
		var v_path_right = 264
		var h_path_top = 144
		var h_path_bottom = 192
		
		# Helper function to get tile type
		# Returns which tile to use based on position
		
		# Draw vertical path (north-south)
		for ty in range(0, 320, tile_size):
			for tx in range(v_path_left, v_path_right, tile_size):
				var tile_x = 1  # Default center
				var tile_y = 1
				
				# Determine tile based on position
				var is_left_edge = (tx == v_path_left)
				var is_right_edge = (tx == v_path_right - tile_size)
				var is_top_edge = (ty == 0)
				var is_bottom_edge = (ty >= 304)
				var is_in_h_path = (ty >= h_path_top and ty < h_path_bottom)
				
				# Skip tiles that are in the horizontal path intersection
				# (we'll draw those with the horizontal path)
				
				if is_left_edge and is_top_edge:
					tile_x = 0; tile_y = 0  # Top-left corner
				elif is_right_edge and is_top_edge:
					tile_x = 2; tile_y = 0  # Top-right corner
				elif is_left_edge and is_bottom_edge:
					tile_x = 0; tile_y = 2  # Bottom-left corner
				elif is_right_edge and is_bottom_edge:
					tile_x = 2; tile_y = 2  # Bottom-right corner
				elif is_left_edge:
					tile_x = 0; tile_y = 1  # Left edge
				elif is_right_edge:
					tile_x = 2; tile_y = 1  # Right edge
				elif is_top_edge:
					tile_x = 1; tile_y = 0  # Top edge
				elif is_bottom_edge:
					tile_x = 1; tile_y = 2  # Bottom edge
				else:
					tile_x = 1; tile_y = 1  # Center fill
				
				var src = Rect2(tile_x * tile_size, tile_y * tile_size, tile_size, tile_size)
				var dest = Rect2(tx, ty, tile_size, tile_size)
				draw_texture_rect_region(tex_tiled_dirt_wide_v2, dest, src)
		
		# Draw horizontal path (east-west)
		for ty in range(h_path_top, h_path_bottom, tile_size):
			for tx in range(0, 480, tile_size):
				# Skip the intersection area (already drawn by vertical path)
				if tx >= v_path_left and tx < v_path_right:
					# Draw intersection tiles with special handling
					var is_top_of_h = (ty == h_path_top)
					var is_bottom_of_h = (ty == h_path_bottom - tile_size)
					
					var tile_x = 1  # Center
					var tile_y = 1
					
					# At intersection, we need to handle the T-junctions
					if tx == v_path_left:
						if is_top_of_h:
							tile_x = 3; tile_y = 0  # Inner corner top-left
						elif is_bottom_of_h:
							tile_x = 3; tile_y = 2  # Inner corner bottom-left
						else:
							tile_x = 1; tile_y = 1  # Center
					elif tx == v_path_right - tile_size:
						if is_top_of_h:
							tile_x = 3; tile_y = 1  # Inner corner top-right (or use another)
						elif is_bottom_of_h:
							tile_x = 3; tile_y = 3 if tile_y < 4 else 2  # Inner corner bottom-right
						else:
							tile_x = 1; tile_y = 1  # Center
					else:
						tile_x = 1; tile_y = 1  # Center fill
					
					var src = Rect2(tile_x * tile_size, tile_y * tile_size, tile_size, tile_size)
					var dest = Rect2(tx, ty, tile_size, tile_size)
					draw_texture_rect_region(tex_tiled_dirt_wide_v2, dest, src)
					continue
				
				var tile_x = 1  # Default center
				var tile_y = 1
				
				var is_left_edge = (tx == 0)
				var is_right_edge = (tx >= 464)
				var is_top_edge = (ty == h_path_top)
				var is_bottom_edge = (ty == h_path_bottom - tile_size)
				
				# Near vertical path - need special edge handling
				var is_near_v_left = (tx == v_path_left - tile_size)
				var is_near_v_right = (tx == v_path_right)
				
				if is_near_v_left:
					# Approaching vertical path from left
					if is_top_edge:
						tile_x = 2; tile_y = 0  # Right edge with top
					elif is_bottom_edge:
						tile_x = 2; tile_y = 2  # Right edge with bottom
					else:
						tile_x = 2; tile_y = 1  # Right edge
				elif is_near_v_right:
					# Coming from vertical path on right
					if is_top_edge:
						tile_x = 0; tile_y = 0  # Left edge with top
					elif is_bottom_edge:
						tile_x = 0; tile_y = 2  # Left edge with bottom
					else:
						tile_x = 0; tile_y = 1  # Left edge
				elif is_left_edge and is_top_edge:
					tile_x = 0; tile_y = 0  # Top-left corner
				elif is_right_edge and is_top_edge:
					tile_x = 2; tile_y = 0  # Top-right corner
				elif is_left_edge and is_bottom_edge:
					tile_x = 0; tile_y = 2  # Bottom-left corner
				elif is_right_edge and is_bottom_edge:
					tile_x = 2; tile_y = 2  # Bottom-right corner
				elif is_left_edge:
					tile_x = 0; tile_y = 1  # Left edge
				elif is_right_edge:
					tile_x = 2; tile_y = 1  # Right edge
				elif is_top_edge:
					tile_x = 1; tile_y = 0  # Top edge
				elif is_bottom_edge:
					tile_x = 1; tile_y = 2  # Bottom edge
				else:
					tile_x = 1; tile_y = 1  # Center fill
				
				var src = Rect2(tile_x * tile_size, tile_y * tile_size, tile_size, tile_size)
				var dest = Rect2(tx, ty, tile_size, tile_size)
				draw_texture_rect_region(tex_tiled_dirt_wide_v2, dest, src)
	else:
		# Fallback to colored rectangles
		var dirt_main = Color(0.85, 0.65, 0.45)
		var dirt_dark = Color(0.65, 0.5, 0.35)
		var dirt_light = Color(0.95, 0.8, 0.6)
		
		# Vertical path
		draw_rect(Rect2(200, 0, 65, 320), dirt_main)
		draw_rect(Rect2(198, 0, 4, 320), dirt_dark)
		draw_rect(Rect2(263, 0, 4, 320), dirt_dark)
		draw_rect(Rect2(225, 0, 8, 320), dirt_light)
		
		# Horizontal path
		draw_rect(Rect2(0, 145, 480, 50), dirt_main)
		draw_rect(Rect2(0, 143, 480, 4), dirt_dark)
		draw_rect(Rect2(0, 193, 480, 4), dirt_dark)
		draw_rect(Rect2(0, 165, 480, 8), dirt_light)

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
	draw_shed(375, 175)
	draw_fence(30, 275, 6)
	draw_farm_plot(35, 200, 4, 3)
	
	# Optional side circuit locations
	draw_chicken_coop(chicken_coop_pos.x, chicken_coop_pos.y)
	
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
		# Use chicken house sprite
		var tex_width = tex_chicken_house.get_width()
		var tex_height = tex_chicken_house.get_height()
		# Scale down to fit nicely (original sprite is large)
		var scale = 0.875  # 25% bigger
		var dest = Rect2(x - 15, y - tex_height * scale + 45, tex_width * scale, tex_height * scale)
		draw_texture_rect(tex_chicken_house, dest, false)
	else:
		# Fallback to hand-drawn
		var wood = Color(0.6, 0.45, 0.35)
		var wood_dark = Color(0.5, 0.38, 0.28)
		var roof = Color(0.55, 0.35, 0.3)
		var outline = Color(0.0, 0.0, 0.0)
		
		# Shadow
		draw_ellipse_shape(Vector2(x + 20, y + 40), Vector2(25, 8), Color(0, 0, 0, 0.15))
		
		# Main coop body
		draw_rect(Rect2(x - 1, y + 9, 42, 32), outline)
		draw_rect(Rect2(x, y + 10, 40, 30), wood)
		draw_rect(Rect2(x, y + 10, 8, 30), wood_dark)
		
		# Wood grain lines
		draw_line(Vector2(x + 12, y + 12), Vector2(x + 12, y + 38), Color(0.45, 0.35, 0.25), 1)
		draw_line(Vector2(x + 24, y + 12), Vector2(x + 24, y + 38), Color(0.45, 0.35, 0.25), 1)
		
		# Roof
		var roof_pts = PackedVector2Array([
			Vector2(x - 5, y + 12),
			Vector2(x + 20, y - 2),
			Vector2(x + 45, y + 12)
		])
		draw_colored_polygon(roof_pts, outline)
		var roof_inner = PackedVector2Array([
			Vector2(x - 3, y + 10),
			Vector2(x + 20, y),
			Vector2(x + 43, y + 10)
		])
		draw_colored_polygon(roof_inner, roof)
		
		# Door/opening
		draw_rect(Rect2(x + 25, y + 22, 12, 18), outline)
		draw_rect(Rect2(x + 26, y + 23, 10, 16), Color(0.2, 0.15, 0.1))
	
	# Chickens!
	draw_chicken(x + 48, y + 32, true)  # Outside chicken (consistent small size)
	if not side_circuits_done.chicken_coop:
		draw_chicken(x + 30, y + 35, true)  # Chicken in doorway
		draw_chicken(x + 55, y + 38, true)  # Second outside chicken (consistent small size)
	
	# Fixed indicator
	if side_circuits_done.chicken_coop:
		var glow = (sin(continuous_timer * 3) * 0.3 + 0.7)
		draw_circle(Vector2(x + 35, y + 15), 4, Color(0.3, 0.9, 0.4, glow))

func draw_chicken(x: float, y: float, small: bool):
	var size_mult = 0.6 if small else 1.0
	
	# Each chicken has unique animation phase based on position
	var phase = x * 0.1 + y * 0.07
	
	# Idle animation offset
	var idle_bob = sin(continuous_timer * 2.5 + phase) * 1.5
	var idle_sway = sin(continuous_timer * 1.5 + phase) * 1.0
	
	if tex_chicken_sprites:
		# Use chicken sprite sheet (2 columns x 3 rows, each frame ~32x32)
		var frame_w = 32
		var frame_h = 32
		
		# Animate between frames based on time
		var frame_idx = int(fmod(continuous_timer * 3 + phase, 6))
		var frame_col = frame_idx % 2
		var frame_row = frame_idx / 2
		
		var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
		var dest_size = frame_w * size_mult * 0.9
		var dest = Rect2(x - dest_size / 2 + idle_sway, y - dest_size + 8 + idle_bob, dest_size, dest_size)
		draw_texture_rect_region(tex_chicken_sprites, dest, src)
	else:
		# Fallback to hand-drawn
		var outline = Color(0.0, 0.0, 0.0)
		var body_color = Color(1.0, 0.95, 0.85)
		var wing_color = Color(0.95, 0.88, 0.75)
		var beak_color = Color(1.0, 0.6, 0.2)
		var comb_color = Color(0.9, 0.25, 0.2)
		
		# Idle animation - pecking motion and body bob
		var peck_cycle = fmod(continuous_timer * 2.0 + phase, 3.0)
		var is_pecking = peck_cycle < 0.4
		var head_bob = 0.0
		var head_forward = 0.0
		if is_pecking:
			var peck_t = peck_cycle / 0.4
			head_bob = sin(peck_t * PI) * 4
			head_forward = sin(peck_t * PI) * 3
		
		var ax = x + idle_sway
		var ay = y + idle_bob
		
		# Shadow (stays in place)
		draw_ellipse_shape(Vector2(x, y + 4 * size_mult), Vector2(8 * size_mult, 3 * size_mult), Color(0, 0, 0, 0.2))
		
		# Body with outline
		draw_circle(Vector2(ax, ay - 2 * size_mult), (8 * size_mult) + 1, outline)
		draw_circle(Vector2(ax, ay - 2 * size_mult), 8 * size_mult, body_color)
		
		# Wing
		var wing_flutter = sin(continuous_timer * 8.0 + phase) * 0.5 if fmod(continuous_timer + phase, 5.0) < 0.3 else 0
		var wing_pts = PackedVector2Array([
			Vector2(ax - 4 * size_mult, ay - 4 * size_mult + wing_flutter),
			Vector2(ax + 6 * size_mult, ay - 2 * size_mult + wing_flutter),
			Vector2(ax + 4 * size_mult, ay + 3 * size_mult),
			Vector2(ax - 2 * size_mult, ay + 2 * size_mult)
		])
		draw_colored_polygon(wing_pts, outline)
		var wing_fill = PackedVector2Array([
			Vector2(ax - 3 * size_mult, ay - 3 * size_mult + wing_flutter),
			Vector2(ax + 5 * size_mult, ay - 1 * size_mult + wing_flutter),
			Vector2(ax + 3 * size_mult, ay + 2 * size_mult),
			Vector2(ax - 1 * size_mult, ay + 1 * size_mult)
		])
		draw_colored_polygon(wing_fill, wing_color)
		
		# Head with outline - moves during peck
		var head_x = ax + 6 * size_mult + head_forward
		var head_y = ay - 6 * size_mult + head_bob
		draw_circle(Vector2(head_x, head_y), (5 * size_mult) + 1, outline)
		draw_circle(Vector2(head_x, head_y), 5 * size_mult, body_color)
		
		# Comb (red thing on head)
		draw_circle(Vector2(head_x, head_y - 5 * size_mult), 3 * size_mult, outline)
		draw_circle(Vector2(head_x, head_y - 5 * size_mult), 2.5 * size_mult, comb_color)
		draw_circle(Vector2(head_x - 2 * size_mult, head_y - 4 * size_mult), 2 * size_mult, comb_color)
		
		# Beak
		var beak_pts = PackedVector2Array([
			Vector2(head_x + 4 * size_mult, head_y),
			Vector2(head_x + 8 * size_mult, head_y + 1 * size_mult),
			Vector2(head_x + 4 * size_mult, head_y + 2 * size_mult)
		])
		draw_colored_polygon(beak_pts, outline)
		var beak_fill = PackedVector2Array([
			Vector2(head_x + 4 * size_mult, head_y + 0.5 * size_mult),
			Vector2(head_x + 7 * size_mult, head_y + 1 * size_mult),
			Vector2(head_x + 4 * size_mult, head_y + 1.5 * size_mult)
		])
		draw_colored_polygon(beak_fill, beak_color)
		
		# Eye
		var blink = fmod(continuous_timer + phase * 2, 3.5) < 0.1
		if not blink:
			draw_circle(Vector2(head_x + 2 * size_mult, head_y - 1 * size_mult), 1.5 * size_mult, outline)
			draw_circle(Vector2(head_x + 2 * size_mult, head_y - 1 * size_mult), 1 * size_mult, Color(0.1, 0.1, 0.1))
		
		# Feet
		var foot_move = sin(continuous_timer * 4.0 + phase) * 1
		draw_line(Vector2(ax - 2 * size_mult, ay + 3 * size_mult), Vector2(ax - 4 * size_mult + foot_move, y + 6 * size_mult), beak_color, 2)
		draw_line(Vector2(ax + 2 * size_mult, ay + 3 * size_mult), Vector2(ax + 4 * size_mult - foot_move, y + 6 * size_mult), beak_color, 2)

func draw_cow(x: float, y: float, facing_left: bool = false):
	# Each cow has unique animation phase
	var phase = x * 0.05 + y * 0.03
	
	# Idle animation - grazing motion
	var idle_bob = sin(continuous_timer * 1.5 + phase) * 2.0
	var tail_wag = sin(continuous_timer * 4.0 + phase) * 0.3
	
	if tex_cow_sprites:
		# Use cow sprite sheet (3 columns x 2 rows, each frame ~32x32)
		var frame_w = 32
		var frame_h = 32
		
		# Animate between walk frames
		var frame_idx = int(fmod(continuous_timer * 2 + phase, 5))
		var frame_col = frame_idx % 3
		var frame_row = frame_idx / 3
		
		var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
		var dest_w = frame_w * 1.2
		var dest_h = frame_h * 1.2
		var dest = Rect2(x - dest_w / 2, y - dest_h + 8 + idle_bob, dest_w, dest_h)
		
		if facing_left:
			# Flip horizontally by drawing mirrored
			dest = Rect2(x + dest_w / 2, y - dest_h + 8 + idle_bob, -dest_w, dest_h)
		draw_texture_rect_region(tex_cow_sprites, dest, src)
	else:
		# Fallback to hand-drawn cow
		var outline = Color(0.0, 0.0, 0.0)
		var body_color = Color(0.95, 0.9, 0.82)
		var spot_color = Color(0.55, 0.35, 0.25)
		var nose_color = Color(0.9, 0.7, 0.65)
		
		var ax = x
		var ay = y + idle_bob
		
		# Shadow
		draw_ellipse_shape(Vector2(x, y + 5), Vector2(18, 6), Color(0, 0, 0, 0.2))
		
		# Body
		draw_ellipse_shape(Vector2(ax, ay - 8), Vector2(20, 12), outline)
		draw_ellipse_shape(Vector2(ax, ay - 8), Vector2(18, 10), body_color)
		
		# Spots
		draw_circle(Vector2(ax - 8, ay - 10), 5, spot_color)
		draw_circle(Vector2(ax + 5, ay - 5), 4, spot_color)
		draw_circle(Vector2(ax + 10, ay - 12), 3, spot_color)
		
		# Head
		var head_offset = -15 if facing_left else 15
		draw_circle(Vector2(ax + head_offset, ay - 12), 10, outline)
		draw_circle(Vector2(ax + head_offset, ay - 12), 9, body_color)
		
		# Ears
		draw_circle(Vector2(ax + head_offset - 6, ay - 20), 4, outline)
		draw_circle(Vector2(ax + head_offset - 6, ay - 20), 3, nose_color)
		draw_circle(Vector2(ax + head_offset + 6, ay - 20), 4, outline)
		draw_circle(Vector2(ax + head_offset + 6, ay - 20), 3, nose_color)
		
		# Nose
		draw_ellipse_shape(Vector2(ax + head_offset, ay - 8), Vector2(6, 4), nose_color)
		draw_circle(Vector2(ax + head_offset - 2, ay - 8), 1, Color(0.3, 0.2, 0.2))
		draw_circle(Vector2(ax + head_offset + 2, ay - 8), 1, Color(0.3, 0.2, 0.2))
		
		# Eyes
		var eye_x = ax + head_offset + (4 if facing_left else -4)
		draw_circle(Vector2(eye_x - 4, ay - 14), 2, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(eye_x + 4, ay - 14), 2, Color(0.1, 0.1, 0.1))
		
		# Legs
		for i in range(4):
			var leg_x = ax - 12 + i * 8
			draw_rect(Rect2(leg_x, ay, 4, 8), outline)
			draw_rect(Rect2(leg_x + 1, ay + 1, 2, 6), body_color)
		
		# Tail
		var tail_x = ax - 18 if facing_left else ax + 18
		draw_line(Vector2(tail_x, ay - 5), Vector2(tail_x + tail_wag * 10, ay + 5), spot_color, 2)

func draw_tool(x: float, y: float, tool_type: int):
	# Draw a farm tool from the spritesheet
	# tool_type: 0=watering can, 1=axe, 2=hoe, 3=wheelbarrow, 4=logs, 5=hay
	if tex_basic_tools:
		var frame_size = 32
		var col = tool_type % 3
		var row = tool_type / 3
		var src = Rect2(col * frame_size, row * frame_size, frame_size, frame_size)
		var dest = Rect2(x - 12, y - 12, 24, 24)
		draw_texture_rect_region(tex_basic_tools, dest, src)
	else:
		# Fallback - simple colored shapes
		var tool_color = Color(0.5, 0.4, 0.35)
		match tool_type:
			0:  # Watering can
				draw_rect(Rect2(x - 8, y - 6, 12, 8), tool_color)
				draw_rect(Rect2(x + 2, y - 10, 3, 6), tool_color)
			1:  # Axe
				draw_rect(Rect2(x - 2, y - 12, 4, 18), Color(0.55, 0.4, 0.3))
				draw_rect(Rect2(x - 8, y - 12, 10, 6), Color(0.5, 0.5, 0.55))
			2:  # Hoe
				draw_rect(Rect2(x - 2, y - 12, 4, 20), Color(0.55, 0.4, 0.3))
				draw_rect(Rect2(x - 6, y + 4, 12, 4), Color(0.5, 0.5, 0.55))
			3:  # Wheelbarrow
				draw_ellipse_shape(Vector2(x, y), Vector2(10, 6), tool_color)
			4:  # Logs
				draw_rect(Rect2(x - 10, y - 4, 20, 8), Color(0.6, 0.45, 0.3))
			5:  # Hay
				draw_rect(Rect2(x - 8, y - 8, 16, 16), Color(0.85, 0.75, 0.4))

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
		
		# Brighter/more visible if flashlight is shining on it
		if flashlight_on and light_dist < 50:
			draw_journal_page_item(pos, 1.0)
		elif dist < 120:
			var alpha = 1.0 - (dist / 120.0)
			alpha *= 0.5  # Dimmer when not lit
			draw_journal_page_item(pos, alpha)

func draw_area_journal_sparkles(page_name: String):
	# Draw journal page sparkle for a specific area
	if page_name in journal_pages_found:
		return
	
	var pos = journal_page_locations[page_name]
	var dist = player_pos.distance_to(pos)
	
	if dist < 120:
		var alpha = 1.0 - (dist / 120.0)
		draw_journal_page_item(pos, alpha * 0.7)

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
	# High-quality hand-drawn pond
	var water_deep = Color(0.25, 0.4, 0.6)
	var water_mid = Color(0.35, 0.55, 0.75)
	var water_light = Color(0.5, 0.7, 0.9)
	var water_highlight = Color(0.7, 0.85, 1.0)
	var bank_dark = Color(0.5, 0.42, 0.32)
	var bank_mid = Color(0.6, 0.5, 0.4)
	var bank_light = Color(0.7, 0.6, 0.48)
	var outline = Color(0.15, 0.12, 0.1)
	
	# Outer bank outline
	draw_ellipse_shape(Vector2(x + 30, y + 26), Vector2(46, 36), outline)
	# Bank layers
	draw_ellipse_shape(Vector2(x + 30, y + 26), Vector2(44, 34), bank_dark)
	draw_ellipse_shape(Vector2(x + 30, y + 25), Vector2(42, 32), bank_mid)
	draw_ellipse_shape(Vector2(x + 30, y + 24), Vector2(40, 30), bank_light)
	
	# Water layers
	draw_ellipse_shape(Vector2(x + 30, y + 24), Vector2(36, 26), water_deep)
	draw_ellipse_shape(Vector2(x + 28, y + 22), Vector2(30, 22), water_mid)
	draw_ellipse_shape(Vector2(x + 26, y + 20), Vector2(22, 16), water_light)
	
	# Animated sparkles
	var sparkle1 = (sin(anim_timer * 3) * 0.4 + 0.6)
	var sparkle2 = (sin(anim_timer * 3 + 1.5) * 0.4 + 0.6)
	draw_circle(Vector2(x + 20, y + 16), 3, Color(1, 1, 1, sparkle1))
	draw_circle(Vector2(x + 35, y + 22), 2, Color(1, 1, 1, sparkle2 * 0.7))
	
	# Lily pad
	draw_ellipse_shape(Vector2(x + 40, y + 28), Vector2(6, 4), Color(0.3, 0.55, 0.35))
	draw_ellipse_shape(Vector2(x + 40, y + 27), Vector2(5, 3), Color(0.4, 0.65, 0.4))
	# Lily flower
	draw_circle(Vector2(x + 42, y + 26), 2, Color(1.0, 0.85, 0.9))
	draw_circle(Vector2(x + 42, y + 26), 1, Color(1.0, 0.95, 0.5))

func draw_trees():
	draw_tree_large(5, 100)
	draw_tree_large(95, 10)
	draw_tree_large(420, 5)
	draw_tree_large(430, 220)
	draw_tree_medium(60, 200)
	draw_tree_medium(350, 250)

func draw_tree_large(x: float, y: float):
	# Use hand-drawn trees for now (more consistent look)
	var trunk = Color(0.6, 0.45, 0.3)
	var trunk_dark = Color(0.45, 0.32, 0.22)
	var leaves_dark = Color(0.35, 0.65, 0.4)
	var leaves_mid = Color(0.5, 0.8, 0.5)
	var leaves_light = Color(0.6, 0.9, 0.55)
	var leaves_highlight = Color(0.75, 1.0, 0.65)
	var outline = Color(0.0, 0.0, 0.0)
	
	draw_ellipse_shape(Vector2(x + 20, y + 58), Vector2(18, 6), Color(0, 0, 0, 0.15))
	
	# Trunk outline
	draw_rect(Rect2(x + 11, y + 34, 18, 27), outline)
	draw_rect(Rect2(x + 12, y + 35, 16, 25), trunk)
	draw_rect(Rect2(x + 12, y + 35, 5, 25), trunk_dark)
	
	# Leaves outline
	draw_circle(Vector2(x + 5, y + 38), 17, outline)
	draw_circle(Vector2(x + 35, y + 38), 17, outline)
	draw_circle(Vector2(x + 20, y + 42), 19, outline)
	draw_circle(Vector2(x + 20, y + 28), 15, outline)
	
	# Leaves fill
	draw_circle(Vector2(x + 5, y + 38), 16, leaves_dark)
	draw_circle(Vector2(x + 35, y + 38), 16, leaves_dark)
	draw_circle(Vector2(x + 20, y + 42), 18, leaves_dark)
	draw_circle(Vector2(x + 8, y + 32), 15, leaves_mid)
	draw_circle(Vector2(x + 32, y + 32), 15, leaves_mid)
	draw_circle(Vector2(x + 20, y + 36), 17, leaves_mid)
	draw_circle(Vector2(x + 20, y + 28), 14, leaves_light)
	draw_circle(Vector2(x + 15, y + 24), 8, leaves_highlight)

func draw_tree_medium(x: float, y: float):
	# Use hand-drawn trees for now
	var trunk = Color(0.6, 0.45, 0.3)
	var trunk_dark = Color(0.45, 0.32, 0.22)
	var leaves_dark = Color(0.35, 0.65, 0.4)
	var leaves_mid = Color(0.5, 0.8, 0.5)
	var leaves_light = Color(0.6, 0.9, 0.55)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Trunk outline
	draw_rect(Rect2(x + 5, y + 27, 14, 18), outline)
	draw_rect(Rect2(x + 6, y + 28, 12, 16), trunk)
	draw_rect(Rect2(x + 6, y + 28, 4, 16), trunk_dark)
	
	# Leaves outline
	draw_circle(Vector2(x + 12, y + 28), 15, outline)
	draw_circle(Vector2(x + 12, y + 20), 13, outline)
	
	# Leaves fill
	draw_circle(Vector2(x + 12, y + 28), 14, leaves_dark)
	draw_circle(Vector2(x + 4, y + 24), 10, leaves_mid)
	draw_circle(Vector2(x + 20, y + 24), 10, leaves_mid)
	draw_circle(Vector2(x + 12, y + 20), 12, leaves_light)

func draw_tree_small(x: float, y: float):
	# Use hand-drawn trees for now
	var trunk = Color(0.6, 0.45, 0.3)
	var leaves = Color(0.5, 0.8, 0.5)
	var leaves_light = Color(0.6, 0.9, 0.55)
	var outline = Color(0.0, 0.0, 0.0)
	
	draw_rect(Rect2(x + 10, y + 28, 10, 16), outline)
	draw_rect(Rect2(x + 11, y + 29, 8, 14), trunk)
	draw_circle(Vector2(x + 15, y + 24), 14, outline)
	draw_circle(Vector2(x + 15, y + 24), 13, leaves)
	draw_circle(Vector2(x + 13, y + 20), 8, leaves_light)

func draw_bushes():
	draw_bush(25, 60)
	draw_bush(150, 215)
	draw_bush(345, 95)

func draw_bush(x: float, y: float):
	# Always use hand-drawn bushes for now until we map the spritesheet properly
	var bush_dark = Color(0.4, 0.7, 0.45)
	var bush_mid = Color(0.5, 0.82, 0.55)
	var bush_light = Color(0.65, 0.95, 0.6)
	var outline = Color(0.0, 0.0, 0.0)
	
	# Outline
	draw_circle(Vector2(x + 6, y + 10), 10, outline)
	draw_circle(Vector2(x + 18, y + 10), 10, outline)
	draw_circle(Vector2(x + 12, y + 8), 12, outline)
	
	# Fill
	draw_circle(Vector2(x + 6, y + 10), 9, bush_dark)
	draw_circle(Vector2(x + 18, y + 10), 9, bush_dark)
	draw_circle(Vector2(x + 12, y + 8), 11, bush_mid)
	draw_circle(Vector2(x + 8, y + 5), 6, bush_light)
	
	# Berries - bright red
	draw_circle(Vector2(x + 5, y + 8), 2, Color(1.0, 0.3, 0.3))
	draw_circle(Vector2(x + 16, y + 6), 2, Color(1.0, 0.3, 0.3))

func draw_rocks():
	draw_rock_large(50, 250)
	draw_rock_small(120, 85)

func draw_rock_large(x: float, y: float):
	var rock_dark = Color(0.5, 0.5, 0.52)
	var rock_mid = Color(0.65, 0.65, 0.68)
	var rock_light = Color(0.8, 0.8, 0.83)
	var outline = Color(0.0, 0.0, 0.0)
	
	draw_ellipse_shape(Vector2(x + 12, y + 12), Vector2(15, 11), outline)
	draw_ellipse_shape(Vector2(x + 12, y + 12), Vector2(14, 10), rock_dark)
	draw_ellipse_shape(Vector2(x + 10, y + 10), Vector2(12, 8), rock_mid)
	draw_ellipse_shape(Vector2(x + 6, y + 7), Vector2(6, 4), rock_light)

func draw_rock_small(x: float, y: float):
	var outline = Color(0.0, 0.0, 0.0)
	draw_ellipse_shape(Vector2(x + 5, y + 6), Vector2(8, 6), outline)
	draw_ellipse_shape(Vector2(x + 5, y + 6), Vector2(7, 5), Color(0.55, 0.55, 0.58))
	draw_ellipse_shape(Vector2(x + 4, y + 4), Vector2(5, 3), Color(0.72, 0.72, 0.76))

func draw_flowers():
	draw_flower_cluster(70, 95)
	draw_flower_cluster(160, 260)
	draw_flower_cluster(320, 85)  # Moved from (410, 145) to avoid walkway

func draw_flower_cluster(x: float, y: float):
	var stem = Color(0.42, 0.62, 0.42)
	var colors = [Color(1.0, 0.5, 0.5), Color(1.0, 0.95, 0.45), Color(1.0, 0.6, 0.8)]
	for i in range(3):
		var fx = x + (i % 2) * 10 + fmod(i * 7, 5)
		var fy = y + (i / 2) * 8 + fmod(i * 3, 4)
		draw_rect(Rect2(fx + 2, fy + 4, 2, 6), stem)
		draw_circle(Vector2(fx + 3, fy + 3), 4, colors[i])
		draw_circle(Vector2(fx + 3, fy + 3), 2, Color(1.0, 1.0, 0.7))

func draw_house(x: float, y: float):
	# High-quality hand-drawn farmhouse
	var wall_base = Color(0.82, 0.72, 0.58)
	var wall_shadow = Color(0.68, 0.58, 0.48)
	var wall_highlight = Color(0.9, 0.82, 0.7)
	var roof_main = Color(0.6, 0.35, 0.28)
	var roof_dark = Color(0.45, 0.25, 0.2)
	var roof_light = Color(0.72, 0.45, 0.35)
	var wood_trim = Color(0.5, 0.38, 0.28)
	var wood_dark = Color(0.38, 0.28, 0.2)
	var window_glass = Color(0.65, 0.82, 0.95)
	var window_glow = Color(1.0, 0.95, 0.8, 0.4)
	var window_frame = Color(0.45, 0.35, 0.28)
	var door_wood = Color(0.52, 0.38, 0.28)
	var outline = Color(0.12, 0.1, 0.08)
	
	# Shadow under house
	draw_ellipse_shape(Vector2(x + 45, y + 80), Vector2(55, 12), Color(0, 0, 0, 0.2))
	
	# === WALLS ===
	# Main wall outline
	draw_rect(Rect2(x - 2, y + 26, 96, 54), outline)
	# Wall base
	draw_rect(Rect2(x, y + 28, 92, 50), wall_base)
	# Wall shadow (bottom)
	draw_rect(Rect2(x, y + 68, 92, 10), wall_shadow)
	# Wall highlight (top)
	draw_rect(Rect2(x, y + 28, 92, 6), wall_highlight)
	
	# Wall texture lines (horizontal planks)
	for i in range(5):
		var ly = y + 34 + i * 10
		draw_line(Vector2(x, ly), Vector2(x + 92, ly), Color(0, 0, 0, 0.08), 1)
	
	# === ROOF ===
	# Roof outline
	var roof_outline_pts = PackedVector2Array([
		Vector2(x - 12, y + 30),
		Vector2(x + 46, y),
		Vector2(x + 104, y + 30)
	])
	draw_colored_polygon(roof_outline_pts, outline)
	
	# Roof main
	var roof_pts = PackedVector2Array([
		Vector2(x - 10, y + 28),
		Vector2(x + 46, y + 2),
		Vector2(x + 102, y + 28)
	])
	draw_colored_polygon(roof_pts, roof_main)
	
	# Roof left side (darker)
	var roof_left = PackedVector2Array([
		Vector2(x - 10, y + 28),
		Vector2(x + 46, y + 2),
		Vector2(x + 46, y + 28)
	])
	draw_colored_polygon(roof_left, roof_dark)
	
	# Roof right side (lighter)
	var roof_right = PackedVector2Array([
		Vector2(x + 46, y + 2),
		Vector2(x + 102, y + 28),
		Vector2(x + 46, y + 28)
	])
	draw_colored_polygon(roof_right, roof_light)
	
	# Roof shingle lines
	for i in range(4):
		var ry = y + 8 + i * 6
		var rx_left = x - 6 + i * 5
		var rx_right = x + 98 - i * 5
		draw_line(Vector2(rx_left, ry + 10), Vector2(x + 46, ry - 4), Color(0, 0, 0, 0.15), 1)
		draw_line(Vector2(x + 46, ry - 4), Vector2(rx_right, ry + 10), Color(1, 1, 1, 0.1), 1)
	
	# === CHIMNEY ===
	draw_rect(Rect2(x + 68, y - 5, 14, 20), outline)
	draw_rect(Rect2(x + 70, y - 3, 10, 18), Color(0.6, 0.4, 0.35))
	draw_rect(Rect2(x + 70, y - 3, 10, 3), Color(0.5, 0.35, 0.3))
	
	# === DOOR ===
	# Door frame
	draw_rect(Rect2(x + 35, y + 42, 24, 36), outline)
	draw_rect(Rect2(x + 36, y + 43, 22, 35), wood_trim)
	# Door
	draw_rect(Rect2(x + 38, y + 45, 18, 31), door_wood)
	# Door panels
	draw_rect(Rect2(x + 40, y + 48, 14, 10), wood_dark)
	draw_rect(Rect2(x + 40, y + 62, 14, 10), wood_dark)
	# Door handle
	draw_circle(Vector2(x + 52, y + 62), 2, Color(0.75, 0.65, 0.4))
	draw_circle(Vector2(x + 52, y + 62), 1, Color(0.9, 0.8, 0.5))
	
	# === WINDOWS ===
	# Left window
	draw_rect(Rect2(x + 6, y + 38, 24, 24), outline)
	draw_rect(Rect2(x + 7, y + 39, 22, 22), window_frame)
	draw_rect(Rect2(x + 9, y + 41, 18, 18), window_glass)
	draw_rect(Rect2(x + 9, y + 41, 18, 18), window_glow)
	# Window cross
	draw_rect(Rect2(x + 17, y + 41, 2, 18), window_frame)
	draw_rect(Rect2(x + 9, y + 49, 18, 2), window_frame)
	# Window sill
	draw_rect(Rect2(x + 5, y + 61, 26, 4), wood_trim)
	
	# Right window
	draw_rect(Rect2(x + 62, y + 38, 24, 24), outline)
	draw_rect(Rect2(x + 63, y + 39, 22, 22), window_frame)
	draw_rect(Rect2(x + 65, y + 41, 18, 18), window_glass)
	draw_rect(Rect2(x + 65, y + 41, 18, 18), window_glow)
	# Window cross
	draw_rect(Rect2(x + 73, y + 41, 2, 18), window_frame)
	draw_rect(Rect2(x + 65, y + 49, 18, 2), window_frame)
	# Window sill
	draw_rect(Rect2(x + 61, y + 61, 26, 4), wood_trim)
	
	# === FOUNDATION ===
	draw_rect(Rect2(x - 2, y + 76, 96, 6), Color(0.45, 0.42, 0.4))
	draw_rect(Rect2(x - 2, y + 76, 96, 2), Color(0.55, 0.52, 0.5))
	
	# === FLOWER BOX ===
	# Under left window
	draw_rect(Rect2(x + 8, y + 64, 20, 5), Color(0.55, 0.4, 0.32))
	for i in range(4):
		var fx = x + 11 + i * 5
		draw_circle(Vector2(fx, y + 63), 3, Color(1.0, 0.5, 0.5))
		draw_circle(Vector2(fx, y + 63), 1.5, Color(1.0, 0.8, 0.3))

func draw_shed(x: float, y: float):
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
	var wood = Color(0.68, 0.52, 0.38)
	var wood_dark = Color(0.52, 0.4, 0.3)
	var wood_light = Color(0.78, 0.62, 0.48)
	var outline = Color(0.15, 0.12, 0.1)
	
	for i in range(count):
		var fx = x + i * 22
		# Posts with depth
		draw_rect(Rect2(fx - 1, y - 1, 7, 22), outline)
		draw_rect(Rect2(fx, y, 5, 20), wood)
		draw_rect(Rect2(fx, y, 2, 20), wood_light)
		draw_rect(Rect2(fx + 3, y, 2, 20), wood_dark)
		# Post cap
		draw_rect(Rect2(fx - 1, y - 2, 7, 3), outline)
		draw_rect(Rect2(fx, y - 1, 5, 2), wood_light)
		
		draw_rect(Rect2(fx + 15, y - 1, 7, 22), outline)
		draw_rect(Rect2(fx + 16, y, 5, 20), wood)
		draw_rect(Rect2(fx + 16, y, 2, 20), wood_light)
		draw_rect(Rect2(fx + 19, y, 2, 20), wood_dark)
		# Post cap
		draw_rect(Rect2(fx + 15, y - 2, 7, 3), outline)
		draw_rect(Rect2(fx + 16, y - 1, 5, 2), wood_light)
		
		# Rails with depth
		draw_rect(Rect2(fx - 1, y + 3, 23, 6), outline)
		draw_rect(Rect2(fx, y + 4, 21, 4), wood)
		draw_rect(Rect2(fx, y + 4, 21, 1), wood_light)
		
		draw_rect(Rect2(fx - 1, y + 11, 23, 6), outline)
		draw_rect(Rect2(fx, y + 12, 21, 4), wood)
		draw_rect(Rect2(fx, y + 12, 21, 1), wood_light)

func draw_farm_plot(x: float, y: float, cols: int, rows: int):
	var soil_dark = Color(0.48, 0.35, 0.25)
	var soil_mid = Color(0.58, 0.42, 0.32)
	var soil_light = Color(0.68, 0.52, 0.4)
	var plant_dark = Color(0.35, 0.55, 0.35)
	var plant_mid = Color(0.45, 0.7, 0.45)
	var plant_light = Color(0.55, 0.8, 0.5)
	
	for i in range(cols):
		for j in range(rows):
			var px = x + i * 26
			var py = y + j * 22
			
			# Soil mound with shading
			draw_rect(Rect2(px - 1, py + 9, 22, 8), Color(0.1, 0.08, 0.06))
			draw_rect(Rect2(px, py + 10, 20, 6), soil_dark)
			draw_rect(Rect2(px + 1, py + 10, 18, 3), soil_mid)
			draw_rect(Rect2(px + 2, py + 10, 16, 1), soil_light)
			
			# Plants with shading
			draw_circle(Vector2(px + 6, py + 6), 6, plant_dark)
			draw_circle(Vector2(px + 6, py + 5), 5, plant_mid)
			draw_circle(Vector2(px + 5, py + 4), 3, plant_light)
			
			draw_circle(Vector2(px + 14, py + 6), 6, plant_dark)
			draw_circle(Vector2(px + 14, py + 5), 5, plant_mid)
			draw_circle(Vector2(px + 13, py + 4), 3, plant_light)
			
			# Water droplets if flowing
			if water_flowing and quest_stage > 7:
				var drop_y = fmod(water_anim + i * 0.5, 1.0) * 10
				draw_circle(Vector2(px + 10, py + drop_y), 2, Color(0.5, 0.75, 1.0, 0.8))

func draw_irrigation_system(x: float, y: float):
	var outline = Color(0.0, 0.0, 0.0)
	
	# Control panel with outline - brighter
	draw_rect(Rect2(x - 1, y - 1, 37, 32), outline)
	draw_rect(Rect2(x, y, 35, 30), Color(0.55, 0.55, 0.6))
	draw_rect(Rect2(x + 2, y + 2, 31, 26), Color(0.35, 0.35, 0.42))
	var light_color = Color(0.3, 1.0, 0.4) if water_flowing else Color(1.0, 0.3, 0.3)
	draw_circle(Vector2(x + 17, y + 15), 7, outline)
	draw_circle(Vector2(x + 17, y + 15), 6, light_color)
	
	# Pipes with outline - brighter
	var pipe_color = Color(0.65, 0.65, 0.7)
	draw_rect(Rect2(x + 34, y + 11, 42, 8), outline)
	draw_rect(Rect2(x + 72, y + 11, 8, 52), outline)
	draw_rect(Rect2(x + 35, y + 12, 40, 6), pipe_color)
	draw_rect(Rect2(x + 73, y + 12, 6, 50), pipe_color)
	
	# Crops next to irrigation
	draw_crops(x + 90, y + 10, water_flowing)
	
	# Water in pipes
	if water_flowing:
		var water_color = Color(0.4, 0.65, 1.0, 0.8)
		draw_rect(Rect2(x + 37, y + 14, 36, 2), water_color)
		draw_rect(Rect2(x + 75, y + 14, 2, 46), water_color)
		
		# Sprinkler effect
		for i in range(3):
			var spray_x = x + 76 + sin(water_anim + i) * 8
			var spray_y = y + 20 + i * 15
			draw_circle(Vector2(spray_x, spray_y), 3, Color(0.5, 0.75, 1.0, 0.6))

func draw_crops(x: float, y: float, healthy: bool):
	var outline = Color(0.0, 0.0, 0.0)
	var stem_color = Color(0.35, 0.55, 0.25) if healthy else Color(0.5, 0.45, 0.3)
	var leaf_color = Color(0.4, 0.7, 0.3) if healthy else Color(0.55, 0.5, 0.35)
	var leaf_highlight = Color(0.5, 0.8, 0.4) if healthy else Color(0.6, 0.55, 0.4)
	
	# Draw 3x2 grid of crops
	for row in range(2):
		for col in range(3):
			var cx = x + col * 22
			var cy = y + row * 25
			
			# Soil mound with outline
			draw_rect(Rect2(cx - 1, cy + 14, 18, 8), outline)
			draw_rect(Rect2(cx, cy + 15, 16, 6), Color(0.45, 0.35, 0.25))
			draw_rect(Rect2(cx + 2, cy + 16, 12, 3), Color(0.5, 0.4, 0.3))
			
			# Plant stem with outline
			draw_rect(Rect2(cx + 6, cy - 2, 4, 18), outline)
			draw_rect(Rect2(cx + 7, cy, 2, 15), stem_color)
			
			# Leaves with outline (left)
			var left_leaf = PackedVector2Array([
				Vector2(cx + 7, cy + 4),
				Vector2(cx - 2, cy + 2),
				Vector2(cx + 2, cy + 8)
			])
			draw_colored_polygon(left_leaf, outline)
			var left_leaf_fill = PackedVector2Array([
				Vector2(cx + 6, cy + 4),
				Vector2(cx, cy + 3),
				Vector2(cx + 3, cy + 7)
			])
			draw_colored_polygon(left_leaf_fill, leaf_color)
			
			# Leaves with outline (right)
			var right_leaf = PackedVector2Array([
				Vector2(cx + 9, cy + 6),
				Vector2(cx + 18, cy + 3),
				Vector2(cx + 14, cy + 10)
			])
			draw_colored_polygon(right_leaf, outline)
			var right_leaf_fill = PackedVector2Array([
				Vector2(cx + 10, cy + 6),
				Vector2(cx + 16, cy + 4),
				Vector2(cx + 13, cy + 9)
			])
			draw_colored_polygon(right_leaf_fill, leaf_color)
			
			# Top leaves
			var top_leaf = PackedVector2Array([
				Vector2(cx + 8, cy - 2),
				Vector2(cx + 4, cy - 8),
				Vector2(cx + 12, cy - 8)
			])
			draw_colored_polygon(top_leaf, outline)
			var top_leaf_fill = PackedVector2Array([
				Vector2(cx + 8, cy - 1),
				Vector2(cx + 5, cy - 6),
				Vector2(cx + 11, cy - 6)
			])
			draw_colored_polygon(top_leaf_fill, leaf_highlight)
			
			# Veins on leaves
			draw_line(Vector2(cx + 6, cy + 5), Vector2(cx + 2, cy + 5), Color(0.3, 0.5, 0.2), 1)
			draw_line(Vector2(cx + 10, cy + 7), Vector2(cx + 14, cy + 6), Color(0.3, 0.5, 0.2), 1)

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
	# Stone archway with outlines
	var stone = Color(0.55, 0.5, 0.45)
	var stone_dark = Color(0.42, 0.38, 0.35)
	var outline = Color(0.0, 0.0, 0.0)
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	
	# Sign post (to the left of entrance)
	var sign_x = x - 45
	var sign_y = y + 5
	
	# Post with outline
	draw_rect(Rect2(sign_x + 8, sign_y + 12, 6, 30), outline)
	draw_rect(Rect2(sign_x + 9, sign_y + 13, 4, 28), wood_dark)
	
	# Sign board with outline
	draw_rect(Rect2(sign_x - 2, sign_y - 2, 44, 18), outline)
	draw_rect(Rect2(sign_x, sign_y, 40, 14), wood)
	draw_rect(Rect2(sign_x + 1, sign_y + 1, 38, 12), Color(0.6, 0.5, 0.38))
	
	# Nails
	draw_circle(Vector2(sign_x + 4, sign_y + 4), 2, Color(0.4, 0.4, 0.45))
	draw_circle(Vector2(sign_x + 36, sign_y + 4), 2, Color(0.4, 0.4, 0.45))
	
	# Text on sign
	draw_string(ThemeDB.fallback_font, Vector2(sign_x + 3, sign_y + 11), "SEWERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.2, 0.15))
	
	# Main structure outline
	draw_rect(Rect2(x - 1, y - 1, 52, 47), outline)
	draw_rect(Rect2(x, y, 50, 45), stone)
	draw_rect(Rect2(x + 8, y + 10, 34, 35), Color(0.1, 0.1, 0.12))
	
	# Arch stones with outline
	for i in range(5):
		var ax = x + 5 + i * 10
		draw_rect(Rect2(ax - 1, y - 1, 10, 10), outline)
		draw_rect(Rect2(ax, y, 8, 8), stone_dark)

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
	var outline = Color(0.0, 0.0, 0.0)
	
	# Shadow
	draw_ellipse_shape(Vector2(pos.x, pos.y + 3), Vector2(8, 3), Color(0, 0, 0, 0.25))
	
	# Body outline
	draw_rect(Rect2(pos.x - 7, pos.y - 20, 14, 24), outline)
	draw_circle(Vector2(pos.x, pos.y - 24), 9, outline)
	
	# Shirt - light blue with stripes
	draw_rect(Rect2(pos.x - 6, pos.y - 19, 12, 21), Color(0.55, 0.7, 0.85))
	draw_rect(Rect2(pos.x - 5, pos.y - 18, 10, 19), Color(0.6, 0.75, 0.9))
	# Stripes on shirt
	draw_line(Vector2(pos.x - 4, pos.y - 14), Vector2(pos.x + 4, pos.y - 14), Color(0.5, 0.65, 0.8), 1)
	draw_line(Vector2(pos.x - 4, pos.y - 8), Vector2(pos.x + 4, pos.y - 8), Color(0.5, 0.65, 0.8), 1)
	
	# Shorts
	draw_rect(Rect2(pos.x - 5, pos.y - 3, 4, 5), outline)
	draw_rect(Rect2(pos.x + 1, pos.y - 3, 4, 5), outline)
	draw_rect(Rect2(pos.x - 4, pos.y - 2, 3, 4), Color(0.4, 0.35, 0.5))
	draw_rect(Rect2(pos.x + 1, pos.y - 2, 3, 4), Color(0.4, 0.35, 0.5))
	
	# Face
	draw_circle(Vector2(pos.x, pos.y - 24), 8, Color(1.0, 0.9, 0.8))
	# Rosy cheeks
	draw_circle(Vector2(pos.x - 5, pos.y - 22), 2, Color(1.0, 0.8, 0.8, 0.4))
	draw_circle(Vector2(pos.x + 5, pos.y - 22), 2, Color(1.0, 0.8, 0.8, 0.4))
	
	# Hair - messy brown
	draw_rect(Rect2(pos.x - 6, pos.y - 32, 12, 8), outline)
	draw_rect(Rect2(pos.x - 5, pos.y - 31, 10, 6), Color(0.4, 0.3, 0.22))
	# Hair tufts
	draw_rect(Rect2(pos.x - 3, pos.y - 34, 3, 4), Color(0.45, 0.35, 0.25))
	draw_rect(Rect2(pos.x + 2, pos.y - 33, 2, 3), Color(0.45, 0.35, 0.25))
	
	# Eyes - big and curious
	draw_circle(Vector2(pos.x - 3, pos.y - 24), 2.5, Color(1, 1, 1))
	draw_circle(Vector2(pos.x + 3, pos.y - 24), 2.5, Color(1, 1, 1))
	draw_circle(Vector2(pos.x - 3, pos.y - 24), 1.5, Color(0.2, 0.15, 0.1))
	draw_circle(Vector2(pos.x + 3, pos.y - 24), 1.5, Color(0.2, 0.15, 0.1))
	# Eye shine
	draw_circle(Vector2(pos.x - 2, pos.y - 25), 0.5, Color(1, 1, 1))
	draw_circle(Vector2(pos.x + 4, pos.y - 25), 0.5, Color(1, 1, 1))
	
	# Smile
	draw_arc(Vector2(pos.x, pos.y - 20), 3, 0.3, PI - 0.3, 8, Color(0.3, 0.2, 0.2), 1)

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
	draw_road_sign_vertical(165, 285, "Farm", false)
	
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
	# Draw lakeside scene background (no NPCs, rocks, or dock - those are Y-sorted)
	var water_deep = Color(0.25, 0.42, 0.62)
	var water_mid = Color(0.35, 0.55, 0.75)
	var water_light = Color(0.5, 0.7, 0.88)
	var cliff = Color(0.5, 0.45, 0.4)
	var grass = Color(0.45, 0.65, 0.4)
	
	# Sky gradient
	for i in range(80):
		var t = i / 80.0
		var sky_color = Color(0.45 + t * 0.15, 0.6 + t * 0.12, 0.85 + t * 0.08)
		draw_rect(Rect2(0, i, 480, 1), sky_color)
	
	# Distant mountains with shading
	var mountain_pts = PackedVector2Array([
		Vector2(0, 80), Vector2(80, 30), Vector2(150, 70),
		Vector2(220, 20), Vector2(300, 60), Vector2(380, 25),
		Vector2(480, 80)
	])
	draw_colored_polygon(mountain_pts, Color(0.35, 0.4, 0.48))
	# Mountain highlights
	var highlight_pts = PackedVector2Array([
		Vector2(80, 30), Vector2(100, 50), Vector2(60, 50)
	])
	draw_colored_polygon(highlight_pts, Color(0.45, 0.5, 0.58))
	var highlight_pts2 = PackedVector2Array([
		Vector2(220, 20), Vector2(250, 50), Vector2(190, 50)
	])
	draw_colored_polygon(highlight_pts2, Color(0.45, 0.5, 0.58))
	
	# Lake with depth
	draw_rect(Rect2(0, 80, 480, 150), water_deep)
	draw_rect(Rect2(0, 90, 480, 100), water_mid)
	# Water ripples
	for i in range(12):
		var rx = 30 + i * 38
		var ry = 115 + sin(continuous_timer * 2 + i * 0.7) * 4
		draw_rect(Rect2(rx, ry, 28, 2), water_light)
		draw_rect(Rect2(rx + 5, ry + 8, 20, 1), Color(1, 1, 1, 0.2))
	
	# Shore
	draw_rect(Rect2(0, 230, 480, 90), grass)
	# Sand strip with gradient
	draw_rect(Rect2(0, 222, 480, 12), Color(0.75, 0.65, 0.5))
	draw_rect(Rect2(0, 222, 480, 4), Color(0.8, 0.7, 0.55))
	
	# Cliffs on right with shading
	draw_rect(Rect2(380, 100, 100, 130), cliff)
	draw_rect(Rect2(380, 100, 15, 130), Color(0.42, 0.38, 0.35))
	draw_rect(Rect2(465, 100, 15, 130), Color(0.58, 0.52, 0.48))
	draw_rect(Rect2(400, 80, 80, 30), Color(0.55, 0.5, 0.45))
	# Note: Dock and rocks drawn by Y-sorted entity system

func draw_lakeside_area_overlay():
	# Journal page sparkle
	draw_area_journal_sparkles("lakeside")
	
	# Exit sign (on shore grass, left side of path)
	draw_road_sign_vertical(165, 240, "Farm", true)
	
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
	
	# Base grass
	var grass_dark = Color(0.35, 0.55, 0.32)
	var grass_mid = Color(0.45, 0.68, 0.38)
	var grass_light = Color(0.52, 0.75, 0.42)
	
	# Draw grass base
	for x in range(0, 480, 12):
		for y in range(0, 320, 12):
			var variation = fmod((x * 7 + y * 13), 3)
			var color = grass_mid
			if variation == 0:
				color = grass_dark
			elif variation == 2:
				color = grass_light
			draw_rect(Rect2(x, y, 12, 12), color)
	
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
	# Smaller, more proportionate fountain
	var stone = Color(0.55, 0.52, 0.48)
	var stone_dark = Color(0.42, 0.4, 0.38)
	var water = Color(0.4, 0.6, 0.85)
	var water_light = Color(0.6, 0.8, 0.95)
	
	# Outer rim (scaled down)
	draw_circle(Vector2(240, 170), 24, stone_dark)
	draw_circle(Vector2(240, 170), 22, stone)
	
	# Water
	draw_circle(Vector2(240, 170), 18, water)
	
	# Water ripples (animated)
	var ripple1 = sin(continuous_timer * 2) * 2
	var ripple2 = sin(continuous_timer * 2 + 2) * 2
	draw_circle(Vector2(240, 170), 6 + ripple1, water_light)
	draw_circle(Vector2(240, 170), 12 + ripple2, Color(water_light.r, water_light.g, water_light.b, 0.5))
	
	# Center pedestal
	draw_circle(Vector2(240, 170), 5, stone)
	draw_rect(Rect2(238, 158, 4, 12), stone_dark)
	
	# Water spout (animated)
	var spout_height = 8 + sin(continuous_timer * 4) * 2
	draw_rect(Rect2(239, 158 - spout_height, 2, spout_height), water_light)
	# Water drops
	for i in range(3):
		var drop_y = fmod(continuous_timer * 40 + i * 10, 18)
		var drop_x = sin(continuous_timer * 3 + i) * 5
		draw_circle(Vector2(240 + drop_x, 152 + drop_y), 1.5, water_light)

func draw_flower_bed(x: float, y: float, count: int):
	# Row of colorful flowers
	var flower_colors = [Color(1, 0.4, 0.5), Color(1, 0.9, 0.3), Color(0.9, 0.5, 0.9), Color(1, 0.6, 0.3)]
	for i in range(count):
		var fx = x + i * 12
		var color = flower_colors[i % flower_colors.size()]
		# Stem
		draw_rect(Rect2(fx + 2, y + 4, 2, 6), Color(0.3, 0.5, 0.3))
		# Flower petals
		draw_circle(Vector2(fx + 3, y + 3), 4, color)
		draw_circle(Vector2(fx + 3, y + 3), 2, Color(1, 0.95, 0.7))

func draw_barrel(x: float, y: float):
	var wood = Color(0.55, 0.38, 0.25)
	var wood_dark = Color(0.42, 0.28, 0.18)
	var metal = Color(0.4, 0.38, 0.35)
	
	# Barrel body
	draw_ellipse_shape(Vector2(x + 10, y + 18), Vector2(10, 5), Color(0, 0, 0, 0.2))  # Shadow
	draw_rect(Rect2(x + 2, y, 16, 18), wood)
	draw_rect(Rect2(x, y + 2, 20, 14), wood)
	
	# Wood grain
	draw_rect(Rect2(x + 6, y + 1, 2, 16), wood_dark)
	draw_rect(Rect2(x + 12, y + 1, 2, 16), wood_dark)
	
	# Metal bands
	draw_rect(Rect2(x, y + 3, 20, 2), metal)
	draw_rect(Rect2(x, y + 12, 20, 2), metal)

func draw_market_stall(x: float, y: float):
	var wood = Color(0.6, 0.45, 0.32)
	var awning = Color(0.85, 0.35, 0.3)
	var awning_stripe = Color(0.95, 0.9, 0.85)
	
	# Counter
	draw_rect(Rect2(x, y + 25, 60, 20), wood)
	draw_rect(Rect2(x, y + 23, 60, 4), Color(0.5, 0.38, 0.28))
	
	# Awning with stripes
	for i in range(6):
		var color = awning if i % 2 == 0 else awning_stripe
		draw_rect(Rect2(x + i * 10, y, 10, 25), color)
	
	# Awning edge
	var awning_pts = PackedVector2Array([
		Vector2(x, y + 25),
		Vector2(x + 60, y + 25),
		Vector2(x + 55, y + 30),
		Vector2(x + 5, y + 30)
	])
	draw_colored_polygon(awning_pts, awning)
	
	# Goods on counter (produce)
	draw_circle(Vector2(x + 12, y + 32), 5, Color(0.9, 0.2, 0.2))  # Tomato
	draw_circle(Vector2(x + 25, y + 33), 4, Color(0.95, 0.8, 0.2))  # Lemon
	draw_circle(Vector2(x + 38, y + 32), 5, Color(0.3, 0.7, 0.3))  # Lettuce
	draw_circle(Vector2(x + 50, y + 33), 4, Color(0.9, 0.5, 0.2))  # Orange

func draw_bench(x: float, y: float):
	var wood = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	
	# Seat
	draw_rect(Rect2(x, y, 30, 6), wood)
	draw_rect(Rect2(x, y, 30, 2), wood_dark)
	
	# Legs
	draw_rect(Rect2(x + 3, y + 5, 4, 8), wood_dark)
	draw_rect(Rect2(x + 23, y + 5, 4, 8), wood_dark)

func draw_lamp_post(x: float, y: float):
	var metal = Color(0.25, 0.25, 0.28)
	var light = Color(1, 0.95, 0.7)
	
	# Post
	draw_rect(Rect2(x, y, 4, 35), metal)
	
	# Lamp housing
	draw_rect(Rect2(x - 4, y - 5, 12, 8), metal)
	
	# Light glow
	var glow_alpha = 0.3 + sin(continuous_timer * 2) * 0.1
	draw_circle(Vector2(x + 2, y - 1), 6, Color(light.r, light.g, light.b, glow_alpha))

func draw_town_building_shop():
	# Charming general store with awning and details
	var building = Color(0.78, 0.65, 0.52)
	var building_dark = Color(0.65, 0.52, 0.42)
	var roof = Color(0.45, 0.32, 0.25)
	var roof_light = Color(0.55, 0.4, 0.32)
	var window = Color(0.5, 0.65, 0.85)
	var awning = Color(0.25, 0.5, 0.35)
	var outline = Color(0.15, 0.12, 0.1)
	
	# Shadow
	draw_ellipse_shape(Vector2(70, 92), Vector2(45, 8), Color(0, 0, 0, 0.15))
	
	# Main building with outline
	draw_rect(Rect2(29, 19, 82, 72), outline)
	draw_rect(Rect2(30, 20, 80, 70), building)
	draw_rect(Rect2(30, 20, 80, 8), building_dark)
	
	# Roof with shingles
	draw_rect(Rect2(24, 9, 92, 16), outline)
	draw_rect(Rect2(25, 10, 90, 14), roof)
	for i in range(9):
		draw_rect(Rect2(27 + i * 10, 12, 8, 4), roof_light)
	
	# Windows with frames
	draw_rect(Rect2(35, 35, 22, 18), outline)
	draw_rect(Rect2(36, 36, 20, 16), window)
	draw_rect(Rect2(45, 36, 2, 16), outline)  # Mullion
	draw_rect(Rect2(36, 43, 20, 2), outline)
	
	draw_rect(Rect2(83, 35, 22, 18), outline)
	draw_rect(Rect2(84, 36, 20, 16), window)
	draw_rect(Rect2(93, 36, 2, 16), outline)
	draw_rect(Rect2(84, 43, 20, 2), outline)
	
	# Flower boxes under windows
	draw_rect(Rect2(35, 53, 22, 5), Color(0.5, 0.35, 0.25))
	draw_rect(Rect2(83, 53, 22, 5), Color(0.5, 0.35, 0.25))
	for i in range(3):
		draw_circle(Vector2(40 + i * 7, 53), 3, Color(1, 0.4, 0.5))
		draw_circle(Vector2(88 + i * 7, 53), 3, Color(0.9, 0.8, 0.3))
	
	# Door with awning
	draw_rect(Rect2(59, 58, 22, 32), outline)
	draw_rect(Rect2(60, 59, 20, 31), Color(0.4, 0.28, 0.2))
	draw_rect(Rect2(60, 59, 20, 3), Color(0.5, 0.35, 0.25))
	# Door handle
	draw_circle(Vector2(76, 75), 2, Color(0.8, 0.7, 0.4))
	
	# Shop awning
	for i in range(3):
		var stripe_color = awning if i % 2 == 0 else Color(0.9, 0.88, 0.82)
		draw_rect(Rect2(56 + i * 10, 52, 10, 8), stripe_color)
	
	# Sign
	draw_rect(Rect2(50, 26, 40, 12), Color(0.6, 0.5, 0.38))
	draw_string(ThemeDB.fallback_font, Vector2(55, 35), "SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.2, 0.18, 0.15))

func draw_town_building_hall():
	# Grand town hall - larger and more impressive
	var building = Color(0.82, 0.75, 0.65)
	var building_accent = Color(0.7, 0.62, 0.52)
	var roof = Color(0.48, 0.35, 0.28)
	var roof_light = Color(0.58, 0.42, 0.32)
	var window = Color(0.5, 0.62, 0.82)
	var door = Color(0.38, 0.28, 0.22)
	var outline = Color(0.15, 0.12, 0.1)
	var gold = Color(0.85, 0.7, 0.35)
	
	# Shadow
	draw_ellipse_shape(Vector2(240, 102), Vector2(65, 10), Color(0, 0, 0, 0.15))
	
	# Main building
	draw_rect(Rect2(169, 14, 142, 88), outline)
	draw_rect(Rect2(170, 15, 140, 86), building)
	
	# Decorative columns
	draw_rect(Rect2(178, 40, 10, 60), building_accent)
	draw_rect(Rect2(292, 40, 10, 60), building_accent)
	draw_rect(Rect2(178, 35, 10, 8), building)
	draw_rect(Rect2(292, 35, 10, 8), building)
	
	# Roof with peaked center
	draw_rect(Rect2(164, 4, 152, 16), outline)
	draw_rect(Rect2(165, 5, 150, 14), roof)
	# Roof tiles
	for i in range(15):
		draw_rect(Rect2(167 + i * 10, 7, 8, 5), roof_light)
	
	# Central pediment (triangle)
	var pediment = PackedVector2Array([
		Vector2(210, 5),
		Vector2(270, 5),
		Vector2(240, -10)
	])
	draw_colored_polygon(pediment, roof)
	draw_circle(Vector2(240, -2), 6, gold)  # Decorative circle
	
	# Windows - three across
	for i in range(3):
		var wx = 192 + i * 35
		draw_rect(Rect2(wx - 1, 39, 27, 24), outline)
		draw_rect(Rect2(wx, 40, 25, 22), window)
		draw_rect(Rect2(wx + 11, 40, 3, 22), outline)
		draw_rect(Rect2(wx, 50, 25, 2), outline)
	
	# Grand double doors
	draw_rect(Rect2(218, 65, 44, 36), outline)
	draw_rect(Rect2(219, 66, 42, 35), door)
	draw_rect(Rect2(239, 66, 3, 35), outline)  # Door split
	# Door handles
	draw_circle(Vector2(235, 83), 3, gold)
	draw_circle(Vector2(245, 83), 3, gold)
	
	# Steps
	draw_rect(Rect2(215, 100, 50, 4), Color(0.6, 0.58, 0.55))
	draw_rect(Rect2(212, 103, 56, 4), Color(0.55, 0.52, 0.5))
	
	# "TOWN HALL" sign
	draw_rect(Rect2(205, 22, 70, 14), Color(0.5, 0.4, 0.32))
	draw_string(ThemeDB.fallback_font, Vector2(210, 32), "TOWN HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, gold)

func draw_town_building_bakery():
	# Cozy bakery with warm colors
	var building = Color(0.9, 0.78, 0.65)
	var building_dark = Color(0.78, 0.65, 0.52)
	var roof = Color(0.7, 0.45, 0.35)
	var roof_light = Color(0.8, 0.55, 0.42)
	var window = Color(0.55, 0.68, 0.88)
	var awning = Color(0.85, 0.55, 0.4)
	var outline = Color(0.15, 0.12, 0.1)
	
	# Shadow
	draw_ellipse_shape(Vector2(405, 92), Vector2(40, 7), Color(0, 0, 0, 0.15))
	
	# Building
	draw_rect(Rect2(369, 24, 72, 68), outline)
	draw_rect(Rect2(370, 25, 70, 66), building)
	draw_rect(Rect2(370, 25, 70, 6), building_dark)
	
	# Roof
	draw_rect(Rect2(364, 14, 82, 16), outline)
	draw_rect(Rect2(365, 15, 80, 14), roof)
	for i in range(8):
		draw_rect(Rect2(367 + i * 10, 17, 8, 5), roof_light)
	
	# Chimney with smoke
	draw_rect(Rect2(415, 2, 12, 18), Color(0.6, 0.4, 0.35))
	# Animated smoke puffs
	var smoke_y = fmod(continuous_timer * 15, 20)
	draw_circle(Vector2(421, -smoke_y), 4 + smoke_y * 0.2, Color(0.8, 0.8, 0.8, 0.5 - smoke_y * 0.02))
	draw_circle(Vector2(418, -smoke_y - 8), 3 + smoke_y * 0.15, Color(0.85, 0.85, 0.85, 0.4 - smoke_y * 0.015))
	
	# Large display window
	draw_rect(Rect2(374, 40, 32, 25), outline)
	draw_rect(Rect2(375, 41, 30, 23), window)
	# Baked goods in window
	draw_circle(Vector2(382, 55), 4, Color(0.85, 0.65, 0.35))  # Bread
	draw_circle(Vector2(392, 56), 3, Color(0.9, 0.75, 0.5))   # Roll
	draw_rect(Rect2(398, 52, 5, 8), Color(0.75, 0.55, 0.35))  # Baguette
	
	# Door
	draw_rect(Rect2(414, 50, 22, 42), outline)
	draw_rect(Rect2(415, 51, 20, 40), Color(0.5, 0.35, 0.28))
	draw_circle(Vector2(431, 72), 2, Color(0.8, 0.7, 0.4))
	
	# Striped awning
	for i in range(4):
		var stripe = awning if i % 2 == 0 else Color(0.95, 0.92, 0.88)
		draw_rect(Rect2(372 + i * 10, 32, 10, 10), stripe)
	
	# Sign with pretzel
	draw_rect(Rect2(378, 68, 30, 10), Color(0.6, 0.45, 0.32))
	draw_string(ThemeDB.fallback_font, Vector2(380, 76), "BAKERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.95, 0.9, 0.8))

func draw_town_building_well():
	# High-quality ornate town well with stone base and wooden roof
	var stone_base = Color(0.62, 0.58, 0.52)
	var stone_mid = Color(0.52, 0.48, 0.44)
	var stone_dark = Color(0.4, 0.38, 0.35)
	var stone_highlight = Color(0.72, 0.68, 0.62)
	var wood_main = Color(0.55, 0.4, 0.3)
	var wood_dark = Color(0.4, 0.3, 0.22)
	var wood_light = Color(0.65, 0.5, 0.38)
	var water_deep = Color(0.2, 0.35, 0.5)
	var water_surface = Color(0.35, 0.55, 0.75)
	var outline = Color(0.12, 0.1, 0.08)
	
	# Shadow
	draw_ellipse_shape(Vector2(240, 308), Vector2(35, 10), Color(0, 0, 0, 0.25))
	
	# === STONE BASE ===
	# Outer stone ring
	draw_circle(Vector2(240, 288), 32, outline)
	draw_circle(Vector2(240, 288), 30, stone_base)
	
	# Stone block texture
	for i in range(10):
		var angle = i * TAU / 10 + 0.15
		var bx = 240 + cos(angle) * 24
		var by = 288 + sin(angle) * 18
		draw_rect(Rect2(bx - 5, by - 4, 10, 8), stone_mid)
		draw_rect(Rect2(bx - 5, by - 4, 10, 2), stone_highlight)
	
	# Inner rings
	draw_circle(Vector2(240, 287), 24, stone_dark)
	draw_circle(Vector2(240, 287), 20, water_deep)
	draw_circle(Vector2(240, 286), 16, water_surface)
	
	# Water ripple animation
	var ripple = sin(continuous_timer * 2.5) * 2
	draw_circle(Vector2(240 + ripple, 285), 8, Color(0.5, 0.7, 0.9, 0.5))
	draw_circle(Vector2(240 - ripple * 0.5, 287), 5, Color(0.6, 0.78, 0.95, 0.3))
	
	# === WOODEN FRAME ===
	# Left post
	draw_rect(Rect2(214, 252, 8, 42), outline)
	draw_rect(Rect2(215, 253, 6, 40), wood_main)
	draw_rect(Rect2(215, 253, 2, 40), wood_light)
	draw_rect(Rect2(219, 253, 2, 40), wood_dark)
	
	# Right post
	draw_rect(Rect2(258, 252, 8, 42), outline)
	draw_rect(Rect2(259, 253, 6, 40), wood_main)
	draw_rect(Rect2(259, 253, 2, 40), wood_light)
	draw_rect(Rect2(263, 253, 2, 40), wood_dark)
	
	# Cross beam
	draw_rect(Rect2(212, 248, 56, 8), outline)
	draw_rect(Rect2(213, 249, 54, 6), wood_main)
	draw_rect(Rect2(213, 249, 54, 2), wood_light)
	
	# === PEAKED ROOF ===
	var roof_pts = PackedVector2Array([
		Vector2(206, 252),
		Vector2(274, 252),
		Vector2(240, 230)
	])
	draw_colored_polygon(roof_pts, outline)
	
	var roof_left = PackedVector2Array([
		Vector2(208, 250),
		Vector2(240, 232),
		Vector2(240, 250)
	])
	draw_colored_polygon(roof_left, wood_dark)
	
	var roof_right = PackedVector2Array([
		Vector2(240, 232),
		Vector2(272, 250),
		Vector2(240, 250)
	])
	draw_colored_polygon(roof_right, wood_main)
	
	# Roof peak cap
	draw_rect(Rect2(237, 228, 6, 6), wood_dark)
	
	# === WINCH ===
	draw_rect(Rect2(220, 262, 40, 5), outline)
	draw_rect(Rect2(221, 263, 38, 3), wood_main)
	
	# Crank handle
	draw_rect(Rect2(262, 260, 8, 4), outline)
	draw_rect(Rect2(263, 261, 6, 2), Color(0.5, 0.45, 0.42))
	draw_rect(Rect2(268, 256, 4, 12), outline)
	draw_rect(Rect2(269, 257, 2, 10), Color(0.5, 0.45, 0.42))
	
	# === BUCKET ===
	draw_line(Vector2(240, 265), Vector2(240, 274), Color(0.55, 0.45, 0.32), 2)
	draw_rect(Rect2(233, 272, 14, 14), outline)
	draw_rect(Rect2(234, 273, 12, 12), Color(0.52, 0.38, 0.28))
	draw_rect(Rect2(234, 273, 12, 3), Color(0.42, 0.3, 0.22))
	# Bucket bands
	draw_rect(Rect2(233, 277, 14, 2), Color(0.38, 0.32, 0.28))
	draw_rect(Rect2(233, 282, 14, 2), Color(0.38, 0.32, 0.28))
	
	# Well sparkle if circuit available
	if not side_circuits_done.well_pump:
		var pulse = (sin(continuous_timer * 3) * 0.3 + 0.7)
		draw_circle(Vector2(240, 283), 12, Color(1, 0.9, 0.4, pulse * 0.4))

func draw_town_building_house1():
	# Quaint cottage on the left
	var building = Color(0.72, 0.62, 0.55)
	var building_dark = Color(0.6, 0.52, 0.45)
	var roof = Color(0.5, 0.38, 0.3)
	var roof_light = Color(0.6, 0.45, 0.35)
	var window = Color(0.5, 0.62, 0.8)
	var outline = Color(0.15, 0.12, 0.1)
	
	# Shadow
	draw_ellipse_shape(Vector2(80, 262), Vector2(35, 7), Color(0, 0, 0, 0.15))
	
	# Building
	draw_rect(Rect2(49, 209, 62, 52), outline)
	draw_rect(Rect2(50, 210, 60, 50), building)
	
	# Roof
	draw_rect(Rect2(44, 199, 72, 16), outline)
	draw_rect(Rect2(45, 200, 70, 14), roof)
	for i in range(7):
		draw_rect(Rect2(47 + i * 10, 202, 8, 5), roof_light)
	
	# Window
	draw_rect(Rect2(54, 220, 20, 18), outline)
	draw_rect(Rect2(55, 221, 18, 16), window)
	draw_rect(Rect2(63, 221, 2, 16), outline)
	
	# Door
	draw_rect(Rect2(82, 228, 18, 32), outline)
	draw_rect(Rect2(83, 229, 16, 31), Color(0.45, 0.32, 0.25))
	draw_circle(Vector2(95, 245), 2, Color(0.75, 0.65, 0.4))
	
	# Flower box
	draw_rect(Rect2(54, 238, 20, 4), Color(0.5, 0.35, 0.25))
	draw_circle(Vector2(59, 237), 3, Color(0.95, 0.5, 0.5))
	draw_circle(Vector2(69, 237), 3, Color(0.5, 0.6, 0.9))

func draw_town_building_house2():
	# Cottage on the right with different style
	var building = Color(0.75, 0.68, 0.58)
	var building_dark = Color(0.62, 0.55, 0.48)
	var roof = Color(0.55, 0.4, 0.32)
	var roof_light = Color(0.65, 0.48, 0.38)
	var window = Color(0.52, 0.65, 0.82)
	var outline = Color(0.15, 0.12, 0.1)
	
	# Shadow
	draw_ellipse_shape(Vector2(405, 277), Vector2(40, 8), Color(0, 0, 0, 0.15))
	
	# Building
	draw_rect(Rect2(369, 219, 72, 58), outline)
	draw_rect(Rect2(370, 220, 70, 56), building)
	
	# Roof
	draw_rect(Rect2(364, 209, 82, 16), outline)
	draw_rect(Rect2(365, 210, 80, 14), roof)
	for i in range(8):
		draw_rect(Rect2(367 + i * 10, 212, 8, 5), roof_light)
	
	# Two windows
	draw_rect(Rect2(375, 232, 18, 16), outline)
	draw_rect(Rect2(376, 233, 16, 14), window)
	draw_rect(Rect2(383, 233, 2, 14), outline)
	
	draw_rect(Rect2(417, 232, 18, 16), outline)
	draw_rect(Rect2(418, 233, 16, 14), window)
	draw_rect(Rect2(425, 233, 2, 14), outline)
	
	# Door
	draw_rect(Rect2(397, 245, 18, 32), outline)
	draw_rect(Rect2(398, 246, 16, 31), Color(0.42, 0.3, 0.22))
	draw_circle(Vector2(410, 262), 2, Color(0.75, 0.65, 0.4))

# Cornfield buildings
func draw_cornfield_farmhouse():
	draw_rect(Rect2(350, 40, 60, 35), Color(0.7, 0.55, 0.4))
	draw_rect(Rect2(345, 30, 70, 15), Color(0.5, 0.35, 0.25))
	draw_rect(Rect2(370, 55, 15, 20), Color(0.4, 0.3, 0.2))

# Lakeside buildings
func draw_lakeside_dock():
	draw_rect(Rect2(150, 220, 80, 8), Color(0.5, 0.38, 0.28))
	draw_rect(Rect2(145, 210, 6, 30), Color(0.45, 0.35, 0.25))
	draw_rect(Rect2(225, 210, 6, 30), Color(0.45, 0.35, 0.25))

# Cherry blossom tree for town center
func draw_cherry_blossom_tree(x: float, y: float):
	var trunk = Color(0.5, 0.35, 0.28)
	var trunk_dark = Color(0.4, 0.28, 0.2)
	var blossom_dark = Color(0.85, 0.55, 0.7)
	var blossom_mid = Color(0.92, 0.68, 0.8)
	var blossom_light = Color(0.98, 0.82, 0.9)
	var blossom_white = Color(1.0, 0.92, 0.95)
	var outline = Color(0.2, 0.15, 0.12)
	
	# Shadow
	draw_ellipse_shape(Vector2(x + 25, y + 48), Vector2(22, 8), Color(0, 0, 0, 0.15))
	
	# Trunk with outline
	draw_rect(Rect2(x + 18, y + 28, 14, 22), outline)
	draw_rect(Rect2(x + 19, y + 29, 12, 20), trunk)
	draw_rect(Rect2(x + 19, y + 29, 4, 20), trunk_dark)
	
	# Branch extensions
	draw_rect(Rect2(x + 10, y + 30, 10, 4), trunk)
	draw_rect(Rect2(x + 30, y + 32, 10, 4), trunk)
	
	# Blossom clusters - multiple overlapping circles for fluffy look
	# Main canopy
	draw_circle(Vector2(x + 8, y + 28), 14, outline)
	draw_circle(Vector2(x + 42, y + 28), 14, outline)
	draw_circle(Vector2(x + 25, y + 32), 16, outline)
	draw_circle(Vector2(x + 25, y + 18), 13, outline)
	
	draw_circle(Vector2(x + 8, y + 28), 13, blossom_dark)
	draw_circle(Vector2(x + 42, y + 28), 13, blossom_dark)
	draw_circle(Vector2(x + 25, y + 32), 15, blossom_dark)
	draw_circle(Vector2(x + 25, y + 18), 12, blossom_mid)
	
	# Mid layer
	draw_circle(Vector2(x + 12, y + 22), 11, blossom_mid)
	draw_circle(Vector2(x + 38, y + 22), 11, blossom_mid)
	draw_circle(Vector2(x + 25, y + 26), 12, blossom_mid)
	
	# Highlights
	draw_circle(Vector2(x + 18, y + 16), 8, blossom_light)
	draw_circle(Vector2(x + 32, y + 18), 7, blossom_light)
	draw_circle(Vector2(x + 25, y + 22), 6, blossom_white)
	
	# Falling petals (animated)
	var petal_time = continuous_timer * 0.5
	for i in range(4):
		var px = x + 10 + fmod(petal_time * 20 + i * 15, 35)
		var py = y + 35 + fmod(petal_time * 30 + i * 20, 25)
		var sway = sin(petal_time * 3 + i) * 3
		draw_circle(Vector2(px + sway, py), 2, Color(blossom_light.r, blossom_light.g, blossom_light.b, 0.7))

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
	
	# V2: Diverse Community - select sprite based on NPC name hash
	var tex: Texture2D = null
	var hash_val = npc_name.hash() % 11
	
	match hash_val:
		0:
			tex = tex_ninja_villager
		1:
			tex = tex_ninja_villager2
		2:
			tex = tex_ninja_villager3
		3:
			tex = tex_ninja_woman
		4:
			tex = tex_ninja_princess
		5:
			tex = tex_ninja_noble
		6:
			tex = tex_ninja_monk
		7:
			tex = tex_ninja_monk2
		8:
			tex = tex_ninja_master
		9:
			tex = tex_ninja_hunter
		10:
			tex = tex_ninja_inspector
		_:
			tex = tex_ninja_villager
	
	if tex:
		# Use Ninja Adventure sprite
		var frame_size = 16
		var frame = int(fmod(continuous_timer * 2 + pos.x * 0.1, 4))  # Slow idle animation
		var direction = 0  # Face down
		
		var src = Rect2(frame * frame_size, direction * frame_size, frame_size, frame_size)
		var scale = 1.4  # Slightly bigger than player
		var dest = Rect2(anim_pos.x - frame_size * scale / 2, anim_pos.y - frame_size * scale + 4, frame_size * scale, frame_size * scale)
		draw_texture_rect_region(tex, dest, src)
	else:
		# Fallback to colored shapes
		var outline = Color(0, 0, 0)
		var body_color = Color.from_hsv(hash_val / 11.0, 0.4, 0.7)
		
		draw_rect(Rect2(anim_pos.x - 7, anim_pos.y - 25, 14, 25), outline)
		draw_rect(Rect2(anim_pos.x - 6, anim_pos.y - 24, 12, 23), body_color)
		
		# Head
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 30), 7, outline)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 30), 6, Color(0.95, 0.85, 0.75))
		
		# Eyes
		draw_circle(Vector2(anim_pos.x - 2, anim_pos.y - 31), 1.5, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(anim_pos.x + 2, anim_pos.y - 31), 1.5, Color(0.1, 0.1, 0.1))

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
	
	# Draw animals (behind player if lower y)
	for animal in stampede_animals:
		draw_stampede_animal_new(animal, shake_offset)
	
	# Draw player using combat sprite system
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
	draw_rect(Rect2(100, 295, 280, 22), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(110, 310), "Z/[X]=Jump  X/[_]=Spook  C/[O]=Dodge", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.9))
	
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()

func draw_stampede_player(pos: Vector2):
	# Use same sprite system as combat but NO FLIP (like exploration)
	var flash_mod = Color(1, 1, 1, 1)
	if stampede_player_state == "hit":
		flash_mod = Color(2, 1.5, 1.5, 1)
	
	var idle_bob = 0.0
	if stampede_player_state == "idle" and stampede_player_grounded:
		idle_bob = sin(continuous_timer * 3) * 2
	
	# Shadow (only when grounded)
	if stampede_player_grounded:
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 5), Vector2(15, 5), Color(0, 0, 0, 0.3))
	else:
		# Smaller shadow when jumping
		var shadow_scale = 1.0 - (stampede_ground_y - pos.y) / 100.0
		shadow_scale = clamp(shadow_scale, 0.3, 1.0)
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 5), Vector2(15 * shadow_scale, 5 * shadow_scale), Color(0, 0, 0, 0.2))
	
	if tex_player:
		var row = 0
		var frame = player_frame % 6
		# NO FLIP - sprite stays consistent to avoid position shifting (like exploration)
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
				frame = 1  # Mid-action frame
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
		
		# Attack swing effect - show on both sides since attack hits both directions
		if stampede_player_state == "attacking":
			var swing_alpha = 0.8 if stampede_player_state_timer > 0.15 else 0.4
			# Left swing
			draw_arc(Vector2(pos.x - 40, pos.y - 15), 35, deg_to_rad(120), deg_to_rad(240), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
			# Right swing
			draw_arc(Vector2(pos.x + 40, pos.y - 15), 35, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.6, swing_alpha), 5)
			# Impact burst
			if stampede_player_state_timer > 0.18:
				draw_circle(Vector2(pos.x, pos.y - 20), 45, Color(1, 1, 0.7, 0.3))
	else:
		# Fallback drawing
		var body_color = Color(0.4, 0.6, 0.85)
		if stampede_player_state == "hit":
			body_color = Color(0.8, 0.5, 0.5)
		draw_rect(Rect2(pos.x - 10, pos.y - 35, 20, 35), Color(0, 0, 0))
		draw_rect(Rect2(pos.x - 9, pos.y - 34, 18, 33), body_color)
		draw_circle(Vector2(pos.x, pos.y - 40), 10, Color(0, 0, 0))
		draw_circle(Vector2(pos.x, pos.y - 40), 9, Color(0.95, 0.85, 0.75))

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
	
	# Shadow
	if not is_defeated:
		draw_ellipse_shape(Vector2(pos.x, stampede_ground_y + 3), Vector2(18, 5), Color(0, 0, 0, 0.25))
	
	match animal_type:
		ANIMAL_CHICKEN:
			if tex_chicken_sprites:
				# Use chicken sprite - animate running
				var frame_w = 32
				var frame_h = 32
				var frame_idx = int(fmod(continuous_timer * 6 + pos.x * 0.1, 6))
				var frame_col = frame_idx % 2
				var frame_row = frame_idx / 2
				var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
				var dest = Rect2(pos.x - 20, pos.y - 32, 40, 40)
				draw_texture_rect_region(tex_chicken_sprites, dest, src, tint)
			else:
				# Fallback - Body
				draw_circle(Vector2(pos.x, pos.y - 10), 12, Color(1.0 * tint.r, 0.95 * tint.g, 0.9 * tint.b))
				# Head
				draw_circle(Vector2(pos.x + 10, pos.y - 14), 7, Color(1.0 * tint.r, 0.95 * tint.g, 0.9 * tint.b))
				# Beak
				draw_rect(Rect2(pos.x + 15, pos.y - 15, 6, 4), Color(1.0, 0.6, 0.2))
				# Comb
				draw_rect(Rect2(pos.x + 8, pos.y - 23, 7, 6), Color(0.9, 0.2, 0.2))
				# Eye
				draw_circle(Vector2(pos.x + 12, pos.y - 16), 2, Color(0.1, 0.1, 0.1))
			# HP bar
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)
			
		ANIMAL_COW:
			if tex_cow_sprites:
				# Use cow sprite - animate running
				var frame_w = 32
				var frame_h = 32
				var frame_idx = int(fmod(continuous_timer * 4 + pos.x * 0.1, 5))
				var frame_col = frame_idx % 3
				var frame_row = frame_idx / 3
				var src = Rect2(frame_col * frame_w, frame_row * frame_h, frame_w, frame_h)
				var dest = Rect2(pos.x - 28, pos.y - 36, 56, 44)
				draw_texture_rect_region(tex_cow_sprites, dest, src, tint)
			else:
				# Fallback - Body
				draw_rect(Rect2(pos.x - 22, pos.y - 28, 44, 28), Color(0.95 * tint.r, 0.95 * tint.g, 0.95 * tint.b))
				# Spots
				draw_circle(Vector2(pos.x - 8, pos.y - 16), 7, Color(0.3, 0.25, 0.2))
				draw_circle(Vector2(pos.x + 10, pos.y - 20), 6, Color(0.3, 0.25, 0.2))
				# Head
				draw_rect(Rect2(pos.x + 18, pos.y - 32, 20, 22), Color(0.95 * tint.r, 0.95 * tint.g, 0.95 * tint.b))
				# Snout
				draw_rect(Rect2(pos.x + 32, pos.y - 24, 10, 12), Color(0.95, 0.8, 0.75))
				# Eye
				draw_circle(Vector2(pos.x + 26, pos.y - 27), 3, Color(0.1, 0.1, 0.1))
				# Legs
				draw_rect(Rect2(pos.x - 16, pos.y - 5, 6, 8), Color(0.9, 0.9, 0.9))
				draw_rect(Rect2(pos.x + 10, pos.y - 5, 6, 8), Color(0.9, 0.9, 0.9))
			# HP bar
			if not is_defeated:
				draw_animal_hp_bar(pos, animal)
			
		ANIMAL_BULL:
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
		
		ANIMAL_ROBOT:
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
		
		ANIMAL_ROBOT_HEAVY:
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
	var is_punching = punch_effect_timer > 0
	
	if tex_player:
		# Check if texture is large enough for spritesheet format (6 frames * 48px = 288px wide)
		var tex_width = tex_player.get_width()
		var tex_height = tex_player.get_height()
		
		if tex_width >= 288 and tex_height >= 240:
			var row = 0
			# Mystic Woods player.png layout:
			# Row 0: Idle down, Row 1: Idle up, Row 2: Idle side (right)
			# Row 3: Walk down, Row 4: Walk up, Row 5: Walk side (right)
			var flip_h = false
			
			if is_walking:
				match player_facing:
					"down": row = 3   # Walk down
					"up": row = 4     # Walk up
					"right": row = 5  # Walk side right
					"left": 
						row = 5       # Walk side (use right, flip)
						flip_h = true
			else:
				match player_facing:
					"down": row = 0   # Idle down
					"up": row = 1     # Idle up
					"right": row = 2  # Idle side right
					"left": 
						row = 2       # Idle side (use right, flip)
						flip_h = true
			
			var frame = player_frame % 6
			var src = Rect2(frame * 48, row * 48, 48, 48)
			
			# Use negative width for horizontal flip (simpler, no transform issues)
			if flip_h:
				var dest = Rect2(pos.x + 24, pos.y - 40, -48, 48)
				draw_texture_rect_region(tex_player, dest, src)
			else:
				var dest = Rect2(pos.x - 24, pos.y - 40, 48, 48)
				draw_texture_rect_region(tex_player, dest, src)
			# Hiding overlay effect
			if is_hiding:
				draw_circle(pos, 20, Color(0.2, 0.4, 0.3, 0.4))
		else:
			# Texture is wrong size - just draw scaled texture
			var dest = Rect2(pos.x - 16, pos.y - 32, 32, 32)
			draw_texture_rect(tex_player, dest, false)
	else:
		# Fallback with outline
		var outline = Color(0.0, 0.0, 0.0)
		var y_offset = 0
		var height_mod = 0
		if is_hiding:
			y_offset = 10  # Crouch down
			height_mod = -10  # Shorter when hiding
		
		# Shadow
		draw_ellipse_shape(Vector2(pos.x, pos.y + 3), Vector2(10, 4), Color(0, 0, 0, 0.25))
		
		# Body
		draw_rect(Rect2(pos.x - 9, pos.y - 29 + y_offset, 18, 32 + height_mod), outline)
		draw_rect(Rect2(pos.x - 8, pos.y - 28 + y_offset, 16, 30 + height_mod), Color(0.4, 0.6, 0.85))
		# Shirt detail
		draw_rect(Rect2(pos.x - 6, pos.y - 20 + y_offset, 12, 3), Color(0.35, 0.55, 0.8))
		
		# Head
		draw_circle(Vector2(pos.x, pos.y - 32 + y_offset), 9, outline)
		draw_circle(Vector2(pos.x, pos.y - 32 + y_offset), 8, Color(1.0, 0.9, 0.8))
		# Hair
		draw_rect(Rect2(pos.x - 6, pos.y - 40 + y_offset, 12, 6), outline)
		draw_rect(Rect2(pos.x - 5, pos.y - 39 + y_offset, 10, 5), Color(0.3, 0.25, 0.2))
		# Eyes
		draw_circle(Vector2(pos.x - 3, pos.y - 33 + y_offset), 2, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(pos.x + 3, pos.y - 33 + y_offset), 2, Color(0.1, 0.1, 0.1))
		
		# Arms - different poses for punch
		if is_punching:
			draw_punch_arm(pos, y_offset)
		else:
			# Normal arm positions
			draw_rect(Rect2(pos.x - 12, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x + 8, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x - 11, pos.y - 21 + y_offset, 2, 8), Color(1.0, 0.88, 0.75))
			draw_rect(Rect2(pos.x + 9, pos.y - 21 + y_offset, 2, 8), Color(1.0, 0.88, 0.75))
		
		# Hiding indicator
		if is_hiding:
			draw_circle(pos, 20, Color(0.2, 0.4, 0.3, 0.4))

func draw_punch_arm(pos: Vector2, y_offset: float):
	var outline = Color(0.0, 0.0, 0.0)
	var skin = Color(1.0, 0.88, 0.75)
	var fist = Color(0.95, 0.85, 0.7)
	
	# Extend arm based on punch direction
	match punch_direction:
		"right":
			# Right arm extended, left arm back
			draw_rect(Rect2(pos.x - 12, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x - 11, pos.y - 21 + y_offset, 2, 8), skin)
			# Extended punch arm
			draw_rect(Rect2(pos.x + 8, pos.y - 20 + y_offset, 20, 6), outline)
			draw_rect(Rect2(pos.x + 9, pos.y - 19 + y_offset, 18, 4), skin)
			# Fist
			draw_rect(Rect2(pos.x + 25, pos.y - 22 + y_offset, 8, 10), outline)
			draw_rect(Rect2(pos.x + 26, pos.y - 21 + y_offset, 6, 8), fist)
		"left":
			# Left arm extended, right arm back
			draw_rect(Rect2(pos.x + 8, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x + 9, pos.y - 21 + y_offset, 2, 8), skin)
			# Extended punch arm
			draw_rect(Rect2(pos.x - 28, pos.y - 20 + y_offset, 20, 6), outline)
			draw_rect(Rect2(pos.x - 27, pos.y - 19 + y_offset, 18, 4), skin)
			# Fist
			draw_rect(Rect2(pos.x - 33, pos.y - 22 + y_offset, 8, 10), outline)
			draw_rect(Rect2(pos.x - 32, pos.y - 21 + y_offset, 6, 8), fist)
		"up":
			# Both arms normal position, but one raised
			draw_rect(Rect2(pos.x - 12, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x - 11, pos.y - 21 + y_offset, 2, 8), skin)
			# Punch arm going up
			draw_rect(Rect2(pos.x + 6, pos.y - 38 + y_offset, 6, 16), outline)
			draw_rect(Rect2(pos.x + 7, pos.y - 37 + y_offset, 4, 14), skin)
			# Fist
			draw_rect(Rect2(pos.x + 4, pos.y - 46 + y_offset, 10, 8), outline)
			draw_rect(Rect2(pos.x + 5, pos.y - 45 + y_offset, 8, 6), fist)
		"down":
			# One arm punching down
			draw_rect(Rect2(pos.x - 12, pos.y - 22 + y_offset, 4, 10), outline)
			draw_rect(Rect2(pos.x - 11, pos.y - 21 + y_offset, 2, 8), skin)
			# Punch arm going down
			draw_rect(Rect2(pos.x + 6, pos.y - 18 + y_offset, 6, 18), outline)
			draw_rect(Rect2(pos.x + 7, pos.y - 17 + y_offset, 4, 16), skin)
			# Fist
			draw_rect(Rect2(pos.x + 4, pos.y - 2 + y_offset, 10, 8), outline)
			draw_rect(Rect2(pos.x + 5, pos.y - 1 + y_offset, 8, 6), fist)

func draw_grandmother(pos: Vector2):
	# Idle animation - very subtle breathing only
	var idle_bob = sin(continuous_timer * 1.2) * 0.5  # Reduced breathing
	var anim_pos = Vector2(pos.x, pos.y + idle_bob)  # No sway
	
	# Shadow
	draw_ellipse(Vector2(pos.x, pos.y + 2), Vector2(11, 4), Color(0, 0, 0, 0.3))
	
	if tex_ninja_oldwoman:
		# Use Ninja Adventure OldWoman sprite
		# Sprite sheet: 16x16 per frame, 4 rows (directions), 4+ columns (frames)
		var frame_size = 16
		var frame = 0  # Stay on first frame - no walking animation
		var direction = 0  # Face down
		
		var src = Rect2(frame * frame_size, direction * frame_size, frame_size, frame_size)
		var scale = 1.3  # 40% bigger total
		var dest = Rect2(anim_pos.x - frame_size * scale / 2, anim_pos.y - frame_size * scale + 4, frame_size * scale, frame_size * scale)
		draw_texture_rect_region(tex_ninja_oldwoman, dest, src)
	elif tex_grandmother:
		draw_texture(tex_grandmother, anim_pos - Vector2(16, 32))
	else:
		var outline = Color(0.0, 0.0, 0.0)  # Pure black outline
		# Body outline - thicker
		draw_rect(Rect2(anim_pos.x - 13, anim_pos.y - 29, 26, 34), outline)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 33), 13, outline)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 45), 11, outline)
		# Dress - purple with pattern
		draw_rect(Rect2(anim_pos.x - 11, anim_pos.y - 27, 22, 30), Color(0.75, 0.4, 0.75))
		draw_rect(Rect2(anim_pos.x - 10, anim_pos.y - 26, 20, 28), Color(0.85, 0.5, 0.85))
		# Apron
		draw_rect(Rect2(anim_pos.x - 7, anim_pos.y - 20, 14, 20), Color(0.95, 0.95, 0.9))
		draw_rect(Rect2(anim_pos.x - 6, anim_pos.y - 19, 12, 18), Color(1.0, 1.0, 0.95))
		# Dress pattern (small flowers)
		for i in range(3):
			draw_circle(Vector2(anim_pos.x - 8 + i * 8, anim_pos.y - 8), 2, Color(0.6, 0.35, 0.6))
		# Face with outline
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 33), 11, Color(0.95, 0.88, 0.78))
		# Rosy cheeks
		draw_circle(Vector2(anim_pos.x - 6, anim_pos.y - 30), 3, Color(1.0, 0.75, 0.75, 0.5))
		draw_circle(Vector2(anim_pos.x + 6, anim_pos.y - 30), 3, Color(1.0, 0.75, 0.75, 0.5))
		# Hair bun with texture
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 44), 9, Color(0.9, 0.9, 0.9))
		draw_circle(Vector2(anim_pos.x - 3, anim_pos.y - 46), 3, Color(0.95, 0.95, 0.95))
		draw_circle(Vector2(anim_pos.x + 3, anim_pos.y - 46), 3, Color(0.95, 0.95, 0.95))
		# Hair strand lines
		draw_line(Vector2(anim_pos.x - 4, anim_pos.y - 48), Vector2(anim_pos.x - 2, anim_pos.y - 40), Color(0.8, 0.8, 0.8), 1)
		draw_line(Vector2(anim_pos.x + 4, anim_pos.y - 48), Vector2(anim_pos.x + 2, anim_pos.y - 40), Color(0.8, 0.8, 0.8), 1)
		# Eyes with glasses - occasional blink
		var blink = fmod(continuous_timer, 4.0) < 0.15
		draw_rect(Rect2(anim_pos.x - 7, anim_pos.y - 36, 6, 5), outline)
		draw_rect(Rect2(anim_pos.x + 1, anim_pos.y - 36, 6, 5), outline)
		if not blink:
			draw_rect(Rect2(anim_pos.x - 6, anim_pos.y - 35, 4, 3), Color(0.85, 0.9, 0.95))
			draw_rect(Rect2(anim_pos.x + 2, anim_pos.y - 35, 4, 3), Color(0.85, 0.9, 0.95))
			draw_circle(Vector2(anim_pos.x - 4, anim_pos.y - 34), 1, Color(0.2, 0.15, 0.1))
			draw_circle(Vector2(anim_pos.x + 4, anim_pos.y - 34), 1, Color(0.2, 0.15, 0.1))
		# Glasses bridge
		draw_line(Vector2(anim_pos.x - 1, anim_pos.y - 34), Vector2(anim_pos.x + 1, anim_pos.y - 34), outline, 1)
		# Smile
		draw_arc(Vector2(anim_pos.x, anim_pos.y - 29), 4, 0.2, PI - 0.2, 8, Color(0.3, 0.2, 0.2), 1)

func draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func draw_kaido(pos: Vector2):
	# Idle animation - gentle floating/bobbing motion
	var idle_float = sin(continuous_timer * 2.5) * 2.0
	var idle_sway = sin(continuous_timer * 1.2) * 0.8
	var anim_pos = Vector2(pos.x + idle_sway, pos.y + idle_float)
	
	# Antenna glow pulse
	var antenna_glow = sin(continuous_timer * 3) * 0.2 + 0.8
	
	if tex_kaido:
		# Scale to ~90% of original size (5% bigger than before)
		var sprite_width = 14  # Was 13, now 5% bigger
		var sprite_height = 22  # Was 21, now 5% bigger
		var dest = Rect2(anim_pos.x - sprite_width / 2, anim_pos.y - sprite_height + 3, sprite_width, sprite_height)
		draw_texture_rect(tex_kaido, dest, false)
	else:
		var teal = Color(0.4, 0.95, 0.85)
		var outline = Color(0.0, 0.0, 0.0)
		# Antenna outline
		draw_rect(Rect2(anim_pos.x - 1, anim_pos.y - 19, 3, 5), outline)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 19), 3, outline)
		# Body outline (5% bigger)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 8), 10, outline)
		# Antenna fill with glow
		draw_rect(Rect2(anim_pos.x, anim_pos.y - 18, 1, 4), teal)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 19), 2, Color(1.0 * antenna_glow, 0.95 * antenna_glow, 0.5))
		# Body fill (5% bigger)
		draw_circle(Vector2(anim_pos.x, anim_pos.y - 8), 9, teal)
		# Eyes - occasional blink
		var blink = fmod(continuous_timer, 3.0) < 0.1
		if not blink:
			draw_rect(Rect2(anim_pos.x - 4, anim_pos.y - 11, 2, 3), Color(0.05, 0.05, 0.05))
			draw_rect(Rect2(anim_pos.x + 2, anim_pos.y - 11, 2, 3), Color(0.05, 0.05, 0.05))
		else:
			draw_rect(Rect2(anim_pos.x - 4, anim_pos.y - 9, 2, 1), Color(0.05, 0.05, 0.05))
			draw_rect(Rect2(anim_pos.x + 2, anim_pos.y - 9, 2, 1), Color(0.05, 0.05, 0.05))

func draw_farmer_wen(pos: Vector2):
	# Asian farmer with conical hat - detailed version
	# Idle animation - subtle breathing and weight shifting
	var idle_bob = sin(continuous_timer * 1.2) * 1.0
	var idle_sway = sin(continuous_timer * 0.6 + 0.5) * 0.8
	var anim_pos = Vector2(pos.x + idle_sway, pos.y + idle_bob)
	
	var outline = Color(0.0, 0.0, 0.0)
	var skin_color = Color(0.92, 0.78, 0.62)
	var skin_shadow = Color(0.82, 0.68, 0.52)
	
	# Shadow (stays in place)
	draw_ellipse_shape(Vector2(pos.x, pos.y + 5), Vector2(14, 5), Color(0, 0, 0, 0.3))
	
	# Legs
	draw_rect(Rect2(anim_pos.x - 6, anim_pos.y - 8, 5, 12), outline)
	draw_rect(Rect2(anim_pos.x + 1, anim_pos.y - 8, 5, 12), outline)
	draw_rect(Rect2(anim_pos.x - 5, anim_pos.y - 7, 3, 10), Color(0.35, 0.3, 0.25))  # Dark pants
	draw_rect(Rect2(anim_pos.x + 2, anim_pos.y - 7, 3, 10), Color(0.35, 0.3, 0.25))
	
	# Boots
	draw_rect(Rect2(anim_pos.x - 7, anim_pos.y + 1, 6, 4), outline)
	draw_rect(Rect2(anim_pos.x + 1, anim_pos.y + 1, 6, 4), outline)
	draw_rect(Rect2(anim_pos.x - 6, anim_pos.y + 2, 4, 2), Color(0.3, 0.25, 0.2))
	draw_rect(Rect2(anim_pos.x + 2, anim_pos.y + 2, 4, 2), Color(0.3, 0.25, 0.2))
	
	# Torso - traditional work tunic
	draw_rect(Rect2(anim_pos.x - 11, anim_pos.y - 30, 22, 24), outline)
	draw_rect(Rect2(anim_pos.x - 10, anim_pos.y - 29, 20, 22), Color(0.55, 0.45, 0.35))  # Base
	draw_rect(Rect2(anim_pos.x - 9, anim_pos.y - 28, 18, 20), Color(0.65, 0.55, 0.42))   # Main tunic color
	
	# Tunic fold details
	draw_line(Vector2(anim_pos.x - 2, anim_pos.y - 28), Vector2(anim_pos.x - 2, anim_pos.y - 10), Color(0.55, 0.45, 0.35), 1)
	draw_line(Vector2(anim_pos.x + 2, anim_pos.y - 28), Vector2(anim_pos.x + 2, anim_pos.y - 10), Color(0.55, 0.45, 0.35), 1)
	
	# Collar - V-neck showing undershirt
	var collar_pts = PackedVector2Array([
		Vector2(anim_pos.x - 5, anim_pos.y - 29),
		Vector2(anim_pos.x, anim_pos.y - 22),
		Vector2(anim_pos.x + 5, anim_pos.y - 29)
	])
	draw_colored_polygon(collar_pts, Color(0.9, 0.88, 0.82))
	
	# Belt with rope tie
	draw_rect(Rect2(anim_pos.x - 9, anim_pos.y - 12, 18, 4), Color(0.4, 0.32, 0.25))
	draw_rect(Rect2(anim_pos.x - 3, anim_pos.y - 11, 6, 2), Color(0.5, 0.42, 0.32))  # Tie
	
	# Arms - muscular from farm work, with subtle movement
	var arm_sway = sin(continuous_timer * 1.8) * 1.5
	draw_rect(Rect2(anim_pos.x - 14, anim_pos.y - 26 + arm_sway * 0.3, 5, 16), outline)
	draw_rect(Rect2(anim_pos.x + 9, anim_pos.y - 26 - arm_sway * 0.3, 5, 16), outline)
	# Sleeves (rolled up)
	draw_rect(Rect2(anim_pos.x - 13, anim_pos.y - 25 + arm_sway * 0.3, 3, 8), Color(0.65, 0.55, 0.42))
	draw_rect(Rect2(anim_pos.x + 10, anim_pos.y - 25 - arm_sway * 0.3, 3, 8), Color(0.65, 0.55, 0.42))
	# Forearms (bare, tanned)
	draw_rect(Rect2(anim_pos.x - 13, anim_pos.y - 17 + arm_sway * 0.3, 3, 7), skin_shadow)
	draw_rect(Rect2(anim_pos.x + 10, anim_pos.y - 17 - arm_sway * 0.3, 3, 7), skin_shadow)
	# Hands
	draw_circle(Vector2(anim_pos.x - 11, anim_pos.y - 9 + arm_sway * 0.3), 3, skin_color)
	draw_circle(Vector2(anim_pos.x + 11, anim_pos.y - 9 - arm_sway * 0.3), 3, skin_color)
	
	# Neck
	draw_rect(Rect2(anim_pos.x - 3, anim_pos.y - 35, 6, 6), outline)
	draw_rect(Rect2(anim_pos.x - 2, anim_pos.y - 34, 4, 5), skin_shadow)
	
	# Head - rounder, more detailed face
	draw_circle(Vector2(anim_pos.x, anim_pos.y - 42), 12, outline)
	draw_circle(Vector2(anim_pos.x, anim_pos.y - 42), 11, skin_color)
	
	# Face shadow under hat
	draw_arc(Vector2(anim_pos.x, anim_pos.y - 42), 10, PI + 0.3, TAU - 0.3, 12, skin_shadow, 4)
	
	# Eyebrows - thick, expressive
	draw_line(Vector2(anim_pos.x - 7, anim_pos.y - 47), Vector2(anim_pos.x - 3, anim_pos.y - 46), Color(0.2, 0.15, 0.1), 2)
	draw_line(Vector2(anim_pos.x + 3, anim_pos.y - 46), Vector2(anim_pos.x + 7, anim_pos.y - 47), Color(0.2, 0.15, 0.1), 2)
	
	# Eyes - almond-shaped, friendly (with occasional blink)
	var blink = fmod(continuous_timer + 1.5, 5.0) < 0.12
	if not blink:
		draw_ellipse_shape(Vector2(anim_pos.x - 5, anim_pos.y - 43), Vector2(3, 2), Color(1.0, 1.0, 1.0))
		draw_ellipse_shape(Vector2(anim_pos.x + 5, anim_pos.y - 43), Vector2(3, 2), Color(1.0, 1.0, 1.0))
		# Irises - dark brown
		draw_circle(Vector2(anim_pos.x - 5, anim_pos.y - 43), 1.5, Color(0.2, 0.12, 0.08))
		draw_circle(Vector2(anim_pos.x + 5, anim_pos.y - 43), 1.5, Color(0.2, 0.12, 0.08))
		# Eye highlights
		draw_circle(Vector2(anim_pos.x - 4, anim_pos.y - 44), 0.8, Color(1.0, 1.0, 1.0))
		draw_circle(Vector2(anim_pos.x + 6, anim_pos.y - 44), 0.8, Color(1.0, 1.0, 1.0))
	else:
		# Closed eyes
		draw_line(Vector2(anim_pos.x - 7, anim_pos.y - 43), Vector2(anim_pos.x - 3, anim_pos.y - 43), Color(0.2, 0.12, 0.08), 1)
		draw_line(Vector2(anim_pos.x + 3, anim_pos.y - 43), Vector2(anim_pos.x + 7, anim_pos.y - 43), Color(0.2, 0.12, 0.08), 1)
	
	# Crow's feet (laugh lines) - weathered from sun
	draw_line(Vector2(anim_pos.x - 9, anim_pos.y - 44), Vector2(anim_pos.x - 7, anim_pos.y - 43), Color(0.75, 0.65, 0.55), 1)
	draw_line(Vector2(anim_pos.x - 9, anim_pos.y - 42), Vector2(anim_pos.x - 7, anim_pos.y - 43), Color(0.75, 0.65, 0.55), 1)
	draw_line(Vector2(anim_pos.x + 9, anim_pos.y - 44), Vector2(anim_pos.x + 7, anim_pos.y - 43), Color(0.75, 0.65, 0.55), 1)
	draw_line(Vector2(anim_pos.x + 9, anim_pos.y - 42), Vector2(anim_pos.x + 7, anim_pos.y - 43), Color(0.75, 0.65, 0.55), 1)
	
	# Nose
	draw_line(Vector2(anim_pos.x, anim_pos.y - 42), Vector2(anim_pos.x, anim_pos.y - 38), Color(0.8, 0.68, 0.55), 1)
	draw_line(Vector2(anim_pos.x - 2, anim_pos.y - 38), Vector2(anim_pos.x + 2, anim_pos.y - 38), Color(0.8, 0.68, 0.55), 1)
	
	# Mouth - warm smile
	draw_arc(Vector2(anim_pos.x, anim_pos.y - 35), 4, 0.3, PI - 0.3, 10, Color(0.5, 0.3, 0.25), 2)
	# Smile lines
	draw_line(Vector2(anim_pos.x - 5, anim_pos.y - 37), Vector2(anim_pos.x - 4, anim_pos.y - 34), Color(0.8, 0.68, 0.55), 1)
	draw_line(Vector2(anim_pos.x + 5, anim_pos.y - 37), Vector2(anim_pos.x + 4, anim_pos.y - 34), Color(0.8, 0.68, 0.55), 1)
	
	# Conical straw hat (non la) - larger, more detailed
	var hat_pts_outline = PackedVector2Array([
		Vector2(anim_pos.x - 18, anim_pos.y - 47),
		Vector2(anim_pos.x, anim_pos.y - 68),
		Vector2(anim_pos.x + 18, anim_pos.y - 47)
	])
	draw_colored_polygon(hat_pts_outline, outline)
	
	var hat_pts = PackedVector2Array([
		Vector2(anim_pos.x - 17, anim_pos.y - 48),
		Vector2(anim_pos.x, anim_pos.y - 67),
		Vector2(anim_pos.x + 17, anim_pos.y - 48)
	])
	draw_colored_polygon(hat_pts, Color(0.95, 0.88, 0.6))
	
	# Hat weave pattern
	for i in range(5):
		var t = (i + 1) / 6.0
		var ly = lerp(anim_pos.y - 67, anim_pos.y - 48, t)
		var lw = 17 * t
		draw_line(Vector2(anim_pos.x - lw, ly), Vector2(anim_pos.x + lw, ly), Color(0.85, 0.78, 0.5), 1)
	# Vertical weave
	draw_line(Vector2(anim_pos.x - 8, anim_pos.y - 52), Vector2(anim_pos.x, anim_pos.y - 67), Color(0.85, 0.78, 0.5), 1)
	draw_line(Vector2(anim_pos.x + 8, anim_pos.y - 52), Vector2(anim_pos.x, anim_pos.y - 67), Color(0.85, 0.78, 0.5), 1)
	draw_line(Vector2(anim_pos.x, anim_pos.y - 52), Vector2(anim_pos.x, anim_pos.y - 67), Color(0.85, 0.78, 0.5), 1)
	
	# Hat brim ellipse
	draw_ellipse_shape(Vector2(anim_pos.x, anim_pos.y - 48), Vector2(17, 5), Color(0.9, 0.82, 0.52))
	draw_arc(Vector2(anim_pos.x, anim_pos.y - 48), 17, 0, PI, 16, outline, 2)
	
	# Chin strap
	draw_line(Vector2(anim_pos.x - 12, anim_pos.y - 48), Vector2(anim_pos.x - 8, anim_pos.y - 32), Color(0.4, 0.32, 0.25), 1)
	draw_line(Vector2(anim_pos.x + 12, anim_pos.y - 48), Vector2(anim_pos.x + 8, anim_pos.y - 32), Color(0.4, 0.32, 0.25), 1)
	
	# Stubble
	for i in range(5):
		var sx = anim_pos.x - 4 + i * 2
		draw_circle(Vector2(sx, anim_pos.y - 26), 0.5, Color(0.4, 0.35, 0.3))

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
	if not in_dialogue:
		# Prompts based on current area
		match current_area:
			Area.FARM:
				draw_farm_prompts()
			Area.CORNFIELD:
				draw_cornfield_prompts()
			Area.LAKESIDE:
				draw_lakeside_prompts()
			Area.TOWN_CENTER:
				draw_town_prompts()
	
	draw_quest_box()
	draw_backpack_icon()
	draw_journal_indicator()
	draw_relics_indicator()
	draw_equipped_gadget_indicator()
	draw_area_indicator()
	
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
	elif player_pos.distance_to(shed_pos) < 40:
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
	# Show current area name in corner (LEFT side, after backpack)
	var area_name = ""
	match current_area:
		Area.FARM:
			area_name = "Farm"
		Area.CORNFIELD:
			area_name = "Cornfield"
		Area.LAKESIDE:
			area_name = "Lakeside"
		Area.TOWN_CENTER:
			area_name = "Town Center"
	
	# Always show area name on left side (after backpack icon which is at x=10, width ~30)
	var ax = 45  # Right of backpack
	var ay = 8
	var name_width = area_name.length() * 8 + 16
	draw_rect(Rect2(ax, ay, name_width, 20), Color(0, 0, 0, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(ax + 8, ay + 15), area_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.85, 0.7))

func draw_detection_overlay():
	# Red flash overlay
	var flash = sin(continuous_timer * 6) * 0.1 + 0.3
	draw_rect(Rect2(0, 0, 480, 320), Color(0.8, 0.1, 0.1, flash))
	
	# DETECTED text
	var text_pulse = sin(continuous_timer * 4) * 0.2 + 0.8
	draw_rect(Rect2(140, 120, 200, 80), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(140, 120, 200, 80), Color(1, 0.2, 0.2), false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(175, 160), "DETECTED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.2, 0.2, text_pulse))
	draw_string(ThemeDB.fallback_font, Vector2(165, 185), "Press [X] to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))

func draw_journal_indicator():
	# Show journal page count in corner
	if journal_pages_found.size() > 0:
		var jx = 10
		var jy = 60
		
		# Small book icon
		draw_rect(Rect2(jx, jy, 20, 16), Color(0.5, 0.35, 0.25))
		draw_rect(Rect2(jx + 2, jy + 2, 7, 12), Color(0.9, 0.85, 0.7))
		draw_rect(Rect2(jx + 11, jy + 2, 7, 12), Color(0.85, 0.8, 0.65))
		
		# Page count
		var count_text = str(journal_pages_found.size()) + "/5"
		draw_string(ThemeDB.fallback_font, Vector2(jx + 24, jy + 12), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.85, 0.7))
		
		# Glow if all found
		if journal_pages_found.size() == 5:
			var glow = (sin(continuous_timer * 3) * 0.2 + 0.8)
			draw_rect(Rect2(jx - 2, jy - 2, 24, 20), Color(1, 0.9, 0.4, glow * 0.3), false, 2)

func draw_relics_indicator():
	# Show relic count below journal indicator
	if relics_found.size() > 0:
		var rx = 10
		var ry = 85  # Below journal indicator
		
		# Gear/relic icon
		draw_circle(Vector2(rx + 10, ry + 8), 8, Color(0.6, 0.5, 0.4))
		draw_circle(Vector2(rx + 10, ry + 8), 5, Color(0.4, 0.35, 0.3))
		# Gear teeth
		for i in range(6):
			var angle = i * PI / 3 + continuous_timer * 0.5
			var tx = rx + 10 + cos(angle) * 9
			var ty = ry + 8 + sin(angle) * 9
			draw_circle(Vector2(tx, ty), 2, Color(0.6, 0.5, 0.4))
		
		# Count
		var count_text = str(relics_found.size()) + "/" + str(relic_data.size())
		draw_string(ThemeDB.fallback_font, Vector2(rx + 24, ry + 12), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.7, 0.6))
		
		# Glow if all found
		if relics_found.size() == relic_data.size():
			var glow = (sin(continuous_timer * 3) * 0.2 + 0.8)
			draw_circle(Vector2(rx + 10, ry + 8), 10, Color(0.9, 0.7, 0.3, glow * 0.3))

func draw_equipped_gadget_indicator():
	if equipped_gadget == "":
		return
	
	var ex = 380  # Right side of screen
	var ey = 38   # Below the quest box (which is at y=8, height=24)
	var data = gadget_data.get(equipped_gadget, {})
	var icon_color = data.get("icon_color", Color(0.5, 0.5, 0.5))
	
	# Background box - glow if flashlight is on
	var border_color = Color(0.4, 0.8, 0.75)
	if equipped_gadget == "led_lamp" and flashlight_on:
		border_color = Color(1.0, 0.9, 0.5)
		draw_rect(Rect2(ex - 2, ey - 2, 94, 49), Color(1, 0.95, 0.7, 0.3))
	
	draw_rect(Rect2(ex, ey, 90, 45), Color(0.1, 0.1, 0.15, 0.85))
	draw_rect(Rect2(ex, ey, 90, 45), border_color, false, 2)
	
	# "EQUIPPED" label or "ON" for flashlight
	if equipped_gadget == "led_lamp" and flashlight_on:
		draw_string(ThemeDB.fallback_font, Vector2(ex + 5, ey + 12), "ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.9, 0.5))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(ex + 5, ey + 12), "EQUIPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.6, 0.6))
	
	# Gadget icon
	draw_rect(Rect2(ex + 5, ey + 18, 22, 22), Color(0.2, 0.2, 0.25))
	draw_gadget_mini_icon(equipped_gadget, ex + 16, ey + 29, icon_color)
	
	# Gadget name
	var name_text = data.get("name", equipped_gadget)
	if name_text.length() > 10:
		name_text = name_text.substr(0, 9) + "."
	draw_string(ThemeDB.fallback_font, Vector2(ex + 30, ey + 34), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	
	# Use hint - different for toggle gadgets
	var hint_alpha = 0.5 + sin(continuous_timer * 3) * 0.3
	var hint_text = "[_] Use"
	if equipped_gadget == "led_lamp":
		hint_text = "[_] " + ("Off" if flashlight_on else "On")
	draw_string(ThemeDB.fallback_font, Vector2(ex + 5, ey + 55), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.9, 0.85, hint_alpha))
	
	# Cooldown overlay (not for toggle gadgets that are on)
	if gadget_use_timer > 0 and not (equipped_gadget == "led_lamp" and flashlight_on):
		var cooldown_pct = gadget_use_timer / 0.5
		draw_rect(Rect2(ex, ey, 90, 45 * cooldown_pct), Color(0.2, 0.2, 0.3, 0.7))

func draw_awareness_bar():
	# Far Cry style awareness meter at top center
	var bar_x = 170
	var bar_y = 8
	var bar_width = 140
	var bar_height = 12
	
	# Only show if there's some awareness or hiding
	if awareness_level < 1 and not is_hiding:
		return
	
	# Background
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.15, 0.1, 0.1))
	
	# Fill based on awareness level
	var fill_pct = awareness_level / max_awareness
	var fill_width = bar_width * fill_pct
	
	# Color transitions from yellow to orange to red
	var bar_color = Color(1, 0.8, 0.2)  # Yellow
	if fill_pct > 0.5:
		bar_color = Color(1, 0.5, 0.1)  # Orange
	if fill_pct > 0.8:
		bar_color = Color(1, 0.2, 0.2)  # Red
		# Pulse when nearly detected
		var pulse = sin(continuous_timer * 10) * 0.3 + 0.7
		bar_color.a = pulse
	
	draw_rect(Rect2(bar_x, bar_y, fill_width, bar_height), bar_color)
	
	# Border
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.5, 0.3, 0.3), false, 2)
	
	# Eye icon
	draw_circle(Vector2(bar_x - 12, bar_y + 6), 6, Color(0.8, 0.3, 0.3))
	draw_circle(Vector2(bar_x - 12, bar_y + 6), 3, Color(0.1, 0.1, 0.1))
	
	# Status text
	var status_text = ""
	var near_safe_spot = check_near_hiding_spot()
	
	if is_hiding:
		status_text = "HIDDEN"
		draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 8, bar_y + 10), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.8, 0.4))
	elif near_safe_spot:
		status_text = "SAFE"
		draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 8, bar_y + 10), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.85, 0.5))
	elif fill_pct > 0.8:
		status_text = "DANGER!"
		var flash = sin(continuous_timer * 8) * 0.5 + 0.5
		draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 8, bar_y + 10), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.2, 0.2, flash))
	elif fill_pct > 0.3:
		status_text = "ALERT"
		draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_width + 8, bar_y + 10), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.6, 0.2))
	
	# Kaido tip (non-blocking warning)
	if kaido_tip_timer > 0 and kaido_tip_text != "":
		var tip_alpha = min(1.0, kaido_tip_timer)
		var tip_x = bar_x + bar_width / 2 - 20
		var tip_y = bar_y + 22
		draw_rect(Rect2(tip_x - 5, tip_y - 2, 60, 18), Color(0.1, 0.15, 0.12, 0.9 * tip_alpha))
		draw_rect(Rect2(tip_x - 5, tip_y - 2, 60, 18), Color(0.4, 0.9, 0.8, tip_alpha), false, 1)
		draw_string(ThemeDB.fallback_font, Vector2(tip_x, tip_y + 11), kaido_tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.95, 0.85, tip_alpha))

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
	match gadget_id:
		"led_lamp":
			# Light bulb shape
			draw_circle(Vector2(x, y - 3), 6, icon_color)
			draw_rect(Rect2(x - 3, y + 2, 6, 4), Color(0.3, 0.3, 0.3))
			# Glow
			var glow = (sin(continuous_timer * 4) * 0.3 + 0.7)
			draw_circle(Vector2(x, y - 3), 8, Color(1, 0.9, 0.5, glow * 0.3))
		"not_gate":
			# Triangle with circle (inverter symbol)
			var pts = PackedVector2Array([
				Vector2(x - 6, y - 6),
				Vector2(x - 6, y + 6),
				Vector2(x + 4, y)
			])
			draw_colored_polygon(pts, icon_color)
			draw_circle(Vector2(x + 6, y), 3, icon_color)
		_:
			# Generic gadget icon
			draw_rect(Rect2(x - 5, y - 5, 10, 10), icon_color)

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
		"not_gate":
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
	var alpha = min(component_popup_timer * 2, 1.0)
	
	# Dim background
	draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.7 * alpha))
	
	# Popup box
	var px = 100
	var py = 60
	var pw = 280
	var ph = 200
	
	draw_rect(Rect2(px, py, pw, ph), Color(0.12, 0.1, 0.08, alpha))
	draw_rect(Rect2(px, py, pw, ph), Color(0.8, 0.6, 0.3, alpha), false, 4)
	
	# Header
	draw_string(ThemeDB.fallback_font, Vector2(px + 70, py + 30), "NEW COMPONENT!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.4, alpha))
	
	# Component icon (large)
	var icon_x = px + 20
	var icon_y = py + 50
	draw_rect(Rect2(icon_x, icon_y, 70, 70), Color(0.25, 0.22, 0.2, alpha))
	draw_rect(Rect2(icon_x, icon_y, 70, 70), Color(0.5, 0.45, 0.4, alpha), false, 2)
	
	# Component icon based on type
	var icon_color = component_popup_data.get("icon_color", Color(0.6, 0.6, 0.6))
	draw_circle(Vector2(icon_x + 35, icon_y + 35), 25, Color(icon_color.r, icon_color.g, icon_color.b, alpha))
	
	# Name and descriptions
	var name_text = component_popup_data.get("name", "Unknown")
	var desc_text = component_popup_data.get("desc", "")
	var adventure_text = component_popup_data.get("adventure_use", "")
	
	draw_string(ThemeDB.fallback_font, Vector2(px + 100, icon_y + 20), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, alpha))
	draw_string(ThemeDB.fallback_font, Vector2(px + 100, icon_y + 40), desc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7, alpha))
	
	# Adventure use in box
	draw_rect(Rect2(px + 15, py + 130, pw - 30, 50), Color(0.15, 0.2, 0.18, alpha))
	var wrapped = wrap_text(adventure_text, 35)
	var ty = py + 148
	for line in wrapped:
		draw_string(ThemeDB.fallback_font, Vector2(px + 22, ty), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.9, 0.8, alpha))
		ty += 14
		if ty > py + 175:
			break
	
	# Continue prompt
	if component_popup_timer > 1.0:
		draw_string(ThemeDB.fallback_font, Vector2(px + 90, py + ph - 15), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6, alpha))

func draw_prompt(text: String):
	var prompt = "[X] " + text
	var w = prompt.length() * 8 + 16
	var px = 240 - w / 2
	draw_rect(Rect2(px, 272, w, 24), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(px, 272, w, 24), Color(0.3, 0.75, 0.68), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(px + 8, 290), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func draw_quest_box():
	if current_quest != "":
		var w = min(current_quest.length() * 7 + 20, 200)
		var base_x = 475 - w
		var base_y = 8  # Always at top right
		
		# Bounce and glow when new
		var bounce_offset = 0.0
		var glow_alpha = 0.0
		var text_color = Color(0.5, 0.95, 0.88)
		var border_color = Color(0.3, 0.75, 0.68)
		
		if quest_is_new:
			# Bounce: rapid up/down motion
			bounce_offset = sin(quest_anim_timer * 12) * 4
			
			# Glow: pulsing yellow
			glow_alpha = (sin(quest_anim_timer * 6) * 0.3 + 0.5)
			
			# Brighter yellow colors
			text_color = Color(1.0, 0.95, 0.4)
			border_color = Color(1.0, 0.85, 0.3)
		
		var box_y = base_y + bounce_offset
		
		# Glow effect behind box
		if quest_is_new:
			draw_rect(Rect2(base_x - 4, box_y - 4, w + 8, 32), Color(1.0, 0.9, 0.3, glow_alpha * 0.4))
		
		# Main box
		draw_rect(Rect2(base_x, box_y, w, 24), Color(0, 0, 0, 0.85))
		draw_rect(Rect2(base_x, box_y, w, 24), border_color, false, 2)
		
		# Text
		draw_string(ThemeDB.fallback_font, Vector2(base_x + 6, box_y + 17), current_quest, HORIZONTAL_ALIGNMENT_LEFT, w - 12, 12, text_color)

func draw_backpack_icon():
	var bx = 10
	var by = 8
	
	draw_rect(Rect2(bx, by + 4, 24, 20), Color(0.75, 0.2, 0.2))
	draw_rect(Rect2(bx + 2, by + 6, 20, 16), Color(0.85, 0.3, 0.3))
	draw_rect(Rect2(bx + 6, by, 12, 6), Color(0.7, 0.18, 0.18))
	draw_rect(Rect2(bx + 6, by + 12, 12, 8), Color(0.65, 0.15, 0.15))
	
	if gadgets.size() > 0:
		draw_circle(Vector2(bx + 28, by + 6), 8, Color(0.3, 0.75, 0.65))
		draw_string(ThemeDB.fallback_font, Vector2(bx + 24, by + 10), str(gadgets.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

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
	draw_rect(Rect2(90, box_y + 6, 90, 20), Color(0.12, 0.18, 0.15))
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
				# Use main sprite as portrait - it's taller than wide so adjust
				# Original aspect ~0.6:1, fit in 56x56 box centered
				var pw = 36
				var ph = 58
				draw_texture_rect(tex_kaido, Rect2(32, box_y + 8, pw, ph), false)
			else:
				draw_kaido_portrait_fallback(50, box_y + 40)
		"grandmother":
			if tex_ninja_oldwoman:
				# Use same sprite as on map - first frame, facing down
				var frame_size = 16
				var src = Rect2(0, 0, frame_size, frame_size)  # First frame
				draw_texture_rect_region(tex_ninja_oldwoman, Rect2(22, box_y + 12, 56, 56), src)
			elif tex_grandmother_portrait:
				draw_texture_rect(tex_grandmother_portrait, Rect2(22, box_y + 12, 56, 56), false)
			else:
				draw_grandmother_portrait_fallback(50, box_y + 40)
		"system", "build":
			draw_rect(Rect2(30, box_y + 20, 40, 40), Color(0.25, 0.25, 0.35))
			draw_string(ThemeDB.fallback_font, Vector2(42, box_y + 50), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.9, 0.8, 0.3))
		"farmer_wen":
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

func draw_kaido_portrait_fallback(x: float, y: float):
	var teal = Color(0.3, 0.78, 0.7)
	draw_circle(Vector2(x, y), 22, teal)
	draw_rect(Rect2(x - 12, y - 6, 8, 10), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(x + 4, y - 6, 8, 10), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(x - 2, y - 32, 4, 10), teal)
	draw_circle(Vector2(x, y - 34), 5, Color(1, 0.86, 0.4))

func draw_grandmother_portrait_fallback(x: float, y: float):
	draw_rect(Rect2(x - 16, y - 6, 32, 26), Color(0.5, 0.35, 0.5))
	draw_circle(Vector2(x, y - 14), 14, Color(0.9, 0.8, 0.7))
	draw_circle(Vector2(x, y - 28), 10, Color(0.75, 0.75, 0.78))

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
		play_sfx("menu")
	if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		pause_menu_selection = min(pause_menu_options.size() - 1, pause_menu_selection + 1)
		play_sfx("menu")
	
	# Selection
	var select_pressed = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		select_pressed = true
	
	if select_pressed:
		match pause_menu_selection:
			0:  # Resume
				current_mode = pause_previous_mode
				play_sfx("menu")
			1:  # Journal
				current_mode = GameMode.JOURNAL_VIEW
				play_sfx("menu")
			2:  # Settings (placeholder for now)
				play_sfx("menu")
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
	# Draw Kaido sitting on the workbench using actual sprite
	
	# Shadow on bench
	draw_ellipse_shape(Vector2(x, y + 45), Vector2(20, 6), Color(0, 0, 0, 0.2))
	
	if tex_kaido:
		# Use actual Kaido sprite - fit to reasonable size
		var tex_w = tex_kaido.get_width()
		var tex_h = tex_kaido.get_height()
		# Target size of about 50x70 pixels on bench
		var target_h = 70.0
		var scale = target_h / tex_h
		var final_w = tex_w * scale
		var final_h = tex_h * scale
		var dest = Rect2(x - final_w / 2, y - final_h / 2, final_w, final_h)
		draw_texture_rect(tex_kaido, dest, false)
	else:
		# Fallback procedural
		var outline = Color(0.0, 0.0, 0.0)
		var body_color = Color(0.3, 0.85, 0.75)
		draw_rect(Rect2(x - 14, y - 8, 28, 32), outline)
		draw_rect(Rect2(x - 12, y - 6, 24, 28), body_color)
	
	# Speech bubble with circuit tip - positioned upper-right of Kaido
	var bubble_w = 145
	var bubble_h = 38
	var bubble_x = x - 20
	var bubble_y = y - 70
	
	draw_rect(Rect2(bubble_x, bubble_y, bubble_w, bubble_h), Color(1, 1, 1, 0.95))
	draw_rect(Rect2(bubble_x, bubble_y, bubble_w, bubble_h), Color(0.3, 0.3, 0.35), false, 2)
	# Bubble tail pointing down to Kaido
	draw_polygon(PackedVector2Array([
		Vector2(bubble_x + 15, bubble_y + bubble_h),
		Vector2(bubble_x + 25, bubble_y + bubble_h),
		Vector2(x, y - 35)
	]), PackedColorArray([Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95)]))
	
	# Circuit building tips - rotate every 4 seconds
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
	var alpha = 0.95
	
	draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.7))
	
	# Popup box
	draw_rect(Rect2(40, 30, 400, 260), Color(0.95, 0.92, 0.85, alpha))
	draw_rect(Rect2(40, 30, 400, 260), Color(0.3, 0.25, 0.2, alpha), false, 4)
	
	# Title
	var data = gadget_data.get(current_schematic, {})
	var title = "CIRCUIT: " + data.get("name", "").to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(60, 55), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.15, 0.1))
	
	# Circuit type
	draw_string(ThemeDB.fallback_font, Vector2(60, 75), data.get("circuit", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.35, 0.3))
	
	# Draw breadboard schematic (centered, larger)
	draw_breadboard_schematic(65, 85, current_schematic)
	
	# Components list (to the right of image)
	var components = data.get("components", [])
	draw_string(ThemeDB.fallback_font, Vector2(295, 95), "COMPONENTS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.25, 0.2))
	var cy = 112
	for comp in components:
		draw_string(ThemeDB.fallback_font, Vector2(300, cy), "- " + comp, HORIZONTAL_ALIGNMENT_LEFT, 130, 10, Color(0.4, 0.35, 0.3))
		cy += 16
	
	# Instructions
	draw_string(ThemeDB.fallback_font, Vector2(160, 270), "[X] Build this circuit", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.6, 0.5))

func draw_breadboard_schematic(x: float, y: float, circuit: String):
	# Try texture first
	var tex: Texture2D = null
	match circuit:
		"led_lamp": tex = tex_schematic_led_lamp
		"buzzer_alarm": tex = tex_schematic_buzzer_alarm
		"not_gate": tex = tex_schematic_not_gate
		"light_sensor": tex = tex_schematic_light_sensor
		"led_chain": tex = tex_schematic_led_chain
		"or_gate": tex = tex_schematic_or_gate
	
	if tex:
		var tex_size = tex.get_size()
		var scale_factor = min(220.0 / tex_size.x, 165.0 / tex_size.y)
		var w = tex_size.x * scale_factor
		var h = tex_size.y * scale_factor
		draw_texture_rect(tex, Rect2(x, y, w, h), false)
		return
	
	# Fallback to procedural drawing
	# Breadboard background
	draw_rect(Rect2(x, y, 150, 120), Color(0.95, 0.95, 0.9))
	draw_rect(Rect2(x, y, 150, 120), Color(0.7, 0.65, 0.6), false, 2)
	
	# Power rails
	draw_rect(Rect2(x + 5, y + 5, 140, 10), Color(0.9, 0.3, 0.3, 0.3))
	draw_rect(Rect2(x + 5, y + 105, 140, 10), Color(0.3, 0.3, 0.9, 0.3))
	
	# Holes
	for row in range(8):
		for col in range(12):
			var hx = x + 15 + col * 11
			var hy = y + 25 + row * 10
			draw_circle(Vector2(hx, hy), 2, Color(0.3, 0.3, 0.35))
	
	# Draw circuit-specific components
	match circuit:
		"led_lamp":
			# LED
			draw_circle(Vector2(x + 60, y + 45), 8, Color(1.0, 0.3, 0.2))
			draw_circle(Vector2(x + 60, y + 45), 4, Color(1.0, 0.6, 0.5))
			draw_rect(Rect2(x + 57, y + 53, 2, 15), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(x + 61, y + 53, 2, 12), Color(0.6, 0.6, 0.6))
			
			# Resistor
			draw_rect(Rect2(x + 90, y + 50, 25, 8), Color(0.7, 0.55, 0.4))
			# Color bands
			draw_rect(Rect2(x + 95, y + 50, 3, 8), Color(0.9, 0.5, 0.1))
			draw_rect(Rect2(x + 100, y + 50, 3, 8), Color(0.9, 0.5, 0.1))
			draw_rect(Rect2(x + 105, y + 50, 3, 8), Color(0.4, 0.25, 0.1))
			
			# Wires
			draw_line(Vector2(x + 60, y + 15), Vector2(x + 60, y + 37), Color(0.8, 0.2, 0.2), 2)
			draw_line(Vector2(x + 115, y + 54), Vector2(x + 130, y + 54), Color(0.2, 0.2, 0.2), 2)
			draw_line(Vector2(x + 130, y + 54), Vector2(x + 130, y + 105), Color(0.2, 0.2, 0.2), 2)
		
		"buzzer_alarm":
			# Buzzer
			draw_circle(Vector2(x + 75, y + 50), 15, Color(0.2, 0.2, 0.25))
			draw_circle(Vector2(x + 75, y + 50), 8, Color(0.3, 0.3, 0.35))
			
			# Button
			draw_rect(Rect2(x + 40, y + 70, 20, 15), Color(0.8, 0.3, 0.3))
			draw_rect(Rect2(x + 45, y + 73, 10, 9), Color(0.9, 0.4, 0.4))
		
		"not_gate":
			# Transistor
			draw_circle(Vector2(x + 75, y + 55), 12, Color(0.2, 0.2, 0.25))
			draw_string(ThemeDB.fallback_font, Vector2(x + 68, y + 60), "NPN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.9, 0.9, 0.9))
			
			# Resistors
			draw_rect(Rect2(x + 40, y + 40, 20, 6), Color(0.7, 0.55, 0.4))
			draw_rect(Rect2(x + 100, y + 40, 20, 6), Color(0.7, 0.55, 0.4))
			
			# LED
			draw_circle(Vector2(x + 110, y + 70), 6, Color(1.0, 0.3, 0.2))
		
		"light_sensor":
			# Photoresistor
			draw_circle(Vector2(x + 50, y + 50), 14, Color(0.85, 0.75, 0.4))
			draw_circle(Vector2(x + 50, y + 50), 8, Color(0.7, 0.6, 0.3))
			# Squiggly pattern
			draw_line(Vector2(x + 45, y + 47), Vector2(x + 55, y + 53), Color(0.5, 0.4, 0.2), 2)
			
			# Resistor
			draw_rect(Rect2(x + 85, y + 45, 25, 8), Color(0.7, 0.55, 0.4))
			
			# LED
			draw_circle(Vector2(x + 75, y + 85), 8, Color(1.0, 0.3, 0.2))
			draw_circle(Vector2(x + 75, y + 85), 4, Color(1.0, 0.6, 0.5))
			
			# Wires
			draw_line(Vector2(x + 64, y + 50), Vector2(x + 85, y + 50), Color(0.4, 0.4, 0.8), 2)
		
		"led_chain":
			# Three LEDs in series
			draw_circle(Vector2(x + 35, y + 55), 10, Color(1.0, 0.3, 0.3))
			draw_circle(Vector2(x + 35, y + 55), 5, Color(1.0, 0.6, 0.6))
			
			draw_circle(Vector2(x + 75, y + 55), 10, Color(1.0, 1.0, 0.3))
			draw_circle(Vector2(x + 75, y + 55), 5, Color(1.0, 1.0, 0.6))
			
			draw_circle(Vector2(x + 115, y + 55), 10, Color(0.3, 1.0, 0.3))
			draw_circle(Vector2(x + 115, y + 55), 5, Color(0.6, 1.0, 0.6))
			
			# Connecting wires
			draw_line(Vector2(x + 45, y + 55), Vector2(x + 65, y + 55), Color(0.3, 0.3, 0.3), 2)
			draw_line(Vector2(x + 85, y + 55), Vector2(x + 105, y + 55), Color(0.3, 0.3, 0.3), 2)
			
			# Resistor at end
			draw_rect(Rect2(x + 55, y + 80, 25, 8), Color(0.7, 0.55, 0.4))
		
		"or_gate":
			# Two diodes
			draw_rect(Rect2(x + 30, y + 40, 20, 8), Color(0.2, 0.2, 0.25))
			draw_rect(Rect2(x + 48, y + 40, 4, 8), Color(0.7, 0.7, 0.75))
			
			draw_rect(Rect2(x + 30, y + 70, 20, 8), Color(0.2, 0.2, 0.25))
			draw_rect(Rect2(x + 48, y + 70, 4, 8), Color(0.7, 0.7, 0.75))
			
			# Two buttons
			draw_rect(Rect2(x + 70, y + 35, 18, 14), Color(0.8, 0.3, 0.3))
			draw_rect(Rect2(x + 70, y + 68, 18, 14), Color(0.3, 0.3, 0.8))
			
			# Output LED
			draw_circle(Vector2(x + 110, y + 55), 10, Color(0.3, 0.9, 0.4))
			draw_circle(Vector2(x + 110, y + 55), 5, Color(0.6, 1.0, 0.7))
			
			# Joining wires
			draw_line(Vector2(x + 52, y + 44), Vector2(x + 70, y + 44), Color(0.4, 0.4, 0.4), 2)
			draw_line(Vector2(x + 52, y + 74), Vector2(x + 70, y + 74), Color(0.4, 0.4, 0.4), 2)
func draw_backpack_popup():
	var alpha = clamp(backpack_anim, 0.0, 1.0)
	
	draw_rect(Rect2(0, 0, 480, 320), Color(0, 0, 0, 0.6 * alpha))
	
	var popup_y = 40 - (1.0 - alpha) * 30
	draw_rect(Rect2(70, popup_y, 340, 240), Color(0.15, 0.12, 0.1, alpha))
	draw_rect(Rect2(70, popup_y, 340, 240), Color(0.75, 0.2, 0.2, alpha), false, 4)
	
	# Tab buttons
	var tab_y = popup_y + 8
	var gadget_tab_color = Color(0.4, 0.35, 0.3, alpha) if backpack_tab == 0 else Color(0.25, 0.22, 0.2, alpha)
	var loot_tab_color = Color(0.4, 0.35, 0.3, alpha) if backpack_tab == 1 else Color(0.25, 0.22, 0.2, alpha)
	
	# Gadgets tab
	draw_rect(Rect2(80, tab_y, 80, 24), gadget_tab_color)
	draw_rect(Rect2(80, tab_y, 80, 24), Color(0.6, 0.55, 0.5, alpha) if backpack_tab == 0 else Color(0.4, 0.35, 0.3, alpha), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(95, tab_y + 17), "GADGETS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, alpha) if backpack_tab == 0 else Color(0.6, 0.6, 0.6, alpha))
	
	# Loot tab
	draw_rect(Rect2(165, tab_y, 60, 24), loot_tab_color)
	draw_rect(Rect2(165, tab_y, 60, 24), Color(0.6, 0.55, 0.5, alpha) if backpack_tab == 1 else Color(0.4, 0.35, 0.3, alpha), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(178, tab_y + 17), "LOOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, alpha) if backpack_tab == 1 else Color(0.6, 0.6, 0.6, alpha))
	
	# Tab switch hint
	draw_string(ThemeDB.fallback_font, Vector2(240, tab_y + 17), "L1/R1", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5, alpha))
	
	if backpack_tab == 0:
		# GADGETS TAB
		draw_backpack_gadgets_tab(popup_y, alpha)
	else:
		# LOOT TAB
		draw_backpack_loot_tab(popup_y, alpha)
	
	draw_string(ThemeDB.fallback_font, Vector2(200, popup_y + 228), "[O] Close", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.5, alpha))

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
	var cx = sx + size / 2
	var cy = sy + size / 2
	
	match item:
		"journal":
			# Book/journal icon
			draw_rect(Rect2(cx - 12, cy - 14, 24, 28), Color(0.0, 0.0, 0.0, alpha))  # Outline
			draw_rect(Rect2(cx - 11, cy - 13, 22, 26), Color(0.5, 0.35, 0.25, alpha))  # Cover
			draw_rect(Rect2(cx - 9, cy - 11, 18, 22), Color(0.85, 0.8, 0.7, alpha))   # Pages
			# Spine
			draw_rect(Rect2(cx - 12, cy - 13, 4, 26), Color(0.4, 0.28, 0.2, alpha))
			# Page lines
			for i in range(4):
				draw_line(Vector2(cx - 5, cy - 8 + i * 5), Vector2(cx + 7, cy - 8 + i * 5), Color(0.6, 0.55, 0.5, alpha), 1)
			# Page count badge
			if journal_pages_found.size() > 0:
				draw_circle(Vector2(sx + size - 8, sy + 8), 8, Color(0.8, 0.6, 0.2, alpha))
				draw_string(ThemeDB.fallback_font, Vector2(sx + size - 11, sy + 12), str(journal_pages_found.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, alpha))
		_:
			# Generic item
			draw_rect(Rect2(cx - 10, cy - 10, 20, 20), Color(0.5, 0.5, 0.5, alpha))

func draw_gadget_icon(sx: float, sy: float, size: float, gadget_id: String, alpha: float):
	var cx = sx + size / 2
	var cy = sy + size / 2
	
	match gadget_id:
		"led_lamp":
			# Flashlight shape
			draw_rect(Rect2(cx - 8, cy - 5, 16, 10), Color(0.6, 0.6, 0.65, alpha))
			draw_rect(Rect2(cx + 8, cy - 8, 8, 16), Color(0.7, 0.7, 0.75, alpha))
			draw_circle(Vector2(cx + 18, cy), 5, Color(1.0, 0.9, 0.5, alpha))
		"buzzer_alarm":
			draw_rect(Rect2(sx + 10, sy + 10, 30, 30), Color(0.3, 0.3, 0.35, alpha))
			draw_circle(Vector2(cx, cy), 10, Color(0.25, 0.25, 0.28, alpha))
			draw_circle(Vector2(cx, cy), 5, Color(0.15, 0.15, 0.18, alpha))
		"not_gate":
			draw_rect(Rect2(sx + 12, sy + 15, 26, 20), Color(0.6, 0.4, 0.8, alpha))
			draw_circle(Vector2(sx + 40, cy), 5, Color(1, 1, 1, alpha))
			draw_string(ThemeDB.fallback_font, Vector2(sx + 16, cy + 5), "NOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, alpha))
		"light_sensor":
			draw_circle(Vector2(cx, cy - 5), 12, Color(0.9, 0.8, 0.3, alpha))
			draw_rect(Rect2(cx - 8, cy + 8, 16, 10), Color(0.35, 0.35, 0.38, alpha))
		"led_chain":
			draw_circle(Vector2(sx + 12, cy), 7, Color(1, 0.3, 0.3, alpha))
			draw_circle(Vector2(cx, cy), 7, Color(1, 1, 0.3, alpha))
			draw_circle(Vector2(sx + size - 12, cy), 7, Color(0.3, 1, 0.3, alpha))
		"or_gate":
			draw_rect(Rect2(sx + 10, sy + 12, 30, 26), Color(0.3, 0.6, 0.9, alpha))
			draw_string(ThemeDB.fallback_font, Vector2(sx + 18, cy + 5), "OR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, alpha))
		"tractor_sensor":
			draw_rect(Rect2(sx + 8, sy + 10, 30, 25), Color(0.6, 0.5, 0.35, alpha))
			draw_rect(Rect2(sx + 12, sy + 14, 22, 17), Color(0.75, 0.65, 0.45, alpha))
			draw_line(Vector2(cx, sy + 35), Vector2(cx, sy + 42), Color(0.3, 0.3, 0.3, alpha), 2)

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
			draw_string(ThemeDB.fallback_font, Vector2(280, sig_y), "â€” CARACTACUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.35, 0.3))
		
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
	# No zoom for shed interior - show full dark room
	# Dark interior
	draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.04, 0.03))
	
	# Wooden walls (barely visible)
	for i in range(30):
		var bx = i * 16
		draw_rect(Rect2(bx, 0, 14, 320), Color(0.08 + fmod(i * 0.01, 0.02), 0.06, 0.04))
	
	# Flashlight cone
	var light_radius = 80
	var light_color = Color(1.0, 0.95, 0.7, 0.25)
	draw_circle(flashlight_pos, light_radius, light_color)
	draw_circle(flashlight_pos, light_radius * 0.6, Color(1.0, 0.95, 0.7, 0.15))
	draw_circle(flashlight_pos, light_radius * 0.3, Color(1.0, 0.98, 0.85, 0.1))
	
	# Objects revealed by flashlight
	draw_shed_objects(flashlight_pos)
	
	# Flashlight source indicator
	draw_circle(flashlight_pos, 5, Color(1.0, 0.9, 0.5, 0.8))
	
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()
	
	if not in_dialogue:
		draw_string(ThemeDB.fallback_font, Vector2(150, 300), "D-Pad Move Light   [X] Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.5))

func draw_shed_objects(light_pos: Vector2):
	var outline = Color(0, 0, 0)
	
	# Tools on wall (top left area)
	if light_pos.distance_to(Vector2(100, 80)) < 100:
		var vis = 1.0 - (light_pos.distance_to(Vector2(100, 80)) / 100)
		# Tool board background
		draw_rect(Rect2(59, 49, 82, 62), Color(0, 0, 0, vis))
		draw_rect(Rect2(60, 50, 80, 60), Color(0.35, 0.28, 0.22, vis))
		
		# Wrench with outline
		draw_rect(Rect2(69, 59, 10, 42), Color(0, 0, 0, vis))
		draw_rect(Rect2(70, 60, 8, 40), Color(0.55, 0.55, 0.6, vis))
		draw_rect(Rect2(68, 58, 12, 8), Color(0, 0, 0, vis))
		draw_rect(Rect2(69, 59, 10, 6), Color(0.5, 0.5, 0.55, vis))
		# Wrench head opening
		draw_rect(Rect2(72, 60, 4, 4), Color(0.35, 0.28, 0.22, vis))
		
		# Hammer with outline
		draw_rect(Rect2(89, 54, 6, 52), Color(0, 0, 0, vis))
		draw_rect(Rect2(90, 55, 4, 50), Color(0.6, 0.48, 0.38, vis))  # Wood handle
		draw_rect(Rect2(84, 52, 18, 12), Color(0, 0, 0, vis))
		draw_rect(Rect2(85, 53, 16, 10), Color(0.45, 0.45, 0.5, vis))  # Metal head
		
		# Screwdriver with outline
		draw_rect(Rect2(109, 69, 22, 10), Color(0, 0, 0, vis))
		draw_rect(Rect2(110, 70, 20, 8), Color(0.7, 0.5, 0.35, vis))  # Handle
		draw_rect(Rect2(128, 72, 14, 4), Color(0, 0, 0, vis))
		draw_rect(Rect2(129, 73, 12, 2), Color(0.5, 0.5, 0.55, vis))  # Shaft
		
		# Watering can with outline
		draw_rect(Rect2(64, 85, 28, 22), Color(0, 0, 0, vis))
		draw_rect(Rect2(65, 86, 26, 20), Color(0.5, 0.55, 0.6, vis))
		# Spout
		draw_line(Vector2(91, 90), Vector2(105, 82), Color(0, 0, 0, vis), 4)
		draw_line(Vector2(92, 90), Vector2(104, 83), Color(0.5, 0.55, 0.6, vis), 2)
		# Handle
		draw_arc(Vector2(78, 83), 8, PI, TAU, 8, Color(0, 0, 0, vis), 4)
		draw_arc(Vector2(78, 83), 8, PI, TAU, 8, Color(0.5, 0.55, 0.6, vis), 2)
	
	# Electronic components (top right)
	if light_pos.distance_to(Vector2(300, 100)) < 100:
		var vis = 1.0 - (light_pos.distance_to(Vector2(300, 100)) / 100)
		# Shelf background
		draw_rect(Rect2(259, 59, 102, 82), Color(0, 0, 0, vis))
		draw_rect(Rect2(260, 60, 100, 80), Color(0.35, 0.28, 0.22, vis))
		
		# Glass jars with outlines
		# Jar 1 (LEDs)
		draw_rect(Rect2(269, 79, 27, 37), Color(0, 0, 0, vis))
		draw_rect(Rect2(270, 80, 25, 35), Color(0.7, 0.8, 0.9, vis * 0.4))
		draw_rect(Rect2(270, 76, 25, 6), Color(0, 0, 0, vis))
		draw_rect(Rect2(271, 77, 23, 4), Color(0.5, 0.45, 0.4, vis))  # Lid
		# LEDs inside
		draw_circle(Vector2(278, 95), 3, Color(1, 0.3, 0.3, vis * 0.7))
		draw_circle(Vector2(285, 100), 3, Color(0.3, 1, 0.3, vis * 0.7))
		draw_circle(Vector2(290, 92), 3, Color(1, 1, 0.3, vis * 0.7))
		
		# Jar 2 (Resistors)
		draw_rect(Rect2(299, 84, 22, 32), Color(0, 0, 0, vis))
		draw_rect(Rect2(300, 85, 20, 30), Color(0.7, 0.8, 0.9, vis * 0.4))
		draw_rect(Rect2(300, 81, 20, 6), Color(0, 0, 0, vis))
		draw_rect(Rect2(301, 82, 18, 4), Color(0.5, 0.45, 0.4, vis))
		# Resistors inside (tiny cylinders)
		for i in range(4):
			draw_rect(Rect2(304, 92 + i * 5, 10, 3), Color(0.7, 0.55, 0.4, vis * 0.6))
		
		# Jar 3 (Capacitors)
		draw_rect(Rect2(329, 81, 24, 35), Color(0, 0, 0, vis))
		draw_rect(Rect2(330, 82, 22, 33), Color(0.7, 0.8, 0.9, vis * 0.4))
		draw_rect(Rect2(330, 78, 22, 6), Color(0, 0, 0, vis))
		draw_rect(Rect2(331, 79, 20, 4), Color(0.5, 0.45, 0.4, vis))
		# Capacitors inside
		draw_rect(Rect2(336, 90, 8, 12), Color(0.2, 0.3, 0.5, vis * 0.6))
		draw_rect(Rect2(338, 105, 6, 8), Color(0.2, 0.3, 0.5, vis * 0.6))
		
		# Labels
		draw_string(ThemeDB.fallback_font, Vector2(268, 125), "LEDs", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
		draw_string(ThemeDB.fallback_font, Vector2(298, 125), "RES", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
		draw_string(ThemeDB.fallback_font, Vector2(330, 125), "CAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 0.8, vis))
	
	# Hidden photograph (bottom right behind boxes)
	if light_pos.distance_to(Vector2(360, 250)) < 80:
		var vis = 1.0 - (light_pos.distance_to(Vector2(360, 250)) / 80)
		# Cardboard boxes with outlines
		draw_rect(Rect2(319, 199, 62, 52), Color(0, 0, 0, vis))
		draw_rect(Rect2(320, 200, 60, 50), Color(0.5, 0.42, 0.32, vis))
		draw_line(Vector2(320, 225), Vector2(380, 225), Color(0.4, 0.32, 0.22, vis), 2)
		draw_rect(Rect2(340, 205, 20, 15), Color(0.45, 0.38, 0.28, vis))  # Tape
		
		draw_rect(Rect2(369, 219, 52, 42), Color(0, 0, 0, vis))
		draw_rect(Rect2(370, 220, 50, 40), Color(0.48, 0.4, 0.3, vis))
		draw_line(Vector2(370, 240), Vector2(420, 240), Color(0.38, 0.3, 0.2, vis), 2)
		
		# Photo peeking out with outline
		if shed_explore_stage < 3:
			draw_rect(Rect2(354, 244, 42, 32), Color(0, 0, 0, vis))
			draw_rect(Rect2(355, 245, 40, 30), Color(0.9, 0.85, 0.75, vis * 0.7))
			# Photo border
			draw_rect(Rect2(358, 248, 34, 24), Color(0.75, 0.7, 0.6, vis * 0.6))
			draw_string(ThemeDB.fallback_font, Vector2(340, 285), "Something here...", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.85, 0.7, vis))
	
	# Shelves with outlines
	if light_pos.distance_to(Vector2(240, 150)) < 120:
		var vis = 1.0 - (light_pos.distance_to(Vector2(240, 150)) / 120)
		draw_rect(Rect2(29, 139, 422, 10), Color(0, 0, 0, vis))
		draw_rect(Rect2(30, 140, 420, 8), Color(0.45, 0.38, 0.3, vis))
		draw_rect(Rect2(29, 199, 302, 10), Color(0, 0, 0, vis))
		draw_rect(Rect2(30, 200, 300, 8), Color(0.45, 0.38, 0.3, vis))

# ============================================
# PHOTOGRAPH REVEAL
# ============================================

func draw_photograph_reveal():
	draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.05, 0.08))
	var alpha = clamp(photo_fade, 0.0, 1.0)
	
	# Photo frame
	draw_rect(Rect2(90, 40, 300, 200), Color(0.85, 0.8, 0.7, alpha))
	draw_rect(Rect2(90, 40, 300, 200), Color(0.6, 0.55, 0.45, alpha), false, 4)
	draw_rect(Rect2(100, 50, 280, 150), Color(0.75, 0.68, 0.58, alpha))
	
	# People silhouettes
	var people_y = 130
	# Person 1
	draw_rect(Rect2(120, people_y, 18, 45), Color(0.45, 0.40, 0.35, alpha))
	draw_circle(Vector2(129, people_y - 8), 11, Color(0.55, 0.48, 0.42, alpha))
	# Person 2 (grandmother younger)
	draw_rect(Rect2(155, people_y - 5, 20, 50), Color(0.5, 0.35, 0.45, alpha))
	draw_circle(Vector2(165, people_y - 18), 13, Color(0.55, 0.50, 0.45, alpha))
	# Person 3
	draw_rect(Rect2(195, people_y - 8, 22, 53), Color(0.4, 0.38, 0.35, alpha))
	draw_circle(Vector2(206, people_y - 22), 14, Color(0.52, 0.48, 0.42, alpha))
	# Person 4
	draw_rect(Rect2(240, people_y, 20, 45), Color(0.42, 0.40, 0.38, alpha))
	draw_circle(Vector2(250, people_y - 12), 12, Color(0.5, 0.46, 0.40, alpha))
	
	# Robots
	draw_rect(Rect2(285, people_y + 5, 25, 40), Color(0.45, 0.5, 0.5, alpha))
	draw_rect(Rect2(285, people_y - 5, 25, 12), Color(0.5, 0.55, 0.55, alpha))
	draw_rect(Rect2(320, people_y + 10, 30, 35), Color(0.4, 0.45, 0.45, alpha))
	draw_rect(Rect2(320, people_y, 30, 12), Color(0.45, 0.5, 0.5, alpha))
	
	# "THE RESISTANCE" text on back
	if alpha > 0.7:
		var text_alpha = (alpha - 0.7) / 0.3
		draw_rect(Rect2(140, 205, 200, 30), Color(0.8, 0.75, 0.65, text_alpha))
		draw_string(ThemeDB.fallback_font, Vector2(165, 228), "THE RESISTANCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.35, 0.30, 0.25, text_alpha))
	
	draw_string(ThemeDB.fallback_font, Vector2(160, 265), "AN OLD PHOTOGRAPH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.65, 0.55, alpha))
	
	if photo_fade >= 1.0:
		draw_string(ThemeDB.fallback_font, Vector2(200, 295), "[X] Continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))

# ============================================
# RADIOTOWER VIEW
# ============================================

func draw_radiotower_view():
	# Sky gradient - changes based on time
	if is_nightfall:
		draw_rect(Rect2(0, 0, 480, 160), Color(0.1, 0.1, 0.2))
		draw_rect(Rect2(0, 160, 480, 160), Color(0.15, 0.12, 0.18))
	else:
		draw_rect(Rect2(0, 0, 480, 160), Color(0.3, 0.4, 0.6))
		draw_rect(Rect2(0, 160, 480, 160), Color(0.6, 0.5, 0.4))
	
	# Sun/moon
	if is_nightfall:
		draw_circle(Vector2(400, 60), 25, Color(0.9, 0.9, 0.8))
		# Stars
		for i in range(15):
			var sx = 50 + i * 30 + sin(i * 1.5) * 20
			var sy = 20 + cos(i * 2.3) * 40
			draw_circle(Vector2(sx, sy), 1, Color(1, 1, 1, 0.8))
	else:
		draw_circle(Vector2(380, 50), 30, Color(1.0, 0.9, 0.5))
	
	# Distant view of Agricommune
	draw_rect(Rect2(0, 180, 480, 140), Color(0.45, 0.55, 0.38))
	
	# Miniature buildings
	draw_rect(Rect2(100, 200, 40, 30), Color(0.55, 0.45, 0.38))
	draw_rect(Rect2(200, 210, 30, 25), Color(0.48, 0.38, 0.30))
	draw_rect(Rect2(300, 195, 35, 40), Color(0.5, 0.42, 0.35))
	
	# Roads
	draw_rect(Rect2(0, 240, 480, 20), Color(0.6, 0.48, 0.35))
	
	# Tower structure
	draw_rect(Rect2(10, 50, 8, 270), Color(0.45, 0.35, 0.28))
	draw_rect(Rect2(462, 50, 8, 270), Color(0.45, 0.35, 0.28))
	for i in range(10):
		var ry = 70 + i * 25
		draw_rect(Rect2(10, ry, 25, 4), Color(0.5, 0.40, 0.32))
		draw_rect(Rect2(445, ry, 25, 4), Color(0.5, 0.40, 0.32))
	draw_rect(Rect2(0, 45, 480, 8), Color(0.5, 0.40, 0.32))
	
	# Radio equipment panel
	draw_rect(Rect2(150, 55, 180, 70), Color(0.25, 0.25, 0.28))
	draw_rect(Rect2(150, 55, 180, 70), Color(0.4, 0.4, 0.45), false, 2)
	
	# Beacon indicator
	draw_circle(Vector2(240, 90), 18, Color(0.15, 0.15, 0.18))
	if quest_stage >= 12:
		var glow = (sin(continuous_timer * 3) * 0.3 + 0.7)
		draw_circle(Vector2(240, 90), 15, Color(0.2, 0.8, 0.3, glow))
	elif quest_stage == 11:
		draw_circle(Vector2(240, 90), 15, Color(0.3, 0.3, 0.35))
	
	# Current task display
	var task_text = ""
	var can_leave = can_exit_radiotower()
	
	if quest_stage == 11:
		task_text = "Build: LIGHT SENSOR"
	elif quest_stage == 12:
		task_text = "Build: LED CHAIN"
	elif quest_stage == 13:
		task_text = "Build: OR GATE"
	elif quest_stage >= 14:
		task_text = "All beacons ready!"
	
	# Task box
	draw_rect(Rect2(140, 135, 200, 30), Color(0.1, 0.1, 0.12, 0.9))
	draw_rect(Rect2(140, 135, 200, 30), Color(0.4, 0.6, 0.5, 0.7), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(155, 156), task_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.9, 0.85))
	
	# Controls
	if can_leave:
		draw_string(ThemeDB.fallback_font, Vector2(160, 300), "[X] Continue   [O] Climb Down", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.55, 0.5))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(160, 300), "[X] Build Circuit", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.55, 0.5))
	
	if in_dialogue and not current_dialogue.is_empty():
		draw_dialogue_box()

# ============================================
# ENDING CUTSCENE
# ============================================

func draw_ending_cutscene():
	match ending_stage:
		0:
			# Tunnel entrance
			draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.08, 0.1))
			draw_rect(Rect2(140, 80, 200, 160), Color(0.05, 0.05, 0.08))
			draw_string(ThemeDB.fallback_font, Vector2(170, 180), "ENTERING TUNNEL...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.5, 0.5))
		1:
			# Flames in background
			draw_rect(Rect2(0, 0, 480, 320), Color(0.15, 0.08, 0.05))
			# Fire glow
			for i in range(5):
				var fx = 80 + i * 80
				var fy = 100 + sin(anim_timer * 2 + i) * 20
				draw_circle(Vector2(fx, fy), 30, Color(1.0, 0.5, 0.2, 0.4))
				draw_circle(Vector2(fx, fy - 10), 20, Color(1.0, 0.7, 0.3, 0.3))
			draw_string(ThemeDB.fallback_font, Vector2(140, 280), "Agricommune burns...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.7, 0.5))
		2:
			# Grandmother captured
			draw_rect(Rect2(0, 0, 480, 320), Color(0.1, 0.08, 0.12))
			# Grandmother silhouette
			draw_circle(Vector2(240, 150), 30, Color(0.5, 0.35, 0.5, 0.6))
			# Robot soldiers
			draw_robot_soldier(Vector2(180, 160))
			draw_robot_soldier(Vector2(300, 160))
			draw_string(ThemeDB.fallback_font, Vector2(130, 280), "Grandmother is captured.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.5, 0.5))
		3:
			# Memory stick
			draw_rect(Rect2(0, 0, 480, 320), Color(0.05, 0.05, 0.08))
			# USB stick
			draw_rect(Rect2(200, 130, 80, 30), Color(0.5, 0.5, 0.55))
			draw_rect(Rect2(280, 135, 15, 20), Color(0.6, 0.6, 0.65))
			# Resistance symbol glow
			draw_circle(Vector2(240, 145), 10, Color(0.3, 0.8, 0.7, 0.6))
			draw_string(ThemeDB.fallback_font, Vector2(150, 200), "\"Find Professor Ohm.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 0.75))
			draw_string(ThemeDB.fallback_font, Vector2(150, 230), "\"Show him this.\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 0.75))
		4:
			# Villagers escaping
			draw_rect(Rect2(0, 0, 480, 320), Color(0.08, 0.1, 0.12))
			# Tunnel perspective
			draw_rect(Rect2(100, 60, 280, 200), Color(0.12, 0.14, 0.16))
			draw_rect(Rect2(140, 90, 200, 140), Color(0.1, 0.12, 0.14))
			# Silhouettes walking
			for i in range(5):
				var sx = 180 + i * 25
				var sy = 180 + i * 5
				draw_rect(Rect2(sx, sy - 20, 8, 22), Color(0.3, 0.3, 0.35))
				draw_circle(Vector2(sx + 4, sy - 25), 5, Color(0.35, 0.35, 0.4))
			# Kaido leading
			draw_circle(Vector2(300, 160), 12, Color(0.3, 0.75, 0.7))
			draw_string(ThemeDB.fallback_font, Vector2(140, 290), "To New Sumida City...", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.8, 0.75))

# ============================================
# COMBAT DRAWING
# ============================================

func draw_combat_arena():
	# Apply screen shake
	var shake_offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	
	# Use centered zoom for combat (no camera offset from exploration)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)  # No zoom for combat - show full arena
	
	# Background - irrigation area
	draw_rect(Rect2(0, 0, 480, 320), Color(0.35, 0.55, 0.38))
	
	# Ground with detail
	var ground_y = 240
	draw_rect(Rect2(0, ground_y - 20, 480, 100), Color(0.58, 0.42, 0.32))
	draw_rect(Rect2(0, ground_y - 25, 480, 8), Color(0.65, 0.5, 0.38))
	
	# Arena boundaries (fences)
	draw_rect(Rect2(50, 150, 8, 100), Color(0.5, 0.38, 0.28))
	draw_rect(Rect2(422, 150, 8, 100), Color(0.5, 0.38, 0.28))
	
	# Irrigation pipes in background
	draw_rect(Rect2(0, 180, 50, 6), Color(0.5, 0.5, 0.55))
	draw_rect(Rect2(430, 180, 50, 6), Color(0.5, 0.5, 0.55))
	
	# Draw characters with shake offset
	draw_combat_player(combat_player_pos + shake_offset)
	
	# Draw robots - either tunnel fight (3 robots) or single robot
	if tunnel_fight_active:
		for i in range(tunnel_robots.size()):
			var r = tunnel_robots[i]
			if not r.defeated:
				draw_tunnel_robot(r, shake_offset, i)
			else:
				draw_defeated_robot(r.pos + shake_offset)
	else:
		if not robot_defeated:
			draw_combat_robot(robot_pos + shake_offset)
		else:
			draw_defeated_robot(robot_pos + shake_offset)
	
	# Health bars above characters
	draw_combat_health_bar(combat_player_pos + shake_offset + Vector2(-30, -55), combat_player_hp, combat_player_max_hp, Color(0.3, 0.85, 0.4), "YOU")
	
	# Draw health bars for tunnel robots or single robot
	if tunnel_fight_active:
		for i in range(tunnel_robots.size()):
			var r = tunnel_robots[i]
			if not r.defeated:
				draw_combat_health_bar(r.pos + shake_offset + Vector2(-25, -55), r.hp, r.max_hp, Color(0.9, 0.25, 0.25), "")
	else:
		if not robot_defeated:
			draw_combat_health_bar(robot_pos + shake_offset + Vector2(-30, -65), robot_hp, robot_max_hp, Color(0.9, 0.25, 0.25), "EN-07")
	
	# Stamina bar for player
	draw_stamina_bar(combat_player_pos + shake_offset + Vector2(-30, -45))
	
	# COUNTER INDICATOR - Arkham style flashing triangle when counterable
	# Only for main robot - tunnel robots draw their own indicators
	if counter_window_active and not tunnel_fight_active and not robot_defeated:
		var flash = sin(continuous_timer * 20) * 0.3 + 0.7  # Fast flash
		var counter_color = Color(0.3, 0.9, 1.0, flash)  # Cyan/blue like Arkham
		# Draw triangle symbol above robot
		var tri_pos = robot_pos + shake_offset + Vector2(0, -75)
		draw_string(ThemeDB.fallback_font, tri_pos + Vector2(-8, 0), "â–³", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, counter_color)
		# Pulsing ring around robot
		var ring_size = 30 + sin(continuous_timer * 15) * 5
		draw_arc(robot_pos + shake_offset + Vector2(0, -20), ring_size, 0, TAU, 32, counter_color, 2.0)
	
	# Hit effects (floating damage numbers)
	for effect in hit_effects:
		var alpha = effect.timer / 0.8
		var eff_color = effect.color
		eff_color.a = alpha
		draw_string(ThemeDB.fallback_font, effect.pos + shake_offset, effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, eff_color)
	
	# Slash trail effects
	for trail in slash_trails:
		var alpha = trail.timer / trail.max_timer
		var trail_color = trail.color
		trail_color.a = alpha * 0.9
		
		# Draw arc slash - multiple lines for thickness
		var width = trail.width * alpha
		draw_line(trail.start + shake_offset, trail.mid + shake_offset, trail_color, width)
		draw_line(trail.mid + shake_offset, trail.end + shake_offset, trail_color, width)
		
		# Inner glow line
		var glow_color = Color(1, 1, 1, alpha * 0.6)
		draw_line(trail.start + shake_offset, trail.mid + shake_offset, glow_color, width * 0.5)
		draw_line(trail.mid + shake_offset, trail.end + shake_offset, glow_color, width * 0.5)
		
		# Impact spark at tip for heavy attacks
		if trail.is_heavy and alpha > 0.5:
			var spark_pos = trail.mid + shake_offset
			for j in range(3):
				var angle = randf() * TAU
				var spark_end = spark_pos + Vector2(cos(angle), sin(angle)) * 15 * alpha
				draw_line(spark_pos, spark_end, Color(1, 0.9, 0.5, alpha), 2)
	
	# Combat hint at bottom
	if combat_hint != "":
		var hint_alpha = min(1.0, combat_hint_timer)
		draw_rect(Rect2(90, 280, 300, 30), Color(0.1, 0.1, 0.15, 0.85 * hint_alpha))
		draw_rect(Rect2(90, 280, 300, 30), Color(0.4, 0.9, 0.85, hint_alpha), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(110, 302), combat_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.95, 0.9, hint_alpha))
	
	# Controls reminder
	draw_string(ThemeDB.fallback_font, Vector2(10, 315), "[X] Strike  [_] Heavy  [O] Evade  â–³ Counter  R2 Gadget", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
	
	# Equipped gadget indicator (top right)
	draw_combat_gadget_indicator()
	
	# Combo counter
	if combat_combo_count > 0:
		var combo_color = Color(1.0, 0.9, 0.3) if combat_combo_count < 5 else Color(1.0, 0.5, 0.2)
		if combat_combo_count >= 10:
			combo_color = Color(1.0, 0.3, 0.8)
		draw_string(ThemeDB.fallback_font, Vector2(400, 30), str(combat_combo_count) + " HIT!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, combo_color)

func draw_combat_gadget_indicator():
	# Draw equipped gadget in top-right corner during combat
	var gx = 410
	var gy = 5
	
	# Background
	draw_rect(Rect2(gx, gy, 65, 50), Color(0.1, 0.1, 0.15, 0.8))
	draw_rect(Rect2(gx, gy, 65, 50), Color(0.4, 0.5, 0.6, 0.6), false, 2)
	
	if equipped_gadget == "":
		draw_string(ThemeDB.fallback_font, Vector2(gx + 8, gy + 30), "No Gadget", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 0.5, 0.5))
	else:
		var data = gadget_data.get(equipped_gadget, {})
		var name_text = data.get("name", equipped_gadget)
		if name_text.length() > 8:
			name_text = name_text.substr(0, 7) + "."
		
		# Icon
		var icon_color = Color.WHITE
		if gadget_use_timer > 0:
			icon_color = Color(0.5, 0.5, 0.5)  # Grayed out on cooldown
		draw_gadget_mini_icon(equipped_gadget, gx + 33, gy + 22, icon_color)
		
		# Name
		draw_string(ThemeDB.fallback_font, Vector2(gx + 5, gy + 42), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.9, 0.85))
		
		# Cooldown overlay
		if gadget_use_timer > 0:
			var cooldown_pct = gadget_use_timer / 1.0
			draw_rect(Rect2(gx + 2, gy + 2, 61 * cooldown_pct, 46), Color(0.2, 0.2, 0.3, 0.6))
		
		# R1 to cycle hint
		draw_string(ThemeDB.fallback_font, Vector2(gx + 45, gy + 12), "R1", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.6, 0.6))

func draw_combat_player(pos: Vector2):
	var outline = Color(0.0, 0.0, 0.0)
	var body_color = Color(0.4, 0.6, 0.85)
	var skin_color = Color(1.0, 0.9, 0.8)
	
	# Flash white when hit
	var flash_mod = Color(1, 1, 1, 1)
	if hit_flash_timer > 0 and hit_flash_target == "player":
		flash_mod = Color(2, 1.5, 1.5, 1)  # Brighten
	
	# Natural idle bob
	var idle_bob = 0.0
	if combat_player_state == "idle":
		idle_bob = sin(continuous_timer * 3) * 2
	
	# Use Mystic Woods player sprite if available
	if tex_player:
		var row = 0
		var frame = player_frame % 6
		var flip = not combat_player_facing_right
		var scale_factor = 1.5  # Make player bigger in combat
		
		# Choose row based on state
		match combat_player_state:
			"idle":
				row = 0  # Idle front-facing
				# Breathing animation - cycle through idle frames slowly
				frame = int(continuous_timer * 2) % 3
			"attacking":
				row = 3  # Walk/action row
				frame = 2 + int((0.2 - combat_player_state_timer) * 15) % 3
			"heavy_attack":
				row = 3
				if combat_player_state_timer > 0.3:
					frame = 0  # Windup
				else:
					frame = 4 + int((0.3 - combat_player_state_timer) * 10) % 2
			"dodging":
				# Draw ghost trail
				for i in range(3):
					var ghost_alpha = 0.3 - i * 0.1
					var roll_dir = 1 if combat_player_facing_right else -1
					var ghost_x = pos.x - roll_dir * i * 25
					var ghost_src = Rect2(frame * 48, 3 * 48, 48, 48)
					var ghost_dest = Rect2(ghost_x - 36, pos.y - 60, 72, 72)
					if flip:
						ghost_dest.position.x += 72
						ghost_dest.size.x = -72
					draw_texture_rect_region(tex_player, ghost_dest, ghost_src, Color(1, 1, 1, ghost_alpha))
				row = 3  # Action row
				frame = 3
			"hit":
				row = 0
				# Apply knockback visual
				var lean_dir = -1 if combat_player_facing_right else 1
				pos.x += lean_dir * 8
				idle_bob = -5  # Stagger down
		
		var src = Rect2(frame * 48, row * 48, 48, 48)
		var sprite_size = 48 * scale_factor
		var dest = Rect2(pos.x - sprite_size/2, pos.y - sprite_size + 10 + idle_bob, sprite_size, sprite_size)
		if flip:
			dest.position.x += sprite_size
			dest.size.x = -sprite_size
		draw_texture_rect_region(tex_player, dest, src, flash_mod)
		
		# Draw attack effect overlay
		if combat_player_state == "attacking" or combat_player_state == "heavy_attack":
			var arm_dir = 1 if combat_player_facing_right else -1
			var swing_alpha = 0.6 if combat_player_state == "attacking" else 0.9
			var swing_size = 25 if combat_player_state == "attacking" else 35
			# Draw swing arc
			var arc_x = pos.x + arm_dir * 30
			draw_arc(Vector2(arc_x, pos.y - 20), swing_size, deg_to_rad(-60), deg_to_rad(60), 12, Color(1, 0.9, 0.7, swing_alpha), 4)
			# Impact burst on attack frame
			if combat_player_state_timer < 0.1:
				draw_circle(Vector2(arc_x + arm_dir * 15, pos.y - 15), 12, Color(1, 1, 0.8, 0.6))
	else:
		# Fallback to drawn player (original code)
		draw_combat_player_fallback(pos, flash_mod)

func draw_combat_robot(pos: Vector2):
	var outline = Color(0.0, 0.0, 0.0)
	var body_color = Color(0.35, 0.18, 0.18)
	var accent = Color(1.0, 0.25, 0.25)
	
	# Flash white when hit - more intense
	var flash_mod = Color(1, 1, 1, 1)
	var is_flashing = hit_flash_timer > 0 and hit_flash_target == "robot"
	if is_flashing:
		var flash_intensity = hit_flash_timer / 0.15  # Intensity based on remaining time
		flash_mod = Color(1 + flash_intensity, 1 + flash_intensity * 0.8, 1 + flash_intensity * 0.8, 1)
	
	# Use Ninja Adventure robot sprite if available
	if tex_robot_enemy:
		var frame = int(continuous_timer * 6) % 4  # Assume 4 frames
		var row = 0
		var frame_size = 16  # Ninja Adventure sprites are usually 16x16
		var scale_factor = 3.0  # Scale up for visibility
		
		# Try to detect sprite size from texture
		var tex_width = tex_robot_enemy.get_width()
		var tex_height = tex_robot_enemy.get_height()
		
		# Common Ninja Adventure sizes: 16x16 per frame, various layouts
		if tex_width >= 64:  # Spritesheet with multiple frames
			frame_size = tex_width / 4 if tex_width >= 64 else 16
		else:
			frame_size = tex_width  # Single sprite
			frame = 0
		
		var flip = pos.x > combat_player_pos.x  # Face player
		
		match robot_state:
			"idle", "recovering":
				row = 0
			"telegraph":
				row = 0
				# Draw warning glow - size varies by attack type
				var flash = sin(continuous_timer * 15) * 0.5 + 0.5
				var glow_size = 20  # Default small
				var glow_alpha = 0.4
				match robot_current_attack:
					"quick_jab":
						glow_size = 15
						glow_alpha = 0.3
					"baton_swing":
						glow_size = 30
						glow_alpha = 0.5
					"lunge_grab":
						glow_size = 40
						glow_alpha = 0.6
					"combo_strike":
						glow_size = 25
						glow_alpha = 0.45
				var glow_color = Color(1.0, 0.2, 0.2, flash * glow_alpha)
				draw_circle(Vector2(pos.x, pos.y - 20), glow_size, glow_color)
			"attacking":
				row = 0
				frame = 2
			"hit":
				# Shake effect when stunned
				pos.x += randf_range(-4, 4)
				pos.y += randf_range(-3, 3)
		
		var src = Rect2(frame * frame_size, row * frame_size, frame_size, frame_size)
		var dest_size = frame_size * scale_factor
		var dest = Rect2(pos.x - dest_size/2, pos.y - dest_size + 10, dest_size, dest_size)
		
		if flip:
			dest.position.x += dest_size
			dest.size.x = -dest_size
		
		draw_texture_rect_region(tex_robot_enemy, dest, src, flash_mod)
		
		# Draw hit burst effect on top when flashing
		if is_flashing:
			var burst_size = 25 * (hit_flash_timer / 0.15)
			draw_circle(pos + Vector2(0, -20), burst_size, Color(1, 1, 0.8, hit_flash_timer * 3))
		
		# Draw attack effects on top
		if robot_state == "telegraph" or robot_state == "attacking":
			draw_robot_attack_effects(pos)
	else:
		# Fallback to drawn robot
		if hit_flash_timer > 0 and hit_flash_target == "robot":
			body_color = Color(0.8, 0.6, 0.6)
			accent = Color(1.0, 0.7, 0.7)
		
		match robot_state:
			"idle", "recovering":
				draw_robot_body(pos, body_color, accent, outline)
			"telegraph":
				draw_robot_body(pos, body_color, accent, outline)
				var flash = sin(continuous_timer * 15) * 0.5 + 0.5
				# Glow size varies by attack type
				var glow_size = 18
				var glow_alpha = 0.4
				match robot_current_attack:
					"quick_jab":
						glow_size = 12
						glow_alpha = 0.3
					"baton_swing":
						glow_size = 25
						glow_alpha = 0.5
					"lunge_grab":
						glow_size = 35
						glow_alpha = 0.6
					"combo_strike":
						glow_size = 20
						glow_alpha = 0.45
				var glow_color = Color(1.0, 0.2, 0.2, flash * glow_alpha)
				draw_circle(Vector2(pos.x, pos.y - 30), glow_size, glow_color)
				draw_robot_telegraph_effects(pos, body_color, accent, outline)
			"attacking":
				draw_robot_body(pos, body_color, accent, outline)
				draw_robot_attack_effects(pos)
			"hit":
				var shake = Vector2(randf_range(-3, 3), randf_range(-2, 2))
				draw_robot_body(pos + shake, body_color, accent, outline)

func draw_robot_telegraph_effects(pos: Vector2, body_color: Color, accent: Color, outline: Color):
	match robot_current_attack:
		"quick_jab":
			# Small quick indicator - just arm raising
			var arm_dir = 1 if pos.x < combat_player_pos.x else -1
			draw_rect(Rect2(pos.x + arm_dir * 8, pos.y - 28, 10 * arm_dir, 6), accent)
		"baton_swing":
			draw_rect(Rect2(pos.x - 15, pos.y - 50, 8, 25), outline)
			draw_rect(Rect2(pos.x - 14, pos.y - 49, 6, 23), accent)
		"lunge_grab":
			draw_rect(Rect2(pos.x - 12, pos.y - 10, 24, 12), outline)
			draw_rect(Rect2(pos.x - 11, pos.y - 9, 22, 10), body_color)
		"combo_strike":
			# Double indicator
			var arm_dir = 1 if pos.x < combat_player_pos.x else -1
			draw_rect(Rect2(pos.x + arm_dir * 6, pos.y - 30, 8 * arm_dir, 5), accent)
			draw_rect(Rect2(pos.x + arm_dir * 10, pos.y - 22, 8 * arm_dir, 5), accent)
		"scan_sweep":
			var flash = sin(continuous_timer * 15) * 0.5 + 0.5
			draw_circle(Vector2(pos.x, pos.y - 22), 8, Color(1.0, 0.3, 0.1, flash))

func draw_robot_attack_effects(pos: Vector2):
	var accent = Color(1.0, 0.25, 0.25)
	match robot_current_attack:
		"quick_jab":
			# Fast straight punch
			var punch_dir = 1 if pos.x < combat_player_pos.x else -1
			var prog = 1.0 - (robot_state_timer / 0.15)
			var punch_extend = prog * 30
			draw_rect(Rect2(pos.x + punch_dir * 10, pos.y - 22, punch_extend * punch_dir, 8), accent)
		"baton_swing":
			var swing_prog = 1.0 - (robot_state_timer / 0.25)
			var arm_angle = -90 + swing_prog * 180
			var arm_x = pos.x + cos(deg_to_rad(arm_angle)) * 25
			var arm_y = pos.y - 25 + sin(deg_to_rad(arm_angle)) * 25
			draw_line(Vector2(pos.x, pos.y - 25), Vector2(arm_x, arm_y), accent, 6)
		"lunge_grab":
			var grab_dir = -1 if pos.x > combat_player_pos.x else 1
			draw_rect(Rect2(pos.x + grab_dir * 10, pos.y - 20, 25 * grab_dir, 12), accent)
		"combo_strike":
			# Alternating punches
			var prog = 1.0 - (robot_state_timer / 0.4)
			var punch_dir = 1 if pos.x < combat_player_pos.x else -1
			if prog < 0.5:
				var extend = (prog * 2) * 25
				draw_rect(Rect2(pos.x + punch_dir * 8, pos.y - 25, extend * punch_dir, 7), accent)
			else:
				var extend = ((prog - 0.5) * 2) * 25
				draw_rect(Rect2(pos.x + punch_dir * 8, pos.y - 18, extend * punch_dir, 7), accent)
		"scan_sweep":
			var sweep_prog = robot_state_timer / 0.3
			var sweep_x = combat_arena_left + (combat_arena_right - combat_arena_left) * (1.0 - sweep_prog)
			draw_line(Vector2(pos.x, pos.y - 22), Vector2(sweep_x, combat_arena_y), Color(1.0, 0.2, 0.1, 0.8), 3)

func draw_tunnel_robot(robot: Dictionary, shake_offset: Vector2, index: int):
	var pos = robot.pos + shake_offset
	var outline = Color(0.0, 0.0, 0.0)
	# Slightly different colors for each robot
	var body_colors = [
		Color(0.35, 0.18, 0.18),
		Color(0.25, 0.25, 0.35),
		Color(0.35, 0.25, 0.18)
	]
	var body_color = body_colors[index % 3]
	var accent = Color(1.0, 0.25, 0.25)
	
	match robot.state:
		"idle", "recover", "approach":
			draw_robot_body(pos, body_color, accent, outline)
		"telegraph":
			draw_robot_body(pos, body_color, accent, outline)
			# Counter indicator - flashing warning
			var flash = sin(continuous_timer * 20 + index) * 0.4 + 0.6
			var glow_color = Color(1.0, 0.2, 0.2, flash * 0.7)
			draw_circle(Vector2(pos.x, pos.y - 30), 28, glow_color)
			# Draw counter prompt and pulsing ring
			var prompt_color = Color(0.3, 0.9, 1.0, flash)
			draw_string(ThemeDB.fallback_font, Vector2(pos.x - 8, pos.y - 70), "â–³", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, prompt_color)
			# Pulsing ring around robot
			var ring_size = 25 + sin(continuous_timer * 15 + index * 2) * 4
			draw_arc(Vector2(pos.x, pos.y - 20), ring_size, 0, TAU, 24, prompt_color, 2.0)
		"attack":
			draw_robot_body(pos, body_color, accent, outline)
			# Swing effect
			var arm_dir = 1 if pos.x > combat_player_pos.x else -1
			draw_rect(Rect2(pos.x - arm_dir * 10, pos.y - 25, 30 * -arm_dir, 8), accent)
		"hit":
			# Flash white when hit - still draw the robot!
			var hit_flash = Color(1.0, 0.8, 0.8)
			draw_robot_body(pos, hit_flash, Color(1.0, 0.5, 0.5), outline)

func draw_combat_player_fallback(pos: Vector2, flash_mod: Color):
	var outline = Color(0.0, 0.0, 0.0)
	var body_color = Color(0.4, 0.6, 0.85)
	var skin_color = Color(1.0, 0.9, 0.8)
	
	if flash_mod.r > 1:
		body_color = Color(1.0, 0.8, 0.8)
		skin_color = Color(1.0, 0.9, 0.9)
	
	match combat_player_state:
		"idle":
			draw_rect(Rect2(pos.x - 9, pos.y - 29, 18, 32), outline)
			draw_rect(Rect2(pos.x - 8, pos.y - 28, 16, 30), body_color)
			draw_circle(Vector2(pos.x, pos.y - 35), 9, outline)
			draw_circle(Vector2(pos.x, pos.y - 35), 8, skin_color)
			var eye_x = 3 if combat_player_facing_right else -3
			draw_circle(Vector2(pos.x + eye_x - 2, pos.y - 36), 2, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(pos.x + eye_x + 2, pos.y - 36), 2, Color(0.1, 0.1, 0.1))
		"attacking":
			draw_rect(Rect2(pos.x - 9, pos.y - 29, 18, 32), outline)
			draw_rect(Rect2(pos.x - 8, pos.y - 28, 16, 30), body_color)
			var arm_dir = 1 if combat_player_facing_right else -1
			draw_rect(Rect2(pos.x + arm_dir * 6, pos.y - 20, 20 * arm_dir, 8), outline)
			draw_rect(Rect2(pos.x + arm_dir * 7, pos.y - 19, 18 * arm_dir, 6), skin_color)
			draw_circle(Vector2(pos.x, pos.y - 35), 9, outline)
			draw_circle(Vector2(pos.x, pos.y - 35), 8, skin_color)
		"heavy_attack":
			var windup = combat_player_state_timer > 0.3
			draw_rect(Rect2(pos.x - 9, pos.y - 29, 18, 32), outline)
			draw_rect(Rect2(pos.x - 8, pos.y - 28, 16, 30), Color(0.5, 0.65, 0.9))
			var arm_dir = 1 if combat_player_facing_right else -1
			if windup:
				draw_rect(Rect2(pos.x - arm_dir * 15, pos.y - 22, 12, 8), skin_color)
			else:
				draw_rect(Rect2(pos.x + arm_dir * 6, pos.y - 18, 25 * arm_dir, 10), outline)
				draw_rect(Rect2(pos.x + arm_dir * 7, pos.y - 17, 23 * arm_dir, 8), skin_color)
			draw_circle(Vector2(pos.x, pos.y - 35), 9, outline)
			draw_circle(Vector2(pos.x, pos.y - 35), 8, skin_color)
		"dodging":
			var roll_dir = 1 if combat_player_facing_right else -1
			for i in range(3):
				var ghost_alpha = 0.2 - i * 0.05
				var ghost_x = pos.x - roll_dir * i * 15
				draw_circle(Vector2(ghost_x, pos.y - 15), 12, Color(0.4, 0.6, 0.85, ghost_alpha))
			draw_ellipse_shape(Vector2(pos.x, pos.y - 12), Vector2(14, 10), outline)
			draw_ellipse_shape(Vector2(pos.x, pos.y - 12), Vector2(12, 8), body_color)
		"hit":
			var lean_dir = -1 if combat_player_facing_right else 1
			draw_rect(Rect2(pos.x + lean_dir * 5 - 8, pos.y - 27, 16, 30), Color(0.9, 0.5, 0.5))
			draw_circle(Vector2(pos.x + lean_dir * 8, pos.y - 35), 8, Color(1.0, 0.85, 0.8))

func draw_robot_body(pos: Vector2, body_color: Color, accent: Color, outline: Color):
	# Main body
	draw_rect(Rect2(pos.x - 13, pos.y - 35, 26, 38), outline)
	draw_rect(Rect2(pos.x - 12, pos.y - 34, 24, 36), body_color)
	
	# Head
	draw_rect(Rect2(pos.x - 11, pos.y - 50, 22, 18), outline)
	draw_rect(Rect2(pos.x - 10, pos.y - 49, 20, 16), body_color)
	
	# Visor (eye)
	draw_rect(Rect2(pos.x - 7, pos.y - 46, 14, 5), accent)
	
	# Legs (animated)
	var leg_offset = sin(continuous_timer * 6) * 3
	draw_rect(Rect2(pos.x - 9, pos.y + 2, 6, 14 + leg_offset), outline)
	draw_rect(Rect2(pos.x + 3, pos.y + 2, 6, 14 - leg_offset), outline)
	draw_rect(Rect2(pos.x - 8, pos.y + 3, 4, 12 + leg_offset), body_color)
	draw_rect(Rect2(pos.x + 4, pos.y + 3, 4, 12 - leg_offset), body_color)
	
	# Arms
	draw_rect(Rect2(pos.x - 18, pos.y - 30, 6, 20), outline)
	draw_rect(Rect2(pos.x + 12, pos.y - 30, 6, 20), outline)
	draw_rect(Rect2(pos.x - 17, pos.y - 29, 4, 18), body_color)
	draw_rect(Rect2(pos.x + 13, pos.y - 29, 4, 18), body_color)

func draw_defeated_robot(pos: Vector2):
	if tex_robot_enemy:
		# Draw collapsed sprite with rotation/scaling
		var tex_width = tex_robot_enemy.get_width()
		var frame_size = tex_width / 4 if tex_width >= 64 else tex_width
		var scale_factor = 3.0
		
		var src = Rect2(0, 0, frame_size, frame_size)
		var dest_size = frame_size * scale_factor
		
		# Draw rotated (on ground)
		var dest = Rect2(pos.x - dest_size/2 - 10, pos.y - 15, dest_size, dest_size * 0.5)
		draw_texture_rect_region(tex_robot_enemy, dest, src, Color(0.5, 0.5, 0.5, 1))
		
		# Sparks
		if fmod(robot_spark_timer, 0.5) < 0.25:
			var spark_x = pos.x + randf_range(-20, 20)
			var spark_y = pos.y + randf_range(-15, 5)
			draw_circle(Vector2(spark_x, spark_y), 3, Color(1.0, 0.9, 0.3))
			draw_circle(Vector2(spark_x + 5, spark_y - 3), 2, Color(1.0, 0.7, 0.2))
		
		# Scattered components
		draw_circle(Vector2(pos.x - 30, pos.y + 5), 4, Color(0.4, 0.4, 0.45))
		draw_rect(Rect2(pos.x + 35, pos.y + 2, 8, 4), Color(0.5, 0.3, 0.2))
		draw_circle(Vector2(pos.x - 10, pos.y + 8), 3, Color(0.7, 0.2, 0.2))
	else:
		# Fallback drawn version
		var outline = Color(0.0, 0.0, 0.0)
		var body_color = Color(0.25, 0.2, 0.2)
		
		# Collapsed on ground
		draw_rect(Rect2(pos.x - 25, pos.y - 5, 50, 18), outline)
		draw_rect(Rect2(pos.x - 24, pos.y - 4, 48, 16), body_color)
		
		# Head tilted
		draw_rect(Rect2(pos.x + 20, pos.y - 15, 16, 14), outline)
		draw_rect(Rect2(pos.x + 21, pos.y - 14, 14, 12), body_color)
		
		# Dead visor
		draw_rect(Rect2(pos.x + 23, pos.y - 12, 10, 4), Color(0.3, 0.1, 0.1))
		
		# Sparks
		if fmod(robot_spark_timer, 0.5) < 0.25:
			var spark_x = pos.x + randf_range(-20, 20)
			var spark_y = pos.y + randf_range(-15, 5)
			draw_circle(Vector2(spark_x, spark_y), 3, Color(1.0, 0.9, 0.3))
			draw_circle(Vector2(spark_x + 5, spark_y - 3), 2, Color(1.0, 0.7, 0.2))
		
		# Scattered components
		draw_circle(Vector2(pos.x - 30, pos.y + 5), 4, Color(0.4, 0.4, 0.45))
		draw_rect(Rect2(pos.x + 35, pos.y + 2, 8, 4), Color(0.5, 0.3, 0.2))
		draw_circle(Vector2(pos.x - 10, pos.y + 8), 3, Color(0.7, 0.2, 0.2))

func draw_combat_health_bar(pos: Vector2, current_hp: int, max_hp: int, color: Color, label: String):
	var bar_width = 60
	var bar_height = 8
	
	# Label
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.9))
	
	# Background
	draw_rect(Rect2(pos.x - 1, pos.y, bar_width + 2, bar_height + 2), Color(0.0, 0.0, 0.0))
	draw_rect(Rect2(pos.x, pos.y + 1, bar_width, bar_height), Color(0.2, 0.2, 0.2))
	
	# Health fill
	var fill_width = int((float(current_hp) / float(max_hp)) * bar_width)
	if fill_width > 0:
		draw_rect(Rect2(pos.x, pos.y + 1, fill_width, bar_height), color)
	
	# HP text
	var hp_text = str(current_hp) + "/" + str(max_hp)
	draw_string(ThemeDB.fallback_font, pos + Vector2(bar_width + 5, bar_height), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.8, 0.8))

func draw_stamina_bar(pos: Vector2):
	var bar_width = 60
	var bar_height = 4
	
	# Background
	draw_rect(Rect2(pos.x, pos.y, bar_width, bar_height), Color(0.15, 0.15, 0.2))
	
	# Stamina fill
	var fill_width = int((combat_player_stamina / combat_player_max_stamina) * bar_width)
	var stam_color = Color(0.3, 0.7, 0.9) if combat_player_stamina > 25 else Color(0.9, 0.5, 0.2)
	if fill_width > 0:
		draw_rect(Rect2(pos.x, pos.y, fill_width, bar_height), stam_color)

# ============================================
# REGION COMPLETE
# ============================================

func draw_region_complete():
	draw_rect(Rect2(0, 0, 480, 320), Color(0.06, 0.08, 0.1))
	
	# Border
	draw_rect(Rect2(30, 30, 420, 260), Color(0.12, 0.15, 0.14))
	draw_rect(Rect2(30, 30, 420, 260), Color(0.3, 0.7, 0.65), false, 3)
	
	draw_string(ThemeDB.fallback_font, Vector2(130, 70), "REGION COMPLETED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 0.95, 0.85))
	
	draw_string(ThemeDB.fallback_font, Vector2(180, 110), "AGRICOMMUNE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.65, 0.55))
	
	draw_string(ThemeDB.fallback_font, Vector2(150, 150), "Circuits built: " + str(circuits_built), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	draw_string(ThemeDB.fallback_font, Vector2(150, 180), "Skills learned:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))
	var skills = ["LED Basics", "Buttons & Switches", "Logic Gates (NOT, OR)", "Light Sensors", "Series Circuits"]
	var sy = 198
	for skill in skills:
		draw_string(ThemeDB.fallback_font, Vector2(170, sy), "- " + skill, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6))
		sy += 15
	
	draw_string(ThemeDB.fallback_font, Vector2(140, 280), "NEXT: New Sumida City", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.85, 0.8))

func draw_shop_interior():
	# Shop interior background
	var floor_color = Color(0.55, 0.45, 0.35)
	var wall_color = Color(0.75, 0.65, 0.55)
	var shelf_color = Color(0.5, 0.38, 0.28)
	
	draw_rect(Rect2(0, 0, 480, 320), wall_color)
	draw_rect(Rect2(0, 150, 480, 170), floor_color)
	
	# Wood floor planks
	for i in range(14):
		draw_line(Vector2(0, 150 + i * 12), Vector2(480, 150 + i * 12), Color(0.45, 0.38, 0.28), 1)
	
	# Shelves on wall
	for row in range(2):
		var shelf_y = 40 + row * 50
		draw_rect(Rect2(30, shelf_y, 180, 8), shelf_color)
		draw_rect(Rect2(270, shelf_y, 180, 8), shelf_color)
		# Items on shelves (use fixed seed for consistent look)
		for i in range(5):
			var item_x = 40 + i * 35
			var hue1 = fmod(i * 0.15 + row * 0.3, 1.0)
			var hue2 = fmod(i * 0.2 + row * 0.25, 1.0)
			draw_rect(Rect2(item_x, shelf_y - 20, 15, 20), Color.from_hsv(hue1, 0.4, 0.7))
			draw_rect(Rect2(item_x + 240, shelf_y - 20, 15, 20), Color.from_hsv(hue2, 0.4, 0.7))
	
	# Counter
	draw_rect(Rect2(160, 130, 160, 30), Color(0.45, 0.35, 0.28))
	draw_rect(Rect2(160, 125, 160, 8), Color(0.55, 0.42, 0.32))
	
	# Shopkeeper robot behind counter
	draw_robot_npc(interior_npc_pos.x, interior_npc_pos.y, "shop")
	
	# Door at bottom
	draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Draw Kaido (behind player if higher Y)
	if interior_kaido_pos.y < interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Draw player
	draw_interior_player(interior_player_pos)
	
	# Draw Kaido (in front of player if lower Y)
	if interior_kaido_pos.y >= interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Title
	draw_rect(Rect2(150, 5, 180, 25), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(195, 22), "GENERAL STORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))
	
	# Context prompts
	if not in_dialogue:
		if interior_near_npc:
			draw_rect(Rect2(180, 100, 120, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(180, 100, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(200, 117), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if interior_near_exit:
			draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))
	
	if in_dialogue:
		draw_dialogue_box()

func draw_townhall_interior():
	# Town hall interior - grand but worn
	var floor_color = Color(0.45, 0.42, 0.4)
	var wall_color = Color(0.65, 0.6, 0.55)
	var pillar_color = Color(0.55, 0.52, 0.48)
	
	draw_rect(Rect2(0, 0, 480, 320), wall_color)
	draw_rect(Rect2(0, 150, 480, 170), floor_color)
	
	# Checkered floor
	for i in range(12):
		for j in range(5):
			if (i + j) % 2 == 0:
				draw_rect(Rect2(i * 40, 150 + j * 34, 40, 34), Color(0.4, 0.38, 0.35))
	
	# Pillars
	draw_rect(Rect2(50, 50, 30, 120), pillar_color)
	draw_rect(Rect2(400, 50, 30, 120), pillar_color)
	
	# Banner on wall (Energy Nation symbol - oppressive)
	draw_rect(Rect2(200, 20, 80, 80), Color(0.7, 0.2, 0.2))
	draw_circle(Vector2(240, 60), 25, Color(0.9, 0.85, 0.3))
	
	# Mayor's desk
	draw_rect(Rect2(180, 110, 120, 40), Color(0.4, 0.3, 0.22))
	draw_rect(Rect2(180, 105, 120, 8), Color(0.5, 0.38, 0.28))
	
	# Mayor sitting at desk
	draw_mayor_npc(interior_npc_pos.x, interior_npc_pos.y)
	
	# Door at bottom
	draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Draw Kaido (behind player if higher Y)
	if interior_kaido_pos.y < interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Draw player
	draw_interior_player(interior_player_pos)
	
	# Draw Kaido (in front of player if lower Y)
	if interior_kaido_pos.y >= interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Title
	draw_rect(Rect2(180, 5, 120, 25), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(205, 22), "TOWN HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))
	
	# Context prompts
	if not in_dialogue:
		if interior_near_npc:
			draw_rect(Rect2(180, 85, 120, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(180, 85, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(200, 102), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if interior_near_exit:
			draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))
	
	if in_dialogue:
		draw_dialogue_box()

func draw_bakery_interior():
	# Warm bakery interior
	var floor_color = Color(0.6, 0.5, 0.4)
	var wall_color = Color(0.85, 0.75, 0.65)
	
	draw_rect(Rect2(0, 0, 480, 320), wall_color)
	draw_rect(Rect2(0, 150, 480, 170), floor_color)
	
	# Warm glow
	draw_rect(Rect2(0, 0, 480, 320), Color(1.0, 0.9, 0.7, 0.1))
	
	# Brick oven
	draw_rect(Rect2(50, 50, 100, 70), Color(0.6, 0.35, 0.25))
	draw_rect(Rect2(70, 70, 60, 35), Color(0.2, 0.1, 0.05))
	# Fire glow
	var fire_pulse = sin(continuous_timer * 5) * 0.2 + 0.8
	draw_rect(Rect2(75, 78, 50, 22), Color(1.0, 0.5, 0.2, fire_pulse))
	
	# Display case with bread
	draw_rect(Rect2(200, 110, 150, 50), Color(0.5, 0.4, 0.3))
	draw_rect(Rect2(205, 105, 140, 10), Color(0.6, 0.5, 0.4))
	# Bread loaves
	for i in range(4):
		draw_ellipse_shape(Vector2(230 + i * 30, 130), Vector2(12, 8), Color(0.75, 0.55, 0.35))
	
	# Baker robot - position from interior_npc_pos
	draw_robot_npc(interior_npc_pos.x, interior_npc_pos.y, "baker")
	
	# Door at bottom
	draw_rect(Rect2(200, 285, 80, 35), Color(0.35, 0.28, 0.22))
	draw_rect(Rect2(200, 285, 80, 5), Color(0.45, 0.35, 0.28))
	
	# Draw Kaido (behind player if higher Y)
	if interior_kaido_pos.y < interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Draw player
	draw_interior_player(interior_player_pos)
	
	# Draw Kaido (in front of player if lower Y)
	if interior_kaido_pos.y >= interior_player_pos.y:
		draw_kaido(interior_kaido_pos)
	
	# Title
	draw_rect(Rect2(195, 5, 90, 25), Color(0, 0, 0, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(215, 22), "BAKERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.7))
	
	# Context prompts
	if not in_dialogue:
		if interior_near_npc:
			draw_rect(Rect2(180, 95, 120, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(180, 95, 120, 24), Color(0.3, 0.8, 0.7), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(200, 112), "[X] Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.95, 0.88))
		if interior_near_exit:
			draw_rect(Rect2(190, 260, 100, 24), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(190, 260, 100, 24), Color(0.8, 0.6, 0.3), false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(210, 277), "[O] Exit", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.6))
	
	if in_dialogue:
		draw_dialogue_box()

func draw_robot_npc(x: float, y: float, type: String):
	var outline = Color(0.0, 0.0, 0.0)
	var body_color = Color(0.6, 0.6, 0.65)
	var accent = Color(0.3, 0.7, 0.6) if type == "shop" else Color(0.8, 0.5, 0.3)
	
	# Body
	draw_rect(Rect2(x - 15, y, 30, 40), outline)
	draw_rect(Rect2(x - 14, y + 1, 28, 38), body_color)
	
	# Head
	draw_rect(Rect2(x - 12, y - 20, 24, 22), outline)
	draw_rect(Rect2(x - 11, y - 19, 22, 20), body_color)
	
	# Eyes (LED style)
	draw_rect(Rect2(x - 8, y - 14, 6, 6), accent)
	draw_rect(Rect2(x + 2, y - 14, 6, 6), accent)
	
	# Antenna
	draw_rect(Rect2(x - 2, y - 28, 4, 10), body_color)
	draw_circle(Vector2(x, y - 30), 4, accent)
	
	# Apron for baker
	if type == "baker":
		draw_rect(Rect2(x - 12, y + 5, 24, 30), Color(0.95, 0.9, 0.85))

func draw_mayor_npc(x: float, y: float):
	var outline = Color(0.0, 0.0, 0.0)
	var suit = Color(0.25, 0.25, 0.3)
	var skin = Color(0.85, 0.7, 0.6)
	
	# Body (hunched posture)
	draw_rect(Rect2(x - 12, y, 24, 35), outline)
	draw_rect(Rect2(x - 11, y + 1, 22, 33), suit)
	
	# Head (looking down)
	draw_circle(Vector2(x, y - 8), 13, outline)
	draw_circle(Vector2(x, y - 8), 12, skin)
	
	# Gray hair
	draw_rect(Rect2(x - 10, y - 18, 20, 8), Color(0.6, 0.6, 0.6))
	
	# Tired eyes (closed/looking down)
	draw_line(Vector2(x - 6, y - 8), Vector2(x - 2, y - 8), outline, 2)
	draw_line(Vector2(x + 2, y - 8), Vector2(x + 6, y - 8), outline, 2)

func draw_interior_player(pos: Vector2):
	# Draw player sprite in building interior - same size as exploration
	if tex_player:
		# Player spritesheet is 48x48 per frame, row 0 is idle front
		var src = Rect2(0, 0, 48, 48)  # First frame of idle
		var dest = Rect2(pos.x - 24, pos.y - 40, 48, 48)  # Same size as exploration
		draw_texture_rect_region(tex_player, dest, src)
	else:
		# Fallback - simple character
		var outline = Color(0, 0, 0)
		var skin = Color(0.92, 0.78, 0.62)
		var shirt = Color(0.3, 0.5, 0.7)
		var pants = Color(0.35, 0.3, 0.4)
		var hair = Color(0.35, 0.25, 0.18)
		
		# Shadow
		draw_ellipse_shape(Vector2(pos.x, pos.y + 2), Vector2(8, 3), Color(0, 0, 0, 0.2))
		
		# Body
		draw_rect(Rect2(pos.x - 6, pos.y - 14, 12, 16), outline)
		draw_rect(Rect2(pos.x - 5, pos.y - 13, 10, 7), shirt)
		draw_rect(Rect2(pos.x - 5, pos.y - 6, 10, 8), pants)
		
		# Head
		draw_circle(Vector2(pos.x, pos.y - 20), 7, outline)
		draw_circle(Vector2(pos.x, pos.y - 20), 6, skin)
		
		# Hair
		draw_rect(Rect2(pos.x - 5, pos.y - 26, 10, 5), hair)
		
		# Eyes
		draw_circle(Vector2(pos.x - 2, pos.y - 21), 1, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(pos.x + 2, pos.y - 21), 1, Color(0.1, 0.1, 0.1))
