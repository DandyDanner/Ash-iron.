shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying float blade_height;
void vertex() {
 blade_height = VERTEX.y;
 vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 VERTEX.x += sin(TIME*1.4+world.x*0.6+world.z*0.7)*VERTEX.y*0.16;
 VERTEX.z += cos(TIME*1.0+world.x*0.5)*VERTEX.y*0.10;
}
void fragment() {
 // Display-space colors converted to linear for Forward+.
 ALBEDO=mix(vec3(0.040, 0.095, 0.017),vec3(0.307, 0.367, 0.084),clamp(blade_height*2.6,0.0,1.0));
 ROUGHNESS=1.0;
}
