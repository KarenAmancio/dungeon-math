# Candles.gd
# Três velas de cera sobre a prateleira (substituem a tocha). Estáticas por enquanto;
# a animação da chama pode entrar depois mexendo só aqui. Tudo em pixels internos.

class_name Candles
extends Node2D

# x, largura, altura da vela (a base fica em y = BASE_Y)
const CANDLES := [[2, 5, 14], [10, 6, 22], [20, 5, 10], [27, 4, 16]]
const BASE_Y := 32


func _draw() -> void:
	for c in CANDLES:
		var x: int = c[0]
		var w: int = c[1]
		var h: int = c[2]
		var top := BASE_Y - h
		draw_rect(Rect2(x - 1, top - 1, w + 2, h + 1), Palette.BORDER_DARK)       # contorno
		draw_rect(Rect2(x, top, w, h), Palette.WAX)
		draw_rect(Rect2(x + w - 2, top, 2, h), Palette.WAX.darkened(0.25))        # sombra do lado direito
		draw_rect(Rect2(x, top, w, 1), Palette.WAX.lightened(0.2))                # tampa
		draw_rect(Rect2(x + 1, top + 1, 1, 4), Palette.WAX.lightened(0.15))       # pinga de cera
		# chama
		draw_rect(Rect2(x + w / 2 - 1, top - 5, 3, 4), Palette.FLAME)
		draw_rect(Rect2(x + w / 2, top - 4, 1, 2), Palette.FLAME_HI)
		draw_rect(Rect2(x + w / 2, top - 6, 1, 1), Palette.FLAME)
		draw_rect(Rect2(x + w / 2, top - 1, 1, 1), Palette.BORDER_DARK)           # pavio
	# pocinha de cera na base
	draw_rect(Rect2(0, BASE_Y, 33, 2), Palette.WAX.darkened(0.3))
	draw_rect(Rect2(0, BASE_Y + 2, 33, 1), Palette.BORDER_DARK)
