extends PathFollow2D

@export var data: BloonData
var current_health: int

func setup(bloon_data: BloonData):
	data = bloon_data
	current_health = data.health
	
	if $Sprite2D and data.bloon_texture:
		$Sprite2D.texture = data.bloon_texture

func _process(delta):
	# Movemos el globo por el camino. 'progress' es una variable nativa de PathFollow2D
	progress += data.speed * delta
	
	# Si llega al final del camino (progress_ratio va de 0.0 a 1.0)
	if progress_ratio >= 1.0:
		# Avisamos al juego que el jugador pierde vidas
		# (Asumimos que quitará tantas vidas como capas le queden al globo)
		GameEvents.bloon_reached_end.emit(current_health) 
		queue_free()

func take_damage(amount: int):
	current_health -= amount
	
	if current_health <= 0:
		pop()

func pop():
	# 1. Avisamos que ganamos dinero
	GameEvents.bloon_popped.emit(data.reward_money)
	
	# 2. Efecto Matrioshka: Spawneamos los globos hijos
	if data.children_on_pop.size() > 0:
		for i in range(data.children_on_pop.size()):
			var child_data = data.children_on_pop[i]
			
			# Instanciamos el nuevo globo
			var new_bloon = load("res://Escenas/Bloon.tscn").instantiate()
			
			# Lo añadimos al mismo Path2D (nuestro padre)
			get_parent().call_deferred("add_child", new_bloon)
			
			new_bloon.setup(child_data)
			
			new_bloon.progress = self.progress - (i * 15.0)
			
	# 3. Destruimos este globo
	queue_free()
