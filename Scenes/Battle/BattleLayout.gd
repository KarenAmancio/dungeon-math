# BattleLayout.gd
# TODAS as posições e tamanhos da cena de batalha, num lugar só.
# Coordenadas em pixels INTERNOS (tela de 640x360, que o PixelViewport amplia ×3
# para 1920x1080). Nenhum outro script deve ter número de posição solto.
#
# Mapa (ver mockup aprovado):
#   topo-esq: ? / velas     topo-centro: mão do inimigo     topo-dir: retrato + HP do inimigo
#   centro: zonas do inimigo, FIM DO TURNO, zonas do jogador, mão do jogador
#   baixo-esq: retrato + HP do jogador     dir: deck e, embaixo dele, o relatório

class_name BattleLayout
extends RefCounted

const INTERNAL_SIZE := Vector2i(640, 360)
const SCALE := 3                              # internos -> tela (1920x1080)

# --- Slots e zonas ---
const SLOT_SIZE := Vector2(36, 56)
const SLOT_PITCH := 40.0                      # distância entre slots
const ATTACK_SLOTS := 5
const DEFENSE_SLOTS := 4
const ATTACK_X := 132.0                       # x do 1º slot de ataque (canto esq.)
const DEFENSE_X := 352.0                      # x do 1º slot de defesa
const ENEMY_SLOT_Y := 98.0                    # y do topo dos slots do inimigo
const PLAYER_SLOT_Y := 218.0                  # y do topo dos slots do jogador

# --- Botão FIM DO TURNO ---
const END_TURN_RECT := Rect2(250, 168, 140, 22)

# --- Mão ---
const PLAYER_HAND_Y := 326.0                  # centro vertical das cartas da mão
const PLAYER_HAND_STEP := 36.0
const ENEMY_HAND_Y := 20.0
const ENEMY_HAND_STEP := 18.0
const ENEMY_HAND_MAX_WIDTH := 110.0

# --- Retratos e HP ---
const PLAYER_PORTRAIT := Rect2(10, 252, 72, 72)
const PLAYER_HP_BAR := Rect2(5, 328, 82, 16)
const ENEMY_PORTRAIT := Rect2(556, 6, 72, 72)
const ENEMY_HP_BAR := Rect2(551, 82, 82, 16)

# --- Deck e relatório (coluna direita) ---
const DECK_CENTER := Vector2(583, 207)        # centro do deck
const DECK_SIZE := Vector2(46, 62)
const DECK_COUNTER_POS := Vector2(560, 242)
const LOG_RECT := Rect2(524, 264, 114, 92)    # resumo do relatório

# --- Botões do canto ---
const HELP_BUTTON := Rect2(28, 6, 22, 22)
const CANDLES_POS := Vector2(10, 36)


# Converte um Rect2 interno em coordenadas de tela cheia (1920x1080).
static func to_screen(rect: Rect2) -> Rect2:
	return Rect2(rect.position * SCALE, rect.size * SCALE)


# Centro do slot `index` de uma zona.
static func slot_center(first_x: float, top_y: float, index: int) -> Vector2:
	return Vector2(first_x + index * SLOT_PITCH + SLOT_SIZE.x / 2.0, top_y + SLOT_SIZE.y / 2.0)
