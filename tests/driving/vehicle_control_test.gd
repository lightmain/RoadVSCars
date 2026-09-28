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


func test_turn_rate_respects_lateral_acceleration_limit() -> void:
	var turn_rate: float = VehicleControl.maximum_turn_rate(30.0, 4.0)

	assert_float(turn_rate).is_equal_approx(4.0 / 30.0, 0.0001)
	assert_float(turn_rate * 30.0).is_equal_approx(4.0, 0.0001)


func test_travel_speed_stays_positive_after_vehicle_spins() -> void:
	var speed: float = VehicleControl.travel_speed(Vector3(0.0, 0.0, -20.0))

	assert_float(speed).is_equal_approx(20.0, 0.001)


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
