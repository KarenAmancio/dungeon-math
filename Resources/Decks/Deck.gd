extends Node2D

const CARD_SCENE_PATH = "res://Resources/Cards/Card.tscn"
const MAX_DRAWS_PER_TURN = 2

var player_deck = []
var draws_this_turn = 0


func _ready() -> void:
	player_deck = CardDatabase.build_player_deck(GameManager.unlocked_cards)   # só as especiais já desbloqueadas
	_update_counter()


# Mostra quantas cartas ainda restam no baralho ("x23").
func _update_counter() -> void:
	$Counter.text = "x%d" % player_deck.size()


# Uma carta especial acabou de ser desbloqueada NESTA luta: as cópias dela entram no baralho que
# ainda não foi comprado, em posições aleatórias.
func add_unlocked(card_name: String) -> void:
	var qty: int = CardDatabase.SPECIAL_CARDS[card_name]["quantity"]
	for i in qty:
		player_deck.insert(randi() % (player_deck.size() + 1), card_name)
	_update_counter()
	if player_deck.size() > 0 and draws_this_turn < MAX_DRAWS_PER_TURN:
		$Area2D/CollisionShape2D.disabled = false
		$"deck image".visible = true


func reset_draws() -> void:
	draws_this_turn = 0
	# Reativa o deck visualmente caso ainda tenha cartas
	if player_deck.size() > 0:
		$Area2D/CollisionShape2D.disabled = false
		$"deck image".visible = true
		$"deck image".modulate = Color.WHITE      # volta a acender (tinha escurecido ao bater o limite de saques)


func draw_card() -> void:
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		print("Deck: limite de saques por turno atingido.")
		return

	if player_deck.size() == 0:
		return

	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	draws_this_turn += 1
	_update_counter()

	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$"deck image".visible = false
	elif draws_this_turn >= MAX_DRAWS_PER_TURN:
		# Limite atingido: bloqueia o deck até o próximo turno
		$Area2D/CollisionShape2D.disabled = true
		$"deck image".modulate = Color(0.5, 0.5, 0.5)  # escurece pra indicar bloqueio

	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()

	var card_data = CardDatabase.card_data(card_drawn)
	new_card.card_label_text = card_data["label"]
	new_card.card_value      = card_data["value"]
	new_card.card_operation  = card_data["operation"]

	new_card.position = self.position
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card)
