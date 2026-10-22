# simulate_battles.gd
# SIMULADOR de equilíbrio: joga milhares de lutas sozinho (um "bot" no lugar do jogador contra a IA
# REAL do Gribnok, o NPCController) e mostra a taxa de vitória. Usa a mesma matemática do jogo
# (BattleMath) e o mesmo fluxo de turno do Battle.gd (conta negativa tira HP, defesa vira "carta
# resumo" a cada rodada, ataque come as cartas da direita pra esquerda), sem cenas nem imagens.
#
# O bot NÃO usa a troca de lado nem o sacrifício e não tem o "feeling" de uma pessoa: serve pra
# comparar CONFIGURAÇÕES entre si (baralho A vs B), não pra dizer a taxa de vitória exata de um humano.
# Os 3 bots vão de "joga qualquer coisa" a "joga direito", pra dar uma faixa.
#
# Rodar (precisa ser como CENA, pra carregar os Autoloads):
#   godot --headless --quiet --path . res://tools/simulate_battles.tscn -- 600 caminho/saida.txt

extends Node

const MAX_ROUNDS := 60
const ATTACK_SLOTS := 5
const DEFENSE_SLOTS := 4
const MAX_HP := 30

# Baralhos (nome da carta -> quantidade), usando os nomes do CardDatabase.
const DECKS := {
	"atual (23)": {"add_1": 7, "add_3": 3, "add_4": 4, "sub_5": 4, "mul_2": 3, "mul_neg1": 2},
	# a proposta tinha uma ×0; a IA do Gribnok ainda não sabe usá-la, então aqui ela vira +1
	"proposta (36)": {"add_1": 8, "add_2": 5, "add_3": 4, "add_4": 3, "add_5": 1,
			"sub_1": 3, "sub_2": 2, "sub_3": 2, "sub_4": 1, "sub_5": 2, "mul_2": 3, "mul_neg1": 2},
}

var _results: Array[String] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 600
	var out_path: String = args[1] if args.size() > 1 else ""
	seed(20261022)

	# cada experimento: baralho, chance de erro da IA, quem abre, vida do Gribnok
	var experiments: Array[Dictionary] = [
		{"nome": "A. jogo de hoje (baralho atual)", "deck": "atual (23)", "random": 0.15, "opening": "player", "enemy_hp": 30},
		{"nome": "B. baralho novo de 36 cartas", "deck": "proposta (36)", "random": 0.15, "opening": "player", "enemy_hp": 30},
		{"nome": "C. B + Gribnok abre a luta", "deck": "proposta (36)", "random": 0.15, "opening": "enemy", "enemy_hp": 30},
		{"nome": "D. B + IA do Gribnok errando só 5%", "deck": "proposta (36)", "random": 0.05, "opening": "player", "enemy_hp": 30},
		{"nome": "E. B + IA 5% + Gribnok com 40 de HP", "deck": "proposta (36)", "random": 0.05, "opening": "player", "enemy_hp": 40},
		{"nome": "F. tudo junto: IA 5% + Gribnok abre + 40 de HP", "deck": "proposta (36)", "random": 0.05, "opening": "enemy", "enemy_hp": 40},
		{"nome": "G. B + defesa com CONTRA-GOLPE (1/3 do que absorve volta em quem atacou)", "deck": "proposta (36)", "random": 0.15, "opening": "player", "enemy_hp": 30, "counter": 0.34},
	]
	var bots := ["aleatório", "ofensivo", "equilibrado"]

	_log("Simulação: %d lutas por linha. Taxa de VITÓRIA do jogador (derrota / empate / não terminou em %d rodadas)." % [games, MAX_ROUNDS])
	for ex in experiments:
		_log("")
		_log(ex["nome"])
		for bot in bots:
			var wins := 0
			var losses := 0
			var draws := 0
			var timeouts := 0
			var rounds_sum := 0
			for g in games:
				var r := _play_game(ex, bot)
				rounds_sum += r["rounds"]
				match r["result"]:
					"win": wins += 1
					"lose": losses += 1
					"draw": draws += 1
					_: timeouts += 1
			_log("   bot %-12s vitória %5.1f%%   (derrota %4.1f%%, empate %3.1f%%, sem fim %3.1f%%)   duração média %.1f rodadas" % [
				bot, 100.0 * wins / games, 100.0 * losses / games, 100.0 * draws / games, 100.0 * timeouts / games, float(rounds_sum) / games])

	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string("\n".join(_results) + "\n")
		f.close()
	get_tree().quit()


