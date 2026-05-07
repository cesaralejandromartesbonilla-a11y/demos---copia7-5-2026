extends Node

@onready var spawn_point: Marker3D = $SpawnPoint

func _ready() -> void:
	if InventoryManager.selected_creature == null:
		return
	
	# 1. Cargamos la escena desde la ruta de texto (Arregla el error)
	var scene_path = InventoryManager.selected_creature.creature_scene_path
	var creature_scene = load(scene_path).instantiate()
	
	add_child(creature_scene)
	
	# 2. Posicionamiento
	var save = InventoryManager.current_save_state
	if save != null:
		# Si hay partida, la ponemos donde guardó por última vez
		creature_scene.global_position = save.global_position
		creature_scene.global_rotation = save.global_rotation
	else:
		# Si es nueva, la ponemos en el SpawnPoint
		creature_scene.global_transform = spawn_point.global_transform
	
	# 3. Le decimos al controlador que se encargue de cargar los stats, nivel y evolución
	creature_scene.initialize_from_data(InventoryManager.selected_creature)
	
	# IMPORTANTE: NO limpiamos InventoryManager.current_save_state aquí.
