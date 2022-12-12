extends TextureRect

export (NodePath) var account_path
export (NodePath) var pw_path
export (NodePath) var alert_path

export (NodePath) var input_box_path

export (NodePath) var network_path

export var alert_ui_res:Resource

var http=null

const MODULO_8_BIT = 256

func getRandomInt():
	randomize()
	return randi() % MODULO_8_BIT

func uuidbin():
	return [
		getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
		getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
		((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
		getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	]

func v4():
	var b = uuidbin()
	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
		b[0], b[1], b[2], b[3],
		b[4], b[5],
		b[6], b[7],
		b[8], b[9],
		b[10], b[11], b[12], b[13], b[14], b[15]
	]

func on_alert_ok():
	get_node(alert_path).visible=false

func show_alert(alert_text):
	var t_node = get_node(alert_path)
	t_node.visible=true
	t_node.set_text(alert_text)
	t_node.set_btn1("OK",funcref(self, "on_alert_ok"))
	t_node.hide_btn(2)

func get_device_id():
	var f=File.new()
	if f.file_exists(Global.device_id_path):
		f.open(Global.device_id_path, File.READ)
		Global.device_id = f.get_as_text()
		f.close()
	else:
		Global.device_id=v4()
		f=File.new()
		f.open(Global.device_id_path, File.WRITE)
		f.store_string(Global.device_id)
		f.close()

func show_login_box(b_show):
	get_node(input_box_path).visible=b_show

func _ready():
	pass

func _on_LoginBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if http!=null:
				return
			var account=get_node(account_path).text
			var pw=get_node(pw_path).text
			if account!="" and pw!="":
				get_node(network_path).rpc_id(1, "login", account, pw)

func _on_RegistBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if http!=null:
				return
			var account=get_node(account_path).text
			var pw=get_node(pw_path).text
			if account!="" and pw!="":
				get_node(network_path).rpc_id(1, "regist", account, pw)

func _on_ClearBtn_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			get_node(account_path).text=""
			get_node(pw_path).text=""


func _on_Login_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			OS.hide_virtual_keyboard()

remote func login_result(result):
	if result["code"]=="ok":
		get_node(network_path).rpc_id(1,"on_user_enter",result["data"]["account"])
		Global.token=result["data"]["account"]
		Global.store_token()
	else:
		show_alert(result["code"])

remote func regist_result(result):
	if result["code"]=="ok":
		get_node(network_path).rpc_id(1,"on_user_enter",result["data"]["account"])
		Global.token=result["data"]["account"]
		Global.store_token()
	else:
		show_alert(result["code"])
