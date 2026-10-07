# PlayLogPanel.gd
# Relatório das jogadas, no estilo do log do Hearthstone:
#   - Fechado: caixinha no canto esquerdo com as últimas jogadas resumidas
#     (3 linhas cada). Não pausa nem bloqueia nada.
#   - Clicando nela: abre o relatório completo, com a conta passo a passo
#     ("0 -> +3 = 3 -> ×2 = 6") e o impacto de cada ataque. FECHAR volta.
#
# O Battle.gd só chama add_entry() com os números; o texto é montado aqui.

class_name PlayLogPanel
extends Control

# A Jersey10 não tem as setas "→" e "⇒". Quando trocar a fonte, mude só aqui.
const ARROW := "->"
const RESULT_ARROW := "=>"

const SUMMARY_COUNT := 3
const SMALL_POS := Vector2(8, 122)       # coluna esquerda livre, acima do deck
const SMALL_SIZE := Vector2(252, 350)
# O painel grande para antes da mão do jogador (y ~790), pra não ficar por cima de cartas clicáveis.
const BIG_POS := Vector2(260, 140)
const BIG_SIZE := Vector2(1400, 645)

var _entries: Array[Dictionary] = []

var _small: PixelPanel
var _summary_box: VBoxContainer
var _hint: Label
var _big: PixelPanel
var _detail_box: VBoxContainer


# Texto compacto "+3 -> ×2 -> -1 = 5", usado no preview ao vivo das zonas.
static func equation_text(steps: Array) -> String:
	if steps.is_empty():
		return "= 0"
	var text := ""
	for i in steps.size():
		if i > 0:
			text += " %s " % ARROW
		text += steps[i]["label"]
	return "%s = %d" % [text, steps.back()["after"]]


# Conta completa no formato "0 -> +3 = 3 -> ×2 = 6".
static func steps_text(steps: Array) -> String:
	var text := "0"
	for step in steps:
		text += " %s %s = %d" % [ARROW, step["label"], step["after"]]
	return text


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_small()
	_build_big()
	_refresh()


# ---------------------------------------------------------------------------
# Painel pequeno (resumo)
# ---------------------------------------------------------------------------
func _build_small() -> void:
	_small = PixelPanel.new()
	_small.position = SMALL_POS
	_small.size = SMALL_SIZE
	add_child(_small)
	_small.configure(Palette.PANEL_FILL, Palette.BORDER_DARK, Palette.PANEL_LIGHT)

	var header := Label.new()
	header.text = "RELATÓRIO"
	header.position = Vector2(14, 8)
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Palette.GOLD)
	_small.add_child(header)

	_hint = Label.new()
	_hint.text = "[+]"
	_hint.position = Vector2(SMALL_SIZE.x - 14 - 40, 10)
	_hint.size = Vector2(40, 28)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 24)
	_small.add_child(_hint)

	_summary_box = VBoxContainer.new()
	_summary_box.position = Vector2(14, 46)
	_summary_box.size = Vector2(SMALL_SIZE.x - 28, SMALL_SIZE.y - 56)
	_summary_box.add_theme_constant_override("separation", 10)
	_small.add_child(_summary_box)

	# Botão transparente por cima de tudo: clicar em qualquer ponto abre o completo.
	var click := Button.new()
	click.flat = true
	click.focus_mode = Control.FOCUS_NONE
	click.position = Vector2.ZERO
	click.size = SMALL_SIZE
	click.pressed.connect(_open_big)
	click.mouse_entered.connect(func() -> void: _hint.add_theme_color_override("font_color", Palette.GOLD))
	click.mouse_exited.connect(func() -> void: _hint.remove_theme_color_override("font_color"))
	_small.add_child(click)


