class_name VehicleFleet
extends Node3D

signal primary_vehicle_available(vehicle: BasicVehicle)
signal vehicle_liveness_changed(index: int, alive: bool)
signal observed_vehicle_changed(index: int, vehicle: BasicVehicle)

const ROAD_COLLISION_LAYER: int = 1
const VEHICLE_COLLISION_LAYER: int = 2
const VEHICLE_COLLISION_MASK: int = (
	ROAD_COLLISION_LAYER | VEHICLE_COLLISION_LAYER
)
const GRID_LATERAL_OFFSET: float = 3.0
const GRID_LONGITUDINAL_SPACING: float = 4.5
const GRID_FRONT_Z: float = 15.0
const CAMERA_ROAD: StringName = &"road"
const CAMERA_CHASE: StringName = &"chase"
const CAMERA_OBSERVER: StringName = &"observer"

@export var vehicle_scene: PackedScene
@export var dynamic_road: DynamicRoad
@export_range(1, 100, 1) var vehicle_count: int = 20
@export_group("Observation")
@export var observation_random_seed: int = 0
@export_group("Target Distribution")
@export var target_random_seed: int = 0
@export_range(0.0, 50.0, 0.5) var target_lateral_radius: float = 12.0
@export_range(0.0, 20.0, 0.5) var target_longitudinal_radius: float = 4.0
@export_range(0.0, 20.0, 0.5) var target_road_edge_margin: float = 3.0

var primary_vehicle: BasicVehicle
var observed_vehicle: BasicVehicle
var observed_vehicle_index: int = -1
var _vehicle_alive_states: Array[bool] = []
var _vehicles: Array[BasicVehicle] = []
var _camera_mode: StringName = CAMERA_CHASE
var _observation_random := RandomNumberGenerator.new()


