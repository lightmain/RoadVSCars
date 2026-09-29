class_name VehicleFleetTest
extends GdUnitTestSuite

const VehicleFleetScript = preload("res://Scenes/Levels/vehicle_fleet.gd")
const LevelScene = preload("res://Scenes/Levels/level.tscn")


func test_alive_index_traversal_skips_dead_slots_and_wraps() -> void:
	var alive_states: Array[bool] = [true, false, true, false]

	assert_int(
		VehicleFleetScript.find_alive_index(alive_states, 0, 1)
	).is_equal(2)
	assert_int(
		VehicleFleetScript.find_alive_index(alive_states, 2, 1)
	).is_equal(0)
	assert_int(
		VehicleFleetScript.find_alive_index(alive_states, 0, -1)
	).is_equal(2)
	assert_int(
		VehicleFleetScript.find_alive_index(alive_states, 2, -1)
	).is_equal(0)
	assert_int(
		VehicleFleetScript.find_alive_index([false, false], 0, 1)
	).is_equal(-1)


func test_seeded_startup_selects_one_alive_vehicle() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.observation_random_seed = 12345
	add_child(level)
	var expected_random := RandomNumberGenerator.new()
	expected_random.seed = 12345
	var expected_index := expected_random.randi_range(0, 19)

	assert_int(fleet.observed_vehicle_index).is_equal(expected_index)
	assert_object(fleet.observed_vehicle).is_same(
		fleet.get_child(expected_index)
	)
	await get_tree().process_frame
	assert_bool(fleet.observed_vehicle.camera_3d.current).is_true()


func test_arrow_keys_cycle_observation_and_ignore_echo_events() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.observation_random_seed = 12345
	add_child(level)
	var initial_index := fleet.observed_vehicle_index
	var expected_right := VehicleFleetScript.find_alive_index(
		fleet.get_vehicle_alive_states(),
		initial_index,
		1
	)

	fleet._input(_arrow_event(KEY_RIGHT))

	assert_int(fleet.observed_vehicle_index).is_equal(expected_right)

	fleet._input(_arrow_event(KEY_LEFT, true))
	assert_int(fleet.observed_vehicle_index).is_equal(expected_right)

	fleet._input(_arrow_event(KEY_LEFT))
	assert_int(fleet.observed_vehicle_index).is_equal(initial_index)


func test_observed_vehicle_death_selects_an_alive_replacement() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.observation_random_seed = 12345
	add_child(level)
	var previous_vehicle := fleet.observed_vehicle
	var previous_index := fleet.observed_vehicle_index

	previous_vehicle.queue_free()
	await get_tree().process_frame

	assert_int(fleet.observed_vehicle_index).is_not_equal(previous_index)
	assert_bool(
		fleet.get_vehicle_alive_states()[fleet.observed_vehicle_index]
	).is_true()
	assert_bool(is_instance_valid(fleet.observed_vehicle)).is_true()


func test_last_vehicle_death_clears_observation_and_restores_road_camera() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.vehicle_count = 1
	fleet.observation_random_seed = 12345
	add_child(level)
	var road_camera: Camera3D = level.get_node("Camera3D")

	fleet.observed_vehicle.queue_free()
	await get_tree().process_frame

	assert_int(fleet.observed_vehicle_index).is_equal(-1)
	assert_bool(is_instance_valid(fleet.observed_vehicle)).is_false()
	assert_bool(road_camera.current).is_true()


func test_camera_mode_and_highlight_transfer_to_cycled_vehicle() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.observation_random_seed = 12345
	add_child(level)
	var ui: DrivingUI = level.get_node("UI")
	var previous_vehicle := fleet.observed_vehicle
	var previous_index := fleet.observed_vehicle_index

	fleet.select_camera_mode(&"observer")
	fleet.cycle_observed_vehicle(1)

	var current_vehicle := fleet.observed_vehicle
	var current_index := fleet.observed_vehicle_index
	var previous_status: Label = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/StatusGrid"
	).get_child(previous_index)
	var current_status: Label = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/StatusGrid"
	).get_child(current_index)

	assert_bool(previous_vehicle.observer_camera.current).is_false()
	assert_bool(current_vehicle.observer_camera.current).is_true()
	assert_bool(previous_status.get_meta("observed", true)).is_false()
	assert_bool(current_status.get_meta("observed", false)).is_true()
	assert_int(
		(
			previous_status.get_theme_stylebox("normal") as StyleBoxFlat
		).border_width_left
	).is_equal(0)
	assert_int(
		(
			current_status.get_theme_stylebox("normal") as StyleBoxFlat
		).border_width_left
	).is_equal(3)


