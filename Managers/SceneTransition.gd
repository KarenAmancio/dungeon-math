# SceneTransition.gd
# Transição entre cenas: a tela é "comida" por blocos de pixel (shader dissolve.gdshader) e depois
# volta do mesmo jeito. Fica numa CanvasLayer por cima de tudo e bloqueia cliques enquanto a tela
# está escura. Não conhece cenas: só escurece (fade_out) e clareia (fade_in).

class_name SceneTransition
extends CanvasLayer

const SHADER := preload("res://Resources/Shaders/dissolve.gdshader")
const DURATION := 0.55          # segundos pra cobrir (ou descobrir) a tela

var _rect: ColorRect
var _material: ShaderMaterial
var _progress: float = 0.0
var _tween: Tween


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS     # a transição continua mesmo com o jogo pausado
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_progress(0.0)


# Deixa a tela totalmente preta já (usado na primeira cena, que "abre" do preto).
func set_black() -> void:
	_set_progress(1.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP


func fade_out() -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_material.set_shader_parameter("seed", randf() * 10.0)
	await _animate(_progress, 1.0)


func fade_in() -> void:
	await _animate(_progress, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _animate(from: float, to: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_progress, from, to, DURATION * absf(to - from))
	await _tween.finished


func _set_progress(value: float) -> void:
	_progress = value
	_material.set_shader_parameter("progress", value)
