# Interlude.gd
# Entre o Gribnok e o Esqueleto: o Gribnok entrega a medalha, o Cayo anda pelo corredor, troca a
# medalha por uma carta nova (divisão) com o mercador e chega ao último corredor. A próxima cena
# (o diálogo com o Esqueleto) fica na tabela FLOW.

extends "res://Scenes/Story/StoryScene.gd"

const GRIBNOK_ROOM := "res://Backgrounds/dialogue_bg.png"
const CURVE := "res://Backgrounds/intro/corredor_curva.png"
const CELL := "res://Backgrounds/intro/corredor_cela.png"
const MERCHANT := "res://Backgrounds/intro/mercador.png"
const RUBBLE := "res://Backgrounds/intro/corredor_escombros.png"
const GATE_HALL := "res://Backgrounds/intro/corredor_grade.png"
const SKELETON := "res://Backgrounds/intro/esqueleto.png"

const CAYO := "[color=#ffe066]CAYO[/color]"
const MERCHANT_NAME := "[color=#c78bff]MERCADOR[/color]"

const STEPS := [
	{"layout": "full", "image": GRIBNOK_ROOM, "zoom": 1.04, "text": "- O Gribnok cai sentado no chão. A medalha rola até os pés do Cayo."},
	{"layout": "full", "image": GRIBNOK_ROOM, "zoom": 1.04, "text": "[color=#9ad46b]GRIBNOK[/color]: Fica com ela... Melhor Guardião do Mês. O departamento vai entender. Acho."},
	{"layout": "full", "image": GRIBNOK_ROOM, "zoom": 1.04, "text": CAYO + ": Eu só queria passar pela porta."},
	{"layout": "full", "image": CURVE, "auto": 3.5},
	{"layout": "full", "image": CELL, "text": CAYO + ": Uma medalha de latão. Vale alguma coisa? Provavelmente não."},
	{"layout": "full", "image": MERCHANT, "zoom": 1.04, "text": "- Uma sala acesa por velas. Um lagarto de capuz embaralha cartas atrás de uma mesa."},
	{"layout": "full", "image": MERCHANT, "zoom": 1.04, "text": MERCHANT_NAME + ": Ssss... Uma medalha de Guardião do Mês? Raridade! Troco por uma carta nova. Sem devolução."},
	{"layout": "full", "image": MERCHANT, "zoom": 1.04, "text": MERCHANT_NAME + ": Então, forasteiro? Medalha por carta?",
		"choice": {
			"prompt": "Trocar?",
			"row_width": 130,
			"options": [
				{"text": "Trocar a medalha", "correct": true, "unlock": "div_2"},
				{"text": "Guardar a medalha", "reply": "- " + MERCHANT_NAME + ": Medalha não corta esqueleto, rapaz. Carta corta. Pense melhor."},
			],
		}},
	{"layout": "full", "image": MERCHANT, "zoom": 1.04, "text": "- Carta nova no baralho: [color=#c78bff]÷2[/color]. Arrastada no ataque, ela corta o total pela metade."},
	{"layout": "full", "image": MERCHANT, "zoom": 1.04, "text": MERCHANT_NAME + ": Divisão. Vai precisar, aí na frente tem coisa que não sangra. Ssss..."},
	{"layout": "full", "image": RUBBLE, "auto": 3.5},
	{"layout": "full", "image": GATE_HALL, "text": CAYO + ": O corredor termina num portão. E tem alguém parado no meio."},
	{"layout": "full", "image": SKELETON, "zoom": 1.04, "text": "- Um esqueleto de capuz, com um leque de cartas na mão, abre o braço como quem diz: \"entre\"."},
]


func _init() -> void:
	scene_id = "interlude"


func _steps() -> Array:
	return STEPS
