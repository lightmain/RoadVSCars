shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 rubber_color : source_color = vec3(0.025, 0.03, 0.032);
uniform vec3 groove_color : source_color = vec3(0.006, 0.008, 0.009);
uniform vec3 rim_color : source_color = vec3(0.42, 0.46, 0.48);
uniform vec3 hub_color : source_color = vec3(0.12, 0.14, 0.15);

varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	float radius = length(local_position.xz);
	float angle = atan(local_position.z, local_position.x);
	float side_surface = 1.0 - smoothstep(0.72, 0.92, abs(local_normal.y));

	float tread_repeat = fract(angle / TAU * 18.0 + local_position.y * 4.0);
	float tread_groove = step(0.72, abs(tread_repeat - 0.5) * 2.0);
	float center_channel = 1.0 - smoothstep(0.022, 0.04, abs(local_position.y));
	float shoulder_channel = smoothstep(0.085, 0.105, abs(local_position.y));
	shoulder_channel *= 1.0 - smoothstep(0.115, 0.14, abs(local_position.y));
	float groove = max(tread_groove * 0.72, max(center_channel, shoulder_channel));
	vec3 tread_color = mix(rubber_color, groove_color, groove);

	float rim_band = smoothstep(0.19, 0.23, radius);
	rim_band *= 1.0 - smoothstep(0.37, 0.405, radius);
	float spoke_wave = 0.5 + 0.5 * cos(angle * 6.0);
	float spokes = smoothstep(0.72, 0.9, spoke_wave);
	spokes *= smoothstep(0.12, 0.17, radius);
	spokes *= 1.0 - smoothstep(0.35, 0.39, radius);
	float hub = 1.0 - smoothstep(0.105, 0.15, radius);
	float metal_mask = max(rim_band, max(spokes, hub));
	vec3 cap_color = mix(rubber_color * 0.82, rim_color, max(rim_band, spokes));
	cap_color = mix(cap_color, hub_color, hub);

	ALBEDO = mix(cap_color, tread_color, side_surface);
	METALLIC = metal_mask * (1.0 - side_surface) * 0.82;
	ROUGHNESS = mix(0.34, 0.88, side_surface);
}
