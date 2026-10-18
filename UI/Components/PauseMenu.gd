# PauseMenu.gd
# Menu de pausa da batalha (ESC ou botão "II" do canto): pausa a árvore inteira
# (get_tree().paused), escurece a tela com um fundo pontilhado e mostra uma janela RPG com
#   continuar / como jogar / reiniciar batalha / voltar ao menu / sair (em minúsculas).
# Reiniciar, voltar e sair pedem confirmação (SIM/NÃO).
#
# Fica numa CanvasLayer ACIMA de tudo da batalha e com process_mode ALWAYS, então continua
# recebendo input com o jogo parado. Não conhece a ordem das cenas: só avisa o GameManager
# ("retry", "menu" ou "quit").
#
# Quem usa liga com setup(battle) e abre por open_menu() / toggle().

class_name PauseMenu
extends Control

signal opened
signal closed

const SCREEN := Vector2(640, 360)
const ROW_WIDTH := 160
const BOX_SIZE := Vector2(230, 168)
const CONFIRM_SIZE := Vector2(230, 96)

const MAIN_ITEMS: Array = [
	{"id": "resume", "text": "continuar"},
	{"id": "how_to", "text": "como jogar"},
	{"id": "restart", "text": "reiniciar batalha"},
	{"id": "menu", "text": "voltar ao menu"},
	{"id": "quit", "text": "sair"},
]
const CONFIRM_ITEMS: Array = [
	{"id": "yes", "text": "sim"},
	{"id": "no", "text": "não"},
]
const CONFIRM_TEXT := {
	"restart": "Reiniciar a batalha?\nO progresso desta luta se perde.",
	"menu": "Voltar ao menu?\nO progresso desta luta se perde.",
	"quit": "Sair do jogo?\nO progresso desta luta se perde.",
}

static var _backdrop_texture: ImageTexture

var battle: Node2D
var is_open: bool = false

var _box: RPGWindow
var _list: MenuList
var _confirm_box: RPGWindow
var _confirm_label: Label
var _confirm_list: MenuList
var _how_to: HowToPlayPanel
var _pending: String = ""        # ação esperando o SIM/NÃO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS      # continua vivo com o jogo pausado
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP     # nada passa pra baixo (cartas, baralho, botões)
	position = Vector2.ZERO
	size = SCREEN

	var backdrop := TextureRect.new()
	backdrop.texture = _get_backdrop()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.size = SCREEN
	add_child(backdrop)

	_box = RPGWindow.new()
	_box.size = BOX_SIZE
	_box.position = ((SCREEN - BOX_SIZE) / 2.0).floor()
	add_child(_box)

	var title := Label.new()
	title.theme_type_variation = "LabelTitle"
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 10)
	title.size = Vector2(BOX_SIZE.x, 24)
	_box.add_child(title)

	_list = MenuList.new()
	_list.row_width = ROW_WIDTH
	_box.add_child(_list)
	_list.setup(MAIN_ITEMS)
	_list.position = Vector2(roundf((BOX_SIZE.x - _list.custom_minimum_size.x) / 2.0), 42)
	_list.activated.connect(_on_main_option)

	_build_confirm()

	# "Como jogar" próprio (o da batalha fica numa camada ABAIXO desta e ficaria escondido)
	_how_to = HowToPlayPanel.new()
	_how_to.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_how_to)
	_how_to.closed.connect(_on_how_to_closed)


func _build_confirm() -> void:
	_confirm_box = RPGWindow.new()
	_confirm_box.size = CONFIRM_SIZE
	_confirm_box.position = ((SCREEN - CONFIRM_SIZE) / 2.0).floor()
	_confirm_box.visible = false
	add_child(_confirm_box)

	_confirm_label = Label.new()
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.position = Vector2(10, 12)
	_confirm_label.size = Vector2(CONFIRM_SIZE.x - 20, 32)
	_confirm_label.add_theme_font_size_override("font_size", 12)
	_confirm_box.add_child(_confirm_label)

	_confirm_list = MenuList.new()
	_confirm_list.row_width = 70
	_confirm_box.add_child(_confirm_list)
	_confirm_list.setup(CONFIRM_ITEMS)
	_confirm_list.position = Vector2(roundf((CONFIRM_SIZE.x - _confirm_list.custom_minimum_size.x) / 2.0), 50)
	_confirm_list.activated.connect(_on_confirm_option)
	_confirm_list.set_enabled(false)


