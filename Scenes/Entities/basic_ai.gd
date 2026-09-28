extends Node

class_name BasicAI

@export var look_ahead_seconds: float = 2.0  # 预瞄距离
# PID控制器参数
@export_group("Steering")
@export var steer_kp: float = 0.5
@export var steer_ki: float = 0.01
@export var steer_kd: float = 0.1
const STEERING_INTEGRAL_LIMIT: float = 10.0

@export_group("Speed")
@export var speed_kp: float = 0.5
@export var speed_ki: float = 0.01
@export var speed_kd: float = 0.1
const SPEED_INTEGRAL_LIMIT: float = 10.0

@export_group("Distance")
@export var dist_kp: float = -0.5
@export var dist_ki: float = -0.01
@export var dist_kd: float = -0.1
const DISTANCE_INTEGRAL_LIMIT: float = 5.0
@export var ideal_distance = 20.0
@export var ideal_distance_min = 12.0
@export var ideal_distance_max = 35.0
@export var transition_width = 2.0

# 路径点管理
var steering_integral_error: float = 0.0   # 积分误差
var steering_previous_error: float = 0.0   # 上一次误差
var speed_integral_error: float = 0.0   # 积分误差
var speed_previous_error: float = 0.0   # 上一次误差
var distance_integral_error: float = 0.0   # 积分误差
var distance_previous_error: float = 0.0   # 上一次误差

# 车辆和路径管理器引用
@onready var vehicle: BasicVehicle = get_parent()
#@onready var navigation_points = vehicle.navigation_points

func _ready() -> void:
	# 确保车辆已连接
	if not vehicle:
		push_error("BasicAI: Vehicle parent not found!")
		set_process(false)
		return

#### 油门控制 ####
#################
# 获取油门指令 (0.0 到 1.0)
func get_throttle(delta: float) -> float:
	var target_point = _get_target_point()
	var dot_res = vehicle.basis.z.dot(target_point - vehicle.global_position)
	#print(target_point - vehicle.global_position)
	if dot_res < 0: 
		return 0.1
	# 获取当前速度 (km/h)
	var current_speed = vehicle.linear_velocity.length()
	
	# 目标速度（根据路径曲率调整）
	var target_speed = _calculate_target_speed()
	# 速度误差
	var speed_lateral_error = target_speed - current_speed
	
	# PID控制器
	speed_integral_error += speed_lateral_error * delta
	speed_integral_error = \
		clamp(speed_integral_error, -SPEED_INTEGRAL_LIMIT, SPEED_INTEGRAL_LIMIT)
	var speed_derivative_error = \
		(speed_lateral_error - speed_previous_error) / delta
	speed_previous_error = speed_lateral_error
	
	# 计算转向指令
	var throttle = \
		(speed_kp * speed_lateral_error) + \
		(speed_ki * speed_integral_error) + \
		(speed_kd * speed_derivative_error)	
	# 应用距离控制约束
	throttle = _apply_distance_constraint(throttle, delta)
	#print("raw throttle: %.2f | [elat, eint, ed]: [%.1f, %.1f, %.1f]" % \
		#[throttle, speed_lateral_error, speed_integral_error, speed_derivative_error])
	# 限制油门范围
	return clamp(throttle, -1.0, 1.0)

# 计算目标速度（基于路径曲率）
# 计算目标速度（基于路径曲率和距离）
func _calculate_target_speed() -> float:
	if vehicle.navigation_points.size() == 0:
		return 0.0
	
	# 获取当前路径段的曲率
	var curvature = _calculate_path_curvature()
	
	# 根据曲率调整速度（曲率越大，速度越低）
	var speed_factor = 1.0 / (1.0 + curvature * 0.1)
	
	# 基础速度限制
	var base_max_speed = vehicle.get_target_speed()
	
	# 根据到最后一个路径点的距离调整最大速度
	var distance_adjustment = 1.0
	if vehicle.navigation_points.size() > 1:
		var last_point = vehicle.navigation_points.back()["position"]
		var distance_to_last = vehicle.global_transform.origin.distance_to(last_point)
		
		# 距离越近，速度应该越低
		distance_adjustment = clamp(distance_to_last / 50.0, 0.5, 1.0)
	
	# 最终目标速度
	var target_speed = base_max_speed * speed_factor * distance_adjustment
	
	# 调试输出
	#print("Curvature: %.2f | DistAdj: %.2f | TargetSpeed: %.2f" % [
		#curvature, distance_adjustment, target_speed
	#])
	
	return target_speed

