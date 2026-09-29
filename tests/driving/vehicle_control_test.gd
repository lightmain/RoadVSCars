class_name VehicleControlTest
extends GdUnitTestSuite

const VehicleControl = preload("res://Scripts/Driving/vehicle_control.gd")


func test_pure_pursuit_steers_toward_each_side() -> void:
	var left_command: float = VehicleControl.pure_pursuit_steering(
		Vector3(-2.0, 0.0, 10.0),
		2.7,
		deg_to_rad(40.0)
	)
	var right_command: float = VehicleControl.pure_pursuit_steering(
		Vector3(2.0, 0.0, 10.0),
		2.7,
		deg_to_rad(40.0)
	)

	assert_float(left_command).is_greater(0.0)
	assert_float(right_command).is_less(0.0)
	assert_float(absf(left_command)).is_less_equal(1.0)
	assert_float(absf(right_command)).is_less_equal(1.0)


func test_pure_pursuit_is_neutral_for_ahead_target() -> void:
	var command: float = VehicleControl.pure_pursuit_steering(
		Vector3(0.0, 0.0, 10.0),
		2.7,
		deg_to_rad(40.0)
	)

	assert_float(command).is_equal_approx(0.0, 0.0001)


func test_heading_recovery_stays_inactive_below_entry_angle() -> void:
	var angle := deg_to_rad(79.0)
	var recovery: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(-sin(angle), 0.0, cos(angle)) * 10.0,
		false,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(recovery["active"]).is_false()
	assert_float(recovery["target_speed"]).is_equal_approx(30.0, 0.001)


func test_heading_recovery_starts_at_entry_angle_with_full_left_lock() -> void:
	var angle := deg_to_rad(80.0)
	var recovery: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(-sin(angle), 0.0, cos(angle)) * 10.0,
		false,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(recovery["active"]).is_true()
	assert_float(recovery["steering"]).is_equal_approx(1.0, 0.001)
	assert_float(recovery["target_speed"]).is_equal_approx(8.0, 0.001)


func test_heading_recovery_uses_full_right_lock_for_right_target() -> void:
	var angle := deg_to_rad(100.0)
	var recovery: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(sin(angle), 0.0, cos(angle)) * 10.0,
		false,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(recovery["active"]).is_true()
	assert_float(recovery["steering"]).is_equal_approx(-1.0, 0.001)


func test_heading_recovery_uses_exit_angle_hysteresis() -> void:
	var stays_active_angle := deg_to_rad(70.0)
	var exits_angle := deg_to_rad(64.0)
	var stays_active: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(
			-sin(stays_active_angle),
			0.0,
			cos(stays_active_angle)
		) * 10.0,
		true,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)
	var exits: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(-sin(exits_angle), 0.0, cos(exits_angle)) * 10.0,
		true,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(stays_active["active"]).is_true()
	assert_bool(exits["active"]).is_false()


func test_heading_recovery_chooses_left_lock_for_directly_rearward_target() -> void:
	var recovery: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(0.0, 0.0, -10.0),
		false,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(recovery["active"]).is_true()
	assert_float(recovery["steering"]).is_equal_approx(1.0, 0.001)


func test_heading_recovery_is_finite_and_inactive_for_invalid_target() -> void:
	var recovery: Dictionary = VehicleControl.heading_recovery_control(
		Vector3(NAN, 0.0, INF),
		true,
		deg_to_rad(80.0),
		deg_to_rad(65.0),
		30.0,
		8.0
	)

	assert_bool(recovery["active"]).is_false()
	assert_float(recovery["steering"]).is_equal_approx(0.0, 0.001)
	assert_bool(is_finite(recovery["target_speed"])).is_true()


func test_path_target_offset_uses_road_right_for_positive_z() -> void:
	var target: Vector3 = VehicleControl.offset_path_target(
		Vector3(10.0, 2.0, 20.0),
		Vector3.BACK,
		3.0
	)

	assert_vector(target).is_equal_approx(
		Vector3(13.0, 2.0, 20.0),
		Vector3.ONE * 0.001
	)


func test_path_target_offset_rotates_with_the_road_tangent() -> void:
	var target: Vector3 = VehicleControl.offset_path_target(
		Vector3(10.0, 2.0, 20.0),
		Vector3.RIGHT,
		3.0
	)

	assert_vector(target).is_equal_approx(
		Vector3(10.0, 2.0, 17.0),
		Vector3.ONE * 0.001
	)


func test_path_target_offset_ignores_a_vertical_tangent() -> void:
	var position := Vector3(10.0, 2.0, 20.0)
	var target: Vector3 = VehicleControl.offset_path_target(
		position,
		Vector3.UP,
		3.0
	)

	assert_vector(target).is_equal_approx(position, Vector3.ONE * 0.001)


