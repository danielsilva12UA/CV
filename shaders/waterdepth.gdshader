shader_type spatial;

uniform vec3 water_color : source_color = vec3(0.35294117647,  0.53725490196, 0.65882352941);
//uniform sampler2D water_noise_1;
//uniform sampler2D water_noise_2;
uniform sampler2D waves;
uniform sampler2D highlights;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;
uniform float depth_distance : hint_range(0.0, 100.0, 0.25) = 40.0;

uniform float waves_sin_movement : hint_range(0.0, 100.0, 1.0) = 45;
uniform float waves_cos_movement : hint_range(0.0, 100.0, 1.0) = 25;

uniform float light_sin_movement : hint_range(0.0, 100.0, 1.0) = 15;
uniform float light_cos_movement : hint_range(0.0, 100.0, 1.0) = 5;

uniform float normal_scale : hint_range(0.0, 10.0, 0.1) = 0.6;
uniform float roughness_scale : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float general_time_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float water_color_ratio : hint_range(0.0, 1.0, 0.1) = 0.6;
uniform float uv_scale : hint_range(0.0, 2.0, 0.01) = 0.03;
uniform float waves_time_scale : hint_range(0.0, 10.0, 0.1) = 7.0;

uniform float refraction_sin_movement : hint_range(0.0, 0.01, 0.001) = 0.004;
uniform float refraction_cos_movement : hint_range(0.0, 0.01, 0.001) = 0.003;

uniform float water_sin_desync : hint_range(0.1, 1.0, 0.1) = 0.3;
uniform float water_cos_desync : hint_range(0.1, 1.0, 0.1) = 0.1;

uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 1.7;

uniform float abberation_r : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float abberation_g : hint_range(0.0, 1.0, 0.1) = 0.8;
uniform float abberation_b : hint_range(0.0, 1.0, 0.1) = 0.8;

uniform float highlights_time_scale : hint_range(0.0, 10.0, 0.1) = 5.0;

varying vec4 world_uv;

vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
		sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

float back_and_forth(float x, float y){
	if (sin(TIME*0.001) < 0.0)
		return x-y;
	else
		return x+y;
}

void vertex() {
	// Called for every vertex the material is visible on.
	world_uv = MODEL_MATRIX * vec4(VERTEX, 10000.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 _uv = world_uv.xz * uv_scale;

	_uv.x += sin((TIME * water_sin_desync * waves_time_scale) + back_and_forth(_uv.x, _uv.y) * waves_sin_movement) * 0.015;
	_uv.y += cos((TIME * water_cos_desync * waves_time_scale) + back_and_forth(_uv.x, _uv.y) * waves_cos_movement) * 0.01;

	// Light
	vec2 _suv = SCREEN_UV;

	_suv.x += sin((TIME * general_time_scale) + (_suv.x + _suv.y) * light_sin_movement) * refraction_sin_movement;
	_suv.y += cos((TIME * general_time_scale) + (_suv.x - _suv.y) * light_cos_movement) * refraction_cos_movement;


	float r = texture(highlights, _uv + abberation_r + TIME * highlights_time_scale).r;
	float g = texture(highlights, _uv + abberation_g + TIME * highlights_time_scale).g;
	float b = texture(highlights, _uv + abberation_b + TIME * highlights_time_scale).b;

	vec3 blended = soft_light(texture(highlights, _uv).rgb, texture(screen_texture, _suv).rgb);

	vec3 screen = textureLod(screen_texture, _suv, 0.0).rgb;

	float depth_r = textureLod(depth_texture, _suv, 0.0).r;
	vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_r, 1.0);
	world.xyz /= world.w;
	float depth_blend = smoothstep(world.z + depth_distance, world.z, VERTEX.z);
	depth_blend = exp(depth_blend*-beers_law);
	depth_blend = clamp(pow(depth_blend, 3.0), 0.0, 1.0);

	ALBEDO = mix(screen * depth_blend * blended, water_color, water_color_ratio);
	NORMAL_MAP = texture(waves,_uv).rgb;
	
	NORMAL *= normal_scale;
	ROUGHNESS *= roughness_scale;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
