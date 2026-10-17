# Credits.gd
# Créditos: uma janela RPG sobre o corredor do menu, com os nomes ROLANDO devagar (1 px a cada
# SCROLL_TICK, em degraus). Qualquer tecla, clique ou ESC volta; ao terminar de rolar também.
# Os nomes e papéis vêm de Resources/Data/credits_data.gd. Só avisa o GameManager ("finished").

extends Control

const BACKGROUND := "res://Backgrounds/menu_bg.png"
const WINDOW_SIZE := Vector2(380, 264)
const PADDING := 12.0
const SCROLL_TICK := 0.05

var _clip: Control
var _column: VBoxContainer
var _acc: float = 0.0
var _done: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := PixelViewport.new()
	add_child(view)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_content(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.modulate = Color(0.55, 0.55, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var window := RPGWindow.new()
	window.custom_minimum_size = WINDOW_SIZE
	center.add_child(window)

	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(PADDING, PADDING)
	_clip.size = WINDOW_SIZE - Vector2(PADDING, PADDING) * 2.0
	window.add_child(_clip)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.custom_minimum_size.x = _clip.size.x
	_clip.add_child(_column)
	_fill_credits()
	_column.position.y = _clip.size.y          # começa logo abaixo da janela e sobe


func _fill_credits() -> void:
	_add_label(CreditsData.TITLE, "LabelTitle", Palette.GOLD, 20)
	_add_label(CreditsData.SUBTITLE, "Label", Palette.TEXT_LIGHT, 16)
	_add_gap(14)
	for section in CreditsData.SECTIONS:
		_add_label(section["heading"], "LabelTitle", Palette.GOLD, 16)
		for line in section["lines"]:
			_add_label(line["name"], "Label", Palette.TEXT_LIGHT, 16)
			_add_label(line["role"], "Label", Palette.TEXT_LIGHT.darkened(0.4), 12)
		_add_gap(14)
	_add_label(CreditsData.THANKS, "LabelTitle", Palette.GOLD, 16)


func _add_label(text: String, variation: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = _clip.size.x
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(label)


func _add_gap(height: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(1, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(gap)


func _process(delta: float) -> void:
	if _done:
		return
	_acc += delta
	while _acc >= SCROLL_TICK:
		_acc -= SCROLL_TICK
		_column.position.y -= 1.0
	if _column.position.y + _column.size.y < 0.0:
		_finish()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	var click: bool = event is InputEventMouseButton and event.pressed
	if key or click:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	GameManager.scene_finished("credits", "finished")
