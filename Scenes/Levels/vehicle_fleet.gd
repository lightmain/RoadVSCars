class_name VehicleFleet
extends Node3D

const VEHICLE_COLLISION_LAYER: int = 2
const VEHICLE_COLLISION_MASK: int = 1
const COLUMN_COUNT: int = 4
const COLUMN_SPACING: float = 4.0
const ROW_SPACING: float = 6.0

@export var vehicle_scene: PackedScene
@export var dynamic_road: DynamicRoad
@export_range(1, 100, 1) var vehicle_count: int = 20


func _ready() -> void:
	if not vehicle_scene:
		push_error("VehicleFleet: Vehicle scene is not assigned.")
		return
	if not dynamic_road:
		push_error("VehicleFleet: Dynamic road is not assigned.")
		return

	var variants := build_variants(vehicle_count)
	for index in variants.size():
		_spawn_vehicle(index, variants[index])


static func build_variants(count: int) -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	var row_count := ceili(float(count) / COLUMN_COUNT)
	for index in maxi(count, 0):
		var column := index % COLUMN_COUNT
		var row := floori(float(index) / COLUMN_COUNT)
		var hue := fmod(float(index) * 0.61803398875, 1.0)
		var profile := index % 5
		var secondary_profile := floori(float(index) / 5.0)
		variants.append({
			"spawn_offset": Vector3(
				(float(column) - (COLUMN_COUNT - 1) * 0.5) * COLUMN_SPACING,
				0.7,
				(float(row) - (row_count - 1) * 0.5) * ROW_SPACING
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
		})
	return variants


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
	vehicle.interface_enabled = index == 0
	vehicle.third_camera_available = index == 0
	vehicle.observer_camera_enabled = false
	vehicle.log_maximum_deceleration = index == 0
	vehicle.configure_variant(variant)
	add_child(vehicle)
