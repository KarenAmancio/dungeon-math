extends Node2D

const CARD_SCENE_PATH = "res://Resources/Cards/Card.tscn"

const MAX_HP: int = 30

var player_hp: int = 30
var enemy_hp: int = 30
var game_over: bool = false
var resolving: bool = false
var round_number: int = 0   # só pra numerar as entradas do relatório

# Bloqueios de entrada (lidos pelo InputManager e pelo CardManager)
var ui_blocking: bool = false            # painel modal aberto ("Como jogar")
var tutorial_active: bool = false        # tutorial rodando: sem arrastar cartas
var tutorial_allow_deck: bool = false    # ...mas o baralho pode estar liberado no passo
var tutorial_allow_confirm: bool = false # ...e o botão Confirmar também

var gribnok: NPCController
var ui: BattleUI
var screen: Node = null     # BattleScreen que contém esta batalha (nulo se a cena rodar sozinha)


# NÍVEL 2 (a revanche): Gribnok com 40 de vida, errando só 5% das jogadas e ABRINDO a luta.
# Esses números saíram do simulador (tools/simulate_battles.gd): é o cenário "tudo junto".
const LEVEL2_ENEMY_HP := 40
const LEVEL2_RANDOM_CHANCE := 0.05

var level: int = 1


func _ready() -> void:
	level = 2 if GameManager.current_scene_id == "battle2" else 1
	gribnok = NPCController.new()
	var enemy_max := MAX_HP
	if level == 2:
		enemy_max = LEVEL2_ENEMY_HP
		enemy_hp = enemy_max
		gribnok.random_chance = LEVEL2_RANDOM_CHANCE
	ui = BattleUI.new()
	add_child(ui)
	ui.setup(self, MAX_HP, player_hp, enemy_hp, enemy_max, "GRIBNOK II" if level == 2 else "GRIBNOK")
	ui.start_tutorial_if_needed()
	if level == 2:
		_gribnok_opens.call_deferred()


# Nível 2: o Gribnok joga e ataca primeiro, antes de o jogador mexer em qualquer coisa.
func _gribnok_opens() -> void:
	resolving = true                          # o jogador fica travado enquanto ele abre
	await wait(1.4)                           # deixa a transição de cena terminar
	round_number += 1
	await resolve_enemy_turn()
	resolving = false
	refresh_swap_marks()


# ÚNICA espera do turno. Usa um nó Timer (e não get_tree().create_timer, que por padrão IGNORA a
# pausa): com o jogo pausado o relógio para, e se a cena for trocada o Timer some junto com ela,
# sem deixar uma espera pendente apontando pra uma cena que já morreu.
func wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(seconds, 0.001)
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()


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
	new_card.set_label_text(card_data["label"])
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
	await wait(0.9)  # dá tempo da animação de compra terminar

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
			"my_attack_slots_left": _free_slots($EnemyAttackZone),
			"my_defense_slots_left": _free_slots($EnemyDefenseZone),
		}

		var decision = gribnok.decide_play(context)
		if decision["action"] != "play":
			break

		var target_zone = $EnemyAttackZone if decision["zone"] == "attack" else $EnemyDefenseZone
		spawn_enemy_card(target_zone, decision["card_name"])
		gribnok.play_card(decision["card_name"])
		$EnemyHand.sync_with_hand_size(gribnok.hand.size())

		plays_made += 1
		await wait(0.35)


# Quantos slots livres a zona ainda tem (a IA do Gribnok usa pra planejar combos).
func _free_slots(zone: Node) -> int:
	var n := 0
	for slot in zone.get_children():
		if not slot.card_in_slot:
			n += 1
	return n


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
	total_card.set_label_text("+%d" % total)
	total_card.swappable = false            # é só o resumo da defesa, não uma carta jogada
	total_card.get_node("Area2D/CollisionShape2D").disabled = true
	total_card.z_index = 5

	first_slot.card_in_slot = true
	first_slot.current_card = total_card

	print("Defesa colapsada: total = ", total)


func animate_card_hit(card_node: Node) -> void:
	var original_pos = card_node.position
	var tween = get_tree().create_tween()
	tween.tween_property(card_node, "position", original_pos + Vector2(2, 0), 0.05)
	tween.tween_property(card_node, "position", original_pos - Vector2(2, 0), 0.05)
	tween.tween_property(card_node, "position", original_pos + Vector2(1, 0), 0.04)
	tween.tween_property(card_node, "position", original_pos, 0.04)
	await tween.finished


