extends Node2D

signal level_complete
signal game_over
signal gems_changed(collected: int, required: int)
signal exit_opened

enum Tile { EMPTY, DIRT, WALL, STEEL, BOULDER, GEM, EXIT, FIREFLY, BUTTERFLY, FALLING_BOULDER, FALLING_GEM, EXPLOSION }

const CELL := 32.0
const MOVE_INTERVAL := 0.15
const ANIM_INTERVAL := 0.15
const GEM_SCORE := 25
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var grid: Array = []
var grid_width := 0
var grid_height := 0
var player_pos := Vector2i.ZERO
var player_alive := false
var player_facing := 1
var gems_collected := 0
var gems_required := 0
var exit_pos := Vector2i.ZERO
var exit_is_open := false
var move_timer := 0.0
var anim_timer := 0.0
var score := 0
var level_index := 0
var pending_death := false
var level_won := false
var level_end_timer := -1.0
var turning := false
var falling: Array = []
var enemy_facing := {}

var tex_dirt: ImageTexture
var tex_wall: ImageTexture
var tex_steel: ImageTexture
var tex_boulder: ImageTexture
var tex_gem: ImageTexture
var tex_exit: ImageTexture
var tex_exit_open: ImageTexture
var tex_firefly: ImageTexture
var tex_butterfly: ImageTexture
var tex_explosion: ImageTexture
var tex_player: ImageTexture

@onready var tile_layer: Node2D = $TileLayer
@onready var player_sprite: Sprite2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var gem_label: Label = $HUD/HUDBox/GemLabel
@onready var score_label: Label = $HUD/HUDBox/ScoreLabel
@onready var level_label: Label = $HUD/HUDBox/LevelLabel
@onready var game_over_panel: ColorRect = $HUD/CenterPanel
@onready var game_over_label: Label = $HUD/CenterPanel/VBox/MessageLabel
@onready var game_over_hint: Label = $HUD/CenterPanel/VBox/HintLabel


func _ready() -> void:
	_build_textures()
	_load_level(GameManager.current_level)


func _build_textures() -> void:
	tex_dirt = TextureFactory.make_dirt()
	tex_wall = TextureFactory.make_wall()
	tex_steel = TextureFactory.make_steel()
	tex_boulder = TextureFactory.make_boulder()
	tex_gem = TextureFactory.make_gem()
	tex_exit = TextureFactory.make_exit()
	tex_exit_open = TextureFactory.make_exit_open()
	tex_firefly = TextureFactory.make_firefly()
	tex_butterfly = TextureFactory.make_butterfly()
	tex_explosion = TextureFactory.make_explosion()
	tex_player = TextureFactory.make_player()
	player_sprite.texture = tex_player


func _find_player_in_map(map_text: String) -> Vector2i:
	var lines: Array = map_text.strip_edges().split("\n")
	for y in range(lines.size()):
		var line: String = lines[y].strip_edges()
		var x := line.find(LevelData.PLAYER)
		if x >= 0:
			return Vector2i(x + 1, y + 1)
	return Vector2i(-1, -1)


func _convert_map(char_grid: Array) -> Array:
	var mapping := {
		LevelData.EMPTY: Tile.EMPTY,
		LevelData.DIRT: Tile.DIRT,
		LevelData.WALL: Tile.WALL,
		LevelData.STEEL: Tile.STEEL,
		LevelData.BOULDER: Tile.BOULDER,
		LevelData.GEM: Tile.GEM,
		LevelData.EXIT: Tile.EXIT,
		LevelData.FIREFLY: Tile.FIREFLY,
		LevelData.BUTTERFLY: Tile.BUTTERFLY,
		LevelData.PLAYER: Tile.EMPTY,
	}
	var result: Array = []
	for y in range(char_grid.size()):
		var row: Array = []
		for x in range(char_grid[y].size()):
			var ch: String = char_grid[y][x]
			row.push_back(mapping.get(ch, Tile.STEEL))
		result.push_back(row)
	return result


