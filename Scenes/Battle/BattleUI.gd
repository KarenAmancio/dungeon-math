# BattleUI.gd
# Monta por código toda a apresentação da batalha, em pixels internos (640x360, ver
# BattleLayout): fundo, painéis das 4 zonas, retratos + HP, velas e o botão "?".
# Os overlays que ainda não foram refeitos (tutorial, relatório, como jogar, resultado)
# ficam em tela cheia, FORA do SubViewport, no BattleScreen (a Etapa G os traz pra dentro).
# O Battle.gd só chama set_hp(), show_result() e add_log(). Não mexe em lógica de turno.

class_name BattleUI
extends Node

const BACKGROUND_PATH := "res://Backgrounds/battle_bg.png"
# Tema transitório ×3 dos overlays em tela cheia (some na Etapa G)
const SCREEN_THEME := preload("res://UI/Themes/pixel_theme_x3.tres")

var battle: Node2D
var enemy_bar: HPBar
var player_bar: HPBar
var result_panel: ResultPanel
var log_panel: PlayLogPanel
var how_to_play: HowToPlayPanel
var tutorial: BattleTutorial

var _zones: Dictionary = {}      # nó da zona -> ZonePanel
var _player_attack_panel: ZonePanel
var _player_defense_panel: ZonePanel


func setup(battle_node: Node2D, max_hp: int, player_hp: int, enemy_hp: int) -> void:
	battle = battle_node

	_build_background()
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


func _build_zone_panels() -> void:
	_add_zone_panel("EnemyAttackZone", "ATAQUE INIMIGO", Palette.ATK_RED, "attack")
	_add_zone_panel("EnemyDefenseZone", "DEFESA INIMIGA", Palette.DEF_BLUE, "defense")
	_player_attack_panel = _add_zone_panel("PlayerAtackZone", "ATAQUE JOGADOR", Palette.ATK_RED, "attack")
	_player_defense_panel = _add_zone_panel("PlayerDefenseZone", "DEFESA JOGADOR", Palette.DEF_BLUE, "defense")


func _add_zone_panel(zone_name: String, title: String, accent: Color, icon_kind: String) -> ZonePanel:
	var zone := battle.get_node(zone_name)
	var panel := ZonePanel.new()
	panel.z_index = -5  # atrás dos slots (z 0) e das cartas
	battle.add_child(panel)
	panel.build(zone, title, accent, icon_kind)
	_zones[zone] = panel
	return panel


func _build_hud(max_hp: int, player_hp: int, enemy_hp: int) -> void:
	var hud := CanvasLayer.new()
	hud.layer = 5
	battle.add_child(hud)

	var candles := Candles.new()
	candles.position = BattleLayout.CANDLES_POS
	hud.add_child(candles)

	var enemy_portrait := Portrait.new()
	enemy_portrait.position = BattleLayout.ENEMY_PORTRAIT.position
	enemy_portrait.setup("enemy", "GRIBNOK")
	hud.add_child(enemy_portrait)
	enemy_bar = HPBar.new()
	enemy_bar.position = BattleLayout.ENEMY_HP_BAR.position
	hud.add_child(enemy_bar)
	enemy_bar.setup(max_hp, enemy_hp, Palette.HP_RED)

	var player_portrait := Portrait.new()
	player_portrait.position = BattleLayout.PLAYER_PORTRAIT.position
	player_portrait.setup("player", "VOCÊ")
	hud.add_child(player_portrait)
	player_bar = HPBar.new()
	player_bar.position = BattleLayout.PLAYER_HP_BAR.position
	hud.add_child(player_bar)
	player_bar.setup(max_hp, player_hp, Palette.PLAYER_HP)

	# Botão fixo "?" (feedback da professora: instruções acessíveis a qualquer momento)
	var help_button := Button.new()
	help_button.text = "?"
	help_button.position = BattleLayout.HELP_BUTTON.position
	help_button.size = BattleLayout.HELP_BUTTON.size
	help_button.custom_minimum_size = BattleLayout.HELP_BUTTON.size
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.pressed.connect(func() -> void: how_to_play.open_panel())
	hud.add_child(help_button)


# CanvasLayer de tela cheia fora do SubViewport (ou local, se a batalha rodar sozinha).
func _overlay_layer(layer_index: int) -> CanvasLayer:
	if battle.screen != null and battle.screen.has_method("add_overlay_layer"):
		return battle.screen.add_overlay_layer(layer_index)
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	add_child(layer)
	return layer


func _build_overlays() -> void:
	var log_layer := _overlay_layer(6)
	log_panel = PlayLogPanel.new()
	log_panel.theme = SCREEN_THEME
	log_layer.add_child(log_panel)

	# Tutorial (camada 8) e "Como jogar" (camada 9) ficam acima do relatório
	var tutorial_layer := _overlay_layer(8)
	var overlay := TutorialOverlay.new()
	overlay.theme = SCREEN_THEME
	tutorial_layer.add_child(overlay)
	tutorial = BattleTutorial.new()
	add_child(tutorial)
	tutorial.setup(battle, self, overlay)

	var howto_layer := _overlay_layer(9)
	how_to_play = HowToPlayPanel.new()
	how_to_play.theme = SCREEN_THEME
	howto_layer.add_child(how_to_play)
	# Enquanto "Como jogar" está aberto, o Battle ignora cliques no mundo (cartas, baralho)
	how_to_play.opened.connect(func() -> void: battle.ui_blocking = true)
	how_to_play.closed.connect(func() -> void: battle.ui_blocking = false)

	var result_layer := _overlay_layer(10)
	result_panel = ResultPanel.new()
	result_panel.theme = SCREEN_THEME
	result_layer.add_child(result_panel)
	result_panel.play_again.connect(func() -> void: get_tree().reload_current_scene())


func set_hp(player_hp: int, enemy_hp: int) -> void:
	player_bar.set_hp(player_hp)
	enemy_bar.set_hp(enemy_hp)


# Espera a barra de HP terminar de esvaziar antes de mostrar o painel.
func show_result(kind: String) -> void:
	await get_tree().create_timer(1.0).timeout
	result_panel.show_result(kind)


func start_tutorial_if_needed() -> void:
	tutorial.start_if_needed()


# Área da tela que o tutorial destaca em cada passo (chaves de TutorialBattleText),
# em coordenadas de TELA CHEIA (os overlays ainda estão fora do SubViewport).
func target_rect(key: String) -> Rect2:
	match key:
		"player_hp", "hp_bars":
			return BattleLayout.to_screen(BattleLayout.PLAYER_PORTRAIT.merge(BattleLayout.PLAYER_HP_BAR).grow(2))
		"hand_area":
			return BattleLayout.to_screen(Rect2(150, 290, 340, 68))
		"deck":
			return BattleLayout.to_screen(Rect2(BattleLayout.DECK_CENTER - BattleLayout.DECK_SIZE / 2.0, BattleLayout.DECK_SIZE).grow(4))
		"player_attack":
			return BattleLayout.to_screen(Rect2(_player_attack_panel.position, _player_attack_panel.size).grow(2))
		"player_defense":
			return BattleLayout.to_screen(Rect2(_player_defense_panel.position, _player_defense_panel.size).grow(2))
		"player_field":
			return BattleLayout.to_screen(
					Rect2(_player_attack_panel.position, _player_attack_panel.size).merge(
					Rect2(_player_defense_panel.position, _player_defense_panel.size)).grow(2))
		"confirm":
			return BattleLayout.to_screen(BattleLayout.END_TURN_RECT.grow(3))
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
