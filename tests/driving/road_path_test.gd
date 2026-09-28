class_name RoadPathTest
extends GdUnitTestSuite

const RoadPathScript = preload("res://Scripts/Driving/road_path.gd")


func test_resamples_straight_input_at_fixed_spacing() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.FORWARD)

	path.append_control_point(Vector3(0.0, 0.0, 5.1), Vector3.FORWARD)
	path.append_control_point(Vector3(0.0, 0.0, 8.2), Vector3.FORWARD)

	var samples: Array = path.get_samples()
	assert_int(samples.size()).is_equal(5)
	for index in range(samples.size()):
		assert_vector(samples[index]["position"]).is_equal_approx(
			Vector3(0.0, 0.0, index * 2.0),
			Vector3.ONE * 0.001
		)
		assert_float(samples[index]["distance"]).is_equal_approx(index * 2.0, 0.001)
		assert_int(samples[index]["index"]).is_equal(index)


func test_projects_onto_path_without_using_world_z_progress() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.RIGHT)
	path.append_control_point(Vector3(10.0, 0.0, 0.0), Vector3.RIGHT)

	var projection: Dictionary = path.project(Vector3(5.0, 0.0, 3.0), 0)

	assert_bool(projection["valid"]).is_true()
	assert_vector(projection["position"]).is_equal_approx(
		Vector3(5.0, 0.0, 0.0),
		Vector3.ONE * 0.001
	)
	assert_float(projection["distance"]).is_equal_approx(5.0, 0.001)


func test_samples_a_lookahead_target_by_arc_length() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.FORWARD)
	path.append_control_point(Vector3(0.0, 0.0, 10.0), Vector3.FORWARD)
	path.append_control_point(Vector3(6.0, 0.0, 10.0), Vector3.RIGHT)

	var target: Dictionary = path.sample_at_distance(13.0)

	assert_bool(target["valid"]).is_true()
	assert_vector(target["position"]).is_equal_approx(
		Vector3(3.0, 0.0, 10.0),
		Vector3.ONE * 0.001
	)
	assert_float(target["distance"]).is_equal_approx(13.0, 0.001)


func test_distance_stays_uniform_when_a_sample_crosses_a_corner() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.FORWARD)
	path.append_control_point(Vector3(0.0, 0.0, 3.0), Vector3.FORWARD)
	path.append_control_point(Vector3(3.0, 0.0, 3.0), Vector3.RIGHT)

	var samples: Array = path.get_samples()
	assert_vector(samples[2]["position"]).is_equal_approx(
		Vector3(1.0, 0.0, 3.0),
		Vector3.ONE * 0.001
	)
	assert_float(samples[2]["distance"]).is_equal_approx(4.0, 0.001)


func test_curvature_is_recorded_when_heading_changes() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.FORWARD)
	path.append_control_point(Vector3(0.0, 0.0, 6.0), Vector3.FORWARD)
	path.append_control_point(Vector3(6.0, 0.0, 6.0), Vector3.RIGHT)

	var max_curvature: float = path.max_curvature_between(4.0, 12.0)

	assert_float(max_curvature).is_greater(0.1)


func test_pruning_keeps_one_sample_before_requested_distance() -> void:
	var path = RoadPathScript.new(2.0)
	path.reset(Vector3.ZERO, Vector3.FORWARD)
	path.append_control_point(Vector3(0.0, 0.0, 12.0), Vector3.FORWARD)

	path.prune_before_distance(7.0)

	var samples: Array = path.get_samples()
	assert_float(samples.front()["distance"]).is_equal_approx(6.0, 0.001)
	assert_int(samples.front()["index"]).is_equal(3)
	assert_float(samples.back()["distance"]).is_equal_approx(12.0, 0.001)


func test_empty_path_queries_return_invalid_results() -> void:
	var path = RoadPathScript.new(2.0)

	assert_bool(path.project(Vector3.ZERO, 0)["valid"]).is_false()
	assert_bool(path.sample_at_distance(5.0)["valid"]).is_false()
	assert_float(path.max_curvature_between(0.0, 10.0)).is_equal(0.0)
