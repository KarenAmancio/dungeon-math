# BattleTutorial.gd
# Controla o tutorial da batalha: percorre os passos de
# Resources/Dialogues/tutorial_battle.gd e usa o TutorialOverlay pra mostrar.
# Enquanto o tutorial está ativo ele avisa o Battle (tutorial_active /
# tutorial_allow_deck / tutorial_allow_confirm), e o Battle bloqueia
# arrastar cartas e os botões que não são do passo atual.

class_name BattleTutorial
extends Node

# Ainda não existe GameManager: o "já viu" fica numa variável estática, que
# sobrevive ao reload da cena ("Jogar de novo") mas não ao fechar o jogo.
# Quando o GameManager existir, é só mover esta flag pra lá.
static var seen: bool = false

var battle: Node2D
var ui: BattleUI
var overlay: TutorialOverlay

var _index: int = -1


func setup(battle_node: Node2D, battle_ui: BattleUI, overlay_node: TutorialOverlay) -> void:
	battle = battle_node
	ui = battle_ui
	overlay = overlay_node
	overlay.next_pressed.connect(func() -> void: _go_to(_index + 1))
	overlay.skip_pressed.connect(finish)


# Chamado ao iniciar a batalha: só roda se o jogador ainda não viu.
func start_if_needed() -> void:
	if not seen:
		start()


func start() -> void:
	battle.tutorial_active = true
	_go_to(0)


func _go_to(index: int) -> void:
	if index >= TutorialBattleText.STEPS.size():
		finish()
		return
	_index = index
	var step: Dictionary = TutorialBattleText.STEPS[index]

	battle.tutorial_allow_deck = step["allow"] == "deck"
	battle.tutorial_allow_confirm = step["allow"] == "confirm"

	var example := ""
	if step.has("example"):
		var steps := BattleMath.calculate_steps(step["example"])
		var total: int = steps.back()["after"] if not steps.is_empty() else 0
		example = "Ex.: %s   %s %s: %d" % [PlayLogPanel.steps_text(steps), PlayLogPanel.RESULT_ARROW, step.get("example_label", "Total"), total]

	var is_last := index == TutorialBattleText.STEPS.size() - 1
	overlay.show_step(
		ui.target_rect(step["target"]),
		step["title"],
		step["text"],
		example,
		"COMEÇAR" if is_last else "PRÓXIMO",
		"%d/%d" % [index + 1, TutorialBattleText.STEPS.size()]
	)


# Fim (último passo, PULAR, ou CONFIRMAR no último passo): libera o jogo e marca como visto.
func finish() -> void:
	seen = true
	battle.tutorial_active = false
	battle.tutorial_allow_deck = false
	battle.tutorial_allow_confirm = false
	overlay.hide_overlay()
