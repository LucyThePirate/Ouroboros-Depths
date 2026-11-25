extends Node2D

class_name DungeonLevel
@export var generator: GenerationStrategy
@export var continually_spawn_creatures := true
@export var initial_spawn_creatures := true
@export var tutorial_level := false
@export var is_arena := false

#region Fog
@onready var fog = %Fog
@onready var shade = %Shade as TileMapLayer
enum LightingModes { FULLY_LIT, FOG_ONLY, FOG_AND_SHADE }
@export var lighting_mode := LightingModes.FOG_AND_SHADE
#endregion

@onready var floors = %Floors
@onready var walls = %Walls
