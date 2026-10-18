# TorchGlow.gd
# Brilho de tocha por cima da chama pintada no fundo: um quadrado com o shader da chama
# (Resources/Shaders/flame.gdshader), que treme, ondula e muda de cor entre laranja e amarelo.
# `radius` é o raio da luz em pixels internos; o nó fica centrado na posição dele.

class_name TorchGlow
extends Node2D

const SHADER := preload("res://Resources/Shaders/flame.gdshader")

@export var radius: int = 20

static var _noise: NoiseTexture2D


func _ready() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(radius, radius) * 2.0
	rect.position = -rect.size / 2.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("noise", _get_noise())
	mat.set_shader_parameter("timeOffset", randf() * 10.0)       # cada tocha treme no seu ritmo
	mat.set_shader_parameter("offsetX", randf() * 3.0)
	rect.material = mat
	add_child(rect)


# Ruído que se repete sem emenda (uma textura só, dividida entre as tochas).
static func _get_noise() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.03
		_noise = NoiseTexture2D.new()
		_noise.noise = n
		_noise.seamless = true
		_noise.width = 128
		_noise.height = 128
	return _noise
