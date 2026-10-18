# Main.gd
# Cena de abertura do projeto: só entrega o controle ao GameManager, que decide a primeira cena.
# (Não conhece Intro, Menu nem Batalha.)

extends Node


func _ready() -> void:
	GameManager.start.call_deferred()    # adiado: não dá pra trocar de cena dentro do _ready
