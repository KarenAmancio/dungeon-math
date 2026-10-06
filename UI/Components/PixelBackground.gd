# PixelBackground.gd
# Fundo placeholder da batalha, desenhado por código: parede de tijolos
# roxos em blocos grandes + faixa escura no topo (atrás das barras de HP)
# e uma faixa de "mesa" separando o campo do inimigo e do jogador.
# Troque pelo background real quando ele estiver pronto.

class_name PixelBackground
extends Control

const BRICK_W := 96
const BRICK_H := 48
const HUD_BAND_H := 110.0
const TABLE_Y := 436.0
const TABLE_H := 47.0


func _init() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BG_DEEP)  # cor do rejunte

	var rows := ceili(size.y / BRICK_H)
	var cols := ceili(size.x / BRICK_W) + 1
	for r in rows:
		var row_offset := (r % 2) * (BRICK_W / 2)
		for c in cols:
			# variação de tom determinística (sem random, não "pisca" ao redesenhar)
			var variant := (r * 7 + c * 13) % 4
			var color: Color = Palette.BG_MID.lightened(0.03 * variant)
			var x := c * BRICK_W - row_offset
			draw_rect(Rect2(x + 3, r * BRICK_H + 3, BRICK_W - 6, BRICK_H - 6), color)
			# luz no topo do tijolo
			draw_rect(Rect2(x + 3, r * BRICK_H + 3, BRICK_W - 6, 4), color.lightened(0.12))

	# Faixa do HUD
	draw_rect(Rect2(0, 0, size.x, HUD_BAND_H), Color(Palette.BG_DEEP, 0.85))
	draw_rect(Rect2(0, HUD_BAND_H, size.x, 4), Palette.BORDER_DARK)

	# Faixa de mesa entre os dois campos
	draw_rect(Rect2(0, TABLE_Y, size.x, TABLE_H), Color(Palette.BG_DEEP, 0.9))
	draw_rect(Rect2(0, TABLE_Y, size.x, 4), Palette.PANEL_LIGHT)
	draw_rect(Rect2(0, TABLE_Y + TABLE_H - 4, size.x, 4), Palette.PANEL_LIGHT)
