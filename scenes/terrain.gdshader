shader_type spatial;

uniform sampler2D texture_base : source_color;
uniform sampler2D texture_red : source_color;
uniform sampler2D texture_green : source_color;
uniform sampler2D texture_blue : source_color;

uniform vec2 uv_scale = vec2(20.0, 20.0);

void fragment() {
	vec2 uv = UV * uv_scale;

	vec4 col_base = texture(texture_base, uv);
	vec4 col_red = texture(texture_red, uv);
	vec4 col_green = texture(texture_green, uv);
	vec4 col_blue = texture(texture_blue, uv);

	vec3 weights = COLOR.rgb;
	float base_weight = clamp(1.0 - (weights.r + weights.g + weights.b), 0.0, 1.0);

	vec4 final_color = col_base * base_weight + col_red * weights.r + col_green * weights.g + col_blue * weights.b;

	ALBEDO = final_color.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}
