extends Node
# GLOBAL / AUTOLOAD (WeatherManager)

# 1. Añadimos las señales para que el Sol y el Entorno puedan escuchar
signal time_changed(current_time: float)
signal weather_changed(new_weather: WeatherType)

enum WeatherType { CLEAR, RAIN, STORM, DROUGHT }
var current_weather: WeatherType = WeatherType.CLEAR
var current_biome: String = "pradera" 
enum TempState { EXTREME_HOT, HOT, TROPICAL, TEMPERATE, COLD, EXTREME_COLD }
var current_temp: TempState = TempState.TEMPERATE

var time_of_day: float = 8.0
var is_day: bool = true
var time_multiplier: float = 1.0 

# 2. Usamos preload() para que Godot sepa que es una escena instanciable
var weather_entity_scene = preload("res://models/relacionado a los biomas/cloud.tscn")
var spawn_timer: float = 0.0

func _process(delta: float) -> void:
	# TUS LÓGICAS ORIGINALES INTÁCTAS
	time_of_day = fmod(time_of_day + (delta * 0.1), 24.0)
	is_day = time_of_day >= 6.0 and time_of_day <= 18.0
	_handle_time_cycle(delta)
	
	# Generación esporádica de clima
	_handle_weather_spawning(delta)
	
	# 3. Emitimos la señal para que el Sol sepa qué hora es y rote
	time_changed.emit(time_of_day)

func _handle_time_cycle(delta: float) -> void:
	time_of_day += (delta * time_multiplier) / 60.0 
	if time_of_day >= 24.0:
		time_of_day = 0.0
		
	var was_day = is_day
	is_day = (time_of_day >= 6.0 and time_of_day <= 18.0)
	if was_day != is_day:
		print("Día/Noche cambiado. Es de día: ", is_day)

func _handle_weather_spawning(delta: float):
	spawn_timer += delta
	# Intenta spawnear una nube cada 60 segundos
	if spawn_timer >= 60.0:
		spawn_timer = 0.0
		_spawn_random_weather()

func _spawn_random_weather():
	if not weather_entity_scene:
		print("no hay nubes")
		return
	
	var spawn_points = get_tree().get_nodes_in_group("weather_spawn")
	if spawn_points.is_empty(): return
	var random_spawner = spawn_points[randi() % spawn_points.size()]
	
	var new_weather = weather_entity_scene.instantiate()
	get_tree().current_scene.add_child(new_weather)
	new_weather.global_position = random_spawner.global_position
	print("se spawneo una nube")

# Función para cambiar el clima global y avisar a los biomas
func set_weather(new_weather: WeatherType):
	if current_weather != new_weather:
		current_weather = new_weather
		weather_changed.emit(current_weather)
		print("El clima ha cambiado a: ", WeatherType.keys()[current_weather])
