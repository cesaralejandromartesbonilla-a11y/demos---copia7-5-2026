extends RigidBody3D
class_name PickableItem

@export var data: ItemData
@onready var collision = $CollisionShape3D

var mesh_instance: MeshInstance3D

func _ready() -> void:
	print("cargadon odjeto")
	if data == null: 
		printerr("PickableItem generado sin datos en: ", global_position)
		return
		
	# 1. GENERACIÓN DINÁMICA DEL MODELO 3D
	if data.item_mesh != null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = data.item_mesh
		add_child(mesh_instance)
		
	# 2. CONFIGURACIÓN DE METADATOS Y GRUPOS
	if data.is_edible:
		if data.food_type == "planta": add_to_group("planta")
		elif data.food_type == "carne": add_to_group("carne")
		
		set_meta("current_capacity", data.nutrition_value)
		set_meta("max_capacity", data.nutrition_value)
	print("se termino de cargar odjeto")
	
func set_picked_up(is_picked: bool) -> void:
	freeze = is_picked 
	if collision:
		collision.disabled = is_picked

func consume(amount: float) -> bool:
	if not has_meta("current_capacity"): return false
	
	var current = get_meta("current_capacity")
	current -= amount
	set_meta("current_capacity", current)
	
	# Usamos el nodo que generamos dinámicamente para encogerlo
	if mesh_instance:
		var max_cap = get_meta("max_capacity")
		var scale_factor = max(0.2, current / max_cap)
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	if current <= 0:
		queue_free()
		return true
	return false

# --- PREPARACIÓN PARA GUARDADO ---
func save_data() -> Dictionary:
	var save_dict = {
		"filename" : get_scene_file_path(), # Sabemos qué escena base instanciar (item_base.tscn)
		"parent" : str(get_parent().get_path()) if get_parent() else "", # Dónde estaba guardado
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z,
		"rot_x" : global_rotation.x,
		"rot_y" : global_rotation.y,
		"rot_z" : global_rotation.z,
		"data_path" : ""
	}
	
	# Guardamos de qué está disfrazado este objeto (ruta del recurso ItemData)
	if data != null:
		save_dict["data_path"] = data.resource_path
		
	# Si es comida a medio comer, recordamos sus mordiscos
	if has_meta("current_capacity"):
		save_dict["current_capacity"] = get_meta("current_capacity")
		
	return save_dict
