extends Node
class_name ControladorVehiculo

enum Traccion { DELANTERA, TRASERA, TOTAL }
enum Direccion { NORMAL, OPUESTA, CANGREJO }

@export_group("Modos Actuales (UI)")
@export var modo_traccion: Traccion = Traccion.TOTAL
@export var modo_direccion: Direccion = Direccion.NORMAL

@export_group("Configuración Tracción")
@export var fuerza_motor: float = 1500.0
@export var velocidad_max_motor: float = 50.0
@export var traccion_delantera: Array[HingeJoint3D] = []
@export var traccion_trasera: Array[HingeJoint3D] = []

@export_group("Configuración Dirección")
@export var fuerza_direccion: float = 1500.0
@export var grados_maximos: float = 30.0
@export var velocidad_volante: float = 5.0
@export var velocidad_retorno: float = 8.0
@export var auto_centrar: bool = true
@export var direccion_delantera: Array[HingeJoint3D] = []
@export var direccion_trasera: Array[HingeJoint3D] = []

func _ready() -> void:
	var limite_rad = deg_to_rad(grados_maximos)
	var todos_direccion = direccion_delantera + direccion_trasera
	for joint in todos_direccion:
		if is_instance_valid(joint):
			joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -limite_rad)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, limite_rad)
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)

func _physics_process(delta: float) -> void:
	var acelerador = Input.get_axis("ui_down", "ui_up")
	var freno = Input.is_action_pressed("ui_select")
	var volante = Input.get_axis("ui_left", "ui_right")
	
	_procesar_traccion(acelerador, freno)
	_procesar_direccion(volante)

func _procesar_traccion(acelerador: float, freno: bool) -> void:
	var ruedas_activas: Array[HingeJoint3D] = []
	if modo_traccion == Traccion.DELANTERA or modo_traccion == Traccion.TOTAL:
		ruedas_activas.append_array(traccion_delantera)
	if modo_traccion == Traccion.TRASERA or modo_traccion == Traccion.TOTAL:
		ruedas_activas.append_array(traccion_trasera)
		
	var todas_traccion = traccion_delantera + traccion_trasera
	for joint in todas_traccion:
		if not is_instance_valid(joint): continue
		
		# Si la rueda no está en el modo activo, la dejamos libre
		if not ruedas_activas.has(joint):
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 0.0)
			continue
			
		if freno:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_motor * 2.0)
		elif abs(acelerador) > 0.05:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocidad_max_motor * acelerador)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_motor)
		else:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 0.0)

func _procesar_direccion(volante: float) -> void:
	# El eje delantero siempre gira normal (Multiplicador 1.0)
	_aplicar_giro_eje(direccion_delantera, volante, 1.0) 
	
	var multiplicador_trasero = 0.0
	if modo_direccion == Direccion.OPUESTA:
		multiplicador_trasero = -1.0 # Giran al revés (Cerrar curvas)
	elif modo_direccion == Direccion.CANGREJO:
		multiplicador_trasero = 1.0  # Giran igual (Avanzar diagonal)
		
	_aplicar_giro_eje(direccion_trasera, volante, multiplicador_trasero)

func _aplicar_giro_eje(eje: Array[HingeJoint3D], volante: float, multiplicador: float) -> void:
	for joint in eje:
		if not is_instance_valid(joint): continue
		var vel_actual = 0.0
		
		# Si el multiplicador es 0 (Modo normal para eje trasero), forzamos centrado
		if multiplicador == 0.0:
			vel_actual = _calcular_centrado(joint)
		elif abs(volante) > 0.05:
			vel_actual = velocidad_volante * (volante * multiplicador)
		else:
			if auto_centrar:
				vel_actual = _calcular_centrado(joint)
				
		joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_actual)
		joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_direccion)

func _calcular_centrado(joint: HingeJoint3D) -> float:
	var mangueta = joint.get_node_or_null(joint.node_b) as Node3D
	var brazo = joint.get_node_or_null(joint.node_a) as Node3D
	if mangueta and brazo:
		var transform_local = brazo.global_transform.affine_inverse() * mangueta.global_transform
		var angulo = transform_local.basis.get_euler().y
		if abs(angulo) > 0.01:
			return -angulo * velocidad_retorno
	return 0.0

# --- FUNCIONES PARA LLAMAR DESDE TU INTERFAZ (UI) ---

func cambiar_traccion(nuevo_modo: int) -> void:
	# 0 = DELANTERA, 1 = TRASERA, 2 = TOTAL
	modo_traccion = nuevo_modo as Traccion

func cambiar_direccion(nuevo_modo: int) -> void:
	# 0 = NORMAL, 1 = OPUESTA, 2 = CANGREJO
	modo_direccion = nuevo_modo as Direccion
