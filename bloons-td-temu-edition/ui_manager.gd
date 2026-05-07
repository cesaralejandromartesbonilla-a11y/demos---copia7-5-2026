extends CanvasLayer

@export var dart_monkey_data: TowerData

func _on_dart_button_pressed():
	GameEvents.request_tower_placement.emit(dart_monkey_data)
