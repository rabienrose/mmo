extends TextureRect

export (NodePath) var label_path
export (NodePath) var btn1_label_path
export (NodePath) var btn2_label_path

var btn1_cb=null
var btn2_cb=null

func _ready():
    pass # Replace with function body.

func hide_btn(btn_ind):
    if btn_ind==1:
        get_node(btn1_label_path).get_parent().visible=false
    elif btn_ind==2:
        get_node(btn2_label_path).get_parent().visible=false

func set_text(text):
    get_node(label_path).text=text

func set_btn1(text, cb):
    get_node(btn1_label_path).text=text
    btn1_cb=cb

func set_btn2(text, cb):
    get_node(btn2_label_path).text=text
    btn2_cb=cb

func _on_Cancel_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            btn1_cb.call_func()

func _on_Ok_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            btn2_cb.call_func()
