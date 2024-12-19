shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.35294117647,  0.53725490196, 0.65882352941, .5);

uniform sampler2D fast_noise : repeat_enable;
uniform sampler2D screen_content : hint_screen_texture;

uniform vec2 speed = vec2(0.3, 0.7);

uniform float wave_strength = 1.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV + speed + TIME * 0.5;
	vec2 noise = texture(fast_noise, uv).rg;
	
	COLOR = vec4(color.r, color.g, color.b, 1) +  vec4(noise.x, noise.y, 1, 1);
	COLOR *= texture(screen_content, SCREEN_UV + noise * (wave_strength / 100.0));
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
