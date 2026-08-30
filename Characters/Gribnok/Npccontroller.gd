# NPCController.gd
# IA do Gribnok — primeiro inimigo do jogo.
#
# Objetivo: uma IA por regras, simples de entender e de ajustar,
# mas que analisa o estado da batalha antes de jogar (não é só
# "puxa carta e larga na primeira zona vazia" como o placeholder
# atual em Battle.gd).
#
# Como é o primeiro personagem, ela NÃO deve jogar perfeitamente:
#   - Tem 15% de chance de tomar uma decisão aleatória (um "erro"
#     proposital, pra não ficar fácil de prever nem impossível de
#     ganhar).
#   - Se a mão dele só tem cartas modificadoras (x2, x(-1)), ele
#     entende que não vale a pena jogar sozinho e passa o turno,
#     guardando as cartas pra combinar depois com uma carta "add".
#
# Essa classe é pura lógica (extends RefCounted), sem depender da
# cena de Battle. Ela não instancia Card.tscn nem mexe em nós —
# só decide O QUE jogar e ONDE. Quem executa a decisão (criar a
# carta visualmente, colocar no slot, etc.) continua sendo o
# Battle.gd, do mesmo jeito que ele já faz em simple_enemy_turn().
#
# --------------------------------------------------------------
# COMO INTEGRAR DEPOIS NA BATTLE (só pra referência, não é preciso
# rodar nada disso agora):
#
#   var gribnok := NPCController.new()
#   ...
#   func resolve_enemy_turn():
#       gribnok.draw_cards()
#       var context = {
#           "my_attack_total": BattleMath.calculate_total(get_zone_cards_data($EnemyAttackZone)),
#           "my_defense_total": BattleMath.calculate_total(get_zone_cards_data($EnemyDefenseZone)),
#           "player_attack_total": BattleMath.calculate_total(get_zone_cards_data($PlayerAtackZone)),
#           "player_defense_total": BattleMath.calculate_total(get_zone_cards_data($PlayerDefenseZone)),
#           "my_attack_slots_free": has_empty_slot($EnemyAttackZone),
#           "my_defense_slots_free": has_empty_slot($EnemyDefenseZone),
#       }
#       var decision = gribnok.decide_play(context)
#       if decision["action"] == "play":
#           gribnok.play_card(decision["card_name"])
#           # ... instanciar a carta e colocar na zona (decision["zone"])
# --------------------------------------------------------------

class_name NPCController
extends RefCounted

const RANDOM_CHANCE := 0.15   # 15% de chance de jogar "no impulso"
const CARDS_PER_TURN := 2     # puxa o mesmo tanto que o jogador puxa por turno

var deck: Array = []
var hand: Array = []          # cada item: {"name": String, "operation": String, "value": int}


func _init(starting_deck: Array = []) -> void:
	deck = starting_deck.duplicate()
	if deck.is_empty():
		deck = CardDatabase.build_deck()


# ---------------------------------------------------------------
# COMPRAR CARTAS
# ---------------------------------------------------------------
# Chamar no início do turno do Gribnok. Ele só compra até o limite
# por turno e respeita o que já tem na mão (cartas guardadas de um
# turno anterior continuam lá).
func draw_cards() -> void:
	for i in range(CARDS_PER_TURN):
		if deck.is_empty():
			break
		var card_name = deck[0]
		deck.erase(card_name)
		var data = CardDatabase.CARDS[card_name]
		hand.append({
			"name": card_name,
			"operation": data["operation"],
			"value": data["value"]
		})
		print("Gribnok comprou: ", data["label"], " (", card_name, ") | mão atual: ", _hand_labels())


# Helper só pra debug: lista os nomes das cartas na mão, tipo ["add_3", "mul_2"].
func _hand_labels() -> Array:
	return hand.map(func(c): return c["name"])


