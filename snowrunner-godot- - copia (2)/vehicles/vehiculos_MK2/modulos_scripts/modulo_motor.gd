extends Node

@export_group("Configuración del Motor Hinge")
@export var fuerza_motor: float = 500.0    
@export var velocidad_maxima: float = 50.0 

var joints_ruedas: Array[Node] = []

func _ready() -> void:
	# MAGIA DE GRUPOS: El motor encuentra todas las ruedas motrices automáticamente
	joints_ruedas = get_tree().get_nodes_in_group("motor_traccion")
	
	for joint in joints_ruedas:
		joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
		joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)

func _physics_process(delta: float) -> void:
	var acelerador = Input.get_axis("ui_down", "ui_up")
	var freno = Input.is_action_pressed("ui_select") 
	
	for joint in joints_ruedas:
		if not is_instance_valid(joint): continue
		
		if freno:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_motor * 2.0)
			
		elif abs(acelerador) > 0.05:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocidad_maxima * acelerador)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, fuerza_motor)
			
		else:
			joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, false)
