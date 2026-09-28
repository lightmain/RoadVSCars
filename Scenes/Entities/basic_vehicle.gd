extends VehicleBody3D

class_name BasicVehicle

@export_group("Vehicle Properties")  # 第二个参数是属性前缀（可选）
@export var MAX_STEER: float = 0.6981 #40度
@export var ENGINE_POWER: float = 300.0
@export var CAMERA_LERP_SPEED: float = 20.0
@export var STEER_SPEED: float = 2.5
@export var BRAKE_POWER: float = 40.0

@export_group("Control Settings")
@export var third_camera_available: bool = true
@export var manual_control: bool = false

@export_group("References")
@export var dynamic_road: DynamicRoad

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera
@onready var ai: BasicAI = $BasicAI

var lookat: Vector3

func _ready() -> void:
	lookat = global_position
	if third_camera_available:
		camera_3d.current = true
		reverse_camera.current = false
	else:
		camera_3d.current = false
		reverse_camera.current = false

func _physics_process(delta: float) -> void:
	if manual_control:
		_hand_control(delta)
	else:
		_ai_control(delta)

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
	$UI.set_speed_monitor(linear_velocity.length() * 3.6,\
		dynamic_road.camera.backward_speed * 3.6, throttle_command)
	
	# Set Camera
	if not third_camera_available:
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
