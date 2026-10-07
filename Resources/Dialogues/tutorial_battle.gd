# tutorial_battle.gd
# Textos do tutorial da batalha e da tela "Como jogar".
# Edite aqui à vontade: a lógica não depende do conteúdo dos textos.
#
# Campos de cada passo em STEPS:
#   "title":         título do balão
#   "text":          texto do balão
#   "target":        área da tela que fica destacada. Valores aceitos:
#                    hp_bars | hand_area | deck | player_attack |
#                    player_defense | player_field | confirm | "" (nada destacado)
#   "allow":         o que o jogador pode clicar durante o passo:
#                    "" (nada, só Próximo/Pular) | "deck" | "confirm"
#   "example":       (opcional) cartas de um exemplo de conta. A conta é calculada
#                    pelo BattleMath, então o resultado nunca fica errado.
#   "example_label": (opcional) nome do total no exemplo, ex.: "Ataque total"

class_name TutorialBattleText
extends RefCounted

const STEPS := [
	{
		"title": "OBJETIVO",
		"text": "Zere o HP do Gribnok antes que ele zere o seu! Cada lado começa com 30 de HP, e as barras ficam aqui no topo.",
		"target": "hp_bars",
		"allow": "",
	},
	{
		"title": "AS CARTAS",
		"text": "As cartas são números e operações: +3 soma, -5 subtrai e ×2 multiplica. A cor mostra o tipo: verde-água é soma, vermelho é subtração e roxo é multiplicação.",
		"target": "hand_area",
		"allow": "",
	},
	{
		"title": "COMPRAR CARTAS",
		"text": "Clique no baralho para comprar uma carta. Você pode comprar até 2 cartas por turno. Experimente!",
		"target": "deck",
		"allow": "deck",
	},
	{
		"title": "ATAQUE",
		"text": "Arraste cartas para a zona de ATAQUE. A conta é feita da esquerda para a direita, sem prioridade de operação: cada carta é aplicada ao total que veio antes dela.",
		"target": "player_attack",
		"allow": "",
		"example": [
			{"operation": "add", "value": 3},
			{"operation": "multiply", "value": 2},
			{"operation": "add", "value": -1},
		],
		"example_label": "Ataque total",
	},
	{
		"title": "DEFESA",
		"text": "Na zona de DEFESA as cartas também são somadas, e o total vira um escudo que absorve o dano que chega. O número ao lado do escudo é a sua defesa atual.",
		"target": "player_defense",
		"allow": "",
	},
	{
		"title": "COMO O DANO FUNCIONA",
		"text": "Quando alguém é atacado, primeiro a DEFESA absorve o que puder. Depois, o que sobrar come as cartas de ATAQUE, da direita para a esquerda, dígito por dígito. Por fim, o que ainda sobrar tira HP.",
		"target": "player_field",
		"allow": "",
	},
	{
		"title": "CONFIRMAR JOGADA",
		"text": "Quando terminar de montar suas zonas, clique em CONFIRMAR JOGADA. Você ataca primeiro; depois o Gribnok joga e ataca. Boa sorte!",
		"target": "confirm",
		"allow": "confirm",
	},
]


# Tela "Como jogar" (botão "?").
const HOW_TO_PLAY := {
	"title": "COMO JOGAR",
	"goal_title": "OBJETIVO",
	"goal": "Zere o HP do Gribnok antes que ele zere o seu. Cada lado começa com 30 de HP.",
	"rules_title": "REGRAS",
	"rules": [
		"Compre até 2 cartas por turno clicando no baralho.",
		"Arraste as cartas para o ATAQUE (causa dano) e para a DEFESA (cria um escudo).",
		"A conta de cada zona é feita da esquerda para a direita, sem prioridade de operação.",
		"Ao ser atacado: primeiro a Defesa absorve; depois o que sobrar come as cartas de Ataque, da direita para a esquerda; por fim o resto tira HP.",
		"Clique em CONFIRMAR JOGADA: você ataca, depois o Gribnok joga e ataca.",
	],
	"example_title": "EXEMPLO DE CONTA",
	"example_cards": [
		{"operation": "add", "value": 3},
		{"operation": "multiply", "value": 2},
		{"operation": "add", "value": -1},
	],
	"example_label": "Ataque total",
	"example_note": "Se o inimigo tiver Defesa 4, ele absorve 4 e sobra 1 de dano, que remove 1 dígito das cartas de ataque dele.",
}
