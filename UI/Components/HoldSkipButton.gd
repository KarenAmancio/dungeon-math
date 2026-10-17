# HoldSkipButton.gd
# Botãozinho de "segurar para pular": só completa depois de ficar pressionado por HOLD_TIME
# segundos (mouse em cima dele, ou ESC/Enter/Espaço mantidos), pra ninguém pular sem querer.
# Mostra uma barra enchendo; soltar esvazia depressa. Desenhado em tela cheia (1920x1080),
# usado nos vídeos (Intro, e depois o Ending).

class_name HoldSkipButton
extends Control

signal completed

const HOLD_TIME := 1.0          # segundos segurando
const DRAIN_SPEED := 3.0        # esvazia 3x mais rápido do que enche
const BOX := Vector2(380, 66)
const MARGIN := 40.0
const FONT_SIZE := 36           # 12 px internos x3: a Pixel Squadron fica nítida
const TEXT := "SEGURE PARA PULAR"

const FILL := Color(0, 0, 0, 0.55)
const EDGE := Color(1, 1, 1, 0.35)
const EDGE_ACTIVE := Color(1, 1, 1, 0.9)
const BAR := Color("#8a1616")
const BAR_HI := Color("#c23a2e")

var progress: float = 0.0       # 0..1
var _mouse_down: bool = false
var _hover: bool = false
var _armed: bool = false        # só vale tecla depois que tudo foi solto uma vez
var _done: bool = false


func _ready() -> void:
	custom_minimum_size = BOX
	size = BOX
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, FILL)
	var inner := rect.grow(-6)
	# barra de progresso (degraus de 6 px pra manter o jeito pixel art)
	var width := floorf(inner.size.x * progress / 6.0) * 6.0
	if width > 0.0:
		draw_rect(Rect2(inner.position, Vector2(width, inner.size.y)), BAR)
		draw_rect(Rect2(inner.position, Vector2(width, 6)), BAR_HI)
	var active: bool = progress > 0.0 or _hover
	draw_rect(rect, EDGE_ACTIVE if active else EDGE, false, 3.0)
	var font := get_theme_font("font", "Label")
	var text_size := font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var pos := Vector2(floorf((size.x - text_size.x) / 2.0), floorf((size.y + text_size.y * 0.55) / 2.0))
	draw_string(font, pos + Vector2(3, 3), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.9))
	draw_string(font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(1, 1, 1, 1.0 if active else 0.7))
