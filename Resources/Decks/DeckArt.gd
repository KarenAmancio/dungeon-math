# DeckArt.gd
# Pilha de cartas viradas desenhada por código (substitui o PNG do deck).
# Tem o mesmo nome de nó que antes ("deck image"), então o Deck.gd continua escondendo
# e escurecendo o visual do mesmo jeito.

extends Node2D

# A pilha é uma arte só (Resources/Cards/deck_back.png), já com a espessura das cartas.
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _draw() -> void:
	CardArt.draw_deck(self, Vector2.ZERO)