func _load_level(index: int) -> void:
	var data: Dictionary = LevelData.get_level(index)
	if data.is_empty():
		index = 0
		GameManager.current_level = 0
		data = LevelData.get_level(0)
	level_index = index
	grid = _convert_map(LevelData.parse_map(data.get("map", "")))
	grid_width = grid[0].size()
	grid_height = grid.size()
	falling = []
	falling.resize(grid_width * grid_height)
	for i in range(falling.size()):
		falling[i] = false
	enemy_facing = {}
	gems_required = data.get("gems", 0)
	gems_collected = 0
	score = GameManager.score
	exit_is_open = false
	pending_death = false
	level_won = false
	turning = false
	level_end_timer = -1.0
	game_over_panel.visible = false
	for y in range(grid_height):
		for x in range(grid_width):
			match grid[y][x]:
				Tile.EMPTY:
					pass
				Tile.EXIT:
					exit_pos = Vector2i(x, y)
				_:
					pass
	var player_start := _find_player_in_map(data.get("map", ""))
	if player_start != Vector2i(-1, -1):
		player_pos = player_start
		player_alive = true
	else:
		push_error("Level %d has no player start" % index)
	level_label.text = "%d. %s" % [index + 1, data.get("name", "Level")]
	_apply_gravity()
	_sync_player_sprite()
	_update_hud()


func _sync_player_sprite() -> void:
	player_sprite.position = (Vector2(player_pos) + Vector2(0.5, 0.5)) * CELL
	player_sprite.scale = Vector2(player_facing, 1)


func _update_hud() -> void:
	gem_label.text = "Gems %d / %d" % [gems_collected, gems_required]
	score_label.text = "Score %d" % score


func _physics_process(delta: float) -> void:
	if pending_death and level_end_timer > 0.0:
		level_end_timer -= delta
		if level_end_timer <= 0.0:
			_end_level(level_won)
		return
	if pending_death:
		return
	move_timer += delta
	anim_timer += delta
	if move_timer >= MOVE_INTERVAL:
		move_timer = 0.0
		_take_turn()
	if anim_timer >= ANIM_INTERVAL:
		anim_timer = 0.0
		_decay_explosions()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameManager.record_high_score()
		GameManager.reload_current_level()
	elif event.is_action_pressed("ui_cancel"):
		GameManager.record_high_score()
		GameManager.go_to_menu()
	elif event.is_action_pressed("grab") and pending_death:
		GameManager.reload_current_level()


func _take_turn() -> void:
	turning = true
	var input_dir := Vector2i.ZERO
	var grab := false
	if Input.is_action_pressed("move_left"):
		input_dir = Vector2i.LEFT
		player_facing = -1
	elif Input.is_action_pressed("move_right"):
		input_dir = Vector2i.RIGHT
		player_facing = 1
	elif Input.is_action_pressed("move_up"):
		input_dir = Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		input_dir = Vector2i.DOWN
	if Input.is_action_pressed("grab"):
		grab = true
	_apply_gravity()
	_update_enemies()
	if input_dir != Vector2i.ZERO:
		_try_player_move(input_dir, grab)
	_apply_gravity()
	_check_hazards()
	_render()
	turning = false


func _try_player_move(dir: Vector2i, grab: bool) -> void:
	var target: Vector2i = player_pos + dir
	if not _in_bounds(target):
		return
	match grid[target.y][target.x]:
		Tile.EMPTY:
			player_pos = target
			_sync_player_sprite()
		Tile.DIRT:
			grid[target.y][target.x] = Tile.EMPTY
			player_pos = target
			_sync_player_sprite()
		Tile.GEM, Tile.FALLING_GEM:
			grid[target.y][target.x] = Tile.EMPTY
			gems_collected += 1
			score += GEM_SCORE
			_check_exit_open()
			player_pos = target
			_sync_player_sprite()
			_update_hud()
		Tile.EXIT:
			if exit_is_open:
				player_pos = target
				_sync_player_sprite()
				if pending_death:
					return
				_win_level()
		Tile.BOULDER:
			if dir.y == 0:
				var beyond: Vector2i = target + dir
				if _in_bounds(beyond) and grid[beyond.y][beyond.x] == Tile.EMPTY:
					grid[beyond.y][beyond.x] = Tile.BOULDER
					grid[target.y][target.x] = Tile.EMPTY
					score += 5
					player_pos = target
					_sync_player_sprite()
					_update_hud()


