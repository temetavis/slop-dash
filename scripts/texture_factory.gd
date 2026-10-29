extends Object
class_name TextureFactory


static func make_texture(draw_fn: Callable) -> ImageTexture:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var rel := Vector2(x / 31.0, y / 31.0)
			var c: Color = draw_fn.call(rel, x, y)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func make_dirt() -> ImageTexture:
	return make_texture(_draw_dirt)


static func _draw_dirt(rel: Vector2, x: int, y: int) -> Color:
	var noise := fmod(absf(sin(float(x * 12.9898 + y * 78.233)) * 43758.5453), 1.0)
	if noise > 0.6:
		return Color(0.62, 0.45, 0.26)
	elif noise < 0.3:
		return Color(0.48, 0.33, 0.18)
	return Color(0.55, 0.38, 0.22)


static func make_wall() -> ImageTexture:
	return make_texture(_draw_wall)


static func _draw_wall(rel: Vector2, x: int, y: int) -> Color:
	if x % 16 == 0 or y % 16 == 0:
		return Color(0.30, 0.25, 0.38)
	return Color(0.42, 0.36, 0.50)


static func make_steel() -> ImageTexture:
	return make_texture(_draw_steel)


static func _draw_steel(rel: Vector2, x: int, y: int) -> Color:
	if x < 2 or y < 2 or x > 29 or y > 29:
		return Color(0.30, 0.31, 0.38)
	if (x + y) % 8 == 0:
		return Color(0.52, 0.54, 0.62)
	return Color(0.45, 0.47, 0.55)


static func make_boulder() -> ImageTexture:
	return make_texture(_draw_boulder)


static func _draw_boulder(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.5)).length()
	if dist > 0.48:
		return Color(0.10, 0.10, 0.12)
	var noise := fmod(absf(sin(float(x * 7.13 + y * 3.71)) * 43758.5453), 1.0)
	if dist > 0.40:
		return Color(0.45, 0.45, 0.48)
	if noise > 0.7:
		return Color(0.66, 0.66, 0.68)
	return Color(0.58, 0.58, 0.60)


static func make_gem() -> ImageTexture:
	return make_texture(_draw_gem)


static func _draw_gem(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.5)).length()
	if dist > 0.45:
		return Color(0, 0, 0, 0)
	if dist > 0.38:
		return Color(0.0, 0.45, 0.65)
	var diamond := absf(rel.x - 0.5) * 2.2 + absf(rel.y - 0.5) * 2.2
	if diamond < 0.35:
		return Color(0.4, 0.95, 1.0)
	return Color(0.1, 0.75, 0.95)


static func make_exit() -> ImageTexture:
	return make_texture(_draw_exit)


static func _draw_exit(rel: Vector2, x: int, y: int) -> Color:
	if rel.x < 0.12 or rel.x > 0.88 or rel.y < 0.12 or rel.y > 0.88:
		return Color(0.35, 0.30, 0.45)
	return Color(0.05, 0.05, 0.08)


static func make_exit_open() -> ImageTexture:
	return make_texture(_draw_exit_open)


static func _draw_exit_open(rel: Vector2, x: int, y: int) -> Color:
	if rel.x < 0.12 or rel.x > 0.88 or rel.y < 0.12 or rel.y > 0.88:
		return Color(0.35, 0.30, 0.45)
	var glow := 1.0 - maxf(absf(rel.x - 0.5), absf(rel.y - 0.5)) * 2.0
	return Color(0.2 * glow, 1.0 * glow, 0.3 * glow)


static func make_firefly() -> ImageTexture:
	return make_texture(_draw_firefly)


static func _draw_firefly(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.5)).length()
	if dist > 0.45:
		return Color(0, 0, 0, 0)
	if dist > 0.36:
		return Color(0.9, 0.45, 0.1)
	return Color(1.0, 0.7, 0.2)


static func make_butterfly() -> ImageTexture:
	return make_texture(_draw_butterfly)


static func _draw_butterfly(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.5)).length()
	if dist > 0.45:
		return Color(0, 0, 0, 0)
	if absf(rel.x - 0.5) > 0.28:
		return Color(0.55, 0.35, 0.85)
	return Color(0.75, 0.55, 0.95)


static func make_explosion() -> ImageTexture:
	return make_texture(_draw_explosion)


static func _draw_explosion(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.5)).length()
	if dist > 0.5:
		return Color(0, 0, 0, 0)
	var noise := fmod(absf(sin(float(x * 19.7 + y * 11.3)) * 43758.5453), 1.0)
	if noise > 0.5:
		return Color(1.0, 0.9, 0.3)
	return Color(1.0, 0.4, 0.1)


static func make_player() -> ImageTexture:
	return make_texture(_draw_player)


static func _draw_player(rel: Vector2, x: int, y: int) -> Color:
	var dist := (rel - Vector2(0.5, 0.55)).length()
	if dist > 0.42:
		if rel.y > 0.72 and absf(rel.x - 0.5) < 0.20:
			return Color(0.15, 0.15, 0.20)
		return Color(0, 0, 0, 0)
	if dist > 0.34:
		return Color(0.85, 0.7, 0.45)
	if (rel - Vector2(0.38, 0.48)).length() < 0.07 or (rel - Vector2(0.62, 0.48)).length() < 0.07:
		return Color(0.1, 0.1, 0.1)
	return Color(0.95, 0.85, 0.6)