func test_telemetry_binding_transfers_to_cycled_vehicle() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var fleet: VehicleFleet = level.get_node("Entities")
	fleet.observation_random_seed = 12345
	add_child(level)
	var ui: DrivingUI = level.get_node("UI")
	var previous_vehicle := fleet.observed_vehicle
	var throttle: ProgressBar = ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	)

	fleet.cycle_observed_vehicle(1)
	var current_vehicle := fleet.observed_vehicle
	previous_vehicle._basic_driving(0.9, 0.0, 0.0, 0.016)
	assert_float(throttle.value).is_equal_approx(0.0, 0.001)

	current_vehicle._basic_driving(0.4, 0.0, 0.0, 0.016)
	assert_float(throttle.value).is_equal_approx(0.4, 0.001)


func test_builds_twenty_distinct_vehicle_variants() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var colors: Dictionary = {}

	assert_int(variants.size()).is_equal(20)
	for variant in variants:
		var color: Color = variant["color"]
		colors[color.to_html()] = true

	assert_int(colors.size()).is_equal(20)


func test_variants_use_an_f1_style_staggered_two_column_grid() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var x_positions: Dictionary = {}
	var z_positions: Dictionary = {}

	for index in variants.size():
		var variant := variants[index]
		var spawn_offset: Vector3 = variant["spawn_offset"]
		x_positions[spawn_offset.x] = true
		z_positions[spawn_offset.z] = true
		var expected_x := -3.0 if index % 2 == 0 else 3.0
		var expected_z := 15.0 - index * 4.5
		assert_float(spawn_offset.x).is_equal_approx(expected_x, 0.001)
		assert_float(spawn_offset.z).is_equal_approx(expected_z, 0.001)
		if index >= 2:
			var previous_same_lane: Vector3 = variants[
				index - 2
			]["spawn_offset"]
			assert_float(
				previous_same_lane.z - spawn_offset.z
			).is_equal_approx(9.0, 0.001)

	assert_int(x_positions.size()).is_equal(2)
	assert_int(z_positions.size()).is_equal(20)


func test_starting_road_covers_the_full_grid_and_meets_dynamic_road() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	var starting_road: StaticBody3D = level.get_node(
		"Environment/StartingRoad"
	)
	var collision: CollisionShape3D = starting_road.get_node(
		"CollisionShape3D"
	)
	var road_shape := collision.shape as BoxShape3D
	var road_mesh := (
		starting_road.get_node("MeshInstance3D") as MeshInstance3D
	).mesh as BoxMesh
	var camera: Camera3D = level.get_node("Camera3D")
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(20)
	var rear_vehicle_z: float = variants[-1]["spawn_offset"].z
	var half_road_length := road_shape.size.z * 0.5
	var road_rear_edge := starting_road.position.z - half_road_length
	var road_front_edge := starting_road.position.z + half_road_length

	assert_float(road_front_edge).is_equal_approx(camera.position.z, 0.001)
	assert_float(road_rear_edge).is_less_equal(rear_vehicle_z - 2.5)
	assert_float(road_shape.size.z).is_equal_approx(120.0, 0.001)
	assert_float(road_mesh.size.z).is_equal_approx(120.0, 0.001)


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


func test_seeded_target_offsets_are_reproducible() -> void:
	var first: Array[Dictionary] = VehicleFleetScript.build_variants(
		20,
		12345,
		12.0,
		4.0
	)
	var second: Array[Dictionary] = VehicleFleetScript.build_variants(
		20,
		12345,
		12.0,
		4.0
	)

	for index in first.size():
		assert_float(first[index]["target_lateral_offset"]).is_equal_approx(
			second[index]["target_lateral_offset"],
			0.0001
		)
		assert_float(first[index]["target_longitudinal_offset"]).is_equal_approx(
			second[index]["target_longitudinal_offset"],
			0.0001
		)