func _log(text: String) -> void:
	_results.append(text)


# ---------------------------------------------------------------------------
# UMA LUTA
# ---------------------------------------------------------------------------
func _play_game(cfg: Dictionary, bot: String) -> Dictionary:
	var def: Dictionary = DECKS[cfg["deck"]]
	var s := {
		"p_hp": MAX_HP, "e_hp": cfg["enemy_hp"],
		"p_atk": [], "p_def": [], "e_atk": [], "e_def": [],
		"p_hand": [], "p_deck": _shuffled_deck(def),
		"npc": NPCController.new(_shuffled_deck(def)),
		"counter": cfg.get("counter", 0.0),     # contra-golpe: fração do dano absorvido que volta em quem atacou
	}
	s["npc"].random_chance = cfg["random"]

	var rounds := 0
	if cfg["opening"] == "enemy":
		_enemy_plan(s)
		if _resolve_side(s, "e"):
			return {"result": _outcome(s), "rounds": rounds}
	while rounds < MAX_ROUNDS:
		rounds += 1
		_player_plan(s, bot)
		if _resolve_side(s, "p"):
			return {"result": _outcome(s), "rounds": rounds}
		_enemy_plan(s)
		if _resolve_side(s, "e"):
			return {"result": _outcome(s), "rounds": rounds}
	return {"result": "timeout", "rounds": rounds}


func _outcome(s: Dictionary) -> String:
	if s["p_hp"] <= 0 and s["e_hp"] <= 0:
		return "draw"
	return "win" if s["e_hp"] <= 0 else "lose"


func _shuffled_deck(def: Dictionary) -> Array:
	var deck: Array = []
	for name in def:
		for i in def[name]:
			deck.append(name)
	deck.shuffle()
	return deck


func _card(name: String) -> Dictionary:
	var d: Dictionary = CardDatabase.CARDS[name]
	return {"name": name, "operation": d["operation"], "value": d["value"]}


func _total(cards: Array) -> int:
	return BattleMath.calculate_total(cards)


# ---------------------------------------------------------------------------
# RESOLUÇÃO DE UM ATAQUE (mesmo fluxo do Battle.gd). Devolve true se a luta acabou.
# ---------------------------------------------------------------------------
func _resolve_side(s: Dictionary, who: String) -> bool:
	var opp := "e" if who == "p" else "p"
	var a := _total(s[who + "_atk"])
	if a < 0:                                   # regra: ataque negativo tira HP de quem atacou
		s[who + "_hp"] += a
		if s[who + "_hp"] <= 0:
			return true
	var incoming := maxi(a, 0)
	var d := _total(s[opp + "_def"])
	s[opp + "_def"] = [] if d <= 0 else [{"operation": "add", "value": d}]   # defesa vira "carta resumo"
	var spill := incoming
	if d > 0:
		var r := BattleMath.apply_damage_to_defense(d, incoming)
		spill = r["spillover"]
		if s["counter"] > 0.0:
			s[who + "_hp"] -= int(minf(d, incoming) * s["counter"])
			if s[who + "_hp"] <= 0:
				return true
		s[opp + "_def"] = [] if r["total"] <= 0 else [{"operation": "add", "value": r["total"]}]
	var res := BattleMath.resolve_incoming_damage(0, s[opp + "_atk"], spill, s[opp + "_hp"])
	s[opp + "_atk"] = res["attack_cards"]
	s[opp + "_hp"] = res["hp"]
	return s["p_hp"] <= 0 or s["e_hp"] <= 0


