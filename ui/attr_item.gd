extends Control
export (NodePath) var name_path
export (NodePath) var val1_path
export (NodePath) var val2_path

signal val_change(attr_name)

var attr_name
var val1
var val2=0

func update_value():
	get_node(val2_path).text=str(val2)

func init(_attr_name, _val1):
	val1=_val1
	val2=0
	get_node(name_path).text=_attr_name.to_upper()
	get_node(val1_path).text=str(val1)
	update_value()
	attr_name=_attr_name

func _on_Dec_button_down():
	if val2>0:
		val2=val2-1
		emit_signal("val_change", attr_name)
		update_value()

func _on_Inc_button_down():
	val2=val2+1
	update_value()
	emit_signal("val_change", attr_name)
		

func get_final_val():
	return val1+val2
