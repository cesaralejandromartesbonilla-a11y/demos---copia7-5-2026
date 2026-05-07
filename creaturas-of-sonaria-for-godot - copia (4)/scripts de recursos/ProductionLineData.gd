extends Resource
class_name ProductionLineData

@export_group("Información de la Línea de Producción")
@export var line_name: String = "Nueva Mega-Receta"
@export_multiline var description: String = "Describe aquí qué hace este sector industrial."
@export var line_icon: Texture2D

@export_group("Secuencia de Procesamiento")
# El orden importa: 
# Índice 0 será para la primera máquina del ProcessorManager.
# Índice 1 será para la segunda máquina, etc.
@export var required_steps: Array[RecipeData] = []

# Esta función te dirá cuántas máquinas necesitas conectar al Manager
func get_required_machine_count() -> int:
	return required_steps.size()

# Devuelve el producto final de toda la línea (asumiendo que es el último paso)
func get_final_product() -> ItemData:
	if required_steps.is_empty():
		return null
		
	var last_recipe: RecipeData = required_steps[required_steps.size() - 1]
	if last_recipe != null:
		return last_recipe.result_item
		
	return null
