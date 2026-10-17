# MenuList.gd
# Lista vertical de opções com o sinal ">" ao lado da opção marcada (a palavra marcada acende), navegável
# por mouse (passar o mouse marca, clicar ativa) e teclado (cima/baixo + Enter). Reutilizável
# no menu inicial e na pausa.
#
#   list.setup([{"id": "play", "text": "JOGAR"}, ...])
#   list.activated.connect(func(id): ...)

class_name MenuList
extends Control

signal activated(id: String)

const ROW_H := 18
const ROW_GAP := 2
const ROW_W := 120
const POINTER_W := 22         # espaço da mão à esquerda do texto
const BOB_TICK := 0.25        # o ">" anda 1 px a cada 0.25 s
const FONT_SIZE := 16

var row_width: int = ROW_W      # mude ANTES de setup() se o texto for maior
var normal_color: Color = Palette.TEXT_LIGHT   # cor das opções não marcadas (mude ANTES de setup())
var _items: Array = []
var _rows: Array[Label] = []
var _selected: int = 0
var _enabled: bool = true
var _box: VBoxContainer
var _pointer: Control
var _bob: bool = false
var _acc: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


# items: Array de {"id": String, "text": String}
func setup(items: Array) -> void:
	_items = items
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", ROW_GAP)
	_box.position = Vector2.ZERO
	add_child(_box)

	for i in items.size():
		var label := Label.new()
		label.text = items[i]["text"]
		label.custom_minimum_size = Vector2(row_width, ROW_H)
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(func() -> void: select(i))
		label.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select(i)
				_activate())
		# espaço pra mão à esquerda
		var wrap := MarginContainer.new()
		wrap.add_theme_constant_override("margin_left", POINTER_W)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(label)
		_box.add_child(wrap)
		_rows.append(label)

	_pointer = _HandPointer.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pointer)
	custom_minimum_size = Vector2(POINTER_W + row_width, items.size() * (ROW_H + ROW_GAP) - ROW_GAP)
	select(0)


func select(index: int) -> void:
	_selected = clampi(index, 0, _items.size() - 1)
	for i in _rows.size():
		_rows[i].add_theme_color_override("font_color", Palette.TEXT_HOVER if i == _selected else normal_color)
	_place_pointer()


func selected_id() -> String:
	return _items[_selected]["id"]


func set_enabled(on: bool) -> void:
	_enabled = on
	_pointer.visible = on


func _place_pointer() -> void:
	_pointer.position = Vector2(8 + (1 if _bob else 0), _selected * (ROW_H + ROW_GAP) + (ROW_H - 12) / 2.0)


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= BOB_TICK:
		_acc = 0.0
		_bob = not _bob
		if _pointer != null:
			_place_pointer()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _enabled or not is_visible_in_tree() or _items.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		select((_selected + 1) % _items.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		select((_selected - 1 + _items.size()) % _items.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_activate()
		get_viewport().set_input_as_handled()


func _activate() -> void:
	if _enabled:
		activated.emit(selected_id())


# O ">" pixelado que marca a opção (mesmo desenho do TextButton).
class _HandPointer extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(6, 12)
		size = custom_minimum_size

	func _draw() -> void:
		var rows := TextButton.MARK
		var y := floorf((size.y - rows.size()) / 2.0)
		for r in rows.size():
			var line: String = rows[r]
			for c in line.length():
				if line[c] == "X":
					draw_rect(Rect2(c, y + r, 1, 1), Palette.TEXT_HOVER)
