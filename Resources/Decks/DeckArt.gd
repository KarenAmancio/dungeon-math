# DeckArt.gd
# Pilha de cartas viradas desenhada por código (substitui o PNG do deck).
# Tem o mesmo nome de nó que antes ("deck image"), então o Deck.gd continua escondendo
# e escurecendo o visual do mesmo jeito.

extends Node2D

const CARD_SIZE := Vector2(42, 58)
const LAYERS := 4         # espessura da pilha


func _draw() -> void:
	var top_left := -Vector2(23, 31)
	for i in range(LAYERS - 1, -1, -1):
		CardArt.draw_back(self, Rect2(top_left + Vector2(i, i), CARD_SIZE))
