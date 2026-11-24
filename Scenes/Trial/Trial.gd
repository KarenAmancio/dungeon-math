# Trial.gd
# Depois do corredor da intro: a porta das 5 chaves (a inscrição dá a dica), a sala do baú (ele ganha
# uma carta) e mais um pedaço de corredor até o Gribnok.
# Cada chave ERRADA machuca 5 de vida (acumulativo): a vida perdida é tirada do começo da PRIMEIRA
# batalha (GameManager.hp_penalty). A pergunta usa a janela provisória do StoryScene (dá pra trocar
# por imagens depois). A próxima cena (o diálogo com o Gribnok) fica na tabela FLOW.

extends "res://Scenes/Story/StoryScene.gd"

const KEY_DOOR := "res://Backgrounds/intro/porta_chaves.png"
const ROOM := "res://Backgrounds/intro/sala_bau.png"
const CHEST_CLOSED := "res://Backgrounds/intro/bau_fechado.png"
const CHEST_OPEN := "res://Backgrounds/intro/bau_aberto.png"
const C_CURVE := "res://Backgrounds/intro/corredor_curva.png"
const C_RUBBLE := "res://Backgrounds/intro/corredor_escombros.png"
const C_GATE_HALL := "res://Backgrounds/intro/corredor_grade.png"
const C_GATE := "res://Backgrounds/intro/corredor_portao.png"
const GRIBNOK_DOOR := "res://Backgrounds/dialogue_bg.png"

const CAYO := "[color=#ffe066]CAYO[/color]"

# A dica fica gravada na porta: 3 + 3 - 2 = 4  ->  chave 4
const STEPS := [
	{"layout": "full", "image": KEY_DOOR, "text": "- Uma porta trancada e cinco chaves na parede. Na madeira, uma inscrição: \"A chave certa vale [color=#ffe066]3 + 3 - 2[/color].\""},
	{"layout": "full", "image": KEY_DOOR, "text": CAYO + ": Só uma chave serve, e as outras não parecem simpáticas. Pelo menos a conta é fácil.",
		"choice": {
			"prompt": "Qual chave?",
			"row_width": 80,
			"options": [
				{"text": "Chave 1", "penalty": 5, "reply": "- ZAP! A chave estava eletrificada. (-5 de vida na luta)"},
				{"text": "Chave 2", "penalty": 5, "reply": "- Dardos saem da parede e acertam o Cayo. (-5 de vida na luta)"},
				{"text": "Chave 3", "penalty": 5, "reply": "- Um gás verde sobe da fechadura. O Cayo tosse. (-5 de vida na luta)"},
				{"text": "Chave 4", "correct": true},
				{"text": "Chave 5", "penalty": 5, "reply": "- A chave pega fogo na mão dele. (-5 de vida na luta)"},
			],
		}},
	{"layout": "full", "image": ROOM, "text": "- A chave gira e a porta se abre. Do outro lado, uma sala pequena iluminada por tochas. No canto, um baú."},
	{"layout": "full", "image": CHEST_CLOSED, "zoom": 1.04, "text": CAYO + ": Um baú numa dungeon. Isso nunca dá errado."},
	{"layout": "full", "image": CHEST_OPEN, "zoom": 1.04, "text": "- Ele levanta a tampa devagar. Dentro, moedas e uma carta nova: [color=#ffe066]×2[/color]. Ela entra no baralho do Cayo."},
	{"layout": "full", "image": CHEST_OPEN, "zoom": 1.04, "text": CAYO + ": Uma carta de graça num baú de dungeon. Estou desconfiado."},
	{"layout": "full", "image": C_CURVE, "text": "- Ele guarda a carta e segue pelo corredor, que faz uma curva."},
	{"layout": "full", "image": C_RUBBLE, "text": CAYO + ": Esse lugar está caindo aos pedaços. Parece o meu bolso."},
	{"layout": "full", "image": C_GATE_HALL, "text": CAYO + ": Um portão no fim. E uma luz atrás dele."},
	{"layout": "full", "image": C_GATE, "text": CAYO + ": Tem alguém aí dentro. Alguém que ronca. Ou rosna. Ou as duas coisas."},
	{"layout": "full", "image": GRIBNOK_DOOR, "text": "- O portão se abre. Lá dentro, o Gribnok está esperando."},
]


func _init() -> void:
	scene_id = "trial"


func _steps() -> Array:
	return STEPS
