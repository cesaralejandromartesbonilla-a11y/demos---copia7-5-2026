extends Node
class_name PowerReceiverComponent

@export var required_kw: float = 15.0
var is_machine_running: bool = false
var my_connector = null 

func try_consume_power(_delta: float) -> float:
	is_machine_running = true # Avisamos que necesitamos luz
	
	# Le preguntamos a nuestro enchufe si su red tiene energía
	if my_connector and my_connector.get("my_grid"):
		return my_connector.my_grid.satisfaction
		
	return 0.0 # Si no hay enchufe o red, satisfacción cero

func turn_machine_on() -> void:
	is_machine_running = true

func turn_machine_off() -> void:
	is_machine_running = false
