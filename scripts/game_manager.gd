extends Node

const SAVE_PATH := "user://slopdash_save.json"

var score: int = 0
var current_level: int = 0
var high_score: int = 0


func _ready() -> void:
	print("[SlopDash] GameManager autoload ready")
	_setup_input()
	load_game()
	print("[SlopDash] save loaded: high_score=%d current_level=%d" % [high_score, current_level])


func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A], [KEY_LEFT])
	_add_key_action("move_right", [KEY_D], [KEY_RIGHT])
	_add_key_action("move_up", [KEY_W], [KEY_UP])
	_add_key_action("move_down", [KEY_S], [KEY_DOWN])
	_add_key_action("grab", [KEY_SPACE, KEY_Z])
	_add_key_action("restart", [KEY_R])
	_add_key_action("ui_cancel", [KEY_ESCAPE])
	print("[SlopDash] input actions registered")


func _add_key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func reload_current_level() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func reset_run() -> void:
	score = 0
	current_level = 0


func save_game() -> void:
	var data := {
		"high_score": high_score,
		"score": score,
		"current_level": current_level,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		high_score = int(parsed.get("high_score", 0))
		score = int(parsed.get("score", 0))
		current_level = int(parsed.get("current_level", 0))


func record_high_score() -> void:
	if score > high_score:
		high_score = score
		save_game()