# ---------------------------------------------------------------
# DECISÃO PRINCIPAL
# ---------------------------------------------------------------
# context esperado (o Battle.gd monta esse dicionário com o estado
# atual do tabuleiro, ver exemplo de integração lá em cima):
#   {
#     "my_attack_total": int,
#     "my_defense_total": int,
#     "player_attack_total": int,
#     "player_defense_total": int,
#     "my_attack_slots_free": bool,
#     "my_defense_slots_free": bool,
#   }
#
# Retorna:
#   {"action": "skip"}
#   {"action": "play", "card_name": String, "zone": "attack" | "defense"}
func decide_play(context: Dictionary) -> Dictionary:
	if hand.is_empty():
		return {"action": "skip"}

	# Regra da mão só com modificadores: só passa o turno se, além de
	# só ter modificador na mão, nenhum deles serve pra fazer algo com
	# o que já está nas zonas (dobrar um total positivo ou consertar
	# um total negativo). Se tiver, por exemplo, um +3 já jogado no
	# ataque e um x2 na mão, ele reconhece que 3 -> 6 vale a pena e
	# joga, em vez de guardar a mão à toa.
	if _only_has_modifiers() and not _has_useful_multiplier_play(context):
		print("Gribnok: só tenho modificadores e nada pra multiplicar/consertar ainda, vou esperar.")
		return {"action": "skip"}

	# 15% de chance de agir por impulso em vez de seguir a regra.
	if randf() < RANDOM_CHANCE:
		print("Gribnok: joga no impulso.")
		return _random_play(context)

	return _rule_based_play(context)


# Remove a carta da mão depois que o Battle.gd efetivamente jogou ela.
func play_card(card_name: String) -> void:
	for i in range(hand.size()):
		if hand[i]["name"] == card_name:
			hand.remove_at(i)
			return


# ---------------------------------------------------------------
# REGRAS DE DECISÃO
# ---------------------------------------------------------------
func _rule_based_play(context: Dictionary) -> Dictionary:
	var add_cards: Array = hand.filter(func(c): return c["operation"] == "add")
	var mult_cards: Array = hand.filter(func(c): return c["operation"] == "multiply")

	var can_attack: bool = context.get("my_attack_slots_free", false)
	var can_defend: bool = context.get("my_defense_slots_free", false)

	# Quanto o ataque do jogador ameaça passar da defesa atual do Gribnok.
	var threat_level: int = context.get("player_attack_total", 0) - context.get("my_defense_total", 0)

	# 1) Se a ameaça é real e ele ainda pode reforçar a defesa, prioriza defender.
	if threat_level > 0 and can_defend:
		var defense_card = _pick_best_add_card(add_cards)
		if defense_card != null:
			print("Gribnok: ameaça de ", threat_level, " de dano passando, reforço a defesa com ", defense_card["name"])
			return {"action": "play", "card_name": defense_card["name"], "zone": "defense"}

	# 2) Sem ameaça imediata: tenta aproveitar um modificador que já vale a pena
	#    (dobrar um total positivo, ou consertar um total que ficou negativo).
	if not mult_cards.is_empty():
		var mult_play = _try_use_multiplier(mult_cards, context)
		if mult_play != null:
			print("Gribnok: vale a pena usar modificador ", mult_play["card_name"], " na zona ", mult_play["zone"])
			return mult_play

	# 2.5) Tenho um x(-1) na mão E uma carta negativa (tipo -5)? Então vale a
	#      pena jogar o negativo DE PROPÓSITO agora, sabendo que vou inverter
	#      com o x(-1) numa jogada seguinte (ex: -5 depois x(-1) = +5, bem
	#      melhor que só jogar uma carta +1 solta e guardar o -5 pra sempre).
	var combo_play = _try_setup_invert_combo(add_cards, mult_cards, context)
	if combo_play != null:
		print("Gribnok: jogo ", combo_play["card_name"], " de propósito pra inverter com o x(-1) depois")
		return combo_play

	# 3) Ataca com a melhor carta "add" disponível.
	if can_attack:
		var attack_card = _pick_best_add_card(add_cards)
		if attack_card != null:
			print("Gribnok: sem ameaça imediata, ataco com ", attack_card["name"])
			return {"action": "play", "card_name": attack_card["name"], "zone": "attack"}

	# 4) Não pôde atacar (zona cheia ou só cartas ruins) mas ainda pode defender.
	if can_defend:
		var fallback_defense = _pick_best_add_card(add_cards)
		if fallback_defense != null:
			print("Gribnok: não deu pra atacar, reforço a defesa com ", fallback_defense["name"])
			return {"action": "play", "card_name": fallback_defense["name"], "zone": "defense"}

	# 5) Nada de bom pra fazer agora — melhor guardar a mão.
	print("Gribnok: nada de útil pra jogar agora, guardo a mão.")
	return {"action": "skip"}


