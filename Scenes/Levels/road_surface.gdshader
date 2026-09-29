shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform bool use_world_coordinates = false;
uniform float road_width = 40.0;
uniform float starting_road_join_z = 25.0;
uniform float grass_width = 5.0;
uniform float shoulder_width = 1.5;
uniform float center_line_width = 0.3;
uniform float dash_length = 9.0;
uniform float dash_gap = 6.0;

uniform vec4 asphalt_color : source_color = vec4(0.12, 0.13, 0.14, 1.0);
uniform vec4 shoulder_color : source_color = vec4(0.38, 0.38, 0.35, 1.0);
uniform vec4 grass_color : source_color = vec4(0.16, 0.34, 0.12, 1.0);
uniform vec4 line_color : source_color = vec4(0.92, 0.91, 0.82, 1.0);

varying vec3 world_position;


float surface_noise(vec2 point) {
	vec2 cell = floor(point * 3.0);
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	float half_width = road_width * 0.5;
	float lateral_position = (UV.x - 0.5) * road_width;
	float longitudinal_distance = UV.y;
	if (use_world_coordinates) {
		lateral_position = world_position.x;
		longitudinal_distance = world_position.z - starting_road_join_z;
	}

	float distance_from_center = abs(lateral_position);
	float asphalt_half_width = max(
		half_width - grass_width - shoulder_width,
		0.0
	);
	float shoulder_outer_edge = max(half_width - grass_width, 0.0);
	float grain = surface_noise(
		vec2(lateral_position, longitudinal_distance)
	);

	vec3 surface_color = asphalt_color.rgb * mix(0.9, 1.08, grain);
	float surface_roughness = 0.92;
	if (distance_from_center > asphalt_half_width) {
		surface_color = shoulder_color.rgb * mix(0.88, 1.1, grain);
		surface_roughness = 0.96;
	}
	if (distance_from_center > shoulder_outer_edge) {
		surface_color = grass_color.rgb * mix(0.78, 1.18, grain);
		surface_roughness = 1.0;
	}

	float dash_period = max(dash_length + dash_gap, 0.001);
	bool inside_center_line = (
		distance_from_center <= center_line_width * 0.5
	);
	bool inside_dash = mod(longitudinal_distance, dash_period) < dash_length;
	if (inside_center_line && inside_dash) {
		surface_color = line_color.rgb;
		surface_roughness = 0.78;
	}

	ALBEDO = surface_color;
	ROUGHNESS = surface_roughness;
}
