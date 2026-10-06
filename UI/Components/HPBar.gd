# HPBar.gd
# Barra de HP segmentada (1 segmento por ponto de vida, até 30 segmentos),
# com borda dupla, nome do personagem e "HP 30/30" com contorno.
# Quando o HP cai: tremida curta, piscada e a barra esvazia em passos,
# deixando um "rastro" claro do que foi perdido.

class_name HPBar
extends Control

const NAME_H := 34.0
const BAR_H := 44.0
const MAX_SEGMENTS := 30
const SEGMENT_GAP := 2.0

var char_name: String = ""
var max_hp: int = 30
var hp: int = 30
var align_right: bool = false

var _shown: int = 30      # valor desenhado agora (anima em passos inteiros)
var _ghost: int = 30      # rastro do dano
var _flash: bool = false
var _home_x: float = 0.0
var _tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(560, NAME_H + BAR_H + 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_home_x = position.x


func setup(display_name: String, max_value: int, start_value: int, right_aligned: bool = false) -> void:
	char_name = display_name
	max_hp = max_value
	hp = start_value
	_shown = start_value
	_ghost = start_value
	align_right = right_aligned
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
		for offset in [-6.0, 6.0, -4.0, 4.0, 0.0]:
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
	var font := get_theme_default_font()

	# Nome do personagem
	var name_align := HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT
	var name_pos := Vector2(0, NAME_H - 8)
	draw_string_outline(font, name_pos, char_name, name_align, size.x, 34, 5, Palette.BORDER_DARK)
	draw_string(font, name_pos, char_name, name_align, size.x, 34, Palette.GOLD)

	# Moldura dupla: borda escura + borda clara por dentro
	var bar := Rect2(0, NAME_H, size.x, BAR_H)
	draw_rect(bar, Palette.BORDER_DARK)
	draw_rect(bar.grow(-4), Palette.PANEL_LIGHT)
	var inner := bar.grow(-6)
	draw_rect(inner, Palette.BG_DEEP)

	# Segmentos
	var seg_count := mini(max_hp, MAX_SEGMENTS)
	var seg_w := floorf((inner.size.x - SEGMENT_GAP * (seg_count - 1)) / seg_count)
	var total_w := seg_w * seg_count + SEGMENT_GAP * (seg_count - 1)
	var start_x := inner.position.x + floorf((inner.size.x - total_w) / 2.0)
	var filled := ceili(float(_shown) / max_hp * seg_count)
	var ghost_filled := ceili(float(_ghost) / max_hp * seg_count)
	var fill_color: Color = Palette.TEXT_LIGHT if _flash else Palette.HP_RED

	for i in seg_count:
		var r := Rect2(start_x + i * (seg_w + SEGMENT_GAP), inner.position.y, seg_w, inner.size.y)
		if i < filled:
			draw_rect(r, fill_color)
			# faixa de luz no topo e sombra embaixo (look pixel art)
			draw_rect(Rect2(r.position, Vector2(seg_w, floorf(r.size.y * 0.3))), fill_color.lightened(0.35))
			draw_rect(Rect2(r.position.x, r.end.y - 4, seg_w, 4), fill_color.darkened(0.35))
		elif i < ghost_filled:
			draw_rect(r, Palette.HP_RED.lightened(0.55))

	# Texto "HP 30/30" centralizado sobre a barra
	var label := "HP %d/%d" % [_shown, max_hp]
	var label_pos := Vector2(0, bar.position.y + BAR_H / 2.0 + 10)
	draw_string_outline(font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, 6, Palette.BORDER_DARK)
	draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Palette.TEXT_LIGHT)
