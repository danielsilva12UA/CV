shader_type spatial;
render_mode unshaded;

uniform sampler2D tex: source_color;

vec3 linear_to_srgb(vec3 color) {
	return max(vec3(1.055) * pow(color, vec3(0.416666667)) - vec3(0.055), vec3(0.0));
}

vec3 srgb_to_linear(vec3 color) {
	return color * (color * (color * 0.305306011 + 0.682171111) + 0.012522878);
}

void fragment() {
	ALBEDO = (texture(tex, SCREEN_UV).rgb);
	ALPHA = texture(tex, SCREEN_UV).a;
}