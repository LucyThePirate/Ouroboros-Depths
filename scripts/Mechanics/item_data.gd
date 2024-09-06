class_name item_data extends Resource

enum ItemTypes {GENERIC, PART, }

@export var name : String = "Default Item"
@export_multiline var description : String = "A run-of-the-mill item.\nWhatcha lookin' at?"
@export var quantity : int = 1
@export var item_id : int = -1
@export var max_stack_size : int = 99
@export var icon : Texture2D
