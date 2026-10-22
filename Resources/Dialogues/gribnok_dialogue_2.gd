# gribnok_dialogue_2.gd
# Diálogo do NÍVEL 2 (a revanche com o Gribnok). Mesmo formato do gribnok_dialogue.gd:
#   "entry":   falas que abrem a cena;  "options": as 3 respostas do Cayo ("label", "flag", "lines")
#   cada fala é [quem, texto, se_flag]  (quem = "GRIBNOK", "CAYO" ou "" pra ação; se_flag = só aparece
#   quando essa flag, de ESTE ou do primeiro diálogo, estiver ativa).
# Tom: o Gribnok continua arrogante e burro por excesso de confiança; agora ele "treinou".

class_name GribnokDialogue2
extends RefCounted

const SCENES: Array = [
	{
		"id": 1,
		"title": "Segunda porta",
		"entry": [
			["", "A porta se abre... e atrás dela tem OUTRA porta, igualzinha. GRIBNOK está na frente, de faixa na cabeça, suando. A faixa diz \"NÍVEL 2\".", ""],
			["GRIBNOK", "Achou que era UMA porta? Eu mandei instalar uma segunda. Chama-se \"redundância\". Aprendi no departamento.", ""],
			["GRIBNOK", "(ajeitando a medalha) Melhor do Trimestre. O departamento está muito orgulhoso.", "medalha"],
			["GRIBNOK", "E nada de \"por favor\" dessa vez, Educado. Eu estou preparado.", "educacao"],
			["GRIBNOK", "E eu já aprendi qual lado da porta se puxa. Mentira. Mas aprendi QUASE.", "porta_puxe"],
		],
		"options": [
			{
				"key": "A",
				"label": "Você nem treinou, né?",
				"flag": "lv2_treino",
				"lines": [
					["CAYO", "Você nem treinou, né?", ""],
					["GRIBNOK", "Treinei! Três semanas! Joguei contra a parede. A parede perdeu... na maioria das vezes.", ""],
					["CAYO", "(A parede não tem mãos.)", ""],
				],
			},
			{
				"key": "B",
				"label": "Tá bom. Vamos logo.",
				"flag": "",
				"lines": [
					["CAYO", "Tá bom. Vamos logo.", ""],
					["GRIBNOK", "Sem enrolação! Gostei. Isso vai constar no relatório do departamento.", ""],
					["CAYO", "(Ele anotou \"sem enrolação\" numa folha amassada.)", ""],
				],
			},
			{
				"key": "C",
				"label": "(olha o bolso dele)",
				"flag": "lv2_bolso",
				"lines": [
					["CAYO", "(olha o bolso dele)", ""],
					["GRIBNOK", "NÃO OLHA! ...Dessa vez a chave está no OUTRO bolso. (olha pro bolso errado)", ""],
					["CAYO", "(Ele se entregou de novo.)", ""],
				],
			},
		],
	},
	{
		"id": 2,
		"title": "O plano de quatro partes",
		"entry": [
			["GRIBNOK", "Regras novas! Eu mesmo mudei. Eu começo, eu tenho mais vida e eu não vou errar quase nada. É por segurança.", ""],
			["GRIBNOK", "Meu plano infalível agora tem QUATRO partes! A primeira é essa. As outras eu vou lembrando no caminho.", ""],
			["GRIBNOK", "Você já viu que eu sei o que significa um menos. E eu não vou me machucar com ele dessa vez.", "lv2_treino"],
		],
		"options": [
			{
				"key": "A",
				"label": "Eu aceito.",
				"flag": "",
				"lines": [
					["CAYO", "Eu aceito.", ""],
					["GRIBNOK", "ACEITOU! HAHAHA! Você caiu na armadilha de novo! (pausa) Que é o duelo. Que eu mesmo propus. Mas dessa vez eu comecei.", ""],
					["GRIBNOK", "Prepare-se pra perder, Cayo! Eu NUNCA erro uma conta! (pausa) Agora erro MENOS ainda.", ""],
				],
			},
			{
				"key": "B",
				"label": "Você começa? Isso não é injusto?",
				"flag": "",
				"lines": [
					["CAYO", "Você começa? Isso não é injusto?", ""],
					["GRIBNOK", "Injusto? É ESTRATÉGIA. Está no manual. (pausa) No manual que eu escrevi ontem.", ""],
					["GRIBNOK", "Prepare-se pra perder, Cayo! Eu NUNCA erro uma conta!", ""],
				],
			},
			{
				"key": "C",
				"label": "Tanto faz. Eu venço de novo.",
				"flag": "",
				"lines": [
					["CAYO", "Tanto faz. Eu venço de novo.", ""],
					["GRIBNOK", "...Você é confiante DEMAIS. Isso me deixa nervoso. (pausa) Mas eu treinei. TREINEI.", ""],
					["GRIBNOK", "Prepare-se pra perder, Cayo! Eu NUNCA erro uma conta!", ""],
				],
			},
		],
	},
]