func test_target_offsets_are_bounded_and_distributed() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(
		20,
		12345,
		12.0,
		4.0
	)
	var offsets: Dictionary = {}

	for variant in variants:
		var lateral: float = variant["target_lateral_offset"]
		var longitudinal: float = variant["target_longitudinal_offset"]
		assert_float(absf(lateral)).is_less_equal(12.0)
		assert_float(absf(longitudinal)).is_less_equal(4.0)
		offsets["%.3f:%.3f" % [lateral, longitudinal]] = true

	assert_int(offsets.size()).is_greater(10)


func test_target_offsets_match_starting_side_across_coordinate_spaces() -> void:
	var variants: Array[Dictionary] = VehicleFleetScript.build_variants(
		20,
		12345,
		12.0,
		4.0
	)

	for variant in variants:
		var spawn_offset: Vector3 = variant["spawn_offset"]
		var target_lateral_offset: float = variant["target_lateral_offset"]
		assert_float(
			spawn_offset.x * target_lateral_offset
		).is_less(0.0)


func test_safe_target_radius_stays_inside_road_edges() -> void:
	var radius: float = VehicleFleetScript.safe_lateral_target_radius(
		40.0,
		30.0,
		3.0
	)

	assert_float(radius).is_equal_approx(17.0, 0.001)


func test_vehicle_collision_filter_includes_road_and_other_vehicles() -> void:
	assert_int(VehicleFleetScript.VEHICLE_COLLISION_LAYER).is_equal(2)
	assert_int(VehicleFleetScript.VEHICLE_COLLISION_MASK).is_equal(3)
	assert_int(VehicleFleetScript.VEHICLE_COLLISION_MASK & 1).is_equal(1)
	assert_int(
		VehicleFleetScript.VEHICLE_COLLISION_MASK
		& VehicleFleetScript.VEHICLE_COLLISION_LAYER
	).is_equal(VehicleFleetScript.VEHICLE_COLLISION_LAYER)


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
	var colors: Dictionary = {}
	var target_offsets: Dictionary = {}

	assert_int(fleet.get_child_count()).is_equal(20)
	assert_bool(level.has_node("UI")).is_true()
	assert_object(level.get_node("UI").get_parent()).is_same(level)
	for vehicle: BasicVehicle in fleet.get_children():
		assert_int(vehicle.collision_layer).is_equal(
			VehicleFleetScript.VEHICLE_COLLISION_LAYER
		)
		assert_int(vehicle.collision_mask).is_equal(
			VehicleFleetScript.VEHICLE_COLLISION_MASK
		)
		assert_bool(vehicle.has_node("UI")).is_false()
		var material: StandardMaterial3D = (
			vehicle.get_node("CarBodyMesh").material_override
		)
		colors[material.albedo_color.to_html()] = true
		var vehicle_ai: BasicAI = vehicle.get_node("BasicAI")
		assert_float(absf(vehicle_ai.target_lateral_offset)).is_less_equal(12.0)
		assert_float(absf(vehicle_ai.target_longitudinal_offset)).is_less_equal(
			4.0
		)
		target_offsets[
			"%.3f:%.3f" % [
				vehicle_ai.target_lateral_offset,
				vehicle_ai.target_longitudinal_offset,
			]
		] = true

	assert_int(colors.size()).is_equal(20)
	assert_int(target_offsets.size()).is_greater(10)


func test_vehicle_wheels_share_the_tire_shader_material() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var vehicle: BasicVehicle = level.get_node("Entities/Vehicle02")
	var wheel_paths: Array[NodePath] = [
		"FrontLeft/MeshInstance3D",
		"BackLeft/MeshInstance3D",
		"FrontRight/MeshInstance3D",
		"BackRight/MeshInstance3D",
	]
	var shared_material: Material

	for wheel_path in wheel_paths:
		var wheel_mesh := vehicle.get_node(wheel_path) as MeshInstance3D
		var material := wheel_mesh.get_surface_override_material(0)
		assert_bool(material is ShaderMaterial).is_true()
		assert_str(material.resource_path).is_equal(
			"res://Scenes/Entities/wheel_material.tres"
		)
		if shared_material:
			assert_object(material).is_same(shared_material)
		else:
			shared_material = material


