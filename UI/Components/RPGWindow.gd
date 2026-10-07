# RPGWindow.gd
# Janela estilo RPG clássico: fundo PRETO com degradê em degraus
# (dithering ordenado, sem suavização), borda clara dupla (cinza neutro) e cantos vazados.
# Usada pelo balão do tutorial, "Como jogar", resultado da batalha, relatório completo e,
# nas próximas etapas, pelo menu e pela pausa.
#
# A arte é gerada uma vez por tamanho (ImageTexture em cache) e só redesenhada ao redimensionar.

class_name RPGWindow
extends Control

const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
static var _cache: Dictionary = {}

var _texture: ImageTexture


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP     # clique na janela não vaza pro que está atrás


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	# a textura é criada sob demanda (e refeita se o tamanho mudou); o evento de resize
	# não dispara pra janelas montadas antes de entrarem na árvore
	if _texture == null or Vector2i(_texture.get_size()) != Vector2i(size):
		_texture = _window_texture(Vector2i(size))
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)


static func _window_texture(win_size: Vector2i) -> ImageTexture:
	if win_size.x < 8 or win_size.y < 8:
		return null
	if _cache.has(win_size):
		return _cache[win_size]
	var w := win_size.x
	var h := win_size.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top := Palette.WINDOW_TOP
	var mid := Palette.WINDOW_FILL
	var bottom := Palette.WINDOW_BOTTOM

	for y in h:
		var t := float(y) / float(h - 1)                       # 0 em cima, 1 embaixo
		for x in w:
			# dois degraus de mistura (top->mid e mid->bottom) com dithering ordenado
			var pos := t * 2.0
			var step := int(floor(pos))
			var frac := pos - step
			var dither: float = BAYER[(y % 4) * 4 + (x % 4)] / 16.0
			var use_next := frac > dither
			var color: Color
			if step == 0:
				color = mid if use_next else top
			else:
				color = bottom if use_next else mid
			img.set_pixel(x, y, color)

	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Palette.BORDER_DARK)
			elif d == 1:
				img.set_pixel(x, y, Palette.WINDOW_EDGE)              # borda clara
			elif d == 2:
				img.set_pixel(x, y, Palette.WINDOW_LINE)           # filete cinza por dentro
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixel(corner.x, corner.y, Color(0, 0, 0, 0))          # cantos vazados
	for corner in [Vector2i(1, 1), Vector2i(w - 2, 1), Vector2i(1, h - 2), Vector2i(w - 2, h - 2)]:
		img.set_pixel(corner.x, corner.y, Palette.BORDER_DARK)         # cantos "mordidos"

	var tex := ImageTexture.create_from_image(img)
	_cache[win_size] = tex
	return tex
