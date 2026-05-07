extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: int = 1
var pierce: int = 1
var my_scene_id: String

func setup(dir: Vector2, dmg: int, prc: int, scene_id: String):
	direction = dir
	damage = dmg
	pierce = prc
	my_scene_id = scene_id
	rotation = direction.angle()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_area_entered(area):
	print("¡Impacto detectado con: ", area.name, "!")
	var globo = area.get_parent()
	
	# Ahora le preguntamos al padre si está en el grupo y si puede recibir daño
	if globo.is_in_group("enemigo"):
		if globo.has_method("take_damage"):
			globo.take_damage(damage)
			
		pierce -= 1
		if pierce <= 0:
			# En lugar de destruirse, vuelve al Pool
			PoolManager.return_instance(self, my_scene_id)