func test_steering_is_limited_by_lateral_acceleration_at_speed() -> void:
	var command: float = VehicleControl.limit_steering_for_speed(
		1.0,
		20.0,
		3.3,
		deg_to_rad(40.0),
		4.0
	)

	assert_float(command).is_greater(0.0)
	assert_float(command).is_less(0.06)


func test_tighter_curvature_has_lower_speed_limit() -> void:
	var gentle_limit: float = VehicleControl.curvature_speed_limit(0.02, 8.0)
	var tight_limit: float = VehicleControl.curvature_speed_limit(0.2, 8.0)

	assert_float(gentle_limit).is_greater(tight_limit)
	assert_float(tight_limit).is_equal_approx(sqrt(40.0), 0.001)


func test_straight_path_has_no_finite_curve_limit() -> void:
	var speed_limit: float = VehicleControl.curvature_speed_limit(0.0, 8.0)

	assert_bool(is_inf(speed_limit)).is_true()


func test_curve_approach_speed_limit_brakes_later_for_a_distant_curve() -> void:
	var near_limit: float = VehicleControl.curve_approach_speed_limit(
		0.2,
		9.0,
		10.0,
		10.0
	)
	var far_limit: float = VehicleControl.curve_approach_speed_limit(
		0.2,
		9.0,
		80.0,
		10.0
	)
	var gentle_limit: float = VehicleControl.curve_approach_speed_limit(
		0.05,
		9.0,
		10.0,
		10.0
	)

	assert_float(near_limit).is_less(far_limit)
	assert_float(near_limit).is_less(gentle_limit)
	assert_float(near_limit).is_greater(
		VehicleControl.curvature_speed_limit(0.2, 9.0)
	)


func test_moving_end_target_accelerates_until_ten_meter_gap() -> void:
	var catch_up_speed: float = VehicleControl.moving_target_speed(
		30.0,
		25.0,
		10.0,
		0.5
	)
	var matched_speed: float = VehicleControl.moving_target_speed(
		30.0,
		10.0,
		10.0,
		0.5
	)
	var back_off_speed: float = VehicleControl.moving_target_speed(
		30.0,
		4.0,
		10.0,
		0.5
	)
	var capped_speed: float = VehicleControl.moving_target_speed(
		30.0,
		100.0,
		10.0,
		0.5,
		45.0
	)

	assert_float(catch_up_speed).is_greater(30.0)
	assert_float(matched_speed).is_equal_approx(30.0, 0.001)
	assert_float(back_off_speed).is_less(30.0)
	assert_float(back_off_speed).is_greater_equal(0.0)
	assert_float(capped_speed).is_equal_approx(45.0, 0.001)


func test_distance_target_speed_stops_at_thirty_meter_end_gap() -> void:
	var target_speed: float = VehicleControl.distance_target_speed(
		30.0,
		30.0,
		10.0,
		80.0
	)

	assert_float(target_speed).is_equal_approx(0.0, 0.001)


func test_distance_target_speed_increases_with_available_distance() -> void:
	var near_speed: float = VehicleControl.distance_target_speed(
		40.0,
		30.0,
		10.0,
		80.0
	)
	var far_speed: float = VehicleControl.distance_target_speed(
		130.0,
		30.0,
		10.0,
		80.0
	)

	assert_float(near_speed).is_equal_approx(sqrt(200.0), 0.001)
	assert_float(far_speed).is_greater(near_speed)


func test_distance_target_speed_has_eighty_meter_per_second_hard_limit() -> void:
	var target_speed: float = VehicleControl.distance_target_speed(
		10000.0,
		30.0,
		10.0,
		80.0
	)

	assert_float(target_speed).is_equal_approx(80.0, 0.001)


func test_road_bounds_are_relative_to_the_nearest_road_point() -> void:
	var is_outside: bool = VehicleControl.is_outside_road_bounds(
		Vector3(0.0, -99.0, 0.0),
		Vector3(0.0, -100.0, 0.0),
		Vector3.BACK,
		40.0,
		5.0,
		6.0
	)

	assert_bool(is_outside).is_false()


func test_road_bounds_allow_a_lateral_safety_margin() -> void:
	var is_outside: bool = VehicleControl.is_outside_road_bounds(
		Vector3(24.0, 1.0, 0.0),
		Vector3.ZERO,
		Vector3.BACK,
		40.0,
		5.0,
		6.0
	)

	assert_bool(is_outside).is_false()


