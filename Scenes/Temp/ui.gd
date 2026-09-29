extends Control

signal camera_selected(camera_mode: StringName)

const CAMERA_ROAD: StringName = &"road"
const CAMERA_CHASE: StringName = &"chase"
const CAMERA_OBSERVER: StringName = &"observer"

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
