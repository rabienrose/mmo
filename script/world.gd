extends Spatial

export (Resource) var player_res

export (NodePath) var players_path
export (NodePath) var mobs_path
export (NodePath) var login_ui_path
export (NodePath) var spwan_pos_path
export (NodePath) var mob_zone_path
export (NodePath) var navi_inst_path
export (NodePath) var network_path
export (NodePath) var ui_main_path

var ui_main
var players
var mobs
var max_mob_id=0
var map_rid
var b_first=true
var me
var network

var mob_refresh_period=10000
var last_mob_refresh_time=0

func get_player_born_posi():
	return get_node(spwan_pos_path).global_transform.origin

func show_login_ui():
	pass

func update_player_server_data():
	for player in players.get_children():
		var info=player.get_player_info()
		Global.server_data["user"][player.account]["player_info"]=info

func load_server_data():
	var f=File.new()
	if f.file_exists(Global.server_data_path):
		f.open(Global.server_data_path, File.READ)
		var content = f.get_as_text()
		var result = JSON.parse(content)
		Global.server_data=result.result
		f.close()
	else:
		Global.server_data={}
		Global.server_data["user"]={}

func get_rand_free_spot_by_name(mob_name):
	var mob_zone_name=Global.mob_infos[mob_name]["spwan_area"]
	var mob_walk_range=Global.mob_infos[mob_name]["walk_range"]
	return get_rand_free_spot(mob_zone_name, mob_walk_range)

func get_rand_free_spot(mob_zone_name, walk_range):
	var zone_center=get_node(str(mob_zone_path)+"/"+mob_zone_name).global_transform.origin
	var zone_r=walk_range
	var r_x = Global.rng.randf_range(-zone_r,zone_r)
	var r_z = Global.rng.randf_range(-zone_r,zone_r)
	var raw_posi=Vector3(zone_center.x+r_x, zone_center.y, zone_center.z+r_z)
	var fix_pos= NavigationServer.map_get_closest_point(map_rid, raw_posi)
	return fix_pos

func get_navi_path(from, to):
	var path = NavigationServer.map_get_path(map_rid,from, to, true)
	# for i in range(path.size()):
	# 	path[i].y=path[i].y-0.2
	return path

remotesync func spawn_mob(mob_name, posi, object_name, info):
	var res_path="res://objects/mobs/"+Global.mob_infos[mob_name]["res_name"]+".tscn"
	var mob_res=load(res_path)	
	var mob=mob_res.instance()
	mob.mob_name=mob_name
	mob.name=object_name
	get_node(mobs_path).add_child(mob)
	mob.on_create(self)
	mob.set_ground_position(posi)
	mob.init_unit_data()
	mob.set_hp_by_info(info)
	return mob

func network_destroy_unit(unit):
	unit.rpc("destroy_self") 

func refresh_mobs():
	var mob_summary={}
	for obj in mobs.get_children():
		if obj.mob_name in mob_summary:
			mob_summary[obj.mob_name]=mob_summary[obj.mob_name]+1
		else:
			mob_summary[obj.mob_name]=1
	
	for mob_name in Global.mob_infos:
		var mob_exp_num=Global.mob_infos[mob_name]["num"]
		
		var new_count=0
		if not mob_name in mob_summary:
			new_count=mob_exp_num
		elif mob_name in mob_summary:
			new_count=mob_exp_num-mob_summary[mob_name]
		if new_count>0:
			for _i in range(new_count):
				var r_posi=get_rand_free_spot_by_name(mob_name)
				rpc("spawn_mob",mob_name, r_posi,"mob_"+str(max_mob_id),{})
				max_mob_id=max_mob_id+1
		
func _ready():
	players=get_node(players_path)
	mobs=get_node(mobs_path)
	ui_main=get_node(ui_main_path)
	network=get_node(network_path)
	if Global.is_server:
		load_server_data()
		
func _process(delta):
	if Global.is_server:
		var cur_time=OS.get_ticks_msec()
		if b_first==true:
			b_first=false
			map_rid=get_world().navigation_map
			last_mob_refresh_time=cur_time
			refresh_mobs()
		if cur_time-last_mob_refresh_time>mob_refresh_period:
			last_mob_refresh_time=cur_time
			refresh_mobs()
	

func seri_cur_path(path_info):
	var path_seri=[]
	for item in path_info:
		path_seri.append([item.x,item.y,item.z])
	return path_seri

func deseri_cur_path(path_seri):
	var cur_path=[]
	for item in path_seri:
		cur_path.append(Vector3(item[0],item[1],item[2]))
	return cur_path

func get_mob_by_name(query_name):
	for obj in mobs.get_children():
		if obj.name==query_name:
			return obj
	return null

func get_player_by_name(query_name):
	for obj in players.get_children():
		if obj.name==query_name:
			return obj
	return null

func get_non_master_players_info(master_player_peer_id):
	var player_list=[]
	for player in players.get_children():
		if player.name!=str(master_player_peer_id):
			var info={}
			info["account"]=player.account
			info["peer_id"]=int(player.name)
			info["cur_posi"]=player.global_transform.origin
			player_list.append(info)
	return player_list

func get_mobs_info():
	var mob_list=[]
	for mob in mobs.get_children():
		var mob_info={}
		mob_info["mob_name"]=mob.mob_name
		mob_info["cur_path"]=seri_cur_path(mob.cur_path)
		mob_info["path_index"]=mob.path_index
		mob_info["posi"]=mob.global_transform.origin
		mob_info["object_name"]=mob.name
		mob_info["hp"]=mob.hp
		mob_list.append(mob_info)
	return mob_list

remotesync func spawn_player(player_info):
	var player = player_res.instance()
	player.on_create(self)
	players.add_child(player)
	player.name=str(player_info["peer_id"])
	player.set_network_master(player_info["peer_id"])
	var peer_id = get_tree().get_network_unique_id()
	player.set_ground_position(player_info["cur_posi"])
	if get_tree().is_network_server() or player_info["peer_id"]==peer_id:
		player.set_player_attr(player_info)
		player.set_hp_by_info(player_info)
	player.account=player_info["account"]
	if player_info["peer_id"]==peer_id:
		player.set_master(true)
		me=player
		ui_main.refresh_main()
		ui_main.refresh_char_ui()
	else:
		player.set_master(false)

remote func sync_mob_and_player(mob_player_list):
	var mob_list=mob_player_list["mobs"]
	for mob_info in mob_list:
		var new_mob = spawn_mob(mob_info["mob_name"], mob_info["posi"], mob_info["object_name"], mob_info)
		new_mob.start_move(deseri_cur_path(mob_info["cur_path"]),new_mob.mov_spd,mob_info["path_index"])
	var player_list=mob_player_list["players"]
	for player_info in player_list:
		spawn_player(player_info)

remote func on_user_enter_done(player_info):
	spawn_player(player_info)
	get_node(login_ui_path).visible=false

func find_near_players(posi, max_dist):
	var min_dist=-1
	var min_player=null
	for obj in players.get_children():
		var dist=(obj.global_transform.origin-posi).length()
		if dist<max_dist:
			if min_player==null or min_dist>dist:
				min_dist=dist
				min_player=obj
	return min_player

func clear_mob_target(target):
	for obj in mobs.get_children():
		if obj.ai_battle_target==target:
			obj.on_tar_die()
	


