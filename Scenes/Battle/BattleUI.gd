# BattleUI.gd
# Monta por código toda a apresentação da batalha, em pixels internos (640x360, ver
# BattleLayout): fundo (imagem), textos das 4 zonas, retratos + HP e os botões "II" e "?".
# Relatório, tutorial, "Como jogar" e resultado também vivem dentro do SubViewport (mesmos
# pixels do resto do jogo), cada um na sua CanvasLayer.
# O Battle.gd só chama set_hp(), show_result() e add_log(). Não mexe em lógica de turno.

class_name BattleUI
extends Node

const BACKGROUND_PATH := "res://Backgrounds/battle_bg.png"

var battle: Node2D
var enemy_bar: HPBar
var enemy_portrait: Portrait
var hud_layer: CanvasLayer
var _points_label: Label
var _enemy_face_lock: String = ""        # enquanto não for "", o rosto do Gribnok fica nessa expressão (fúria)
var _shield_button: TextButton
var _trap_button: TextButton
var player_portrait: Portrait
var _max_hp: int = 30
var _enemy_max_hp: int = 30
var _enemy_name: String = "GRIBNOK"
var player_bar: HPBar
var result_panel: ResultPanel
var log_panel: PlayLogPanel
var how_to_play: HowToPlayPanel
var tutorial: BattleTutorial
var pause_menu: PauseMenu

var _zones: Dictionary = {}      # nó da zona -> ZonePanel
var _player_attack_panel: ZonePanel
var _player_defense_panel: ZonePanel


func setup(battle_node: Node2D, max_hp: int, player_hp: int, enemy_hp: int, enemy_max_hp: int = -1, enemy_name: String = "GRIBNOK") -> void:
	battle = battle_node
	_enemy_max_hp = enemy_max_hp if enemy_max_hp > 0 else max_hp      # nível 2: o Gribnok tem mais vida
	_enemy_name = enemy_name

	_build_background()
	_place_slots()
	_build_zone_panels()
	_build_hud(max_hp, player_hp, enemy_hp)
	_build_overlays()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND_PATH)
	bg.position = Vector2.ZERO
	bg.size = Vector2(BattleLayout.INTERNAL_SIZE)
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	battle.add_child(bg)


# Põe cada slot no lugar medido no fundo (BattleLayout.SLOT_X); a cena só guarda os nós.
func _place_slots() -> void:
	for zone_name in BattleLayout.SLOT_X:
		var zone := battle.get_node(zone_name)
		for i in zone.get_child_count():
			zone.get_child(i).position = BattleLayout.slot_center(zone_name, i)


func _build_zone_panels() -> void:
	_add_zone_panel("EnemyAttackZone", "ATAQUE", Palette.ATK_TEXT, "attack")
	_add_zone_panel("EnemyDefenseZone", "DEFESA", Palette.DEF_TEXT, "defense")
	_player_attack_panel = _add_zone_panel("PlayerAtackZone", "ATAQUE", Palette.ATK_TEXT, "attack")
	_player_defense_panel = _add_zone_panel("PlayerDefenseZone", "DEFESA", Palette.DEF_TEXT, "defense")


func _add_zone_panel(zone_name: String, title: String, text_color: Color, icon_kind: String) -> ZonePanel:
	var zone := battle.get_node(zone_name)
	var panel := ZonePanel.new()
	panel.z_index = -5  # atrás dos slots (z 0) e das cartas
	battle.add_child(panel)
	panel.build(zone, title, text_color, icon_kind, BattleLayout.ZONE_BAR[zone_name])
	_zones[zone] = panel
	return panel


