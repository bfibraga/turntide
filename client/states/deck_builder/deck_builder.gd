[gd_scene format=3 uid="uid://deck_builder_state_scene"]

[ext_resource type="Script" uid="uid://deck_builder_state" path="res://states/deck_builder/deck_builder_state.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://deck_builder_scene" path="res://scenes/deck_builder/deck_builder.tscn" id="2"]

[node name="DeckBuilder" type="Node"]
script = ExtResource("1")
packed_scene = ExtResource("2")