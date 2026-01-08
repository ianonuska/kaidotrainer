extends Node
# DialogueData.gd - All game dialogue text
# Add to Project > Project Settings > Autoload as "DialogueData"

# ===========================================
# GRANDMOTHER DIALOGUE
# ===========================================

func grandmother_stage_0() -> Array:
	return [
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

func grandmother_stage_1() -> Array:
	return [
		{"speaker": "grandmother", "text": "The shed is over to the east."},
		{"speaker": "grandmother", "text": "Be careful in there, it's very dark."},
	]

func grandmother_stage_2() -> Array:
	return [
		{"speaker": "grandmother", "text": "You built your first circuit!"},
		{"speaker": "grandmother", "text": "Your grandfather would be proud."},
		{"speaker": "grandmother", "text": "Now use it to explore the shed."},
	]

func grandmother_stage_3() -> Array:
	return [
		{"speaker": "grandmother", "text": "You found... the photograph."},
		{"speaker": "grandmother", "text": "Where did you find this?"},
		{"speaker": "grandmother", "text": "The Resistance. We were engineers."},
		{"speaker": "grandmother", "text": "Before Energy Nation took control."},
		{"speaker": "grandmother", "text": "They made us forget how to build."},
		{"speaker": "grandmother", "text": "But some of us kept the knowledge."},
		{"speaker": "set_stage", "text": "4"},
		{"speaker": "quest", "text": "Learn about Kaido"},
	]

func grandmother_stage_4() -> Array:
	return [
		{"speaker": "grandmother", "text": "Kaido. That name... decades ago."},
		{"speaker": "grandmother", "text": "It was built by CARACTACUS..."},
		{"speaker": "grandmother", "text": "Your grandfather."},
		{"speaker": "kaido", "text": "Memory unlocking. I remember now."},
		{"speaker": "kaido", "text": "I was built to teach children."},
		{"speaker": "kaido", "text": "To preserve what was being erased."},
	]

func grandmother_stage_4_kid_arrives() -> Array:
	return [
		{"speaker": "kid", "text": "Energy Nation patrol!"},
		{"speaker": "kid", "text": "Coming up the road!"},
		{"speaker": "kid", "text": "Five minutes out!"},
		{"speaker": "set_stage", "text": "5"},
		{"speaker": "quest", "text": "Build Silent Alarm"},
	]

func grandmother_stage_5() -> Array:
	return [
		{"speaker": "grandmother", "text": "We need to warn the others. Quietly."},
		{"speaker": "grandmother", "text": "Can you build a silent alarm?"},
		{"speaker": "grandmother", "text": "The parts should be in the shed."},
		{"speaker": "kaido", "text": "A buzzer circuit! Let's go!"},
	]

func grandmother_stage_6_7() -> Array:
	return [
		{"speaker": "grandmother", "text": "The patrol moves on."},
		{"speaker": "grandmother", "text": "That was close."},
		{"speaker": "grandmother", "text": "There's still work to do here."},
		{"speaker": "grandmother", "text": "The irrigation system is broken."},
		{"speaker": "grandmother", "text": "Without water, the crops will die."},
		{"speaker": "grandmother", "text": "Follow me to the field."},
	]

func grandmother_stage_8_9() -> Array:
	return [
		{"speaker": "grandmother", "text": "Your grandfather would be proud."},
		{"speaker": "grandmother", "text": "There's more we can do for the village."},
		{"speaker": "grandmother", "text": "Farmer Wen's tractor broke down nearby."},
	]

func grandmother_deep_talk(count: int) -> Array:
	match count:
		1:
			return [
				{"speaker": "grandmother", "text": "You've learned so much."},
				{"speaker": "grandmother", "text": "But dark times are coming."},
				{"speaker": "kaido", "text": "We should check the radiotower."},
			]
		2:
			return [
				{"speaker": "grandmother", "text": "You know, I wasn't always a farmer."},
				{"speaker": "grandmother", "text": "Before the takeover, I was an engineer."},
				{"speaker": "grandmother", "text": "I built the first solar grid for this valley."},
			]
		3:
			return [
				{"speaker": "grandmother", "text": "Your grandfather and I met at university."},
				{"speaker": "grandmother", "text": "He was brilliant. Always tinkering."},
				{"speaker": "grandmother", "text": "He believed everyone should understand how things work."},
				{"speaker": "grandmother", "text": "That's why they came for him first."},
			]
		4:
			return [
				{"speaker": "grandmother", "text": "CARACTACUS... his code name."},
				{"speaker": "grandmother", "text": "He hid Kaido here before they took him."},
				{"speaker": "grandmother", "text": "Said someday, someone would find it."},
				{"speaker": "grandmother", "text": "I waited thirty years for you."},
			]
		_:
			return [
				{"speaker": "grandmother", "text": "Whatever happens, keep building."},
				{"speaker": "grandmother", "text": "Knowledge shared is knowledge that survives."},
			]

# ===========================================
# FARMER WEN DIALOGUE
# ===========================================

func farmer_wen_stage_9() -> Array:
	return [
		{"speaker": "farmer_wen", "text": "My tractor's sensor is broken."},
		{"speaker": "farmer_wen", "text": "Can't see at night no more."},
		{"speaker": "kaido", "text": "We can build a light sensor circuit!"},
		{"speaker": "kaido", "text": "It'll detect darkness automatically."},
		{"speaker": "set_stage", "text": "10"},
		{"speaker": "quest", "text": "Fix Tractor Sensor"},
	]

func farmer_wen_stage_10() -> Array:
	return [
		{"speaker": "farmer_wen", "text": "Any luck with that sensor?"},
		{"speaker": "kaido", "text": "We need a photoresistor and transistor."},
		{"speaker": "kaido", "text": "Check the shed for parts."},
	]

func farmer_wen_stage_11() -> Array:
	return [
		{"speaker": "farmer_wen", "text": "It works! The lights turn on automatically!"},
		{"speaker": "farmer_wen", "text": "You've got a gift, kid."},
		{"speaker": "farmer_wen", "text": "The whole village could use help like this."},
		{"speaker": "grandmother", "text": "Speaking of which..."},
		{"speaker": "grandmother", "text": "The old radiotower. It hasn't worked in years."},
		{"speaker": "grandmother", "text": "If we could get it running..."},
		{"speaker": "kaido", "text": "We could broadcast to other villages!"},
		{"speaker": "set_stage", "text": "12"},
		{"speaker": "quest", "text": "Restore the Radiotower"},
	]

func farmer_wen_default() -> Array:
	return [
		{"speaker": "farmer_wen", "text": "Good luck with that tower."},
		{"speaker": "farmer_wen", "text": "The whole valley's counting on you."},
	]

# ===========================================
# SHOP NPC DIALOGUE
# ===========================================

func shop_intro() -> Array:
	return [
		{"speaker": "shop", "text": "Welcome to the village shop!"},
		{"speaker": "shop", "text": "We don't have much these days..."},
		{"speaker": "shop", "text": "Energy Nation controls all the supplies."},
	]

func shop_default() -> Array:
	return [
		{"speaker": "shop", "text": "Come back when times are better."},
	]

# ===========================================
# MAYOR DIALOGUE
# ===========================================

func mayor_intro() -> Array:
	return [
		{"speaker": "mayor", "text": "Ah, you must be the young engineer."},
		{"speaker": "mayor", "text": "Word travels fast in a small village."},
		{"speaker": "mayor", "text": "We could use someone with your skills."},
	]

func mayor_default() -> Array:
	return [
		{"speaker": "mayor", "text": "The village is counting on you."},
	]

# ===========================================
# BAKER DIALOGUE
# ===========================================

func baker_intro() -> Array:
	return [
		{"speaker": "baker", "text": "Fresh bread! Well... day-old bread."},
		{"speaker": "baker", "text": "Hard to bake without reliable power."},
	]

func baker_default() -> Array:
	return [
		{"speaker": "baker", "text": "Maybe one day we'll have fresh pastries again."},
	]

# ===========================================
# SHED DIALOGUE
# ===========================================

func shed_dark() -> Array:
	return [
		{"speaker": "kaido", "text": "It's too dark to see anything."},
		{"speaker": "kaido", "text": "We need a light source."},
		{"speaker": "kaido", "text": "Let's build an LED circuit first!"},
	]

func shed_flashlight_works() -> Array:
	return [
		{"speaker": "kaido", "text": "The LED works! Now we can explore."},
		{"speaker": "kaido", "text": "Look around for useful parts."},
		{"speaker": "set_stage", "text": "2"},
		{"speaker": "quest", "text": "Explore the Shed"},
	]

func shed_found_photograph() -> Array:
	return [
		{"speaker": "kaido", "text": "What's this? An old photograph..."},
		{"speaker": "kaido", "text": "These people... they're wearing lab coats."},
		{"speaker": "kaido", "text": "And that symbol... I've seen it before."},
		{"speaker": "kaido", "text": "We should show this to Grandmother."},
		{"speaker": "set_stage", "text": "3"},
		{"speaker": "quest", "text": "Show Grandmother"},
	]

# ===========================================
# IRRIGATION DIALOGUE
# ===========================================

func irrigation_broken() -> Array:
	return [
		{"speaker": "grandmother", "text": "The control panel is dead."},
		{"speaker": "grandmother", "text": "Without automation, we'd have to water by hand."},
		{"speaker": "kaido", "text": "I can fix this! We need a NOT gate."},
		{"speaker": "kaido", "text": "It inverts the signal - off becomes on!"},
		{"speaker": "set_stage", "text": "8"},
		{"speaker": "quest", "text": "Build NOT Gate Circuit"},
	]

func irrigation_fixed() -> Array:
	return [
		{"speaker": "grandmother", "text": "The water flows again!"},
		{"speaker": "grandmother", "text": "The crops will survive now."},
		{"speaker": "kaido", "text": "Another circuit mastered!"},
	]

# ===========================================
# RADIOTOWER DIALOGUE
# ===========================================

func radiotower_stage_12() -> Array:
	return [
		{"speaker": "kaido", "text": "The radiotower! It's been dormant for years."},
		{"speaker": "kaido", "text": "If we restore power, we can broadcast."},
		{"speaker": "kaido", "text": "Other villages might hear us!"},
		{"speaker": "kaido", "text": "We need a complex circuit for this one."},
		{"speaker": "kaido", "text": "Multiple LEDs in series with proper resistance."},
		{"speaker": "set_stage", "text": "13"},
		{"speaker": "quest", "text": "Build LED Chain"},
	]

func radiotower_stage_13() -> Array:
	return [
		{"speaker": "kaido", "text": "Almost there! We need the LED chain."},
		{"speaker": "kaido", "text": "The shed should have what we need."},
	]

func radiotower_complete() -> Array:
	return [
		{"speaker": "kaido", "text": "The tower is broadcasting!"},
		{"speaker": "kaido", "text": "Villages across the valley can hear us now."},
		{"speaker": "kaido", "text": "The revolution begins..."},
		{"speaker": "set_stage", "text": "14"},
		{"speaker": "quest", "text": "Liberation!"},
	]

# ===========================================
# AREA ENTRY DIALOGUE
# ===========================================

func cornfield_led_hint() -> Array:
	return [
		{"speaker": "kaido", "text": "The farmers up here need to see the signal."},
		{"speaker": "kaido", "text": "We should place LED markers along the path."},
	]

func town_first_visit() -> Array:
	return [
		{"speaker": "kaido", "text": "The town center. Most villagers live here."},
	]

func lakeside_hint() -> Array:
	return [
		{"speaker": "kaido", "text": "Beautiful lake. Good for fishing."},
		{"speaker": "kaido", "text": "I wonder if there's anything useful here."},
	]

# ===========================================
# STAMPEDE DIALOGUE
# ===========================================

func stampede_intro() -> Array:
	return [
		{"speaker": "kaido", "text": "STAMPEDE! The animals are panicking!"},
		{"speaker": "kaido", "text": "We need to calm them down!"},
		{"speaker": "kaido", "text": "Jump to dodge, attack to calm!"},
	]

func stampede_victory() -> Array:
	return [
		{"speaker": "kaido", "text": "The animals are calm now."},
		{"speaker": "kaido", "text": "Good work!"},
	]

# ===========================================
# COMBAT DIALOGUE
# ===========================================

func robot_encounter() -> Array:
	return [
		{"speaker": "kaido", "text": "An Energy Nation patrol robot!"},
		{"speaker": "kaido", "text": "Watch for the counter indicator!"},
		{"speaker": "kaido", "text": "Press X when you see the flash!"},
	]

func robot_defeated() -> Array:
	return [
		{"speaker": "kaido", "text": "We disabled it!"},
		{"speaker": "kaido", "text": "But more will come."},
		{"speaker": "kaido", "text": "We need to move fast."},
	]

# ===========================================
# WELL / CHICKEN COOP DIALOGUE
# ===========================================

func well_fixed() -> Array:
	return [
		{"speaker": "kaido", "text": "The pump circuit is working!"},
		{"speaker": "kaido", "text": "Fresh water for the village."},
	]

func well_broken() -> Array:
	return [
		{"speaker": "kaido", "text": "The well pump is broken."},
		{"speaker": "kaido", "text": "We could fix it with a simple circuit."},
	]

func chicken_coop_fixed() -> Array:
	return [
		{"speaker": "kaido", "text": "The automatic feeder works!"},
		{"speaker": "kaido", "text": "Happy chickens, happy farm."},
	]

func chicken_coop_broken() -> Array:
	return [
		{"speaker": "kaido", "text": "The chicken feeder timer is broken."},
		{"speaker": "kaido", "text": "An OR gate circuit could fix it."},
	]
