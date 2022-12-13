extends Node2D
export (NodePath) var name_path
export (NodePath) var lv_path
export (NodePath) var exp_path
export (NodePath) var hp_path

export (NodePath) var menu_path
export (NodePath) var char_root_path
export (Array, NodePath) var attr_item_path
export (NodePath) var points_path
export (NodePath) var atk_path
export (NodePath) var def_path
export (NodePath) var m_atk_path
export (NodePath) var m_def_path
export (NodePath) var aspd_path
export (NodePath) var hit_path
export (NodePath) var flee_path
export (NodePath) var crit_path
export (NodePath) var exp_rate_path
export (NodePath) var max_hp_path
export (NodePath) var world_path

var world

func get_used_point():
	var user_point=0
	for path_node in attr_item_path:
		user_point=user_point+get_node(path_node).val2
	return user_point

func on_attr_val_change(attr_name):
	var user_point = get_used_point()
	get_node(points_path).text="点数: "+str(world.me.remain_points-user_point)
	refresh_char_info()

func _ready():
	world=get_node(world_path)
	world.get_node(world.network_path).connect("update_char_ui",self, "refresh_char_ui")
	for path_node in attr_item_path:
		get_node(path_node).connect("val_change", self, "on_attr_val_change")

func _on_Menu_button_down():
	get_node(menu_path).visible=!get_node(menu_path).visible

func refresh_main():
	get_node(name_path).text=world.me.account
	get_node(lv_path).text="LV: "+str(world.me.lv)
	get_node(exp_path).text="EXP: "+str(world.me.exp_a)
	get_node(hp_path).text="HP: "+str(world.me.hp)+"/"+str(world.me.max_hp)

func refresh_char_info():
	var _str=get_node(attr_item_path[0]).get_final_val()
	var _agi=get_node(attr_item_path[1]).get_final_val()
	var _vit=get_node(attr_item_path[2]).get_final_val()
	var _dex=get_node(attr_item_path[3]).get_final_val()
	var _int=get_node(attr_item_path[4]).get_final_val()
	var _luk=get_node(attr_item_path[5]).get_final_val()
	var info = world.me.cal_attr_by_input(_str, _vit, _agi, _dex, _int, _luk)
	var crit=info["crit"]
	var hit=info["hit"]
	var flee=info["flee"]
	var max_atk=info["max_atk"]
	var min_atk=info["min_atk"]
	var m_atk=info["m_atk"]
	var m_def=info["m_def"]
	var add_def=info["add_def"]
	var rate_def=info["rate_def"]
	var exp_rate=info["exp_rate"]
	var max_hp=info["max_hp"]
	var atk_spd=info["atk_spd"]
	get_node(atk_path).text="攻击: "+str(min_atk)+"-"+str(max_atk)
	get_node(def_path).text="防御: "+str(add_def)+"+"+str(int(rate_def*100))+"%"
	get_node(m_atk_path).text="魔法攻击: "+str(m_atk)
	get_node(m_def_path).text="魔法防御: "+str(m_def)
	get_node(flee_path).text="回避: "+str(flee)
	get_node(hit_path).text="命中: "+str(hit)
	get_node(crit_path).text="暴击率: "+str(int(crit*100))+"%"
	get_node(exp_rate_path).text="经验倍率: "+str(stepify(exp_rate, 0.01) )
	get_node(max_hp_path).text="最大HP: "+str(max_hp)
	get_node(aspd_path).text="攻击速度: "+str(stepify(atk_spd, 0.1))+"/s"

func refresh_char_ui():
	get_node(attr_item_path[0]).init("str", world.me.str_a)
	get_node(attr_item_path[1]).init("agi", world.me.agi)
	get_node(attr_item_path[2]).init("vit", world.me.vit)
	get_node(attr_item_path[3]).init("dex", world.me.dex)
	get_node(attr_item_path[4]).init("int", world.me.int_a)
	get_node(attr_item_path[5]).init("luk", world.me.luk)
	get_node(points_path).text="点数: "+str(world.me.remain_points)
	refresh_char_info()

func show_char_ui():
	refresh_char_ui()
	get_node(char_root_path).visible=true

func _on_Chara_button_up():
	if get_node(char_root_path).visible:
		get_node(char_root_path).visible=false
	else:
		show_char_ui()

func _on_Clear_button_up():
	for path_node in attr_item_path:
		get_node(path_node).val2=0
	get_node(points_path).text="点数: "+str(world.me.remain_points)
	refresh_char_info()
	
func _on_OK_button_up():
	var user_point = get_used_point()
	if user_point==0 or world.me.remain_points-user_point<0:
		return
	var info={}
	for path_node in attr_item_path:
		info[get_node(path_node).attr_name]=get_node(path_node).val2
	world.network.rpc_id(1, "request_modify_player_attr",info)


