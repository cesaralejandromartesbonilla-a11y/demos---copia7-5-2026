extends CanvasLayer
class_name MotorHUD

@export_group("Diseño de Interfaz")
@export var slider_custom_size: Vector2 = Vector2(200, 40) 

var motor_machine: Node3D 
var processor: ProcessorComponent
var hinges: Array[HingeJoint3D] = []

@onready var controls_container = $PanelBackground/HBoxContainer/ScrollContainer/VBoxContainer
@onready var toggle_btn = $PanelBackground/Botonshift
@onready var close_btn = $PanelBackground/BotonCerrar

func setup(_motor: Node3D, _processor: ProcessorComponent) -> void:
	motor_machine = _motor
	processor = _processor
	
	hinges.clear()
	_find_hinges(motor_machine)
	
	close_btn.pressed.connect(func(): queue_free())
	
	if processor:
		_update_toggle_btn_text()
		toggle_btn.pressed.connect(_on_toggle_pressed)
		processor.machine_state_changed.connect(_on_state_changed)
		
	_populate_sliders()

func _find_hinges(node: Node) -> void:
	for child in node.get_children():
		if child is HingeJoint3D:
			hinges.append(child)
		_find_hinges(child) 

func _populate_sliders() -> void:
	for child in controls_container.get_children():
		child.queue_free()
		
	if hinges.is_empty():
		var lbl = Label.new()
		lbl.text = "Error: No se detectaron ejes físicos."
		controls_container.add_child(lbl)
		return
		
	var max_speed = motor_machine.target_speed if "target_speed" in motor_machine else 5.0
		
	for i in range(hinges.size()):
		var hinge = hinges[i]
		
		var row = HBoxContainer.new()
		
		var lbl_name = Label.new()
		lbl_name.text = "Eje " + str(i + 1) + ":"
		lbl_name.custom_minimum_size = Vector2(80, 0)
		
		var slider = HSlider.new()
		slider.min_value = -1.0 
		slider.max_value = 1.0  
		slider.step = 0.01
		
		# Aplicamos el tamaño personalizado del Inspector
		slider.custom_minimum_size = slider_custom_size
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# --- SOLUCIÓN AL RESETEO ---
		# Leemos la velocidad actual del motor para que la barra aparezca donde debe
		var current_vel = hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
		if max_speed != 0:
			slider.value = current_vel / max_speed
		else:
			slider.value = 0.0
		
		var lbl_val = Label.new()
		lbl_val.text = str(int(slider.value * 100)) + "%"
		lbl_val.custom_minimum_size = Vector2(50, 0)
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		slider.value_changed.connect(func(value: float):
			lbl_val.text = str(int(value * 100)) + "%"
			_update_hinge_speed(hinge, value)
		)
		
		row.add_child(lbl_name)
		row.add_child(slider)
		row.add_child(lbl_val)
		
		controls_container.add_child(row)

func _update_hinge_speed(hinge: HingeJoint3D, direction_multiplier: float) -> void:
	var max_speed = motor_machine.target_speed if "target_speed" in motor_machine else 5.0
	var final_speed = max_speed * direction_multiplier
	
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, final_speed)
	
	# --- SOLUCIÓN AL "NO HACE NADA" ---
	# Forzamos a los cuerpos físicos conectados a despertar
	var node_a = hinge.get_node_or_null(hinge.node_a)
	var node_b = hinge.get_node_or_null(hinge.node_b)
	
	if node_a is RigidBody3D: node_a.sleeping = false
	if node_b is RigidBody3D: node_b.sleeping = false

func _on_toggle_pressed() -> void:
	if processor:
		processor.toggle_machine()
		_update_toggle_btn_text()

func _update_toggle_btn_text() -> void:
	if processor:
		toggle_btn.text = "Apagar Motor" if processor.is_machine_enabled else "Encender Motor"

func _on_state_changed(_new_state: String) -> void:
	_update_toggle_btn_text()
