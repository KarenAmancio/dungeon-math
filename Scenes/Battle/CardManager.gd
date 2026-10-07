extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mousebt_released", on_left_click_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y)
		)


func start_drag(card):
	# Guarda defensiva: mesmo que algo chame start_drag diretamente,
	# nunca deixa arrastar carta com o turno sendo resolvido.
	if get_parent().resolving or get_parent().tutorial_active:
		return
	card_being_dragged = card
	card.scale = Card.SCALE_NORMAL
	# Mata o tween da carta ao começar a arrastar
	player_hand_reference.cancel_card_tween(card)

#func finish_drag():
	#card_being_dragged.scale = Vector2(0.40, 0.40)
	#var card_slot_found = raycast_check_for_card_slot()
	#if card_slot_found and not card_slot_found.card_in_slot:
		## Card dropped in empty card slot
		#if card_slot_found.zone == "player_attack" or card_slot_found.zone == "player_defense":
			#card_being_dragged.position = card_slot_found.position
			#card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			#card_slot_found.card_in_slot = true
			#player_hand_reference.remove_card_from_hand(card_being_dragged)
		#card_being_dragged = null
		
		
func finish_drag():
	#a parte da escala nao funciona, só se "solta a carta em qualquer lugar, mas no caso ela devolve pra mao
	#IMPORTANTE PARA ARRUMAR O SLOT QUE FICA APARECENDO NO FUNDO
	card_being_dragged.scale = Card.SCALE_NORMAL
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		if card_slot_found.zone == "player_attack" or card_slot_found.zone == "player_defense":
			card_being_dragged.position = card_slot_found.position
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			card_slot_found.card_in_slot = true
			card_slot_found.current_card = card_being_dragged
			player_hand_reference.remove_card_from_hand(card_being_dragged)
		else:
			# Slot inválido — devolve pra mão
			player_hand_reference.return_card_to_hand(card_being_dragged)
	else:
		# Nenhum slot encontrado — devolve pra mão
		player_hand_reference.return_card_to_hand(card_being_dragged)
	card_being_dragged = null


func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_left_click_released():
	if card_being_dragged:
				finish_drag()

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		is_hovering_on_card = false
		highlight_card(card, false)

		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
			is_hovering_on_card = true
		else:
			is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered:
		card.scale = Card.SCALE_HOVER
		card.z_index = 2
	else:
		card.scale = Card.SCALE_NORMAL
		card.z_index = 1

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD

	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		return get_card_with_highest_z_index(result)

	return null
	
func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT

	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	# Assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index

	# Loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index

	return highest_z_card
