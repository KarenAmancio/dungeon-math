# HowToPlayPanel.gd
# Tela "Como jogar": objetivo, resumo das regras e um exemplo de conta, numa janela RPGWindow
# (pixels internos 640x360). O conteúdo vem de TutorialBattleText.HOW_TO_PLAY
# (Resources/Dialogues). É modal: escurece a tela e bloqueia cliques nos controles de baixo
# enquanto estiver aberta (quem usa avisa o resto do jogo pelos sinais).

class_name HowToPlayPanel
extends Control

signal opened
signal closed

const SCREEN := Vector2(640, 360)
const BOX_RECT := Rect2(70, 36, 500, 288)
const MARGIN := 12.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = SCREEN

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_DEEP, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = SCREEN
	add_child(dim)

	var data: Dictionary = TutorialBattleText.HOW_TO_PLAY

	var box := RPGWindow.new()
	box.position = BOX_RECT.position
	box.size = BOX_RECT.size
	add_child(box)

	var title := Label.new()
	title.theme_type_variation = "LabelTitle"
	title.text = data["title"]
	title.position = Vector2(MARGIN, 7)
	box.add_child(title)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.position = Vector2(MARGIN, 28)
	text.size = Vector2(BOX_RECT.size.x - MARGIN * 2.0, BOX_RECT.size.y - 28 - 30)
	text.add_theme_font_size_override("normal_font_size", 10)
	text.add_theme_color_override("default_color", Palette.TEXT_LIGHT)
	text.text = _build_text(data)
	box.add_child(text)

	var close := Button.new()
	close.text = "FECHAR"
	close.size = Vector2(80, 16)
	close.position = Vector2((BOX_RECT.size.x - close.size.x) / 2.0, BOX_RECT.size.y - 24)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_panel)
	box.add_child(close)


func _build_text(data: Dictionary) -> String:
	var gold := Palette.GOLD.to_html(false)
	var out := "[font_size=15][color=#%s]%s[/color][/font_size]\n%s\n\n" % [gold, data["goal_title"], data["goal"]]

	out += "[font_size=15][color=#%s]%s[/color][/font_size]\n" % [gold, data["rules_title"]]
	for rule in data["rules"]:
		out += "- %s\n" % rule

	var steps := BattleMath.calculate_steps(data["example_cards"])
	var total: int = steps.back()["after"] if not steps.is_empty() else 0
	out += "\n[font_size=15][color=#%s]%s[/color][/font_size]\n" % [gold, data["example_title"]]
	out += "%s   %s %s: %d\n%s" % [PlayLogPanel.steps_text(steps), PlayLogPanel.RESULT_ARROW, data["example_label"], total, data["example_note"]]
	return out


func open_panel() -> void:
	visible = true
	opened.emit()


func close_panel() -> void:
	visible = false
	closed.emit()