# ---------------------------------------------------------------------------
# GRIBNOK (a IA de verdade)
# ---------------------------------------------------------------------------
func _enemy_plan(s: Dictionary) -> void:
	var npc: NPCController = s["npc"]
	npc.draw_cards()
	for plays in 6:
		var ctx := {
			"my_attack_total": _total(s["e_atk"]),
			"my_defense_total": _total(s["e_def"]),
			"player_attack_total": _total(s["p_atk"]),
			"player_defense_total": _total(s["p_def"]),
			"my_attack_slots_free": s["e_atk"].size() < ATTACK_SLOTS,
			"my_defense_slots_free": s["e_def"].size() < DEFENSE_SLOTS,
		}
		var decision: Dictionary = npc.decide_play(ctx)
		if decision["action"] != "play":
			break
		var zone: Array = s["e_atk"] if decision["zone"] == "attack" else s["e_def"]
		var cap := ATTACK_SLOTS if decision["zone"] == "attack" else DEFENSE_SLOTS
		if zone.size() < cap:
			zone.append({"operation": CardDatabase.CARDS[decision["card_name"]]["operation"], "value": CardDatabase.CARDS[decision["card_name"]]["value"]})
		npc.play_card(decision["card_name"])      # (como no jogo: a carta sai da mão mesmo sem slot)


# ---------------------------------------------------------------------------
# BOTS DO JOGADOR
# ---------------------------------------------------------------------------
func _draw_two(s: Dictionary) -> void:
	for i in 2:
		if not s["p_deck"].is_empty():
			s["p_hand"].append(_card(s["p_deck"].pop_front()))


func _play_to(s: Dictionary, index: int, zone_key: String) -> bool:
	var cap := ATTACK_SLOTS if zone_key == "p_atk" else DEFENSE_SLOTS
	if s[zone_key].size() >= cap:
		return false
	var c: Dictionary = s["p_hand"][index]
	s[zone_key].append({"operation": c["operation"], "value": c["value"]})
	s["p_hand"].remove_at(index)
	return true


func _player_plan(s: Dictionary, bot: String) -> void:
	_draw_two(s)
	if bot == "aleatório":
		_plan_random(s)
	else:
		_plan_smart(s, bot == "equilibrado")


# Joga cartas aleatórias em zonas aleatórias (limite inferior: alguém que não entendeu o jogo).
func _plan_random(s: Dictionary) -> void:
	var i: int = s["p_hand"].size() - 1
	while i >= 0:
		if randf() < 0.6:
			_play_to(s, i, "p_atk" if randf() < 0.5 else "p_def")
		i -= 1


# Joga com um critério: soma positivos no ataque (maiores primeiro), usa ×2 quando já tem total
# bom, conserta total negativo com ×(-1), guarda cartas negativas. O "equilibrado" também reforça
# a defesa quando o Gribnok está ameaçando mais do que o escudo aguenta.
func _plan_smart(s: Dictionary, defend: bool) -> void:
	for guard in 12:
		var hand: Array = s["p_hand"]
		var t := _total(s["p_atk"])
		var acted := false

		var inv := _find(hand, "multiply", -1)
		if t < 0 and inv >= 0 and _play_to(s, inv, "p_atk"):
			continue

		var best := -1
		for i in hand.size():
			if hand[i]["operation"] == "add" and hand[i]["value"] > 0 and (best < 0 or hand[i]["value"] > hand[best]["value"]):
				best = i
		if best >= 0:
			var threat := _total(s["e_atk"]) - _total(s["p_def"])
			if defend and t >= 3 and threat > 0 and s["p_def"].size() < DEFENSE_SLOTS:
				acted = _play_to(s, best, "p_def")
			else:
				acted = _play_to(s, best, "p_atk")
				if not acted and s["p_def"].size() < DEFENSE_SLOTS:
					acted = _play_to(s, best, "p_def")
			if acted:
				continue

		var dbl := _find(hand, "multiply", 2)
		if dbl >= 0 and t >= 3 and _play_to(s, dbl, "p_atk"):
			continue
		break


func _find(hand: Array, operation: String, value: int) -> int:
	for i in hand.size():
		if hand[i]["operation"] == operation and hand[i]["value"] == value:
			return i
	return -1
