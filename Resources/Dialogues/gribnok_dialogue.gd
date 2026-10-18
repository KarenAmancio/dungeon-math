# gribnok_dialogue.gd
# Diálogo Cayo x Gribnok (8 cenas) — GERADO do documento "Cayo x Gribnok — Diálogo com ramificações".
# Edite as falas aqui à vontade; a cena Dialogue só lê esta estrutura.
#
# Cada cena:
#   "entry":   falas que abrem a cena (o Gribnok fala sozinho antes de o Cayo escolher)
#   "options": as 3 respostas do Cayo (A = base, B e C = variações). "label" é o que aparece no menu,
#              "lines" é o que acontece depois de escolher (começa pela fala do Cayo) e "flag" é
#              o que o jogo guarda dessa escolha ("" = nada).
# Cada fala é [quem, texto, se_flag]: quem = "GRIBNOK", "CAYO" ou "" (ação/narração em itálico);
# se_flag = só aparece quando essa flag estiver ativa ("" = sempre).

class_name GribnokDialogue
extends RefCounted

const SCENES: Array = [
	{
		"id": 1,
		"title": "A abertura",
		"entry": [
			["", "Dungeon escura. Tochas. Uma porta de ferro enorme. GRIBNOK parado na frente, de braços cruzados, peito estufado. CAYO entra. O chão range.", ""],
			["GRIBNOK", "PARADO! Mais um passo e eu faço coisas terríveis. Eu sei fazer várias. Já fiz uma ontem.", ""],
		],
		"options": [
			{
				"key": "A",
				"label": "Eu só quero passar pela porta.",
				"flag": "",
				"lines": [
					["CAYO", "Eu só quero passar pela porta.", ""],
					["GRIBNOK", "Ha! Passar. NINGUÉM passa. Está escrito em algum lugar. (pausa) Não lembro onde, mas está.", ""],
					["CAYO", "(Ele está muito orgulhoso da própria frase.)", ""],
				],
			},
			{
				"key": "B",
				"label": "Que coisas terríveis? Me dá um exemplo.",
				"flag": "copo_cheio",
				"lines": [
					["CAYO", "Que coisas terríveis? Me dá um exemplo.", ""],
					["GRIBNOK", "Exemplo? Eu não entrego meus métodos assim, de graça! (pausa) Tá. Ontem eu derrubei um copo. De propósito. Estava CHEIO.", ""],
					["CAYO", "(Ele está tremendo de orgulho.)", ""],
				],
			},
			{
				"key": "C",
				"label": "(finge tremer) Não, por favor! Eu sou só uma criança!",
				"flag": "medo_fingido",
				"lines": [
					["CAYO", "(finge tremer) Não, por favor! Eu sou só uma criança!", ""],
					["GRIBNOK", "ISSO! É assim que se faz! Finalmente alguém que respeita o protocolo! (pro nada) Anotem aí: funcionou de primeira.", ""],
					["CAYO", "(Não tem ninguém anotando.)", ""],
				],
			},
		],
	},
	{
		"id": 2,
		"title": "Quem é você?",
		"entry": [
			["GRIBNOK", "(olhando o próprio punho) Foi um dia difícil, aquele copo. Mas eu aguentei.", "copo_cheio"],
			["GRIBNOK", "(estufando o peito) Pode perguntar uma coisa, tremedeira. Eu sou generoso com quem respeita.", "medo_fingido"],
		],
		"options": [
			{
				"key": "A",
				"label": "Quem é você?",
				"flag": "",
				"lines": [
					["CAYO", "Quem é você?", ""],
					["GRIBNOK", "GRIBNOK! O Terror das Sete Masmorras! Quatro, na verdade. As outras três estão em obras. Mas eu terrorizo elas mesmo assim, de longe.", ""],
				],
			},
			{
				"key": "B",
				"label": "Sete masmorras? Então você viaja muito.",
				"flag": "viajante",
				"lines": [
					["CAYO", "Sete masmorras? Então você viaja muito.", ""],
					["GRIBNOK", "Viajo! Constantemente! Todo dia eu vou daqui até aquela tocha. E volto. (pausa) Hoje já fui duas vezes.", ""],
					["CAYO", "(Eram quatro metros.)", ""],
				],
			},
			{
				"key": "C",
				"label": "Nunca ouvi falar de você.",
				"flag": "medalha",
				"lines": [
					["CAYO", "Nunca ouvi falar de você.", ""],
					["GRIBNOK", "IMPOSSÍVEL! Eu sou famosíssimo! Tenho até medalha!", ""],
					["CAYO", "(A medalha diz \"MELHOR GUARDIÃO DO MÊS\".)", ""],
					["GRIBNOK", "Eu sei o que você vai perguntar. Quem deu? O departamento.", ""],
					["CAYO", "Que departamento?", ""],
					["GRIBNOK", "O meu.", ""],
					["CAYO", "E quantas pessoas trabalham nele?", ""],
					["GRIBNOK", "...Uma. Mas é MUITO dedicado.", ""],
				],
			},
		],
	},
	{
		"id": 3,
		"title": "Por que ele guarda a porta",
		"entry": [
			["CAYO", "(Ele tem um crachá escrito \"GUARDIÃO - NÃO MORDE\".)", ""],
			["GRIBNOK", "Sete masmorras não se terrorizam sozinhas. Isso exige logística.", "viajante"],
			["GRIBNOK", "(polindo a medalha com a manga) Melhor do mês. Do ano, na verdade. O departamento ainda está deliberando.", "medalha"],
		],
		"options": [
			{
				"key": "A",
				"label": "Por que você tá guardando essa porta?",
				"flag": "",
				"lines": [
					["CAYO", "Por que você tá guardando essa porta?", ""],
					["GRIBNOK", "Porque EU sou o mais temido, o mais forte e o mais esperto da dungeon. Ninguém me escolheu pra isso. Eu me escolhi sozinho. O chefe nem sabe ainda, mas vai adorar.", ""],
					["CAYO", "(Ele se promoveu sozinho.)", ""],
				],
			},
			{
				"key": "B",
				"label": "Você trabalha pro Arkhon?",
				"flag": "carta_arkhon",
				"lines": [
					["CAYO", "Você trabalha pro Arkhon?", ""],
					["GRIBNOK", "ARKHON! O Grande! O Devorador de Números! (tom reverente) Nós somos praticamente sócios. Ele até me escreveu. (tira um papel amassado do cinto) \"Prezado Ocupante.\" Está vendo? OCUPANTE! Eu ocupo o cargo!", ""],
					["CAYO", "(Tem um carimbo vermelho no papel. Ele não parece ter lido.)", ""],
				],
			},
			{
				"key": "C",
				"label": "O Arkhon roubou a matemática da minha vila. Todo mundo esqueceu como contar.",
				"flag": "gribnok_sabe_contar",
				"lines": [
					["CAYO", "O Arkhon roubou a matemática da minha vila. Todo mundo esqueceu como contar.", ""],
					["GRIBNOK", "Eu SEI! Foi uma OBRA-PRIMA! Agora ninguém sabe quantos tem de nada! (pausa) Eu, claro, sei contar. Posso provar. Dois mais dois? (olha pro teto) ...Bastante.", ""],
					["CAYO", "(Lá em casa meu tio vendeu \"uns peixes\" por \"umas moedas\". Ninguém reclamou.)", ""],
				],
			},
		],
	},
	{
		"id": 4,
		"title": "A porta e a chave",
		"entry": [
			["GRIBNOK", "(guardando o papel amassado) Isso é confidencial. Entre sócios.", "carta_arkhon"],
			["GRIBNOK", "(contando nos dedos, pra provar) ...E isso é só o começo. Eu tenho muitos dedos.", "gribnok_sabe_contar"],
		],
		"options": [
			{
				"key": "A",
				"label": "E se eu empurrar a porta?",
				"flag": "",
				"lines": [
					["CAYO", "E se eu empurrar a porta?", ""],
					["GRIBNOK", "Impossível! Eu tranquei com a Chave Suprema, forjada no fogo do... (olha pro chão) ...do fogão. E escondi num lugar que NINGUÉM jamais vai descobrir. (dá uma batidinha no bolso do peito. Uma chave brilha lá dentro) Está num lugar secreto. Secretíssimo.", ""],
				],
			},
			{
				"key": "B",
				"label": "(tenta empurrar a porta. Nada acontece.)",
				"flag": "porta_puxe",
				"lines": [
					["CAYO", "(tenta empurrar a porta. Nada acontece.)", ""],
					["GRIBNOK", "NÃO ABRE! Eu SEI que não abre! Eu empurrei essa porta a semana inteira!", ""],
					["CAYO", "(Em cima da porta tem uma placa grande: \"PUXE\".)", ""],
				],
			},
			{
				"key": "C",
				"label": "E onde você escondeu essa chave?",
				"flag": "bolso_revelado",
				"lines": [
					["CAYO", "E onde você escondeu essa chave?", ""],
					["GRIBNOK", "Num lugar que você nunca vai adivinhar. (Cayo olha pro bolso. Gribnok cobre o bolso com as duas mãos.) NÃO OLHA PRO MEU BOLSO!", ""],
					["CAYO", "(Ele acabou de me contar.)", ""],
				],
			},
		],
	},
	{
		"id": 5,
		"title": "Pegar a chave",
		"entry": [
			["CAYO", "(A chave está no bolso. O bolso está na frente de todo mundo.)", ""],
			["GRIBNOK", "(batendo na porta com a mão aberta) Essa porta aguenta tudo. Empurrei de manhã, de tarde, de noite. É resistente.", "porta_puxe"],
			["GRIBNOK", "Você olhou pro bolso. Eu SEI que olhou. (vira o corpo pro outro lado. O bolso continua à mostra.) Pronto. Agora ninguém acha.", "bolso_revelado"],
		],
		"options": [
			{
				"key": "A",
				"label": "Tá, mas e se eu pegar a chave?",
				"flag": "",
				"lines": [
					["CAYO", "Tá, mas e se eu pegar a chave?", ""],
					["GRIBNOK", "Então você vai ter que passar por MIM. E eu sou INVENCÍVEL. Meu plano é infalível: se alguém me atacar, eu simplesmente não perco.", ""],
				],
			},
			{
				"key": "B",
				"label": "E se eu só pedir por favor?",
				"flag": "educacao",
				"lines": [
					["CAYO", "E se eu só pedir por favor?", ""],
					["GRIBNOK", "...Por favor? (pausa longa) Essa opção eu nem ia deixar disponível. (se recompõe) NÃO! Mas foi um bom golpe. Muito sujo. Anotado.", ""],
				],
			},
			{
				"key": "C",
				"label": "(joga uma pedrinha no chão)",
				"flag": "pedrinha",
				"lines": [
					["CAYO", "(joga uma pedrinha no chão)", ""],
					["GRIBNOK", "(pula de susto, os dois braços pro alto) AAH! (pausa. Se recompõe.) Tática de defesa. Eu estava testando meus reflexos. Funcionaram.", ""],
					["CAYO", "(Ele está suando. A pedrinha mal quicou.)", ""],
					["GRIBNOK", "(ajeitando a medalha) Isso vai constar no relatório do departamento.", "medalha"],
				],
			},
		],
	},
	{
		"id": 6,
		"title": "Os planos infalíveis",
		"entry": [
			["CAYO", "(Esse plano tem alguns problemas.)", ""],
			["GRIBNOK", "(ajeitando o crachá) Não pense que o \"por favor\" me amoleceu. Eu fiquei em alerta.", "educacao"],
			["GRIBNOK", "(olhando a pedrinha de lado) Aquela pedra tinha intenção. Eu senti.", "pedrinha"],
		],
		"options": [
			{
				"key": "A",
				"label": "Isso não é um plano, é só uma frase.",
				"flag": "",
				"lines": [
					["CAYO", "Isso não é um plano, é só uma frase.", ""],
					["GRIBNOK", "Eu tenho três planos! O primeiro é esse. O segundo é o primeiro, mas mais alto. O terceiro eu esqueci, mas era o melhor.", ""],
				],
			},
			{
				"key": "B",
				"label": "Qual era o terceiro plano?",
				"flag": "terceiro_plano",
				"lines": [
					["CAYO", "Qual era o terceiro plano?", ""],
					["GRIBNOK", "Eu... ESQUECI. Mas envolvia fogo. E uma tubaína. Eu lembro bem da tubaína.", ""],
					["CAYO", "(Ele fecha os olhos com muita força. Não vem nada.)", ""],
				],
			},
			{
				"key": "C",
				"label": "Quantos planos você tem mesmo?",
				"flag": "contagem_errada",
				"lines": [
					["CAYO", "Quantos planos você tem mesmo?", ""],
					["GRIBNOK", "Três! (levanta quatro dedos) Três. (conta de novo, levanta dois) ...Três. É que o número depende do dia.", ""],
					["CAYO", "(Na vila é igual. Ninguém acerta quanto é nada.)", ""],
				],
			},
		],
	},
	{
		"id": 7,
		"title": "O desafio",
		"entry": [
			["CAYO", "(Ele conta devagar, mexendo os dedos.)", ""],
			["GRIBNOK", "(ainda tentando lembrar) Fogo... tubaína... aquilo era um pato? Não. Pato é o plano quatro.", "terceiro_plano"],
			["GRIBNOK", "(recontando nos dedos) Três. Ou cinco. Não importa, o plano é bom!", "contagem_errada"],
		],
		"options": [
			{
				"key": "A",
				"label": "Então como a gente resolve isso?",
				"flag": "",
				"lines": [
					["CAYO", "Então como a gente resolve isso?", ""],
					["GRIBNOK", "Como todo grande guerreiro resolve: com um duelo de cartas! Eu sou o MELHOR jogador de cartas dessa masmorra. Já ganhei... (conta nos dedos) ...muitas vezes. Mais que dez. Talvez mais que doze.", ""],
					["", "(Ele tira um baralho do cinto. Uma carta cai. Ele finge que não viu.)", ""],
				],
			},
			{
				"key": "B",
				"label": "Cartas? Eu nem sei jogar.",
				"flag": "regras_gribnok",
				"lines": [
					["CAYO", "Cartas? Eu nem sei jogar.", ""],
					["GRIBNOK", "Melhor ainda! Vou te ensinar rapidinho, que já tá chegando minha pausa pro café. Regra um: eu ganho. Regra dois: veja regra um. (pausa) Tem uma regra três, mas é segredo. Ou eu esqueci.", ""],
					["", "(Ele tira um baralho do cinto. Uma carta cai. Ele finge que não viu.)", ""],
				],
			},
			{
				"key": "C",
				"label": "(pega a carta que caiu) Você derrubou uma.",
				"flag": "carta_extra",
				"lines": [
					["CAYO", "(pega a carta que caiu) Você derrubou uma.", ""],
					["GRIBNOK", "Essa não é minha! É decoração! (arranca a carta da mão do Cayo)", ""],
					["CAYO", "(Era um \"9999\". Escrito à caneta.)", ""],
					["GRIBNOK", "(guardando a carta no cinto) Enfim, ao que interessa: um duelo de cartas! Eu sou o MELHOR jogador dessa masmorra. Já ganhei mais que dez. Talvez mais que doze.", ""],
				],
			},
		],
	},
	{
		"id": 8,
		"title": "Aceitar o duelo e entrar na batalha",
		"entry": [
			["GRIBNOK", "Você já sabe as regras: eu ganho. O resto é detalhe.", "regras_gribnok"],
			["GRIBNOK", "(batendo no cinto, onde a carta sumiu) Eu não tenho carta extra nenhuma. Isso é difamação.", "carta_extra"],
		],
		"options": [
			{
				"key": "A",
				"label": "Eu aceito.",
				"flag": "",
				"lines": [
					["CAYO", "Eu aceito.", ""],
					["GRIBNOK", "ACEITOU! HAHAHA! Você caiu direitinho na armadilha! (pausa) Que é... o duelo. Que eu mesmo propus. Mas foi MUITO esperto da minha parte.", ""],
					["", "(GRIBNOK embaralha. As cartas voam pelo ar, uma sai voando pelo corredor. Ele finge que era de propósito.)", ""],
					["GRIBNOK", "Prepare-se pra perder, pequeno herói! Eu NUNCA erro uma conta! (pausa) Quase nunca.", ""],
				],
			},
			{
				"key": "B",
				"label": "Eu aceito. Se eu ganhar, você me dá a chave.",
				"flag": "aposta_chave",
				"lines": [
					["CAYO", "Eu aceito. Se eu ganhar, você me dá a chave.", ""],
					["GRIBNOK", "A chave?! ...Tá. Mas se EU ganhar... (pensa) ...você fica aqui e me ajuda a guardar a porta. Pra sempre. De quinta a quinta.", ""],
					["", "(GRIBNOK embaralha. As cartas voam pelo ar.)", ""],
					["GRIBNOK", "Prepare-se pra perder, pequeno herói! Eu NUNCA erro uma conta! (pausa) Quase nunca.", ""],
				],
			},
			{
				"key": "C",
				"label": "Eu aceito. E eu não vou perder.",
				"flag": "",
				"lines": [
					["CAYO", "Eu aceito. E eu não vou perder.", ""],
					["GRIBNOK", "...Você é confiante. Isso é ruim. (pausa) Eu não devia estar aqui no começo da masmorra. É pressão demais pra um guardião de porta.", ""],
					["", "(GRIBNOK embaralha. As cartas voam pelo ar.)", ""],
					["GRIBNOK", "Prepare-se pra perder, pequeno herói! Eu NUNCA erro uma conta! (pausa) Quase nunca.", ""],
				],
			},
		],
	},
]
