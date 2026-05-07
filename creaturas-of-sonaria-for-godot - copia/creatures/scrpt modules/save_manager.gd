extends Node
class_name SaveManager

@export var target_resource: Resource 
@onready var survival = $"../SurvivalManager"

func save_stats_only(target_resource: Resource) -> void:
	if target_resource == null or not survival: 
		print("Error: No se puede guardar. Falta recurso o SurvivalManager.")
		return
	
	target_resource.set("max_health", survival.max_health)
	target_resource.set("current_health", survival.current_health)
	
	target_resource.set("max_energy", survival.max_energy)
	target_resource.set("current_energy", survival.current_energy)
	
	target_resource.set("current_hunger", survival.current_hunger)
	target_resource.set("current_thirst", survival.current_thirst)
	
	target_resource.set("growth_percent", survival.growth_percent)
	
	# Asegúrate de que resource_path no esté vacío
	if target_resource.resource_path != "":
		ResourceSaver.save(target_resource, target_resource.resource_path)
		print("¡Partida Guardada! Vida actual: ", survival.current_health, " en: ", target_resource.resource_path)
	else:
		print("Error: El recurso no tiene una ruta de guardado válida.")
