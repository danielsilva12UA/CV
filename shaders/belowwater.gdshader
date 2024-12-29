shader_type spatial;

uniform vec3 water_color : source_color = vec3(0.35294117647,  0.53725490196, 0.65882352941);
uniform vec3 near_center_color : source_color = vec3(0.0, 0.6, 0.5); // Slightly greener tint

uniform sampler2D waves;
uniform sampler2D highlights;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;

uniform float waves_sin_movement : hint_range(0.0, 100.0, 1.0) = 45;
uniform float waves_cos_movement : hint_range(0.0, 100.0, 1.0) = 25;

uniform float light_sin_movement : hint_range(0.0, 100.0, 1.0) = 15;
uniform float light_cos_movement : hint_range(0.0, 100.0, 1.0) = 5;

uniform float normal_scale : hint_range(0.0, 10.0, 0.1) = 0.6;
uniform float roughness_scale : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float water_color_ratio : hint_range(0.0, 1.0, 0.01) = 0.95;
uniform float uv_scale : hint_range(0.0, 0.1, 0.001) = 0.012;
uniform float waves_time_scale : hint_range(10.0, 50.0, 0.5) = 10.0;

uniform float refraction_sin_movement : hint_range(0.0, 0.01, 0.001) = 0.004;
uniform float refraction_cos_movement : hint_range(0.0, 0.01, 0.001) = 0.003;

uniform float water_sin_desync : hint_range(0.1, 1.0, 0.1) = 0.3;
uniform float water_cos_desync : hint_range(0.1, 1.0, 0.1) = 0.1;

varying vec4 world_uv;

uniform float center_influence_radius : hint_range(0.0, 1000.0, 10.0) = 500; // Radius for influence near center

vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
		sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void vertex() {
	world_uv = MODEL_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
    vec3 position = world_uv.xyz;
    float distance_to_center = length(position); // Distance to (0, 0, 0)
    float center_influence = clamp(1.0 - (distance_to_center / center_influence_radius), 0.0, 1.0);

    // Modify wave direction unaffected by center influence
    vec2 _uv = world_uv.xz * uv_scale;
    _uv.x += sin((TIME * water_sin_desync * waves_time_scale * (2.0)) + _uv.x - _uv.y * waves_sin_movement) * 0.015;
    _uv.y += cos((TIME * water_cos_desync * waves_time_scale * (2.0)) + _uv.x - _uv.y * waves_cos_movement) * 0.01;

    // Light refraction
    vec2 _suv = SCREEN_UV;

    _suv.x += sin((TIME) + (_suv.x + _suv.y) * light_sin_movement) * refraction_sin_movement;
    _suv.y += cos((TIME) + (_suv.x - _suv.y) * light_cos_movement) * refraction_cos_movement;

    vec3 blended = soft_light(texture(highlights, _uv).rgb, vec3(0.5, 0.2, 0.9));

    vec3 screen = textureLod(screen_texture, _suv, 0.0).rgb;

    // Mix colors based on proximity to center
    vec3 final_color = mix(water_color, near_center_color, center_influence);
    ALBEDO = mix(screen * blended, final_color, water_color_ratio);
    NORMAL_MAP = texture(waves, _uv).rgb;
    NORMAL *= normal_scale;
    ROUGHNESS *= roughness_scale;
    ALPHA = 0.9;
}
