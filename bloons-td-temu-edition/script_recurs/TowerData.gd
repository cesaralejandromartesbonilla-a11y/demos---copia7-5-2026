class_name TowerData
extends Resource

@export var tower_id: String
@export var cost: int = 200
@export var range_radius: float = 150.0
@export var attack_cooldown: float = 1.0 # Tiempo entre disparos
@export var damage: int = 1
@export var pierce: int = 1 # A cuántos globos puede atravesar un proyectil
@export var tower_texture: Texture2D
@export var projectile_scene: PackedScene
@export var damage_type: GameEnums.DamageType = GameEnums.DamageType.SHARP
enum PlacementType { ESTANDAR, CAMINO, AGUA }
@export var allowed_terrain: PlacementType = PlacementType.ESTANDAR
