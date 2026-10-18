shader_type canvas_item;

// Transição de cena: a tela vai sendo "comida" por blocos de pixel (preto), em ordem aleatória,
// com uma borda roxa nos blocos que acabaram de aparecer. progress 0 = nada, 1 = tudo preto.
// Os blocos têm o tamanho de um pixel do jogo x cell_px.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float cell_px = 24.0;                    // tamanho do bloco na tela (8 pixels internos)
uniform float seed = 0.0;
uniform float edge = 0.12;                       // largura da borda colorida (em progresso)
uniform vec4 edge_color : source_color = vec4(0.45, 0.2, 0.7, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32 + seed);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / cell_px);
	float n = hash(cell);
	// o ruído decide QUANDO o bloco escurece; uma leve diagonal faz a onda varrer a tela
	float t = n * 0.8 + (cell.x + cell.y) * 0.0006;
	float p = progress * 1.2 - 0.1;
	if (t < p - edge) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else if (t < p) {
		COLOR = edge_color;
	} else {
		COLOR = vec4(0.0);
	}
}
