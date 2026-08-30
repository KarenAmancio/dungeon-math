# EnemyHand.gd
# Representação visual da mão do Gribnok: só cartas viradas (verso),
# sem valor nem interação — o jogador nunca vê o que ele tem.
#
# Não guarda dado de jogo nenhum (isso é responsabilidade do
# NPCController.hand). Essa cena só espelha visualmente o TAMANHO
# dessa mão. Battle.gd chama sync_with_hand_size(gribnok.hand.size())
# toda vez que a mão do Gribnok muda (compra ou joga carta).

extends Node2D

const CARD_WIDTH = 120
const HAND_Y_POSITION = 100  # bem no topo da tela, mas ainda totalmente visível
const CARD_SCENE_PATH = "res://Resources/Cards/Card.tscn"

var enemy_hand_cards: Array = []   # nós Card.tscn (face_down = true)
var center_screen_x: float
var card_tweens = {}


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


# Ajusta a quantidade de cartas viradas em tela pra bater com o
# tamanho real da mão do Gribnok.
func sync_with_hand_size(hand_size: int) -> void:
	while enemy_hand_cards.size() < hand_size:
		_add_face_down_card()
	while enemy_hand_cards.size() > hand_size:
		_remove_one_face_down_card()


func _add_face_down_card() -> void:
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.face_down = true
	new_card.position = Vector2(center_screen_x, -150)  # entra vindo de cima da tela
	add_child(new_card)
	enemy_hand_cards.insert(0, new_card)
	update_hand_positions()


func _remove_one_face_down_card() -> void:
	if enemy_hand_cards.is_empty():
		return

	var card = enemy_hand_cards.pop_back()
	if card_tweens.has(card):
		card_tweens[card].kill()
		card_tweens.erase(card)

	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", Vector2(0, 0), 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(card.queue_free)

	update_hand_positions()


func update_hand_positions() -> void:
	for i in range(enemy_hand_cards.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		animate_card_to_position(enemy_hand_cards[i], new_position)


func calculate_card_position(index: int) -> float:
	var total_width = (enemy_hand_cards.size() - 1) * CARD_WIDTH
	@warning_ignore("integer_division")
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset


func animate_card_to_position(card, new_position) -> void:
	if card_tweens.has(card):
		card_tweens[card].kill()

	var tween = get_tree().create_tween()
	card_tweens[card] = tween
	tween.tween_property(card, "global_position", new_position, 0.9)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