# 计算路径曲率
func _calculate_path_curvature() -> float:
	if vehicle.navigation_points.size() < 3:
		return 0.0

	# 使用更多点计算平均曲率
	var total_curvature = 0.0
	var point_count = min(5, vehicle.navigation_points.size() - 2)

	for i in range(point_count):
		var prev_point = vehicle.navigation_points[i]["position"]
		var current_point = vehicle.navigation_points[i+1]["position"]
		var next_point = vehicle.navigation_points[i+2]["position"]

		# 计算向量
		var vec1 = (current_point - prev_point).normalized()
		var vec2 = (next_point - current_point).normalized()

		# 计算角度变化
		var angle = acos(vec1.dot(vec2))

		# 计算曲率（角度/距离）
		var distance = prev_point.distance_to(next_point)
		total_curvature += abs(angle) / max(distance, 0.1)

	return total_curvature / point_count

# 应用距离约束
func _apply_distance_constraint(throttle: float, delta: float) -> float:
	# 检查是否有有效的路径点
	if vehicle.navigation_points.size() < 1:
		return throttle
	
	# 获取最后一个路径点位置
	var last_point = vehicle.navigation_points.back()["position"]
	
	# 计算到最后一个路径点的距离
	var distance_to_last = vehicle.global_position.distance_to(last_point)
	
	# 计算距离误差
	var distance_lateral_error = distance_to_last - ideal_distance
	
	distance_integral_error += distance_lateral_error * delta
	distance_integral_error = \
		clamp(distance_integral_error, -DISTANCE_INTEGRAL_LIMIT, DISTANCE_INTEGRAL_LIMIT)
	
	var distance_derivative_error = (distance_lateral_error - distance_previous_error) / delta
	distance_previous_error = distance_lateral_error
	
	# 计算距离控制输出（正值表示需要加速，负值表示需要减速）
	var distance_output = \
		(dist_kp * distance_lateral_error) + \
		(dist_ki * distance_integral_error) + \
		(dist_kd * distance_derivative_error)
	
	# 根据距离调整油门
	#print("distance to last: %.2f | distance_output: %.2f | distance_lateral_error: %.3f" % \
		#[distance_to_last, distance_output,distance_lateral_error])
	if distance_to_last < ideal_distance_min:
		# 太接近终点，减速
		#print("TOO CLOSE")
		return min(throttle, distance_output)
	elif distance_to_last > ideal_distance_max:
		# 离终点太远，加速
		#print("TOO FAR")
		return max(throttle, distance_output)
	else:
		# 在理想范围内，使用原始油门值
		# 计算过渡因子（0-1之间的值）
		var transition_factor = 0.0
		# 接近下限的过渡区
		if distance_to_last < ideal_distance:
			transition_factor = 1.0 - (distance_to_last - ideal_distance_min) / (ideal_distance - ideal_distance_min)
			#print("IDEAL CLOSER: %.2f" % transition_factor)
			return lerp(throttle, min(throttle, distance_output), transition_factor)
		else:
			transition_factor = (distance_to_last - ideal_distance) / (ideal_distance_max - ideal_distance)
			#print("IDEAL FARER: %.2f" % transition_factor)
			return lerp(throttle, max(throttle, distance_output), transition_factor)


#### 转向控制 ####
#################
# 获取转向指令 (-1.0 到 1.0)
func get_steering(delta: float) -> float:
	# 获取目标点
	var target_point = _get_target_point()
	
	# 计算横向误差（车辆局部坐标系）
	var local_target = vehicle.to_local(target_point)
	var steering_lateral_error = atan2(-local_target.x, abs(local_target.z))  # 正值表示目标在右侧
	if local_target.z < 0:
		steering_lateral_error = PI if (-local_target.x > 0) else -PI
	#print("local_target: " , target_point)
	# PID控制器
	steering_integral_error += steering_lateral_error * delta
	steering_integral_error = \
		clamp(steering_integral_error, -STEERING_INTEGRAL_LIMIT, STEERING_INTEGRAL_LIMIT)
	var steering_derivative_error = \
		(steering_lateral_error - steering_previous_error) / delta
	steering_previous_error = steering_lateral_error
	
	# 计算转向指令
	var steering = \
		(steer_kp * steering_lateral_error) + \
		(steer_ki * steering_integral_error) + \
		(steer_kd * steering_derivative_error)
	
	if vehicle.is_reversing():
		steering = -steering
	# 限制转向范围
	return clamp(steering, -1.0, 1.0)
	
# 获取目标点（预瞄点）
func _get_target_point() -> Vector3:
	if vehicle.navigation_points.size() == 0:
		return vehicle.global_position

	for i in range(vehicle.navigation_points.size()):
		var distance = vehicle.global_position.distance_to(vehicle.navigation_points[i]["position"])
		#print("Lookahead distance: %.2f" % [look_ahead_seconds * vehicle.linear_velocity.length()])
		if distance > look_ahead_seconds * vehicle.linear_velocity.length():
			return vehicle.navigation_points[i]["position"]
	
	return vehicle.navigation_points.back()["position"]
