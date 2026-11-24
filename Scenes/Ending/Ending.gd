# Ending.gd
# Final do jogo (depois de vencer o Gribnok II): o Cayo resolve a conta da porta, ouve a voz do
# Arkhon e segue pelo corredor. Termina com "Continua..." e vai para os créditos.
# O motor fica em Scenes/Story/StoryScene.gd; aqui só estão o id da cena e os passos.
# A pergunta da porta (7 × ? = 56) usa uma janela provisória: é só trocar por imagens depois.

extends "res://Scenes/Story/StoryScene.gd"

const DOOR_PUZZLE := "res://Backgrounds/intro/corredor_porta.png"
const CORRIDOR_LONG := "res://Backgrounds/intro/corredor_escuro.png"
const WALK_A := "res://Backgrounds/intro/corredor_tochas.png"
const WALK_B := "res://Backgrounds/intro/corredor_grade.png"

const STEPS := [
	{"layout": "full", "image": DOOR_PUZZLE, "zoom": 1.04, "text": "- O esqueleto desmorona numa pilha de ossos. Atrás dele, uma porta de pedra com uma conta gravada."},
	{"layout": "full", "image": DOOR_PUZZLE, "zoom": 1.04, "text": "[color=#ffe066]CAYO[/color]: Mais uma conta? Ninguém por aqui sabe usar maçaneta?",
		"choice": {
			"prompt": "7 × ? = 56",
			"options": [
				{"text": "6", "reply": "- A porta pensa um pouco e responde: não."},
				{"text": "8", "correct": true},
				{"text": "9", "reply": "- A porta tosse. Tente de novo."},
			],
		}},
	{"layout": "full", "image": DOOR_PUZZLE, "zoom": 1.04, "text": "- A porta se abre com um rangido. Do outro lado, só escuridão."},
	{"layout": "card", "char_time": 0.07, "text": "[color=#ff3b3b]Então ainda restou um que sabe contar.[/color]"},
	{"layout": "card", "char_time": 0.07, "text": "[color=#ff3b3b]Venha, garoto. Eu estava à sua espera.[/color]"},
	{"layout": "full", "image": CORRIDOR_LONG, "zoom": 1.04, "text": "[color=#ffe066]CAYO[/color]: ...Eu devia ter ficado em casa."},
	{"layout": "full", "image": WALK_A, "auto": 3.5},
	{"layout": "full", "image": WALK_B, "auto": 4.0},
	{"layout": "card", "char_time": 0.1, "auto": 4.5, "text": "Continua..."},
]


func _init() -> void:
	scene_id = "ending"


func _steps() -> Array:
	return STEPS
