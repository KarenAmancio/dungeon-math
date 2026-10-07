# Palette.gd
# Única fonte das cores do jogo (paleta de dungeon: pedra escura, sangue, aço e âmbar,
# tirada da imagem em reference/) e dos helpers que criam StyleBoxFlat.
#
# Os temas (UI/Themes/pixel_theme*.tres) NÃO duplicam estes valores: eles são GERADOS
# por tools/build_theme.gd a partir daqui. Mudou uma cor? Rode o gerador de novo.

class_name Palette
extends RefCounted

# --- Base da interface ---
const BG_DEEP := Color("#0d0a0a")       # quase preto
const BG_MID := Color("#1c1613")        # marrom muito escuro
const BORDER_DARK := Color("#070505")   # contorno externo de tudo
const PANEL_FILL := Color("#17110f")    # miolo dos painéis
const PANEL_LIGHT := Color("#5a4636")   # segunda borda (bronze)
const TEXT_LIGHT := Color("#e8d8b0")    # pergaminho
const GOLD := Color("#d9a441")          # destaque

# --- Significado de jogo ---
const HP_RED := Color("#c8372d")        # HP do inimigo / dano
const PLAYER_HP := Color("#3a8fd0")     # HP do jogador (azul, como na referência)
const DEF_BLUE := Color("#3f78b8")      # defesa
const ATK_RED := Color("#c8402f")       # ataque
const ATK_ORANGE := ATK_RED             # nome antigo, ainda usado pelos overlays

# --- Tipos de carta ---
const CARD_ADD := Color("#3d9c7a")      # soma
const CARD_SUB := Color("#b8392b")      # subtração
const CARD_MUL := Color("#7a55c9")      # multiplicação
const CARD_BACK := Color("#2b2143")     # verso da carta / deck
const CARD_BACK_EDGE := Color("#5a4690")

# --- Janela estilo Chrono Trigger (menu, pausa) ---
const WINDOW_BLUE := Color("#12214a")
const WINDOW_BLUE_HI := Color("#2f4a96")

# --- Cenário (usado pelo gerador do fundo e pelas decorações) ---
const STONE_DARK := Color("#1d1815")
const STONE_MID := Color("#2c2420")
const STONE_LIGHT := Color("#3e342d")
const STONE_HI := Color("#54463b")
const MORTAR := Color("#0f0b0a")
const COIN := Color("#e0b040")
const COIN_DARK := Color("#9a6f1c")
const BONE := Color("#cbbf9f")
const BLOOD := Color("#6b1014")
const WAX := Color("#d9cdb0")
const FLAME := Color("#ff9a2e")
const FLAME_HI := Color("#ffd36b")


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
