class_name VehicleFleetTest
extends GdUnitTestSuite

const VehicleFleetScript = preload("res://Scenes/Levels/vehicle_fleet.gd")
const LevelScene = preload("res://Scenes/Levels/level.tscn")


func test_builds_twenty_distinct_vehicle_variants() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var colors: Dictionary = {}

	assert_int(variants.size()).is_equal(20)
	for variant in variants:
		var color: Color = variant["color"]
		colors[color.to_html()] = true

	assert_int(colors.size()).is_equal(20)


func test_variants_use_four_columns_and_five_rows() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var x_positions: Dictionary = {}
	var z_positions: Dictionary = {}

	for variant in variants:
		var spawn_offset: Vector3 = variant["spawn_offset"]
		x_positions[spawn_offset.x] = true
		z_positions[spawn_offset.z] = true

	assert_int(x_positions.size()).is_equal(4)
	assert_int(z_positions.size()).is_equal(5)


func test_variants_change_suspension_and_driving_parameters() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var suspension_stiffness_values: Dictionary = {}
	var suspension_travel_values: Dictionary = {}
	var lookahead_time_values: Dictionary = {}
	var suspension_profiles: Dictionary = {}
	var driving_profiles: Dictionary = {}

	for variant in variants:
		suspension_stiffness_values[variant["suspension_stiffness"]] = true
		suspension_travel_values[variant["suspension_travel"]] = true
		lookahead_time_values[variant["lookahead_time"]] = true
		suspension_profiles[
			"%.2f:%.2f:%.2f:%.2f:%.2f" % [
				variant["suspension_stiffness"],
				variant["suspension_travel"],
				variant["damping_compression"],
				variant["damping_relaxation"],
				variant["wheel_friction_slip"],
			]
		] = true
		driving_profiles[
			"%.2f:%.2f:%.2f:%.2f:%.2f" % [
				variant["maximum_speed"],
				variant["maximum_lateral_acceleration"],
				variant["lookahead_time"],
				variant["speed_kp"],
				variant["brake_gain"],
			]
		] = true

	assert_int(suspension_stiffness_values.size()).is_greater(1)
	assert_int(suspension_travel_values.size()).is_greater(1)
	assert_int(lookahead_time_values.size()).is_greater(1)
	assert_int(suspension_profiles.size()).is_equal(20)
	assert_int(driving_profiles.size()).is_equal(20)


func test_every_variant_has_eighty_meter_per_second_hard_limit() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)

	for variant in variants:
		assert_float(variant["maximum_speed"]).is_equal_approx(80.0, 0.001)


func test_vehicle_collision_filter_keeps_road_and_ignores_other_vehicles() -> void:
	assert_int(VehicleFleetScript.VEHICLE_COLLISION_LAYER).is_equal(2)
	assert_int(VehicleFleetScript.VEHICLE_COLLISION_MASK).is_equal(1)
	assert_int(
		VehicleFleetScript.VEHICLE_COLLISION_MASK
		& VehicleFleetScript.VEHICLE_COLLISION_LAYER
	).is_equal(0)


func test_vehicle_is_destroyed_after_falling_below_the_road() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var vehicle: BasicVehicle = level.get_node("Entities/Vehicle02")
	vehicle.off_road_check_interval = 0.0
	vehicle.off_road_grace_time = 0.0
	vehicle.global_position.y -= 20.0

	vehicle._physics_process(0.1)

	assert_bool(vehicle.is_queued_for_deletion()).is_true()


func test_vehicle_must_remain_off_road_for_the_grace_period() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var vehicle: BasicVehicle = level.get_node("Entities/Vehicle02")
	vehicle.off_road_check_interval = 0.0
	vehicle.off_road_grace_time = 1.0
	var road_height := vehicle.global_position.y

	vehicle.global_position.y = road_height - 20.0
	vehicle._physics_process(0.6)
	assert_bool(vehicle.is_queued_for_deletion()).is_false()

	vehicle.global_position.y = road_height
	vehicle._physics_process(0.1)
	vehicle.global_position.y = road_height - 20.0
	vehicle._physics_process(0.6)

	assert_bool(vehicle.is_queued_for_deletion()).is_false()


func test_level_spawns_twenty_configured_vehicles() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var fleet: Node3D = level.get_node("Entities")
	var visible_interface_count := 0
	var colors: Dictionary = {}

	assert_int(fleet.get_child_count()).is_equal(20)
	for vehicle: BasicVehicle in fleet.get_children():
		assert_int(vehicle.collision_layer).is_equal(
			VehicleFleetScript.VEHICLE_COLLISION_LAYER
		)
		assert_int(vehicle.collision_mask).is_equal(
			VehicleFleetScript.VEHICLE_COLLISION_MASK
		)
		visible_interface_count += int(vehicle.get_node("UI").visible)
		var material: StandardMaterial3D = (
			vehicle.get_node("CarBodyMesh").material_override
		)
		colors[material.albedo_color.to_html()] = true

	assert_int(colors.size()).is_equal(20)
	assert_int(visible_interface_count).is_equal(1)


func test_primary_vehicle_selects_each_available_camera() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var vehicle: BasicVehicle = level.get_node("Entities/Vehicle01")
	var road_camera: Camera3D = level.get_node("Camera3D")
	var chase_camera: Camera3D = vehicle.get_node("CameraPivot/Camera3D")
	var observer_camera: Camera3D = vehicle.get_node("ObserverCamera")

	vehicle.select_camera(&"road")
	assert_bool(road_camera.current).is_true()

	vehicle.select_camera(&"chase")
	assert_bool(chase_camera.current).is_true()

	vehicle.select_camera(&"observer")
	assert_bool(observer_camera.current).is_true()
