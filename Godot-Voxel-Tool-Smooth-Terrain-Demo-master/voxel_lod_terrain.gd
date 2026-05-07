@tool
extends VoxelLodTerrain


func _ready() -> void:
	var texture1 = preload("res://assets/Stone.png").get_image()
	var texture2 = preload("res://assets/Grass.png").get_image()
	var texture3 = preload("res://assets/Wood.png").get_image()

	var texture_2d_array := Texture2DArray.new()
	texture_2d_array.create_from_images([texture1,texture2,texture3])

	material.set("shader_parameter/u_texture_array", texture_2d_array)
