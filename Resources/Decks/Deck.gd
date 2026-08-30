extends Node2D

const CARD_SCENE_PATH = "res://Resources/Cards/Card.tscn"
const MAX_DRAWS_PER_TURN = 2

var player_deck = []
var draws_this_turn = 0


func _ready() -> void:
	player_deck = CardDatabase.build_deck()


func reset_draws() -> void:
	draws_this_turn = 0
	# Reativa o deck visualmente caso ainda tenha cartas
	if player_deck.size() > 0:
		$Area2D/CollisionShape2D.disabled = false
		$"deck image".visible = true


func draw_card() -> void:
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		print("Deck: limite de saques por turno atingido.")
		return

	if player_deck.size() == 0:
		return

	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	draws_this_turn += 1

	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$"deck image".visible = false
	elif draws_this_turn >= MAX_DRAWS_PER_TURN:
		# Limite atingido: bloqueia o deck até o próximo turno
		$Area2D/CollisionShape2D.disabled = true
		$"deck image".modulate = Color(0.5, 0.5, 0.5)  # escurece pra indicar bloqueio

	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()

	var card_data = CardDatabase.CARDS[card_drawn]
	new_card.card_label_text = card_data["label"]
	new_card.card_value      = card_data["value"]
	new_card.card_operation  = card_data["operation"]

	new_card.position = self.position
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card)
