extends CanvasLayer
class_name CraftingUI

var table: CraftingTable
var player: Node3D
var hands: Node

@onready var vbox = $Panel/ScrollContainer/VBoxContainer

func setup(_table: CraftingTable, _player: Node3D) -> void:
	table = _table
	player = _player
	hands = player.get_node_or_null("HandsInventory")
	
	_populate_recipes()
	
	# Botón para cerrar la interfaz
	var close_btn = Button.new()
	close_btn.text = "Cerrar Mesa"
	close_btn.pressed.connect(_on_close)
	$Panel.add_child(close_btn)
	close_btn.position = Vector2(10, 10) # Ajusta según tu diseño

func _populate_recipes() -> void:
	for recipe in table.available_recipes:
		var btn = Button.new()
		
		# Crear el texto del botón (Ej: "Harina (Requiere: Trigo x1, Agua x1)")
		var req_text = ""
		for req_item in recipe.required_items:
			req_text += req_item.item_name + ", "
			
		btn.text = recipe.recipe_name + " \n[Requiere: " + req_text.trim_suffix(", ") + "]"
		btn.pressed.connect(func(): _try_craft(recipe))
		
		vbox.add_child(btn)

func _try_craft(recipe: RecipeData) -> void:
	if hands == null: return
	
	# 1. Recopilar qué tenemos en las manos
	var items_in_hands = []
	if hands.item_in_right: items_in_hands.append(hands.item_in_right)
	if hands.item_in_left: items_in_hands.append(hands.item_in_left)
	
	# 2. Comprobar si tenemos los requisitos
	var matched_items = []
	var has_all_ingredients = true
	
	# Hacemos una copia de los requisitos para ir tachándolos
	var requirements_left = recipe.required_items.duplicate()
	
	for req in requirements_left:
		var found = false
		for hand_item in items_in_hands:
			if hand_item.data == req and not hand_item in matched_items:
				matched_items.append(hand_item)
				found = true
				break
		
		if not found:
			has_all_ingredients = false
			break
			
	# 3. Procesar el crafteo
	if has_all_ingredients:
		print("Iniciando crafteo...")
		# Consumir los objetos de las manos
		for item_to_consume in matched_items:
			hands.consume_item(item_to_consume)
			
		# Enviar la orden a la mesa para que suelte el objeto
		table.spawn_result(recipe.result_item)
	else:
		print("Te faltan ingredientes en las manos.")

func _on_close() -> void:
	table.is_in_use = false
	queue_free()