func animate_digit_drop(card_node: Node, operation: String, old_value: int, new_value: int) -> void:
	var steps = abs(old_value - new_value)
	var direction = -1 if old_value > new_value else 1

	await animate_card_hit(card_node)

	for i in range(steps):
		var current = old_value + direction * (i + 1)
		card_node.set_label_text(BattleMath.card_to_label({"operation": operation, "value": current}))
		await wait(0.08)

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

		await wait(0.15)


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
		await wait(0.15)

	return spillover


# Registra no relatório (PlayLogPanel) o que este ataque vai causar. Só lê dados
# e NÃO pausa o turno. O impacto é pré-calculado com a mesma função que o turno
# usa depois (resolve_incoming_damage), então o relatório sempre bate com o que acontece.
func log_attack(who: String, target: String, attack_tag: String, defense_tag: String, defense_name: String, attack_data: Array, defense_data: Array, defender_attack_data: Array, defender_hp: int, self_damage: int = 0) -> void:
	var attack_steps := BattleMath.calculate_steps(attack_data)
	var defense_steps := BattleMath.calculate_steps(defense_data)
	var attack_total: int = attack_steps.back()["after"] if not attack_steps.is_empty() else 0
	var defense_total: int = maxi(defense_steps.back()["after"], 0) if not defense_steps.is_empty() else 0

	var incoming := maxi(attack_total, 0)
	var absorbed := mini(defense_total, incoming)
	var spillover := incoming - absorbed
	var preview := BattleMath.resolve_incoming_damage(defense_total, defender_attack_data, incoming, defender_hp)

	ui.add_log({
		"round": round_number,
		"who": who,
		"target": target,
		"attack_tag": attack_tag,
		"defense_tag": defense_tag,
		"defense_name": defense_name,
		"attack_steps": attack_steps,
		"defense_steps": defense_steps,
		"attack_total": attack_total,
		"defense_total": defense_total,
		"absorbed": absorbed,
		"spillover": spillover,
		"removed": spillover - preview["hp_damage"],
		"hp_before": defender_hp,
		"hp_after": maxi(preview["hp"], 0),
		"self_damage": self_damage,
	})


# =============================================================
#  TROCA DE LADO
# =============================================================
# Uma carta + ou - que JÁ ESTAVA no campo desde um turno anterior pode ir pro outro lado (ataque <->
# defesa) com o sinal INVERTIDO: +3 no ataque vira -3 na defesa, e -5 no ataque vira +5 na defesa.
# (Na prática só as cartas do ATAQUE sobrevivem de um turno pro outro como cartas soltas: a defesa
# vira uma "carta resumo" a cada rodada, que não troca.)
# Não vale no mesmo turno em que a carta foi colocada (nem logo depois de trocar). Cartas × e a
# "carta resumo" da defesa não trocam. Precisa ter slot livre do outro lado.

const PLAYER_ZONES := ["PlayerAtackZone", "PlayerDefenseZone"]

# =============================================================
#  SACRIFÍCIO
# =============================================================
# SHIFT + clique numa carta sua do campo: ela some e o valor dela (sempre positivo: um -5 vale 5)
# vira PONTOS DE SACRIFÍCIO. Com os pontos você ergue um ESCUDO (carta de defesa especial).
# Limites: 1 sacrifício por turno, só carta que já estava no campo (mesma regra da troca de
# lado), no máximo 10 pontos guardados. O escudo e o resumo da defesa não podem ser sacrificados.
const MAX_SACRIFICE_POINTS := 10
const SHIELD_COST := 3
const SHIELD_VALUE := 4

var sacrifice_points: int = 0
var _last_sacrifice_round: int = -1


func sacrifice_block_reason(card: Node) -> String:
	if game_over or resolving or ui_blocking or tutorial_active:
		return "agora não"
	if not card.swappable:
		return "essa carta não pode ser sacrificada"
	if _slot_of_card(card) == null:
		return "fora do campo"
	if card.placed_round >= round_number:
		return "colocada neste turno"
	if _last_sacrifice_round == round_number:
		return "só 1 sacrifício por turno"
	if sacrifice_points >= MAX_SACRIFICE_POINTS:
		return "pontos no máximo"
	return ""


func can_sacrifice_card(card: Node) -> bool:
	return sacrifice_block_reason(card) == ""


# Sacrifica a carta. Devolve true se sacrificou.
func sacrifice_card(card: Node) -> bool:
	if not can_sacrifice_card(card):
		return false
	var slot := _slot_of_card(card)
	slot.card_in_slot = false
	slot.current_card = null
	var gained := absi(card.card_value)
	sacrifice_points = mini(sacrifice_points + gained, MAX_SACRIFICE_POINTS)
	_last_sacrifice_round = round_number
	ui.set_sacrifice_points(sacrifice_points, MAX_SACRIFICE_POINTS, SHIELD_COST)
	print("Sacrifício: ", card.card_label_text, " vira ", gained, " pontos (", sacrifice_points, ")")
	# animação: a carta encolhe e sobe até a caveira da mesa
	card.get_node("Area2D/CollisionShape2D").disabled = true
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "global_position", BattleLayout.SACRIFICE_LABEL.get_center() - Vector2(0, 30), 0.35)
	tween.chain().tween_callback(card.queue_free)
	refresh_swap_marks()
	return true


