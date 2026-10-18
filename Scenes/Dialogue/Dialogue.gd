# Dialogue.gd
# Diálogo do Cayo com o Gribnok na porta (8 cenas). As falas ficam em
# Resources/Dialogues/gribnok_dialogue.gd; esta cena só mostra: fundo da porta, caixa de diálogo
# embaixo (nome de quem fala + texto aparecendo letra por letra) e, no fim de cada cena, as 3
# respostas do Cayo em lista.
#
# - Clique (ou Enter/Espaço): se o texto ainda está aparecendo, mostra tudo; senão, próxima fala.
# - Cada resposta pode guardar uma "flag" (GameManager.dialogue_flags). Falas marcadas com uma
#   flag só aparecem quando ela está ativa, e a batalha pode ler as flags depois.
# - Ao terminar (ou ao "pular") só avisa o GameManager: esta cena não sabe qual é a próxima.

extends Control

const BACKGROUND := "res://Backgrounds/dialogue_bg.png"
const BOX_RECT := Rect2(16, 236, 608, 112)
const MARGIN := 12.0
const CHARS_PER_SECOND := 60.0
const BODY_SIZE := 14
const OPTION_SIZE := 14

const NAME_COLORS := {
	"GRIBNOK": Color("#9ad46b"),
	"CAYO": Color("#7fb2e8"),
}

var _flags: Dictionary
var _scene_index: int = 0
var _queue: Array = []
var _qi: int = 0
var _after: Callable
var _mode: String = "lines"        # "lines" (falas) ou "options" (escolha do Cayo)
var _typing: bool = false
var _type_tween: Tween
var _blink_tween: Tween
var _finished: bool = false

var _name_label: Label
var _body: RichTextLabel
var _hint: Label
var _options_holder: Control
var _list: MenuList


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flags = GameManager.dialogue_flags
	_flags.clear()

	# fundo: a imagem ORIGINAL (sem reduzir cores), em tela cheia e com filtro suave
	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# a caixa e os textos ficam por cima, na tela de pixel (fundo transparente)
	var view := PixelViewport.new()
	view.viewport.transparent_bg = true
	add_child(view)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_content(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# área clicável por baixo de tudo: um clique em qualquer lugar avança a fala
	var catcher := Control.new()
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(catcher)
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.gui_input.connect(_on_click)

	_build_box(content)

	var skip := TextButton.new()
	skip.text = "pular"
	skip.position = Vector2(572, 6)
	skip.size = Vector2(60, 18)
	skip.pressed.connect(_finish)
	content.add_child(skip)

	CursorManager.use_hand()
	_begin_scene(0)


func _exit_tree() -> void:
	CursorManager.use_default()


func _build_box(content: Control) -> void:
	var box := RPGWindow.new()
	box.position = BOX_RECT.position
	box.size = BOX_RECT.size
	box.gui_input.connect(_on_click)          # a janela absorve o clique: repassa pra avançar a fala
	content.add_child(box)

	_name_label = Label.new()
	_name_label.theme_type_variation = "LabelTitle"
	_name_label.position = Vector2(MARGIN, 7)
	_name_label.size = Vector2(300, 20)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_name_label)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_size_override("normal_font_size", BODY_SIZE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.position = Vector2(MARGIN, 30)
	_body.size = Vector2(BOX_RECT.size.x - MARGIN * 2.0, 64)
	box.add_child(_body)

	_hint = Label.new()
	_hint.text = "continuar >"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.position = Vector2(BOX_RECT.size.x - MARGIN - 100, BOX_RECT.size.y - 18)
	_hint.size = Vector2(100, 14)
	_hint.add_theme_font_size_override("font_size", 10)
	_hint.add_theme_color_override("font_color", Palette.TEXT_LIGHT.darkened(0.25))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hint)

	_options_holder = Control.new()
	_options_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_holder.position = Vector2(MARGIN - 6.0, 30)
	_options_holder.size = Vector2(BOX_RECT.size.x - MARGIN * 2.0, 70)
	box.add_child(_options_holder)

	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_callback(func() -> void: _hint.modulate.a = 0.35)
	_blink_tween.tween_interval(0.45)
	_blink_tween.tween_callback(func() -> void: _hint.modulate.a = 1.0)
	_blink_tween.tween_interval(0.45)