func _build_hud(max_hp: int, player_hp: int, enemy_hp: int) -> void:
	var hud := CanvasLayer.new()
	hud_layer = hud
	hud.layer = 5
	hud.scale = Vector2(BattleLayout.SCALE, BattleLayout.SCALE)
	battle.add_child(hud)

	_max_hp = max_hp
	enemy_portrait = Portrait.new()
	enemy_portrait.position = BattleLayout.ENEMY_PORTRAIT.position
	enemy_portrait.setup("enemy", _enemy_name)
	hud.add_child(enemy_portrait)
	enemy_bar = HPBar.new()
	enemy_bar.position = BattleLayout.ENEMY_HP_BAR.position
	hud.add_child(enemy_bar)
	enemy_bar.setup(_enemy_max_hp, enemy_hp, Palette.HP_RED)
	enemy_portrait.set_face(GribnokFace.face_for_hp(float(enemy_hp) / float(_enemy_max_hp)))

	player_portrait = Portrait.new()
	player_portrait.position = BattleLayout.PLAYER_PORTRAIT.position
	player_portrait.setup("player", "CAYO")
	hud.add_child(player_portrait)
	player_bar = HPBar.new()
	player_bar.position = BattleLayout.PLAYER_HP_BAR.position
	hud.add_child(player_bar)
	player_bar.setup(max_hp, player_hp, Palette.PLAYER_HP)
	player_portrait.set_face(CayoFace.face_for_hp(float(player_hp) / float(max_hp)))

	# Botão de pausa "II" (canto superior esquerdo): o mesmo que apertar ESC
	var pause_button := TextButton.new()
	pause_button.show_mark = false
	pause_button.text = "II"
	pause_button.position = BattleLayout.PAUSE_BUTTON.position
	pause_button.size = BattleLayout.PAUSE_BUTTON.size
	pause_button.custom_minimum_size = BattleLayout.PAUSE_BUTTON.size
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(func() -> void: pause_menu.open_menu())
	hud.add_child(pause_button)

	# Pontos de sacrifício (embaixo da caveira da mesa) e o botão que gasta 3 deles num escudo
	var points_bg := ColorRect.new()                 # fundo escuro: o texto ficava apagado em cima da vela
	points_bg.color = Color(Palette.BORDER_DARK, 0.82)
	points_bg.position = BattleLayout.SACRIFICE_LABEL.position - Vector2(2, 1)
	points_bg.size = Vector2(BattleLayout.SACRIFICE_LABEL.size.x + 4, BattleLayout.SACRIFICE_LABEL.size.y + BattleLayout.SHIELD_BUTTON.size.y + BattleLayout.TRAP_BUTTON.size.y + 3)
	points_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(points_bg)
	_points_label = Label.new()
	_points_label.theme_type_variation = "LabelMath"
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.position = BattleLayout.SACRIFICE_LABEL.position
	_points_label.size = BattleLayout.SACRIFICE_LABEL.size
	_points_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_points_label.add_theme_color_override("font_color", Palette.TEXT_HOVER)
	hud.add_child(_points_label)
	_shield_button = TextButton.new()
	_shield_button.show_mark = false
	_shield_button.position = BattleLayout.SHIELD_BUTTON.position
	_shield_button.size = BattleLayout.SHIELD_BUTTON.size
	_shield_button.add_theme_font_size_override("font_size", 10)
	_shield_button.pressed.connect(func() -> void: battle.buy_shield())
	hud.add_child(_shield_button)
	_trap_button = TextButton.new()
	_trap_button.show_mark = false
	_trap_button.position = BattleLayout.TRAP_BUTTON.position
	_trap_button.size = BattleLayout.TRAP_BUTTON.size
	_trap_button.add_theme_font_size_override("font_size", 10)
	_trap_button.pressed.connect(func() -> void: battle.buy_trap())
	hud.add_child(_trap_button)
	set_sacrifice_points(0, 10, 3, 4, false)

	# Botão fixo "?" (feedback da professora: instruções acessíveis a qualquer momento)
	var help_button := TextButton.new()
	help_button.show_mark = false
	help_button.text = "?"
	help_button.position = BattleLayout.HELP_BUTTON.position
	help_button.size = BattleLayout.HELP_BUTTON.size
	help_button.custom_minimum_size = BattleLayout.HELP_BUTTON.size
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.pressed.connect(func() -> void: how_to_play.open_panel())
	hud.add_child(help_button)


