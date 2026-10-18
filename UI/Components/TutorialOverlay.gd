# TutorialOverlay.gd
# Overlay de tutorial reutilizável, em pixels internos (640x360): escurece a tela, deixa uma área
# "furada" destacada com moldura dourada piscando, e mostra um balão estilo RPG (RPGWindow) com o
# texto aparecendo letra por letra e os botões PRÓXIMO e PULAR.
#
# As 4 faixas escuras bloqueiam clique nos controles de baixo; só o que estiver dentro do
# "buraco" continua clicável. (Cliques no mundo 2D, como o baralho, são bloqueados pelo
# Battle, não por aqui.)
#
# Não conhece a batalha: quem usa decide o conteúdo e o que fazer nos sinais.

class_name TutorialOverlay
extends Control

signal next_pressed
signal skip_pressed

const SCREEN := Vector2(640, 360)
const BOX_SIZE := Vector2(320, 108)
const CHARS_PER_SECOND := 70.0
const MARGIN := 10.0

var _dims: Array[ColorRect] = []
var _frame: Panel
var _box: RPGWindow
var _title: Label
var _counter: Label
var _body: RichTextLabel
var _example: Label
var _next: Button
var _skip: Button

var _typing: bool = false
var _type_tween: Tween
var _blink_tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = SCREEN

	for i in 4:
		var dim := ColorRect.new()
		dim.color = Color(Palette.BG_DEEP, 0.80)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dim)
		_dims.append(dim)

	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_theme_stylebox_override("panel", Palette.outline(Palette.GOLD, 1))
	add_child(_frame)

	_box = RPGWindow.new()
	_box.size = BOX_SIZE
	add_child(_box)
	# um clique em qualquer lugar do balão (ou da área escura) mostra o texto inteiro
	_box.gui_input.connect(_on_click_to_complete)
	for dim in _dims:
		dim.gui_input.connect(_on_click_to_complete)

	_title = _make_label(Vector2(MARGIN, 5), Vector2(BOX_SIZE.x - MARGIN * 2 - 40, 16), "LabelTitle")
	_counter = _make_label(Vector2(BOX_SIZE.x - MARGIN - 40, 8), Vector2(40, 12), "LabelSmall")
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.add_theme_color_override("font_color", Palette.WINDOW_LINE.lightened(0.5))

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.position = Vector2(MARGIN, 26)
	_body.size = Vector2(BOX_SIZE.x - MARGIN * 2, 52)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_body)

	_example = _make_label(Vector2(MARGIN, 76), Vector2(BOX_SIZE.x - MARGIN * 2, 14), "LabelMath")
	_example.add_theme_color_override("font_color", Palette.GOLD)

	_skip = TextButton.new()
	_skip.text = "pular"
	_skip.position = Vector2(MARGIN, BOX_SIZE.y - 22)
	_skip.size = Vector2(60, 15)
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	_box.add_child(_skip)

	_next = TextButton.new()
	_next.position = Vector2(BOX_SIZE.x - MARGIN - 80, BOX_SIZE.y - 22)
	_next.size = Vector2(80, 15)
	_next.focus_mode = Control.FOCUS_NONE
	_next.pressed.connect(_on_next_pressed)
	_box.add_child(_next)


func _make_label(pos: Vector2, label_size: Vector2, variation: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.position = pos
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		_frame.position = hole.position - Vector2(1, 1)
		_frame.size = hole.size + Vector2(2, 2)
		_blink_tween = create_tween().set_loops()
		_blink_tween.tween_interval(0.5)
		_blink_tween.tween_callback(_frame.hide)
		_blink_tween.tween_interval(0.25)
		_blink_tween.tween_callback(_frame.show)

	# O balão vai pro lado da tela oposto ao destaque, pra nunca cobri-lo
	var box_y := (SCREEN.y - BOX_SIZE.y) / 2.0
	if has_hole:
		box_y = 12.0 if hole.get_center().y > SCREEN.y / 2.0 - 14.0 else SCREEN.y - BOX_SIZE.y - 12.0
	_box.position = Vector2((SCREEN.x - BOX_SIZE.x) / 2.0, box_y)

	_title.text = step_title
	_counter.text = counter_text
	_next.text = next_text
	_example.text = example
	_example.visible = false

	# Texto aparecendo letra por letra (estilo caixa de diálogo de RPG)
	_body.text = Emph.prep(body)
	_body.visible_characters = 0
	_typing = true
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = create_tween()
	var length: int = _body.get_total_character_count()
	_type_tween.tween_property(_body, "visible_characters", length, maxf(length / CHARS_PER_SECOND, 0.1))
	_type_tween.tween_callback(_finish_typing)


# Retângulo do balão (usado nos testes pra garantir que ele não cobre o destaque).
func box_rect() -> Rect2:
	return Rect2(_box.position, _box.size)


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


func _on_click_to_complete(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _typing:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_finish_typing()


# 1º clique completa o texto; o 2º avança.
func _on_next_pressed() -> void:
	if _typing:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_finish_typing()
	else:
		next_pressed.emit()
