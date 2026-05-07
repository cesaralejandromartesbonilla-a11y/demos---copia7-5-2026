extends Area3D
class_name CropPlot

enum State { EMPTY, GROWING, READY, DIRTY, PEST_INFESTED, NEEDS_CLEARING }
var current_state: State = State.EMPTY

@export var plot_type: ItemData.TerrainRequired = ItemData.TerrainRequired.NORMAL_PLOT
@export var item_base_scene: PackedScene # La escena base de los items para soltarlos al cosechar
@export var plot_mesh: MeshInstance3D 
var current_crop_mesh: MeshInstance3D = null
var current_visual_stage: int = -1

var growth_progress: float = 0.0
var current_water: float = 0.0
var current_organic_matter: float = 0.0
var is_fertilized: bool = false
var planted_seed_data: ItemData = null
var is_submerged: bool = false

var custom_material: StandardMaterial3D

func _ready() -> void:
	# Nos conectamos al Autoload
	WeatherManager.time_changed.connect(_on_global_time_tick)
	
	if plot_mesh:
		custom_material = StandardMaterial3D.new()
		plot_mesh.material_override = custom_material
		_update_visuals()
		
	add_to_group("crop_plot")
	add_to_group("estructuras")
	_update_visuals()

func _process(_delta: float) -> void:
	if current_state == State.GROWING and planted_seed_data and planted_seed_data.visual_data:
		var vis_data = planted_seed_data.visual_data
		# Calculamos el porcentaje de crecimiento (0.0 a 1.0)
		var progress_ratio = clamp(growth_progress / planted_seed_data.grow_time_ticks, 0.0, 1.0)
		
		if vis_data.style == CropVisualData.VisualStyle.COLOR_SHIFT:
			_process_color_shift(vis_data, progress_ratio)
		elif vis_data.style == CropVisualData.VisualStyle.MULTIPLE_MODELS:
			_process_model_stages(vis_data, progress_ratio)

# Simulación de físicas para saber si está bajo el agua (Algas)
func _physics_process(_delta: float) -> void:
	var overlapping = get_overlapping_areas()
	is_submerged = false
	for area in overlapping:
		if area.is_in_group("agua"):
			is_submerged = true
			break

func _on_global_time_tick(_current_time: float) -> void:
	if current_state != State.GROWING: return
	if planted_seed_data == null: return
	
	# 1. Comprobaciones estrictas de entorno
	if planted_seed_data.requires_submerged and not is_submerged:
		return # No crece si no está bajo el agua
		
	# 2. Sistema de Plagas (Probabilidad aleatoria si es vulnerable)
	if planted_seed_data.vulnerable_to_pests and randf() < 0.05: # 5% de chance por tick
		current_state = State.PEST_INFESTED
		print("¡Una plaga ha atacado el cultivo!")
		_update_visuals()
		return
	
	var speed_multiplier = 2.0 if is_fertilized else 1.0 
	var is_raining = (WeatherManager.current_weather == WeatherManager.WeatherType.RAIN)
	if is_raining: current_water += 2.0 
	
	# 3. Crecimiento basado en el tipo de planta
	var can_grow = false
	
	if planted_seed_data.crop_type == ItemData.CropType.FUNGUS:
		# Los hongos usan materia orgánica en vez de agua
		if current_organic_matter >= (planted_seed_data.organic_matter_needed * 0.1):
			can_grow = true
			current_organic_matter -= 1.0
	else:
		# Las plantas normales, árboles y algas usan agua
		if is_submerged or current_water >= (planted_seed_data.water_needed * 0.1): 
			can_grow = true
			current_water -= 1.0 

	# Aplicar crecimiento
	if can_grow:
		growth_progress += 1.0 * speed_multiplier
	else:
		growth_progress += 0.2 * speed_multiplier # Crece muy lento si le faltan recursos
		
	# 4. Finalizar crecimiento
	if growth_progress >= planted_seed_data.grow_time_ticks:
		current_state = State.READY
		_update_visuals()

