# SceneTransition.gd
# Fade em DEGRAUS (poucos níveis de preto, sem suavização) usado pelo GameManager nas trocas de
# cena. Fica numa CanvasLayer por cima de tudo e bloqueia cliques enquanto a tela está escura.
# Não conhece cenas: só escurece (fade_out) e clareia (fade_in).

class_name SceneTransition
extends CanvasLayer

const STEPS := 5            # quantos degraus de escuridão
const STEP_TIME := 0.05     # segundos por degrau

var _rect: ColorRect


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS     # a transição continua mesmo com o jogo pausado
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Deixa a tela totalmente preta já (usado na primeira cena, que "abre" do preto).
func set_black() -> void:
	_rect.color.a = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP


func fade_out() -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _run_steps(_rect.color.a, 1.0)


func fade_in() -> void:
	await _run_steps(_rect.color.a, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _run_steps(from: float, to: float) -> void:
	for i in range(1, STEPS + 1):
		_rect.color.a = lerpf(from, to, float(i) / STEPS)
		await get_tree().create_timer(STEP_TIME).timeout
