class_name BloonData
extends Resource

@export_group("Hierarchy")
@export var children_on_pop: Array[BloonData] # Lista de globos que aparecen al morir
@export var children_count: int = 1            # Cuántos de esos globos aparecen
@export_group("stats_base")
@export var bloon_id: String # ej. "red", "blue", "ceramic"
@export var speed: float = 100.0
@export var health: int = 1 # Daño necesario para "explotar" esta capa
@export var reward_money: int = 1
@export var bloon_texture: Texture2D
@export var immunities: Array[GameEnums.DamageType] = []
