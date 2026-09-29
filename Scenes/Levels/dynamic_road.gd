extends Node3D

class_name DynamicRoad

const RoadPathScript = preload("res://Scripts/Driving/road_path.gd")
const ROAD_COLOR := Color.WHITE
const MARKER_COLOR := Color.BLACK
const MARKER_INTERVAL: float = 10.0

@export var camera: RoadBuilderCamera
@export var road_material: Material           # 道路材质
# 配置参数
@export_group("Road Properties")
@export var road_width: float = 30.0          # 道路宽度
@export var road_thickness: float = 1         # 道路厚度
@export var min_segment_length: float = 0.15
@export var max_segment_length: float = 3.0
@export var curvature_threshold: float = 0.02  # 曲率阈值，大于此值则缩短分段
@export var max_segments: int = 4000           # 最大路段数
@export var path_sample_spacing: float = 2.0

# 内部变量
var segments: Array = []                      # 存储路段实例
var last_position: Vector3 = Vector3.ZERO     # 上一帧位置
var last_basis: Basis = Basis.IDENTITY        # 上一帧方向
var last_pitch: float = 0                     # 上一帧俯仰角
var segment_counter: int = 0                  # 路段计数器
var is_first_segment: bool = true             # 是否是第一段

var road_path: RefCounted
signal path_extended(end_distance: float)

func _ready() -> void:
	# 确保摄像机已设置
	if not camera:
		push_error("DynamicRoad: Camera not assigned!")
		set_process(false)
		return
	# 初始化位置
	_update_target_position()
	last_position = _get_camera_road_position()
	last_basis = _get_camera_road_basis()
	last_pitch = _get_camera_pitch()
	segment_counter = 0
	road_path = RoadPathScript.new(path_sample_spacing)
	road_path.reset(last_position, last_basis.z)
	segments.append({
		"instance": null,
		"position": last_position,
		"basis": last_basis,
		"pitch": last_pitch,
		"index": segment_counter,
		"path_distance": road_path.get_end_distance(),
		"road_distance": 0.0,
	})

func _process(_delta: float) -> void:
	# 获取当前目标位置和方向
	var current_position = _get_camera_road_position()
	var current_basis = _get_camera_road_basis()
	var current_pitch = _get_camera_pitch()
	var previous_sample_count: int = road_path.get_sample_count()
	road_path.append_control_point(current_position, current_basis.z)
	if road_path.get_sample_count() != previous_sample_count:
		path_extended.emit(road_path.get_end_distance())

	# 计算移动距离
	var distance_moved = last_position.distance_to(current_position)
	if distance_moved <= 0.0001:
		return
	var curvature = _calculate_curvature(current_basis, distance_moved, current_pitch)
	var adaptive_length = lerp(max_segment_length, min_segment_length, 
							  min(curvature / maxf(curvature_threshold, 0.0001), 1.0))
	if (distance_moved < adaptive_length):
		return
	
	# 根据移动距离生成多个段
	var segments_to_create := ceili(distance_moved / adaptive_length)
	
	for i in range(segments_to_create):
		# 计算插值位置
		var t = float(i + 1) / segments_to_create
		var segment_end = last_position.lerp(current_position, t)
		var segment_basis = last_basis.slerp(current_basis, t)
		var segment_pitch = lerp(last_pitch, current_pitch, t)
		
		# 生成路段
		_create_road_segment(segment_end, segment_basis, segment_pitch)
	
	# 更新位置
	last_position = current_position
	last_basis = current_basis
	last_pitch = current_pitch
	
	# 清理旧路段
	_cleanup_old_segments()
	
func _calculate_curvature(new_basis: Basis, distance: float, pitch: float) -> float:
	# 计算方向变化角度（弧度）
	var yaw_cur = abs(last_basis.z.angle_to(new_basis.z)) / distance
	var pitch_cur = abs(pitch - last_pitch) / distance
	return yaw_cur * 0.1 + pitch_cur * 0.9
	
