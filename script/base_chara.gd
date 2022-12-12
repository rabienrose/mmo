extends KinematicBody

class_name BaseChara

export (NodePath) var ground_ray_cast_path
export (NodePath) var model_path
export (NodePath) var anim_tree_path
export (NodePath) var char_ui_path
var ground_ray_cast
var world
var model

var ai_sub_status="stop" # atk mov idle
var ai_scheme="stand" # stand battle walk rand_walk
var ai_battle_target=null
var cur_path=[]
var path_index=-1 

var max_hp
var max_sp
var hp=100
var sp=10
var lv=1
var exp_a=1
var str_a=5
var vit=100
var agi=1
var int_a=5
var dex=5
var luk=5
var atk_range=1
var atk_spd=1
var atk
var def
var m_atk
var m_def
var flee
var hit
var crit
var mov_spd=1
var b_dead=false

var last_idle_time
var last_atk_time
var last_ai_time
var last_path_find_time
var ai_update_t=200
var path_update_t=1000
var randwalk_idle_time=1000

func add_exp(exp_add):
	pass

func on_create(_world):
	world=_world

func cal_attr():
	atk=str_a
	atk_spd=agi
	max_hp=vit

func get_unit_info():
	var info={}
	info["hp"]=hp
	info["sp"]=sp
	info["lv"]=lv
	info["exp"]=exp_a
	info["str"]=str_a
	info["vit"]=vit
	info["agi"]=agi
	info["int"]=int_a
	info["dex"]=dex
	info["luk"]=luk
	info["mov_spd"]=mov_spd
	if is_inside_tree():
		info["cur_posi"]=Global.v3_2_list(global_transform.origin)
	else:
		info["cur_posi"]=[0,0,0]
	return info

func init_unit_data():
	pass

func set_base_attr_by_info(info):
	str_a=info["str"]
	vit=info["vit"]
	agi=info["agi"]
	int_a=info["int"]
	dex=info["dex"]
	luk=info["luk"]
	mov_spd=info["mov_spd"]

func set_unit_info(info):
	set_base_attr_by_info(info)
	hp=info["hp"]
	sp=info["sp"]
	lv=info["lv"]
	exp_a=info["exp"]
	cal_attr()

func update_hp_bar():
	get_node(char_ui_path).update_hp_bar(hp, max_hp)

func set_ground_position(posi_ground):
	global_transform.origin=posi_ground

remotesync func destroy_self():
	queue_free()

func on_die(killer):
	b_dead=true
	world.network_destroy_unit(self)

func on_damaged(dmg, attacker):
	hp=hp-dmg
	if hp<=0:
		on_die(attacker)
	else:
		rpc("trigger_loss_hp",dmg, hp)

remote func request_battle(tar_name):
	if get_tree().is_network_server():
		var tar_obj=world.get_mob_by_name(tar_name)
		if tar_obj==null:
			tar_obj=world.get_player_by_name(tar_name)
		if tar_obj!=null:
			set_ai_scheme("battle",{"battle_tar":tar_obj})
		else:
			print("error: no battle target")

remotesync func start_move(path_node,_mov_spd, path_ind=0):
	path_index=path_ind
	mov_spd=_mov_spd
	cur_path=path_node
	set_anima_walk()

remote func request_move_to(posi):
	set_ai_scheme("walk",{"mov_posi":posi})
	
remote func set_anima_idle():
	if get_tree().is_network_server()==false:
		get_node(anim_tree_path).set("parameters/WalkIdle/current",1)

remote func set_anima_walk():
	if get_tree().is_network_server()==false:
		get_node(anim_tree_path).set("parameters/WalkIdle/current",0)

remote func trigger_anima_atk():
	if get_tree().is_network_server()==false:
		get_node(anim_tree_path).set("parameters/AttackOn/active",true)

remote func trigger_loss_hp(dmg, new_hp):
	if get_tree().is_network_server()==false:
		hp=new_hp
		get_node(char_ui_path).toggle_hpbar(true)
		update_hp_bar()

