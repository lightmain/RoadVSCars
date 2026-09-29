class_name DrivingUI
extends Control

signal camera_selected(camera_mode: StringName)

const CAMERA_ROAD: StringName = &"road"
const CAMERA_CHASE: StringName = &"chase"
const CAMERA_OBSERVER: StringName = &"observer"
const FLEET_STATUS_CAPACITY: int = 20

@export var vehicle_fleet: VehicleFleet

@onready var _steering_left: ProgressBar = \
	$ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left
@onready var _steering_right: ProgressBar = \
	$ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Right
@onready var _throttle: ProgressBar = \
	$ControlMonitor/VBoxContainer/ThrottleRow/Throttle
@onready var _brake: ProgressBar = \
	$ControlMonitor/VBoxContainer/BrakeRow/Brake
@onready var _road_camera_button: Button = \
	$CameraSelector/MarginContainer/Buttons/RoadCamera
@onready var _chase_camera_button: Button = \
	$CameraSelector/MarginContainer/Buttons/ChaseCamera
@onready var _observer_camera_button: Button = \
	$CameraSelector/MarginContainer/Buttons/ObserverCamera
@onready var _fleet_title: Label = \
	$FleetStatus/MarginContainer/VBoxContainer/Title
@onready var _fleet_status_grid: GridContainer = \
	$FleetStatus/MarginContainer/VBoxContainer/StatusGrid

var _observed_vehicle: BasicVehicle
var _observed_vehicle_index: int = -1
var _fleet_alive_states: Array[bool] = []
var _fleet_status_labels: Array[Label] = []
var _alive_style: StyleBoxFlat
var _dead_style: StyleBoxFlat
var _observed_alive_style: StyleBoxFlat
var _observed_dead_style: StyleBoxFlat


func _ready() -> void:
	_road_camera_button.pressed.connect(
		set_camera_mode.bind(CAMERA_ROAD, true)
	)
	_chase_camera_button.pressed.connect(
		set_camera_mode.bind(CAMERA_CHASE, true)
	)
	_observer_camera_button.pressed.connect(
		set_camera_mode.bind(CAMERA_OBSERVER, true)
	)
	camera_selected.connect(_on_camera_selected)
	_build_fleet_status_slots()
	_bind_vehicle_fleet()


func set_speed_monitor(speed: float, camera_speed: float) -> void:
	$SpeedMonitor/MarginContainer/Label.text = \
		"Speed: %.2f\nCamera speed: %.2f" % [speed, camera_speed]


func set_control_monitor(
	steering: float,
	throttle: float,
	brake: float
) -> void:
	var safe_steering := clampf(steering, -1.0, 1.0)
	_steering_left.value = maxf(safe_steering, 0.0)
	_steering_right.value = maxf(-safe_steering, 0.0)
	_throttle.value = clampf(throttle, 0.0, 1.0)
	_brake.value = clampf(brake, 0.0, 1.0)


func set_camera_mode(camera_mode: StringName, emit_selection: bool = false) -> void:
	if camera_mode not in [CAMERA_ROAD, CAMERA_CHASE, CAMERA_OBSERVER]:
		push_warning("UI: Unknown camera mode '%s'." % camera_mode)
		return

	_road_camera_button.button_pressed = camera_mode == CAMERA_ROAD
	_chase_camera_button.button_pressed = camera_mode == CAMERA_CHASE
	_observer_camera_button.button_pressed = camera_mode == CAMERA_OBSERVER
	if emit_selection:
		camera_selected.emit(camera_mode)


func _bind_vehicle_fleet() -> void:
	if not vehicle_fleet:
		return
	vehicle_fleet.vehicle_liveness_changed.connect(
		_on_vehicle_liveness_changed
	)
	vehicle_fleet.observed_vehicle_changed.connect(
		_on_observed_vehicle_changed
	)
	_sync_fleet_status(vehicle_fleet.get_vehicle_alive_states())
	_on_observed_vehicle_changed(
		vehicle_fleet.observed_vehicle_index,
		vehicle_fleet.observed_vehicle
	)


