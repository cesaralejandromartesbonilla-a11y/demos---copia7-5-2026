extends Node

# Diccionarios para manejar múltiples pools (dardos, bombas, globos rojos, etc.)
var pools: Dictionary = {}

func get_instance(scene: PackedScene) -> Node2D:
	var scene_id = scene.resource_path
	
	# Si el pool no existe, lo creamos
	if not pools.has(scene_id):
		pools[scene_id] = []
		
	# Si hay nodos disponibles, sacamos el último
	if pools[scene_id].size() > 0:
		var instance = pools[scene_id].pop_back()
		instance.show()
		instance.set_process(true)
		instance.set_physics_process(true)
		return instance
		
	# Si el pool está vacío, instanciamos uno nuevo
	return scene.instantiate()

func return_instance(instance: Node2D, scene_id: String) -> void:
	# En lugar de queue_free(), lo "apagamos" y lo guardamos
	instance.hide()
	instance.set_process(false)
	instance.set_physics_process(false)
	
	# IMPORTANTE: Asegúrate de resetear variables en el nodo (posición, vida) 
	# antes o después de devolverlo al pool.
	
	if pools.has(scene_id):
		pools[scene_id].append(instance)
