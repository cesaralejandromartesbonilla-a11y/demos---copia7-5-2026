extends Area3D
class_name CraftingTable

@export var available_recipes: Array[RecipeData] = []
@onready var ui_scene = preload("res://ecenas/mesas/crafting_ui.tscn")
@onready var item_base_scene = preload("res://items/pickable_item.tscn")

var is_in_use: bool = false

func _ready() -> void:
	add_to_group("estructuras")
	var processor = get_node_or_null("ProcessorComponent")
	if processor:
		processor.request_spawn_drop.connect(spawn_result)

func interact(player: Node3D) -> void:
	if is_in_use: return
	
	var processor: ProcessorComponent = null
	for child in get_children():
		if child is ProcessorComponent: processor = child; break

	if ui_scene != null and processor != null:
		var player_hands = player.get_node_or_null("HandsInventory")
		
		# --- NUEVO: AUTO-DEPOSITAR DE LAS MANOS ---
		if player_hands:
			if player_hands.item_in_right: _try_deposit(player_hands.item_in_right, processor, player_hands)
			if player_hands.item_in_left: _try_deposit(player_hands.item_in_left, processor, player_hands)
		
		var ui_instance = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		
		# Le pasamos también el item_base_scene para que la UI sepa cómo crear el objeto físico
		ui_instance.setup(processor, player_hands, item_base_scene) 
		
		is_in_use = true
		ui_instance.tree_exited.connect(func(): is_in_use = false)
	else:
		print("Error: Falta UI o ProcessorComponent")

# Función auxiliar para meter lo de las manos al inventario correcto
func _try_deposit(item_node: Node3D, processor: ProcessorComponent, hands: Node) -> void:
	var data = item_node.data
	if processor.input_inv and processor.input_inv.can_accept(data):
		processor.input_inv.add_item(data)
		hands.consume_item(item_node)
	elif processor.fuel_inv and processor.fuel_inv.can_accept(data):
		processor.fuel_inv.add_item(data)
		hands.consume_item(item_node)

func spawn_result(item_data: ItemData) -> void:
	if item_base_scene:
		var drop = item_base_scene.instantiate()
		drop.data = item_data
		get_tree().current_scene.add_child(drop)
		
		# Aparece ligeramente arriba de la mesa
		drop.global_position = global_position + Vector3(0, 1.5, 0)
		
		# EL CAÑÓN: Si usa físicas, lo empujamos en una dirección aleatoria
		if drop is RigidBody3D:
			var random_dir = Vector3(randf_range(-1.0, 1.0), 1.5, randf_range(-1.0, 1.0)).normalized()
			drop.apply_central_impulse(random_dir * 4.0) # Ajusta este número para más o menos fuerza
			
		print("¡Objeto expulsado: " + item_data.item_name + "!")