func test_basic_ai_applies_heading_recovery_after_large_rotation() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var road: DynamicRoad = level.get_node("Environment/DynamicRoad")
	var path: RefCounted = road.get_road_path()
	var path_start: Dictionary = path.sample_at_distance(0.0)
	path.append_control_point(
		path_start["position"] + path_start["tangent"] * 100.0,
		path_start["tangent"]
	)
	var vehicle: BasicVehicle = level.get_node("Entities/Vehicle02")
	vehicle.set_physics_process(false)
	vehicle.global_position = (
		path_start["position"] - path_start["tangent"] * 10.0
	)
	vehicle.global_rotation = Vector3(0.0, deg_to_rad(100.0), 0.0)
	vehicle.ai.target_lateral_offset = 0.0
	vehicle.ai.target_longitudinal_offset = 0.0

	var command: Dictionary = vehicle.ai.get_control(0.016)

	assert_float(absf(command["steering"])).is_equal_approx(1.0, 0.001)
	assert_float(command["target_speed"]).is_less_equal(
		vehicle.ai.heading_recovery_target_speed
	)


func test_scene_ui_tracks_vehicle_liveness_after_vehicle_exits() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var fleet: VehicleFleet = level.get_node("Entities")
	var ui: Control = level.get_node("UI")
	var vehicle: BasicVehicle = fleet.get_node("Vehicle02")
	var title: Label = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/Title"
	)
	var vehicle_status: Label = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/StatusGrid/Vehicle02"
	)

	assert_array(fleet.get_vehicle_alive_states()).contains_exactly(
		Array(range(20)).map(func(_index: int) -> bool: return true)
	)
	assert_str(title.text).is_equal("Fleet 20 / 20")
	assert_bool(vehicle_status.get_meta("alive", false)).is_true()

	vehicle.queue_free()
	await get_tree().process_frame

	assert_bool(fleet.get_vehicle_alive_states()[1]).is_false()
	assert_str(title.text).is_equal("Fleet 19 / 20")
	assert_bool(vehicle_status.get_meta("alive", true)).is_false()
	assert_bool(is_instance_valid(ui)).is_true()


func test_scene_ui_receives_observed_vehicle_telemetry_and_camera_selection() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var fleet: VehicleFleet = level.get_node("Entities")
	var vehicle: BasicVehicle = fleet.observed_vehicle
	var ui: Control = level.get_node("UI")
	var throttle: ProgressBar = ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	)
	var brake: ProgressBar = ui.get_node(
		"ControlMonitor/VBoxContainer/BrakeRow/Brake"
	)
	var observer_button: Button = ui.get_node(
		"CameraSelector/MarginContainer/Buttons/ObserverCamera"
	)
	var observer_camera: Camera3D = vehicle.get_node("ObserverCamera")

	vehicle._basic_driving(0.75, 0.5, 0.25, 0.016)

	assert_float(throttle.value).is_equal_approx(0.75, 0.001)
	assert_float(brake.value).is_equal_approx(0.25, 0.001)

	observer_button.pressed.emit()

	assert_bool(observer_camera.current).is_true()


func test_observed_vehicle_selects_each_available_camera() -> void:
	var level: Node3D = auto_free(LevelScene.instantiate())
	add_child(level)
	var fleet: VehicleFleet = level.get_node("Entities")
	var vehicle: BasicVehicle = fleet.observed_vehicle
	var road_camera: Camera3D = level.get_node("Camera3D")
	var chase_camera: Camera3D = vehicle.get_node("CameraPivot/Camera3D")
	var observer_camera: Camera3D = vehicle.get_node("ObserverCamera")

	fleet.select_camera_mode(&"road")
	assert_bool(road_camera.current).is_true()

	fleet.select_camera_mode(&"chase")
	assert_bool(chase_camera.current).is_true()

	fleet.select_camera_mode(&"observer")
	assert_bool(observer_camera.current).is_true()


func _arrow_event(keycode: Key, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = echo
	return event
