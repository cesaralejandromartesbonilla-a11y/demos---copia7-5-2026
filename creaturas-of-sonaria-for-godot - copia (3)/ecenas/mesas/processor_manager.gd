extends StaticBody3D
class_name ProcessorManager

@export_group("Identificación")
@export var sector_name: String = "Sector Industrial Alpha"
@export var is_sector_active: bool = false
@export var master_recipe_list: ProductionLineData

@export_group("Maquinaria Controlada")
@export var controlled_processors: Array[ProcessorComponent] = []
@export var local_power_nodes: Array[PowerReceiverComponent] = []

@export_group("Energía del Sector")
@export var main_power_receiver: PowerReceiverComponent # El enchufe principal del Manager

var total_kw_required: float = 0.0

@export_group("Configuración Global")
# CAMBIO: Ahora es un Array para que cargues varias Mega-Recetas en el Inspector
@export var available_mega_recipes: Array[ProductionLineData] = []
var active_mega_recipe: ProductionLineData = null

@onready var manager_ui_scene = preload("res://ecenas/mesas/manager_hud.tscn")
var is_in_use: bool = false

func interact(_player: Node3D) -> void:
	print("click")
	if is_in_use or manager_ui_scene == null: return
	
	var ui_instance = manager_ui_scene.instantiate()
	get_tree().current_scene.add_child(ui_instance)
	
	# Le pasamos a la UI este mismo script
	ui_instance.setup(self)
	
	is_in_use = true
	ui_instance.tree_exited.connect(func(): is_in_use = false)

# REEMPLAZA tu antigua 'apply_mega_recipe' por esta:
func select_and_start_mega_recipe(data: ProductionLineData) -> void:
	if data == null: return
	active_mega_recipe = data
	
	for i in range(controlled_processors.size()):
		if i < data.required_steps.size():
			var p = controlled_processors[i]
			var recipe = data.required_steps[i]
			
			p.is_automatic = true
			p.recipes.clear()
			p.recipes.append(recipe)
			
			# SOLUCIÓN: Si la máquina estaba apagada, la encendemos a la fuerza
			if not p.is_machine_enabled:
				p.toggle_machine()
			
			p.status_changed.emit("Asignado: " + recipe.recipe_name)
	
	is_sector_active = true

func _ready() -> void:
	add_to_group("estructuras")
	add_to_group("managers")
	
	# 1. Calculamos el consumo inicial
	_update_total_energy_requirement()
	
	# 2. Asignamos las recetas de la Mega-Factoría
	if master_recipe_list != null:
		apply_mega_recipe(master_recipe_list)

func _process(delta: float) -> void:
	if not is_sector_active:
		_shutdown_sector()
		return

	# GESTIÓN DE ENERGÍA
	if main_power_receiver:
		_update_total_energy_requirement()
		main_power_receiver.required_kw = total_kw_required
		
		var energy_ratio = main_power_receiver.try_consume_power(delta)
		
		if energy_ratio >= 1.0:
			_distribute_power_to_nodes(true)
		else:
			_distribute_power_to_nodes(false)

# --- LÓGICA DE CONTROL DE MAQUINARIA ---

func apply_mega_recipe(data: ProductionLineData) -> void:
	if data == null: return
	master_recipe_list = data
	
	for i in range(controlled_processors.size()):
		if i < data.required_steps.size():
			var p = controlled_processors[i]
			var recipe = data.required_steps[i]
			
			p.is_automatic = true
			p.recipes.clear()
			p.recipes.append(recipe)
			
			p.status_changed.emit("Configuración remota: " + recipe.recipe_name)

func toggle_sector() -> void:
	is_sector_active = !is_sector_active
	if is_sector_active:
		_boot_sector()
	else:
		_shutdown_sector()

func _boot_sector() -> void:
	for p in controlled_processors:
		if not p.is_machine_enabled:
			p.toggle_machine()

func _shutdown_sector() -> void:
	for p in controlled_processors:
		if p.is_machine_enabled:
			p.toggle_machine()
	_distribute_power_to_nodes(false)

# --- FUNCIONES AUXILIARES ---

func _update_total_energy_requirement() -> void:
	var total = 0.0
	for node in local_power_nodes:
		if node: total += node.required_kw
	total_kw_required = total

func _distribute_power_to_nodes(has_power: bool) -> void:
	for node in local_power_nodes:
		if node:
			if has_power:
				pass 
			else:
				node.turn_machine_off()
