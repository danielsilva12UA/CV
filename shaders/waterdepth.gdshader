shader_type spatial;

uniform vec3 water_color : source_color = vec3(0.35294117647,  0.53725490196, 0.65882352941);
uniform sampler2D water_noise_1;
uniform sampler2D water_noise_2;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;
uniform float depth_distance : hint_range(0.0, 100.0, 0.25) = 40.0;

uniform float waves_sin_movement : hint_range(0.0, 100.0, 1.0) = 45;
uniform float waves_cos_movement : hint_range(0.0, 100.0, 1.0) = 25;

uniform float light_sin_movement : hint_range(0.0, 100.0, 1.0) = 15;
uniform float light_cos_movement : hint_range(0.0, 100.0, 1.0) = 5;

uniform float normal_scale : hint_range(0.0, 10.0, 0.1) = 0.6;
uniform float roughness_scale : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float time_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float water_color_ratio : hint_range(0.0, 1.0, 0.1) = 0.6;
uniform float uv_scale : hint_range(0.0, 2.0, 0.01) = 0.03;

uniform float refraction_sin_movement : hint_range(0.0, 0.01, 0.001) = 0.004;
uniform float refraction_cos_movement : hint_range(0.0, 0.01, 0.001) = 0.003;

uniform float water_sin_desync : hint_range(0.1, 1.0, 0.1) = 0.3;
uniform float water_cos_desync : hint_range(0.1, 1.0, 0.1) = 0.1;

uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 1.7;

varying vec4 world_uv;

vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
		sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void vertex() {
	// Called for every vertex the material is visible on.
	world_uv = MODEL_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 _uv = world_uv.xz * uv_scale;

	_uv.x += sin((TIME * water_sin_desync * time_scale) + (_uv.x + _uv.y) * waves_sin_movement) * 0.01;
	_uv.y += cos((TIME * water_cos_desync * time_scale) + (_uv.x - _uv.y) * waves_cos_movement) * 0.01;

	// Light
	vec2 _suv = SCREEN_UV;

	_suv.x += sin((TIME * time_scale) + (_suv.x + _suv.y) * light_sin_movement) * refraction_sin_movement;
	_suv.y += cos((TIME * time_scale) + (_suv.x - _suv.y) * light_cos_movement) * refraction_cos_movement;

	vec3 blended = soft_light(texture(screen_texture, _suv).rgb, vec3(0.0,0.5,1.));

	vec3 screen = textureLod(screen_texture, _suv, 0.0).rgb;

	float depth_r = textureLod(depth_texture, _suv, 0.0).r;
	vec4 world = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_r, 1.0);
	world.xyz /= world.w;
	float depth_blend = smoothstep(world.z + depth_distance, world.z, VERTEX.z);
	depth_blend = exp(depth_blend*-beers_law);
	depth_blend = clamp(pow(depth_blend, 3.0), 0.0, 1.0);

	ALBEDO = mix(screen *- depth_blend * blended, water_color, water_color_ratio);
	NORMAL_MAP = mix(texture(water_noise_1,_uv).rgb, texture(water_noise_2, _uv).rgb, (sin(TIME * (time_scale * 2.1))+1.3));
	//NORMAL_MAP = texture(water_noise_1, _uv).rgb;
	NORMAL *= normal_scale;
	ROUGHNESS *= roughness_scale;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
