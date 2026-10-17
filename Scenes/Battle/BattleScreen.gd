# BattleScreen.gd
# Raiz da cena de batalha na tela: monta o PixelViewport (640x360 internos, ×3) e instancia
# a Battle.tscn DENTRO dele, sem mudar a estrutura da Battle (caminhos relativos intactos).

class_name BattleScreen
extends Control

const BATTLE_SCENE := preload("res://Scenes/Battle/Battle.tscn")

var pixel_view: PixelViewport
var battle: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	pixel_view = PixelViewport.new()
	pixel_view.enable_hires()          # batalha em resolução cheia: as cartas mantêm todo o desenho
	# Com o jogo pausado o container PRECISA continuar repassando o mouse/teclado ao SubViewport
	# (senão o menu de pausa não recebe nada). A batalha em si volta a ser "pausável" abaixo.
	pixel_view.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pixel_view)

	battle = BATTLE_SCENE.instantiate()
	battle.process_mode = Node.PROCESS_MODE_PAUSABLE    # a batalha para quando o jogo pausa
	battle.screen = self          # definido ANTES de entrar na árvore: o Battle._ready já enxerga
	pixel_view.add_content(battle)
