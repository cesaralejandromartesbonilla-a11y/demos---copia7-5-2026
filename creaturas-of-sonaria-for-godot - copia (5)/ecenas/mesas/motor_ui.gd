extends CanvasLayer
class_name MotorHUD

var motor_machine: Node3D 
var processor: ProcessorComponent
var hinges: Array[HingeJoint3D] = []

@onready var controls_container = $PanelBackground/HBoxContainer/ScrollContainer
@onready var toggle_btn = $PanelBackground/Botonshift
@onready var close_btn = $PanelBackground/BotonCerrar

func setup(_motor: Node3D, _processor: ProcessorComponent) -> void:
	motor_machine = _motor
	processor = _processor
	
	# 1. Rastrear automáticamente cuántos ejes (Hinges) tiene este motor
	hinges.clear()
	_find_hinges(motor_machine)
	
	# 2. Conectar los botones base
	close_btn.pressed.connect(func(): queue_free())
	
	if processor:
		_update_toggle_btn_text()
		toggle_btn.pressed.connect(_on_toggle_pressed)
		processor.machine_state_changed.connect(_on_state_changed)
		
	# 3. Dibujar las barras deslizantes según la cantidad de ejes
	_populate_sliders()

# Buscador recursivo (encuentra HingeJoints aunque estén dentro de otros nodos)
func _find_hinges(node: Node) -> void:
	for child in node.get_children():
		if child is HingeJoint3D:
			hinges.append(child)
		_find_hinges(child) 

# ==========================================
# GENERACIÓN DINÁMICA DE SLIDERS
# ==========================================
func _populate_sliders() -> void:
	# Limpiamos cosas viejas por si acaso
	for child in controls_container.get_children():
		child.queue_free()
		
	if hinges.is_empty():
		var lbl = Label.new()
		lbl.text = "Error: No se detectaron ejes físicos."
		controls_container.add_child(lbl)
		return
		
	# Creamos un Slider por cada eje encontrado
	for i in range(hinges.size()):
		var hinge = hinges[i]
		
		# Contenedor horizontal para: [Nombre] [====|====] [Valor %]
		var row = HBoxContainer.new()
		
		var lbl_name = Label.new()
		lbl_name.text = "Eje " + str(i + 1) + ":"
		lbl_name.custom_minimum_size = Vector2(200, 10)
		
		var slider = HSlider.new()
		slider.min_value = -1.0 # 100% Antihorario
		slider.max_value = 1.0  # 100% Horario
		slider.step = 0.01
		slider.value = 0.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var lbl_val = Label.new()
		lbl_val.text = "0%"
		lbl_val.custom_minimum_size = Vector2(50, 0)
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		# La magia: conectar el movimiento de la barra a la velocidad del motor
		slider.value_changed.connect(func(value: float):
			lbl_val.text = str(int(value * 100)) + "%"
			_update_hinge_speed(hinge, value)
		)
		
		row.add_child(lbl_name)
		row.add_child(slider)
		row.add_child(lbl_val)
		
		controls_container.add_child(row)

func _update_hinge_speed(hinge: HingeJoint3D, direction_multiplier: float) -> void:
	# Tomamos la velocidad máxima del script principal del motor
	var max_speed = motor_machine.target_speed if "target_speed" in motor_machine else 5.0
	var final_speed = max_speed * direction_multiplier
	
	# Actualizamos la velocidad directamente en la física del eje
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, final_speed)

# ==========================================
# CONTROLES DE ENCENDIDO
# ==========================================
func _on_toggle_pressed() -> void:
	if processor:
		processor.toggle_machine()
		_update_toggle_btn_text()

func _update_toggle_btn_text() -> void:
	if processor:
		toggle_btn.text = "Apagar Motor" if processor.is_machine_enabled else "Encender Motor"

func _on_state_changed(_new_state: String) -> void:
	_update_toggle_btn_text()
