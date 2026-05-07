extends CanvasLayer
class_name MachineHUD

var processor: ProcessorComponent
var player_hands: Node 
var item_base_scene: PackedScene

# --- REFERENCIAS ---
@onready var seccion_izq = $PanelBackground/HBoxContainer/SeccionIzquierda
@onready var seccion_der = $PanelBackground/HBoxContainer/SeccionDerecha
@onready var titulo_combustible = $PanelBackground/HBoxContainer/SeccionDerecha/VBoxContainer/TituloCombustible

@onready var recipe_list = $PanelBackground/HBoxContainer/SeccionIzquierda/ScrollContainer/RecipeList
@onready var inventory_list = $PanelBackground/HBoxContainer/SeccionCentro/ScrollContainer/InventoryList

@onready var status_label = $PanelBackground/HBoxContainer/SeccionDerecha/VBoxContainer/StatusLabel
@onready var work_bar = $PanelBackground/HBoxContainer/SeccionDerecha/VBoxContainer/WorkBar
@onready var fuel_bar = $PanelBackground/HBoxContainer/SeccionDerecha/VBoxContainer/FuelBar

func setup(_processor: ProcessorComponent, _player_hands: Node, _base_scene: PackedScene) -> void:
	processor = _processor
	player_hands = _player_hands
	item_base_scene = _base_scene
	
	$PanelBackground/BotonCerrar.pressed.connect(_on_close)
	
	# --- 1. MODULARIDAD VISUAL (Ocultar lo que no sirve) ---
	var has_burner = processor.burner != null
	var has_recipes = processor.recipes.size() > 0
	
	# Ocultar barra de combustible si no hay quemador
	fuel_bar.visible = has_burner
	titulo_combustible.visible = has_burner
	
	# Ocultar panel de recetas entero si la máquina no tiene recetas (Ej: Un cofre)
	seccion_izq.visible = has_recipes
	
	# Ocultar panel derecho entero si no hay quemador NI recetas
	seccion_der.visible = has_burner or has_recipes
	
	# --- 2. CONEXIONES ---
	processor.progress_updated.connect(_on_work_progress)
	processor.status_changed.connect(_on_status_changed)
	
	if processor.input_inv: processor.input_inv.inventory_changed.connect(_update_inventory_ui)
	if processor.fuel_inv: processor.fuel_inv.inventory_changed.connect(_update_inventory_ui)
	if processor.output_inv: processor.output_inv.inventory_changed.connect(_update_inventory_ui)
		
	_populate_recipes()
	_update_inventory_ui()

func _process(_delta: float) -> void:
	# Actualizar la barra de fuego solo si es visible y existe el quemador
	if fuel_bar.visible and processor and processor.burner:
		fuel_bar.value = processor.burner.remaining_burn_time 

# --- RECETAS CON TEXTO DETALLADO ---
func _populate_recipes() -> void:
	for child in recipe_list.get_children(): child.queue_free()
		
	for recipe in processor.recipes:
		var btn = Button.new()
		var req_text = ""
		for req_item in recipe.required_items: req_text += req_item.item_name + ", "
			
		btn.text = "Fabricar: " + recipe.recipe_name + "\n[Requiere: " + req_text.trim_suffix(", ") + "]"
		
		# CONEXIÓN: Al presionar, inicia la receta específica
		btn.pressed.connect(func(): processor.start_recipe(recipe))
		
		recipe_list.add_child(btn)

func _update_inventory_ui() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
		
	if processor.input_inv: _draw_inventory_section("Entrada (Para Procesar)", processor.input_inv)
	if processor.fuel_inv: _draw_inventory_section("Combustible", processor.fuel_inv)
	if processor.output_inv: _draw_inventory_section("Salida (Terminado)", processor.output_inv)

func _draw_inventory_section(title: String, inv: InventoryComponent) -> void:
	var title_lbl = Label.new()
	title_lbl.text = "--- " + title + " ---"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2)) 
	inventory_list.add_child(title_lbl)
	
	if inv.stored_items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Vacío"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_list.add_child(empty_lbl)
	else:
		# Agrupamos items para la visualización
		var item_counts = {}
		var item_references = {} # Guardamos una referencia al objeto ItemData
		
		for item in inv.stored_items:
			if item_counts.has(item.item_name):
				item_counts[item.item_name] += 1
			else:
				item_counts[item.item_name] = 1
				item_references[item.item_name] = item
				
		for item_name in item_counts:
			var item_btn = Button.new()
			item_btn.text = "> " + item_name + " x" + str(item_counts[item_name])
			item_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			# CONECTAR EL CLIC PARA RECOGER
			item_btn.pressed.connect(_on_item_clicked.bind(item_references[item_name], inv))
			
			inventory_list.add_child(item_btn)
			
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	inventory_list.add_child(spacer)

# Nueva función para manejar la transferencia al jugador
func _on_item_clicked(item_data: ItemData, from_inv: InventoryComponent) -> void:
	if player_hands and item_base_scene:
		# 1. Creamos el objeto 3D físicamente
		var physical_item = item_base_scene.instantiate()
		physical_item.data = item_data
		
		# 2. Tu script HandsInventory exige que el nodo esté en el mundo antes de agarrarlo
		get_tree().current_scene.add_child(physical_item)
		
		# 3. Intentamos agarrarlo
		if player_hands.try_pick_up(physical_item):
			from_inv.remove_item(item_data)
		else:
			# Si las manos están llenas, borramos el objeto que acabamos de crear
			physical_item.queue_free()
			status_label.text = "Manos llenas"

func _on_work_progress(percent: float) -> void:
	work_bar.value = percent * 100

func _on_status_changed(msg: String) -> void:
	status_label.text = msg

func _on_close() -> void:
	queue_free()