# 获取摄像机下方3米位置
func _get_camera_road_position() -> Vector3:
	return camera.global_position + Vector3.DOWN * 5.0

# 获取道路方向（与摄像机视平面平行）
func _get_camera_road_basis() -> Basis:
	# 获取摄像机方向
	var cam_basis = camera.global_transform.basis
	
	# 创建与摄像机视平面平行的方向
	# 使用摄像机的右向量和上向量，忽略前向量
	var right = cam_basis.x.normalized()
	var up = Vector3.DOWN  # 保持道路水平
	var forward = right.cross(up).normalized()
	
	return Basis(right, up, forward).orthonormalized()

func _get_camera_pitch() -> float:
	# 获取摄像机的全局旋转（欧拉角）
	var camera_rotation = camera.global_rotation
	
	# 在Godot中，rotation.x对应俯仰角（pitch）
	# 返回值范围是[-PI, PI]弧度，0表示水平
	return camera_rotation.x
	

# 创建路段（使用StaticBody3D作为父节点）
func _create_road_segment(sposition: Vector3, sbasis: Basis, pitch: float) -> void:
	var previous_segment: Dictionary = segments[-1]
	var segment_start_distance: float = previous_segment["road_distance"]
	var previous_position: Vector3 = previous_segment["position"]
	var segment_end_distance := (
		segment_start_distance + previous_position.distance_to(sposition)
	)

	# 创建StaticBody3D作为路段容器
	var road_segment = StaticBody3D.new()
	road_segment.name = "RoadSegment_%d" % segment_counter
	segment_counter += 1
	
	# 重置位置和旋转（根据要求设为0）
	#road_segment.global_position = Vector3.ZERO
	#road_segment.global_basis = Basis.IDENTITY
	
	# 创建网格实例
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "RoadMesh"
	_create_segment_mesh(
		mesh_instance,
		sposition,
		sbasis,
		segment_start_distance,
		segment_end_distance
	)
	
	# 创建碰撞体
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "RoadCollision"
	_create_collision_shape(collision_shape, sposition, sbasis)
	
	# 添加为子节点
	road_segment.add_child(mesh_instance)
	road_segment.add_child(collision_shape)
	
	# 添加到场景和管理列表
	add_child(road_segment)
	segments.append({
		"instance": road_segment,
		"position": sposition,
		"basis": sbasis,
		"pitch": pitch,
		"index": segment_counter,
		"path_distance": road_path.get_end_distance(),
		"road_distance": segment_end_distance,
	})
		
	# 更新第一段标志
	if is_first_segment:
		is_first_segment = false

# 创建凸包碰撞体形状（不规则六面体）
func _create_collision_shape(collision_shape: CollisionShape3D, sposition: Vector3, sbasis: Basis) -> void:
	# 创建凸包形状
	var convex_shape = ConvexPolygonShape3D.new()
	
	# 计算方向向量
	var right_vector = -sbasis.x.normalized()
	var down_vector = Vector3.DOWN
	
	# 计算道路四个边角的全局位置
	var half_width = road_width / 2.0
	
	# 顶部四个点
	var top_left = sposition + half_width * right_vector
	var top_right = sposition - half_width * right_vector
	var bottom_left = top_left + down_vector * road_thickness
	var bottom_right = top_right + down_vector * road_thickness
	
	# 如果有上一段，使用上一段的点作为起点
	var prev_top_left = top_left
	var prev_top_right = top_right
	var prev_bottom_left = bottom_left
	var prev_bottom_right = bottom_right
	
	if segments.size() > 0:
		var prev_segment = segments[-1]
		var prev_position = prev_segment["position"]
		var prev_basis = prev_segment["basis"]
		var prev_right_vector = -prev_basis.x.normalized()
		
		prev_top_left = prev_position + half_width * prev_right_vector
		prev_top_right = prev_position - half_width * prev_right_vector
		prev_bottom_left = prev_top_left + down_vector * road_thickness
		prev_bottom_right = prev_top_right + down_vector * road_thickness
	
	# 定义8个顶点（形成不规则六面体）
	var vertices = PackedVector3Array([
		# 当前段顶部
		top_left,
		top_right,
		# 当前段底部
		bottom_left,
		bottom_right,
		# 上一段顶部
		prev_top_left,
		prev_top_right,
		# 上一段底部
		prev_bottom_left,
		prev_bottom_right
	])
	
	# 设置碰撞体顶点
	convex_shape.points = vertices
	collision_shape.shape = convex_shape
	
