extends RefCounted
# DialogueData.gd - All game dialogue text
# Preload and instantiate: var dialogue_data = Dialogue.new()

# ===========================================
# GRANDMOTHER DIALOGUE
# ===========================================

func grandmother_stage_0() -> Array:
	return [
		{"speaker": "grandmother", "text": "Oh Child! You've finally come to visit!"},
		{"speaker": "grandmother", "text": "The power has been out for days now."},
		{"speaker": "grandmother", "text": "Energy Nation doesn't care about us farmers."},
		{"speaker": "grandmother", "text": "They sap all our energy."},
		{"speaker": "kaido", "text": "We can help! I know how to fix electronics."},
		{"speaker": "grandmother", "text": "Really? That knowledge is illegal..."},
		{"speaker": "grandmother", "text": "But there are parts in the old shed."},
		{"speaker": "grandmother", "text": "Your grandfather used to tinker."},
		{"speaker": "grandmother", "text": "Before it was outlawed."},
		{"speaker": "kaido", "text": "Let's start with a simple LED circuit to light up the shed!"},
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
		{"speaker": "grandmother", "text": "That photograph..."},
		{"speaker": "grandmother", "text": "Where did you find it?"},
		{"speaker": "grandmother", "text": "The Resistance. We were teachers and inventors."},
		{"speaker": "grandmother", "text": "Before Energy Nation attacked."},
		{"speaker": "grandmother", "text": "They made us forget how to build, how to be free."},
		{"speaker": "grandmother", "text": "But some of us never forgot."},
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
		{"speaker": "kid", "text": "I have to warn the others!"},
		{"speaker": "milo_leave", "text": ""},
		{"speaker": "set_stage", "text": "5"},
		{"speaker": "quest", "text": "Build Silent Alarm"},
	]

func grandmother_stage_5() -> Array:
	return [
		{"speaker": "grandmother", "text": "We need to warn the village. Quietly."},
		{"speaker": "grandmother", "text": "Can you build a silent alarm?"},
		{"speaker": "grandmother", "text": "You can find more parts in the shed."},
		{"speaker": "kaido", "text": "A buzzer circuit should do it! Let's go!"},
	]

func grandmother_stage_6_7() -> Array:
	return [
		{"speaker": "grandmother", "text": "Be careful. Energy Nation robots attack on sight."},
		{"speaker": "grandmother", "text": "That was a close one."},
		{"speaker": "grandmother", "text": "There's still work to do on the farm."},
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
		{"speaker": "robot", "text": "GREETING-CUSTOMER. I-AM-SHOPKEEPER-BOT-3000."},
		{"speaker": "robot", "text": "INVENTORY: LOW. SUPPLY-CHAINS-DISRUPTED."},
		{"speaker": "robot", "text": "ENERGY-NATION-REGULATIONS... RESTRICT-GOODS."},
		{"speaker": "kaido", "text": "Even the robots are affected..."},
		{"speaker": "robot", "text": "COMMERCE-DIFFICULT. MORALE: CALCULATING... LOW."},
	]

func shop_return() -> Array:
	return [
		{"speaker": "robot", "text": "WELCOME BACK. BROWSE-INVENTORY-AVAILABLE."},
		{"speaker": "robot", "text": "ENERGY-CREDITS-REQUIRED. NO-BARTER-ACCEPTED."},
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

func mayor_return() -> Array:
	return [
		{"speaker": "villager", "text": "Still here? The commune needs all the help it can get."},
		{"speaker": "villager", "text": "But what can one child do against the Energy Nation?"},
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

func baker_return() -> Array:
	return [
		{"speaker": "robot", "text": "BREAD-FRESH. ENERGY-EFFICIENT-BAKING."},
		{"speaker": "robot", "text": "TAKE-SUSTENANCE. JOURNEY: LONG."},
	]

func baker_default() -> Array:
	return [
		{"speaker": "baker", "text": "Maybe one day we'll have fresh pastries again."},
	]

# ===========================================
# KID (MILO) DIALOGUE
# ===========================================

func kid_talk(count: int) -> Array:
	match count:
		1:
			return [
				{"speaker": "kid", "text": "I'm Milo! I run messages for the village."},
				{"speaker": "kid", "text": "Fastest feet in the valley!"},
				{"speaker": "kid", "text": "You're the one with the robot, right?"},
			]
		2:
			return [
				{"speaker": "kid", "text": "Someday I want to be a radio operator."},
				{"speaker": "kid", "text": "Send messages across the whole region!"},
				{"speaker": "kid", "text": "But you need to know circuits for that..."},
				{"speaker": "kaido", "text": "I could teach you! When things calm down."},
				{"speaker": "kid", "text": "Really?! You mean it?"},
			]
		3:
			return [
				{"speaker": "kid", "text": "My parents were taken last year."},
				{"speaker": "kid", "text": "They were teachers. That's illegal now."},
				{"speaker": "kid", "text": "Grandmother looks after me."},
				{"speaker": "kid", "text": "She says knowledge is worth protecting."},
			]
		4:
			return [
				{"speaker": "kid", "text": "I found something in the fields last week."},
				{"speaker": "kid", "text": "A piece of old tech. I hid it by the pond."},
				{"speaker": "kid", "text": "Maybe you can figure out what it is?"},
			]
		_:
			return [
				{"speaker": "kid", "text": "Be careful out there!"},
				{"speaker": "kid", "text": "I'll keep watch for patrols."},
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
