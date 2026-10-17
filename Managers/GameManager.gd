# GameManager.gd  (Autoload)
# Dono da ORDEM das cenas e do estado que precisa sobreviver entre elas.
#
# REGRA DE OURO: as cenas NÃO sabem qual é a próxima. Quando uma cena termina, ela só avisa:
#
#     GameManager.scene_finished("battle", "won")     # "eu sou a batalha e o resultado foi 'won'"
#
# e o GameManager consulta a tabela FLOW abaixo. Mudar a ordem do jogo = mudar SÓ a tabela FLOW
# (e, se for cena nova, a tabela SCENES). Nenhuma cena precisa ser editada.
#
# Cena ainda inexistente (ex.: Intro e Menu antes da Etapa I) é PULADA com aviso no console,
# seguindo o resultado de SKIP_RESULT, em vez de quebrar.

extends Node

signal scene_changed(scene_id: String)

const QUIT := "quit"           # "próxima cena" especial: fecha o jogo
const START_SCENE := "menu"    # por onde o jogo começa

# id da cena -> arquivo. As marcadas "previsto" ainda não existem.
const SCENES := {
	"intro": "res://Scenes/Intro/Intro.tscn",
	"menu": "res://Scenes/Menu/Menu.tscn",
	"battle": "res://Scenes/Battle/BattleScreen.tscn",
	"credits": "res://Scenes/Credits/Credits.tscn",
	# previsto:
	"dialogue": "res://Scenes/Dialogue/Dialogue.tscn",
	"dungeon": "res://Scenes/Dungeon/Dungeon.tscn",
	"ending": "res://Scenes/Ending/Ending.tscn",
}

# TABELA DE ORDEM:  FLOW[cena que terminou][resultado] = próxima cena
#
#   Menu --play--> Intro --finished--> Battle --won----> Menu
#    |                                  |--retry--> Battle
#    |                                  '--menu---> Menu
#    '--credits--> Credits --finished--> Menu
#
const FLOW := {
	"intro": {"finished": "battle"},
	"menu": {"play": "intro", "credits": "credits", "quit": QUIT},
	"battle": {"won": "menu", "retry": "battle", "menu": "menu", "quit": QUIT},
	"credits": {"finished": "menu"},

	# --- Previsto (descomente/ajuste quando as cenas existirem) -----------------------------
	# Com a Dungeon, o "play" do menu passa a abrir o diálogo e a masmorra, e a batalha
	# vira um evento dentro dela:
	#   "menu":     {"play": "dialogue", ...},
	#   "dialogue": {"finished": "dungeon"},
	#   "dungeon":  {"battle": "battle", "exit": "ending"},
	#   "battle":   {"won": "dungeon", "retry": "battle", "menu": "menu"},
	#   "ending":   {"finished": "credits"},
	#   "credits":  {"finished": "menu"},
}

# Se a cena X não existir (ainda), pula como se ela tivesse terminado com este resultado.
const SKIP_RESULT := {
	"intro": "finished",
	"menu": "play",
	"credits": "finished",
	"dialogue": "finished",
	"dungeon": "exit",
	"ending": "finished",
}

# --- Estado que sobrevive entre cenas (não é salvo em disco ainda) ---
var tutorial_seen: bool = false       # o tutorial da batalha já foi visto?
var last_battle_result: String = ""   # "win" | "lose" | "draw"
var battles_won: int = 0
var battles_lost: int = 0
var current_scene_id: String = ""

var _transition: SceneTransition
var _busy: bool = false               # há uma troca em andamento (fade-out, troca e fade-in)
var _leaving_scene: Node = null       # a cena que está sendo deixada (pra reconhecer cliques duplicados)
var _queued: String = ""              # pedido feito pela cena NOVA enquanto o fade-in ainda rodava


func _ready() -> void:
	_transition = SceneTransition.new()
	add_child(_transition)


# Chamado pela cena Main ao abrir o jogo: a primeira cena "abre" do preto.
func start() -> void:
	_transition.set_black()
	await go_to(START_SCENE)


# ÚNICA porta de saída das cenas: "terminei, com este resultado".
func scene_finished(from_scene: String, result: String = "finished") -> void:
	var next: String = FLOW.get(from_scene, {}).get(result, "")
	if next == "":
		push_warning("GameManager: a cena '%s' terminou com '%s', que não está na tabela FLOW" % [from_scene, result])
		return
	print("GameManager: %s --(%s)--> %s" % [from_scene, result, next])
	await go_to(next)


# Vai para uma cena (com fade em degraus). Cena inexistente é pulada com aviso.
#
# Pedido que chega com uma troca em andamento:
#   - vindo da cena que está SAINDO (duplo clique)  -> ignorado (uma troca só);
#   - vindo da cena NOVA (ex.: Intro sem vídeo que já termina no _ready) -> vai pra fila e
#     roda assim que o fade-in acabar. Sem isso, o jogo ficava preso nessa cena.
func go_to(scene_id: String) -> void:
	if _busy:
		if get_tree().current_scene != _leaving_scene:
			_queued = scene_id
		return
	var target := resolve_scene(scene_id)
	if target == QUIT:
		get_tree().quit()
		return
	if target == "":
		push_error("GameManager: nenhuma cena válida a partir de '%s'" % scene_id)
		return

	_busy = true
	_leaving_scene = get_tree().current_scene
	await _transition.fade_out()
	var err := get_tree().change_scene_to_file(SCENES[target])
	if err != OK:
		push_error("GameManager: falha ao abrir %s (erro %d)" % [SCENES[target], err])
	await get_tree().process_frame
	await get_tree().process_frame     # a cena nova precisa terminar o _ready antes de clarear
	current_scene_id = target
	await _transition.fade_in()
	_busy = false
	scene_changed.emit(target)
	if _queued != "":
		var next := _queued
		_queued = ""
		await go_to(next)


# Resolve o id pedido para uma cena que EXISTE (seguindo SKIP_RESULT quando falta arquivo).
# Devolve QUIT, "" (nada utilizável) ou o id final.
func resolve_scene(scene_id: String) -> String:
	for i in 8:    # trava de segurança contra ciclo de cenas ausentes
		if scene_id == QUIT or scene_id == "":
			return scene_id
		var path: String = SCENES.get(scene_id, "")
		if path != "" and ResourceLoader.exists(path):
			return scene_id
		push_warning("GameManager: a cena '%s' ainda não existe, pulando" % scene_id)
		scene_id = FLOW.get(scene_id, {}).get(SKIP_RESULT.get(scene_id, "finished"), "")
	return ""


# A batalha avisa o resultado final (só registra; quem decide pra onde ir é a tabela FLOW).
func register_battle_result(kind: String) -> void:
	last_battle_result = kind
	if kind == "win":
		battles_won += 1
	else:
		battles_lost += 1
