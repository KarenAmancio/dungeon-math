# HPBar.gd
# Barra de HP em pixels internos (82x16), SIMPLES: moldura (contorno escuro + linha clara),
# preenchimento liso e "HP 25/30" com sombra de 1 px. Quando o HP cai: tremida curta, piscada e a barra esvazia em passos,
# deixando um "rastro" claro do que foi perdido. Cor de preenchimento configurável
# (azul = jogador, vermelho = inimigo, como na referência).

class_name HPBar
extends Control

const BAR_SIZE := Vector2(82, 16)

var max_hp: int = 30
var hp: int = 30
var fill_color: Color = Palette.HP_RED

var _shown: int = 30      # valor desenhado agora (anima em passos inteiros)
var _ghost: int = 30      # rastro do dano
var _flash: bool = false
var _home_x: float = 0.0
var _tween: Tween


func _init() -> void:
	custom_minimum_size = BAR_SIZE
	size = BAR_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_home_x = position.x


func setup(max_value: int, start_value: int, color: Color) -> void:
	max_hp = max_value
	hp = start_value
	_shown = start_value
	_ghost = start_value
	fill_color = color
	queue_redraw()


func set_hp(new_hp: int) -> void:
	new_hp = clampi(new_hp, 0, max_hp)
	if new_hp == hp:
		return
	var old := hp
	hp = new_hp

	if _tween and _tween.is_valid():
		_tween.kill()
	position.x = _home_x
	_tween = create_tween()

	if new_hp < old:
		_ghost = old
		# tremida e piscada curtas, sem easing
		for offset in [-2.0, 2.0, -1.0, 1.0, 0.0]:
			_tween.tween_property(self, "position:x", _home_x + offset, 0.04)
		for i in 2:
			_tween.tween_callback(_set_flash.bind(true))
			_tween.tween_interval(0.05)
			_tween.tween_callback(_set_flash.bind(false))
			_tween.tween_interval(0.05)
	else:
		_ghost = new_hp

	var steps := absi(old - new_hp)
	_tween.tween_method(_set_shown, float(old), float(new_hp), clampf(0.05 * steps, 0.1, 0.8))
	_tween.tween_callback(_finish.bind(new_hp))


func _set_shown(v: float) -> void:
	var rounded := roundi(v)
	if rounded != _shown:
		_shown = rounded
		queue_redraw()


func _set_flash(on: bool) -> void:
	_flash = on
	queue_redraw()


func _finish(final_hp: int) -> void:
	_shown = final_hp
	_ghost = final_hp
	queue_redraw()


func _draw() -> void:
	# moldura simples: contorno escuro + uma linha clara por dentro
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BORDER_DARK)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Palette.WINDOW_EDGE)
	var inner := Rect2(2, 2, size.x - 4, size.y - 4)
	draw_rect(inner, Palette.BG_DEEP)

	var ghost_w := roundi(inner.size.x * float(_ghost) / max_hp)
	var fill_w := roundi(inner.size.x * float(_shown) / max_hp)
	if ghost_w > fill_w:
		draw_rect(Rect2(inner.position, Vector2(ghost_w, inner.size.y)), fill_color.lightened(0.55))
	if fill_w > 0:
		var c: Color = Palette.TEXT_LIGHT if _flash else fill_color
		draw_rect(Rect2(inner.position, Vector2(fill_w, inner.size.y)), c)

	# "HP 25/30" centralizado, com sombra de 1 px
	var font := get_theme_default_font()
	var fs := 10
	var label := "HP %d/%d" % [_shown, max_hp]
	var base_y := (size.y - (font.get_ascent(fs) + font.get_descent(fs))) / 2.0 + font.get_ascent(fs)
	draw_string(font, Vector2(1, base_y + 1), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Palette.BORDER_DARK)
	draw_string(font, Vector2(0, base_y), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Palette.TEXT_LIGHT)
