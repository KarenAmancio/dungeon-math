# gravar_clipes.gd
# GRAVADOR de clipes de demonstração do jogo (pro vídeo do PAC). O Godot grava a própria janela com o
# modo "Movie Maker" e este script joga sozinho, na velocidade de uma pessoa, desenhando uma mãozinha
# no lugar do cursor (o cursor do sistema não sai na gravação).
#
# Rodar um clipe (a janela abre; NÃO mexa no mouse enquanto grava):
#   godot --path . --write-movie gravacoes/01_menu.avi --fixed-fps 30 --script res://tools/gravar_clipes.gd -- menu
# Os clipes disponíveis estão nas funções clip_*() lá embaixo.

extends SceneTree

const SCALE := 3.0                       # posições internas (640x360) -> tela (1920x1080)

var gm
var _clip := ""
var cursor: Node2D
var _cursor_pos := Vector2(960, 700)
var _shift := false


class HandCursor extends Node2D:
	func _draw() -> void:
		CursorManager.draw_grid(self, CursorManager.HAND_UP, Vector2(-12, 0), 3.0)


func _initialize() -> void:
	gm = root.get_node("GameManager")
	var args := OS.get_cmdline_user_args()
	var clip: String = args[0] if args.size() > 0 else "menu"
	_clip = clip
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	cursor = HandCursor.new()
	cursor.position = _cursor_pos
	cursor.z_index = 4000
	layer.add_child(cursor)
	await create_timer(0.3).timeout
	await call("clip_" + clip)
	await secs(0.8)
	quit()


# ------------------------------------------------------------------ ajudantes
func secs(t: float) -> void:
	await create_timer(t).timeout


func scr(p: Vector2) -> Vector2:
	return p * SCALE


func wait_scene(id: String, extra := 1.0) -> void:
	var t := 0.0
	while (gm.current_scene_id != id or gm._busy) and t < 20.0:
		await create_timer(0.1).timeout
		t += 0.1
	await create_timer(extra).timeout


# Desliza o cursor (e o mouse de verdade) até `to` (em pixels de TELA) em `dur` segundos.
# Marca o instante em que o clipe "começa de verdade" (a cena já montada): o conversor corta tudo antes disso.
func mark_cut() -> void:
	var sec := Engine.get_frames_drawn() / 30.0
	var f := FileAccess.open(ProjectSettings.globalize_path("res://gravacoes/" + _clip + ".corte"), FileAccess.WRITE)
	f.store_string("%.2f" % sec)
	f.close()


func glide(to: Vector2, dur := 0.6) -> void:
	var from := _cursor_pos
	var steps := maxi(int(dur * 30.0), 1)
	for i in steps:
		var k := float(i + 1) / steps
		k = k * k * (3.0 - 2.0 * k)
		_cursor_pos = from.lerp(to, k)
		cursor.position = _cursor_pos
		Input.warp_mouse(_cursor_pos)
		await process_frame


func glide_i(p: Vector2, dur := 0.6) -> void:
	await glide(scr(p), dur)


