shader_type sky;

// Cielo de puntos generado matemáticamente; no requiere texturas externas.
void sky() {
	vec3 direccion = normalize(EYEDIR);
	vec3 celda = floor(direccion * 200.0);
	float azar = fract(sin(dot(celda, vec3(127.1, 311.7, 74.7))) * 43758.5453);
	vec3 centro = fract(direccion * 200.0) - 0.5;
	float punto = 1.0 - smoothstep(0.08, 0.2, length(centro));
	float estrella = step(0.97, azar) * punto;
	COLOR = vec3(0.012, 0.02, 0.045) + vec3(0.65, 0.78, 1.0) * estrella;
}
