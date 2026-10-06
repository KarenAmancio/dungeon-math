# ResultPanel.gd
# Painel de fim de batalha (vitória / derrota / empate) com botão
# "JOGAR DE NOVO". Escurece a tela e bloqueia cliques no que está atrás.

class_name ResultPanel
extends Control

signal play_again

const BOX_SIZE := Vector2(640, 340)

var _box: PixelPanel
var _title: Label
var _subtitle: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_DEEP, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_box = PixelPanel.new()
	_box.custom_minimum_size = BOX_SIZE
	center.add_child(_box)
	_box.configure(Palette.PANEL_FILL, Palette.BORDER_DARK, Palette.GOLD, 6, 3)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	_box.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 88)
	_title.add_theme_constant_override("outline_size", 8)
	column.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 30)
	column.add_child(_subtitle)

	var button := Button.new()
	button.text = "JOGAR DE NOVO"
	button.custom_minimum_size = Vector2(320, 64)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void: play_again.emit())
	column.add_child(button)


# kind: "win" | "lose" | "draw"
func show_result(kind: String) -> void:
	match kind:
		"win":
			_title.text = "VITÓRIA!"
			_title.add_theme_color_override("font_color", Palette.GOLD)
			_subtitle.text = "Você zerou o HP do Gribnok."
		"lose":
			_title.text = "DERROTA"
			_title.add_theme_color_override("font_color", Palette.HP_RED)
			_subtitle.text = "O Gribnok zerou o seu HP."
		_:
			_title.text = "EMPATE"
			_title.add_theme_color_override("font_color", Palette.TEXT_LIGHT)
			_subtitle.text = "Os dois chegaram a 0 de HP."

	visible = true
	# "pulinho" de entrada em 3 passos secos
	_box.pivot_offset = BOX_SIZE / 2.0
	_box.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(_box, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(_box, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(_box, "scale", Vector2.ONE, 0.05)
