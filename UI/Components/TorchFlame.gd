# TorchFlame.gd
# Chama de tocha que TREME em pixels (altura, balanço e brilho mudam a ~10 quadros por segundo),
# com um brilho pontilhado ao redor. O suporte de metal já está pintado no fundo.
# `px` é o tamanho do pixel da chama (inteiro, pra não borrar): tochas perto usam 2, longe 1.

class_name TorchFlame
extends Node2D

const TICK := 0.1

@export var px: int = 1

var _acc: float = 0.0
var _height: int = 8
var _sway: int = 0
var _glow: int = 0


func _ready() -> void:
	_roll()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < TICK:
		return
	_acc = 0.0
	_roll()
	queue_redraw()


func _roll() -> void:
	_height = randi_range(7, 10)
	_sway = randi_range(-1, 1)
	_glow = randi_range(0, 2)


func _draw() -> void:
	var s := float(px)
	# brilho pontilhado (xadrez de pixels quentes) em volta
	var radius := 8 + _glow
	for j in range(-radius, radius + 1):
		for i in range(-radius, radius + 1):
			var d2 := i * i + j * j
			if d2 <= radius * radius and (i + j) % 2 == 0 and d2 > 6:
				var a := 0.16 * (1.0 - float(d2) / float(radius * radius))
				draw_rect(Rect2(i * s, (j - 6) * s, s, s), Color(Palette.FLAME.r, Palette.FLAME.g, Palette.FLAME.b, a))
	# corpo da chama: base larga, ponta fina, balançando
	for row in _height:
		var t := float(row) / float(_height)            # 0 = base, 1 = ponta
		var half := int(round(2.6 * (1.0 - t * 0.85)))
		var shift := int(round(_sway * t * 1.5))
		var y := -row * s
		for i in range(-half, half + 1):
			var core := absi(i) <= maxi(half - 1, 0) and t < 0.7
			var c: Color = Palette.FLAME_HI if core and t < 0.45 else Palette.FLAME
			if t > 0.8:
				c = Palette.FLAME.darkened(0.15)
			draw_rect(Rect2((i + shift) * s, y - s, s, s), c)
	draw_rect(Rect2(-s, 0, 2 * s, s), Color("#3a1e0c"))     # pavio
