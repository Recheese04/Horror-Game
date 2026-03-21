shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(2.0, 2.0); // Allow tiling the seamless texture

uniform float wind_speed = 2.0;
uniform float wind_strength = 0.15;
uniform float fold_amount = 0.1;
uniform float fold_density = 5.0;

void vertex() {
    float curtain_height = 2.5; 
    
    // Normalized height factor: 0 at the top (pinned), 1 at the bottom (free to blow)
    // Note: since the PlaneMesh is centered, VERTEX.z ranges from -1.25 to 1.25.
    float height_factor = (VERTEX.z + (curtain_height * 0.5)) / curtain_height;
    height_factor = max(0.0, height_factor);
    
    // Permanent vertical folds that get slightly deeper towards the bottom
    float folds = sin(VERTEX.x * fold_density) * fold_amount;
    
    // Time-based wind wobble
    float wind = sin(TIME * wind_speed + VERTEX.x * 2.0 + VERTEX.z * 1.5) * wind_strength;
    
    // Apply displacement heavily toward the bottom of the curtain (y squared)
    VERTEX.y += (folds + wind) * (height_factor * height_factor);
}

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV * uv_scale);
    ALBEDO = tex_color.rgb * albedo_color.rgb;
    ROUGHNESS = 0.9;
}
