extends Node3D
const Art = preload("res://scripts/archery_art.gd")
const DRAW_TIME := 0.85
const MIN_DRAW := 0.12
var drawing := false
var draw_time := 0.0
var strings: Dictionary
var nocked: Node3D

func _ready() -> void:
	name = "StarterBow"
	position = Vector3(-0.28, -0.12, -0.78)
	strings = Art.bow(self)
	nocked = Art.arrow(self)
	cancel_draw()
	hide()

func begin_draw() -> void:
	if visible:
		drawing = true
		draw_time = 0.0

func advance(delta: float) -> void:
	if drawing:
		draw_time = minf(DRAW_TIME, draw_time + delta)
		_refresh()

func charge() -> float:
	return draw_time / DRAW_TIME

func release() -> float:
	var power := charge() if drawing and draw_time >= MIN_DRAW else -1.0
	cancel_draw()
	return power

func cancel_draw() -> void:
	drawing = false
	draw_time = 0.0
	if is_instance_valid(nocked):
		_refresh()

func _refresh() -> void:
	var middle := Vector3(0, 0, charge() * 0.28)
	Art.place_segment(strings.lower, Vector3(0, -0.52, 0.04), middle)
	Art.place_segment(strings.upper, middle, Vector3(0, 0.52, 0.04))
	nocked.visible = drawing
	nocked.position = middle + Vector3(0, 0, -0.28)