# ---------------------------------------------------------------------------
# Fluxo das cenas
# ---------------------------------------------------------------------------
func _begin_scene(index: int) -> void:
	_scene_index = index
	var scene: Dictionary = GribnokDialogue.SCENES[index]
	_queue = _visible(scene["entry"])
	_qi = 0
	_after = _show_options
	_mode = "lines"
	_next_line()


# Só as falas cuja flag está ativa (ou que não pedem flag).
func _visible(lines: Array) -> Array:
	var out: Array = []
	for line in lines:
		var need: String = line[2]
		if need == "" or _flags.get(need, false):
			out.append(line)
	return out


func _next_line() -> void:
	if _qi >= _queue.size():
		_after.call()
		return
	var line: Array = _queue[_qi]
	_qi += 1
	_show_line(line[0], line[1])


func _show_line(who: String, text: String) -> void:
	_mode = "lines"
	_options_holder.visible = false
	_body.visible = true
	_hint.visible = false
	_name_label.visible = who != ""
	_name_label.text = who
	_name_label.add_theme_color_override("font_color", NAME_COLORS.get(who, Palette.GOLD))
	# ação/pensamento (entre parênteses) e narração ficam mais apagados que a fala
	var is_action := who == "" or text.begins_with("(")
	_body.add_theme_color_override("default_color", Palette.TEXT_LIGHT.darkened(0.3) if is_action else Color("#f2eee6"))
	_body.text = text
	_body.visible_characters = 0
	_typing = true
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	var total := _body.get_total_character_count()
	_type_tween = create_tween()
	_type_tween.tween_property(_body, "visible_characters", total, maxf(total / CHARS_PER_SECOND, 0.1))
	_type_tween.tween_callback(_finish_typing)


func _finish_typing() -> void:
	_typing = false
	_body.visible_characters = -1
	_hint.visible = true


# Clique/Enter: completa o texto que está aparecendo; senão, vai pra próxima fala.
func _advance() -> void:
	if _mode != "lines" or _finished:
		return
	if _typing:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_finish_typing()
	else:
		_next_line()


func _show_options() -> void:
	_mode = "options"
	_body.visible = false
	_hint.visible = false
	_name_label.visible = true
	_name_label.text = "CAYO"
	_name_label.add_theme_color_override("font_color", NAME_COLORS["CAYO"])
	_options_holder.visible = true
	if _list != null:
		_list.queue_free()
	var scene: Dictionary = GribnokDialogue.SCENES[_scene_index]
	var items: Array = []
	for i in scene["options"].size():
		items.append({"id": str(i), "text": scene["options"][i]["label"]})
	_list = MenuList.new()
	_list.row_width = 560
	_list.font_size = OPTION_SIZE
	_list.normal_color = Color("#f2eee6")
	_options_holder.add_child(_list)
	_list.setup(items)
	_list.activated.connect(_on_option)


func _on_option(id: String) -> void:
	var scene: Dictionary = GribnokDialogue.SCENES[_scene_index]
	var option: Dictionary = scene["options"][int(id)]
	var flag: String = option["flag"]
	if flag != "":
		_flags[flag] = true
	if _list != null:
		_list.queue_free()
		_list = null
	_queue = _visible(option["lines"])
	_qi = 0
	_after = _end_scene
	_next_line()


func _end_scene() -> void:
	if _scene_index + 1 < GribnokDialogue.SCENES.size():
		_begin_scene(_scene_index + 1)
	else:
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	GameManager.scene_finished("dialogue", "finished")


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------
func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		if _mode == "lines":
			_advance()
			get_viewport().set_input_as_handled()
