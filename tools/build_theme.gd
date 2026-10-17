# build_theme.gd
# Gera os temas do jogo A PARTIR de UI/Palette.gd (assim as cores têm um único dono).
#
# Rodar (depois de qualquer mudança em Palette.gd ou nas fontes):
#   godot --headless --path . --script res://tools/build_theme.gd
#
# Saídas:
#   UI/Themes/pixel_theme.tres     tema da batalha/menus (escala 1: pixels internos 640x360)
#
# PONTO ÚNICO DE TROCA DE FONTE: as constantes abaixo.
#   FONT_UI        texto normal (Pixel Squadron). Nítida a partir de 12 px.
#   FONT_TITLE     títulos (Sorcery Code). Nítida de 16 a 40 px.
#   FONT_EMPHASIS  palavras importantes no meio do texto (CS Wavelle Pixel), usada via [b] no RichTextLabel.
# A Pixel Squadron não tem < > − e a Sorcery Code não tem ×: as reservas (FALLBACKS) cobrem isso
# (Jersey10 tem < > − × e a Tiny5 tem a seta →).

extends SceneTree

const FONT_UI := "res://UI/Fonts/Pixel Squadron.ttf"
const FONT_TITLE := "res://UI/Fonts/Sorcery Code.ttf"
const FONT_EMPHASIS := "res://UI/Fonts/CS Wavelle Pixel/CSWavellePixel-Regular.ttf"
# Números e nomes de operação das cartas (a mais legível pra 4 e 5 em tamanho pequeno).
const FONT_NUMBERS := "res://UI/Fonts/Jersey10-Regular.ttf"
# Contas (+3 ×2 -5 = 12): na Pixel Squadron o + × = ficam minúsculos, então toda conta usa a Jersey10.
# A fonte (com reservas) é salva em arquivo pra poder ser citada em [font=...] dentro dos textos.
const MATH_FONT_PATH := "res://UI/Fonts/math_font.tres"
const SIZE_MATH := 10
const FONT_FALLBACKS: Array[String] = [
	"res://UI/Fonts/Jersey10-Regular.ttf",     # < > − ×
	"res://UI/Fonts/Tiny5-Regular.ttf",        # →
]

const SIZE_SMALL := 10
const SIZE_BODY := 12
const SIZE_TITLE := 16
const SIZE_BIG := 20
const SIZE_EMPHASIS := 14


func _initialize() -> void:
	_save(_build(1), "res://UI/Themes/pixel_theme.tres")
	quit()


func _save(theme: Theme, path: String) -> void:
	var err := ResourceSaver.save(theme, path)
	print("%s: %s" % [path, "ok" if err == OK else "ERRO %d" % err])


# Fonte com as reservas de caracteres que faltam.
func _with_fallbacks(path: String) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = load(path)
	var extra: Array[Font] = []
	for f in FONT_FALLBACKS:
		if f != path:
			extra.append(load(f))
	v.fallbacks = extra
	return v


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
	var font: Font = _with_fallbacks(FONT_UI)
	var title_font: Font = _with_fallbacks(FONT_TITLE)
	var emphasis_font: Font = _with_fallbacks(FONT_EMPHASIS)
	var number_font: Font = load(FONT_NUMBERS)
	var math_font := _with_fallbacks(FONT_NUMBERS)
	ResourceSaver.save(math_font, MATH_FONT_PATH)
	math_font = load(MATH_FONT_PATH)

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
	t.set_font("font", "LabelTitle", title_font)
	t.set_font_size("font_size", "LabelTitle", SIZE_TITLE * s)
	t.set_color("font_color", "LabelTitle", Palette.GOLD)

	t.set_type_variation("LabelSmall", "Label")
	t.set_font_size("font_size", "LabelSmall", SIZE_SMALL * s)

	t.set_type_variation("LabelNumber", "Label")
	t.set_font_size("font_size", "LabelNumber", SIZE_TITLE * s)

	t.set_type_variation("LabelMath", "Label")
	t.set_font("font", "LabelMath", math_font)
	t.set_font_size("font_size", "LabelMath", SIZE_MATH * s)

	t.set_type_variation("LabelLogo", "Label")
	t.set_font("font", "LabelLogo", title_font)
	t.set_font_size("font_size", "LabelLogo", 40 * s)
	t.set_color("font_color", "LabelLogo", Palette.TEXT_LIGHT)
	t.set_color("font_outline_color", "LabelLogo", Palette.BORDER_DARK)
	t.set_constant("outline_size", "LabelLogo", 2 * s)

	# --- RichTextLabel (textos longos: tutorial, Como jogar). [b]palavra[/b] = destaque ---
	t.set_font("normal_font", "RichTextLabel", font)
	t.set_font_size("normal_font_size", "RichTextLabel", SIZE_BODY * s)
	t.set_font("bold_font", "RichTextLabel", emphasis_font)
	t.set_font_size("bold_font_size", "RichTextLabel", SIZE_EMPHASIS * s)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT_LIGHT)
	t.set_color("font_shadow_color", "RichTextLabel", Palette.BORDER_DARK)
	t.set_constant("shadow_offset_x", "RichTextLabel", s)
	t.set_constant("shadow_offset_y", "RichTextLabel", s)

	# Fonte das cartas (lida pelo CardArt)
	t.set_font("font", "CardNumber", number_font)

	t.set_type_variation("RichMath", "RichTextLabel")
	t.set_font("normal_font", "RichMath", math_font)
	t.set_font_size("normal_font_size", "RichMath", SIZE_MATH * s)

	# --- Button: SÓ A PALAVRA, sem caixa. O hover só acende a cor (e o TextButton desenha o ">") ---
	t.set_font_size("font_size", "Button", SIZE_BODY * s)
	t.set_color("font_color", "Button", Palette.TEXT_LIGHT)
	t.set_color("font_hover_color", "Button", Palette.TEXT_HOVER)
	t.set_color("font_pressed_color", "Button", Palette.GOLD)
	t.set_color("font_disabled_color", "Button", Palette.TEXT_LIGHT.darkened(0.55))
	t.set_color("font_focus_color", "Button", Palette.TEXT_HOVER)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", StyleBoxEmpty.new())

	# Botão FIM DO TURNO: só o texto; a placa está desenhada no fundo da batalha
	t.set_type_variation("EndTurn", "Button")
	t.set_font_size("font_size", "EndTurn", SIZE_BODY * s)
	t.set_color("font_color", "EndTurn", Palette.TEXT_LIGHT)
	t.set_color("font_hover_color", "EndTurn", Palette.TEXT_HOVER)
	t.set_color("font_disabled_color", "EndTurn", Palette.TEXT_LIGHT.darkened(0.55))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "EndTurn", StyleBoxEmpty.new())

	# --- Panel e variações ---
	t.set_stylebox("panel", "Panel", Palette.box(Palette.PANEL_FILL, Palette.BORDER_DARK, s))

	t.set_type_variation("PanelAttack", "Panel")
	t.set_stylebox("panel", "PanelAttack", Palette.box(Palette.dark_of(Palette.ATK_RED), Palette.ATK_RED.darkened(0.45), s))

	t.set_type_variation("PanelDefense", "Panel")
	t.set_stylebox("panel", "PanelDefense", Palette.box(Palette.dark_of(Palette.DEF_BLUE), Palette.DEF_BLUE.darkened(0.45), s))

	# Janela estilo Chrono Trigger (menu, pausa, como jogar)
	t.set_type_variation("PanelWindow", "Panel")
	t.set_stylebox("panel", "PanelWindow", Palette.box(Palette.WINDOW_FILL, Palette.WINDOW_EDGE, s))

	return t
