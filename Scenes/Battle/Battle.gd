extends Node2D

const CARD_SCENE_PATH = "res://Resources/Cards/Card.tscn"

var player_hp: int = 30
var enemy_hp: int = 30
var game_over: bool = false
var resolving: bool = false

var gribnok: NPCController


func _ready() -> void:
	$GameOverLabel.visible = false
	gribnok = NPCController.new()


func get_zone_cards_data(zone: Node) -> Array:
	var cards_data = []
	for slot in zone.get_children():
		if slot.card_in_slot and slot.current_card != null:
			cards_data.append({
				"operation": slot.current_card.card_operation,
				"value": slot.current_card.card_value,
				"card_node": slot.current_card,
				"slot_node": slot
			})
	return cards_data


func spawn_enemy_card(zone: Node, card_name: String) -> void:
	var empty_slot = find_empty_slot(zone)
	if empty_slot == null:
		print("Gribnok: sem slot livre em ", zone.name, ", não joga.")
		return

	var card_data = CardDatabase.CARDS[card_name]

	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.card_label_text = card_data["label"]
	new_card.card_value = card_data["value"]
	new_card.card_operation = card_data["operation"]

	$CardManager.add_child(new_card)
	new_card.global_position = empty_slot.global_position
	new_card.get_node("CardLabel").text = card_data["label"]
	new_card.get_node("Area2D/CollisionShape2D").disabled = true
	new_card.z_index = 5

	empty_slot.card_in_slot = true
	empty_slot.current_card = new_card

	print("Gribnok jogou: ", card_data["label"], " em ", zone.name)


# Roda a IA do Gribnok pro turno inteiro: compra as cartas do turno e
# vai pedindo decisões pro NPCController uma a uma (igual o jogador,
# que também pode jogar mais de uma carta por turno), até ele decidir
# "skip" ou não ter mais onde jogar.
func resolve_gribnok_turn() -> void:
	gribnok.draw_cards()
	$EnemyHand.sync_with_hand_size(gribnok.hand.size())
	await get_tree().create_timer(0.9).timeout  # dá tempo da animação de compra terminar

	var plays_made := 0
	const MAX_PLAYS_PER_TURN := 6  # trava de segurança, evita loop infinito

	while plays_made < MAX_PLAYS_PER_TURN:
		var context = {
			"my_attack_total": BattleMath.calculate_total(get_zone_cards_data($EnemyAttackZone)),
			"my_defense_total": BattleMath.calculate_total(get_zone_cards_data($EnemyDefenseZone)),
			"player_attack_total": BattleMath.calculate_total(get_zone_cards_data($PlayerAtackZone)),
			"player_defense_total": BattleMath.calculate_total(get_zone_cards_data($PlayerDefenseZone)),
			"my_attack_slots_free": find_empty_slot($EnemyAttackZone) != null,
			"my_defense_slots_free": find_empty_slot($EnemyDefenseZone) != null,
		}

		var decision = gribnok.decide_play(context)
		if decision["action"] != "play":
			break

		var target_zone = $EnemyAttackZone if decision["zone"] == "attack" else $EnemyDefenseZone
		spawn_enemy_card(target_zone, decision["card_name"])
		gribnok.play_card(decision["card_name"])
		$EnemyHand.sync_with_hand_size(gribnok.hand.size())

		plays_made += 1
		await get_tree().create_timer(0.35).timeout


func find_empty_slot(zone: Node) -> Node:
	for slot in zone.get_children():
		if not slot.card_in_slot:
			return slot
	return null


func clear_zone_cards(zone: Node) -> void:
	for slot in zone.get_children():
		if slot.card_in_slot and slot.current_card != null:
			slot.current_card.queue_free()
			slot.current_card = null
			slot.card_in_slot = false


func collapse_defense_to_total(zone: Node, total: int) -> void:
	var slots = zone.get_children()

	for slot in slots:
		if slot.card_in_slot and slot.current_card != null:
			slot.current_card.queue_free()
			slot.current_card = null
			slot.card_in_slot = false

	if total <= 0:
		return

	var first_slot = slots[0]
	var card_scene = preload(CARD_SCENE_PATH)
	var total_card = card_scene.instantiate()
	total_card.card_value = total
	total_card.card_operation = "add"

	$CardManager.add_child(total_card)
	total_card.global_position = first_slot.global_position
	total_card.get_node("CardLabel").text = "+%d" % total
	total_card.get_node("Area2D/CollisionShape2D").disabled = true
	total_card.z_index = 5

	first_slot.card_in_slot = true
	first_slot.current_card = total_card

	print("Defesa colapsada: total = ", total)


func animate_card_hit(card_node: Node) -> void:
	var original_pos = card_node.position
	var tween = get_tree().create_tween()
	tween.tween_property(card_node, "position", original_pos + Vector2(6, 0), 0.05)
	tween.tween_property(card_node, "position", original_pos - Vector2(6, 0), 0.05)
	tween.tween_property(card_node, "position", original_pos + Vector2(4, 0), 0.04)
	tween.tween_property(card_node, "position", original_pos, 0.04)
	await tween.finished


func animate_digit_drop(card_node: Node, operation: String, old_value: int, new_value: int) -> void:
	var label = card_node.get_node("CardLabel")
	var steps = abs(old_value - new_value)
	var direction = -1 if old_value > new_value else 1

	await animate_card_hit(card_node)

	for i in range(steps):
		var current = old_value + direction * (i + 1)
		label.text = BattleMath.card_to_label({"operation": operation, "value": current})
		await get_tree().create_timer(0.08).timeout

	card_node.card_value = new_value


