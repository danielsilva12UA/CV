shader_type spatial;

uniform vec3 water_color : source_color;
uniform float uv_scale : hint_range(0.0, 100.0, 5.0) = 2.0;
uniform float time_scale : hint_range(0.0, 10.0, 0.01) = 1.0;

uniform sampler2D water_normal_noise;

uniform float normal : hint_range(0.0, 1.0, 0.1) = 0.45;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 0.4;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;
uniform sampler2D sun_highlights;

uniform float color_ratio : hint_range(0.0, 1.0, 0.1) = 0.5;

uniform vec2 abberation_r;
uniform vec2 abberation_g;
uniform vec2 abberation_b;

uniform float highlights_time_scale : hint_range(0.0, 1.0, 0.001) = 1.0;

uniform float waves_sin_movement : hint_range(0.0, 100.0, 1.0) = 10.0;
uniform float waves_cos_movement : hint_range(0.0, 100.0, 1.0) = 10.0;
uniform float light_sin_movement : hint_range(0.0, 100.0, 1.0) = 10.0;
uniform float light_cos_movement : hint_range(0.0, 100.0, 1.0) = 10.0;


vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
		sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	// Waves
	vec2 _uv = UV * uv_scale;

	_uv.x += sin((TIME * time_scale) + (_uv.x + _uv.y) * waves_sin_movement) * 0.01;
	_uv.y += cos((TIME * time_scale) + (_uv.x - _uv.y) * waves_cos_movement) * 0.01;

	// Light
	vec2 _suv = SCREEN_UV;

	_suv.x += sin((TIME * time_scale) + (_suv.x + _suv.y) * light_sin_movement) * 0.01;
	_suv.y += cos((TIME * time_scale) + (_suv.x - _suv.y) * light_cos_movement) * 0.01;

	float r = texture(sun_highlights, _uv + abberation_r + TIME * highlights_time_scale).r;
	float g = texture(sun_highlights, _uv + abberation_g + TIME * highlights_time_scale).g;
	float b = texture(sun_highlights, _uv + abberation_b + TIME * highlights_time_scale).b;


	vec3 blended = soft_light(texture(screen_texture, _suv).rgb, vec3(r,g,b));

	ALBEDO = mix(blended, water_color, color_ratio);
	NORMAL_MAP = texture(water_normal_noise, _uv).rgb;
	NORMAL *= normal;
	ROUGHNESS = roughness;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
