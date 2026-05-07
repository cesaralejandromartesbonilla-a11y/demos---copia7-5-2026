extends Area3D
class_name InteractionManager

@export_group("Habilidades de cultivo")
@export var enable_farming_override: bool = false 
@export var crop_plot_scene: PackedScene # NUEVO: Arrastra aquí la escena de tu Parcela

@onready var survival = get_parent().get_node("SurvivalManager")
@onready var hands = get_parent().get_node_or_null("HandsInventory")
@onready var controller = get_parent()

# --- LÓGICA CONTINUA (Mantener pulsado para comer/beber) ---
func try_interact_continuous(delta: float) -> void:
	if controller.current_creature_data == null: return
	var current_diet = controller.current_creature_data.diet
	
	# --- PRIORIDAD 1: COMER DE LAS MANOS ---
	if hands:
		var item_to_eat = null
		if hands.item_in_right and _is_edible(hands.item_in_right.data, current_diet):
			item_to_eat = hands.item_in_right
		elif hands.item_in_left and _is_edible(hands.item_in_left.data, current_diet):
			item_to_eat = hands.item_in_left
			
		if item_to_eat:
			_process_hand_consumption(item_to_eat, 40.0 * delta) 
			controller.velocity = Vector3.ZERO
			return 
			
	var areas = get_overlapping_areas()
	var interacted = false
	
	for area in areas:
		# --- LÓGICA DE HERBÍVOROS ---
		if area.is_in_group("planta"):
			if current_diet == CreatureData.DietType.HERBIVORE or current_diet == CreatureData.DietType.OMNIVORE:
				_process_consumption(area, 20.0 * delta, "hunger", false, true) 
				interacted = true
				
		# --- LÓGICA DE CARNÍVOROS ---
		elif area.is_in_group("carne") or area.is_in_group("podrido"):
			if current_diet == CreatureData.DietType.CARNIVORE or current_diet == CreatureData.DietType.OMNIVORE:
				var is_toxic = area.is_in_group("podrido")
				_process_consumption(area, 30.0 * delta, "hunger", is_toxic, true) 
				interacted = true
				
		# --- LÓGICA DE AGUA ---
		elif area.is_in_group("agua"):
			_process_consumption(area, 25.0 * delta, "thirst", false, false) 
			interacted = true
		elif area.is_in_group("agua_contaminada"):
			_process_consumption(area, 15.0 * delta, "thirst", true, false) 
			interacted = true
			
		if interacted: 
			controller.velocity = Vector3.ZERO
			break

# --- NUEVA LÓGICA DE ACCIÓN ÚNICA (Pulsar una vez) ---
func try_interact_action() -> void:
	if controller.current_creature_data == null: return
	
	var areas = get_overlapping_areas()
	var bodies = get_overlapping_bodies()
	
	# Revisamos si estamos tocando agua y tenemos una cubeta vacía en la mano
	for area in areas:
		if area.is_in_group("agua") or area.is_in_group("agua_contaminada"):
			if hands:
				if _try_fill_container(hands.item_in_right, area): return
				if _try_fill_container(hands.item_in_left, area): return

	# --- NUEVO: Arar la tierra con el asadón ---
	var tool_in_hand: PickableItem = null
	if hands:
		if hands.item_in_right and hands.item_in_right.data.is_tool and hands.item_in_right.data.can_till_soil:
			tool_in_hand = hands.item_in_right
		elif hands.item_in_left and hands.item_in_left.data.is_tool and hands.item_in_left.data.can_till_soil:
			tool_in_hand = hands.item_in_left

	if tool_in_hand and crop_plot_scene:
		# Comprobamos que no estemos intentando arar sobre una parcela ya existente
		var can_till = true
		for area in areas:
			if area.is_in_group("crop_plot") or area.is_in_group("estructuras"):
				can_till = false
				break
				
		if can_till:
			print("Arando la tierra...")
			var new_plot = crop_plot_scene.instantiate()
			get_tree().current_scene.add_child(new_plot)
			
			# Ajustamos la posición un poco adelante de la criatura y al nivel del suelo
			var forward_offset = -controller.global_transform.basis.z * 1.5
			var spawn_pos = controller.global_position + forward_offset
			
			# Opcional: Forzar Y a la altura del piso si tu terreno es plano (ej: spawn_pos.y = 0.0)
			# spawn_pos.y = 0.0 
			
			new_plot.global_position = spawn_pos
			return # Terminamos la interacción aquí para no hacer otras acciones por accidente

	# --- Recoger objetos del suelo ---
	for body in bodies:
		if "data" in body and body.data is ItemData:
			if hands and hands.try_pick_up(body):
				return 

	# --- Construcción y Parcelas ---
	for area in areas:
		if area.is_in_group("estructuras") or area.is_in_group("crop_plot"):
			if area.has_method("interact"):
				area.interact(controller)
				return 
	
	# Verificar si tiene permiso para cultivar
	var can_farm = enable_farming_override
	var evo_manager = controller.get_node_or_null("EvolutionManager")
	if evo_manager:
		var stage = evo_manager._get_current_stage()
		if stage and stage.can_farm:
			can_farm = true
			
	for area in areas:
		if area.is_in_group("crop_plot"):
			if can_farm:
				if area.has_method("interact"):
					area.interact(controller)
					break
			else:
				print("Tu criatura actual no tiene la capacidad de cultivar.")
				
	# --- LÓGICA DE RECOGER OBJETOS TIPO ÁREA (Por si acaso) ---
	for area in areas:
		if area is PickableItem:
			if controller.get_node_or_null("HandsInventory"):
				if controller.get_node("HandsInventory").try_pick_up(area):
					break

