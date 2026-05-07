# este script es innesesario para el juego 
extends Path2D

@export var globo_prueba: BloonData

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"): # Barra espaciadora
		var nuevo_globo = preload("res://bloons/bloon_base.tscn").instantiate()
		add_child(nuevo_globo)
		nuevo_globo.setup(globo_prueba)
		# Empieza al inicio del camino
		nuevo_globo.progress = 0
