# CardDatabase.gd
extends Node

const CARDS = {
	"add_1":    { "label": "+1",     "value": 1,  "operation": "add",      "quantity": 7 },
	"add_4":    { "label": "+4",     "value": 4,  "operation": "add",      "quantity": 4 },
	"sub_5":    { "label": "-5",     "value": -5, "operation": "add",      "quantity": 4 },
	"mul_2":    { "label": "×2",     "value": 2,  "operation": "multiply", "quantity": 3 },
	"mul_neg1": { "label": "×(-1)", "value": -1,  "operation": "multiply", "quantity": 2 },
	"add_3": {"label": "+3", "value": 3, "operation": "add", "quantity":3},

	# Cartas NOVAS (quantity 0 = ainda NÃO entram no baralho do jogo). Existem na base pra o simulador
	# (tools/simulate_battles.gd) poder testar baralhos maiores. Pra adotar uma, é só subir a quantidade.
	"add_2": {"label": "+2", "value": 2, "operation": "add", "quantity": 0},
	"add_5": {"label": "+5", "value": 5, "operation": "add", "quantity": 0},
	"sub_1": {"label": "-1", "value": -1, "operation": "add", "quantity": 0},
	"sub_2": {"label": "-2", "value": -2, "operation": "add", "quantity": 0},
	"sub_3": {"label": "-3", "value": -3, "operation": "add", "quantity": 0},
	"sub_4": {"label": "-4", "value": -4, "operation": "add", "quantity": 0},
}
# Total: 23 cartas por deck

# Essa função monta o deck já com as quantidades certas
static func build_deck() -> Array:
	var deck = []
	for card_name in CARDS:
		for i in range(CARDS[card_name]["quantity"]):
			deck.append(card_name)
	deck.shuffle()
	return deck