func interact(player: Node3D) -> void:
	var hands = player.get_node_or_null("HandsInventory")
	var hand_item: PickableItem = null
	
	if hands:
		if hands.item_in_right: hand_item = hands.item_in_right
		elif hands.item_in_left: hand_item = hands.item_in_left
	
	# Lógica según el estado actual
	match current_state:
		State.EMPTY:
			if hand_item and hand_item.data.is_seed:
				_try_plant_seed(hand_item, hands)
			else:
				print("Necesitas una semilla compatible en la mano.")
				
		State.GROWING:
			# Si tiene agua en la mano
			if hand_item and hand_item.is_in_group("agua"):
				_water_plot(hand_item)
			# Si tiene materia orgánica (para hongos)
			elif hand_item and hand_item.data.is_organic_matter and planted_seed_data.crop_type == ItemData.CropType.FUNGUS:
				current_organic_matter = 100.0
				hands.consume_item(hand_item)
				print("Materia orgánica depositada.")
			# Si tiene fertilizante
			elif hand_item and hand_item.data.is_fertilizer and not is_fertilized:
				is_fertilized = true
				hands.consume_item(hand_item)
				print("Parcela fertilizada.")
			else:
				print("Progreso de crecimiento: ", int(growth_progress), "/", int(planted_seed_data.grow_time_ticks))
				
		State.PEST_INFESTED:
			if hand_item and hand_item.data.is_pest_killer:
				current_state = State.GROWING
				#hands.consume_item(hand_item)
				print("Plaga eliminada. El cultivo vuelve a crecer.")
			else:
				print("¡Necesitas algo para matar las plagas!")
				
		State.READY:
			_harvest()
			
		State.NEEDS_CLEARING:
			if hand_item and hand_item.data.is_fire_starter:
				print("Quemando restos agrícolas...")
				_reset_plot()
			else:
				print("Necesitas fuego para limpiar los restos de este cultivo.")
				
		State.DIRTY:
			print("Limpiando parcela...")
			_reset_plot()

func _try_plant_seed(seed_item: PickableItem, hands: Node) -> void:
	# Verificar si el terreno es el correcto para esta semilla
	if seed_item.data.required_terrain != plot_type:
		print("Este no es el terreno adecuado para esta semilla.")
		return
		
	planted_seed_data = seed_item.data
	growth_progress = 0.0
	current_state = State.GROWING
	hands.consume_item(seed_item)
	_update_visuals()
	print("Semilla plantada: ", planted_seed_data.item_name)

func _water_plot(water_item: PickableItem) -> void:
	current_water = 100.0
	print("Parcela regada.")
	
	if water_item.data.result_item_data != null:
		water_item.data = water_item.data.result_item_data
		if water_item.mesh_instance and water_item.data.item_mesh:
			water_item.mesh_instance.mesh = water_item.data.item_mesh
		
		water_item.remove_from_group("agua")
		if water_item.has_meta("current_capacity"):
			water_item.remove_meta("current_capacity")

func _harvest() -> void:
	if planted_seed_data == null: return
	
	# Generar el drop principal
	if planted_seed_data.result_item_data and item_base_scene:
		var total_drops = planted_seed_data.drop_amount + (2 if is_fertilized else 0) 
		for i in range(total_drops):
			_spawn_item(planted_seed_data.result_item_data)
			
	# Generar el drop secundario (ej. Madera, tallos)
	if planted_seed_data.secondary_result_data and item_base_scene:
		_spawn_item(planted_seed_data.secondary_result_data)
	
	# Evaluar qué pasa con la parcela después de cosechar
	if planted_seed_data.is_perennial:
		# Vuelve a crecer (Manzanos, Algas)
		current_state = State.GROWING
		growth_progress = 0.0
		is_fertilized = false # El fertilizante se gasta por cosecha
		print("Cosecha recolectada. La planta volverá a dar frutos.")
	elif planted_seed_data.leaves_trash_behind:
		# Deja basura que hay que quemar (Trigo)
		current_state = State.NEEDS_CLEARING
		print("Cosecha recolectada. Quedan restos que deben ser quemados.")
	else:
		# Planta normal, la parcela queda vacía (Hongos normales, zanahorias, etc.)
		_reset_plot()
	
	_update_visuals()

func _spawn_item(data: ItemData) -> void:
	var drop = item_base_scene.instantiate()
	drop.data = data 
	get_tree().current_scene.add_child(drop)
	drop.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5))

