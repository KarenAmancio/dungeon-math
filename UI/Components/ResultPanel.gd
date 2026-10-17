# ResultPanel.gd
# Painel de fim de batalha (vitória / derrota / empate) numa RPGWindow, com o botão
# botões de saída. Escurece a tela e bloqueia cliques no que está atrás. Pixels internos 640x360.
# O título usa a fonte de títulos do tema (Sorcery Code).

class_name ResultPanel
extends Control

# action: "won" (continuar), "retry" (tentar de novo) ou "menu". Quem decide o que cada uma
# significa é o GameManager (tabela FLOW); este painel só devolve a escolha.
signal action_chosen(action: String)

const SCREEN := Vector2(640, 360)
const BOX_SIZE := Vector2(300, 130)
const TITLE_SIZE := 28

var _box: RPGWindow
var _title: Label
var _subtitle: Label
var _buttons: Array[Button] = []


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
	_title.theme_type_variation = "LabelTitle"          # Sorcery Code
	_title.add_theme_font_size_override("font_size", TITLE_SIZE)
	_title.add_theme_constant_override("outline_size", 0)
	_box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.position = Vector2(0, 58)
	_subtitle.size = Vector2(BOX_SIZE.x, 14)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_subtitle)


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

	# vitória: continuar. Derrota/empate: tentar de novo ou voltar ao menu.
	if kind == "win":
		_set_buttons([["continuar", "won"]])
	else:
		_set_buttons([["tentar de novo", "retry"], ["menu", "menu"]])

	visible = true
	# entrada em 3 passos secos (a janela "cai" no lugar), sem escala pra não borrar os pixels
	var rest := (SCREEN - BOX_SIZE) / 2.0
	_box.position = rest + Vector2(0, -12)
	var tween := create_tween()
	tween.tween_property(_box, "position", rest + Vector2(0, 3), 0.08)
	tween.tween_property(_box, "position", rest + Vector2(0, -1), 0.05)
	tween.tween_property(_box, "position", rest, 0.05)


func _set_buttons(specs: Array) -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	var width := 118.0
	var gap := 10.0
	var total := width * specs.size() + gap * (specs.size() - 1)
	for i in specs.size():
		var button := TextButton.new()
		button.text = specs[i][0]
		button.size = Vector2(width, 20)
		button.position = Vector2((BOX_SIZE.x - total) / 2.0 + i * (width + gap), BOX_SIZE.y - 38)
		button.focus_mode = Control.FOCUS_NONE
		var action: String = specs[i][1]
		button.pressed.connect(func() -> void: action_chosen.emit(action))
		_box.add_child(button)
		_buttons.append(button)


# Botões atuais (usado nos testes pra achar onde clicar).
func buttons() -> Array[Button]:
	return _buttons
