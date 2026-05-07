extends Node2D

var placing_tower_data: TowerData = null
var ghost_sprite: Sprite2D = null
var ghost_area: Area2D = null

func _ready():
	GameEvents.request_tower_placement.connect(_start_placement)

func _start_placement(tower_data: TowerData):
	placing_tower_data = tower_data
	
	if ghost_sprite:
		_cancel_placement()
		
	# Crear el sprite fantasma
	ghost_sprite = Sprite2D.new()
	ghost_sprite.texture = tower_data.tower_texture
	add_child(ghost_sprite)
	
	# Crear un Area2D temporal para el fantasma
	ghost_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0 # Ajusta esto al tamaño de la "base" de tus torres
	collision.shape = shape
	ghost_area.add_child(collision)
	ghost_sprite.add_child(ghost_area)

func _process(_delta):
	if ghost_sprite:
		ghost_sprite.global_position = get_global_mouse_position()
		
		# Cambiar el color según si es válido o no
		if _is_placement_valid():
			ghost_sprite.modulate = Color(1, 1, 1, 0.5)
		else:
			ghost_sprite.modulate = Color(1, 0, 0, 0.5)

func _unhandled_input(event):
	if placing_tower_data and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("click")
			if _is_placement_valid():
				print("click valido")
				_place_tower(get_global_mouse_position())
			else:
				print("No puedes colocar la torre aquí.")
				# Aquí podrías reproducir un sonido de error
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()

func _is_placement_valid() -> bool:
	if not ghost_area or placing_tower_data == null:
		return false
		
	# Obtenemos todo lo que el fantasma está tocando
	var overlapping_areas = ghost_area.get_overlapping_areas()
	var is_touching_path = false
	
	for area in overlapping_areas:
		# 1. Regla de oro: NUNCA encima de otra torre o de un obstáculo duro
		if area.is_in_group("torre") or area.is_in_group("no_apto"):
			return false 
			
		# 2. Revisamos si está tocando el camino
		if area.is_in_group("camino"):
			is_touching_path = true
			
	# Evaluamos según el tipo de torre que estamos intentando poner
	match placing_tower_data.allowed_terrain:
		TowerData.PlacementType.ESTANDAR:
			# Las torres estándar no pueden pisar el camino
			if is_touching_path: return false
			
		TowerData.PlacementType.CAMINO:
			# Las torres de camino que DEBEN estar en el camino
			if not is_touching_path: return false
			
		TowerData.PlacementType.AGUA:
			# Para torres de agua, podrías crear un grupo "agua" 
			# y requerir que is_touching_water sea true.
			pass
	return true

func _place_tower(pos: Vector2):
	var new_tower = preload("res://Tower/tower_test.tscn").instantiate()
	get_parent().add_child(new_tower) # Asegúrate de que se añade al mapa, no al manager si quieres separarlos
	new_tower.global_position = pos
	new_tower.setup(placing_tower_data)
	
	_cancel_placement()

func _cancel_placement():
	placing_tower_data = null
	if ghost_sprite:
		ghost_sprite.queue_free()
		ghost_sprite = null
		ghost_area = null
