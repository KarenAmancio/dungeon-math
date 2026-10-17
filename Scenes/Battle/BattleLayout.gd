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
# O fundo (Backgrounds/battle_bg.png) já traz os slots e as barras desenhados; estes números
# foram medidos NA IMAGEM (por isso o espaçamento não é perfeitamente regular).
const SLOT_SIZE := Vector2(36, 56)
const ENEMY_ROW_Y := 128.0                    # centro vertical dos slots do inimigo
const PLAYER_ROW_Y := 254.0                   # centro vertical dos slots do jogador

# Centro X de cada slot, por zona (5 de ataque + 4 de defesa em cada fileira).
const SLOT_X := {
	"EnemyAttackZone": [151.0, 193.0, 233.0, 271.0, 308.0],
	"EnemyDefenseZone": [357.0, 395.0, 435.0, 476.0],
	"PlayerAtackZone": [144.0, 184.0, 223.0, 264.0, 305.0],
	"PlayerDefenseZone": [353.0, 395.0, 438.0, 483.0],
}

# Barras de título desenhadas no fundo (o nome da zona e a conta ao vivo ficam em cima delas).
const ZONE_BAR := {
	"EnemyAttackZone": Rect2(157, 75, 148, 18),
	"EnemyDefenseZone": Rect2(356, 75, 132, 18),
	"PlayerAtackZone": Rect2(153, 200, 151, 20),
	"PlayerDefenseZone": Rect2(353, 200, 140, 20),
}

# --- Botão FIM DO TURNO (a placa está desenhada no fundo) ---
const END_TURN_RECT := Rect2(256, 168, 120, 24)

# --- Mão ---
const PLAYER_HAND_Y := 326.0                  # centro vertical das cartas da mão
const PLAYER_HAND_STEP := 41.0                # carta 38 + 3 de respiro
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
const PAUSE_BUTTON := Rect2(4, 6, 22, 22)
const HELP_BUTTON := Rect2(28, 6, 22, 22)


# Converte um Rect2 interno em coordenadas de tela cheia (1920x1080).
static func to_screen(rect: Rect2) -> Rect2:
	return Rect2(rect.position * SCALE, rect.size * SCALE)


# Centro (em pixels internos) do slot `index` de uma zona.
static func slot_center(zone_name: String, index: int) -> Vector2:
	var y := ENEMY_ROW_Y if zone_name.begins_with("Enemy") else PLAYER_ROW_Y
	return Vector2(SLOT_X[zone_name][index], y)
