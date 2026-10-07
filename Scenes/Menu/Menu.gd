# Menu.gd
# Menu inicial: corredor de masmorra decadente (tochas tremendo, olhos piscando no escuro e
# sussurros nas paredes), logo com sangue pingando e uma janela RPG com as opções:
# JOGAR, COMO JOGAR, CRÉDITOS e SAIR, com cursor de mão.
#
# O layout usa containers e âncoras sobre a tela interna fixa de 640x360 (PixelViewport), então
# fica igual em qualquer máquina. O menu NÃO sabe qual cena vem depois: só avisa o GameManager
# o que o jogador escolheu ("play", "credits", "quit").

extends Control

const BACKGROUND := "res://Backgrounds/menu_bg.png"
# onde ficam as chamas (em cima dos suportes pintados no fundo) e o tamanho do pixel delas
const TORCHES := [[Vector2(238, 134), 2], [Vector2(369, 141), 1], [Vector2(290, 144), 1]]

var _list: MenuList
var _how_to: HowToPlayPanel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := PixelViewport.new()
	add_child(view)

	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_content(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(BACKGROUND)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ambiente: chamas, olhos e sussurros (atrás do logo e da janela)
	var ambience := Node2D.new()
	content.add_child(ambience)
	for t in TORCHES:
		var flame := TorchFlame.new()
		flame.px = t[1]
		flame.position = t[0]
		ambience.add_child(flame)
	ambience.add_child(DarkEyes.new())
	content.add_child(Whispers.new())

	_build_layout(content)

	_how_to = HowToPlayPanel.new()
	content.add_child(_how_to)
	_how_to.opened.connect(func() -> void: _list.set_enabled(false))
	_how_to.closed.connect(func() -> void: _list.set_enabled(true))

	CursorManager.use_hand()


func _exit_tree() -> void:
	CursorManager.use_default()


# Logo no topo, janela de opções embaixo, e o corredor aparecendo no meio.
func _build_layout(content: Control) -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	content.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	var logo_row := CenterContainer.new()
	logo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo_row)
	logo_row.add_child(Logo.new())

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var window_row := CenterContainer.new()
	window_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(window_row)

	var window := RPGWindow.new()
	window.custom_minimum_size = Vector2(160, 98)
	window_row.add_child(window)

	var inner := MarginContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 10)
	window.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_list = MenuList.new()
	inner.add_child(_list)
	_list.setup([
		{"id": "play", "text": "JOGAR"},
		{"id": "how_to", "text": "COMO JOGAR"},
		{"id": "credits", "text": "CRÉDITOS"},
		{"id": "quit", "text": "SAIR"},
	])
	_list.activated.connect(_on_option)


func _on_option(id: String) -> void:
	match id:
		"how_to":
			_how_to.open_panel()
		"play", "credits", "quit":
			GameManager.scene_finished("menu", id)
