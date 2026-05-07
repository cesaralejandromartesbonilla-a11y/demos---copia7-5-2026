extends Node

@export var waves: Array[WaveData]   # Aquí arrastras tus recursos de oleada
@export var path_to_follow: Path2D   # Referencia al camino del mapa
@export var bloon_scene: PackedScene # La escena Bloon.tscn
var current_wave_index: int = 0

func _ready() -> void:
	start_next_wave()

func start_next_wave():
	if current_wave_index < waves.size():
		var wave = waves[current_wave_index]
		process_wave(wave)
		current_wave_index += 1

func process_wave(wave_data: WaveData):
	for group in wave_data.groups:
		# Esperar el delay inicial del grupo
		if group.initial_delay > 0:
			await get_tree().create_timer(group.initial_delay).timeout
		
		# Soltar los globos uno a uno
		for i in range(group.count):
			spawn_bloon(group.bloon_type)
			await get_tree().create_timer(group.interval).timeout

func spawn_bloon(type: BloonData):
	# Aquí es donde el PoolManager que planeamos entraría en juego
	var new_bloon = bloon_scene.instantiate()
	new_bloon.setup(type) 
	# IMPORTANTE: El globo debe ser hijo del Path2D para moverse
	path_to_follow.add_child(new_bloon)
