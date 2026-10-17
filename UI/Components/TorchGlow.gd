# TorchGlow.gd
# Brilho de tocha que TREME por cima da chama pintada no fundo: anéis quentes somados à imagem
# (blend aditivo), com raio e força mudando a ~10 quadros por segundo. Só ambiente.

class_name TorchGlow
extends Node2D

const TICK := 0.1

@export var radius: int = 20
var _acc: float = 0.0
var _wobble: int = 0
var _power: float = 1.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_roll()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < TICK:
		return
	_acc = 0.0
	_roll()
	queue_redraw()


func _roll() -> void:
	_wobble = randi_range(-2, 2)
	_power = randf_range(0.7, 1.1)


func _draw() -> void:
	var r := radius + _wobble
	draw_circle(Vector2.ZERO, r, Color(0.20, 0.09, 0.02, 0.10 * _power))
	draw_circle(Vector2.ZERO, r * 0.7, Color(0.28, 0.13, 0.03, 0.12 * _power))
	draw_circle(Vector2.ZERO, r * 0.4, Color(0.40, 0.20, 0.05, 0.14 * _power))
