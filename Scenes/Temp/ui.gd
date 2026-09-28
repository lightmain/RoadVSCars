extends Control

func set_speed_monitor(speed: float, camera_speed: float, throttle: float) -> void:
	$SpeedMonitor/MarginContainer/Label.text = \
		"Speed: %.2f\nCamera speed: %.2f\nThrottle: %.2f" % [speed, camera_speed, throttle]
