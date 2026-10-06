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

var _enemy_defense_zone: Node
var _player_defense_zone: Node
var _enemy_shield: ShieldBadge
var _player_shield: ShieldBadge


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

	_add_zone_panel(battle.get_node("EnemyAttackZone"), "ATAQUE", Palette.ATK_ORANGE, false)
	_enemy_shield = _add_zone_panel(_enemy_defense_zone, "DEFESA", Palette.DEF_BLUE, true)
	_add_zone_panel(battle.get_node("PlayerAtackZone"), "ATAQUE", Palette.ATK_ORANGE, false)
	_player_shield = _add_zone_panel(_player_defense_zone, "DEFESA", Palette.DEF_BLUE, true)


# Devolve o ShieldBadge do painel (ou null se a zona não tem escudo).
func _add_zone_panel(zone: Node, title: String, accent: Color, with_shield: bool) -> ShieldBadge:
	var panel := ZonePanel.new()
	panel.z_index = -5  # atrás dos slots (z 0) e das cartas
	battle.add_child(panel)
	panel.build(zone, SLOT_SIZE, title, accent, with_shield)
	return panel.shield


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


# Escudo = total da zona de defesa, sempre em dia (a zona muda por drag,
# jogada do Gribnok, colapso e dano; ler a cada frame evita ter que
# avisar a UI em cada um desses pontos).
func _process(_delta: float) -> void:
	if battle == null:
		return
	_update_shield(_enemy_defense_zone, _enemy_shield)
	_update_shield(_player_defense_zone, _player_shield)


func _update_shield(zone: Node, shield: ShieldBadge) -> void:
	if shield == null:
		return
	var total := BattleMath.calculate_total(battle.get_zone_cards_data(zone))
	shield.set_value(maxi(total, 0))
