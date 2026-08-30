extends Node2D

const CARD_WIDTH = 100 
const HAND_Y_POSITION = 890

var player_hand = []
var center_screen_x
var card_tweens = {}  # guarda o tween de cada carta

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_positions()
	
func remove_card_from_hand(card):
	player_hand.erase(card)
	# Limpa o tween da carta removida
	if card_tweens.has(card):
		card_tweens[card].kill()
		card_tweens.erase(card)
	update_hand_positions()
	
func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		animate_card_to_position(card, new_position)

func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	@warning_ignore("integer_division")
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func animate_card_to_position(card, new_position):
	# Mata o tween anterior dessa carta se existir
	if card_tweens.has(card):
		card_tweens[card].kill()
	
	var tween = get_tree().create_tween()
	card_tweens[card] = tween
	tween.tween_property(card, "global_position", new_position, 0.9)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)


func cancel_card_tween(card):
	if card_tweens.has(card):
		card_tweens[card].kill()
		card_tweens.erase(card)
		
func return_card_to_hand(card):
	if not player_hand.has(card):
		player_hand.insert(0,card)
		card.get_node("Area2D/CollisionShape2D").disabled = false
	update_hand_positions()
