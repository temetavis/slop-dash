extends Node2D

const CELLS_PER_SECOND := 7.0
const TITLE_WOBBLE := 2.0

@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton
@onready var high_label: Label = $HighScoreLabel

func _ready() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	title.position = Vector2(vp_size.x / 2 - 140, 140)
	subtitle.position = Vector2(vp_size.x / 2 - 180, 220)
	play_button.position = Vector2(vp_size.x / 2 - 100, 330)
	quit_button.position = Vector2(vp_size.x / 2 - 100, 400)
	high_label.position = Vector2(vp_size.x / 2 - 120, 480)
	high_label.text = "High Score: %d" % GameManager.high_score
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)

func _process(delta: float) -> void:
	title.position.y = 140 + sin(Time.get_ticks_msec() / 300.0) * TITLE_WOBBLE

func _on_play() -> void:
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_on_play()