# 创建路段网格（顶部平面）
func _create_segment_mesh(
	mesh_instance: MeshInstance3D,
	sposition: Vector3,
	sbasis: Basis,
	start_distance: float,
	end_distance: float
) -> void:
	var mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 创建动态材质实例
	var dynamic_material = road_material.duplicate() if road_material else StandardMaterial3D.new()
	var start_marker := floori(start_distance / MARKER_INTERVAL)
	var end_marker := floori(end_distance / MARKER_INTERVAL)
	dynamic_material.albedo_color = (
		MARKER_COLOR if end_marker > start_marker else ROAD_COLOR
	)
	
	# 设置材质
	surface_tool.set_material(dynamic_material)
	
	# 计算方向向量
	var right_vector = -sbasis.x.normalized()
	var half_width = road_width / 2.0
	
	# 计算道路四个边角的全局位置
	var top_left = sposition + half_width * right_vector
	var top_right = sposition - half_width * right_vector
	
	# 如果有上一段，使用上一段的点作为起点
	var prev_top_left = top_left
	var prev_top_right = top_right
	
	if segments.size() > 0:
		var prev_segment = segments[-1]
		var prev_position = prev_segment["position"]
		var prev_basis = prev_segment["basis"]
		var prev_right_vector = -prev_basis.x.normalized()
		
		prev_top_left = prev_position + half_width * prev_right_vector
		prev_top_right = prev_position - half_width * prev_right_vector
	
	# 添加道路顶部（两个三角形）
	# 第一个三角形：左上 -> 右上 -> 右下
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(prev_top_left)
	
	surface_tool.set_uv(Vector2(1, 0))
	surface_tool.add_vertex(prev_top_right)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(top_right)
	
	# 第二个三角形：左上 -> 右下 -> 左下
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(prev_top_left)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(top_right)
	
	surface_tool.set_uv(Vector2(0, 1))
	surface_tool.add_vertex(top_left)
	
	# 生成网格
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	surface_tool.commit(mesh)
	mesh_instance.mesh = mesh

# 清理旧路段
func _cleanup_old_segments() -> void:
	if segments.size() > max_segments:
		var segments_to_remove = segments.size() - max_segments
		
		for i in range(segments_to_remove):
			var segment_data = segments.pop_front()
			if is_instance_valid(segment_data["instance"]):
				segment_data["instance"].queue_free()
		if not segments.is_empty():
			road_path.prune_before_distance(segments.front()["path_distance"])
				

# 更新目标位置（在摄像机脚本中调用）
func _update_target_position() -> void:
	# 这个方法由摄像机脚本每帧调用
	# 实际逻辑在_process中处理
	pass

# 调试功能：可视化所有路段
func debug_visualize_road() -> void:
	for i in range(segments.size()):
		var segment: StaticBody3D = segments[i]["instance"]
		if not is_instance_valid(segment):
			continue
		var mesh_instance := segment.get_node("RoadMesh") as MeshInstance3D
		var material := mesh_instance.mesh.surface_get_material(0)
		if material is StandardMaterial3D:
			var end_distance: float = segments[i]["road_distance"]
			var start_distance: float = (
				segments[i - 1]["road_distance"] if i > 0 else 0.0
			)
			var crosses_marker := (
				floori(end_distance / MARKER_INTERVAL)
				> floori(start_distance / MARKER_INTERVAL)
			)
			material.albedo_color = MARKER_COLOR if crosses_marker else ROAD_COLOR

func get_road_path() -> RefCounted:
	return road_path
