shader_type canvas_item;

uniform float scroll_offset = 0.0;
uniform vec2 scroll_axis = vec2(0.0, -1.0);
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 texture_size_px = vec2(4096.0, 4096.0);
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 sample_uv = UV;
	float viewport_aspect = max(viewport_size.x, 1.0) / max(viewport_size.y, 1.0);
	float texture_aspect = max(texture_size_px.x, 1.0) / max(texture_size_px.y, 1.0);

	if (viewport_aspect > texture_aspect) {
		float vertical_scale = texture_aspect / viewport_aspect;
		sample_uv.y = (sample_uv.y - 0.5) * vertical_scale + 0.5;
	} else {
		float horizontal_scale = viewport_aspect / texture_aspect;
		sample_uv.x = (sample_uv.x - 0.5) * horizontal_scale + 0.5;
	}

	float axis_len = length(scroll_axis);
	vec2 axis = axis_len > 0.0001 ? scroll_axis / axis_len : vec2(0.0, -1.0);
	sample_uv = fract(sample_uv + axis * scroll_offset);
	COLOR = texture(TEXTURE, sample_uv) * tint;
}