func test_road_bounds_detect_a_vehicle_far_beside_the_road() -> void:
	var is_outside: bool = VehicleControl.is_outside_road_bounds(
		Vector3(26.0, 1.0, 0.0),
		Vector3.ZERO,
		Vector3.BACK,
		40.0,
		5.0,
		6.0
	)

	assert_bool(is_outside).is_true()


func test_road_bounds_detect_a_vehicle_below_the_road() -> void:
	var is_outside: bool = VehicleControl.is_outside_road_bounds(
		Vector3(0.0, -7.0, 0.0),
		Vector3.ZERO,
		Vector3.BACK,
		40.0,
		5.0,
		6.0
	)

	assert_bool(is_outside).is_true()


func test_road_bounds_ignore_longitudinal_distance_from_path_endpoint() -> void:
	var is_outside: bool = VehicleControl.is_outside_road_bounds(
		Vector3(0.0, 1.0, -100.0),
		Vector3.ZERO,
		Vector3.BACK,
		40.0,
		5.0,
		6.0
	)

	assert_bool(is_outside).is_false()


func test_road_builder_turn_rate_uses_original_road_width_radius() -> void:
	var turn_rate: float = VehicleControl.road_builder_turn_rate(
		80.0,
		40.0,
		8.0
	)

	assert_float(turn_rate).is_equal_approx(80.0 / 60.0, 0.0001)


func test_turn_rate_respects_lateral_acceleration_limit() -> void:
	var turn_rate: float = VehicleControl.maximum_turn_rate(30.0, 4.0)

	assert_float(turn_rate).is_equal_approx(4.0 / 30.0, 0.0001)
	assert_float(turn_rate * 30.0).is_equal_approx(4.0, 0.0001)


func test_travel_speed_stays_positive_after_vehicle_spins() -> void:
	var speed: float = VehicleControl.travel_speed(Vector3(0.0, 0.0, -20.0))

	assert_float(speed).is_equal_approx(20.0, 0.001)


func test_forward_speed_ignores_lateral_and_vertical_motion() -> void:
	var speed: float = VehicleControl.forward_speed(
		Vector3(12.0, -5.0, 20.0),
		Vector3.BACK
	)

	assert_float(speed).is_equal_approx(20.0, 0.001)


func test_observer_camera_uses_fixed_world_offset() -> void:
	var position: Vector3 = VehicleControl.observer_camera_position(
		Vector3(10.0, 1.0, -4.0),
		Vector3(0.0, 3.0, 8.0)
	)

	assert_vector(position).is_equal_approx(
		Vector3(10.0, 4.0, 4.0),
		Vector3.ONE * 0.001
	)


func test_windowed_deceleration_uses_full_sample_window() -> void:
	var samples: Array[Dictionary] = [
		{"time": 0.0, "speed": 30.0},
		{"time": 0.05, "speed": 20.0},
		{"time": 0.1, "speed": 29.0},
	]

	var deceleration: float = VehicleControl.windowed_deceleration(
		samples,
		0.1
	)

	assert_float(deceleration).is_equal_approx(10.0, 0.001)


func test_deceleration_classification_separates_braking_and_collision() -> void:
	var braking: StringName = VehicleControl.classify_deceleration(
		8.0,
		1.0,
		2.0 * 9.80665
	)
	var collision: StringName = VehicleControl.classify_deceleration(
		25.0,
		1.0,
		2.0 * 9.80665
	)

	assert_str(braking).is_equal("braking")
	assert_str(collision).is_equal("collision")


func test_positive_speed_error_only_requests_throttle() -> void:
	var command: Dictionary = VehicleControl.split_speed_control(
		5.0,
		1.0,
		0.25,
		0.05,
		0.4
	)

	assert_float(command["throttle"]).is_greater(0.0)
	assert_float(command["brake"]).is_equal(0.0)


func test_negative_speed_error_only_requests_brake() -> void:
	var command: Dictionary = VehicleControl.split_speed_control(
		-5.0,
		0.0,
		0.25,
		0.05,
		0.4
	)

	assert_float(command["throttle"]).is_equal(0.0)
	assert_float(command["brake"]).is_greater(0.0)
	assert_float(command["brake"]).is_less_equal(1.0)


func test_speed_commands_remain_clamped() -> void:
	var accelerate: Dictionary = VehicleControl.split_speed_control(
		1000.0,
		1000.0,
		1.0,
		1.0,
		1.0
	)
	var decelerate: Dictionary = VehicleControl.split_speed_control(
		-1000.0,
		-1000.0,
		1.0,
		1.0,
		1.0
	)

	assert_float(accelerate["throttle"]).is_equal(1.0)
	assert_float(accelerate["brake"]).is_equal(0.0)
	assert_float(decelerate["throttle"]).is_equal(0.0)
	assert_float(decelerate["brake"]).is_equal(1.0)