func _ready() -> void:
	if not vehicle_scene:
		push_error("VehicleFleet: Vehicle scene is not assigned.")
		return
	if not dynamic_road:
		push_error("VehicleFleet: Dynamic road is not assigned.")
		return

	_vehicle_alive_states.resize(vehicle_count)
	_vehicle_alive_states.fill(false)
	_vehicles.resize(vehicle_count)
	_initialize_observation_random()
	var safe_lateral_radius := safe_lateral_target_radius(
		dynamic_road.road_width,
		target_lateral_radius,
		target_road_edge_margin
	)
	var variants := build_variants(
		vehicle_count,
		target_random_seed,
		safe_lateral_radius,
		target_longitudinal_radius
	)
	for index in variants.size():
		_spawn_vehicle(index, variants[index])
	_select_random_alive_vehicle()
	_activate_observed_camera.call_deferred()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_LEFT:
			cycle_observed_vehicle(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT:
			cycle_observed_vehicle(1)
			get_viewport().set_input_as_handled()


func _initialize_observation_random() -> void:
	if observation_random_seed == 0:
		_observation_random.randomize()
	else:
		_observation_random.seed = observation_random_seed


static func find_alive_index(
	alive_states: Array[bool],
	current_index: int,
	direction: int
) -> int:
	if alive_states.is_empty() or direction == 0:
		return -1
	var step_direction := 1 if direction > 0 else -1
	var start_index := current_index
	if start_index < 0 or start_index >= alive_states.size():
		start_index = -1 if step_direction > 0 else 0
	for step in range(1, alive_states.size() + 1):
		var candidate := posmod(
			start_index + step * step_direction,
			alive_states.size()
		)
		if alive_states[candidate]:
			return candidate
	return -1


func cycle_observed_vehicle(direction: int) -> void:
	var next_index := find_alive_index(
		_vehicle_alive_states,
		observed_vehicle_index,
		direction
	)
	if next_index >= 0 and next_index != observed_vehicle_index:
		_set_observed_vehicle(next_index)


func select_camera_mode(camera_mode: StringName) -> void:
	if camera_mode not in [CAMERA_ROAD, CAMERA_CHASE, CAMERA_OBSERVER]:
		push_warning("VehicleFleet: Unknown camera mode '%s'." % camera_mode)
		return
	_camera_mode = camera_mode
	if is_instance_valid(observed_vehicle):
		observed_vehicle.select_camera(camera_mode)
	elif dynamic_road and dynamic_road.camera:
		dynamic_road.camera.make_current()


func _activate_observed_camera() -> void:
	if is_instance_valid(observed_vehicle):
		observed_vehicle.select_camera(_camera_mode)


func _select_random_alive_vehicle() -> void:
	var alive_indices: Array[int] = []
	for index in _vehicle_alive_states.size():
		if _vehicle_alive_states[index]:
			alive_indices.append(index)
	if alive_indices.is_empty():
		_clear_observed_vehicle()
		return
	var random_position := _observation_random.randi_range(
		0,
		alive_indices.size() - 1
	)
	_set_observed_vehicle(alive_indices[random_position])


func _set_observed_vehicle(index: int) -> void:
	if (
		index < 0
		or index >= _vehicles.size()
		or not _vehicle_alive_states[index]
		or not is_instance_valid(_vehicles[index])
	):
		return
	if index == observed_vehicle_index:
		return

	if is_instance_valid(observed_vehicle):
		observed_vehicle.interface_enabled = false
		observed_vehicle.release_camera()
	observed_vehicle_index = index
	observed_vehicle = _vehicles[index]
	observed_vehicle.interface_enabled = true
	observed_vehicle.select_camera(_camera_mode)
	observed_vehicle_changed.emit(observed_vehicle_index, observed_vehicle)


func _clear_observed_vehicle() -> void:
	if is_instance_valid(observed_vehicle):
		observed_vehicle.interface_enabled = false
		observed_vehicle.release_camera()
	observed_vehicle = null
	observed_vehicle_index = -1
	if dynamic_road and dynamic_road.camera:
		dynamic_road.camera.make_current()
	observed_vehicle_changed.emit(-1, null)


static func build_variants(
	count: int,
	random_seed: int = 0,
	max_lateral_offset: float = 0.0,
	max_longitudinal_offset: float = 0.0
) -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	var random := RandomNumberGenerator.new()
	if random_seed == 0:
		random.randomize()
	else:
		random.seed = random_seed
	var lateral_radius := maxf(max_lateral_offset, 0.0)
	var longitudinal_radius := maxf(max_longitudinal_offset, 0.0)
	for index in maxi(count, 0):
		var hue := fmod(float(index) * 0.61803398875, 1.0)
		var profile := index % 5
		var secondary_profile := floori(float(index) / 5.0)
		var spawn_lateral_offset := (
			-GRID_LATERAL_OFFSET if index % 2 == 0 else GRID_LATERAL_OFFSET
		)
		variants.append({
			"spawn_offset": Vector3(
				spawn_lateral_offset,
				0.7,
				GRID_FRONT_Z - index * GRID_LONGITUDINAL_SPACING
			),
			"color": Color.from_hsv(hue, 0.72, 0.9),
			"suspension_stiffness": 70.0 + profile * 15.0,
			"suspension_travel": 0.32 + secondary_profile * 0.06,
			"damping_compression": 0.65 + profile * 0.08,
			"damping_relaxation": 0.75 + secondary_profile * 0.1,
			"wheel_friction_slip": 0.85 + profile * 0.08,
			"maximum_speed": 80.0,
			"maximum_lateral_acceleration": 6.5 + secondary_profile * 1.1,
			"lookahead_time": 0.48 + profile * 0.08,
			"speed_kp": 0.09 + secondary_profile * 0.015,
			"brake_gain": 1.1 + profile * 0.12,
			"target_lateral_offset": (
				-signf(spawn_lateral_offset)
				* random.randf_range(0.0, lateral_radius)
			),
			"target_longitudinal_offset": random.randf_range(
				-longitudinal_radius,
				longitudinal_radius
			),
		})
	return variants


static func safe_lateral_target_radius(
	road_width: float,
	requested_radius: float,
	road_edge_margin: float
) -> float:
	var safe_half_width := maxf(
		road_width * 0.5 - maxf(road_edge_margin, 0.0),
		0.0
	)
	return minf(maxf(requested_radius, 0.0), safe_half_width)


func _spawn_vehicle(index: int, variant: Dictionary) -> void:
	var vehicle := vehicle_scene.instantiate() as BasicVehicle
	if not vehicle:
		push_error("VehicleFleet: Vehicle scene root must be BasicVehicle.")
		return

	vehicle.name = "Vehicle%02d" % (index + 1)
	vehicle.position = variant["spawn_offset"]
	vehicle.dynamic_road = dynamic_road
	vehicle.collision_layer = VEHICLE_COLLISION_LAYER
	vehicle.collision_mask = VEHICLE_COLLISION_MASK
	vehicle.interface_enabled = false
	vehicle.third_camera_available = false
	vehicle.observer_camera_enabled = false
	vehicle.log_maximum_deceleration = index == 0
	vehicle.configure_variant(variant)
	add_child(vehicle)
	_vehicles[index] = vehicle
	_vehicle_alive_states[index] = true
	vehicle.tree_exiting.connect(_on_vehicle_tree_exiting.bind(index))
	vehicle_liveness_changed.emit(index, true)
	if index == 0:
		primary_vehicle = vehicle
		primary_vehicle_available.emit(vehicle)


func get_vehicle_alive_states() -> Array[bool]:
	return _vehicle_alive_states.duplicate()


func _on_vehicle_tree_exiting(index: int) -> void:
	if index < 0 or index >= _vehicle_alive_states.size():
		return
	if not _vehicle_alive_states[index]:
		return
	_vehicle_alive_states[index] = false
	_vehicles[index] = null
	vehicle_liveness_changed.emit(index, false)
	if index == observed_vehicle_index:
		_select_random_alive_vehicle()
