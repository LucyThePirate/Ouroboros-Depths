extends SkillStrategy

@export var heal_amount := 2
@export var text_scene: PackedScene

var fortunes := [
	"if you die in the real life, you die in the game; keep your flesh prison healthy!",
	"you should drink water.... NOW!!!!",
	"penis",
	"I forgot what I was going to say",
	"Have you ever had a dream that you, um, you had, your, you- you could, you’ll do, you- you wants, you, you could do so, you- you’ll do, you could- you, you want, you want them to do you so much you could do anything?",
	"oh! this fortune cookie was full of poison gas, make a constitution saving throw!",
	"i forgor [img]res://textures/Creatures/Lich/Skull.png[/img]",
	"🧱 When the walls fade 🧱  🕑 Time is your only enemy 🕖"
]


func _ready():
	super()


func use_skill(grid_entity: GridEntity):
	$CookieOpen.play()
	var new_text_component = text_scene.instantiate() as TextComponent
	add_child(new_text_component)
	new_text_component.initialize(false)
	new_text_component.global_position = grid_entity.global_position
	(
		new_text_component
		. set_text(
			fortunes.pick_random(),
			'[rainbow freq=.5 sat=0.8 val=0.8 speed=.5][wave amp=50.0 freq=5.0 connected=1]"%s"[/wave][/rainbow]'
		)
	)
	grid_entity.heal(heal_amount)
	super(grid_entity)
