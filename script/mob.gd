extends BaseChara

var atk_type="assist" # passive assist active 
var mob_name=""
var spwan_area=""
var last_enemy_search_time=0
var enemy_search_period=2000
var enemy_search_range=2
var randwalk_idle_time=1000

func on_die(killer):
	killer.add_exp(int(Global.mob_infos[mob_name]["mob_exp"]*killer.exp_rate))
	.on_die(killer)

func on_damaged(dmg, attacker):
	if atk_type =="passive" and ai_scheme=="rand_walk":
		set_ai_scheme("battle",{"battle_tar":attacker})
	if atk_type =="active":
		if ai_battle_target!=attacker:
			set_ai_scheme("battle",{"battle_tar":attacker})
	if atk_type =="assist":
		if ai_battle_target!=attacker:
			set_ai_scheme("battle",{"battle_tar":attacker})
		for obj in world.mobs.get_children():
			if obj.ai_battle_target==null and obj.mob_name==mob_name:
				var dist=(obj.global_transform.origin-global_transform.origin).length()
				if dist<10:
					obj.set_ai_scheme("battle",{"battle_tar":attacker})
	.on_damaged(dmg, attacker)

func init_unit_data():
	var info=Global.mob_infos[mob_name]
	max_hp=info["max_hp"]
	lv=info["lv"]
	atk_range=info["atk_range"]
	atk_spd=info["atk_spd"]
	min_atk=info["min_atk"]
	max_atk=info["max_atk"]
	add_def=info["add_def"]
	rate_def=info["rate_def"]
	m_atk=info["m_atk"]
	m_def=info["m_def"]
	flee=info["flee"]
	hit=info["hit"]
	crit=info["crit"]
	mov_spd=info["mov_spd"]
	atk_type=info["atk_type"]

func _physics_process(delta):
	if get_tree().is_network_server():
		var cur_time=OS.get_ticks_msec()
		if atk_type=="active" and ai_scheme=="rand_walk":
			if last_enemy_search_time==0:
				last_enemy_search_time=cur_time
			if cur_time-last_enemy_search_time>enemy_search_period:
				last_enemy_search_time=cur_time
				var p = world.find_near_players(global_transform.origin, enemy_search_range)
				if p!=null:
					set_ai_scheme("battle",{"battle_tar":p})
		if ai_scheme=="rand_walk":
			if ai_sub_status=="idle":
				if cur_time-last_idle_time>randwalk_idle_time:
					last_idle_time=cur_time
					var chance =Global.rng.randf_range(0,1)
					if chance>0.5:
						var posi = world.get_rand_free_spot_by_name(mob_name)
						set_ai_sub("mov", {"mov_posi":posi})


remote func trigger_loss_hp(dmg, new_hp):
	if get_tree().is_network_server()==false:
		.trigger_loss_hp(dmg, new_hp)
		get_node(char_ui_path).toggle_hpbar(true)
		update_hp_bar()

func _ready():
	set_ai_scheme("rand_walk",{})
	get_node(char_ui_path).toggle_hpbar(false)
	get_node(char_ui_path).set_name(mob_name)

func on_tar_die():
	set_ai_scheme("rand_walk",{})

func on_move_end():
	if ai_scheme=="rand_walk":
		set_ai_sub("idle",{})
		last_idle_time=OS.get_ticks_msec()
	.on_move_end()

func set_ai_scheme(scheme_name, info):
	if get_tree().is_network_server():
		if scheme_name=="rand_walk":
			set_ai_sub("idle",{})
			last_idle_time=OS.get_ticks_msec()
		.set_ai_scheme(scheme_name, info)

func on_target_out():
	set_ai_scheme("rand_walk",{})
