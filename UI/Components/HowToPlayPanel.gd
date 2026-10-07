# HowToPlayPanel.gd
# Tela "Como jogar": objetivo, resumo das regras e um exemplo de conta.
# O conteúdo vem de TutorialBattleText.HOW_TO_PLAY (Resources/Dialogues).
# É modal: escurece a tela e bloqueia cliques nos controles de baixo
# enquanto estiver aberta (quem usa avisa o resto do jogo pelos sinais).

class_name HowToPlayPanel
extends Control

signal opened
signal closed

const BOX_SIZE := Vector2(1100, 780)


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_DEEP, 0.85)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var data: Dictionary = TutorialBattleText.HOW_TO_PLAY

	var box := PixelPanel.new()
	box.position = (Vector2(1920, 1080) - BOX_SIZE) / 2.0
	box.size = BOX_SIZE
	add_child(box)
	box.configure(Palette.PANEL_FILL, Palette.BORDER_DARK, Palette.GOLD, 6, 3)

	var title := Label.new()
	title.text = data["title"]
	title.position = Vector2(32, 20)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Palette.GOLD)
	box.add_child(title)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.position = Vector2(32, 90)
	text.size = Vector2(BOX_SIZE.x - 64, BOX_SIZE.y - 90 - 100)
	text.add_theme_font_size_override("normal_font_size", 30)
	text.add_theme_color_override("default_color", Palette.TEXT_LIGHT)
	text.text = _build_text(data)
	box.add_child(text)

	var close := Button.new()
	close.text = "FECHAR"
	close.position = Vector2((BOX_SIZE.x - 260) / 2.0, BOX_SIZE.y - 70)
	close.size = Vector2(260, 48)
	close.add_theme_font_size_override("font_size", 30)
	close.pressed.connect(close_panel)
	box.add_child(close)


func _build_text(data: Dictionary) -> String:
	var gold := Palette.GOLD.to_html(false)
	var out := "[font_size=36][color=#%s]%s[/color][/font_size]\n%s\n\n" % [gold, data["goal_title"], data["goal"]]

	out += "[font_size=36][color=#%s]%s[/color][/font_size]\n" % [gold, data["rules_title"]]
	for rule in data["rules"]:
		out += "- %s\n" % rule

	var steps := BattleMath.calculate_steps(data["example_cards"])
	var total: int = steps.back()["after"] if not steps.is_empty() else 0
	out += "\n[font_size=36][color=#%s]%s[/color][/font_size]\n" % [gold, data["example_title"]]
	out += "%s   %s %s: %d\n%s" % [PlayLogPanel.steps_text(steps), PlayLogPanel.RESULT_ARROW, data["example_label"], total, data["example_note"]]
	return out


func open_panel() -> void:
	visible = true
	opened.emit()


func close_panel() -> void:
	visible = false
	closed.emit()