func _on_observed_vehicle_changed(
	index: int,
	vehicle: BasicVehicle
) -> void:
	if vehicle == _observed_vehicle and index == _observed_vehicle_index:
		return
	if (
		is_instance_valid(_observed_vehicle)
		and _observed_vehicle.telemetry_updated.is_connected(
			_on_vehicle_telemetry_updated
		)
	):
		_observed_vehicle.telemetry_updated.disconnect(
			_on_vehicle_telemetry_updated
		)
	_observed_vehicle = vehicle
	_observed_vehicle_index = index
	if is_instance_valid(_observed_vehicle):
		_observed_vehicle.telemetry_updated.connect(
			_on_vehicle_telemetry_updated
		)
	for status_index in _fleet_status_labels.size():
		_set_vehicle_status(
			status_index,
			_fleet_alive_states[status_index]
		)


func _on_camera_selected(camera_mode: StringName) -> void:
	if vehicle_fleet:
		vehicle_fleet.select_camera_mode(camera_mode)


func _on_vehicle_telemetry_updated(
	speed: float,
	camera_speed: float,
	steering: float,
	throttle: float,
	brake: float
) -> void:
	set_speed_monitor(speed, camera_speed)
	set_control_monitor(steering, throttle, brake)


func _build_fleet_status_slots() -> void:
	_alive_style = _create_status_style(Color(0.12, 0.52, 0.3, 0.96))
	_dead_style = _create_status_style(Color(0.19, 0.21, 0.25, 0.88))
	_observed_alive_style = _create_status_style(
		Color(0.12, 0.52, 0.3, 0.96),
		true
	)
	_observed_dead_style = _create_status_style(
		Color(0.19, 0.21, 0.25, 0.88),
		true
	)
	_fleet_alive_states.resize(FLEET_STATUS_CAPACITY)
	_fleet_alive_states.fill(false)
	for index in FLEET_STATUS_CAPACITY:
		var status := Label.new()
		status.name = "Vehicle%02d" % (index + 1)
		status.text = "%02d" % (index + 1)
		status.custom_minimum_size = Vector2(38.0, 24.0)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fleet_status_grid.add_child(status)
		_fleet_status_labels.append(status)
		_set_vehicle_status(index, false)
	_update_fleet_title()


func _create_status_style(
	color: Color,
	observed: bool = false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	if observed:
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.78, 0.18, 1.0)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


func _sync_fleet_status(alive_states: Array[bool]) -> void:
	for index in FLEET_STATUS_CAPACITY:
		_set_vehicle_status(
			index,
			index < alive_states.size() and alive_states[index]
		)
	_update_fleet_title()


func _on_vehicle_liveness_changed(index: int, alive: bool) -> void:
	_set_vehicle_status(index, alive)
	_update_fleet_title()


func _set_vehicle_status(index: int, alive: bool) -> void:
	if index < 0 or index >= _fleet_status_labels.size():
		return
	_fleet_alive_states[index] = alive
	var status := _fleet_status_labels[index]
	status.set_meta("alive", alive)
	var observed := index == _observed_vehicle_index
	status.set_meta("observed", observed)
	var style := _alive_style if alive else _dead_style
	if observed:
		style = _observed_alive_style if alive else _observed_dead_style
	status.add_theme_stylebox_override(
		"normal",
		style
	)
	status.add_theme_color_override(
		"font_color",
		Color(0.94, 1.0, 0.97) if alive else Color(0.52, 0.55, 0.6)
	)


func _update_fleet_title() -> void:
	var alive_count := 0
	for alive in _fleet_alive_states:
		alive_count += int(alive)
	_fleet_title.text = "Fleet %d / %d" % [
		alive_count,
		FLEET_STATUS_CAPACITY,
	]