func _check_exit_open() -> void:
	if not exit_is_open and gems_collected >= gems_required:
		exit_is_open = true
		exit_opened.emit()


func _win_level() -> void:
	if pending_death:
		return
	pending_death = true
	level_won = true
	level_end_timer = 1.0
	game_over_label.text = "LEVEL COMPLETE!"
	game_over_hint.text = "Get ready for the next cave..."
	game_over_panel.visible = true
	score += 250
	GameManager.score = score
	GameManager.current_level = level_index + 1
	GameManager.save_game()


func _die() -> void:
	if pending_death:
		return
	pending_death = true
	level_end_timer = 1.5
	player_alive = false
	player_sprite.visible = false
	_explode_at(player_pos, true)
	game_over_label.text = "GAME OVER"
	game_over_hint.text = "The cave claims another digger..."
	game_over_panel.visible = true
	GameManager.score = 0
	GameManager.current_level = level_index


func _end_level(won: bool) -> void:
	if won and level_index + 1 < LevelData.get_level_count():
		GameManager.reload_current_level()
	elif won:
		GameManager.record_high_score()
		get_tree().change_scene_to_file("res://scenes/victory.tscn")
	else:
		GameManager.record_high_score()
		GameManager.reload_current_level()


func _explode_at(center: Vector2i, kill_player: bool = false, drop_gems: bool = false) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not _in_bounds(pos):
				continue
			var tile: int = grid[pos.y][pos.x]
			if tile == Tile.STEEL or tile == Tile.EXIT:
				continue
			if not kill_player and pos == player_pos:
				continue
			grid[pos.y][pos.x] = Tile.GEM if drop_gems else Tile.EXPLOSION
			if grid[pos.y][pos.x] == Tile.GEM:
				falling[_falling_index(pos.x, pos.y)] = false


func _update_enemies() -> void:
	var fireflies: Array = []
	var butterflies: Array = []
	for y in range(grid_height):
		for x in range(grid_width):
			match grid[y][x]:
				Tile.FIREFLY:
					fireflies.append(Vector2i(x, y))
				Tile.BUTTERFLY:
					butterflies.append(Vector2i(x, y))
	for pos in fireflies:
		_move_enemy(pos, Tile.FIREFLY, 1)
	for pos in butterflies:
		_move_enemy(pos, Tile.BUTTERFLY, -1)


const ENEMY_DIRS := [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]


func _move_enemy(pos: Vector2i, kind: int, rotation_dir: int) -> void:
	if grid[pos.y][pos.x] != kind:
		return
	var facing: int = enemy_facing.get(pos, 2 if kind == Tile.FIREFLY else 0)
	var next_dir: int = facing
	var moved := false
	for attempt in range(4):
		next_dir = (next_dir + rotation_dir + 4) % 4
		var dir: Vector2i = ENEMY_DIRS[next_dir]
		var target: Vector2i = pos + dir
		if not _in_bounds(target):
			continue
		if grid[target.y][target.x] == Tile.EMPTY:
			grid[target.y][target.x] = kind
			grid[pos.y][pos.x] = Tile.EMPTY
			enemy_facing.erase(pos)
			enemy_facing[target] = next_dir
			moved = true
			break
	if not moved:
		enemy_facing[pos] = next_dir


func _falling_index(x: int, y: int) -> int:
	return y * grid_width + x


