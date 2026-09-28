class_name VehicleControl
extends RefCounted

const MIN_DISTANCE: float = 0.0001


static func pure_pursuit_steering(
	local_target: Vector3,
	wheel_base: float,
	max_steer_angle: float
) -> float:
	var horizontal_target := Vector2(local_target.x, local_target.z)
	var distance_squared := horizontal_target.length_squared()
	if distance_squared <= MIN_DISTANCE or max_steer_angle <= 0.0:
		return 0.0

	# Positive commands steer left; the project's travel-forward axis is +Z.
	var heading_error := atan2(-local_target.x, local_target.z)
	var pursuit_curvature := 2.0 * sin(heading_error) / sqrt(distance_squared)
	var steer_angle := atan(maxf(wheel_base, 0.0) * pursuit_curvature)
	return clampf(steer_angle / max_steer_angle, -1.0, 1.0)


static func limit_steering_for_speed(
	steering_command: float,
	speed: float,
	wheel_base: float,
	max_steer_angle: float,
	max_lateral_accel: float
) -> float:
	if speed <= MIN_DISTANCE or max_steer_angle <= 0.0:
		return clampf(steering_command, -1.0, 1.0)
	var max_curvature := maxf(max_lateral_accel, 0.0) / (speed * speed)
	var safe_steer_angle := atan(maxf(wheel_base, 0.0) * max_curvature)
	var safe_command := clampf(safe_steer_angle / max_steer_angle, 0.0, 1.0)
	return clampf(steering_command, -safe_command, safe_command)


static func curvature_speed_limit(curvature: float, lateral_accel: float) -> float:
	if curvature <= MIN_DISTANCE:
		return INF
	return sqrt(maxf(lateral_accel, 0.0) / curvature)


static func curve_approach_speed_limit(
	curvature: float,
	lateral_accel: float,
	distance_to_curve: float,
	deceleration: float
) -> float:
	var curve_speed := curvature_speed_limit(curvature, lateral_accel)
	if is_inf(curve_speed):
		return INF
	return sqrt(
		curve_speed * curve_speed
		+ 2.0 * maxf(deceleration, 0.0) * maxf(distance_to_curve, 0.0)
	)


static func moving_target_speed(
	target_speed: float,
	current_gap: float,
	target_gap: float,
	gap_gain: float,
	maximum_speed: float = INF
) -> float:
	var gap_error := current_gap - maxf(target_gap, 0.0)
	var requested_speed := maxf(
		target_speed + gap_error * maxf(gap_gain, 0.0),
		0.0
	)
	return minf(requested_speed, maxf(maximum_speed, 0.0))


static func road_builder_turn_rate(
	speed: float,
	road_width: float,
	rotation_smoothness: float
) -> float:
	var minimum_turning_radius := maxf(road_width * 0.5 * 3.0, MIN_DISTANCE)
	return minf(
		maxf(rotation_smoothness, 0.0),
		maxf(speed, 0.0) / minimum_turning_radius
	)


static func maximum_turn_rate(speed: float, lateral_accel: float) -> float:
	return maxf(lateral_accel, 0.0) / maxf(absf(speed), MIN_DISTANCE)


static func travel_speed(linear_velocity: Vector3) -> float:
	var speed := linear_velocity.length()
	return speed if is_finite(speed) else 0.0


static func calculate_deceleration(
	previous_speed: float,
	current_speed: float,
	delta: float
) -> float:
	if delta <= MIN_DISTANCE:
		return 0.0
	if not is_finite(previous_speed) or not is_finite(current_speed):
		return 0.0
	return maxf((previous_speed - current_speed) / delta, 0.0)


static func stopping_speed_limit(
	remaining_distance: float,
	stop_margin: float,
	deceleration: float
) -> float:
	var usable_distance := maxf(remaining_distance - stop_margin, 0.0)
	return sqrt(2.0 * maxf(deceleration, 0.0) * usable_distance)


static func split_speed_control(
	speed_error: float,
	integral_error: float,
	proportional_gain: float,
	integral_gain: float,
	brake_gain: float
) -> Dictionary:
	var output := proportional_gain * speed_error + integral_gain * integral_error
	if not is_finite(output):
		return {"throttle": 0.0, "brake": 0.0}
	if output >= 0.0:
		return {
			"throttle": clampf(output, 0.0, 1.0),
			"brake": 0.0,
		}
	return {
		"throttle": 0.0,
		"brake": clampf(-output * maxf(brake_gain, 0.0), 0.0, 1.0),
	}
