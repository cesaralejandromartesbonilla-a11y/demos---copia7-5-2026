extends Node2D

@export var data: TowerData
@onready var attack_timer = $AttackTimer

func _ready():
	attack_timer.wait_time = data.attack_cooldown
	attack_timer.autostart = true
	attack_timer.start()

func setup(tower_data: TowerData):
	data = tower_data
	$Sprite2D.texture = data.tower_texture

func _on_attack_timer_timeout():
	# 1. Agarra TODOS los enemigos del mapa sin importar dónde estén
	var all_enemies = get_tree().get_nodes_in_group("enemigo")
	
	# 2. Si existe al menos un enemigo...
	if all_enemies.size() > 0:
		var target = all_enemies[0] # Apuntamos al primero de la lista
		
		if is_instance_valid(target):
			# ROTACIÓN: look_at hace que el eje X (derecha) del nodo mire al objetivo
			look_at(target.global_position)
			
			# DISPARAR
			_shoot(target)

func _shoot(target: Node2D):
	var projectile = PoolManager.get_instance(data.projectile_scene)
	
	# Lo añadimos al mapa (al padre de la torre)
	get_parent().add_child(projectile) 
	
	projectile.global_position = global_position
	
	# Dirección matemática simple
	var direction = (target.global_position - global_position).normalized()
	
	# Le pasamos los datos a la bala (incluyendo su ruta para el Pool)
	var scene_path = data.projectile_scene.resource_path
	projectile.setup(direction, data.damage, data.pierce, scene_path)
