extends Node2D

@onready var score_label: Label = $ScoreLabel
@onready var menu_button: Button = $MenuButton

func _ready() -> void:
	score_label.text = "You escaped all the caves!\nFinal Score: %d" % GameManager.score
	menu_button.pressed.connect(_on_menu)

func _on_menu() -> void:
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