func _apply_gravity() -> void:
	for y in range(grid_height - 2, -1, -1):
		for x in range(grid_width):
			var tile: int = grid[y][x]
			var idx := _falling_index(x, y)
			if tile not in [Tile.BOULDER, Tile.GEM]:
				falling[idx] = false
				continue
			var was_falling: bool = falling[idx]
			var below: int = grid[y + 1][x]
			if below == Tile.EMPTY:
				grid[y + 1][x] = tile
				grid[y][x] = Tile.EMPTY
				falling[idx] = false
				falling[_falling_index(x, y + 1)] = true
			elif below in [Tile.BOULDER, Tile.GEM, Tile.WALL, Tile.STEEL, Tile.DIRT, Tile.EXIT]:
				var side_left: bool = x > 0 and grid[y][x - 1] == Tile.EMPTY and grid[y + 1][x - 1] == Tile.EMPTY
				var side_right: bool = x < grid_width - 1 and grid[y][x + 1] == Tile.EMPTY and grid[y + 1][x + 1] == Tile.EMPTY
				if side_left and side_right:
					var dx := -1 if randf() < 0.5 else 1
					grid[y + 1][x + dx] = tile
					grid[y][x] = Tile.EMPTY
					falling[idx] = false
					falling[_falling_index(x + dx, y + 1)] = true
				elif side_left:
					grid[y + 1][x - 1] = tile
					grid[y][x] = Tile.EMPTY
					falling[idx] = false
					falling[_falling_index(x - 1, y + 1)] = true
				elif side_right:
					grid[y + 1][x + 1] = tile
					grid[y][x] = Tile.EMPTY
					falling[idx] = false
					falling[_falling_index(x + 1, y + 1)] = true
				else:
					falling[idx] = false
			elif below == Tile.FIREFLY or below == Tile.BUTTERFLY:
				if was_falling:
					_explode_at(Vector2i(x, y + 1), false, below == Tile.BUTTERFLY)
					grid[y][x] = Tile.EMPTY
					falling[idx] = false
			elif below == Tile.EXPLOSION:
				grid[y][x] = Tile.EMPTY
				falling[idx] = false
			else:
				falling[idx] = false


func _check_hazards() -> void:
	if not player_alive:
		return
	var own_tile: int = grid[player_pos.y][player_pos.x]
	if own_tile in [Tile.BOULDER, Tile.GEM] and falling[_falling_index(player_pos.x, player_pos.y)]:
		_die()
		return
	var above: Vector2i = player_pos + Vector2i(0, -1)
	if _in_bounds(above) and grid[above.y][above.x] in [Tile.BOULDER, Tile.GEM]:
		if falling[_falling_index(above.x, above.y)]:
			_die()
			return
	for dir in DIRS:
		var n: Vector2i = player_pos + dir
		if _in_bounds(n) and grid[n.y][n.x] in [Tile.FIREFLY, Tile.BUTTERFLY]:
			_die()
			return


func _decay_explosions() -> void:
	var changed := false
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x] == Tile.EXPLOSION:
				grid[y][x] = Tile.EMPTY
				changed = true
	if changed:
		_render()


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


func _render() -> void:
	for child in tile_layer.get_children():
		child.queue_free()
	for y in range(grid_height):
		for x in range(grid_width):
			var tile: int = grid[y][x]
			if tile == Tile.EMPTY or tile == Tile.EXPLOSION:
				if tile == Tile.EXPLOSION:
					_spawn_tile(tex_explosion, x, y)
				continue
			match tile:
				Tile.DIRT:
					_spawn_tile(tex_dirt, x, y)
				Tile.WALL:
					_spawn_tile(tex_wall, x, y)
				Tile.STEEL:
					_spawn_tile(tex_steel, x, y)
				Tile.BOULDER:
					_spawn_tile(tex_boulder, x, y)
				Tile.GEM:
					_spawn_tile(tex_gem, x, y)
				Tile.EXIT:
					_spawn_tile(tex_exit_open if exit_is_open else tex_exit, x, y)
				Tile.FIREFLY:
					_spawn_tile(tex_firefly, x, y)
				Tile.BUTTERFLY:
					_spawn_tile(tex_butterfly, x, y)
				Tile.FALLING_BOULDER:
					_spawn_tile(tex_boulder, x, y)
				Tile.FALLING_GEM:
					_spawn_tile(tex_gem, x, y)


func _spawn_tile(texture: Texture2D, x: int, y: int) -> void:
	var s := Sprite2D.new()
	s.texture = texture
	s.position = (Vector2(x, y) + Vector2(0.5, 0.5)) * CELL
	tile_layer.add_child(s)
