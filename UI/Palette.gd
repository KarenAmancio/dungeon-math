# Palette.gd
# Única fonte das cores do jogo (paleta pixel art de dungeon) e dos
# helpers que criam StyleBoxFlat "caixa de RPG" (cantos retos, borda grossa).
#
# OBS: UI/Themes/dungeon_theme.tres repete alguns desses valores (Button/Label),
# porque .tres não importa constantes. Se mudar uma cor aqui, confira lá.

class_name Palette
extends RefCounted

# --- Fundo e painéis ---
const BG_DEEP := Color("#150d2b")      # roxo quase preto
const BG_MID := Color("#211742")       # roxo escuro (tijolos do fundo)
const BORDER_DARK := Color("#0a0618")  # borda externa de tudo
const PANEL_FILL := Color("#1c1438")   # miolo dos painéis
const PANEL_LIGHT := Color("#4a3a85")  # segunda borda (profundidade)

# --- Texto e destaque ---
const TEXT_LIGHT := Color("#f3e9d2")   # creme
const GOLD := Color("#ffc53d")         # destaque / título

# --- Significado de jogo ---
const HP_RED := Color("#e0374b")
const DEF_BLUE := Color("#4a86e8")
const ATK_ORANGE := Color("#e8683a")

# --- Tipos de carta ---
const CARD_ADD := Color("#1f9c85")     # soma (verde-água, longe do vermelho p/ daltônicos)
const CARD_SUB := HP_RED               # subtração
const CARD_MUL := Color("#8d5ff0")     # multiplicação (roxo vivo)


# Caixa de RPG: cantos retos, sem antialiasing, borda de `width` px.
static func box(fill: Color, border: Color, width: int = 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	return sb


# Só a moldura (sem preenchimento); usada como "segunda borda" interna.
static func outline(color: Color, width: int = 2) -> StyleBoxFlat:
	var sb := box(Color(0, 0, 0, 0), color, width)
	sb.draw_center = false
	return sb


# Versão bem escura de uma cor de destaque, pra fundo de painel.
static func dark_of(c: Color) -> Color:
	return c.darkened(0.8)
