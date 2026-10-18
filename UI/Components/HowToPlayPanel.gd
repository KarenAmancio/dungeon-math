# HowToPlayPanel.gd
# Tela "Como jogar" PAGINADA: objetivo, regras e exemplo de conta, numa janela RPGWindow
# (pixels internos 640x360), com setas pra virar a página (botões "<" ">" ou teclas ← →),
# texto aparecendo letra por letra e FECHAR (ou ESC). O conteúdo vem de
# TutorialBattleText.HOW_TO_PLAY (Resources/Dialogues), o MESMO texto do tutorial.
#
# É modal: escurece a tela e bloqueia cliques nos controles de baixo enquanto estiver aberta
# (quem usa avisa o resto do jogo pelos sinais opened/closed). Usada na batalha ("?") e no menu.

class_name HowToPlayPanel
extends Control

signal opened
signal closed

const SCREEN := Vector2(640, 360)
const BOX_RECT := Rect2(60, 44, 520, 272)
const MARGIN := 14.0
const CHARS_PER_SECOND := 70.0
const RULES_PER_PAGE := 3
const BODY_SIZE := 14

var _pages: Array[Dictionary] = []
var _index: int = 0
var _typing: bool = false
var _type_tween: Tween

var _title: Label
var _body: RichTextLabel
var _counter: Label
var _prev: TextButton
var _next: TextButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = SCREEN

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_DEEP, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = SCREEN
	add_child(dim)

	var box := RPGWindow.new()
	box.position = BOX_RECT.position
	box.size = BOX_RECT.size
	add_child(box)
	box.gui_input.connect(_gui_input)      # a janela absorve o clique, então repassa pra completar o texto

	_title = Label.new()
	_title.theme_type_variation = "LabelTitle"
	_title.add_theme_font_size_override("font_size", 20)
	_title.position = Vector2(MARGIN, 8)
	_title.size = Vector2(BOX_RECT.size.x - MARGIN * 2.0 - 60.0, 24)
	box.add_child(_title)

	_counter = Label.new()
	_counter.position = Vector2(BOX_RECT.size.x - MARGIN - 60.0, 12)
	_counter.size = Vector2(60, 14)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter.add_theme_color_override("font_color", Palette.WINDOW_LINE.lightened(0.55))
	box.add_child(_counter)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_size_override("normal_font_size", BODY_SIZE)
	_body.add_theme_font_size_override("bold_font_size", BODY_SIZE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.position = Vector2(MARGIN, 42)
	_body.size = Vector2(BOX_RECT.size.x - MARGIN * 2.0, BOX_RECT.size.y - 42.0 - 36.0)
	box.add_child(_body)

	_prev = _make_button("<", Vector2(MARGIN, BOX_RECT.size.y - 28), Vector2(30, 18))
	_prev.add_theme_font_size_override("font_size", 20)
	_prev.show_mark = false
	_prev.pressed.connect(func() -> void: if not _complete_typing(): _go(_index - 1))
	box.add_child(_prev)

	_next = _make_button(">", Vector2(MARGIN + 36, BOX_RECT.size.y - 28), Vector2(30, 18))
	_next.add_theme_font_size_override("font_size", 20)
	_next.show_mark = false
	_next.pressed.connect(func() -> void: if not _complete_typing(): _go(_index + 1))
	box.add_child(_next)

	var close := _make_button("fechar", Vector2(BOX_RECT.size.x - MARGIN - 80, BOX_RECT.size.y - 28), Vector2(80, 18))
	close.pressed.connect(close_panel)
	box.add_child(close)

	_pages = _build_pages(TutorialBattleText.HOW_TO_PLAY)


func _make_button(text: String, pos: Vector2, button_size: Vector2) -> TextButton:
	var b := TextButton.new()
	b.text = text
	b.position = pos
	b.size = button_size
	b.focus_mode = Control.FOCUS_NONE
	return b


# Quebra o conteúdo em páginas: objetivo, regras (de 3 em 3) e exemplo de conta.
func _build_pages(data: Dictionary) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	pages.append({"title": data["goal_title"], "body": data["goal"]})

	var rules: Array = data["rules"]
	var start := 0
	while start < rules.size():
		var chunk := ""
		for i in range(start, mini(start + RULES_PER_PAGE, rules.size())):
			chunk += "- %s\n\n" % rules[i]
		pages.append({"title": data["rules_title"], "body": chunk.strip_edges()})
		start += RULES_PER_PAGE

	var steps := BattleMath.calculate_steps(data["example_cards"])
	var total: int = steps.back()["after"] if not steps.is_empty() else 0
	pages.append({
		"title": data["example_title"],
		"body": "%s\n\n%s\n\n%s" % [Emph.math(PlayLogPanel.steps_text(steps)), Emph.math("%s %s: %d" % [PlayLogPanel.RESULT_ARROW, data["example_label"], total]), data["example_note"]],
	})
	return pages


func open_panel() -> void:
	visible = true
	_show_page(0)
	opened.emit()


func close_panel() -> void:
	visible = false
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	closed.emit()


func _go(index: int) -> void:
	if index < 0 or index >= _pages.size():
		return
	_show_page(index)


func _show_page(index: int) -> void:
	_index = clampi(index, 0, _pages.size() - 1)
	var page := _pages[_index]
	_title.text = page["title"]
	_counter.text = "%d/%d" % [_index + 1, _pages.size()]
	_prev.disabled = _index == 0
	_next.disabled = _index == _pages.size() - 1

	# texto aparecendo letra por letra
	_body.text = Emph.prep(page["body"])
	_body.visible_characters = 0
	_typing = true
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	var length: int = _body.get_total_character_count()
	_type_tween = create_tween()
	_type_tween.tween_property(_body, "visible_characters", length, maxf(length / CHARS_PER_SECOND, 0.1))
	_type_tween.tween_callback(_finish_typing)


# Clique em qualquer lugar da tela "Como jogar" enquanto o texto aparece: mostra o texto inteiro.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_complete_typing()


# Se o texto ainda está aparecendo, mostra tudo e devolve true (o clique foi "gasto" nisso).
func _complete_typing() -> bool:
	if not _typing:
		return false
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_finish_typing()
	return true


func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1


# Teclado: ← → viram a página (ou completam o texto), Enter avança, ESC fecha.
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		if _typing:
			_type_tween.kill()
			_finish_typing()
		else:
			_go(_index + 1)
	elif event.is_action_pressed("ui_left"):
		_go(_index - 1)
	else:
		return
	get_viewport().set_input_as_handled()


# Nos testes: mostra o texto inteiro sem esperar a digitação.
func skip_typing() -> void:
	if _typing:
		_type_tween.kill()
		_finish_typing()