func try_sacrifice_at(pos: Vector2) -> bool:
	for zone_name in PLAYER_ZONES:
		for slot in get_node(zone_name).get_children():
			if not slot.card_in_slot or slot.current_card == null:
				continue
			var card = slot.current_card
			if Rect2(card.global_position - card.card_size / 2.0, card.card_size).has_point(pos):
				if not sacrifice_card(card):
					print("Sacrifício negado: ", sacrifice_block_reason(card))
					_shake_card(card)
				return true
	return false


# Gasta pontos e coloca uma carta de ESCUDO numa defesa livre.
func buy_shield() -> bool:
	if game_over or resolving or ui_blocking or tutorial_active:
		return false
	if sacrifice_points < SHIELD_COST:
		return false
	var slot := find_empty_slot($PlayerDefenseZone)
	if slot == null:
		print("Escudo negado: defesa cheia")
		return false
	sacrifice_points -= SHIELD_COST
	ui.set_sacrifice_points(sacrifice_points, MAX_SACRIFICE_POINTS, SHIELD_COST)
	var card = preload(CARD_SCENE_PATH).instantiate()
	card.card_value = SHIELD_VALUE
	card.card_operation = "add"
	$CardManager.add_child(card)
	card.global_position = slot.global_position
	card.set_label_text("+%d" % SHIELD_VALUE)
	card.get_node("Area2D/CollisionShape2D").disabled = true
	card.z_index = 5
	card.swappable = false                  # o escudo não troca de lado nem é sacrificado
	card.placed_round = round_number
	slot.card_in_slot = true
	slot.current_card = card
	print("Escudo erguido: +", SHIELD_VALUE, " (pontos: ", sacrifice_points, ")")
	return true


func _slot_of_card(card: Node) -> Node:
	for zone_name in PLAYER_ZONES:
		for slot in get_node(zone_name).get_children():
			if slot.card_in_slot and slot.current_card == card:
				return slot
	return null


func _other_zone_name(zone_name: String) -> String:
	return "PlayerDefenseZone" if zone_name == "PlayerAtackZone" else "PlayerAtackZone"


# Motivo de NÃO poder trocar ("" = pode).
func swap_block_reason(card: Node) -> String:
	if game_over or resolving or ui_blocking or tutorial_active:
		return "agora não"
	if card.card_operation != "add" or not card.swappable:
		return "só cartas de + e -"
	if card.placed_round >= round_number:
		return "colocada neste turno"
	var slot := _slot_of_card(card)
	if slot == null:
		return "fora do campo"
	if find_empty_slot(get_node(_other_zone_name(slot.get_parent().name))) == null:
		return "sem espaço do outro lado"
	return ""


func can_swap_card(card: Node) -> bool:
	return swap_block_reason(card) == ""


