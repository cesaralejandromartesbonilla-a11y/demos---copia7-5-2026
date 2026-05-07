extends Node
class_name BuilderManager

@onready var controller = get_parent() 

@export_group("Referencias de Escena")
@export var construction_site_scene: PackedScene 
@export var crop_plot_scene: PackedScene
@onready var ground_detector: RayCast3D = $"../GroundDetector" 

@export_group("Interfaz (HUD)")
@export var blueprint_label: Label

var active_blueprints: Array[BlueprintData] = []
var current_bp_index: int = 0
var is_build_mode: bool = false
var snap_to_grid: bool = true 
var grid_size: float = 2.0 
var blueprint_rotation_y: float = 0.0

var hologram: MeshInstance3D
var mat_valid: StandardMaterial3D
var mat_invalid: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	hologram = MeshInstance3D.new()
	add_child(hologram)
	hologram.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# --- CONTROL DE CÁMARA (CLIC DERECHO) ---
	if is_build_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	# --- ACTIVAR/DESACTIVAR MODO CONSTRUCCIÓN ---
	if event.is_action_pressed("press_tab"):
		if not is_build_mode:
			_toggle_build_mode()
		else:
			_exit_build_mode() # Usamos una función limpia para salir
		return

	# --- INPUTS SOLO SI ESTAMOS EN MODO CONSTRUCCIÓN ---
	if is_build_mode:
		if event.is_action_pressed("press_pleca"):
			snap_to_grid = !snap_to_grid
			print("Grid: ", snap_to_grid)

		if event.is_action_pressed("press_c"):
			blueprint_rotation_y += deg_to_rad(90)
		elif event.is_action_pressed("press_v"):
			blueprint_rotation_y -= deg_to_rad(90)

		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_change_blueprint(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_change_blueprint(-1)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				_try_place_blueprint()
				
	else:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_check_disassemble_action()

func _toggle_build_mode() -> void:
	active_blueprints.clear()
	#print("--- INICIANDO RASTREO DE PLANOS ---")
	
	var evo_manager = controller.get_node_or_null("EvolutionManager")
	if evo_manager == null:
		print("FALLO 1: No se encontró el EvolutionManager.")
		return
	
	# Usamos tu función inteligente
	var current_stage_resource = evo_manager._get_current_stage()
	if current_stage_resource == null:
		print("FALLO 2: _get_current_stage() devolvió null.")
		return
		
	if not "unlocked_blueprints" in current_stage_resource:
		print("FALLO 3: El recurso no tiene la variable 'unlocked_blueprints'.")
		return
		
	var guardados = current_stage_resource.unlocked_blueprints
	if guardados.is_empty():
		print("FALLO 4: La lista de planos está vacía en el inspector de ", current_stage_resource.stage_name)
		return
		
	# ¡LA MAGIA OCURRE AQUÍ! Usamos duplicate() para no borrar el recurso original
	active_blueprints = guardados.duplicate()
	#print("EXITO FINAL: Planos obtenidos correctamente. Cantidad -> ", active_blueprints.size())
	#print("--- RASTREO COMPLETADO ---")

	is_build_mode = true
	hologram.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_bp_index = 0 
	_update_blueprint_ui() 

func _exit_build_mode() -> void:
	is_build_mode = false
	hologram.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if blueprint_label: blueprint_label.text = ""

func _physics_process(_delta: float) -> void:
	if is_build_mode:
		_update_hologram_logic()

func _update_hologram_logic() -> void:
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 20.0
	
	var space_state = get_viewport().world_3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	# ARREGLO DE FLOTACIÓN: El raycast SOLO chocará con la capa 1.
	# Asegúrate de que tu terreno esté en la capa 1, y tus estructuras construidas en la capa 2.
	query.collision_mask = 1 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var pos = result.position
		if snap_to_grid:
			pos.x = snapped(pos.x, grid_size)
			pos.z = snapped(pos.z, grid_size)
		
		hologram.global_position = pos
		hologram.rotation.y = blueprint_rotation_y
		hologram.material_override = mat_valid
	else:
		hologram.material_override = mat_invalid

func _change_blueprint(dir: int) -> void:
	current_bp_index = clampi(current_bp_index + dir, 0, active_blueprints.size() - 1)
	_update_blueprint_ui()

func _update_blueprint_ui() -> void:
	var bp = active_blueprints[current_bp_index]
	hologram.mesh = bp.hologram_mesh
	if blueprint_label:
		blueprint_label.text = "Construyendo: " + bp.building_name

func _try_place_blueprint() -> void:
	if active_blueprints.is_empty() or current_bp_index < 0 or current_bp_index >= active_blueprints.size():
		return
	if construction_site_scene == null:
		print("Error: Falta 'construction_site_scene' en el Inspector.")
		return
		
	if hologram.material_override == mat_invalid:
		return

	var bp = active_blueprints[current_bp_index]
	var site = construction_site_scene.instantiate()
	
	# 1. PRIMERO entregamos los datos (Para que el _ready sepa qué hacer)
	site.blueprint = bp
	
	# 2. SEGUNDO lo metemos al mundo (Aquí Godot ejecuta el _ready de ConstructionSite)
	get_tree().current_scene.add_child(site)
	
	# 3. TERCERO le damos sus coordenadas en el espacio 3D
	site.global_position = hologram.global_position
	site.global_rotation.y = blueprint_rotation_y
	
	_exit_build_mode()

func try_build_plot() -> void:
	# 1. ESCUDO: Verificar si la etapa de la criatura sabe cultivar
	var evo_manager = controller.get_node_or_null("EvolutionManager")
	if evo_manager:
		var stage = evo_manager._get_current_stage()
		if stage == null or not stage.can_farm:
			print("Esta criatura no sabe cómo cultivar.")
			return

	# 2. ESCUDO: Verificar si tiene la herramienta en las manos
	var hands = controller.get_node_or_null("HandsInventory")
	var has_tool = false
	if hands:
		if (hands.item_in_right and hands.item_in_right.data.can_till_soil) or (hands.item_in_left and hands.item_in_left.data.can_till_soil):
			has_tool = true
			
	if not has_tool:
		print("Necesitas una herramienta (asadón) para arar la tierra.")
		return

	# 3. Lógica original de creación
	if not ground_detector.is_colliding(): return
	var collider = ground_detector.get_collider()
	
	if collider.is_in_group("cosechable"):
		var pos = ground_detector.get_collision_point()
		if snap_to_grid:
			pos.x = snapped(pos.x, grid_size)
			pos.z = snapped(pos.z, grid_size)
			
		var plot = crop_plot_scene.instantiate()
		get_tree().current_scene.add_child(plot)
		plot.global_position = pos
		print("¡Parcela creada con éxito!")

func _setup_materials() -> void:
	mat_valid = StandardMaterial3D.new()
	mat_valid.albedo_color = Color(0, 1, 0, 0.4)
	mat_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_invalid = StandardMaterial3D.new()
	mat_invalid.albedo_color = Color(1, 0, 0, 0.4)
	mat_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _check_disassemble_action() -> void:
	var hands = controller.get_node_or_null("HandsInventory")
	var has_tool = false
	if hands:
		if (hands.item_in_right and hands.item_in_right.data.can_till_soil) or (hands.item_in_left and hands.item_in_left.data.can_till_soil):
			has_tool = true
			
	if not has_tool: return

	# --- DISPARO DE LÁSER DESDE LA CÁMARA (Mouse) ---
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 20.0
	
	var space_state = get_viewport().world_3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var target = result.collider
		if target.is_in_group("estructuras"):
			if target.has_method("disassemble_with_tool"):
				target.disassemble_with_tool()
			else:
				print("Estructura simple detectada, eliminando...")
				target.queue_free()
