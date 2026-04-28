shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 disk_color : source_color = vec4(0.17, 0.03, 0.14, 0.68);
uniform vec4 shield_color : source_color = vec4(1.0, 0.78, 0.10, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.98, 0.46, 1.0);
uniform float pulse_boost = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float angle = atan(p.y, p.x);

	float disk = 1.0 - smoothstep(0.78, 0.86, r);
	float outer_ring = smoothstep(0.61, 0.53, r) * smoothstep(0.35, 0.44, r);
	float inner_ring = smoothstep(0.48, 0.42, r) * smoothstep(0.25, 0.32, r);

	float bite = smoothstep(0.28, 0.46, length(p - vec2(0.20, -0.10)));
	float crescent = max(outer_ring * bite, inner_ring * 0.45);

	float sweep = 0.72 + 0.28 * sin(angle * 3.0 + r * 8.0 - TIME * 2.15);
	float pulse = 0.86 + 0.14 * sin(TIME * 3.0) + pulse_boost * 0.18;
	float glow = (1.0 - smoothstep(0.18, 0.34, abs(r - 0.49))) * bite * 0.44;
	float rim = (1.0 - smoothstep(0.68, 0.82, r)) * smoothstep(0.62, 0.72, r) * 0.28;

	vec3 color = disk_color.rgb * disk * disk_color.a;
	color += shield_color.rgb * crescent * sweep * pulse;
	color += hot_color.rgb * glow * pulse;
	color += shield_color.rgb * rim;

	float alpha = max(disk * disk_color.a, crescent + glow * 0.88 + rim);
	alpha *= 1.0 - smoothstep(0.82, 0.88, r);
	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
