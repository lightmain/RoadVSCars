class_name RoadPath
extends RefCounted

const MIN_SPACING: float = 0.01
const MIN_SEGMENT_LENGTH: float = 0.0001

var _sample_spacing: float
var _samples: Array[Dictionary] = []
var _last_input_position: Vector3 = Vector3.ZERO
var _last_input_tangent: Vector3 = Vector3.FORWARD
var _distance_since_sample: float = 0.0
var _next_index: int = 0


func _init(sample_spacing: float = 2.0) -> void:
	_sample_spacing = maxf(sample_spacing, MIN_SPACING)


func reset(position: Vector3, tangent: Vector3) -> void:
	_samples.clear()
	_last_input_position = position
	_last_input_tangent = _safe_tangent(tangent, Vector3.FORWARD)
	_distance_since_sample = 0.0
	_next_index = 0
	_append_sample(position, _last_input_tangent)


func append_control_point(position: Vector3, tangent: Vector3) -> void:
	if _samples.is_empty():
		reset(position, tangent)
		return

	var segment := position - _last_input_position
	var segment_length := segment.length()
	if segment_length <= MIN_SEGMENT_LENGTH:
		_last_input_tangent = _safe_tangent(tangent, _last_input_tangent)
		return

	var direction := segment / segment_length
	var end_tangent := _safe_tangent(tangent, direction)
	var cursor := _last_input_position
	var remaining := segment_length
	var travelled := 0.0
	var distance_to_next := _sample_spacing - _distance_since_sample

	while remaining + MIN_SEGMENT_LENGTH >= distance_to_next:
		cursor += direction * distance_to_next
		travelled += distance_to_next
		remaining -= distance_to_next
		var weight := clampf(travelled / segment_length, 0.0, 1.0)
		var sample_tangent := _interpolate_tangent(
			_last_input_tangent,
			end_tangent,
			weight,
			direction
		)
		_append_sample(cursor, sample_tangent)
		_distance_since_sample = 0.0
		distance_to_next = _sample_spacing

	_distance_since_sample += maxf(remaining, 0.0)
	_last_input_position = position
	_last_input_tangent = end_tangent


func get_samples() -> Array:
	return _samples.duplicate(true)


func get_sample_count() -> int:
	return _samples.size()


func get_end_distance() -> float:
	if _samples.is_empty():
		return 0.0
	return _samples.back()["distance"]


func project(position: Vector3, hint_index: int = 0) -> Dictionary:
	if _samples.is_empty():
		return _invalid_result()
	if _samples.size() == 1:
		return _sample_result(_samples.front(), _samples.front()["position"])

	var start := _local_index_for_global_hint(hint_index)
	start = maxi(start - 1, 0)
	var best_squared_distance := INF
	var best_result := _invalid_result()

	for local_index in range(start, _samples.size() - 1):
		var first: Dictionary = _samples[local_index]
		var second: Dictionary = _samples[local_index + 1]
		var segment: Vector3 = second["position"] - first["position"]
		var length_squared := segment.length_squared()
		if length_squared <= MIN_SEGMENT_LENGTH * MIN_SEGMENT_LENGTH:
			continue
		var weight := clampf(
			(position - first["position"]).dot(segment) / length_squared,
			0.0,
			1.0
		)
		var projected: Vector3 = first["position"] + segment * weight
		var squared_distance := position.distance_squared_to(projected)
		if squared_distance < best_squared_distance:
			best_squared_distance = squared_distance
			var projected_tangent := _interpolate_tangent(
				first["tangent"],
				second["tangent"],
				weight,
				segment
			)
			best_result = {
				"valid": true,
				"position": projected,
				"tangent": projected_tangent,
				"distance": lerpf(first["distance"], second["distance"], weight),
				"segment_index": first["index"],
			}

	return best_result


