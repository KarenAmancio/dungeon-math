# ZonePanel.gd
# Painel de uma zona de batalha (ATAQUE ou DEFESA): título colorido no topo
# e uma moldura marcando cada slot. Ele se ajusta sozinho às posições dos
# CardSlots da zona, então mover os slots na cena move o painel junto.
# A zona de defesa ganha um ShieldBadge no canto do título.

class_name ZonePanel
extends PixelPanel

const PAD := 20.0
const TOP_SPACE := 46.0      # espaço do título acima dos slots
const BOTTOM_SPACE := 10.0
const BAR_H := 30.0

var shield: ShieldBadge = null
var equation_label: Label = null  # preview da conta, preenchido por quem usa o painel


func build(zone: Node, slot_size: Vector2, title: String, accent: Color, with_shield: bool) -> void:
	var rect := Rect2()
	var first := true
	for slot in zone.get_children():
		var r := Rect2(slot.global_position - slot_size / 2.0, slot_size)
		rect = r if first else rect.merge(r)
		first = false
	var panel_rect := rect.grow_individual(PAD, TOP_SPACE, PAD, BOTTOM_SPACE)
	position = panel_rect.position
	size = panel_rect.size

	configure(Palette.dark_of(accent), Palette.BORDER_DARK, accent)

	# Barra de título
	var bar := Panel.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", Palette.box(accent.darkened(0.25), Palette.BORDER_DARK, 3))
	bar.position = Vector2(8, 8)
	bar.size = Vector2(size.x - 16, BAR_H)
	add_child(bar)

	var label := Label.new()
	label.text = title
	label.position = Vector2(12, 0)
	label.size = Vector2(bar.size.x - 24, BAR_H)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)

	# Conta ao vivo ("+3 -> ×2 = 6"), alinhada à direita, antes do escudo
	var reserved := 114.0 if with_shield else 0.0
	equation_label = Label.new()
	equation_label.position = Vector2(120, 0)
	equation_label.size = Vector2(bar.size.x - 120 - 12 - reserved, BAR_H)
	equation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equation_label.add_theme_font_size_override("font_size", 28)
	equation_label.add_theme_color_override("font_color", Palette.GOLD)
	equation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(equation_label)

	if with_shield:
		shield = ShieldBadge.new()
		shield.position = Vector2(bar.size.x - shield.size.x - 3, (BAR_H - shield.size.y) / 2.0)
		bar.add_child(shield)

	# Moldura de cada slot (a arte do slot é desenhada por cima dela)
	for slot in zone.get_children():
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override("panel", Palette.box(Palette.BORDER_DARK.lightened(0.05), accent, 3))
		frame.position = slot.global_position - slot_size / 2.0 - position
		frame.size = slot_size
		add_child(frame)