func _btn(button: int, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = down
	ev.shift_pressed = _shift
	ev.position = _cursor_pos
	ev.global_position = _cursor_pos
	Input.parse_input_event(ev)
	await process_frame
	await process_frame


func click_here(shift := false) -> void:
	_shift = shift
	await _btn(MOUSE_BUTTON_LEFT, true)
	await secs(0.08)
	await _btn(MOUSE_BUTTON_LEFT, false)
	_shift = false


func click_i(p: Vector2, dur := 0.6) -> void:
	await glide_i(p, dur)
	await click_here()


func rclick_i(p: Vector2, dur := 0.6) -> void:
	await glide_i(p, dur)
	await _btn(MOUSE_BUTTON_RIGHT, true)
	await secs(0.08)
	await _btn(MOUSE_BUTTON_RIGHT, false)


func drag_i(a: Vector2, b: Vector2, dur := 0.9) -> void:
	await glide_i(a, 0.5)
	await _btn(MOUSE_BUTTON_LEFT, true)
	await glide_i(b, dur)
	await secs(0.1)
	await _btn(MOUSE_BUTTON_LEFT, false)


# ------------------------------------------------------------------ CLIPES
func clip_menu() -> void:
	var main = load("res://Main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await wait_scene("menu", 0.3)
	mark_cut()
	await secs(2.0)
	await glide(Vector2(905, 410), 1.0)               # a mão aponta o "jogar"
	await secs(2.5)


# Abre o jogo já no menu e vai pra uma cena pelo GameManager.
func boot(scene_id: String, tutorial_seen := true) -> void:
	gm.tutorial_seen = tutorial_seen
	var main = load("res://Main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await wait_scene("menu", 0.5)
	if scene_id != "menu":
		gm.go_to(scene_id)
		await wait_scene(scene_id, 0.8)


# Diálogo do Gribnok: lê as falas da primeira cena, escolhe uma resposta do Cayo e vê a reação.
func clip_dialogo() -> void:
	await boot("dialogue")
	mark_cut()
	var d = current_scene
	await glide(Vector2(1200, 930), 0.8)
	var guard := 0
	while d._scene_index == 0 and not d._finished and guard < 40:
		guard += 1
		if d._mode == "lines":
			var t := 0.0
			while d._typing and t < 8.0:
				await secs(0.1)
				t += 0.1
			await secs(1.6)                              # tempo de leitura
			await click_here()
			await secs(0.2)
		else:                                            # as 3 respostas do Cayo
			await secs(2.2)
			var row := Vector2(d._list.get_global_rect().position) + Vector2(150, 18 + 24 * 0)
			await glide(row * SCALE, 0.8)
			await secs(0.8)
			d._on_option("0")
			await secs(0.3)
	await secs(1.0)


# Tutorial da batalha (passo a passo, como o jogador vê a primeira vez).
func clip_tutorial() -> void:
	await boot("battle", false)
	mark_cut()
	var b = current_scene.battle
	var tut = b.ui.tutorial
	var ov = tut.overlay
	await secs(1.2)
	var steps: Array = TutorialBattleText.STEPS
	for i in steps.size():
		var step: Dictionary = steps[i]
		var t := 0.0
		while ov._typing and t < 12.0:
			await secs(0.1)
			t += 0.1
		await secs(1.0 + String(step["text"]).length() / 45.0)          # tempo de leitura
		if step["allow"] == "deck":
			await click_i(BattleLayout.DECK_CENTER, 0.9)
			await secs(1.8)
		if step["allow"] == "confirm":
			await click_i(BattleLayout.END_TURN_RECT.get_center(), 0.9)
			await secs(3.0)
			break
		var btn_pos: Vector2 = ov._next.get_global_transform_with_canvas() * (ov._next.size / 2.0)
		await glide(btn_pos, 0.7)
		await click_here()
		await secs(0.4)


# ------------------------------------------------------------------ ajudantes de batalha
var bt                                           # o nó Battle da cena atual


# Entra numa batalha nova com a ordem de compra do baralho "armada" (pra a demonstração ser previsível).
func new_battle(scene_id: String, deck_order: Array, tutorial_seen := true, mark := true) -> void:
	await boot(scene_id, tutorial_seen)
	bt = current_scene.battle
	var deck = bt.get_node("Deck")
	deck.player_deck = deck_order.duplicate()
	deck._update_counter()
	while bt.resolving:                          # nível 2: o Gribnok abre a luta
		await secs(0.2)
	await secs(0.6)
	if mark:
		mark_cut()


func draw(n: int) -> void:
	for i in n:
		await click_i(BattleLayout.DECK_CENTER, 0.7)
		await secs(1.3)


func hand_card(label: String):
	for c in bt.get_node("PlayerHand").player_hand:
		if c.card_label_text == label:
			return c
	return null


func slot_pos(zone_name: String, index: int) -> Vector2:
	return bt.get_node(zone_name).get_children()[index].global_position


# Arrasta a carta da mão (pelo texto dela) até o slot da zona.
func play(label: String, zone_name: String, index: int) -> void:
	var c = hand_card(label)
	if c == null:
		print("AVISO: carta ", label, " não está na mão")
		return
	await drag_i(c.global_position, slot_pos(zone_name, index), 0.9)
	await secs(0.7)


func end_turn() -> void:
	await click_i(BattleLayout.END_TURN_RECT.get_center(), 0.8)
	await secs(0.5)
	var t := 0.0
	while bt.resolving and t < 40.0:
		await secs(0.2)
		t += 0.2
	await secs(1.2)


# ------------------------------------------------------------------ CLIPES: cálculos
# Conta CERTA: +4 e depois ×2 = 8, e o ataque machuca o Gribnok.
func clip_calculo_certo() -> void:
	await new_battle("battle", ["add_4", "mul_2", "add_1", "add_3", "add_1", "add_1"])
	await draw(2)
	await play("+4", "PlayerAtackZone", 0)
	await play("×2", "PlayerAtackZone", 1)
	await secs(2.0)                                  # a conta ao vivo mostra "+4 ×2 = 8"
	await end_turn()
	await secs(2.5)


# Conta ERRADA: -5 e +1 dão -4 no ataque. O jogador perde HP em vez de atacar.
func clip_calculo_errado() -> void:
	await new_battle("battle", ["sub_5", "add_1", "add_1", "add_3", "add_1", "add_1"])
	await draw(2)
	await play("-5", "PlayerAtackZone", 0)
	await play("+1", "PlayerAtackZone", 1)
	await secs(2.5)                                  # total negativo na tela
	await end_turn()
	await secs(2.5)


# Conta CORRIGIDA: -5 deixa o total negativo, mas ×(-1) inverte o sinal ANTES de terminar o turno.
func clip_calculo_corrigido() -> void:
	await new_battle("battle", ["sub_5", "mul_neg1", "add_1", "add_3", "add_1", "add_1"])
	await draw(2)
	await play("-5", "PlayerAtackZone", 0)
	await secs(2.0)                                  # total -5: perigoso!
	await play("×(-1)", "PlayerAtackZone", 1)
	await secs(2.5)                                  # virou +5
	await end_turn()
	await secs(2.5)


# ------------------------------------------------------------------ ajudantes: campo pronto
# Deixa o Gribnok sem cartas (ele passa o turno), pra a demonstração não ser desmanchada por ele.
func mute_gribnok() -> void:
	bt.gribnok.deck.clear()
	bt.gribnok.hand.clear()


# Põe uma carta "de turnos anteriores" direto num slot (já pode trocar de lado, ser sacrificada...).
func put_old(zone_name: String, index: int, operation: String, value: int, label: String) -> Node:
	var card = load("res://Resources/Cards/Card.tscn").instantiate()
	card.card_label_text = label
	card.card_value = value
	card.card_operation = operation
	bt.get_node("CardManager").add_child(card)
	var slot = bt.get_node(zone_name).get_children()[index]
	card.global_position = slot.global_position
	card.get_node("Area2D/CollisionShape2D").disabled = true
	card.placed_round = -1
	slot.card_in_slot = true
	slot.current_card = card
	return card


func shift_click_i(p: Vector2) -> void:
	await glide_i(p, 0.7)
	await click_here(true)


func button_center(btn: Control) -> Vector2:
	return btn.get_global_transform_with_canvas() * (btn.size / 2.0)


# ------------------------------------------------------------------ CLIPES: mecânicas
# Troca de lado: o -5 do ataque vai pra defesa como +5 (botão direito).
func clip_troca() -> void:
	await new_battle("battle", ["add_1", "add_1", "add_1", "add_1"], true, false)
	mute_gribnok()
	put_old("PlayerAtackZone", 0, "add", 4, "+4")
	put_old("PlayerAtackZone", 1, "add", -5, "-5")
	put_old("PlayerAtackZone", 2, "add", 3, "+3")
	bt.refresh_swap_marks()
	await secs(0.5)
	mark_cut()
	await secs(2.5)                                  # a marquinha de troca aparece nas cartas
	await rclick_i(slot_pos("PlayerAtackZone", 1), 1.0)
	await secs(3.0)                                  # o -5 virou +5 na defesa
	await end_turn()
	await secs(1.5)


# Sacrifício -> escudo (turno 1) e sacrifício -> armadilha (turno 2), contra um Gribnok que ataca.
func clip_escudo_armadilha() -> void:
	await new_battle("battle", ["add_1", "add_1", "add_1", "add_1", "add_1", "add_1"], true, false)
	bt.gribnok.deck = ["add_4", "add_3", "add_4", "add_3", "add_4", "add_3", "add_4", "add_3"]
	put_old("PlayerAtackZone", 0, "add", 4, "+4")
	put_old("PlayerAtackZone", 1, "add", 4, "+4")
	put_old("PlayerAtackZone", 2, "add", 3, "+3")
	put_old("PlayerAtackZone", 3, "add", -5, "-5")
	put_old("PlayerAtackZone", 4, "add", -4, "-4")
	bt.refresh_swap_marks()
	await secs(0.5)
	mark_cut()
	await secs(2.0)
	await shift_click_i(slot_pos("PlayerAtackZone", 3))        # -5 vira 5 pontos
	await secs(2.0)
	await click_i(BattleLayout.SHIELD_BUTTON.get_center(), 0.9)  # 3 pontos viram um escudo +4
	await secs(2.5)
	await end_turn()
	await secs(1.5)
	# turno 2: mais um sacrifício, agora pra armar a armadilha
	var victim = null
	for slot in bt.get_node("PlayerAtackZone").get_children():
		var c = slot.current_card
		if slot.card_in_slot and c != null and c.card_value < 0 and bt.can_sacrifice_card(c):
			victim = slot
	if victim == null:
		put_old("PlayerAtackZone", 4, "add", -5, "-5")
		victim = bt.get_node("PlayerAtackZone").get_children()[4]
	await shift_click_i(victim.global_position)
	await secs(1.8)
	await click_i(BattleLayout.TRAP_BUTTON.get_center(), 0.9)
	await secs(2.5)
	await end_turn()
	await secs(2.5)


# Carta especial x²: eleva uma carta do campo (4 vira 16).
func clip_potencia() -> void:
	await new_battle("battle", ["pow_2", "add_1", "add_1", "add_1"], true, false)
	mute_gribnok()
	put_old("PlayerAtackZone", 0, "add", 4, "+4")
	bt.refresh_swap_marks()
	await secs(0.5)
	mark_cut()
	await secs(1.5)
	await draw(2)
	await play("x^2", "PlayerAtackZone", 0)
	await secs(2.5)
	await play("+1", "PlayerAtackZone", 1)
	await secs(2.0)
	await end_turn()
	await secs(2.0)


# Carta especial ÷2: resume o ataque inteiro numa carta só (e libera os slots).
func clip_divisao() -> void:
	await new_battle("battle", ["div_2", "add_3", "add_1", "add_1"], true, false)
	mute_gribnok()
	for i in 4:
		put_old("PlayerAtackZone", i, "add", 4, "+4")
	bt.refresh_swap_marks()
	await secs(0.5)
	mark_cut()
	await secs(1.5)
	await draw(2)
	await play("÷2", "PlayerAtackZone", 4)
	await secs(2.5)                                  # 16 virou uma carta de +8, sobraram slots
	await play("+3", "PlayerAtackZone", 1)
	await secs(2.0)
	await end_turn()
	await secs(2.0)


# ------------------------------------------------------------------ CLIPES: progressão de fases
# Roda um diálogo inteiro (todas as cenas) lendo rápido e escolhendo a 1ª resposta.
func run_dialogue(d, read_time := 1.3) -> void:
	await glide(Vector2(1200, 930), 0.8)
	var guard := 0
	while not d._finished and guard < 120:
		guard += 1
		if d._mode == "lines":
			var t := 0.0
			while d._typing and t < 8.0:
				await secs(0.1)
				t += 0.1
			await secs(read_time)
			await click_here()
			await secs(0.2)
		else:
			await secs(1.6)
			var row := Vector2(d._list.get_global_rect().position) + Vector2(150, 18)
			await glide(row * SCALE, 0.7)
			await secs(0.6)
			d._on_option("0")
			await secs(0.3)


# Fase 1: o Gribnok está quase morto; um ataque dá a vitória e o jogo avança pra revanche.
func clip_vitoria() -> void:
	await new_battle("battle", ["add_4", "add_1", "add_1", "add_1"])
	bt.enemy_hp = 4
	bt.update_hp_labels()
	await secs(1.0)
	await draw(1)
	await play("+4", "PlayerAtackZone", 0)
	await secs(1.5)
	await end_turn()
	var t := 0.0
	while not bt.ui.result_panel.visible and t < 10.0:
		await secs(0.2)
		t += 0.2
	await secs(3.5)                                  # tela de VITÓRIA (+ aviso da carta desbloqueada)
	var buttons: Array = bt.ui.result_panel.buttons()
	await glide(button_center(buttons[0]), 0.9)
	await secs(0.4)
	await click_here()
	await wait_scene("dialogue2", 2.5)


# Fase 2, parte 1: a conversa da revanche (as respostas da fase 1 mudam as falas).
func clip_revanche_dialogo() -> void:
	gm.dialogue_flags["medalha"] = true
	gm.dialogue_flags["educacao"] = true
	await boot("dialogue2")
	mark_cut()
	await run_dialogue(current_scene, 1.3)
	await wait_scene("battle2", 0.5)


# Fase 2, parte 2: Gribnok II abre a luta com a medalha e, na metade da vida, avisa o Plano Três.
func clip_fase2() -> void:
	gm.tutorial_seen = true
	await boot("battle2")
	mark_cut()
	bt = current_scene.battle
	bt.get_node("Deck").player_deck = ["add_4", "add_3", "add_4", "add_1", "add_3", "add_1", "add_1", "add_4"]
	bt.get_node("Deck")._update_counter()
	var t := 0.0
	while bt.resolving and t < 20.0:
		await secs(0.2)
		t += 0.2
	await secs(2.5)
	await draw(2)
	await play("+4", "PlayerAtackZone", 0)
	await play("+3", "PlayerAtackZone", 1)
	bt.enemy_hp = 20                                 # (atalho: leva o Gribnok à metade da vida pra mostrar a fúria)
	bt.update_hp_labels()
	await end_turn()                                 # no fim do turno do jogador: "Estou pensando no Plano Três..."
	await secs(2.0)
	await draw(2)
	await secs(1.0)
	await end_turn()                                 # no fim do turno dele: "o PRÓXIMO ataque vale o dobro"
	await secs(3.0)