func sample_at_distance(distance: float) -> Dictionary:
	if _samples.is_empty():
		return _invalid_result()
	if distance <= _samples.front()["distance"]:
		return _sample_result(_samples.front(), _samples.front()["position"])
	if distance >= _samples.back()["distance"]:
		return _sample_result(_samples.back(), _samples.back()["position"])

	for index in range(_samples.size() - 1):
		var first: Dictionary = _samples[index]
		var second: Dictionary = _samples[index + 1]
		if distance > second["distance"]:
			continue
		var span: float = second["distance"] - first["distance"]
		var weight := clampf((distance - first["distance"]) / maxf(span, MIN_SPACING), 0.0, 1.0)
		var tangent := _interpolate_tangent(
			first["tangent"],
			second["tangent"],
			weight,
			first["tangent"]
		)
		return {
			"valid": true,
			"position": first["position"].lerp(second["position"], weight),
			"tangent": tangent,
			"curvature": lerpf(first["curvature"], second["curvature"], weight),
			"distance": distance,
			"index": first["index"],
		}

	return _sample_result(_samples.back(), _samples.back()["position"])


func max_curvature_between(from_distance: float, to_distance: float) -> float:
	if _samples.is_empty():
		return 0.0
	var lower := minf(from_distance, to_distance)
	var upper := maxf(from_distance, to_distance)
	var maximum := 0.0
	for sample in _samples:
		if sample["distance"] < lower or sample["distance"] > upper:
			continue
		maximum = maxf(maximum, sample["curvature"])
	return maximum


func get_curvature_profile_between(
	from_distance: float,
	to_distance: float
) -> Array[Dictionary]:
	var profile: Array[Dictionary] = []
	if _samples.is_empty():
		return profile
	var lower := minf(from_distance, to_distance)
	var upper := maxf(from_distance, to_distance)
	for sample in _samples:
		if sample["distance"] < lower or sample["distance"] > upper:
			continue
		profile.append({
			"distance": sample["distance"],
			"curvature": sample["curvature"],
		})
	return profile


func prune_before_distance(distance: float) -> void:
	while _samples.size() > 2 and _samples[1]["distance"] <= distance:
		_samples.pop_front()


func _append_sample(position: Vector3, tangent: Vector3) -> void:
	var safe_tangent := _safe_tangent(tangent, Vector3.FORWARD)
	var curvature := 0.0
	var cumulative_distance := 0.0
	if not _samples.is_empty():
		var previous: Dictionary = _samples.back()
		cumulative_distance = previous["distance"] + _sample_spacing
		curvature = _horizontal_curvature(previous["tangent"], safe_tangent, _sample_spacing)

	_samples.append({
		"position": position,
		"tangent": safe_tangent,
		"curvature": curvature,
		"distance": cumulative_distance,
		"index": _next_index,
	})
	_next_index += 1


func _local_index_for_global_hint(hint_index: int) -> int:
	for index in range(_samples.size()):
		if _samples[index]["index"] >= hint_index:
			return index
	return maxi(_samples.size() - 1, 0)


func _sample_result(sample: Dictionary, position: Vector3) -> Dictionary:
	return {
		"valid": true,
		"position": position,
		"tangent": sample["tangent"],
		"curvature": sample["curvature"],
		"distance": sample["distance"],
		"index": sample["index"],
	}


func _invalid_result() -> Dictionary:
	return {
		"valid": false,
		"position": Vector3.ZERO,
		"tangent": Vector3.FORWARD,
		"curvature": 0.0,
		"distance": 0.0,
		"index": -1,
		"segment_index": -1,
	}


func _safe_tangent(value: Vector3, fallback: Vector3) -> Vector3:
	if value.length_squared() > MIN_SEGMENT_LENGTH * MIN_SEGMENT_LENGTH:
		return value.normalized()
	if fallback.length_squared() > MIN_SEGMENT_LENGTH * MIN_SEGMENT_LENGTH:
		return fallback.normalized()
	return Vector3.FORWARD


func _interpolate_tangent(
	from: Vector3,
	to: Vector3,
	weight: float,
	fallback: Vector3
) -> Vector3:
	var blended := from.lerp(to, weight)
	return _safe_tangent(blended, fallback)


func _horizontal_curvature(from: Vector3, to: Vector3, distance: float) -> float:
	var from_flat := Vector3(from.x, 0.0, from.z)
	var to_flat := Vector3(to.x, 0.0, to.z)
	if from_flat.length_squared() <= MIN_SEGMENT_LENGTH * MIN_SEGMENT_LENGTH:
		return 0.0
	if to_flat.length_squared() <= MIN_SEGMENT_LENGTH * MIN_SEGMENT_LENGTH:
		return 0.0
	return absf(from_flat.normalized().angle_to(to_flat.normalized())) / maxf(
		distance,
		MIN_SPACING
	)
