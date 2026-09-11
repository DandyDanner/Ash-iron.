shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 skin_color : source_color = vec4(0.38, 0.42, 0.32, 1.0);
varying vec3 surface_position;

float hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float grain(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y), mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	surface_position = VERTEX;
}
void fragment() {
	float mottling = grain(surface_position * 11.0);
	float pores = grain(surface_position * 85.0);
	ALBEDO = skin_color.rgb * (0.78 + mottling * 0.30 + pores * 0.13);
	ROUGHNESS = 0.82 + pores * 0.12;
	SPECULAR = 0.2;
}
