# ZonePanel.gd
# Painel invisível de uma zona de batalha (ATAQUE ou DEFESA, do jogador ou do inimigo). O fundo
# (Backgrounds/battle_bg.png) já traz as barras de título e os slots desenhados; este nó só põe
# POR CIMA da barra o ícone, o nome da zona e, à direita, a CONTA AO VIVO ("+3 ×2 -5 = 1").
# O retângulo do painel cobre a barra e os slots (usado pra destacar a zona no tutorial).

class_name ZonePanel
extends Panel

const PAD := 3.0
const ICON_SPACE := 14.0     # ícone + folga antes do título

var equation_label: Label = null
var equation_max_width: float = 0.0   # largura que a conta pode ocupar sem invadir o título


# bar: retângulo da barra desenhada no fundo (pixels internos); text_color: cor do título.
func build(zone: Node, title: String, text_color: Color, icon_kind: String, bar: Rect2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var slot_size := BattleLayout.SLOT_SIZE
	var rect := bar
	for slot in zone.get_children():
		rect = rect.merge(Rect2(slot.global_position - slot_size / 2.0, slot_size))
	var panel_rect := rect.grow(PAD)
	position = panel_rect.position
	size = panel_rect.size

	var bar_local := Rect2(bar.position - position, bar.size)

	var icon := ZoneIcon.new()
	icon.setup(icon_kind)
	icon.position = Vector2(bar_local.position.x + 4.0, bar_local.position.y + floorf((bar_local.size.y - icon.size.y) / 2.0))
	add_child(icon)

	var label := Label.new()
	label.text = title
	label.position = Vector2(bar_local.position.x + ICON_SPACE + 4.0, bar_local.position.y)
	label.size = Vector2(200.0, bar_local.size.y)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", text_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	# a conta começa depois do título REAL (medido), pra nunca invadi-lo
	var title_w := label.get_theme_font("font").get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	label.size.x = title_w + 2.0
	var eq_x := label.position.x + title_w + 6.0
	equation_max_width = bar_local.end.x - 4.0 - eq_x

	equation_label = Label.new()
	equation_label.theme_type_variation = "LabelMath"
	equation_label.position = Vector2(eq_x, bar_local.position.y)
	equation_label.size = Vector2(equation_max_width, bar_local.size.y)
	equation_label.clip_text = true
	equation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equation_label.add_theme_color_override("font_color", text_color.lightened(0.25))
	equation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(equation_label)
