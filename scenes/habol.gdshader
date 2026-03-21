shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);

uniform float crumple_amount = 0.05;
uniform float fold_scale = 10.0;

void vertex() {
    // Generate crumpled look using overlapping sine waves
    float wave1 = sin(VERTEX.x * fold_scale + VERTEX.z * fold_scale * 0.5);
    float wave2 = cos(VERTEX.z * fold_scale * 1.5 - VERTEX.x * fold_scale);
    VERTEX.y += (wave1 * wave2) * crumple_amount;
}

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV * uv_scale);
    ALBEDO = tex_color.rgb * albedo.rgb;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}
