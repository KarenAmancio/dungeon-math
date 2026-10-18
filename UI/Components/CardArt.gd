# CardArt.gd
# Desenho das cartas, compartilhado entre as cartas, o baralho e a mão do inimigo. Tudo em pixels
# internos (640x360); quem chama passa o CanvasItem onde desenhar e o retângulo da carta.
#
#   draw_face: frente da carta (+4, ×2, ×(-1)...): sprite Resources/Cards/card_face.png com SÓ o
#              número, em azul, no meio.
#   draw_back: verso (Resources/Cards/card_back.png), usado também na mão do inimigo (menor).
#   draw_deck: o baralho (verso + pilha de cartas aparecendo embaixo).
#
# As artes vêm de reference/cartas roxas.webp, recortadas do fundo com tools/convert_sprite.gd
# (largura/altura 0 = qualidade original).
#
# Legibilidade: o tamanho do número é escolhido entre os tamanhos em que a fonte fica nítida
# (30, 20, 10 px): o maior que cabe inteiro dentro da carta, sem nunca quebrar linha.

class_name CardArt
extends RefCounted

# As artes ficam na qualidade ORIGINAL; quem desenha usa filtro suave (com mipmaps) pra reduzir.
const FACE_SOURCE := preload("res://Resources/Cards/card_face.png")
const BACK_SOURCE := preload("res://Resources/Cards/card_back.png")
const DECK_SOURCE := preload("res://Resources/Cards/deck_back.png")
const DECK_DRAW_SIZE := Vector2(42, 64)        # tamanho do baralho na tela (pixels internos)

static var _textures: Dictionary = {}

const NUMBER_SIZES: Array[int] = [30, 20, 10]
const NUMBER_INK := Color("#1d4fa6")          # azul: a ÚNICA coisa azul da carta
const NUMBER_MARGIN := 10.0                   # folga lateral pro número


# Fonte do projeto (vem do tema, então a troca de fonte continua num ponto só).
static func font() -> Font:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.default_font != null:
		return theme.default_font
	return ThemeDB.fallback_font


# Fonte dos números e das palavras das cartas (definida no tema, tipo "CardNumber").
static func number_font() -> Font:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.has_font("font", "CardNumber"):
		return theme.get_font("font", "CardNumber")
	return font()


# Maior tamanho de número que cabe em max_width (nunca menor que o último da lista).
static func fit_number_size(text: String, max_width: float) -> int:
	var f := number_font()
	for size in NUMBER_SIZES:
		if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
	return NUMBER_SIZES[NUMBER_SIZES.size() - 1]


# Cópia da arte com mipmaps (redução suave); feita uma vez só.
static func _smooth(key: String, source: Texture2D) -> Texture2D:
	if not _textures.has(key):
		var img := source.get_image()
		img.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(img)
	return _textures[key]


# A arte da frente (filtro suave, em qualidade original).
static func draw_face_art(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_texture_rect(_smooth("face", FACE_SOURCE), rect, false)


# O número da carta, azul, no meio. Quem chama usa um item com filtro NEAREST (o número é fonte
# de pixel e não pode ficar borrado).
static func draw_number(ci: CanvasItem, rect: Rect2, label: String) -> void:
	# Só no desenho: "×(-1)" vira "×-1" (mesma leitura, cabe em tamanho grande). O texto da carta,
	# o relatório e a conta continuam com "×(-1)".
	var text := label.replace("(", "").replace(")", "")

	# maior tamanho que cabe, com uma sombrinha de papel mais escuro
	var f := number_font()
	var size := fit_number_size(text, rect.size.x - NUMBER_MARGIN)
	var base := Vector2(rect.position.x, roundf(rect.get_center().y + (f.get_ascent(size) - f.get_descent(size)) / 2.0))
	ci.draw_string(f, base + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Color(0.35, 0.22, 0.12, 0.35))
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, NUMBER_INK)


static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_texture_rect(_smooth("back", BACK_SOURCE), rect, false)


# O baralho (sprite com a pilha), centrado em `center`.
static func draw_deck(ci: CanvasItem, center: Vector2) -> void:
	var rect := Rect2((center - DECK_DRAW_SIZE / 2.0).round(), DECK_DRAW_SIZE)
	ci.draw_texture_rect(_smooth("deck", DECK_SOURCE), rect, false)
