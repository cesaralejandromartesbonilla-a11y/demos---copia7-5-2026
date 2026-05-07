extends Node3D
class_name CraftingTable

@export var available_recipes: Array[RecipeData] = []
@onready var ui_scene = preload("res://ecenas/mesas/crafting_ui.tscn")
@onready var item_base_scene = preload("res://items/pickable_item.tscn")
@export var machine_name: String = "Mesa de Elaboración"

@onready var processor = get_node_or_null("ProcessorComponent")

@export_group("Visuales y Animación")
@export var anim_player: AnimationPlayer
@export var indicator_mesh: MeshInstance3D # La malla que tiene el material de la luz
@export var light_material_index: int = 0 # Qué índice de material es la luz
@export var LuzNocturna: OmniLight3D

# Materiales precargados para las luces (Crea estos materiales en tu carpeta de recursos con 'Emission' activado)
@onready var mat_off = preload("res://materiales/luces/luz_roja.tres")
@onready var mat_working = preload("res://materiales/luces/luz_verde.tres")
@onready var mat_jammed = preload("res://materiales/luces/luz_amarilla.tres")

@export_group("cañon")
@export var ejector_point:Marker3D
@export var expulcion_aleatoria: bool
@export var fuerza_de_expluscion: float = 4

var is_in_use: bool = false

func _ready() -> void:
	add_to_group("estructuras")
	if processor:
		processor.optional_power_state.connect(_on_optional_power)
		processor.request_spawn_drop.connect(spawn_result)
		# NUEVO: Conectamos la señal de estado
		processor.machine_state_changed.connect(_on_machine_state_changed)

func _on_optional_power(has_power: bool) -> void:
	if LuzNocturna:
		LuzNocturna.visible = has_power

func interact(player: Node3D) -> void:
	if is_in_use: return
	
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
		ui_instance.setup(processor, player_hands, item_base_scene, machine_name)
		
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
	if expulcion_aleatoria == true:
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
	else:
		if item_base_scene == null or ejector_point == null: 
			print("Error: Falta item_base_scene o un marker3D en la Máquina")
			return
			
		# 1. Creamos el objeto
		var drop = item_base_scene.instantiate()
		drop.data = item_data
		get_tree().current_scene.add_child(drop)
		
		# 2. Posición: En el centro del Marker3D
		drop.global_position = ejector_point.global_position
		
		# 3. DIRECCIÓN DEL CAÑÓN: Usamos la rotación del Marker3D
		if drop is RigidBody3D:
			# En Godot, la dirección "adelante" local de un objeto es -Z
			var forward_dir = -ejector_point.global_transform.basis.z
			
			# Le damos un poco de inclinación hacia arriba para que haga un arco (opcional)
			var shoot_dir = (forward_dir + Vector3(0, 0.5, 0)).normalized()
			
			# Aplicamos la fuerza
			drop.apply_central_impulse(shoot_dir * fuerza_de_expluscion) 
			
		print("¡Máquina industrial expulsó: " + item_data.item_name + "!")

# --- NUEVA FUNCIÓN: Controlador Visual ---
func _on_machine_state_changed(new_state: String) -> void:
	match new_state:
		"OFF":
			_set_indicator_light(mat_off)
			if anim_player: anim_player.play("idle") # O anim_player.stop()
		
		"NO_FUEL":
			_set_indicator_light(mat_off)
			if anim_player: anim_player.play("idle")
			
		"WORKING":
			_set_indicator_light(mat_working)
			if anim_player and processor.current_recipe:
				# Magia pura: Hacemos que la animación de trabajo dure EXACTAMENTE lo que dura la receta
				var anim_name = "work" # O podrías usar: processor.current_recipe.recipe_name
				if anim_player.has_animation(anim_name):
					var current_anim = anim_player.get_animation(anim_name)
					# Calculamos la escala de velocidad (Si anim dura 5s y receta 10s, velocidad = 0.5)
					var speed_scale = current_anim.length / processor.current_recipe.craft_time
					anim_player.play(anim_name, -1, speed_scale)
		
		"JAMMED":
			_set_indicator_light(mat_jammed)
			if anim_player: 
				anim_player.pause() # Pausamos el martillo en el aire para que se vea atascado

func _set_indicator_light(material: Material) -> void:
	if indicator_mesh and material:
		indicator_mesh.set_surface_override_material(light_material_index, material)
