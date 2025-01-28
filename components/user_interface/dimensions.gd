extends HBoxContainer

signal value_changed(value: Vector2i)
signal x_changed(value: int)
signal y_changed(value: int)

@export var allow_negative := false

var value := Vector2i.ZERO:
	set(new_value):
		value = new_value
		x_edit.value = value.x
		y_edit.value = value.y

@onready var x_edit: SpinBox = %XEdit
@onready var y_edit: SpinBox = %YEdit


func _ready() -> void:
	x_edit.allow_lesser = allow_negative
	y_edit.allow_lesser = allow_negative


func _on_x_edit_value_changed(x_val: float) -> void:
	x_changed.emit(x_val)
	value.x = x_val
	value_changed.emit(value)


func _on_y_edit_value_changed(y_val: float) -> void:
	y_changed.emit(y_val)
	value.y = y_val
	value_changed.emit(value)