func set_ai_scheme(scheme_name, info):
	if get_tree().is_network_server():
		ai_scheme = scheme_name
		if scheme_name=="stop":
			set_ai_sub("idle",{})
		elif scheme_name=="rand_walk":
			set_ai_sub("idle",{})
			last_idle_time=OS.get_ticks_msec()
		elif scheme_name=="walk":
			ai_battle_target=null
			set_ai_sub("mov", info)
		elif scheme_name=="battle":
			ai_battle_target=info["battle_tar"]
			set_ai_sub("mov", {"mov_posi":ai_battle_target.global_transform.origin})

func set_ai_sub(sub_name, info):
	if get_tree().is_network_server():
		ai_sub_status=sub_name
		if sub_name=="idle":
			rpc("set_anima_idle")
		elif sub_name=="mov":
			var posi=info["mov_posi"]
			var t_path = world.get_navi_path(global_transform.origin, posi)
			rpc("start_move",t_path, mov_spd)
		elif sub_name=="atk":
			pass

func on_move_end():
	if ai_scheme=="battle":
		pass
	elif ai_scheme=="rand_walk":
		set_ai_sub("idle",{})
		last_idle_time=OS.get_ticks_msec()
	elif ai_scheme=="walk":
		set_ai_sub("idle",{})

func on_tar_die():
	pass

func check_tar_die():
	if is_instance_valid(ai_battle_target) and ai_battle_target.b_dead==false:
		return false
	else:
		on_tar_die()
		return true

func _physics_process(delta):
	if cur_path.size()>0:
		if path_index<cur_path.size():
			var dir=cur_path[path_index]-global_transform.origin
			if dir.length()<0.3:
				path_index=path_index+1
			else:
				var dir_n=dir.normalized()
				var dir_angle=atan2(dir_n.x,dir_n.z)+PI
				model.rotation.y=dir_angle
				global_transform.origin=global_transform.origin+dir_n*delta*mov_spd
		else:
			cur_path=[]
			path_index=-1
	var cur_time=OS.get_ticks_msec()
	if get_tree().is_network_server() and cur_time-last_ai_time>ai_update_t:
		if ai_sub_status=="mov":
			if cur_path.size()==0:
				on_move_end()
		elif ai_sub_status=="atk":
			if cur_time-last_atk_time>1.0/atk_spd*1000:
				last_atk_time=cur_time
				if check_tar_die()==false:
					var dist=(ai_battle_target.global_transform.origin-global_transform.origin).length()
					if dist<atk_range:
						rpc("trigger_anima_atk")
						ai_battle_target.on_damaged(atk, self)    
		if ai_scheme=="battle":
			if check_tar_die()==false:
				var dist=(ai_battle_target.global_transform.origin-global_transform.origin).length()
				if dist<atk_range:
					if ai_sub_status!="atk":
						set_ai_sub("atk", {"atk_tar":ai_battle_target})
				else:
					if cur_time-last_path_find_time>path_update_t:
						last_path_find_time=cur_time
						set_ai_sub("mov", {"mov_posi":ai_battle_target.global_transform.origin})
		elif ai_scheme=="rand_walk":
			if ai_sub_status=="idle":
				if cur_time-last_idle_time>randwalk_idle_time:
					last_idle_time=cur_time
					var chance =Global.rng.randf_range(0,1)
					if chance>0.5:
						var posi = world.get_rand_free_spot()
						set_ai_sub("mov", {"mov_posi":posi})
		last_ai_time=cur_time

func set_hp_by_info(info):
	if "hp" in info:
		hp=info["hp"]
	else:
		hp=max_hp
	update_hp_bar()

func _ready():
	# ground_ray_cast=get_node(ground_ray_cast_path)
	model=get_node(model_path)
	last_atk_time=OS.get_ticks_msec()
	last_ai_time=last_atk_time
	last_path_find_time=last_atk_time
	last_idle_time=last_atk_time
