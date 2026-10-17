extends Node2D

var card_in_slot = false
var current_card = null
@export var zone = ""  # "player_attack", "player_defense", "enemy_attack", "enemy_defense"


# A moldura do slot está desenhada no fundo (Backgrounds/battle_bg.png); o slot é só a posição.
