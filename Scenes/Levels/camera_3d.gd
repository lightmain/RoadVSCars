extends Camera3D

class_name RoadBuilderCamera

const VehicleControlMath = preload("res://Scripts/Driving/vehicle_control.gd")

@export var dynamic_road: DynamicRoad
# 配置参数
@export var enabled: bool = true
@export var mouse_capture: bool = false
@export var mouse_input_enabled: bool = true
@export_group("Properties")
@export var backward_speed_start: float = 7.0  # 初始后退速度（单位/秒）
@export var backward_acceleration: float = 0.5 # 后退速度增加速度
@export var backward_speed_max: float = 80.0
@export var rotation_sensitivity: float = 0.001  # 鼠标旋转灵敏度
@export var rotation_smoothness: float = 8.0  # 旋转平滑度（值越大越平滑）
@export var maximum_lateral_acceleration: float = 9.0
@export var max_pitch_angle: float = 35  # 最大俯仰角度（度）
@export var min_pitch_angle: float = -35  # 最小俯仰角度（度）
@export var max_yaw_angle: float = 170

# 内部变量
var backward_speed: float = 0
var _target_rotation: Vector3 = Vector3.ZERO
var _current_rotation: Vector3 = Vector3.ZERO
var _mouse_position: Vector2 = Vector2.ZERO
var _is_first_frame: bool = true

func _ready() -> void:
	# 设置鼠标模式
	if mouse_capture:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if enabled:
		current = true
	else:
		current = false
	
	backward_speed = backward_speed_start
	# 初始化旋转
	_target_rotation = rotation
	_current_rotation = rotation
	
	# 连接退出信号
	get_tree().get_root().connect("close_requested", \
		Callable(self, "_on_window_close_requested"))

func _input(event: InputEvent) -> void:
	# 处理鼠标移动事件
	if event is InputEventMouseMotion:
		_mouse_position = event.position
		
		# 获取视口大小
		var viewport_size = get_viewport().size
		
		# 计算鼠标在屏幕上的归一化位置 (0.0-1.0)
		var normalized_x = - (_mouse_position.x / viewport_size.x - 0.5)
		var normalized_y = _mouse_position.y / viewport_size.y
		
		# 将归一化位置映射到旋转角度范围
		# 偏航 (左右转动)：屏幕左侧为0°，右侧为360°
		_target_rotation.y = -normalized_x *	deg_to_rad(max_yaw_angle) # TAU = 2 * PI = 360°
		
		# 俯仰 (上下转动)：屏幕顶部为-90°，底部为+90°
		_target_rotation.x = lerp(
			deg_to_rad(min_pitch_angle), 
			deg_to_rad(max_pitch_angle),
			normalized_y
		)
	
	# 处理按键事件
	if event is InputEventKey:
		if event.pressed:
			# ESC键释放鼠标
			if event.keycode == KEY_ESCAPE and mouse_capture:
				if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
			# F键切换全屏
			if event.keycode == KEY_F:
				get_window().mode = (
					Window.MODE_FULLSCREEN 
					if get_window().mode != Window.MODE_FULLSCREEN 
					else Window.MODE_WINDOWED
				)

func _process(delta: float) -> void:
	# 跳过第一帧避免跳变
	if _is_first_frame:
		_is_first_frame = false
		return
		
	backward_speed = minf(
		backward_speed + backward_acceleration * delta,
		backward_speed_max
	)
	
	if mouse_input_enabled:
		var road_width := dynamic_road.road_width if dynamic_road else 1.0
		var turning_angular_velocity := VehicleControlMath.road_builder_turn_rate(
			backward_speed,
			road_width,
			rotation_smoothness
		)
		_current_rotation = _current_rotation.lerp(
			_target_rotation,
			minf(turning_angular_velocity * delta, 1.0)
		)
		rotation = _current_rotation
	
	
	# 摄像机向后退（沿着自身负Z轴方向）
	var move_direction = global_transform.basis.z
	global_position += move_direction * backward_speed * delta
	
	if dynamic_road:
		dynamic_road._update_target_position()

# 窗口关闭时恢复鼠标
func _on_window_close_requested() -> void:
	if mouse_capture:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# 退出时恢复鼠标
func _exit_tree() -> void:
	if mouse_capture:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
