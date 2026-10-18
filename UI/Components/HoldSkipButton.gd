# HoldSkipButton.gd
# "Segure para pular": só a palavra (sem caixa), igual aos outros botões do jogo. Só completa
# depois de ficar pressionado por HOLD_TIME segundos (mouse em cima dela, ou ESC/Enter mantidos),
# pra ninguém pular sem querer. Ao passar o mouse aparece o ">" e a palavra acende; enquanto
# segura, uma linha embaixo vai enchendo. Soltar esvazia depressa.
# Desenhado em tela cheia (1920x1080), usado nos vídeos (Intro, e depois o Ending).

class_name HoldSkipButton
extends Control

signal completed

const HOLD_TIME := 1.0          # segundos segurando
const DRAIN_SPEED := 3.0        # esvazia 3x mais rápido do que enche
const BOX := Vector2(420, 66)   # área clicável (invisível)
const MARGIN := 40.0
const FONT_SIZE := 36           # 12 px internos x3: a Pixel Squadron fica nítida
const TEXT := "segure para pular"
const PIXEL := 3                # tamanho do pixel do ">" (a tela é a interna x3)
const LINE_H := 6

const COLOR_IDLE := Color(0.95, 0.93, 0.90, 0.6)
const COLOR_ACTIVE := Color("#e6c46c")     # mesmo destaque do hover do resto do jogo

var progress: float = 0.0       # 0..1
var _mouse_down: bool = false
var _hover: bool = false
var _armed: bool = false        # só vale tecla depois que tudo foi solto uma vez
var _done: bool = false


func _ready() -> void:
	custom_minimum_size = BOX
	size = BOX
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -(BOX.x + MARGIN)
	offset_right = -MARGIN
	offset_top = -(BOX.y + MARGIN)
	offset_bottom = -MARGIN
	mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
	mouse_exited.connect(func() -> void: _hover = false; queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = event.pressed
		accept_event()


# Soltar o mouse fora do botão também solta.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_mouse_down = false


func _key_held() -> bool:
	return Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("ui_accept")


func _process(delta: float) -> void:
	if _done:
		return
	if not _armed:
		_armed = not _key_held()          # a tecla que abriu esta cena ainda pode estar apertada
	var holding: bool = _mouse_down or (_armed and _key_held())
	var before := progress
	if holding:
		progress = minf(progress + delta / HOLD_TIME, 1.0)
	else:
		progress = maxf(progress - delta * DRAIN_SPEED / HOLD_TIME, 0.0)
	if progress != before:
		queue_redraw()
	if progress >= 1.0:
		_done = true
		completed.emit()


func _draw() -> void:
	var active: bool = progress > 0.0 or _hover
	var color := COLOR_ACTIVE if active else COLOR_IDLE
	var font := get_theme_font("font", "Label")
	var text_size := font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var text_x := size.x - text_size.x                   # alinhado à direita
	var base_y := floorf(size.y / 2.0 + text_size.y * 0.25)
	draw_string(font, Vector2(text_x + 3, base_y + 3), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(text_x, base_y), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)

	# ">" pixelado antes da palavra (só com o mouse em cima ou segurando)
	if active:
		var rows := TextButton.MARK
		var mark_x := text_x - 18 - 5 * PIXEL
		var mark_y := base_y - text_size.y * 0.45 - rows.size() * PIXEL / 2.0
		for r in rows.size():
			var line: String = rows[r]
			for c in line.length():
				if line[c] == "X":
					draw_rect(Rect2(floorf(mark_x) + c * PIXEL, floorf(mark_y) + r * PIXEL, PIXEL, PIXEL), color)

	# linha de progresso embaixo da palavra (em degraus de 6 px)
	var line_y := base_y + 12
	draw_rect(Rect2(text_x, line_y, text_size.x, LINE_H), Color(1, 1, 1, 0.15))
	var filled := floorf(text_size.x * progress / 6.0) * 6.0
	if filled > 0.0:
		draw_rect(Rect2(text_x, line_y, filled, LINE_H), COLOR_ACTIVE)
