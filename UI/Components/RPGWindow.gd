# RPGWindow.gd
# Janela simples: miolo preto LISO (sem degradê), contorno escuro e uma borda clara de 1 px.
# Os cantos têm o "degrauzinho" do pixel art: o canto some e a borda faz a curva com o pixel
# entrando em diagonal.
# Usada pelo balão do tutorial, "Como jogar", resultado, relatório, menu, pausa e créditos.
#
# A arte é gerada uma vez por tamanho (ImageTexture em cache) e só redesenhada ao redimensionar.

class_name RPGWindow
extends Control

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
	img.fill(Palette.WINDOW_FILL)

	# contorno escuro (d=0) e borda clara (d=1)
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Palette.BORDER_DARK)
			elif d == 1:
				img.set_pixel(x, y, Palette.WINDOW_EDGE)

	# cantos em degrau: some o pixel de fora e o contorno desce na diagonal
	for corner in [[0, 0, 1, 1], [w - 1, 0, -1, 1], [0, h - 1, 1, -1], [w - 1, h - 1, -1, -1]]:
		var cx: int = corner[0]
		var cy: int = corner[1]
		var dx: int = corner[2]
		var dy: int = corner[3]
		img.set_pixel(cx, cy, Color(0, 0, 0, 0))
		img.set_pixel(cx + dx, cy, Color(0, 0, 0, 0))
		img.set_pixel(cx, cy + dy, Color(0, 0, 0, 0))
		img.set_pixel(cx + dx * 2, cy, Palette.BORDER_DARK)
		img.set_pixel(cx, cy + dy * 2, Palette.BORDER_DARK)
		img.set_pixel(cx + dx, cy + dy, Palette.BORDER_DARK)
		img.set_pixel(cx + dx * 2, cy + dy, Palette.WINDOW_EDGE)
		img.set_pixel(cx + dx, cy + dy * 2, Palette.WINDOW_EDGE)

	var tex := ImageTexture.create_from_image(img)
	_cache[win_size] = tex
	return tex