func _make_summary(e: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var who_color: Color = Palette.GOLD if e["who"] == "VOCÊ" else Palette.HP_RED.lightened(0.3)
	_add_line(box, "R%d  %s" % [e["round"], e["who"]], who_color)
	_add_line(box, "ATQ %d  vs  DEF %d" % [e["attack_total"], e["defense_total"]], Palette.TEXT_LIGHT)

	var hp_changed: bool = e["hp_after"] != e["hp_before"]
	var hp_color: Color = Palette.HP_RED.lightened(0.3) if hp_changed else Palette.TEXT_LIGHT
	_add_line(box, "HP %s: %d %s %d" % [e["target"], e["hp_before"], ARROW, e["hp_after"]], hp_color)
	return box


func _add_line(parent: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


# ---------------------------------------------------------------------------
# Painel grande (completo)
# ---------------------------------------------------------------------------
func _build_big() -> void:
	_big = PixelPanel.new()
	_big.position = BIG_POS
	_big.size = BIG_SIZE
	_big.visible = false
	add_child(_big)
	_big.configure(Palette.PANEL_FILL, Palette.BORDER_DARK, Palette.GOLD, 6, 3)

	var title := Label.new()
	title.text = "RELATÓRIO DA BATALHA"
	title.position = Vector2(24, 14)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Palette.GOLD)
	_big.add_child(title)

	var close := Button.new()
	close.text = "FECHAR"
	close.position = Vector2(BIG_SIZE.x - 24 - 180, 12)
	close.size = Vector2(180, 44)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(_close_big)
	_big.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 70)
	scroll.size = Vector2(BIG_SIZE.x - 48, BIG_SIZE.y - 70 - 24)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_big.add_child(scroll)

	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 18)
	scroll.add_child(_detail_box)


func _make_detail(e: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)

	var who_color: Color = Palette.GOLD if e["who"] == "VOCÊ" else Palette.HP_RED.lightened(0.3)
	var heading := Label.new()
	heading.text = "RODADA %d  -  TURNO %s" % [e["round"], "DO JOGADOR" if e["who"] == "VOCÊ" else "DO GRIBNOK"]
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", who_color)
	box.add_child(heading)

	_add_detail_row(box, e["attack_tag"], Palette.ATK_ORANGE.lightened(0.25),
			"%s   %s Ataque total: %d" % [steps_text(e["attack_steps"]), RESULT_ARROW, e["attack_total"]])
	_add_detail_row(box, e["defense_tag"], Palette.DEF_BLUE.lightened(0.3),
			"%s   %s Defesa total: %d" % [steps_text(e["defense_steps"]), RESULT_ARROW, e["defense_total"]])
	_add_detail_row(box, "IMPACTO", Palette.GOLD, _impact_text(e))
	return box


func _add_detail_row(parent: Control, tag: String, tag_color: Color, text: String) -> void:
	var row := RichTextLabel.new()
	row.bbcode_enabled = true
	row.fit_content = true
	row.scroll_active = false
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_font_size_override("normal_font_size", 30)
	row.add_theme_color_override("default_color", Palette.TEXT_LIGHT)
	row.text = "[color=#%s]%s[/color]   %s" % [tag_color.to_html(false), tag, text]
	parent.add_child(row)


# "Defesa do inimigo: 3 -> absorve 3 -> sobra 2 -> remove 2 das cartas de ataque -> HP: 30 -> 30"
func _impact_text(e: Dictionary) -> String:
	var parts: Array[String] = [
		"%s: %d" % [e["defense_name"], e["defense_total"]],
		"absorve %d" % e["absorbed"],
		"sobra %d" % e["spillover"],
	]
	if e["removed"] > 0:
		parts.append("remove %d das cartas de ataque" % e["removed"])
	parts.append("HP: %d %s %d" % [e["hp_before"], ARROW, e["hp_after"]])
	return (" %s " % ARROW).join(PackedStringArray(parts))


func _open_big() -> void:
	_big.visible = true


func _close_big() -> void:
	_big.visible = false


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------
# e: round, who ("VOCÊ"/"GRIBNOK"), target, attack_tag, defense_tag, defense_name,
#    attack_steps, defense_steps, attack_total, defense_total, absorbed,
#    spillover, removed, hp_before, hp_after
func add_entry(e: Dictionary) -> void:
	_entries.append(e)
	_refresh()
	# "pulinho" curto no painel pra chamar atenção pra jogada nova
	_small.pivot_offset = SMALL_SIZE / 2.0
	var tween := create_tween()
	tween.tween_property(_small, "scale", Vector2(1.04, 1.04), 0.05)
	tween.tween_property(_small, "scale", Vector2.ONE, 0.05)


func _refresh() -> void:
	for child in _summary_box.get_children():
		child.queue_free()
	for child in _detail_box.get_children():
		child.queue_free()

	if _entries.is_empty():
		_add_line(_summary_box, "Nenhuma jogada", Palette.PANEL_LIGHT.lightened(0.4))
		_add_line(_summary_box, "ainda.", Palette.PANEL_LIGHT.lightened(0.4))
		return

	# Mais recente em cima, tanto no resumo quanto no completo
	for i in range(_entries.size() - 1, -1, -1):
		_detail_box.add_child(_make_detail(_entries[i]))
		if _entries.size() - i <= SUMMARY_COUNT:
			_summary_box.add_child(_make_summary(_entries[i]))
