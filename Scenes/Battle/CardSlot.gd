extends Node2D

var card_in_slot = false
var current_card = null
@export var zone = ""  # "player_attack", "player_defense", "enemy_attack", "enemy_defense"


# O slot se desenha sozinho (sem PNG): fundo escuro, borda na cor da zona e cantoneiras.
func _draw() -> void:
	var accent: Color = Palette.DEF_BLUE if zone.ends_with("defense") else Palette.ATK_RED
	var size := BattleLayout.SLOT_SIZE
	var r := Rect2(-size / 2.0, size)
	draw_rect(r, Palette.BORDER_DARK)
	draw_rect(r.grow(-1), accent.darkened(0.45))
	draw_rect(r.grow(-2), Color(Palette.BG_DEEP, 0.92))
	# cantoneiras mais claras
	for corner in [r.position, Vector2(r.end.x - 4, r.position.y), Vector2(r.position.x, r.end.y - 4), r.end - Vector2(4, 4)]:
		var left: bool = corner.x < 0.0
		var top: bool = corner.y < 0.0
		draw_rect(Rect2(corner.x + (1 if left else 0), corner.y + (1 if top else 3), 3, 1), accent.lightened(0.1))
		draw_rect(Rect2(corner.x + (1 if left else 3), corner.y + (1 if top else 0), 1, 3), accent.lightened(0.1))
