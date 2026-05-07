extends Node3D
class_name MotorHingeMachine

@export_group("Configuración del Motor")
@export var machine_name: String = "Motor Rotativo"
@export var target_speed: float = 5.0 # Velocidad de giro (Radianes por segundo)
@export var max_torque: float = 100.0 # Fuerza del motor (Max Impulse)

@onready var processor: ProcessorComponent = get_node_or_null("ProcessorComponent")
@onready var hinge: HingeJoint3D = get_node_or_null("HingeJoint3D")

var is_in_use: bool = false

func _ready() -> void:
	add_to_group("estructuras")
	
	if processor:
		processor.machine_state_changed.connect(_on_machine_state_changed)
	else:
		print("Error: El Motor no encontró su ProcessorComponent.")
		
	if not hinge:
		print("Error: El Motor necesita un HingeJoint3D como hijo.")
		
	# Aseguramos que el motor inicie apagado físicamente
	_set_motor_active(false)

# Interfaz básica para interactuar y abrir el menú (similar a CraftingTable)
func interact(player: Node3D) -> void:
	if is_in_use: return
	# Aquí llamaremos a la nueva UI que tienes planeada.
	print("Abriendo menú del motor: ", machine_name)
	# is_in_use = true

func _on_machine_state_changed(new_state: String) -> void:
	match new_state:
		# IDLE significa que la máquina está ON y tiene recursos, pero no craftea.
		# WORKING se incluye por si decides añadirle "recetas de movimiento" en el futuro.
		"IDLE", "WORKING":
			_set_motor_active(true)
		
		# Cualquier estado de falta de recursos o apagado detiene el eje
		"OFF", "NO_FUEL", "NO_POWER", "NO_FLUID", "JAMMED":
			_set_motor_active(false)

func _set_motor_active(active: bool) -> void:
	if hinge == null: return
	
	# Activamos o desactivamos la bandera del motor en el HingeJoint3D
	hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, active)
	
	if active:
		# Le damos velocidad y fuerza para mover los RigidBody3D conectados
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target_speed)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, max_torque)
	else:
		# Frenamos el motor
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 0.0)
