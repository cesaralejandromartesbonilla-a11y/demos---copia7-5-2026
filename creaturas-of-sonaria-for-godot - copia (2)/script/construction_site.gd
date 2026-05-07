extends Area3D
class_name ConstructionSite

var blueprint: BlueprintData
var progress: Array[int] = [] # ¡Ahora es un arreglo de números!

@onready var preview_mesh = MeshInstance3D.new()
@onready var floating_label_scene = preload("res://test/damage_label.tscn")

func _ready() -> void:
	add_child(preview_mesh)
	if blueprint:
		# Preparamos el arreglo de progreso con ceros (0) del mismo tamaño que la lista de items requeridos
		progress.resize(blueprint.required_items.size())
		progress.fill(0)
			
		if blueprint.hologram_mesh:
			preview_mesh.mesh = blueprint.hologram_mesh
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5) 
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			preview_mesh.material_override = mat
			
		if blueprint.build_instantly:
			_finish_construction()

func interact(player: Node3D) -> void:
	var hands = player.get_node_or_null("HandsInventory")
	if not hands or not blueprint: return
	
	var item_to_use: PickableItem = null
	var hand_item_data = null
	
	if hands.item_in_right:
		hand_item_data = hands.item_in_right.data
		item_to_use = hands.item_in_right
	elif hands.item_in_left:
		hand_item_data = hands.item_in_left.data
		item_to_use = hands.item_in_left
		
	if item_to_use:
		var item_index = blueprint.required_items.find(hand_item_data)
		
		if item_index != -1: 
			var amount_needed = blueprint.required_amounts[item_index]
			var current_amount = progress[item_index] # ¡Usamos el índice de forma 100% segura!
			
			if current_amount < amount_needed:
				hands.consume_item(item_to_use)
				progress[item_index] += 1 
				
				_spawn_floating_text("+1 " + str(hand_item_data.item_name), Color.GREEN)
				_check_if_finished()
			else:
				_spawn_floating_text("¡Suficiente " + str(hand_item_data.item_name) + "!", Color.YELLOW)
		else:
			_spawn_floating_text("Material incorrecto", Color.RED)
	else:
		var missing_text = "Falta material"
		for i in range(blueprint.required_items.size()):
			if progress[i] < blueprint.required_amounts[i]:
				missing_text = "Falta " + str(blueprint.required_items[i].item_name) + " (" + str(progress[i]) + "/" + str(blueprint.required_amounts[i]) + ")"
				break
		_spawn_floating_text(missing_text, Color.ORANGE)

func _check_if_finished() -> void:
	var is_finished = true
	for i in range(blueprint.required_items.size()):
		if progress[i] < blueprint.required_amounts[i]:
			is_finished = false
			break
			
	if is_finished:
		_finish_construction()

func _finish_construction() -> void:
	_spawn_floating_text("¡Terminado!", Color.AQUA)
	if blueprint.final_scene:
		var building = blueprint.final_scene.instantiate()
		get_tree().current_scene.add_child(building)
		building.global_position = global_position
		building.global_rotation = global_rotation
		
	queue_free()

func _spawn_floating_text(texto: String, color: Color) -> void:
	if floating_label_scene == null: return
	
	var label = floating_label_scene.instantiate()
	get_tree().root.add_child(label) 
	label.global_position = global_position + Vector3(0, 2.0, 0) 
	
	if label.has_method("display_text"):
		label.display_text(texto, color)
	elif label.has_method("display"):
		label.display(0, color) 
		label.text = texto
