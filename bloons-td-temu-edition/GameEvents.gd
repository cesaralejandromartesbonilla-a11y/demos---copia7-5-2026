# GameEvents.gd (Autoload)
extends Node

signal bloon_popped(gold_earned: int)
signal bloon_reached_end(damage_to_base: int)
signal tower_placed(tower_resource: TowerData)
signal wave_started(wave_number: int)
signal wave_finished()
signal request_tower_placement(tower_data: TowerData)
