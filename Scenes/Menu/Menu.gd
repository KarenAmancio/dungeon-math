# Menu.gd
# Menu inicial: corredor de masmorra (imagem de fundo), brilho das tochas tremendo, logo brilhando
# em roxo/rosa e as opções escritas em branco, em minúsculas, no meio do corredor (sem caixa):
# jogar, como jogar, créditos e sair.
#
# O layout usa containers e âncoras sobre a tela interna fixa de 640x360 (PixelViewport), então
# fica igual em qualquer máquina. O menu NÃO sabe qual cena vem depois: só avisa o GameManager
# o que o jogador escolheu ("play", "credits", "quit").

extends Control

const BACKGROUND := "res://Backgrounds/menu_bg.png"
# onde ficam as chamas pintadas no fundo (centro) e o raio do brilho em cima delas
const TORCHES := [[Vector2(45, 112), 40], [Vector2(218, 171), 20], [Vector2(420, 176), 20], [Vector2(588, 127), 40]]

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

	# ambiente: brilho das tochas, olhos e sussurros (atrás do logo e da janela)
	var ambience := Node2D.new()
	content.add_child(ambience)
	for t in TORCHES:
		var glow := TorchGlow.new()
		glow.radius = t[1]
		glow.position = t[0]
		ambience.add_child(glow)

	_build_layout(content)

	_how_to = HowToPlayPanel.new()
	content.add_child(_how_to)
	_how_to.opened.connect(func() -> void: _list.set_enabled(false))
	_how_to.closed.connect(func() -> void: _list.set_enabled(true))

	CursorManager.use_hand()


func _exit_tree() -> void:
	CursorManager.use_default()


# Logo no topo e as opções no meio do corredor.
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

	# opções direto sobre o corredor (sem caixa), no meio dele
	var list_row := CenterContainer.new()
	list_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(list_row)

	_list = MenuList.new()
	_list.row_width = 100
	_list.normal_color = Color("#f2eee6")
	list_row.add_child(_list)
	_list.setup([
		{"id": "play", "text": "jogar"},
		{"id": "how_to", "text": "como jogar"},
		{"id": "credits", "text": "créditos"},
		{"id": "quit", "text": "sair"},
	])

	# folga embaixo: sobe a lista pro meio do corredor
	var bottom := Control.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.custom_minimum_size = Vector2(0, 140)
	column.add_child(bottom)
	_list.activated.connect(_on_option)


func _on_option(id: String) -> void:
	match id:
		"how_to":
			_how_to.open_panel()
		"play", "credits", "quit":
			GameManager.scene_finished("menu", id)
