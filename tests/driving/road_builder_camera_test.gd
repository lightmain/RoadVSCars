class_name RoadBuilderCameraTest
extends GdUnitTestSuite

const RoadBuilderCameraScript = preload("res://Scenes/Levels/camera_3d.gd")


func test_space_gradually_slows_camera_and_restores_previous_speed() -> void:
	var camera: RoadBuilderCamera = auto_free(RoadBuilderCameraScript.new())
	add_child(camera)
	camera.backward_speed = 32.0

	camera._input(_space_event(true))
	camera._process(1.0)
	camera._process(1.0)

	assert_float(camera.backward_speed).is_equal_approx(30.0, 0.001)

	camera._input(_space_event(false))

	assert_float(camera.backward_speed).is_equal_approx(32.0, 0.001)


func test_repeated_space_press_does_not_replace_saved_speed() -> void:
	var camera: RoadBuilderCamera = auto_free(RoadBuilderCameraScript.new())
	add_child(camera)
	camera.backward_speed = 24.0

	camera._input(_space_event(true))
	camera._process(1.0)
	camera._process(1.0)
	camera._input(_space_event(true, true))
	camera._input(_space_event(false))

	assert_float(camera.backward_speed).is_equal_approx(24.0, 0.001)


func test_camera_slowdown_stops_at_temporary_speed() -> void:
	var camera: RoadBuilderCamera = auto_free(RoadBuilderCameraScript.new())
	add_child(camera)
	camera.backward_speed = 40.0
	camera.mouse_input_enabled = false

	camera._input(_space_event(true))
	camera._process(1.0)
	camera._process(100.0)

	assert_float(camera.backward_speed).is_equal_approx(7.0, 0.001)


func test_navigation_speed_reports_gradual_camera_slowdown() -> void:
	var camera: RoadBuilderCamera = auto_free(RoadBuilderCameraScript.new())
	add_child(camera)
	camera.backward_speed = 35.0
	camera.mouse_input_enabled = false

	camera._input(_space_event(true))
	camera._process(1.0)
	camera._process(1.0)

	assert_float(camera.get_navigation_target_speed()).is_equal_approx(
		33.0,
		0.001
	)


func _space_event(pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = pressed
	event.echo = echo
	return event
