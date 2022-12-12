extends Spatial

export (Resource) var player_res
export (Resource) var mob_res

export (NodePath) var players_path
export (NodePath) var mobs_path
export (NodePath) var login_ui_path
export (NodePath) var spwan_pos_path
export (NodePath) var mob_zone_path
export (NodePath) var navi_inst_path
export (NodePath) var network_path

var players
var mobs
var max_mob_id=0
var map_rid
var b_first=true

func get_player_born_posi():
	return get_node(spwan_pos_path).global_transform.origin

func show_login_ui():
	pass

func update_player_server_data():
	for player in players.get_children():
		var info=player.get_unit_info()
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

func get_rand_free_spot():
	var zone_center=get_node(mob_zone_path).global_transform.origin
	var zone_r=5
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

func create_more_mobs():
	var mob_name="mob1"
	for i in range(0,1):
		var r_posi=get_rand_free_spot()
		rpc("spawn_mob",mob_name, r_posi,"mob_"+str(max_mob_id),{})
		max_mob_id=max_mob_id+1
		
func _ready():
	players=get_node(players_path)
	mobs=get_node(mobs_path)
	if Global.is_server:
		load_server_data()
		
func _process(delta):
	if b_first==true:
		b_first=false
		map_rid=get_world().navigation_map
		if Global.is_server:
			create_more_mobs()

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
		player.set_base_attr_by_info(player_info)
		player.set_player_attr(player_info)
		player.cal_attr()
		player.set_hp_by_info(player_info)
	player.account=player_info["account"]
	if player_info["peer_id"]==peer_id:
		player.set_master(true)
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


