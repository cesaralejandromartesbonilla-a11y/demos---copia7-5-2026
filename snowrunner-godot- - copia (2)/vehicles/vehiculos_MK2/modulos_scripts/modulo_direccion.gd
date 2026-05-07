extends Node

@export_group("Configuración de Dirección")
@export var grados_maximos: float = 30.0     # Cuánto gira la llanta como máximo
@export var velocidad_volante: float = 10.0  # Qué tan rápido gira
@export var fuerza_direccion: float = 1000.0 # Fuerza de la hidráulica

var joints_direccion: Array[Node] = []

func _ready() -> void:
	# Busca todos los ejes de dirección
	joints_direccion = get_tree().get_nodes_in_group("motor_direccion")
	
	for joint in joints_direccion:
		joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_direccion)

func _physics_process(delta: float) -> void:
	# Rellena con tus teclas de girar izquierda/derecha
	var volante = Input.get_axis("ui_right", "ui_left") 
	var angulo_objetivo = deg_to_rad(grados_maximos) * volante
	
	for joint in joints_direccion:
		if not is_instance_valid(joint): continue
		
		# Obtenemos la mangueta (el cuerpo físico que está girando)
		var mangueta = joint.get_node_or_null(joint.node_b) as Node3D
		if mangueta:
			# Asumimos que la mangueta gira sobre el eje Y (Arriba/Abajo)
			var angulo_actual = mangueta.rotation.y 
			
			# Calculamos el error y definimos la velocidad para corregirlo
			var error = angulo_objetivo - angulo_actual
			var vel_necesaria = error * velocidad_volante
			
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_necesaria)
