class_name DynamicRoadTest
extends GdUnitTestSuite

const DynamicRoadScript = preload("res://Scenes/Levels/dynamic_road.gd")
const LevelScene = preload("res://Scenes/Levels/level.tscn")


func test_center_line_uses_nine_meter_dashes_and_six_meter_gaps() -> void:
	assert_float(DynamicRoadScript.CENTER_DASH_LENGTH).is_equal_approx(
		9.0,
		0.001
	)
	assert_float(DynamicRoadScript.CENTER_DASH_GAP).is_equal_approx(
		6.0,
		0.001
	)


func test_segment_uvs_preserve_cumulative_road_distance() -> void:
	var first: PackedVector2Array = DynamicRoadScript.build_surface_uvs(
		12.0,
		14.5
	)
	var second: PackedVector2Array = DynamicRoadScript.build_surface_uvs(
		14.5,
		17.0
	)

	assert_int(first.size()).is_equal(6)
	assert_vector(first[0]).is_equal(Vector2(0.0, 12.0))
	assert_vector(first[1]).is_equal(Vector2(1.0, 12.0))
	assert_vector(first[2]).is_equal(Vector2(1.0, 14.5))
	assert_vector(first[5]).is_equal(Vector2(0.0, 14.5))
	assert_vector(second[0]).is_equal(first[5])


func test_level_uses_one_full_width_shader_surface() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var dynamic_road: DynamicRoad = level.get_node(
		"Environment/DynamicRoad"
	)
	var starting_road: StaticBody3D = level.get_node(
		"Environment/StartingRoad"
	)
	var collision := (
		starting_road.get_node("CollisionShape3D") as CollisionShape3D
	).shape as BoxShape3D
	var mesh_instance := starting_road.get_node(
		"MeshInstance3D"
	) as MeshInstance3D
	var road_mesh := mesh_instance.mesh as BoxMesh

	assert_bool(dynamic_road.road_material is ShaderMaterial).is_true()
	assert_bool(mesh_instance.material_override is ShaderMaterial).is_true()
	var dynamic_material := dynamic_road.road_material as ShaderMaterial
	var starting_material := (
		mesh_instance.material_override as ShaderMaterial
	)
	assert_float(dynamic_material.get_shader_parameter(
		"dash_length"
	)).is_equal_approx(9.0, 0.001)
	assert_float(dynamic_material.get_shader_parameter(
		"dash_gap"
	)).is_equal_approx(6.0, 0.001)
	assert_bool(starting_material.get_shader_parameter(
		"use_world_coordinates"
	)).is_true()
	assert_float(road_mesh.size.x).is_equal_approx(collision.size.x, 0.001)
	assert_float(collision.size.x).is_equal_approx(
		dynamic_road.road_width,
		0.001
	)
