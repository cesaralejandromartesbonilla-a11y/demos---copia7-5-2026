extends Node
class_name FluidTankComponent

@export var max_volume: float = 100.0
@export var allowed_fluid_type: String = "agua"

var current_volume: float = 0.0

func can_accept(type: String, amount: float) -> bool:
	if type != allowed_fluid_type: return false
	return current_volume + amount <= max_volume

func add_fluid(type: String, amount: float) -> bool:
	if can_accept(type, amount):
		current_volume += amount
		return true
	return false

func consume_fluid(amount: float) -> bool:
	if current_volume >= amount:
		current_volume -= amount
		return true
	return false
