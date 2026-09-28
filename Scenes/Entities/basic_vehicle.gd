extends VehicleBody3D

class_name BasicVehicle

@export_group("Vehicle Properties")  # 第二个参数是属性前缀（可选）
@export var MAX_STEER = 0.6981 #40度
@export var ENGINE_POWER = 300
@export var CAMERA_LERP_SPEED = 20.0
@export var STEER_SPEED = 2.5
@export var BRAKE_POWER = 1.0

@export_group("Control Settings")
@export var third_camera_available: bool = true
@export var manual_control: bool = false

@export_group("References")
@export var dynamic_road: DynamicRoad

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera
@onready var ai: Node = $BasicAI

var lookat: Vector3
var navigation_points: Array = [] 

func _ready() -> void:
	lookat = global_position
	if third_camera_available:
		camera_3d.current = true
		reverse_camera.current = false
	else:
		camera_3d.current = false
		reverse_camera.current = false

	
	navigation_points = dynamic_road.get_navigation_points()
	dynamic_road.connect("new_navigation_point", self._on_new_navigation_point)

func _physics_process(delta: float) -> void:
	if manual_control:
		_hand_control(delta)
	else:
		_ai_control(delta)
	pop_navigation_points()
	print(reverse_camera.current)

func _ai_control(delta: float) -> void:
	var throttleCmd = ai.get_throttle(delta)
	var steeringCmd = ai.get_steering(delta)
	#print("throttle: %.2f | steering: %.2f" %\
		#[throttleCmd, steeringCmd])
	_basic_driving(throttleCmd, steeringCmd, 0, delta)
	

func _hand_control(delta: float) -> void:
	var throttleCmd = Input.get_axis("Backward", "Forward")
	var steeringCmd = Input.get_axis("Turn left", "Turn right")
	var brakeCmd = Input.is_action_pressed("Brake")
	_basic_driving(throttleCmd, steeringCmd, brakeCmd, delta)
	

# forwardCmd: 1 = forward, -1 = backward
# turningCmd: -1 = turn right, 1 = turn left
func _basic_driving(throttleCmd: float, steeringCmd: float, brakeCmd: float, delta: float) -> void:
	# Handle car physics
	var speed := linear_velocity.length()
	steering = move_toward(steering, -steeringCmd * MAX_STEER, delta * STEER_SPEED)
	var engine_force_value = throttleCmd * ENGINE_POWER
	var brake_value = brakeCmd * BRAKE_POWER
	if speed < 5.0 and not is_zero_approx(speed):
		engine_force = clampf(engine_force_value * 5.0 / speed, -500, 500)
	else:
		engine_force = engine_force_value
	brake = brake_value
	
	# Set UI
	$UI.set_speed_monitor(linear_velocity.length() * 3.6,\
		dynamic_road.camera.backward_speed * 3.6, throttleCmd)
	
	# Set Camera
	if not third_camera_available:
		camera_3d.current = false
		reverse_camera.current = false 
	else:
		camera_pivot.global_position = camera_pivot.global_position.\
			slerp(global_position, delta * CAMERA_LERP_SPEED)
		camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 4.0)
		lookat = lookat.lerp(global_position + linear_velocity, delta * 5.0)
		camera_3d.look_at(lookat)
		reverse_camera.look_at(lookat)
		_check_camera_switch()

func _check_camera_switch():
	var use_forward_cam = linear_velocity.dot(transform.basis.z) > 0 or linear_velocity.length() < 3
	camera_3d.current = use_forward_cam
	reverse_camera.current = not use_forward_cam

func _on_new_navigation_point(point):
	navigation_points.append(point)

func pop_navigation_points() -> void:
	while not navigation_points.is_empty():
		var next_point = navigation_points.front()
		if not has_passed_through(next_point):
			break
		navigation_points.pop_front()

func has_passed_through(navigation_point) -> bool:
	#var veh_local_pos = global_position - navigation_point["position"]
	#var basis_forward = basis.z
	#var dot = basis_forward.dot(veh_local_pos)
	return global_position.z > navigation_point["position"].z
	
func get_target_speed() -> float:
	return dynamic_road.camera.backward_speed
	
func is_reversing() -> bool:
	var forward_vector = global_transform.basis.z.normalized()
	var velocity_vector = linear_velocity.normalized()
	var dot_product = forward_vector.dot(velocity_vector)
	return dot_product < -0.3  # 添加阈值防止误判