# CanvasLayer dentro da batalha (as camadas definem quem fica por cima de quem).
func _overlay_layer(layer_index: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	layer.scale = Vector2(BattleLayout.SCALE, BattleLayout.SCALE)      # a batalha roda em resolução cheia
	battle.add_child(layer)
	return layer


func _build_overlays() -> void:
	var log_layer := _overlay_layer(6)
	log_panel = PlayLogPanel.new()
	log_layer.add_child(log_panel)

	# Tutorial (camada 8) e "Como jogar" (camada 9) ficam acima do relatório
	var tutorial_layer := _overlay_layer(8)
	var overlay := TutorialOverlay.new()
	tutorial_layer.add_child(overlay)
	tutorial = BattleTutorial.new()
	add_child(tutorial)
	tutorial.setup(battle, self, overlay)

	var howto_layer := _overlay_layer(9)
	how_to_play = HowToPlayPanel.new()
	howto_layer.add_child(how_to_play)
	# Enquanto "Como jogar" está aberto, o Battle ignora cliques no mundo (cartas, baralho)
	how_to_play.opened.connect(func() -> void: battle.ui_blocking = true)
	how_to_play.closed.connect(func() -> void: battle.ui_blocking = false)

	var result_layer := _overlay_layer(10)
	result_panel = ResultPanel.new()
	result_layer.add_child(result_panel)
	# A batalha não sabe pra onde ir: só avisa o GameManager o que o jogador escolheu
	result_panel.action_chosen.connect(func(action: String) -> void: GameManager.scene_finished(GameManager.current_scene_id, action))

	# Pausa (camada 12): acima de TUDO, inclusive do resultado
	var pause_layer := _overlay_layer(12)
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu = PauseMenu.new()
	pause_layer.add_child(pause_menu)
	pause_menu.setup(battle)


# Fixa (ou solta, com "") a expressão do Gribnok, por cima da que vem da vida dele.
func lock_enemy_face(expression: String) -> void:
	_enemy_face_lock = expression
	enemy_portrait.set_face(expression if expression != "" else GribnokFace.face_for_hp(float(battle.enemy_hp) / float(_enemy_max_hp)))


# Atualiza o contador de pontos de sacrifício e o botão do escudo (apagado se faltam pontos).
func set_sacrifice_points(points: int, max_points: int, shield_cost: int, trap_cost: int, trap_armed: bool) -> void:
	_points_label.text = "pontos %d/%d" % [points, max_points]
	_shield_button.text = "escudo (%d)" % shield_cost
	_shield_button.disabled = points < shield_cost
	_trap_button.text = "ARMADA!" if trap_armed else "armadilha (%d)" % trap_cost
	_trap_button.disabled = trap_armed or points < trap_cost
	if trap_armed:
		_trap_button.add_theme_color_override("font_disabled_color", Palette.NEGATIVE_WARNING)
	else:
		_trap_button.remove_theme_color_override("font_disabled_color")


func set_hp(player_hp: int, enemy_hp: int) -> void:
	player_bar.set_hp(player_hp)
	enemy_bar.set_hp(enemy_hp)
	enemy_portrait.set_face(_enemy_face_lock if _enemy_face_lock != "" else GribnokFace.face_for_hp(float(enemy_hp) / float(_enemy_max_hp)))
	# o Cayo muda com a vida dele; se o Gribnok caiu, ele vence e fica feliz
	player_portrait.set_face("feliz" if enemy_hp <= 0 else CayoFace.face_for_hp(float(player_hp) / float(_max_hp)))


# Espera a barra de HP terminar de esvaziar antes de mostrar o painel.
func show_result(kind: String, extra: String = "") -> void:
	await battle.wait(1.0)
	result_panel.show_result(kind, extra)


# Aviso no alto da tela (frases do inimigo, carta desbloqueada...). Grande, em fonte legível (VT323),
# com caixa escura e borda dourada; quebra em 2 linhas se for longo e fica o tempo de LER (cresce
# com o tamanho do texto). Se já tem um aviso na tela, o novo entra logo abaixo dele.
const TOAST_FONT: Font = preload("res://UI/Fonts/VT323-Regular.ttf")
const TOAST_SIZE := 15            # pixels internos (a camada é ×3: 45 px na tela cheia)
const TOAST_MAX_W := 380.0
var _toast_count: int = 0


func show_toast(text: String) -> void:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(holder)
	var text_w: float = TOAST_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TOAST_SIZE).x
	var inner_w: float = minf(text_w + 4.0, TOAST_MAX_W)
	var lines: int = maxi(ceili(text_w / (TOAST_MAX_W - 8.0)), 1)
	var line_h: float = TOAST_FONT.get_height(TOAST_SIZE)
	var box := Vector2(inner_w + 20.0, lines * line_h + 12.0)

	var edge := ColorRect.new()
	edge.color = Palette.GOLD
	edge.size = box
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(edge)
	var fill := ColorRect.new()
	fill.color = Color(0.04, 0.035, 0.05, 0.96)
	fill.position = Vector2(1, 1)
	fill.size = box - Vector2(2, 2)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(fill)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TOAST_FONT)
	label.add_theme_font_size_override("font_size", TOAST_SIZE)
	label.add_theme_color_override("font_color", Color("#fff1c9"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(10, 6)
	label.size = Vector2(inner_w, lines * line_h)
	holder.add_child(label)

	holder.position = Vector2(roundf((BattleLayout.INTERNAL_SIZE.x - box.x) / 2.0), 6.0 + _toast_count * (box.y + 4.0))
	_toast_count += 1
	var tween := create_tween()
	tween.tween_interval(3.2 + text.length() * 0.045)      # tempo de ler
	tween.tween_property(holder, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		_toast_count = maxi(_toast_count - 1, 0)
		holder.queue_free())


func start_tutorial_if_needed() -> void:
	tutorial.start_if_needed()


# Área da tela que o tutorial destaca em cada passo (chaves de TutorialBattleText),
# em pixels internos (640x360).
func target_rect(key: String) -> Rect2:
	match key:
		"player_hp", "hp_bars":
			return BattleLayout.PLAYER_PORTRAIT.merge(BattleLayout.PLAYER_HP_BAR).grow(2)
		"hand_area":
			return Rect2(150, 290, 340, 68)
		"deck":
			return Rect2(BattleLayout.DECK_CENTER - BattleLayout.DECK_SIZE / 2.0, BattleLayout.DECK_SIZE).grow(4)
		"player_attack":
			return Rect2(_player_attack_panel.position, _player_attack_panel.size).grow(2)
		"player_defense":
			return Rect2(_player_defense_panel.position, _player_defense_panel.size).grow(2)
		"player_field":
			return Rect2(_player_attack_panel.position, _player_attack_panel.size).merge(
					Rect2(_player_defense_panel.position, _player_defense_panel.size)).grow(2)
		"confirm":
			return BattleLayout.END_TURN_RECT.grow(3)
	return Rect2()


# Adiciona uma jogada ao relatório (não bloqueia o turno).
func add_log(data: Dictionary) -> void:
	log_panel.add_entry(data)


# Conta ao vivo de cada zona ("+3 ×2 -5 = 1"): atualiza quando uma carta entra ou sai de um
# slot (a zona muda por drag, jogada do Gribnok, colapso e dano; ler todo frame evita ter que
# avisar a UI em cada um desses pontos).
func _process(_delta: float) -> void:
	if battle == null:
		return
	for zone in _zones:
		var panel: ZonePanel = _zones[zone]
		var steps := BattleMath.calculate_steps(battle.get_zone_cards_data(zone))
		var text := PlayLogPanel.equation_text(steps)
		# Se a conta não cabe na barra, mostra só o total ("= 12") em vez de invadir o título
		var label := panel.equation_label
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > panel.equation_max_width:
			text = "= %d" % (steps.back()["after"] if not steps.is_empty() else 0)
		if label.text != text:
			label.text = text
		# ataque com total NEGATIVO tira HP de quem atacou: a conta fica vermelha pra avisar
		var total: int = steps.back()["after"] if not steps.is_empty() else 0
		var is_attack := String(zone.name).ends_with("AttackZone") or String(zone.name).ends_with("AtackZone")
		label.add_theme_color_override("font_color", Palette.NEGATIVE_WARNING if (is_attack and total < 0) else panel.equation_color)
