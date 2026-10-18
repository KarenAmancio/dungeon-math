# SceneTransition.gd
# Transição entre cenas com o shader de ruído em pixels (Resources/Shaders/transition.gdshader).
# O "progress" do shader vai de 0 a 1 em duas metades: 0 -> 0.5 COBRE a tela (fade_out) e
# 0.5 -> 1.0 DESCOBRE (fade_in). Fica numa CanvasLayer por cima de tudo e bloqueia cliques
# enquanto a tela está coberta. Não conhece cenas: só cobre e descobre.

class_name SceneTransition
extends CanvasLayer

const SHADER := preload("res://Resources/Shaders/transition.gdshader")
const HALF_TIME := 0.5           # segundos de cada metade (cobrir / descobrir)

var _rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS     # a transição continua mesmo com o jogo pausado
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Deixa a tela totalmente coberta já (usado na primeira cena, que "abre" do preto).
func set_black() -> void:
	_rect.visible = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_progress(0.5)


func fade_out() -> void:
	_rect.visible = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_material.set_shader_parameter("seed", randf())
	await _animate(0.0, 0.5)


func fade_in() -> void:
	await _animate(0.5, 1.0)
	_rect.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _animate(from: float, to: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_progress, from, to, HALF_TIME)
	await _tween.finished


# Mesmas fórmulas do controle original: os limiares seguem o progresso.
func _set_progress(value: float) -> void:
	_material.set_shader_parameter("progress", value)
	_material.set_shader_parameter("background_threshold", absf(1.0 - value * 2.0) - 0.5)
	_material.set_shader_parameter("color_threshold", minf(1.0, absf(-4.0 + value * 8.0)) * 0.48)
