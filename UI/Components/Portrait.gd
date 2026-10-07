# Portrait.gd
# Moldura de retrato (72x72 internos) com plaquinha de nome. A arte é um PLACEHOLDER
# desenhado por código (figura encapuzada pro jogador, caveira pro inimigo); quando existir
# arte real, é só desenhar a textura em _draw no lugar de _draw_hooded/_draw_skull.

class_name Portrait
extends Control

const FRAME := 4

var kind: String = "player"       # "player" | "enemy"
var display_name: String = ""


func _init() -> void:
	custom_minimum_size = Vector2(72, 72)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(portrait_kind: String, name_text: String) -> void:
	kind = portrait_kind
	display_name = name_text
	queue_redraw()


func _draw() -> void:
	var s := size
	# moldura de pedra/bronze com relevo
	draw_rect(Rect2(Vector2.ZERO, s), Palette.BORDER_DARK)
	draw_rect(Rect2(1, 1, s.x - 2, s.y - 2), Palette.PANEL_LIGHT.darkened(0.35))
	draw_rect(Rect2(2, 2, s.x - 4, s.y - 4), Palette.PANEL_LIGHT)
	draw_rect(Rect2(FRAME, FRAME, s.x - FRAME * 2, s.y - FRAME * 2), Palette.BORDER_DARK)

	var art := Rect2(FRAME + 1, FRAME + 1, s.x - FRAME * 2 - 2, s.y - FRAME * 2 - 2)
	draw_rect(art, Color("#0a101c") if kind == "player" else Color("#160a0a"))
	if kind == "player":
		_draw_hooded(art)
	else:
		_draw_skull(art)

	# cantoneiras douradas
	for p in [Vector2(0, 0), Vector2(s.x - 3, 0), Vector2(0, s.y - 3), Vector2(s.x - 3, s.y - 3)]:
		draw_rect(Rect2(p, Vector2(3, 3)), Palette.COIN_DARK)
		draw_rect(Rect2(p, Vector2(2, 2)), Palette.COIN)

	# plaquinha de nome
	var plate := Rect2(art.position.x, art.end.y - 11, art.size.x, 11)
	draw_rect(plate, Color(Palette.BORDER_DARK, 0.85))
	var font := get_theme_default_font()
	var fs := 10
	var base_y := plate.position.y + (plate.size.y - (font.get_ascent(fs) + font.get_descent(fs))) / 2.0 + font.get_ascent(fs)
	draw_string(font, Vector2(plate.position.x + 1, base_y + 1), display_name, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, fs, Palette.BORDER_DARK)
	draw_string(font, Vector2(plate.position.x, base_y), display_name, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, fs, Palette.GOLD)


# --- helpers de desenho em pixels (tudo cortado pela área da arte) ---
func _fill_ellipse(area: Rect2, cx: float, cy: float, rx: float, ry: float, color: Color, shade_dir: Vector2 = Vector2.ZERO, shade: Color = Color.BLACK) -> void:
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var nx := (x - cx) / rx
			var ny := (y - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			if not area.has_point(Vector2(x, y)):
				continue
			var c := color
			if shade_dir != Vector2.ZERO and (nx * shade_dir.x + ny * shade_dir.y) > 0.35:
				c = shade
			draw_rect(Rect2(x, y, 1, 1), c)


func _draw_hooded(area: Rect2) -> void:
	var o := area.position
	var hood := Color("#223b6e")
	_fill_ellipse(area, o.x + 31, o.y + 52, 29, 16, hood, Vector2(1, 0.6), Color("#162a52"))      # ombros
	_fill_ellipse(area, o.x + 31, o.y + 26, 21, 25, hood, Vector2(1, 0.4), Color("#162a52"))      # capuz
	_fill_ellipse(area, o.x + 31, o.y + 29, 12, 15, Color("#05080f"))                             # rosto na sombra
	for e in [Vector2(26, 27), Vector2(34, 27)]:                                                  # olhos brilhantes
		draw_rect(Rect2(o + e, Vector2(3, 2)), Color("#6fe6ff"))
		draw_rect(Rect2(o + e + Vector2(0, 2), Vector2(3, 1)), Color("#2f8fb0"))
	draw_rect(Rect2(o.x + 12, o.y + 14, 2, 14), Color("#3a62a8"))                                 # luz na borda esquerda


func _draw_skull(area: Rect2) -> void:
	var o := area.position
	var bone := Palette.BONE
	_fill_ellipse(area, o.x + 31, o.y + 24, 19, 19, bone, Vector2(1, 0.5), bone.darkened(0.3))   # crânio
	draw_rect(Rect2(o.x + 21, o.y + 38, 20, 11), bone.darkened(0.12))                             # mandíbula
	for i in 5:                                                                                   # dentes
		draw_rect(Rect2(o.x + 23 + i * 4, o.y + 41, 1, 8), Palette.BG_DEEP)
	for e in [Vector2(23, 22), Vector2(35, 22)]:                                                  # órbitas
		_fill_ellipse(area, o.x + e.x + 2, o.y + e.y + 2, 4, 5, Palette.BG_DEEP)
		draw_rect(Rect2(o + e + Vector2(1, 2), Vector2(2, 2)), Palette.HP_RED)                    # brilho vermelho
	draw_rect(Rect2(o.x + 30, o.y + 31, 2, 4), Palette.BG_DEEP)                                   # nariz
	draw_rect(Rect2(o.x + 29, o.y + 34, 4, 1), Palette.BG_DEEP)
	draw_rect(Rect2(o.x + 38, o.y + 8, 1, 7), Palette.BG_DEEP)                                    # rachadura
	draw_rect(Rect2(o.x + 39, o.y + 14, 1, 4), Palette.BG_DEEP)
