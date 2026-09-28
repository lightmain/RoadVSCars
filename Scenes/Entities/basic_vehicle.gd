extends VehicleBody3D

class_name BasicVehicle

const VehicleControlMath = preload("res://Scripts/Driving/vehicle_control.gd")
const GRAVITY_ACCELERATION: float = 9.80665

@export_group("Vehicle Properties")  # 第二个参数是属性前缀（可选）
@export var MAX_STEER: float = 0.6981 #40度
@export var ENGINE_POWER: float = 300.0
@export var CAMERA_LERP_SPEED: float = 20.0
@export var STEER_SPEED: float = 2.5
@export var BRAKE_POWER: float = 40.0

@export_group("Control Settings")
@export var third_camera_available: bool = true
@export var manual_control: bool = false

@export_group("Observer Camera")
@export var observer_camera_enabled: bool = true
@export var observer_camera_offset: Vector3 = Vector3(0.0, 3.0, 8.0)

@export_group("Diagnostics")
@export var log_maximum_deceleration: bool = true
@export_range(0.05, 1.0, 0.05) var deceleration_window: float = 0.1
@export_range(0.5, 10.0, 0.1) var collision_threshold_g: float = 2.0
@export_range(0.1, 10.0, 0.1) var deceleration_log_interval: float = 1.0

@export_group("References")
@export var dynamic_road: DynamicRoad

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera
@onready var observer_camera: Camera3D = $ObserverCamera
@onready var ai: BasicAI = $BasicAI

var lookat: Vector3
var _deceleration_samples: Array[Dictionary] = []
var _telemetry_time: float = 0.0
var _maximum_braking_deceleration: float = 0.0
var _maximum_collision_deceleration: float = 0.0
var _braking_peak_snapshot: Dictionary = {}
var _collision_peak_snapshot: Dictionary = {}
var _deceleration_log_elapsed: float = 0.0
var _braking_peak_changed: bool = false
var _collision_peak_changed: bool = false

func _ready() -> void:
	lookat = global_position
	_deceleration_samples.append({
		"time": _telemetry_time,
		"speed": VehicleControlMath.forward_speed(
			linear_velocity,
			global_transform.basis.z
		),
		"brake": 0.0,
	})
	if observer_camera_enabled:
		camera_3d.current = false
		reverse_camera.current = false
		call_deferred("_activate_observer_camera")
	elif third_camera_available:
		camera_3d.current = true
		reverse_camera.current = false
	else:
		camera_3d.current = false
		reverse_camera.current = false


func _process(_delta: float) -> void:
	if observer_camera_enabled:
		_update_observer_camera()


func _activate_observer_camera() -> void:
	if not observer_camera_enabled:
		return
	_update_observer_camera()
	observer_camera.make_current()


func _update_observer_camera() -> void:
	observer_camera.global_position = VehicleControlMath.observer_camera_position(
		global_position,
		observer_camera_offset
	)
	_look_at_if_valid(observer_camera, global_position)


func _physics_process(delta: float) -> void:
	_measure_deceleration(delta)
	if manual_control:
		_hand_control(delta)
	else:
		_ai_control(delta)


func _measure_deceleration(delta: float) -> void:
	if delta <= 0.0:
		return
	_telemetry_time += delta
	var current_speed := VehicleControlMath.forward_speed(
		linear_velocity,
		global_transform.basis.z
	)
	var brake_ratio := clampf(brake / maxf(BRAKE_POWER, 0.0001), 0.0, 1.0)
	_deceleration_samples.append({
		"time": _telemetry_time,
		"speed": current_speed,
		"brake": brake_ratio,
	})
	var cutoff := _telemetry_time - deceleration_window
	while (
		_deceleration_samples.size() > 2
		and _deceleration_samples[1]["time"] <= cutoff
	):
		_deceleration_samples.pop_front()
	if not log_maximum_deceleration:
		return

	_deceleration_log_elapsed += delta
	var deceleration := VehicleControlMath.windowed_deceleration(
		_deceleration_samples,
		deceleration_window
	)
	var window_brake := 0.0
	for sample in _deceleration_samples:
		window_brake = maxf(window_brake, sample["brake"])
	var category := VehicleControlMath.classify_deceleration(
		deceleration,
		window_brake,
		collision_threshold_g * GRAVITY_ACCELERATION
	)
	var snapshot := {
		"deceleration": deceleration,
		"speed": current_speed,
		"brake": window_brake,
	}
	if category == &"braking" and deceleration > _maximum_braking_deceleration:
		_maximum_braking_deceleration = deceleration
		_braking_peak_snapshot = snapshot
		_braking_peak_changed = true
	elif category == &"collision" and deceleration > _maximum_collision_deceleration:
		_maximum_collision_deceleration = deceleration
		_collision_peak_snapshot = snapshot
		_collision_peak_changed = true

	if _deceleration_log_elapsed < deceleration_log_interval:
		return
	if _braking_peak_changed:
		_log_deceleration_peak("braking", _braking_peak_snapshot)
		_braking_peak_changed = false
	if _collision_peak_changed:
		_log_deceleration_peak("collision", _collision_peak_snapshot)
		_collision_peak_changed = false
	_deceleration_log_elapsed = 0.0


