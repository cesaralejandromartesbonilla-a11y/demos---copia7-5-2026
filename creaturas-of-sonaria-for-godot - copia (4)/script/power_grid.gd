extends RefCounted 
class_name PowerGrid

var generators: Array = []
var receivers: Array = []
var connectors: Array = []

var satisfaction: float = 1.0

func update_logic() -> void:
	var supply = 0.0
	var demand = 0.0
	
	for gen in generators:
		supply += gen.get_current_generation()
	
	for rec in receivers:
		if rec.is_machine_running:
			demand += rec.required_kw
			
	if demand <= 0:
		satisfaction = 1.0
	else:
		satisfaction = clamp(supply / demand, 0.0, 1.0)
