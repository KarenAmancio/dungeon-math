# PixelViewport.gd
# Tela "de pixel art": renderiza o conteúdo numa resolução interna pequena (640x360) e
# amplia ×3 com filtro Nearest até preencher a tela virtual de 1920x1080.
#
# - stretch + stretch_shrink: o SubViewport fica sempre com tamanho = tela / 3.
# - O mouse chega ao conteúdo já em pixels internos (o container converte).
# - physics_object_picking: SEM isso o Area2D.mouse_entered (hover das cartas) nunca dispara.
# - Reutilizável: batalha e menu usam o mesmo componente.

class_name PixelViewport
extends SubViewportContainer

var viewport: SubViewport
var _hires: bool = false


func _init() -> void:
	stretch = true
	stretch_shrink = BattleLayout.SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	viewport = SubViewport.new()
	viewport.physics_object_picking = true
	viewport.handle_input_locally = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	add_child(viewport)


# Modo de resolução CHEIA (1920x1080): o conteúdo continua sendo escrito em pixels internos
# (640x360), mas é desenhado com escala x3 direto na tela. Cenários e textos em pixel continuam
# nítidos (filtro nearest), e arte detalhada (as cartas) aproveita os pixels extras em vez de ser
# encolhida pra 640x360. Chamar ANTES de entrar na árvore. Cada CanvasLayer do conteúdo precisa
# de scale = BattleLayout.SCALE (ver BattleUI).
func enable_hires() -> void:
	stretch_shrink = 1
	_hires = true


# A escala só pode ser aplicada com o SubViewport já dentro da árvore.
func _ready() -> void:
	if _hires:
		viewport.canvas_transform = Transform2D().scaled(Vector2(BattleLayout.SCALE, BattleLayout.SCALE))


func add_content(node: Node) -> void:
	viewport.add_child(node)
