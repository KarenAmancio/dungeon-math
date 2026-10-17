# TutorialOverlay.gd
# Overlay de tutorial reutilizável: escurece a tela, deixa uma área
# "furada" e destacada com moldura dourada piscando, e mostra um balão
# no estilo caixa de diálogo de RPG (texto aparecendo letra por letra)
# com os botões PRÓXIMO e PULAR.
#
# As 4 faixas escuras bloqueiam clique nos controles de baixo; só o que
# estiver dentro do "buraco" continua clicável. (Cliques no mundo 2D, como
# o baralho, são bloqueados pelo Battle, não por aqui.)
#
# Não conhece a batalha: quem usa decide o conteúdo e o que fazer nos sinais.

class_name TutorialOverlay
extends Control

signal next_pressed
signal skip_pressed

const SCREEN := Vector2(1920, 1080)
const BOX_SIZE := Vector2(940, 330)
const CHARS_PER_SECOND := 70.0

var _dims: Array[ColorRect] = []
var _frame: Panel
var _box: PixelPanel
var _title: Label
var _counter: Label
var _body: Label
var _example: Label
var _next: Button
var _skip: Button

var _typing: bool = false
var _type_tween: Tween
var _blink_tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for i in 4:
		var dim := ColorRect.new()
		dim.color = Color(Palette.BG_DEEP, 0.82)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dim)
		_dims.append(dim)

	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_theme_stylebox_override("panel", Palette.outline(Palette.GOLD, 4))
	add_child(_frame)

	_box = PixelPanel.new()
	_box.size = BOX_SIZE
	add_child(_box)
	_box.configure(Palette.PANEL_FILL, Palette.BORDER_DARK, Palette.GOLD, 6, 3)

	_title = _make_label(Vector2(28, 18), Vector2(700, 40), 36, Palette.GOLD)
	_counter = _make_label(Vector2(BOX_SIZE.x - 28 - 120, 22), Vector2(120, 36), 28, Palette.PANEL_LIGHT.lightened(0.5))
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_body = _make_label(Vector2(28, 70), Vector2(BOX_SIZE.x - 56, 160), 30, Palette.TEXT_LIGHT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_example = _make_label(Vector2(28, 232), Vector2(BOX_SIZE.x - 56, 34), 28, Palette.GOLD)

	_skip = Button.new()
	_skip.text = "PULAR"
	_skip.position = Vector2(28, BOX_SIZE.y - 44 - 18)
	_skip.size = Vector2(200, 44)
	_skip.add_theme_font_size_override("font_size", 26)
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	_box.add_child(_skip)

	_next = Button.new()
	_next.position = Vector2(BOX_SIZE.x - 28 - 240, BOX_SIZE.y - 44 - 18)
	_next.size = Vector2(240, 44)
	_next.add_theme_font_size_override("font_size", 28)
	_next.pressed.connect(_on_next_pressed)
	_box.add_child(_next)


func _make_label(pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_box.add_child(label)
	return label


# hole: área da tela que fica clara/clicável (Rect2() = nada destacado).
func show_step(hole: Rect2, step_title: String, body: String, example: String, next_text: String, counter_text: String) -> void:
	visible = true
	hole = hole.intersection(Rect2(Vector2.ZERO, SCREEN))
	var has_hole := hole.size.x > 0.0 and hole.size.y > 0.0

	var rects: Array[Rect2] = [Rect2(Vector2.ZERO, SCREEN), Rect2(), Rect2(), Rect2()]
	if has_hole:
		rects = [
			Rect2(0, 0, SCREEN.x, hole.position.y),                                        # cima
			Rect2(0, hole.end.y, SCREEN.x, SCREEN.y - hole.end.y),                         # baixo
			Rect2(0, hole.position.y, hole.position.x, hole.size.y),                       # esquerda
			Rect2(hole.end.x, hole.position.y, SCREEN.x - hole.end.x, hole.size.y),        # direita
		]
	for i in 4:
		_dims[i].position = rects[i].position
		_dims[i].size = rects[i].size

	# Moldura dourada piscando em passos secos
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	_frame.visible = has_hole
	if has_hole:
		_frame.position = hole.position - Vector2(4, 4)
		_frame.size = hole.size + Vector2(8, 8)
		_blink_tween = create_tween().set_loops()
		_blink_tween.tween_interval(0.5)
		_blink_tween.tween_callback(_frame.hide)
		_blink_tween.tween_interval(0.25)
		_blink_tween.tween_callback(_frame.show)

	# O balão vai pro lado da tela oposto ao destaque, pra nunca cobri-lo
	var box_y := 375.0
	if has_hole:
		box_y = 120.0 if hole.get_center().y > 500.0 else 720.0
	_box.position = Vector2((SCREEN.x - BOX_SIZE.x) / 2.0, box_y)

	_title.text = step_title
	_counter.text = counter_text
	_next.text = next_text
	_example.text = example
	_example.visible = false

	# Texto aparecendo letra por letra (estilo caixa de diálogo de RPG)
	_body.text = body
	_body.visible_characters = 0
	_typing = true
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(_body, "visible_characters", body.length(), maxf(body.length() / CHARS_PER_SECOND, 0.1))
	_type_tween.tween_callback(_finish_typing)


func hide_overlay() -> void:
	visible = false
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()


func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	_example.visible = _example.text != ""


# 1º clique completa o texto; o 2º avança.
func _on_next_pressed() -> void:
	if _typing:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_finish_typing()
	else:
		next_pressed.emit()
