extends Control

@onready var _steering_left: ProgressBar = \
	$ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left
@onready var _steering_right: ProgressBar = \
	$ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Right
@onready var _throttle: ProgressBar = \
	$ControlMonitor/VBoxContainer/ThrottleRow/Throttle
@onready var _brake: ProgressBar = \
	$ControlMonitor/VBoxContainer/BrakeRow/Brake


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
