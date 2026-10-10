extends CanvasLayer
## Barra del jefe, abajo y centrada: su nombre, la armadura (gris, hasta romperla)
## y el núcleo (rojo, lo que de verdad hay que vaciar). No sabe de qué jefe es:
## la sala le pasa los números con `set_values()`.

var _name_label: Label
var _armor_bar: SegmentedBar
var _core_bar: SegmentedBar


func _ready() -> void:
	layer = 6
	visible = false
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 0)
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.offset_left = 0.0
	box.offset_right = 0.0
	box.offset_top = -62.0
	box.offset_bottom = -14.0
	add_child(box)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", Color("#a39fa8"))
	box.add_child(_name_label)
	_armor_bar = _make_bar(box, Color("#3a3840"), Color("#a39fa8"), Color("#6a6670"), Color("#1b1a1f"))
	_core_bar = _make_bar(box, Color("#3a1218"), Color("#c2453f"), Color("#7a2430"), Color("#f08a6a"))


func _make_bar(parent: Control, back: Color, fill: Color, shade: Color, highlight: Color) -> SegmentedBar:
	var holder := CenterContainer.new()
	var bar := SegmentedBar.new()
	bar.segment_width = 16
	bar.bar_height = 6
	bar.back_color = back
	bar.fill_color = fill
	bar.shade_color = shade
	bar.highlight_color = highlight
	holder.add_child(bar)
	parent.add_child(holder)
	return bar


func show_boss(boss_name: String) -> void:
	_name_label.text = boss_name
	visible = true


func hide_boss() -> void:
	visible = false


func set_values(armor: int, armor_max: int, core: int, core_max: int) -> void:
	_armor_bar.set_values(armor, armor_max)
	_core_bar.set_values(core, core_max)
