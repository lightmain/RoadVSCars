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


static func heading_recovery_control(
	local_target: Vector3,
	was_active: bool,
	enter_angle: float,
	exit_angle: float,
	planned_target_speed: float,
	recovery_target_speed: float
) -> Dictionary:
	var safe_planned_speed := (
		maxf(planned_target_speed, 0.0)
		if is_finite(planned_target_speed)
		else 0.0
	)
	var horizontal_target := Vector2(local_target.x, local_target.z)
	if (
		not is_finite(horizontal_target.x)
		or not is_finite(horizontal_target.y)
		or horizontal_target.length_squared() <= MIN_DISTANCE
	):
		return {
			"active": false,
			"steering": 0.0,
			"target_speed": safe_planned_speed,
		}

	var safe_enter_angle := clampf(absf(enter_angle), 0.0, PI)
	var safe_exit_angle := clampf(absf(exit_angle), 0.0, safe_enter_angle)
	var heading_error := atan2(-horizontal_target.x, horizontal_target.y)
	var heading_magnitude := absf(heading_error)
	var threshold := safe_exit_angle if was_active else safe_enter_angle
	var is_active := heading_magnitude + MIN_DISTANCE >= threshold
	if not is_active:
		return {
			"active": false,
			"steering": 0.0,
			"target_speed": safe_planned_speed,
		}

	var steering := signf(heading_error)
	if absf(horizontal_target.x) <= MIN_DISTANCE and horizontal_target.y < 0.0:
		steering = 1.0
	var safe_recovery_speed := (
		maxf(recovery_target_speed, 0.0)
		if is_finite(recovery_target_speed)
		else 0.0
	)
	return {
		"active": true,
		"steering": steering,
		"target_speed": minf(safe_planned_speed, safe_recovery_speed),
	}


static func offset_path_target(
	position: Vector3,
	tangent: Vector3,
	lateral_offset: float
) -> Vector3:
	var road_right := Vector3.UP.cross(tangent)
	if road_right.length_squared() <= MIN_DISTANCE:
		return position
	return position + road_right.normalized() * lateral_offset


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


static func distance_target_speed(
	current_gap: float,
	target_gap: float,
	deceleration: float,
	maximum_speed: float
) -> float:
	var stopping_limit := stopping_speed_limit(
		current_gap,
		target_gap,
		deceleration
	)
	return minf(stopping_limit, maxf(maximum_speed, 0.0))


static func is_outside_road_bounds(
	vehicle_position: Vector3,
	road_position: Vector3,
	road_tangent: Vector3,
	road_width: float,
	lateral_margin: float,
	vertical_drop_limit: float
) -> bool:
	var horizontal_tangent := Vector2(road_tangent.x, road_tangent.z)
	var horizontal_offset := Vector2(
		vehicle_position.x - road_position.x,
		vehicle_position.z - road_position.z
	)
	var lateral_distance := horizontal_offset.length()
	if horizontal_tangent.length_squared() > MIN_DISTANCE:
		var road_right := Vector2(
			horizontal_tangent.y,
			-horizontal_tangent.x
		).normalized()
		lateral_distance = absf(horizontal_offset.dot(road_right))

	var lateral_limit := (
		maxf(road_width, 0.0) * 0.5 + maxf(lateral_margin, 0.0)
	)
	var vertical_drop := road_position.y - vehicle_position.y
	return (
		lateral_distance > lateral_limit
		or vertical_drop > maxf(vertical_drop_limit, 0.0)
	)


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


static func forward_speed(
	linear_velocity: Vector3,
	forward_direction: Vector3
) -> float:
	if forward_direction.length_squared() <= MIN_DISTANCE:
		return 0.0
	var speed := linear_velocity.dot(forward_direction.normalized())
	return maxf(speed, 0.0) if is_finite(speed) else 0.0


static func observer_camera_position(
	target_position: Vector3,
	world_offset: Vector3
) -> Vector3:
	return target_position + world_offset


static func windowed_deceleration(
	samples: Array[Dictionary],
	window_seconds: float
) -> float:
	if samples.size() < 2 or window_seconds <= MIN_DISTANCE:
		return 0.0
	var oldest: Dictionary = samples.front()
	var newest: Dictionary = samples.back()
	var elapsed: float = newest["time"] - oldest["time"]
	if elapsed + MIN_DISTANCE < window_seconds:
		return 0.0
	var previous_speed: float = oldest["speed"]
	var current_speed: float = newest["speed"]
	if not is_finite(previous_speed) or not is_finite(current_speed):
		return 0.0
	return maxf((previous_speed - current_speed) / elapsed, 0.0)


static func classify_deceleration(
	deceleration: float,
	brake_ratio: float,
	collision_threshold: float
) -> StringName:
	if deceleration <= 0.0:
		return &""
	if deceleration >= maxf(collision_threshold, 0.0):
		return &"collision"
	if brake_ratio > 0.01:
		return &"braking"
	return &""


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
