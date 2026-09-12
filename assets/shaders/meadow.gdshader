shader_type spatial;
render_mode specular_disabled;
// Colors are authored as display (sRGB) values and converted to linear here, so the
// meadow reads the same on Forward+ (linear shading) as it did on the compatibility renderer.
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float segment_distance(vec2 p, vec2 a, vec2 b) {
 vec2 ab=b-a; return length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0));
}
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p = world.xz;
 float n = noise(p*0.22)*0.72 + noise(p*1.1)*0.28;
 vec3 grass = mix(vec3(0.073, 0.133, 0.030), vec3(0.205, 0.274, 0.068), n);
 vec2 curved=p+vec2(sin(p.y*0.45)*0.16,cos(p.x*0.35)*0.13);
 float trail=min(segment_distance(curved,vec2(0,10),vec2(-3.5,0.3)),segment_distance(curved,vec2(-3.5,0.3),vec2(10,-9)));
 float camp=length(p-vec2(-3.5,0.3));
 float dirt=1.0-smoothstep(0.65,1.35,trail+noise(p*2.1)*0.15);
 dirt=max(dirt,1.0-smoothstep(1.0,2.0,camp));
 vec3 sand=mix(vec3(0.196, 0.133, 0.059),vec3(0.367, 0.274, 0.113),n);
 ALBEDO=mix(grass,sand,dirt*0.85); ROUGHNESS=1.0;
}
