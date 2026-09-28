class_name BasicAI
extends Node

const VehicleControlMath = preload("res://Scripts/Driving/vehicle_control.gd")

@export_group("Path Tracking")
@export var wheel_base: float = 3.3
@export var minimum_lookahead: float = 7.0
@export var maximum_lookahead: float = 24.0
@export var lookahead_time: float = 0.65
@export var curvature_horizon: float = 200.0

@export_group("Speed Planning")
@export var maximum_speed: float = 80.0
@export var maximum_lateral_acceleration: float = 9.0
@export_range(0.1, 1.0) var curve_speed_safety_factor: float = 0.6
@export var path_end_margin: float = 10.0
@export var end_gap_gain: float = 0.5
@export var catch_up_speed_margin: float = 15.0
@export var comfortable_deceleration: float = 10.0

@export_group("Speed Control")
@export var speed_kp: float = 0.12
@export var speed_ki: float = 0.025
@export var speed_integral_limit: float = 12.0
@export var brake_gain: float = 1.4
@export var speed_deadband: float = 0.25

@onready var vehicle: BasicVehicle = get_parent()

var _path_distance: float = 0.0
var _path_index: int = 0
var _speed_integral: float = 0.0
var _previous_speed_error: float = 0.0


func _ready() -> void:
	if not vehicle:
		push_error("BasicAI: Vehicle parent not found.")
		set_physics_process(false)


func get_control(delta: float) -> Dictionary:
	var neutral := _neutral_control()
	if not vehicle or not vehicle.dynamic_road:
		return neutral

	var path: RefCounted = vehicle.dynamic_road.get_road_path()
	if not path or path.get_sample_count() < 2:
		_reset_speed_controller()
		return neutral

	var projection: Dictionary = path.project(vehicle.global_position, _path_index)
	if not projection["valid"]:
		_reset_speed_controller()
		return neutral

	_path_distance = maxf(_path_distance, projection["distance"])
	_path_index = maxi(_path_index, projection["segment_index"])

	var travel_speed := VehicleControlMath.travel_speed(vehicle.linear_velocity)
	var lookahead := clampf(
		minimum_lookahead + travel_speed * lookahead_time,
		minimum_lookahead,
		maximum_lookahead
	)
	var target: Dictionary = path.sample_at_distance(_path_distance + lookahead)
	if not target["valid"]:
		_reset_speed_controller()
		return neutral

	var local_target := vehicle.to_local(target["position"])
	var steering := VehicleControlMath.pure_pursuit_steering(
		local_target,
		wheel_base,
		vehicle.MAX_STEER
	)
	steering = VehicleControlMath.limit_steering_for_speed(
		steering,
		travel_speed,
		wheel_base,
		vehicle.MAX_STEER,
		maximum_lateral_acceleration
	)
	var target_speed := _calculate_target_speed(path)
	var speed_error := target_speed - travel_speed
	_update_speed_integral(speed_error, delta)
	var longitudinal := VehicleControlMath.split_speed_control(
		speed_error,
		_speed_integral,
		speed_kp,
		speed_ki,
		brake_gain
	)

	return {
		"throttle": longitudinal["throttle"],
		"brake": longitudinal["brake"],
		"steering": steering,
		"target_speed": target_speed,
		"path_distance": _path_distance,
	}


func _calculate_target_speed(path: RefCounted) -> float:
	var horizon_end := _path_distance + curvature_horizon
	var curvature_profile: Array = path.get_curvature_profile_between(
		_path_distance,
		horizon_end
	)
	var curve_limit := INF
	for point in curvature_profile:
		var approach_limit := VehicleControlMath.curve_approach_speed_limit(
			point["curvature"],
			maximum_lateral_acceleration * curve_speed_safety_factor,
			point["distance"] - _path_distance,
			comfortable_deceleration
		)
		curve_limit = minf(curve_limit, approach_limit)

	var end_gap: float = maxf(path.get_end_distance() - _path_distance, 0.0)
	var builder_speed := vehicle.get_target_speed()
	var catch_up_margin := maxf(catch_up_speed_margin, 0.0)
	var catch_up_limit := minf(
		maximum_speed + catch_up_margin,
		builder_speed + catch_up_margin
	)
	var following_speed := VehicleControlMath.moving_target_speed(
		builder_speed,
		end_gap,
		path_end_margin,
		end_gap_gain,
		catch_up_limit
	)
	var target_speed := following_speed
	target_speed = minf(target_speed, curve_limit)
	return maxf(target_speed, 0.0)


func _update_speed_integral(speed_error: float, delta: float) -> void:
	if delta <= 0.0 or not is_finite(speed_error):
		return
	if absf(speed_error) <= speed_deadband:
		_speed_integral = move_toward(_speed_integral, 0.0, delta)
		_previous_speed_error = speed_error
		return
	if signf(speed_error) != signf(_previous_speed_error):
		_speed_integral = 0.0
	_speed_integral = clampf(
		_speed_integral + speed_error * delta,
		-speed_integral_limit,
		speed_integral_limit
	)
	_previous_speed_error = speed_error


func _reset_speed_controller() -> void:
	_speed_integral = 0.0
	_previous_speed_error = 0.0


func _neutral_control() -> Dictionary:
	return {
		"throttle": 0.0,
		"brake": 0.0,
		"steering": 0.0,
		"target_speed": 0.0,
		"path_distance": _path_distance,
	}
