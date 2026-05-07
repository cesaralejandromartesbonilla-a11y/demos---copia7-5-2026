extends Resource
class_name RecipeData

@export var recipe_name: String = "Nueva Receta"
@export var required_items: Array[ItemData] = [] # Lo que pide (Ej: Trigo, Agua)
@export var result_item: ItemData # Lo que da (Ej: Harina)
@export var craft_time: float = 1.5 # Tiempo que tarda en procesarse
