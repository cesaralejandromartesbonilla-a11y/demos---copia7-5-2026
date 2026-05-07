extends Area3D
class_name CraftingTable

@export var available_recipes: Array[RecipeData] = []
@export var ui_scene: PackedScene # Aquí arrastrarás la escena CraftingUI.tscn
@export var item_base_scene: PackedScene # La escena base de los items para soltarlos al cosechar

var is_in_use: bool = false

func _ready() -> void:
	add_to_group("estructuras")

func interact(player: Node3D) -> void:
	if is_in_use: return
	
	if ui_scene != null:
		var ui_instance = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		ui_instance.setup(self, player)
		is_in_use = true
	else:
		print("Error: No se ha asignado la UI a la mesa de trabajo.")

func spawn_result(item_data: ItemData) -> void:
	if item_base_scene:
		var drop = item_base_scene.instantiate()
		drop.data = item_data
		get_tree().current_scene.add_child(drop)
		# Aparece ligeramente arriba de la mesa
		drop.global_position = global_position + Vector3(0, 1.5, 0)
		print("¡Objeto crafteado: " + item_data.item_name + "!")
