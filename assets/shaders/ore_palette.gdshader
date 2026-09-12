shader_type spatial;
render_mode cull_back;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_color : source_color = vec4(.49, .51, .54, 1.0);
uniform vec4 mineral_color : source_color = vec4(.74, .46, .24, 1.0);
uniform vec4 weather_color : source_color = vec4(.27, .48, .40, 1.0);
uniform float mineral_amount = 0.0;
uniform float weather_amount = 0.0;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	float detail = dot(texture(surface_texture, UV).rgb, vec3(.2126, .7152, .0722));
	vec3 p = local_position;
	float veins = .5 + .5 * sin(p.x * 18.0 + p.z * 12.0 + sin(p.y * 16.0) * 1.7);
	float mineral = smoothstep(.43, .70, veins) * smoothstep(.12, .52, p.y) * mineral_amount;
	float weather = smoothstep(.80, .97, .5 + .5 * sin(p.z * 36.0 - p.x * 24.0 + p.y * 19.0)) * mineral * weather_amount;
	vec3 color = mix(stone_color.rgb, mineral_color.rgb, mineral);
	color = mix(color, weather_color.rgb, weather);
	ALBEDO = color * .55 * mix(.62, 1.28, clamp(detail * 2.0, 0.0, 1.0));
	ROUGHNESS = mix(.91, .68, mineral);
	METALLIC = .08 * mineral;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = .4;
}
