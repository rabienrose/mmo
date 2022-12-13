extends BaseChara


export (NodePath) var cam_platform_path
export (NodePath) var cam_path
export (Resource) var mouse_icon_normal
export (Resource) var mouse_icon_atk

var state_space
var cam_platform
var cam

var sp=10
var exp_a=1
var str_a=5
var vit=100
var agi=1
var int_a=5
var dex=5
var luk=5

var exp_rate=1
var remain_points=0
var level_point=10
var auto_recover_hp=30

var auto_recover_period=5000
var last_auto_recover_time=0

var hori_rot_spd=0.005
var veri_rot_spd=0.005
var zoom_spd=0.9
var pressed=false
var b_drag=false
var b_master=false
var account=""

var mouse_status="normal"

func cal_attr_by_input(_str, _vit, _agi, _dex, _int, _luk):
	var info={}
	info["crit"]=_luk/1000.0
	info["hit"]=_dex
	info["flee"]=_agi
	info["max_atk"]=_str*3
	info["min_atk"]=_dex*2
	info["atk_spd"]=2-_agi/100
	info["max_hp"]=_vit*10
	info["m_atk"]=0
	info["m_def"]=0
	info["add_def"]=_vit
	info["rate_def"]=0
	info["exp_rate"]=pow(1.01,_int) 
	return info

func cal_attr():
	var info = cal_attr_by_input(str_a, vit, agi, dex, int_a, luk)
	crit=info["crit"]
	hit=info["hit"]
	flee=info["flee"]
	max_atk=info["max_atk"]
	min_atk=info["min_atk"]
	atk_spd=info["atk_spd"]
	max_hp=info["max_hp"]
	m_atk=info["m_atk"]
	m_def=info["m_def"]
	add_def=info["add_def"]
	rate_def=info["rate_def"]
	exp_rate=info["exp_rate"]

func add_exp(exp_add):
	exp_a=exp_a+exp_add
	var lv_exp=Global.level_info[lv]["exp"]
	if exp_a>=lv_exp:
		lv=lv+1
		remain_points=remain_points+level_point
		rpc_id(int(name),"show_level_up",lv,exp_a-lv_exp,remain_points)
	else:
		rpc_id(int(name),"show_exp_add",exp_add,exp_a)

remote func show_exp_add(exp_add, new_exp):
	exp_a=new_exp
	world.ui_main.refresh_main()

remote func show_level_up(new_lv, new_exp, remain_points):
	lv=new_lv
	exp_a=new_exp
	world.ui_main.refresh_main()

func reset_player():
	rpc("set_hp", 10)

func on_die(killer):
	world.clear_mob_target(self)
	rpc("teleport", world.get_player_born_posi())
	reset_player()
	#.on_die(killer)

func get_player_info():
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
	info["remain_points"]=remain_points
	if is_inside_tree():
		info["cur_posi"]=Global.v3_2_list(global_transform.origin)
	else:
		info["cur_posi"]=[0,0,0]
	info["account"]=account
	return info

func set_master(b_true):
	b_master=b_true
	get_node(cam_path).current=b_master
	if b_true:
		get_node(char_ui_path).toggle_hpbar(true)
		get_node(char_ui_path).update_hp_bar(hp, max_hp)
	else:
		get_node(char_ui_path).toggle_hpbar(false)
	get_node(char_ui_path).set_name(account)

func get_point_mob(screen_pos):
	var from = cam.project_ray_origin(screen_pos)
	var to= from +cam.project_ray_normal(screen_pos)*1000
	var result = state_space.intersect_ray(from, to,[],8)
	if result.size()!=0:
		return result.collider
	else:
		return null

func get_ground_posi(screen_pos):
	var from = cam.project_ray_origin(screen_pos)
	var to= from +cam.project_ray_normal(screen_pos)*1000
	var result = state_space.intersect_ray(from, to,[],4)
	if result.size()!=0:
		return result.position
	else:
		return null

func _input(event):
	if b_master==false:
		return
	if event is InputEventMouseMotion:
		var collider = get_point_mob(event.position)
		if collider!=null and collider.is_in_group("Mob"):
			if mouse_status!="atk":
				Input.set_custom_mouse_cursor(mouse_icon_atk)
				mouse_status="atk"
		else:
			if mouse_status!="normal":
				Input.set_custom_mouse_cursor(mouse_icon_normal)
				mouse_status="normal"
		if pressed:
			if event.relative.length()>10:
				b_drag=true
			cam_platform.rotation.y=cam_platform.rotation.y-event.relative.x*hori_rot_spd
			if cam_platform.rotation.y>PI:
				cam_platform.rotation.y=cam_platform.rotation.y-2*PI
			elif cam_platform.rotation.y<-PI:
				cam_platform.rotation.y=cam_platform.rotation.y+2*PI
			cam_platform.rotation.x=cam_platform.rotation.x-event.relative.y*veri_rot_spd
			if cam_platform.rotation.x>-PI/9:
				cam_platform.rotation.x=-PI/9
			elif cam_platform.rotation.x<-PI/2:
				cam_platform.rotation.x=-PI/2
			
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			pressed=event.is_pressed()
			if pressed:
				b_drag=false
			if pressed==false:
				if b_drag==false:
					var collider = get_point_mob(event.position)
					if collider!=null:
						rpc_id(1, "request_battle", collider.name)
					else:
						var posi_ground = get_ground_posi(event.position)
						if posi_ground!= null:
							rpc_id(1, "request_move_to", posi_ground)
				b_drag=false

		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				cam.translation.z=cam.translation.z*zoom_spd
				if cam.translation.z<1:
					cam.translation.z=1
			if event.button_index == BUTTON_WHEEL_DOWN:
				cam.translation.z=cam.translation.z/zoom_spd
				if cam.translation.z>5:
					cam.translation.z=5

func _ready():
	state_space=get_world().direct_space_state
	cam_platform=get_node(cam_platform_path)
	cam=get_node(cam_path)
	set_ai_scheme("stand",{})

func set_player_attr(info):
	lv=int(info["lv"])
	exp_a=info["exp"]
	str_a=info["str"]
	vit=info["vit"]
	agi=info["agi"]
	int_a=info["int"]
	dex=info["dex"]
	luk=info["luk"]
	mov_spd=info["mov_spd"]
	remain_points=info["remain_points"]
	set_hp_by_info(info)
	cal_attr()

func on_tar_die():
	set_ai_scheme("stand",{})

remote func trigger_loss_hp(dmg, new_hp):
	if get_tree().is_network_server()==false:
		if world.me==self:
			.trigger_loss_hp(dmg, new_hp)
			get_node(char_ui_path).toggle_hpbar(true)
			update_hp_bar()
			world.ui_main.refresh_main()

func _physics_process(delta):
	if get_tree().is_network_server():
		var cur_time=OS.get_ticks_msec()
		if last_auto_recover_time==0:
			last_auto_recover_time=cur_time
		if cur_time-last_auto_recover_time>auto_recover_period and cur_time-last_action_time>auto_recover_period:
			last_auto_recover_time=cur_time
			rpc("recover_hp",auto_recover_hp)

func on_target_out():
	set_ai_scheme("stand",{})

func on_move_end():
	if ai_scheme=="walk":
		set_ai_scheme("stand",{})
	.on_move_end()

remote func request_move_to(posi):
	set_ai_scheme("walk",{"mov_posi":posi})

func set_ai_scheme(scheme_name, info):
	if get_tree().is_network_server():
		if scheme_name=="walk":
			ai_battle_target=null
			set_ai_sub("mov", info)
		.set_ai_scheme(scheme_name, info)
