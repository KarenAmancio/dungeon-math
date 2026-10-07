# ZonePanel.gd
# Painel de uma zona de batalha (ATAQUE ou DEFESA, do jogador ou do inimigo) em pixels
# internos: barra de título colorida com ícone, nome da zona e, à direita, a CONTA AO VIVO
# ("+3 ×2 -5 = 1"). Ele se ajusta sozinho às posições dos CardSlots da zona (cada slot se
# desenha sozinho), então mover os slots na cena move o painel junto.

class_name ZonePanel
extends PixelPanel

const PAD := 6.0
const BAR_INSET := 3.0
const BAR_H := 14.0
const TOP_SPACE := 22.0      # barra (3+14) + folga até os slots
const BOTTOM_SPACE := 8.0
const ICON_SPACE := 14.0     # ícone + folga antes do título
const TITLE_W := 64.0        # largura reservada pro título; a conta ocupa o resto

var equation_label: Label = null


func build(zone: Node, title: String, accent: Color, icon_kind: String) -> void:
	var slot_size := BattleLayout.SLOT_SIZE
	var rect := Rect2()
	var first := true
	for slot in zone.get_children():
		var r := Rect2(slot.global_position - slot_size / 2.0, slot_size)
		rect = r if first else rect.merge(r)
		first = false
	var panel_rect := rect.grow_individual(PAD, TOP_SPACE, PAD, BOTTOM_SPACE)
	position = panel_rect.position
	size = panel_rect.size

	configure(Palette.dark_of(accent), Palette.BORDER_DARK, accent.darkened(0.35), 1, 1)

	var bar := Panel.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", Palette.box(accent.darkened(0.55), Palette.BORDER_DARK, 1))
	bar.position = Vector2(BAR_INSET, BAR_INSET)
	bar.size = Vector2(size.x - BAR_INSET * 2.0, BAR_H)
	add_child(bar)

	var icon := ZoneIcon.new()
	icon.setup(icon_kind)
	icon.position = Vector2(3, (BAR_H - icon.size.y) / 2.0)
	bar.add_child(icon)

	var label := Label.new()
	label.text = title
	label.position = Vector2(ICON_SPACE + 1, 0)
	label.size = Vector2(TITLE_W, BAR_H)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)

	equation_label = Label.new()
	var eq_x := ICON_SPACE + 1.0 + TITLE_W
	equation_label.position = Vector2(eq_x, 0)
	equation_label.size = Vector2(bar.size.x - eq_x - 3.0, BAR_H)
	equation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equation_label.add_theme_color_override("font_color", Palette.GOLD)
	equation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(equation_label)
