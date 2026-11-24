# skeleton_dialogue.gd
# Diálogo com o ESQUELETO, o guardião do último corredor (nível 2). Mesmo formato do
# gribnok_dialogue.gd:
#   "entry":   falas que abrem a cena;  "options": as respostas do Cayo ("label", "flag", "lines")
#   cada fala é [quem, texto, se_flag]  (quem = "ESQUELETO", "CAYO" ou "" pra ação).
# Tom: educado, cansado e seco, com piadas de osso. Ainda não tem rosto próprio (o Dialogue só
# mostra o rosto do Cayo nas falas dele); quando a arte do esqueleto existir é só encaixar.

class_name SkeletonDialogue
extends RefCounted

const SCENES: Array = [
	{
		"id": 1,
		"title": "O guardião do corredor",
		"entry": [
			["", "No fim do corredor, um portão de ferro. Na frente dele, um ESQUELETO de capuz embaralha um leque de cartas sem pressa.", ""],
			["ESQUELETO", "Então foi você que derrubou o Gribnok. Eu ouvi a gritaria daqui. Ele sempre grita quando perde.", ""],
			["ESQUELETO", "Sou o Guardião do Último Corredor. Faz trezentos anos que ninguém passa por mim. Em minha defesa, ninguém nunca tentou.", ""],
			["ESQUELETO", "O Arkhon me disse: \"Conte tudo o que passar.\" Eu conto. Tenho tempo. Tenho muito tempo.", ""],
			["ESQUELETO", "(a mandíbula cai no chão; ele recoloca) ...Desculpe. É a articulação.", ""],
		],
		"options": [
			{
				"key": "A",
				"label": "Você é bem educado para um esqueleto.",
				"flag": "skel_educado",
				"lines": [
					["CAYO", "Você é bem educado para um esqueleto.", ""],
					["ESQUELETO", "Obrigado. Faltam-me músculos, mas nunca modos.", ""],
					["CAYO", "(Ele ajeitou o capuz, lisonjeado.)", ""],
				],
			},
			{
				"key": "B",
				"label": "Sai da frente.",
				"flag": "",
				"lines": [
					["CAYO", "Sai da frente.", ""],
					["ESQUELETO", "Não posso. É a minha função. Ossos precisam de propósito, senão ficam só... ali.", ""],
					["CAYO", "(Ele disse isso com muita tristeza para quem não tem olhos.)", ""],
				],
			},
			{
				"key": "C",
				"label": "(olha o portão)",
				"flag": "",
				"lines": [
					["CAYO", "(olha o portão)", ""],
					["ESQUELETO", "Esse portão não abre com chave. Abre com contas. E as contas passam por mim.", ""],
					["CAYO", "(Ele disse \"contas\" olhando direto para o meu cérebro.)", ""],
				],
			},
		],
	},
	{
		"id": 2,
		"title": "As regras do último corredor",
		"entry": [
			["ESQUELETO", "Regras. Eu começo, tenho mais vida e erro muito pouco. Não é maldade. É que eu já vi todas as jogadas.", ""],
			["ESQUELETO", "Minha armadura de ossos segura o primeiro golpe. Escudo de família. Passou de pai para filho. Na verdade, de osso para osso.", ""],
			["ESQUELETO", "E se eu ficar com pouca vida, eu preparo meu Golpe Final. Quando eu terminar... é bom você ter uma defesa.", ""],
			["ESQUELETO", "Ah, e as cartas minhas com o numerozinho em cima, as elevadas? Se você destruir uma, ela vira sua. É uma regra ruim. Eu sei. Eu não a escrevi.", ""],
			["ESQUELETO", "Obrigado por perguntar sobre a minha saúde. Ninguém pergunta.", "skel_educado"],
		],
		"options": [
			{
				"key": "A",
				"label": "Eu aceito.",
				"flag": "",
				"lines": [
					["CAYO", "Eu aceito.", ""],
					["ESQUELETO", "Que bom. Eu detesto convencer as pessoas. Dá muito trabalho sem pulmões.", ""],
					["ESQUELETO", "Que comece a contagem, Cayo. Eu já contei até o fim uma vez. Foi cansativo.", ""],
				],
			},
			{
				"key": "B",
				"label": "Você tem alguma fraqueza?",
				"flag": "",
				"lines": [
					["CAYO", "Você tem alguma fraqueza?", ""],
					["ESQUELETO", "Cócegas, nenhuma. Mas eu perco a cabeça com facilidade. É literal.", ""],
					["ESQUELETO", "Que comece a contagem, Cayo.", ""],
				],
			},
			{
				"key": "C",
				"label": "Vamos acabar logo com isso.",
				"flag": "",
				"lines": [
					["CAYO", "Vamos acabar logo com isso.", ""],
					["ESQUELETO", "Pressa. Os vivos sempre têm pressa. Eu tenho a eternidade, e ainda assim estou atrasado.", ""],
					["ESQUELETO", "Que comece a contagem, Cayo.", ""],
				],
			},
		],
	},
]
