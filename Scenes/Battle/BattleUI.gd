# BattleUI.gd
# Monta por código toda a apresentação da batalha: fundo placeholder,
# painéis das 4 zonas, barras de HP no topo, escudos de defesa e o painel
# de vitória/derrota. O Battle.gd só chama set_hp() e show_result().
# Não mexe em lógica de turno.

class_name BattleUI
extends Node

# Tamanho visual de um CardSlot (PNG * escala do CardSlot.tscn)
const SLOT_SIZE := Vector2(156, 242)

# Troque pra false pra voltar a mostrar o TextureRect de fundo original.
const USE_CODE_BACKGROUND := true

var battle: Node2D
var enemy_bar: HPBar
var player_bar: HPBar
var result_panel: ResultPanel
var log_panel: PlayLogPanel

var _enemy_defense_zone: Node
var _player_defense_zone: Node
var _enemy_shield: ShieldBadge
var _player_shield: ShieldBadge
var _player_attack_zone: Node
var _player_attack_panel: ZonePanel
var _player_defense_panel: ZonePanel


func setup(battle_node: Node2D, max_hp: int, player_hp: int, enemy_hp: int) -> void:
	battle = battle_node

	_build_background()
	_build_zone_panels()
	_build_hud(max_hp, player_hp, enemy_hp)


func _build_background() -> void:
	if not USE_CODE_BACKGROUND:
		return
	var old_bg := battle.get_node_or_null("TextureRect")
	if old_bg:
		old_bg.visible = false
	var bg := PixelBackground.new()
	bg.z_index = -10
	battle.add_child(bg)


func _build_zone_panels() -> void:
	_enemy_defense_zone = battle.get_node("EnemyDefenseZone")
	_player_defense_zone = battle.get_node("PlayerDefenseZone")

	_player_attack_zone = battle.get_node("PlayerAtackZone")

	_add_zone_panel(battle.get_node("EnemyAttackZone"), "ATAQUE", Palette.ATK_ORANGE, false)
	_enemy_shield = _add_zone_panel(_enemy_defense_zone, "DEFESA", Palette.DEF_BLUE, true).shield
	_player_attack_panel = _add_zone_panel(_player_attack_zone, "ATAQUE", Palette.ATK_ORANGE, false)
	_player_defense_panel = _add_zone_panel(_player_defense_zone, "DEFESA", Palette.DEF_BLUE, true)
	_player_shield = _player_defense_panel.shield


func _add_zone_panel(zone: Node, title: String, accent: Color, with_shield: bool) -> ZonePanel:
	var panel := ZonePanel.new()
	panel.z_index = -5  # atrás dos slots (z 0) e das cartas
	battle.add_child(panel)
	panel.build(zone, SLOT_SIZE, title, accent, with_shield)
	return panel


func _build_hud(max_hp: int, player_hp: int, enemy_hp: int) -> void:
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)

	enemy_bar = HPBar.new()
	enemy_bar.position = Vector2(30, 16)
	hud.add_child(enemy_bar)
	enemy_bar.setup("GRIBNOK", max_hp, enemy_hp, false)

	player_bar = HPBar.new()
	player_bar.position = Vector2(1920 - 30 - 560, 16)
	hud.add_child(player_bar)
	player_bar.setup("VOCÊ", max_hp, player_hp, true)

	var log_layer := CanvasLayer.new()
	log_layer.layer = 6
	add_child(log_layer)
	log_panel = PlayLogPanel.new()
	log_layer.add_child(log_panel)

	var result_layer := CanvasLayer.new()
	result_layer.layer = 10
	add_child(result_layer)
	result_panel = ResultPanel.new()
	result_layer.add_child(result_panel)
	result_panel.play_again.connect(func() -> void: get_tree().reload_current_scene())


func set_hp(player_hp: int, enemy_hp: int) -> void:
	player_bar.set_hp(player_hp)
	enemy_bar.set_hp(enemy_hp)


# Espera a barra de HP terminar de esvaziar antes de mostrar o painel.
func show_result(kind: String) -> void:
	await get_tree().create_timer(1.0).timeout
	result_panel.show_result(kind)


# Adiciona uma jogada ao relatório do canto (não bloqueia o turno).
func add_log(data: Dictionary) -> void:
	log_panel.add_entry(data)


# Escudo = total da zona de defesa, sempre em dia (a zona muda por drag,
# jogada do Gribnok, colapso e dano; ler a cada frame evita ter que
# avisar a UI em cada um desses pontos).
func _process(_delta: float) -> void:
	if battle == null:
		return
	_update_shield(_enemy_defense_zone, _enemy_shield)
	_update_shield(_player_defense_zone, _player_shield)
	# Preview ao vivo da conta do jogador: atualiza quando uma carta entra ou sai de um slot
	_update_equation(_player_attack_zone, _player_attack_panel)
	_update_equation(_player_defense_zone, _player_defense_panel)


func _update_shield(zone: Node, shield: ShieldBadge) -> void:
	if shield == null:
		return
	var total := BattleMath.calculate_total(battle.get_zone_cards_data(zone))
	shield.set_value(maxi(total, 0))


func _update_equation(zone: Node, panel: ZonePanel) -> void:
	var steps := BattleMath.calculate_steps(battle.get_zone_cards_data(zone))
	var text := PlayLogPanel.equation_text(steps)
	if panel.equation_label.text != text:
		panel.equation_label.text = text
