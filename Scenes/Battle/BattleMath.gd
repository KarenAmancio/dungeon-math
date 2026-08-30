# BattleMath.gd
# Motor de cálculo do "Dungeon Math".
#
# Representação de uma carta: um Dictionary com:
#   { "operation": "add" ou "multiply", "value": <int> }
#
# Exemplos:
#   {"operation": "add",      "value": 3}   -> carta "+3"
#   {"operation": "add",      "value": -5}  -> carta "-5"
#   {"operation": "multiply", "value": 2}   -> carta "×2"
#   {"operation": "multiply", "value": -1}  -> carta "×(-1)" (inverte o sinal do total)
#
# Isso casa com o formato que já existe no CardDatabase.gd
# (campos "operation" e "value" de cada carta).

class_name BattleMath
extends RefCounted


# ---------------------------------------------------------------------------
# 1) TOTAL DE UMA ZONA
# ---------------------------------------------------------------------------
# Aplica as cartas na ordem (esquerda -> direita), sem prioridade de sinal.
# "starting_value" serve para a Defesa, que começa o round a partir do valor
# que sobrou da fusão do round anterior (ver apply_damage_to_defense).
# Para a zona de Ataque, normalmente starting_value = 0.
static func calculate_total(cards: Array, starting_value: int = 0) -> int:
	var total = starting_value
	for card in cards:
		match card["operation"]:
			"add":
				total += card["value"]
			"multiply":
				total *= card["value"]
	return total


# ---------------------------------------------------------------------------
# 2) DANO NA ZONA DE ATAQUE
# ---------------------------------------------------------------------------
# Recebe a lista de cartas do Ataque e a quantidade de dano que "passou" pela
# defesa. Percorre as cartas da DIREITA pra ESQUERDA:
#   - Se o dígito (valor absoluto) da carta <= dano que falta:
#       remove a carta inteira e desconta o dígito do dano que falta.
#   - Se o dígito da carta > dano que falta:
#       a carta NÃO é removida, só "perde dígitos": novo dígito = dígito - dano,
#       mantendo o mesmo sinal/operação. O dano que falta zera e o loop para.
#
# Retorna um Dictionary:
#   {
#     "cards": Array   -> nova lista de cartas do ataque (já modificada)
#     "leftover": int  -> dano que não coube nas cartas (vai pro HP)
#   }
static func apply_damage_to_attack(cards: Array, damage: int) -> Dictionary:
	var remaining_cards = cards.duplicate(true)
	var leftover = damage

	var i = remaining_cards.size() - 1
	while i >= 0 and leftover > 0:
		var card = remaining_cards[i]
		var digit = abs(card["value"])

		if digit <= leftover:
			# carta inteira é consumida
			leftover -= digit
			remaining_cards.remove_at(i)
		else:
			# carta perde só parte do dígito, mantendo o sinal
			var new_digit = digit - leftover
			if card["value"] < 0:
				card["value"] = -new_digit
			else:
				card["value"] = new_digit
			leftover = 0

		i -= 1

	return {"cards": remaining_cards, "leftover": leftover}


# ---------------------------------------------------------------------------
# 3) DANO NA ZONA DE DEFESA
# ---------------------------------------------------------------------------
# A defesa não guarda cartas separadas pra esse cálculo: ela é tratada como
# UM NÚMERO (o total calculado no round). Esse número é "fundido" e reduzido
# pelo dano que chega:
#
#   novo_total = defense_total - damage
#
#   - Se novo_total >= 0: a defesa absorveu tudo. "spillover" = 0.
#     Esse novo_total será o "starting_value" da defesa no próximo round
#     (ver calculate_total).
#   - Se novo_total < 0: a defesa não tinha o suficiente. Ela vai pra 0
#     e o que faltou ("spillover") é o dano que sobra pra zona de Ataque.
#
# Retorna:
#   {
#     "total": int      -> novo total da defesa (>= 0)
#     "spillover": int  -> dano restante para aplicar no Ataque (>= 0)
#   }
static func apply_damage_to_defense(defense_total: int, damage: int) -> Dictionary:
	var new_total = defense_total - damage
	var spillover = 0

	if new_total < 0:
		spillover = -new_total
		new_total = 0

	return {"total": new_total, "spillover": spillover}


# ---------------------------------------------------------------------------
# 4) RESOLUÇÃO COMPLETA DE UM ATAQUE RECEBIDO
# ---------------------------------------------------------------------------
# Junta os passos 2 e 3 numa função só. Use isso quando um jogador (ou o
# inimigo) recebe "incoming_damage" pontos de dano:
#
#   1. A defesa absorve o que conseguir (passo 3).
#   2. O que sobrar ("spillover") desconta das cartas de ataque (passo 2).
#   3. O que sobrar disso desconta da vida (HP).
#
# Parâmetros:
#   defense_total   -> total atual da defesa (int)
#   attack_cards    -> lista de cartas da zona de ataque
#   incoming_damage -> dano total que está chegando
#   hp              -> vida atual
#
# Retorna:
#   {
#     "defense_total": int   -> novo total da defesa
#     "attack_cards": Array  -> nova lista de cartas de ataque
#     "hp": int              -> nova vida
#     "hp_damage": int       -> quanto efetivamente foi tirado do HP (pra UI/log)
#   }
static func resolve_incoming_damage(defense_total: int, attack_cards: Array, incoming_damage: int, hp: int) -> Dictionary:
	var defense_result = apply_damage_to_defense(defense_total, incoming_damage)
	var new_defense_total = defense_result["total"]
	var spillover = defense_result["spillover"]

	var new_attack_cards = attack_cards.duplicate(true)
	var hp_damage = 0

	if spillover > 0:
		var attack_result = apply_damage_to_attack(new_attack_cards, spillover)
		new_attack_cards = attack_result["cards"]
		hp_damage = attack_result["leftover"]

	var new_hp = hp - hp_damage

	return {
		"defense_total": new_defense_total,
		"attack_cards": new_attack_cards,
		"hp": new_hp,
		"hp_damage": hp_damage
	}


# ---------------------------------------------------------------------------
# 5) HELPER: gerar o "label" (texto exibido na carta) a partir de uma carta
# ---------------------------------------------------------------------------
# Útil depois que apply_damage_to_attack reduz o dígito de uma carta, pra
# atualizar o texto exibido nela.
static func card_to_label(card: Dictionary) -> String:
	var value = card["value"]
	match card["operation"]:
		"add":
			if value >= 0:
				return "+%d" % value
			else:
				return "%d" % value  # já vem com o "-"
		"multiply":
			if value >= 0:
				return "×%d" % value
			else:
				return "×(%d)" % value
	return "?"
