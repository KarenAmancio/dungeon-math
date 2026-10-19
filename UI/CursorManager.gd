# CursorManager.gd
# Cursor de MÃO em pixel art, desenhado por código (sem textura). A mesma mão serve de cursor do
# mouse (apontando pra cima, ampliada ×3 pra combinar com a tela de 640x360 ampliada) e de
# indicador de seleção nos menus (apontando pra direita).
#
#   CursorManager.use_hand()      # liga o cursor de mão
#   CursorManager.use_default()   # volta pro cursor padrão do sistema

class_name CursorManager
extends RefCounted

const SCALE := 3          # mesma ampliação do PixelViewport
# X = contorno, W = preenchimento. 12 colunas × 14 linhas, apontando pra cima.
const HAND_UP: Array[String] = [
	"....XX......",
	"...XWWX.....",
	"...XWWX.....",
	"...XWWX.....",
	"...XWWXXX...",
	"...XWWXWWXX.",
	"XX.XWWXWWXWX",
	"XWXXWWWWWWWX",
	"XWWXWWWWWWWX",
	".XWWWWWWWWWX",
	".XWWWWWWWWX.",
	"..XWWWWWWWX.",
	"..XWWWWWWX..",
	"...XXXXXXX..",
]

static var _cursor_texture: ImageTexture


# Grade da mão girada 90° pra direita (usada como seta de seleção das listas).
static func hand_right() -> Array[String]:
	var rows := HAND_UP.size()
	var cols := HAND_UP[0].length()
	var out: Array[String] = []
	for x in cols:
		var line := ""
		for y in range(rows - 1, -1, -1):
			line += HAND_UP[y][x]
		out.append(line)
	return out


# Desenha uma grade (X/W) em `ci` na posição `pos`, com pixels de tamanho `px`.
static func draw_grid(ci: CanvasItem, grid: Array[String], pos: Vector2, px: float = 1.0, outline: Color = Palette.BORDER_DARK, fill: Color = Palette.TEXT_LIGHT) -> void:
	for j in grid.size():
		var row: String = grid[j]
		for i in row.length():
			var c := row[i]
			if c == "X":
				ci.draw_rect(Rect2(pos.x + i * px, pos.y + j * px, px, px), outline)
			elif c == "W":
				ci.draw_rect(Rect2(pos.x + i * px, pos.y + j * px, px, px), fill)


static var hand_active: bool = false      # true enquanto o cursor de mão está ligado


static func use_hand() -> void:
	hand_active = true
	if _cursor_texture == null:
		var cols := HAND_UP[0].length()
		var img := Image.create(cols, HAND_UP.size(), false, Image.FORMAT_RGBA8)
		for j in HAND_UP.size():
			var row: String = HAND_UP[j]
			for i in cols:
				var c := row[i]
				img.set_pixel(i, j, Palette.BORDER_DARK if c == "X" else (Palette.TEXT_LIGHT if c == "W" else Color(0, 0, 0, 0)))
		img.resize(cols * SCALE, HAND_UP.size() * SCALE, Image.INTERPOLATE_NEAREST)
		_cursor_texture = ImageTexture.create_from_image(img)
	# a ponta do dedo (coluna 4, linha 0) é o "clique"
	Input.set_custom_mouse_cursor(_cursor_texture, Input.CURSOR_ARROW, Vector2(4.5 * SCALE, 0))
	Input.set_custom_mouse_cursor(_cursor_texture, Input.CURSOR_POINTING_HAND, Vector2(4.5 * SCALE, 0))


static func use_default() -> void:
	hand_active = false
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