# Escolhe a melhor carta "add" pra reforçar a própria zona.
# Cartas negativas (ex: -5) atrapalhariam o próprio total, então
# ele evita jogá-las enquanto tiver opção melhor.
func _pick_best_add_card(add_cards: Array):
	var best = null
	for card in add_cards:
		if card["value"] <= 0:
			continue
		if best == null or card["value"] > best["value"]:
			best = card
	return best


# Só usa o multiplicador quando faz sentido:
#   x2        -> zona já tem um total positivo pra dobrar.
#   x(-1)     -> zona ficou com total negativo (alguma carta ruim foi
#                jogada antes) e o x(-1) conserta isso.
func _try_use_multiplier(mult_cards: Array, context: Dictionary):
	var my_attack_total: int = context.get("my_attack_total", 0)
	var my_defense_total: int = context.get("my_defense_total", 0)
	var can_attack: bool = context.get("my_attack_slots_free", false)
	var can_defend: bool = context.get("my_defense_slots_free", false)

	for card in mult_cards:
		var is_double = card["value"] > 1
		var is_invert = card["value"] < 0

		if is_double:
			if my_attack_total > 0 and can_attack:
				return {"action": "play", "card_name": card["name"], "zone": "attack"}
			if my_defense_total > 0 and can_defend:
				return {"action": "play", "card_name": card["name"], "zone": "defense"}

		if is_invert:
			if my_attack_total < 0 and can_attack:
				return {"action": "play", "card_name": card["name"], "zone": "attack"}
			if my_defense_total < 0 and can_defend:
				return {"action": "play", "card_name": card["name"], "zone": "defense"}

	return null


# Vê se vale a pena jogar uma carta "add" negativa DE PROPÓSITO, sabendo
# que ainda tenho um x(-1) guardado na mão pra inverter o total depois.
# Escolhe a carta negativa "mais forte" (a que mais puxa pra baixo), já
# que é ela que vira o maior número positivo quando invertida.
# Só faz sentido se, jogando essa carta, a zona ficar negativa — senão
# não tem o que inverter.
func _try_setup_invert_combo(add_cards: Array, mult_cards: Array, context: Dictionary):
	var has_invert_card := false
	for card in mult_cards:
		if card["value"] < 0:
			has_invert_card = true
			break
	if not has_invert_card:
		return null

	var negative_add_cards: Array = add_cards.filter(func(c): return c["value"] < 0)
	if negative_add_cards.is_empty():
		return null

	var worst_card = negative_add_cards[0]
	for card in negative_add_cards:
		if card["value"] < worst_card["value"]:
			worst_card = card

	var can_attack: bool = context.get("my_attack_slots_free", false)
	var can_defend: bool = context.get("my_defense_slots_free", false)
	var my_attack_total: int = context.get("my_attack_total", 0)
	var my_defense_total: int = context.get("my_defense_total", 0)

	if can_attack and my_attack_total + worst_card["value"] < 0:
		return {"action": "play", "card_name": worst_card["name"], "zone": "attack"}
	if can_defend and my_defense_total + worst_card["value"] < 0:
		return {"action": "play", "card_name": worst_card["name"], "zone": "defense"}

	return null


# Jogada "por impulso": ignora a análise e escolhe qualquer carta
# válida da mão pra uma zona com espaço livre. É essa aleatoriedade
# que impede a IA de ficar 100% previsível.
func _random_play(context: Dictionary) -> Dictionary:
	var playable_zones = []
	if context.get("my_attack_slots_free", false):
		playable_zones.append("attack")
	if context.get("my_defense_slots_free", false):
		playable_zones.append("defense")

	if playable_zones.is_empty() or hand.is_empty():
		return {"action": "skip"}

	var random_card = hand[randi() % hand.size()]
	var random_zone = playable_zones[randi() % playable_zones.size()]
	return {"action": "play", "card_name": random_card["name"], "zone": random_zone}


func _only_has_modifiers() -> bool:
	for card in hand:
		if card["operation"] != "multiply":
			return false
	return true


# Usa a mesma análise de _try_use_multiplier só pra responder
# "existe alguma jogada de modificador que vale a pena AGORA, dado
# o que já está nas zonas?" — sem executar a jogada.
func _has_useful_multiplier_play(context: Dictionary) -> bool:
	var mult_cards: Array = hand.filter(func(c): return c["operation"] == "multiply")
	return _try_use_multiplier(mult_cards, context) != null
