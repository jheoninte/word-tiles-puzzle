shader_type canvas_item;

uniform vec2 focus_center = vec2(0.5, 0.35);
uniform vec2 focus_size = vec2(0.3, 0.18);
uniform float dim_alpha = 0.72;

void fragment() {
	vec2 uv = UV;
	vec2 delta = abs(uv - focus_center);
	float inside_x = step(delta.x, focus_size.x * 0.5);
	float inside_y = step(delta.y, focus_size.y * 0.5);
	float inside = inside_x * inside_y;
	COLOR = vec4(0.0, 0.0, 0.0, dim_alpha * (1.0 - inside));
}
