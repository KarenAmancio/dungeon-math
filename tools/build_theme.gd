# build_theme.gd
# Gera os temas do jogo A PARTIR de UI/Palette.gd (assim as cores têm um único dono).
#
# Rodar (depois de qualquer mudança em Palette.gd ou nas fontes):
#   godot --headless --path . --script res://tools/build_theme.gd
#
# Saídas:
#   UI/Themes/pixel_theme.tres     tema da batalha/menus (escala 1: pixels internos 640x360)
#   UI/Themes/pixel_theme_x3.tres  TRANSITÓRIO: mesmo tema ×3, para os overlays que ainda ficam
#                                  em tela cheia (tutorial, relatório, como jogar, resultado).
#                                  Some quando eles forem pra dentro do SubViewport (Etapa G).
#
# PONTO ÚNICO DE TROCA DE FONTE: as duas constantes abaixo.
# A Tiny5 só fica nítida em múltiplos de 5 px (10, 15, 20...), por isso os tamanhos abaixo.

extends SceneTree

const FONT_UI := "res://UI/Fonts/Tiny5-Regular.ttf"
const FONT_TITLE := "res://UI/Fonts/Jacquard24-Regular.ttf"
# Números e nomes de operação das cartas: a "4" da Tiny5 parece um "d", então as cartas usam outra.
const FONT_NUMBERS := "res://UI/Fonts/Jersey10-Regular.ttf"

const SIZE_SMALL := 10
const SIZE_BODY := 10
const SIZE_TITLE := 15
const SIZE_BIG := 20


func _initialize() -> void:
	_save(_build(1), "res://UI/Themes/pixel_theme.tres")
	_save(_build(3), "res://UI/Themes/pixel_theme_x3.tres")
	quit()


func _save(theme: Theme, path: String) -> void:
	var err := ResourceSaver.save(theme, path)
	print("%s: %s" % [path, "ok" if err == OK else "ERRO %d" % err])


func _flat(fill: Color, border: Color, border_px: int, s: int, bottom_extra: int = 0) -> StyleBoxFlat:
	var sb := Palette.box(fill, border, border_px * s)
	sb.border_width_bottom = (border_px + bottom_extra) * s
	sb.content_margin_left = 4 * s
	sb.content_margin_right = 4 * s
	sb.content_margin_top = 2 * s
	sb.content_margin_bottom = 2 * s + bottom_extra * s
	return sb


func _build(s: int) -> Theme:
	var t := Theme.new()
	var font: Font = load(FONT_UI)
	var title_font: Font = load(FONT_TITLE)
	var number_font: Font = load(FONT_NUMBERS)

	t.default_font = font
	t.default_font_size = SIZE_BODY * s

	# --- Label (texto com sombra de 1 px, no estilo pixel art) ---
	t.set_font_size("font_size", "Label", SIZE_BODY * s)
	t.set_color("font_color", "Label", Palette.TEXT_LIGHT)
	t.set_color("font_shadow_color", "Label", Palette.BORDER_DARK)
	t.set_constant("shadow_offset_x", "Label", s)
	t.set_constant("shadow_offset_y", "Label", s)
	t.set_constant("outline_size", "Label", 0)

	t.set_type_variation("LabelTitle", "Label")
	t.set_font_size("font_size", "LabelTitle", SIZE_TITLE * s)
	t.set_color("font_color", "LabelTitle", Palette.GOLD)

	t.set_type_variation("LabelSmall", "Label")
	t.set_font_size("font_size", "LabelSmall", SIZE_SMALL * s)

	t.set_type_variation("LabelNumber", "Label")
	t.set_font_size("font_size", "LabelNumber", SIZE_TITLE * s)

	t.set_type_variation("LabelLogo", "Label")
	t.set_font("font", "LabelLogo", title_font)
	t.set_font_size("font_size", "LabelLogo", 40 * s)
	t.set_color("font_color", "LabelLogo", Palette.HP_RED.darkened(0.35))
	t.set_color("font_outline_color", "LabelLogo", Palette.BORDER_DARK)
	t.set_constant("outline_size", "LabelLogo", 2 * s)

	# Fonte das cartas (lida pelo CardArt)
	t.set_font("font", "CardNumber", number_font)

	# --- Button (placa de bronze; borda de baixo mais grossa dá o "relevo") ---
	t.set_font_size("font_size", "Button", SIZE_BODY * s)
	t.set_color("font_color", "Button", Palette.TEXT_LIGHT)
	t.set_color("font_hover_color", "Button", Palette.GOLD)
	t.set_color("font_pressed_color", "Button", Palette.GOLD.darkened(0.2))
	t.set_color("font_disabled_color", "Button", Palette.PANEL_LIGHT)
	t.set_stylebox("normal", "Button", _flat(Palette.STONE_MID, Palette.BORDER_DARK, 1, s, 1))
	t.set_stylebox("hover", "Button", _flat(Palette.STONE_LIGHT, Palette.GOLD.darkened(0.3), 1, s, 1))
	t.set_stylebox("pressed", "Button", _flat(Palette.STONE_DARK, Palette.BORDER_DARK, 1, s, 0))
	t.set_stylebox("disabled", "Button", _flat(Palette.BG_MID, Palette.BORDER_DARK, 1, s, 0))
	var focus := Palette.outline(Palette.GOLD, s)
	t.set_stylebox("focus", "Button", focus)

	# Botão FIM DO TURNO (placa bronze com borda dourada, como na referência)
	t.set_type_variation("EndTurn", "Button")
	t.set_font_size("font_size", "EndTurn", SIZE_BODY * s)
	t.set_color("font_color", "EndTurn", Palette.GOLD)
	t.set_color("font_hover_color", "EndTurn", Palette.FLAME_HI)
	t.set_stylebox("normal", "EndTurn", _flat(Palette.STONE_MID, Palette.PANEL_LIGHT, 1, s, 1))
	t.set_stylebox("hover", "EndTurn", _flat(Palette.STONE_LIGHT, Palette.GOLD, 1, s, 1))
	t.set_stylebox("pressed", "EndTurn", _flat(Palette.STONE_DARK, Palette.GOLD.darkened(0.3), 1, s, 0))
	t.set_stylebox("disabled", "EndTurn", _flat(Palette.BG_MID, Palette.STONE_MID, 1, s, 0))

	# --- Panel e variações ---
	t.set_stylebox("panel", "Panel", Palette.box(Palette.PANEL_FILL, Palette.BORDER_DARK, s))

	t.set_type_variation("PanelAttack", "Panel")
	t.set_stylebox("panel", "PanelAttack", Palette.box(Palette.dark_of(Palette.ATK_RED), Palette.ATK_RED.darkened(0.45), s))

	t.set_type_variation("PanelDefense", "Panel")
	t.set_stylebox("panel", "PanelDefense", Palette.box(Palette.dark_of(Palette.DEF_BLUE), Palette.DEF_BLUE.darkened(0.45), s))

	# Janela estilo Chrono Trigger (menu, pausa, como jogar)
	t.set_type_variation("PanelWindow", "Panel")
	t.set_stylebox("panel", "PanelWindow", Palette.box(Palette.WINDOW_BLUE, Palette.TEXT_LIGHT, s))

	return t
