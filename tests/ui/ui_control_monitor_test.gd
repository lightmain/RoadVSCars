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


func test_camera_selector_emits_mode_and_updates_selected_button() -> void:
	var ui: Control = auto_free(UIScene.instantiate())
	add_child(ui)
	var selected_modes: Array[StringName] = []
	ui.connect(
		"camera_selected",
		func(camera_mode: StringName) -> void:
			selected_modes.append(camera_mode)
	)
	var road_button: Button = ui.get_node(
		"CameraSelector/MarginContainer/Buttons/RoadCamera"
	)
	var chase_button: Button = ui.get_node(
		"CameraSelector/MarginContainer/Buttons/ChaseCamera"
	)
	var observer_button: Button = ui.get_node(
		"CameraSelector/MarginContainer/Buttons/ObserverCamera"
	)

	observer_button.pressed.emit()

	assert_int(selected_modes.size()).is_equal(1)
	assert_str(selected_modes[0]).is_equal("observer")
	assert_bool(observer_button.button_pressed).is_true()
	assert_bool(road_button.button_pressed).is_false()
	assert_bool(chase_button.button_pressed).is_false()


func test_fleet_status_panel_builds_twenty_stable_slots() -> void:
	var ui: Control = auto_free(UIScene.instantiate())
	add_child(ui)
	var status_grid: GridContainer = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/StatusGrid"
	)
	var title: Label = ui.get_node(
		"FleetStatus/MarginContainer/VBoxContainer/Title"
	)

	assert_int(status_grid.get_child_count()).is_equal(20)
	assert_str(status_grid.get_child(0).name).is_equal("Vehicle01")
	assert_str(status_grid.get_child(19).name).is_equal("Vehicle20")
	assert_str(title.text).is_equal("Fleet 0 / 20")