func animate_card_remove(card_node: Node, slot_node: Node) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(card_node, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	slot_node.card_in_slot = false
	slot_node.current_card = null
	card_node.queue_free()


func animate_attack_on_zone(cards_before: Array, cards_after: Array) -> void:
	var surviving = {}
	for card in cards_after:
		surviving[card["card_node"]] = card["value"]

	for i in range(cards_before.size() - 1, -1, -1):
		var card = cards_before[i]
		var card_node = card["card_node"]
		var slot_node = card["slot_node"]

		if surviving.has(card_node):
			var new_value = surviving[card_node]
			if new_value != card["value"]:
				await animate_digit_drop(card_node, card["operation"], card["value"], new_value)
		else:
			await animate_digit_drop(card_node, card["operation"], card["value"], 0)
			await animate_card_remove(card_node, slot_node)

		await get_tree().create_timer(0.15).timeout


# Anima o dano na defesa colapsada.
# Retorna o spillover (dano que passou da defesa pro ataque/HP).
func animate_defense_damage(defense_zone: Node, def_total: int, incoming: int) -> int:
	var defense_result = BattleMath.apply_damage_to_defense(def_total, incoming)
	var new_def = defense_result["total"]
	var spillover = defense_result["spillover"]

	var defense_collapsed = get_zone_cards_data(defense_zone)
	if defense_collapsed.size() > 0:
		var def_card = defense_collapsed[0]
		if new_def <= 0:
			await animate_digit_drop(def_card["card_node"], "add", def_total, 0)
			await animate_card_remove(def_card["card_node"], def_card["slot_node"])
		else:
			await animate_digit_drop(def_card["card_node"], "add", def_total, new_def)
		await get_tree().create_timer(0.15).timeout

	return spillover


func update_hp_labels() -> void:
	$PlayerHPLabel.text = "HP: %d" % max(player_hp, 0)
	$EnemyHPLabel.text = "HP: %d" % max(enemy_hp, 0)


func check_game_over() -> void:
	if player_hp <= 0 or enemy_hp <= 0:
		game_over = true

		var message = ""
		if player_hp <= 0 and enemy_hp <= 0:
			message = "Empate!"
		elif enemy_hp <= 0:
			message = "Você venceu!"
		else:
			message = "Você perdeu!"

		$GameOverLabel.text = message
		$GameOverLabel.visible = true
		print("--- FIM DE JOGO: ", message, " ---")


# =============================================================
#  FLUXO PRINCIPAL
# =============================================================

func resolve_turn() -> void:
	if game_over or resolving:
		return
	resolving = true

	await resolve_player_turn()

	if not game_over:
		await get_tree().create_timer(0.6).timeout
		await resolve_enemy_turn()

	if not game_over:
		$Deck.reset_draws()
	resolving = false


func resolve_player_turn() -> void:
	var player_attack_data = get_zone_cards_data($PlayerAtackZone)
	var enemy_attack_data  = get_zone_cards_data($EnemyAttackZone)
	var enemy_defense_data = get_zone_cards_data($EnemyDefenseZone)

	var p_atk = BattleMath.calculate_total(player_attack_data)
	var e_def = BattleMath.calculate_total(enemy_defense_data)
	var incoming_to_enemy = max(p_atk, 0)

	print("--- Turno do Jogador ---")
	print("Seu ataque: ", p_atk, " | Defesa do inimigo: ", e_def)

	# Colapsa a defesa visualmente
	collapse_defense_to_total($EnemyDefenseZone, e_def)
	await get_tree().create_timer(0.8).timeout

	# 1) Anima a defesa e descobre quanto dano passou
	var spillover = 0
	if e_def > 0:
		spillover = await animate_defense_damage($EnemyDefenseZone, e_def, incoming_to_enemy)
	else:
		spillover = incoming_to_enemy

	# 2) Com o spillover, calcula e anima o dano nas cartas de ataque do inimigo
	var enemy_result = BattleMath.resolve_incoming_damage(0, enemy_attack_data, spillover, enemy_hp)

	print("Inimigo HP: ", enemy_hp, " → ", enemy_result["hp"], " (dano: ", enemy_result["hp_damage"], ")")

	await animate_attack_on_zone(enemy_attack_data, enemy_result["attack_cards"])
	enemy_hp = enemy_result["hp"]
	update_hp_labels()

	check_game_over()


func resolve_enemy_turn() -> void:
	await resolve_gribnok_turn()

	var player_attack_data  = get_zone_cards_data($PlayerAtackZone)
	var enemy_attack_data   = get_zone_cards_data($EnemyAttackZone)
	var player_defense_data = get_zone_cards_data($PlayerDefenseZone)

	var e_atk = BattleMath.calculate_total(enemy_attack_data)
	var p_def = BattleMath.calculate_total(player_defense_data)
	var incoming_to_player = max(e_atk, 0)

	print("--- Turno do Inimigo ---")
	print("Ataque do inimigo: ", e_atk, " | Sua defesa: ", p_def)

	# Colapsa a defesa visualmente
	collapse_defense_to_total($PlayerDefenseZone, p_def)
	await get_tree().create_timer(0.8).timeout

	# 1) Anima a defesa e descobre quanto dano passou
	var spillover = 0
	if p_def > 0:
		spillover = await animate_defense_damage($PlayerDefenseZone, p_def, incoming_to_player)
	else:
		spillover = incoming_to_player

	# 2) Com o spillover, calcula e anima o dano nas cartas de ataque do jogador
	var player_result = BattleMath.resolve_incoming_damage(0, player_attack_data, spillover, player_hp)

	print("Player HP: ", player_hp, " → ", player_result["hp"], " (dano: ", player_result["hp_damage"], ")")

	await animate_attack_on_zone(player_attack_data, player_result["attack_cards"])
	player_hp = player_result["hp"]
	update_hp_labels()

	check_game_over()


func _on_button_pressed() -> void:
	resolve_turn()
