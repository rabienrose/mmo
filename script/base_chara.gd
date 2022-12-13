extends KinematicBody

class_name BaseChara

export (NodePath) var ground_ray_cast_path
export (NodePath) var model_path
export (NodePath) var anim_tree_path
export (NodePath) var char_ui_path
var ground_ray_cast
var world
var model

var ai_sub_status="idle" # atk mov idle
var ai_scheme="stand" # stand battle
var ai_battle_target=null
var cur_path=[]
var path_index=-1 

var max_hp=100
var hp=100
var lv=1
var atk_range=1
var atk_spd=1
var min_atk=10
var max_atk=10
var add_def=0
var rate_def=0
var m_atk=10
var m_def=0
var flee=0
var hit=0
var crit=0
var mov_spd=1
var b_dead=false

var last_idle_time
var last_atk_time
var last_ai_time
var last_path_find_time
var ai_update_t=200
var path_update_t=1000
var last_action_time=0

remotesync func recover_hp(amount):
	hp=hp+amount
	if hp>max_hp:
		hp=max_hp
	update_hp_bar()
	if get_tree().is_network_server()==false:
		pass

func add_exp(exp_add):
	pass

func on_create(_world):
	world=_world

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

remotesync func set_hp(new_hp):
	hp=new_hp
	update_hp_bar()
	
remotesync func start_move(path_node,_mov_spd, path_ind=0):
	path_index=path_ind
	mov_spd=_mov_spd
	cur_path=path_node
	set_anima_walk()

remotesync func teleport(posi):
	global_transform.origin=posi
	
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

func set_ai_scheme(scheme_name, info):
	if get_tree().is_network_server():
		ai_scheme = scheme_name
		if scheme_name=="stand":
			set_ai_sub("idle",{})
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
	pass

func on_tar_die():
	pass

func check_tar_die():
	if is_instance_valid(ai_battle_target) and ai_battle_target.b_dead==false:
		return false
	else:
		on_tar_die()
		return true

func get_damage(tar):
	var chance =Global.rng.randf_range(0,1)
	var b_crit=false
	if chance<=crit:
		b_crit=true
	var b_miss=false
	if b_crit==false:
		if tar.flee-hit>=100:
			b_miss=true
		elif hit - tar.flee>=100:
			b_miss=false
		else:
			chance =Global.rng.randf_range(0,1)
			if chance<(hit - tar.flee)/100.0:
				b_miss=false
	if b_miss:
		return 0
	var dmg=max_atk
	if b_crit==false:
		chance =Global.rng.randf_range(0,1)
		dmg = (max_atk-min_atk)*chance+min_atk
		dmg=dmg*(1-tar.rate_def)
		dmg=dmg-tar.add_def
	if dmg<0:
		dmg=0
	dmg=int(dmg)
	return dmg

func _physics_process(delta):
	var cur_time=OS.get_ticks_msec()
	if cur_path.size()>0:
		if path_index<cur_path.size():
			var dir=cur_path[path_index]-global_transform.origin
			if dir.length()<0.3:
				last_action_time=cur_time
				path_index=path_index+1
			else:
				var dir_n=dir.normalized()
				var dir_angle=atan2(dir_n.x,dir_n.z)+PI
				model.rotation.y=dir_angle
				global_transform.origin=global_transform.origin+dir_n*delta*mov_spd
		else:
			cur_path=[]
			path_index=-1
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
						last_action_time=cur_time
						rpc("trigger_anima_atk")
						var dmg=get_damage(ai_battle_target)
						ai_battle_target.on_damaged(dmg, self)    
		if ai_scheme=="battle":
			if check_tar_die()==false:
				var dist=(ai_battle_target.global_transform.origin-global_transform.origin).length()
				if dist<atk_range:
					if ai_sub_status!="atk":
						set_ai_sub("atk", {"atk_tar":ai_battle_target})
				elif dist>5:
					on_target_out()
				else:
					if cur_time-last_path_find_time>path_update_t:
						last_path_find_time=cur_time
						set_ai_sub("mov", {"mov_posi":ai_battle_target.global_transform.origin})
		last_ai_time=cur_time

func on_target_out():
	pass

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
