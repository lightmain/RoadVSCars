class_name UIControlMonitorTest
extends GdUnitTestSuite

const UIScene = preload("res://Scenes/Temp/ui.tscn")


func test_control_monitor_clamps_and_splits_vehicle_commands() -> void:
	var ui: Control = auto_free(UIScene.instantiate())
	add_child(ui)

	ui.set_control_monitor(1.5, 1.4, -0.2)

	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left"
	).value).is_equal(1.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Right"
	).value).is_equal(0.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	).value).is_equal(1.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/BrakeRow/Brake"
	).value).is_equal(0.0)

	ui.set_control_monitor(-0.6, 0.25, 0.75)

	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left"
	).value).is_equal(0.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Right"
	).value).is_equal_approx(0.6, 0.001)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	).value).is_equal_approx(0.25, 0.001)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/BrakeRow/Brake"
	).value).is_equal_approx(0.75, 0.001)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left"
	).custom_minimum_size.y).is_equal(12.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	).custom_minimum_size.y).is_equal(12.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/BrakeRow/Brake"
	).custom_minimum_size.y).is_equal(12.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Left"
	).max_value).is_equal(1.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/SteeringRow/SteeringTrack/Right"
	).max_value).is_equal(1.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/ThrottleRow/Throttle"
	).max_value).is_equal(1.0)
	assert_float(ui.get_node(
		"ControlMonitor/VBoxContainer/BrakeRow/Brake"
	).max_value).is_equal(1.0)