# Dither do fundo: escurece tudo e deixa um xadrez de pixels ainda mais escuros por cima.
static func _get_backdrop() -> ImageTexture:
	if _backdrop_texture == null:
		var img := Image.create(int(SCREEN.x), int(SCREEN.y), false, Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var a := 0.78 if (x + y) % 2 == 0 else 0.56
				img.set_pixel(x, y, Color(0.02, 0.01, 0.02, a))
		_backdrop_texture = ImageTexture.create_from_image(img)
	return _backdrop_texture


# ---------------------------------------------------------------------------
# Abrir / fechar
# ---------------------------------------------------------------------------
func setup(battle_node: Node2D) -> void:
	battle = battle_node


func toggle() -> void:
	if is_open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	if is_open or not _can_pause():
		return
	is_open = true
	# larga a carta que estava no ar: o mouse pode soltar enquanto está pausado
	var cards := battle.get_node_or_null("CardManager")
	if cards != null and cards.has_method("cancel_drag"):
		cards.cancel_drag()
	_show_main()
	visible = true
	get_tree().paused = true
	opened.emit()


func close_menu() -> void:
	if not is_open:
		return
	is_open = false
	_pending = ""
	visible = false
	_how_to.visible = false
	get_tree().paused = false
	closed.emit()


# Não pausa quando o jogo já acabou (o painel de resultado tem as próprias opções).
func _can_pause() -> bool:
	if battle == null:
		return false
	return not battle.game_over


func _show_main() -> void:
	_pending = ""
	_confirm_box.visible = false
	_confirm_list.set_enabled(false)
	_box.visible = true
	_list.set_enabled(true)
	_list.select(0)


# ---------------------------------------------------------------------------
# Opções
# ---------------------------------------------------------------------------
func _on_main_option(id: String) -> void:
	match id:
		"resume":
			close_menu()
		"how_to":
			_list.set_enabled(false)
			_how_to.open_panel()
		_:
			_ask_confirm(id)


func _ask_confirm(id: String) -> void:
	_pending = id
	_confirm_label.text = CONFIRM_TEXT[id]
	_box.visible = false
	_list.set_enabled(false)
	_confirm_box.visible = true
	_confirm_list.set_enabled(true)
	_confirm_list.select(1)           # começa em NÃO: confirmar sem querer custa a luta


func _on_confirm_option(id: String) -> void:
	if id == "no":
		_show_main()
		return
	var action := _pending
	_pending = ""
	_confirm_list.set_enabled(false)
	# SEM despausar aqui: a árvore continua parada durante o fade, então a batalha não anda
	# por baixo da transição. O despause acontece quando esta cena sai da árvore.
	match action:
		"restart":
			GameManager.scene_finished("battle", "retry")
		"menu":
			GameManager.scene_finished("battle", "menu")
		"quit":
			GameManager.scene_finished("battle", "quit")


func _on_how_to_closed() -> void:
	if is_open:
		_show_main()


# ESC: abre; dentro do menu volta um nível (confirmação -> opções -> jogo).
# "Como jogar" aberto trata o próprio ESC.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if _how_to.visible:
		return
	if is_open:
		if _confirm_box.visible:
			_show_main()
		else:
			close_menu()
	elif not battle.ui_blocking:
		open_menu()
	else:
		return
	get_viewport().set_input_as_handled()


# Se a cena sair da árvore com o menu aberto (reiniciar, voltar ao menu), solta a pausa.
func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false
