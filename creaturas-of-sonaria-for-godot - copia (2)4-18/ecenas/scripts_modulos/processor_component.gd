extends Node
class_name ProcessorComponent

signal progress_updated(percent: float)
signal status_changed(msg: String)
signal request_spawn_drop(item: ItemData)

@export_group("Conexiones")
@export var input_inv: InventoryComponent
@export var fuel_inv: InventoryComponent
@export var output_inv: InventoryComponent
@export var burner: BurnerComponent

@export var recipes: Array[RecipeData] = []

var current_recipe: RecipeData = null
var progress: float = 0.0

func _process(delta: float) -> void:
	# 1. Gestión de Combustible Automática
	if burner and not burner.is_burning:
		if fuel_inv.stored_items.size() > 0:
			var fuel = fuel_inv.stored_items[0]
			burner.add_fuel(20.0) # O el valor que tenga el item
			fuel_inv.remove_item(fuel)
			status_changed.emit("Combustible consumido")

#	# 2. Lógica de Procesamiento
#	if burner and burner.is_burning:
#		if current_recipe == null:
#			_check_for_recipes()
#		else:
#			_continue_processing(delta)
#	else:
#		if progress > 0: progress -= delta * 0.5 # Se enfría si no hay fuego
	if burner and burner.is_burning:
		# Solo avanza si hay una receta actual.
		if current_recipe != null:
			_continue_processing(delta)
	else:
		if progress > 0: progress -= delta * 0.5


func _check_for_recipes() -> void:
	for r in recipes:
		if _has_ingredients(r) and output_inv.can_accept(r.result_item):
			current_recipe = r
			status_changed.emit("Procesando: " + r.recipe_name)
			return

func _has_ingredients(recipe: RecipeData) -> bool:
	# Verifica si los ingredientes están REALMENTE en el input_inv
	for req in recipe.required_items:
		var count = 0
		for item in input_inv.stored_items:
			if item.item_name == req.item_name: count += 1
		if count < 1: return false 
	return true

func _continue_processing(delta: float) -> void:
	progress += delta
	progress_updated.emit(progress / current_recipe.craft_time)
	
	if progress >= current_recipe.craft_time:
		# 1. Consumir ingredientes
		for req in current_recipe.required_items:
			input_inv.extract_item_by_name(req.item_name)
		
		# 2. Lógica de Salida
		var result = current_recipe.result_item
		
		# Intentamos meterlo al inventario de salida
		if output_inv and output_inv.add_item(result):
			status_changed.emit("Producto guardado en salida")
		else:
			# Si no hay inventario de salida o está lleno, lo lanzamos al mundo
			request_spawn_drop.emit(result)
			status_changed.emit("¡Producto lanzado!")
		
		current_recipe = null
		progress = 0.0
		progress_updated.emit(0.0)

func start_recipe(recipe: RecipeData) -> void:
	if current_recipe != null: return # Ya está fabricando algo
	
	if _has_ingredients(recipe) and output_inv.can_accept(recipe.result_item):
		current_recipe = recipe
		status_changed.emit("Procesando: " + recipe.recipe_name)
	else:
		status_changed.emit("Faltan ingredientes o salida llena")
