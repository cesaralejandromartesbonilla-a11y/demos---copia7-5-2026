extends Resource
class_name ItemData

@export_group("Datos Básicos")
@export var slot_cost: int = 1 
@export var weight_kg: float = 1.0 
@export var item_name: String = "Item"
@export var item_mesh: Mesh
@export var is_edible: bool = false
@export var item_category: String = "planta" # "planta", "carne", "podrido", "combustible"
@export var nutrition_value: float = 10.0

@export_group("Herramientas y Acciones")
@export var is_tool: bool = false
@export var can_till_soil: bool = false
@export var is_fire_starter: bool = false # Para quemar el trigo/limpiar parcelas
@export var is_pest_killer: bool = false # Para eliminar plagas

@export_group("Contenedores")
@export var is_container: bool = false
@export var gather_liquid_group: String = "agua"
@export var filled_result_data: ItemData

@export_group("Suministros Agrícolas")
@export var is_fertilizer: bool = false
@export var is_organic_matter: bool = false # Para los hongos

@export_group("Datos de Semilla")
@export var is_seed: bool = false
@export var result_item_data: ItemData # Lo que suelta al cosechar (Ej: Manzana)
@export var secondary_result_data: ItemData # Drop extra (Ej: Madera, Tallos, Semillas extra)
@export var drop_amount: int = 1
@export var visual_data: CropVisualData

enum CropType { NORMAL, TREE, FUNGUS, ALGAE }
enum TerrainRequired { DIRT, NORMAL_PLOT, LARGE_PLOT, FUNGUS_PLOT }

@export_group("Requisitos de Cultivo Avanzado")
@export var crop_type: CropType = CropType.NORMAL
@export var required_terrain: TerrainRequired = TerrainRequired.NORMAL_PLOT
@export var requires_submerged: bool = false
@export var water_needed: float = 100.0
@export var organic_matter_needed: float = 0.0

@export_group("Ciclo de Vida")
@export var vulnerable_to_pests: bool = true
@export var is_perennial: bool = false # True para árboles/algas (vuelve a crecer tras cosechar)
@export var leaves_trash_behind: bool = false # True para el trigo (deja restos que hay que quemar)
@export var grow_time_ticks: float = 100.0 # Cuánto tarda en crecer totalmente