func _process_color_shift(vis_data: CropVisualData, ratio: float) -> void:
	# Si no hay modelo instanciado, lo creamos
	if not current_crop_mesh:
		current_crop_mesh = MeshInstance3D.new()
		current_crop_mesh.mesh = vis_data.single_mesh
		add_child(current_crop_mesh)
		
		# Le damos un material único para que no cambie el color de otras parcelas
		var mate = StandardMaterial3D.new()
		current_crop_mesh.set_surface_override_material(0, mate)
		
	# Actualizamos el color creando un degradado entre el inicial y el final
	var mat = current_crop_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = vis_data.start_color.lerp(vis_data.ready_color, ratio)

func _process_model_stages(vis_data: CropVisualData, ratio: float) -> void:
	var new_stage = 0
	if ratio >= 0.66: new_stage = 2 # 66% a 100% (Listo)
	elif ratio >= 0.33: new_stage = 1 # 33% a 65% (Creciendo)
	
	if new_stage != current_visual_stage:
		_transition_to_stage(new_stage, vis_data)

func _transition_to_stage(new_stage: int, vis_data: CropVisualData) -> void:
	var new_mesh_data = null
	match new_stage:
		0: new_mesh_data = vis_data.sprout_mesh
		1: new_mesh_data = vis_data.growing_mesh
		2: new_mesh_data = vis_data.ready_mesh
		
	if new_mesh_data == null: return
		
	var new_instance = MeshInstance3D.new()
	new_instance.mesh = new_mesh_data
	add_child(new_instance)
	
	if current_crop_mesh:
		# Animación de suavizado (Tween)
		var old_mesh = current_crop_mesh
		var tween = create_tween().set_parallel(true)
		
		# El nuevo modelo crece desde 0
		new_instance.scale = Vector3.ZERO
		tween.tween_property(new_instance, "scale", Vector3.ONE, vis_data.transition_duration).set_trans(Tween.TRANS_BACK)
		
		# El viejo modelo se "traga" hacia 0 y luego se elimina
		tween.tween_property(old_mesh, "scale", Vector3.ZERO, vis_data.transition_duration)
		tween.chain().tween_callback(old_mesh.queue_free)
	else:
		# Primera vez que se planta (brote)
		new_instance.scale = Vector3.ONE
		
	current_crop_mesh = new_instance
	current_visual_stage = new_stage

# Modificacion de función _reset_plot para limpiar los modelos al cosechar o quemar
func _reset_plot() -> void:
	if current_crop_mesh:
		current_crop_mesh.queue_free()
		current_crop_mesh = null
	current_visual_stage = -1
	
	current_state = State.EMPTY
	planted_seed_data = null
	growth_progress = 0.0
	current_water = 0.0
	current_organic_matter = 0.0
	is_fertilized = false

func save_data() -> Dictionary:
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : str(get_parent().get_path()) if get_parent() else "",
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z,
		"rot_x" : global_rotation.x,
		"rot_y" : global_rotation.y,
		"rot_z" : global_rotation.z,
		"current_state" : current_state,
		"current_compost" : is_fertilized,
		"growth_progress" : growth_progress,
		"is_watered": is_submerged,
		"planted_seed_path" : ""
	}
	if planted_seed_data != null:
		save_dict["planted_seed_path"] = planted_seed_data.resource_path
	return save_dict

func _update_visuals() -> void:
	return
#	if custom_material == null: return
#	
#	match current_state:
#		State.EMPTY:
#			custom_material.albedo_color = Color(0.4, 0.2, 0.1) 
#		State.GROWING:
#			if planted_seed_data and planted_seed_data.requires_submerged and not is_submerged:
#				custom_material.albedo_color = Color(0.3, 0.3, 0.3) 
#			elif planted_seed_data and planted_seed_data.crop_type == ItemData.CropType.FUNGUS:
#				custom_material.albedo_color = Color(0.5, 0.2, 0.5) 
#			else:A
#				# Si está regada o es de lluvia, se ve un verde más vivo
#				if is_submerged or WeatherManager.current_weather == WeatherManager.WeatherType.RAIN:
#					custom_material.albedo_color = Color(0.2, 0.8, 0.2)
#				else:
#					custom_material.albedo_color = Color(0.4, 0.7, 0.2) # Verde pálido (necesita agua)
#		State.READY:
#			custom_material.albedo_color = Color(0.9, 0.8, 0.1) 
#		State.DIRTY:
#			custom_material.albedo_color = Color(0.15, 0.1, 0.05)
