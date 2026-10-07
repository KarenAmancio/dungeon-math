# Palette.gd
# Clima: escuro, sujo e dessaturado (ver reference/). Evite cores vivas: o brilho é raro e vale mais.
# Única fonte das cores do jogo (paleta de dungeon: pedra escura, sangue, aço e âmbar,
# tirada da imagem em reference/) e dos helpers que criam StyleBoxFlat.
#
# Os temas (UI/Themes/pixel_theme*.tres) NÃO duplicam estes valores: eles são GERADOS
# por tools/build_theme.gd a partir daqui. Mudou uma cor? Rode o gerador de novo.

class_name Palette
extends RefCounted

# --- Base da interface ---
const BG_DEEP := Color("#070606")       # quase preto
const BG_MID := Color("#120f0e")        # marrom muito escuro
const BORDER_DARK := Color("#030202")   # contorno externo de tudo
const PANEL_FILL := Color("#0e0a0a")    # miolo dos painéis
const PANEL_LIGHT := Color("#3a2c24")   # segunda borda (bronze)
const TEXT_LIGHT := Color("#b9ab8c")    # pergaminho
const GOLD := Color("#a87a30")          # destaque

# --- Significado de jogo ---
const HP_RED := Color("#8a241c")        # HP do inimigo / dano
const PLAYER_HP := Color("#2a5f92")     # HP do jogador (azul, como na referência)
const DEF_BLUE := Color("#34608f")      # defesa
const ATK_RED := Color("#8f2a22")       # ataque
const ATK_ORANGE := ATK_RED             # nome antigo, ainda usado pelos overlays

# --- Cartas (uma cor só: papel antigo com moldura escura) ---
const PAPER := Color("#d8c398")         # papel
const PAPER_INK := Color("#2a170c")     # tinta do número
const PAPER_FRAME := Color("#2a1a10")   # moldura escura
const PAPER_LINE := Color("#6b4a2b")    # filete interno

# --- Janelas (menu, pausa, tutorial, resultado): degradê de PRETO (cinza neutro, sem tom de cor) ---
const WINDOW_TOP := Color("#222222")    # topo do degradê
const WINDOW_FILL := Color("#0b0b0b")   # meio
const WINDOW_BOTTOM := Color("#000000") # base: preto puro
const WINDOW_EDGE := Color("#8c8c8c")   # borda clara
const WINDOW_LINE := Color("#404040")   # filete interno
const BUTTON_FILL := Color("#262626")   # botões comuns (cinza neutro)
const BUTTON_HOVER := Color("#3c3c3c")
const BUTTON_DOWN := Color("#121212")

# --- Cenário (usado pelo gerador do fundo e pelas decorações) ---
const STONE_DARK := Color("#100d0c")
const STONE_MID := Color("#1a1614")
const STONE_LIGHT := Color("#26201d")
const STONE_HI := Color("#382f29")
const MORTAR := Color("#070505")
const COIN := Color("#a8822c")
const COIN_DARK := Color("#5a421a")
const BONE := Color("#9c9078")
const BLOOD := Color("#4a0a0c")
const WAX := Color("#a89c80")
const FLAME := Color("#e0832a")
const FLAME_HI := Color("#f2c25a")


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