# --- FUNCIÓN AUXILIAR PARA LLENAR CUBETAS ---
func _try_fill_container(item: PickableItem, water_area: Area3D) -> bool:
	if item == null or item.data == null: return false
	
	if item.data.is_container and item.data.filled_result_data != null:
		if water_area.is_in_group(item.data.gather_liquid_group):
			print("Llenando " + item.data.item_name + "...")
			
			# 1. El cambiazo de datos
			item.data = item.data.filled_result_data
			
			# 2. Actualizamos el mesh usando tu variable dinámica
			if item.mesh_instance != null and item.data.item_mesh != null:
				item.mesh_instance.mesh = item.data.item_mesh
				
			# 3. Le damos propiedades de agua al nuevo objeto
			item.add_to_group("agua")
			if item.data.is_edible:
				item.set_meta("current_capacity", item.data.nutrition_value)
				item.set_meta("max_capacity", item.data.nutrition_value)
				
			return true
	return false
	
func _process_consumption(area: Area3D, requested_amount: float, stat_type: String, is_toxic: bool, is_depletable: bool):
	var amount_received = requested_amount
	
	if is_depletable:
		if not area.has_meta("current_capacity"):
			area.set_meta("current_capacity", 100.0) 
			area.set_meta("max_capacity", 100.0)
		
		var current_cap = area.get_meta("current_capacity")
		if current_cap <= 0: return 
		
		amount_received = min(requested_amount, current_cap)
		current_cap -= amount_received
		area.set_meta("current_capacity", current_cap) 
		
		var max_cap = area.get_meta("max_capacity")
		var scale_factor = max(0.1, current_cap / max_cap) 
		area.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		if current_cap <= 0:
			area.queue_free()
			
	if stat_type == "hunger":
		survival.current_hunger = clamp(survival.current_hunger + amount_received, 0, survival.max_hunger)
		if is_toxic: survival.take_damage(5.0 * get_process_delta_time()) 
		
	elif stat_type == "thirst":
		survival.current_thirst = clamp(survival.current_thirst + amount_received, 0, survival.max_thirst)
		if is_toxic: survival.take_damage(10.0 * get_process_delta_time())

func _is_edible(item_data: ItemData, diet: int) -> bool:
	if item_data == null or not item_data.is_edible: return false
	
	var is_plant = (item_data.food_type == "planta")
	var is_meat = (item_data.food_type == "carne")
	
	if diet == CreatureData.DietType.OMNIVORE: return true
	if diet == CreatureData.DietType.HERBIVORE and is_plant: return true
	if diet == CreatureData.DietType.CARNIVORE and is_meat: return true
	
	return false

func _process_hand_consumption(item: PickableItem, amount: float):
	survival.current_hunger = clamp(survival.current_hunger + amount, 0, survival.max_hunger)
	if item.consume(amount): 
		hands.consume_item(item)
