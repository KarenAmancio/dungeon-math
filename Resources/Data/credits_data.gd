# credits_data.gd
# Dados dos CRÉDITOS (nomes e papéis), separados da cena pra você editar sem mexer na lógica.
# Os nomes da equipe vêm do relatório de progresso; os PAPÉIS são placeholders: troque
# PLACEHOLDER_ROLE pelo papel real de cada pessoa.
#
# Cada seção: {"heading": título, "lines": [{"name": ..., "role": ...}, ...]}

class_name CreditsData
extends RefCounted

const TITLE := "DUNGEON MATH"
const SUBTITLE := "A Masmorra dos Números"
const THANKS := "Obrigado por jogar!"
const PLACEHOLDER_ROLE := "[papel a definir]"

const SECTIONS := [
	{
		"heading": "EQUIPE",
		"lines": [
			{"name": "ELOISA FAZZIO DA SILVA ROCHA", "role": PLACEHOLDER_ROLE},
			{"name": "ERIC EDUARDO LANGE", "role": PLACEHOLDER_ROLE},
			{"name": "ESTHER RIGOL", "role": PLACEHOLDER_ROLE},
			{"name": "KAREN AMANCIO", "role": PLACEHOLDER_ROLE},
		],
	},
	{
		"heading": "ORIENTAÇÃO",
		"lines": [
			{"name": "Beatriz Michelson", "role": "Orientadora"},
		],
	},
	{
		"heading": "INSTITUIÇÃO",
		"lines": [
			{"name": "Centro Universitário Católica de Santa Catarina", "role": "Engenharia de Software · PAC IV · 2026"},
		],
	},
	{
		"heading": "FERRAMENTAS",
		"lines": [
			{"name": "Godot Engine 4", "role": "motor do jogo"},
			{"name": "Tiny5, Jersey 10 e Jacquard 24", "role": "fontes (SIL Open Font License)"},
		],
	},
]
