extends Node3D

@export_group("Referencias")
@export var chasis: VehicleBody3D
@export var esqueleto: Skeleton3D

@export_group("Configuración Principal")
@export var configuracion_ejes: Array[DatosEje] = []

@export_group("Ajustes de Torsión")
@export var huesos_torsion_chasis: Array[String]
@export_enum("X", "Y", "Z") var eje_torsion: int = 2 
@export var multiplicador_torsion: float = 1.0
@export var suavizado_torsion: float = 5.0

@export_group("Corrección de Llantas")
@export var eje_volante: Vector3 = Vector3.FORWARD  
@export var eje_rodamiento: Vector3 = Vector3.RIGHT 

# Almacenamiento Interno (Se llena solo en el _ready)
var ruedas_izq: Array[VehicleWheel3D] = []
var ruedas_der: Array[VehicleWheel3D] = []
var ids_brazos_izq: Array[int] = []
var ids_brazos_der: Array[int] = []
var ids_llantas_izq: Array[int] = []
var ids_llantas_der: Array[int] = []
var ids_torsion: Array[int] = []

var poses_originales_brazos_izq: Array[Transform3D] = []
var poses_originales_brazos_der: Array[Transform3D] = []
var rot_rodamiento_izq: Array[float] = []
var rot_rodamiento_der: Array[float] = []
var angulos_torsion_suavizados: Array[float] = []

var pos_y_original_ruedas_izq: Array[float] = []
var pos_y_original_ruedas_der: Array[float] = []

func _ready() -> void:
	if not esqueleto or not chasis: return
	
	# Extraemos la información de los Recursos y llenamos las listas
	for eje in configuracion_ejes:
		if not eje: continue
		
		# Le decimos a Godot: "Busca la ruta, pero si es un nombre simple, búscalo dentro del chasis"
		var r_izq = get_node_or_null(eje.ruta_rueda_izq) as VehicleWheel3D
		if not r_izq: r_izq = chasis.get_node(String(eje.ruta_rueda_izq)) as VehicleWheel3D
			
		var r_der = get_node_or_null(eje.ruta_rueda_der) as VehicleWheel3D
		if not r_der: r_der = chasis.get_node(String(eje.ruta_rueda_der)) as VehicleWheel3D
		ruedas_izq.append(r_izq)
		ruedas_der.append(r_der)
		
		var id_bi = esqueleto.find_bone(eje.hueso_brazo_izq)
		var id_bd = esqueleto.find_bone(eje.hueso_brazo_der)
		ids_brazos_izq.append(id_bi)
		ids_brazos_der.append(id_bd)
		ids_llantas_izq.append(esqueleto.find_bone(eje.hueso_llanta_izq))
		ids_llantas_der.append(esqueleto.find_bone(eje.hueso_llanta_der))
		
		poses_originales_brazos_izq.append(esqueleto.get_bone_rest(id_bi))
		poses_originales_brazos_der.append(esqueleto.get_bone_rest(id_bd))
		
		# INICIALIZAR ARRAYS SEPARADOS
		rot_rodamiento_izq.append(0.0)
		rot_rodamiento_der.append(0.0)
		
		pos_y_original_ruedas_izq.append(r_izq.position.y)
		pos_y_original_ruedas_der.append(r_der.position.y)

	for nombre in huesos_torsion_chasis:
		ids_torsion.append(esqueleto.find_bone(nombre))
		angulos_torsion_suavizados.append(0.0)

func _physics_process(delta: float) -> void:
	if not esqueleto: return
	for i in range(ruedas_izq.size()):
		_actualizar_esquina(i, true, delta)
		_actualizar_esquina(i, false, delta)
	_actualizar_torsion_chasis(delta)

func _actualizar_esquina(indice: int, es_izq: bool, delta: float) -> void:
	var config_actual = configuracion_ejes[indice] 
	
	var rueda = ruedas_izq[indice] if es_izq else ruedas_der[indice]
	var id_brazo = ids_brazos_izq[indice] if es_izq else ids_brazos_der[indice]
	var id_llanta = ids_llantas_izq[indice] if es_izq else ids_llantas_der[indice]

	# --- 1. SUSPENSIÓN INMUNE A ROTACIONES DEL PADRE ---
	if id_brazo != -1:
		var pose_rest = poses_originales_brazos_izq[indice] if es_izq else poses_originales_brazos_der[indice]
		var y_base_rueda = pos_y_original_ruedas_izq[indice] if es_izq else pos_y_original_ruedas_der[indice]
		var compresion = (rueda.position.y - y_base_rueda) * config_actual.multiplicador_suspension 
		
		var offset_local = Vector3(0, compresion, 0)
		var parent_id = esqueleto.get_bone_parent(id_brazo)
		
		# Si el hueso tiene un padre, rotamos el vector "Arriba" hacia el espacio del padre
		if parent_id != -1:
			var parent_rest = esqueleto.get_bone_global_rest(parent_id)
			offset_local = parent_rest.basis.inverse() * Vector3(0, compresion, 0)
			
		esqueleto.set_bone_pose_position(id_brazo, pose_rest.origin + offset_local)

	# --- 2. ROTACIÓN Y DIRECCIÓN (Sin conflictos) ---
	if id_llanta != -1:
		var invertir = config_actual.invertir_giro_izq if es_izq else config_actual.invertir_giro_der
		var direccion_giro = -1.0 if invertir else 1.0
		
		var rotacion_actual = 0.0
		if es_izq:
			rot_rodamiento_izq[indice] += (rueda.get_rpm() * PI / 30.0) * delta * direccion_giro
			rotacion_actual = rot_rodamiento_izq[indice]
		else:
			rot_rodamiento_der[indice] += (rueda.get_rpm() * PI / 30.0) * delta * direccion_giro
			rotacion_actual = rot_rodamiento_der[indice]
		
		var pose_rest_llanta = esqueleto.get_bone_rest(id_llanta)
		var q_original = pose_rest_llanta.basis.get_rotation_quaternion()
		var q_steering = Quaternion(eje_volante, rueda.steering)
		var q_roll = Quaternion(eje_rodamiento, rotacion_actual)
		
		esqueleto.set_bone_pose_rotation(id_llanta, q_original * q_steering * q_roll)

func _actualizar_torsion_chasis(delta: float) -> void:
	# Tu código original exacto
	var angulos_reales = []
	for i in range(ruedas_izq.size()):
		var angulo_eje = 0.0
		if ruedas_izq[i].is_in_contact() or ruedas_der[i].is_in_contact():
			var local_i = chasis.to_local(ruedas_izq[i].get_contact_point())
			var local_d = chasis.to_local(ruedas_der[i].get_contact_point())
			angulo_eje = atan2(local_i.y - local_d.y, abs(ruedas_izq[i].position.x - ruedas_der[i].position.x))
		
		angulos_torsion_suavizados[i] = lerp(angulos_torsion_suavizados[i], angulo_eje * multiplicador_torsion, suavizado_torsion * delta)
		angulos_reales.append(angulos_torsion_suavizados[i])

	for i in range(ids_torsion.size()):
		var rot_relativa = angulos_reales[i]
		if i > 0: rot_relativa = angulos_reales[i] - angulos_reales[i-1]
		
		var eje_vec = Vector3.ZERO
		if eje_torsion == 0: eje_vec = Vector3.RIGHT
		elif eje_torsion == 1: eje_vec = Vector3.UP
		else: eje_vec = Vector3.FORWARD
		
		esqueleto.set_bone_pose_rotation(ids_torsion[i], Quaternion(eje_vec, rot_relativa))
