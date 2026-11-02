shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float impacto : hint_range(0.0, 1.0) = 0.0;
varying vec3 punto_local;

void vertex() {
	punto_local = VERTEX;
}

void fragment() {
	if (punto_local.y < 0.0) {
		discard;
	}
	float borde = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	vec2 cuadricula = abs(fract(UV * vec2(32.0, 16.0)) - 0.5);
	float lineas = smoothstep(0.475, 0.495, max(cuadricula.x, cuadricula.y));
	float base = 1.0 - smoothstep(0.0, 0.025, punto_local.y);
	vec3 color = mix(vec3(0.35, 0.95, 0.35), vec3(0.12, 0.85, 1.0), impacto);
	ALBEDO = color;
	EMISSION = color * (0.15 + impacto * 0.4);
	ALPHA = 0.012 + borde * 0.10 + lineas * 0.045 + base * 0.25 + impacto * 0.10;
}
