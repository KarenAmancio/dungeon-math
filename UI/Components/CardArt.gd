# CardArt.gd
# Desenho de cartas por código (sem PNG), compartilhado entre o deck, a mão do inimigo e as
# cartas. Nesta etapa: o VERSO da carta. A face (+4, ×2 etc.) entra na Etapa F.
# Tudo em pixels internos; quem chama passa o CanvasItem onde desenhar e o retângulo.

class_name CardArt
extends RefCounted

const EMBLEM: Array[String] = [
	"...X...",
	"..XXX..",
	".XXXXX.",
	"XXXXXXX",
	".XXXXX.",
	"..XXX..",
	"...X...",
]


static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect, Palette.BORDER_DARK)
	ci.draw_rect(rect.grow(-1), Palette.CARD_BACK_EDGE)
	ci.draw_rect(rect.grow(-2), Palette.CARD_BACK)
	ci.draw_rect(rect.grow(-4), Palette.CARD_BACK_EDGE.darkened(0.45), false)    # filete interno
	# cantoneiras
	for p in [rect.position + Vector2(2, 2), Vector2(rect.end.x - 4, rect.position.y + 2),
			Vector2(rect.position.x + 2, rect.end.y - 4), rect.end - Vector2(4, 4)]:
		ci.draw_rect(Rect2(p, Vector2(2, 2)), Palette.COIN_DARK)
	# losango central com caveirinha
	var c := rect.get_center()
	var o := Vector2(c.x - 3.5, c.y - 3.5)
	for j in EMBLEM.size():
		var row: String = EMBLEM[j]
		for i in row.length():
			if row[i] == "X":
				ci.draw_rect(Rect2(o.x + i, o.y + j, 1, 1), Palette.CARD_BACK_EDGE.lightened(0.15))
	ci.draw_rect(Rect2(c.x - 2, c.y - 1, 1, 1), Palette.CARD_BACK)
	ci.draw_rect(Rect2(c.x + 1, c.y - 1, 1, 1), Palette.CARD_BACK)