func _log_deceleration_peak(category: String, snapshot: Dictionary) -> void:
	print(
		(
			"[VehicleTelemetry][%s] peak=%.2f m/s^2 (%.2f g), "
			+ "speed=%.1f km/h, brake=%.2f, window=%.2f s"
		)
		% [
			category,
			snapshot["deceleration"],
			snapshot["deceleration"] / GRAVITY_ACCELERATION,
			snapshot["speed"] * 3.6,
			snapshot["brake"],
			deceleration_window,
		]
	)


func _ai_control(delta: float) -> void:
	var command := ai.get_control(delta)
	_basic_driving(
		command["throttle"],
		command["steering"],
		command["brake"],
		delta
	)
	

func _hand_control(delta: float) -> void:
	var throttle_command := Input.get_axis("Backward", "Forward")
	var steering_command := Input.get_axis("Turn left", "Turn right")
	var brake_command := 1.0 if Input.is_action_pressed("Brake") else 0.0
	_basic_driving(throttle_command, steering_command, brake_command, delta)
	

func _basic_driving(
	throttle_command: float,
	steering_command: float,
	brake_command: float,
	delta: float
) -> void:
	# Handle car physics
	var speed := linear_velocity.length()
	steering = move_toward(
		steering,
		-steering_command * MAX_STEER,
		delta * STEER_SPEED
	)
	var engine_force_value := throttle_command * ENGINE_POWER
	var brake_value := brake_command * BRAKE_POWER
	if speed < 5.0 and not is_zero_approx(speed):
		engine_force = clampf(engine_force_value * 5.0 / speed, -500, 500)
	else:
		engine_force = engine_force_value
	brake = brake_value
	
	# Set UI
	$UI.set_speed_monitor(
		linear_velocity.length() * 3.6,
		dynamic_road.camera.backward_speed * 3.6
	)
	$UI.set_control_monitor(
		-steering / maxf(MAX_STEER, 0.0001),
		throttle_command,
		brake_command
	)
	
	# Set Camera
	if observer_camera_enabled:
		camera_3d.current = false
		reverse_camera.current = false
	elif not third_camera_available:
		camera_3d.current = false
		reverse_camera.current = false 
	else:
		camera_pivot.global_position = camera_pivot.global_position.\
			slerp(global_position, delta * CAMERA_LERP_SPEED)
		camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 4.0)
		lookat = lookat.lerp(global_position + linear_velocity, delta * 5.0)
		_look_at_if_valid(camera_3d, lookat)
		_look_at_if_valid(reverse_camera, lookat)
		_check_camera_switch()


func _look_at_if_valid(camera: Camera3D, target: Vector3) -> void:
	var direction := target - camera.global_position
	if direction.length_squared() <= 0.0001:
		return
	if absf(direction.normalized().dot(Vector3.UP)) >= 0.999:
		return
	camera.look_at(target)


func _check_camera_switch() -> void:
	var use_forward_cam: bool = (
		linear_velocity.dot(transform.basis.z) > 0
		or linear_velocity.length() < 3
	)
	camera_3d.current = use_forward_cam
	reverse_camera.current = not use_forward_cam

func get_target_speed() -> float:
	return dynamic_road.camera.backward_speed
