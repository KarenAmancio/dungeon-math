# ResultPanel.gd
# Painel de fim de batalha (vitória / derrota / empate) numa RPGWindow, com o botão
# "JOGAR DE NOVO". Escurece a tela e bloqueia cliques no que está atrás. Pixels internos 640x360.
# O título usa a fonte dos números das cartas (Jersey10, grossa e bem legível).

class_name ResultPanel
extends Control

signal play_again

const SCREEN := Vector2(640, 360)
const BOX_SIZE := Vector2(300, 130)
const TITLE_SIZE := 30

var _box: RPGWindow
var _title: Label
var _subtitle: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = SCREEN

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_DEEP, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = SCREEN
	add_child(dim)

	_box = RPGWindow.new()
	_box.size = BOX_SIZE
	_box.position = (SCREEN - BOX_SIZE) / 2.0
	add_child(_box)

	_title = Label.new()
	_title.position = Vector2(0, 12)
	_title.size = Vector2(BOX_SIZE.x, 34)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.has_font("font", "CardNumber"):
		_title.add_theme_font_override("font", theme.get_font("font", "CardNumber"))
	_title.add_theme_font_size_override("font_size", TITLE_SIZE)
	_title.add_theme_constant_override("outline_size", 0)
	_box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.position = Vector2(0, 58)
	_subtitle.size = Vector2(BOX_SIZE.x, 14)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_subtitle)

	var button := Button.new()
	button.text = "JOGAR DE NOVO"
	button.size = Vector2(130, 20)
	button.position = Vector2((BOX_SIZE.x - button.size.x) / 2.0, BOX_SIZE.y - 38)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: play_again.emit())
	_box.add_child(button)


# kind: "win" | "lose" | "draw"
func show_result(kind: String) -> void:
	match kind:
		"win":
			_title.text = "VITÓRIA!"
			_title.add_theme_color_override("font_color", Palette.GOLD)
			_subtitle.text = "Você zerou o HP do Gribnok."
		"lose":
			_title.text = "DERROTA"
			_title.add_theme_color_override("font_color", Palette.HP_RED.lightened(0.15))
			_subtitle.text = "O Gribnok zerou o seu HP."
		_:
			_title.text = "EMPATE"
			_title.add_theme_color_override("font_color", Palette.TEXT_LIGHT)
			_subtitle.text = "Os dois chegaram a 0 de HP."

	visible = true
	# entrada em 3 passos secos (a janela "cai" no lugar), sem escala pra não borrar os pixels
	var rest := (SCREEN - BOX_SIZE) / 2.0
	_box.position = rest + Vector2(0, -12)
	var tween := create_tween()
	tween.tween_property(_box, "position", rest + Vector2(0, 3), 0.08)
	tween.tween_property(_box, "position", rest + Vector2(0, -1), 0.05)
	tween.tween_property(_box, "position", rest, 0.05)