# Troca a carta de lado e inverte o sinal. Devolve true se trocou.
func swap_card(card: Node) -> bool:
	if not can_swap_card(card):
		return false
	var from_slot := _slot_of_card(card)
	var to_zone := get_node(_other_zone_name(from_slot.get_parent().name))
	var to_slot := find_empty_slot(to_zone)

	from_slot.card_in_slot = false
	from_slot.current_card = null
	to_slot.card_in_slot = true
	to_slot.current_card = card

	card.card_value = -card.card_value
	card.set_label_text(BattleMath.card_to_label({"operation": card.card_operation, "value": card.card_value}))
	card.placed_round = round_number          # conta como "colocada agora": não troca de volta no mesmo turno
	card.set_swap_ready(false)

	var tween := get_tree().create_tween()
	tween.tween_property(card, "global_position", to_slot.global_position, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print("Troca de lado: carta virou ", card.card_label_text, " em ", to_zone.name)
	refresh_swap_marks()
	return true


# Clique direito em (pos): acha a carta do campo debaixo do mouse e tenta trocar. Se não pode, a
# carta dá uma balançadinha (feedback de "não").
func try_swap_at(pos: Vector2) -> void:
	for zone_name in PLAYER_ZONES:
		for slot in get_node(zone_name).get_children():
			if not slot.card_in_slot or slot.current_card == null:
				continue
			var card = slot.current_card
			if Rect2(card.global_position - card.card_size / 2.0, card.card_size).has_point(pos):
				if not swap_card(card):
					print("Troca de lado negada: ", swap_block_reason(card))
					_shake_card(card)
				return


func _shake_card(card: Node) -> void:
	var x: float = card.position.x
	var tween := get_tree().create_tween()
	for offset in [-2.0, 2.0, -1.0, 1.0, 0.0]:
		tween.tween_property(card, "position:x", x + offset, 0.04)


# Mostra a marquinha de setas só nas cartas que podem trocar agora.
func refresh_swap_marks() -> void:
	for zone_name in PLAYER_ZONES:
		for slot in get_node(zone_name).get_children():
			if slot.card_in_slot and slot.current_card != null:
				slot.current_card.set_swap_ready(can_swap_card(slot.current_card))


# REGRA: se o total do ATAQUE de quem joga fica NEGATIVO, essa pessoa perde esse tanto de HP, logo
# no início da resolução do turno (antes de atacar). A defesa negativa continua valendo 0.
func apply_negative_attack_penalty(who: String, amount: int) -> void:
	if who == "player":
		player_hp -= amount
		print("Conta de ataque negativa: você perde ", amount, " de HP (", player_hp, ")")
	else:
		enemy_hp -= amount
		print("Conta de ataque negativa: o Gribnok perde ", amount, " de HP (", enemy_hp, ")")
	update_hp_labels()
	await wait(0.9)                      # dá tempo da barra tremer e esvaziar
	check_game_over()


func update_hp_labels() -> void:
	ui.set_hp(maxi(player_hp, 0), maxi(enemy_hp, 0))


func check_game_over() -> void:
	if player_hp <= 0 or enemy_hp <= 0:
		game_over = true

		var kind = ""
		if player_hp <= 0 and enemy_hp <= 0:
			kind = "draw"
		elif enemy_hp <= 0:
			kind = "win"
		else:
			kind = "lose"

		GameManager.register_battle_result(kind)   # só registra; o destino é decidido pelo GameManager
		ui.show_result(kind)
		print("--- FIM DE JOGO: ", kind, " ---")


# =============================================================
#  FLUXO PRINCIPAL
# =============================================================

func resolve_turn() -> void:
	if game_over or resolving:
		return
	resolving = true
	round_number += 1
	refresh_swap_marks()                    # durante a resolução ninguém troca carta

	await resolve_player_turn()

	if not game_over:
		await wait(0.6)
		await resolve_enemy_turn()

	if not game_over:
		$Deck.reset_draws()
	resolving = false
	refresh_swap_marks()                    # as cartas que ficaram no campo já podem trocar de lado


func resolve_player_turn() -> void:
	var player_attack_data = get_zone_cards_data($PlayerAtackZone)
	var enemy_attack_data  = get_zone_cards_data($EnemyAttackZone)
	var enemy_defense_data = get_zone_cards_data($EnemyDefenseZone)

	var p_atk = BattleMath.calculate_total(player_attack_data)
	var e_def = BattleMath.calculate_total(enemy_defense_data)
	var incoming_to_enemy = max(p_atk, 0)

	print("--- Turno do Jogador ---")
	print("Seu ataque: ", p_atk, " | Defesa do inimigo: ", e_def)

	var p_self := maxi(-p_atk, 0)       # regra: ataque com total negativo tira esse tanto de HP de quem atacou
	log_attack("VOCÊ", "Gribnok", "SEU ATAQUE", "DEFESA DO INIMIGO", "Defesa do inimigo",
			player_attack_data, enemy_defense_data, enemy_attack_data, enemy_hp, p_self)

	# O PRIMEIRO efeito do turno: conta negativa machuca quem a montou
	if p_self > 0:
		await apply_negative_attack_penalty("player", p_self)
		if game_over:
			return

	# Colapsa a defesa visualmente
	collapse_defense_to_total($EnemyDefenseZone, e_def)
	await wait(0.8)

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

	var e_self := maxi(-e_atk, 0)
	log_attack("GRIBNOK", "Você", "ATAQUE DO GRIBNOK", "SUA DEFESA", "Sua defesa",
			enemy_attack_data, player_defense_data, player_attack_data, player_hp, e_self)

	if e_self > 0:
		await apply_negative_attack_penalty("enemy", e_self)
		if game_over:
			return

	# Colapsa a defesa visualmente
	collapse_defense_to_total($PlayerDefenseZone, p_def)
	await wait(0.8)

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
	if tutorial_active:
		if not tutorial_allow_confirm:
			return
		# Confirmar no último passo do tutorial encerra o tutorial e joga o turno
		ui.tutorial.finish()
	resolve_turn()
