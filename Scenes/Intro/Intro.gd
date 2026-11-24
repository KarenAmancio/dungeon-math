# Intro.gd
# Abertura contada em imagens, com o texto surgindo letra por letra (no lugar do vídeo).
# O motor (layouts, zoom, caminhada, digitação, pular) fica em Scenes/Story/StoryScene.gd; aqui só
# estão o id da cena e os passos. A próxima cena (a sala do baú, Trial) fica na tabela FLOW.

extends "res://Scenes/Story/StoryScene.gd"

const ENTERING := "res://Backgrounds/intro/entrando_dungeon.png"
const CORRIDOR_LONG := "res://Backgrounds/intro/corredor_dungeon.png"
const TOWN_BEFORE := "res://Backgrounds/intro/cidade_antes.png"
const ARKHON_HALL := "res://Backgrounds/intro/arkhon_dungeon.png"
const TOWN_ATTACK := "res://Backgrounds/intro/cidade_ataque.png"
const TOWN_AFTER := "res://Backgrounds/intro/cidade_depois.png"
const C_TORCHES := "res://Backgrounds/intro/corredor_tochas.png"
const C_CELL := "res://Backgrounds/intro/corredor_cela.png"
const C_DARK := "res://Backgrounds/intro/corredor_escuro.png"

const CAYO := "[color=#ffe066]CAYO[/color]"

# O Cayo anda pelo corredor (cada espaço mostra o corredor mais perto, SEM zoom: é só a foto
# trocando) e, entre um trecho e outro, as lembranças do vilarejo aparecem no quadro.
const STEPS := [
	{"layout": "card", "text": "E se matemática fosse uma [color=#ffe066]arma[/color]?"},
	{"layout": "card", "text": "E se você precisasse resolver uma conta para [color=#ffe066]sobreviver[/color]?"},
	{"layout": "full", "image": ENTERING, "text": CAYO + ": Eu não deveria estar aqui..."},
	{"layout": "frame", "image": TOWN_BEFORE, "zoom": 1.1, "text": "- Antes tudo era bom no vilarejo, mas algo [color=#ff3b3b]terrível[/color] aconteceu."},
	{"layout": "full", "image": CORRIDOR_LONG, "text": CAYO + ": Foi no dia em que ele voltou. Todo mundo lembra do barulho."},
	{"layout": "title", "image": ARKHON_HALL, "zoom": 1.1, "shake": true, "style": "flame", "text": "Arkhon ressurgiu de sua masmorra"},
	{"layout": "frame", "image": TOWN_ATTACK, "zoom": 1.1, "text": "- E com fúria roubou a essência numérica do vilarejo, levou a [color=#ffe066]matemática[/color]."},
	{"layout": "full", "image": C_TORCHES, "text": CAYO + ": Ontem três vizinhos tentaram dividir um pão e quase saiu briga. Ninguém mais sabe fazer conta."},
	{"layout": "frame", "image": TOWN_AFTER, "zoom": 1.1, "text": "- E sem ela... A vida em paz [color=#ff3b3b]colapsou[/color]."},
	{"layout": "full", "image": C_CELL, "text": CAYO + ": Sorte minha ser o único que lembra o que é [color=#ffe066]matemática[/color] mesmo."},
	{"layout": "full", "image": C_DARK, "text": CAYO + ": Só para garantir... sete vezes oito, cinquenta e seis. Ufa, ainda está tudo aqui."},
]


func _init() -> void:
	scene_id = "intro"


func _steps() -> Array:
	return STEPS
