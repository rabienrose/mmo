extends Spatial

export (Resource) var player_res
export (Resource) var mob_res

export (NodePath) var players_path
export (NodePath) var mobs_path
export (NodePath) var navigate_path
export (NodePath) var login_ui_path
export (NodePath) var spwan_pos_path
export (NodePath) var mob_zone_path

var players
var mobs
var navi
var max_mob_id=0

func get_player_born_posi():
    return get_node(spwan_pos_path).global_transform.origin

func get_init_player_info():
    var player_t = player_res.instance()
    player_t.init_player_data()
    return player_t.get_player_info()

func show_login_ui():
    pass

func get_navi_path(from, to):
    var path = navi.get_simple_path(from, to)
    for i in range(path.size()):
        path[i].y=path[i].y-0.2
    return path

func update_player_server_data():
    for player in players.get_children():
        Global.server_data["user"][player.account]["player_info"]=player.get_player_info()

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
    var posi_t = navi.get_closest_point(raw_posi)
    return posi_t

func init_mobs():
    for i in range(0,5):
        var mob=mob_res.instance()
        mob.name="mob_"+str(max_mob_id)
        max_mob_id=max_mob_id+1
        get_node(mobs_path).add_child(mob)
        mob.on_create(self)
        var r_posi=get_rand_free_spot()
        mob.set_ground_position(r_posi)

func _ready():
    navi=get_node(navigate_path)
    players=get_node(players_path)
    mobs=get_node(mobs_path)
    if Global.is_server:
        load_server_data()
        init_mobs()

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

remotesync func spawn_mobs(mob_info):
    pass

func get_mobs_info():
    var mob_list=[]
    for mob in mobs.get_children():
        var mob_info={}
        mob_info["name"]=mob.name
        mob_info["cur_path"]=seri_cur_path(mob.cur_path)
        mob_info["path_index"]=mob.path_index
        mob_info["posi"]=mob.global_transform.origin
        mob_list.append(mob_info)
    return mob_list

remotesync func spawn_player(player_info):
    var player = player_res.instance()
    player.on_create(self)
    players.add_child(player)
    player.name=str(player_info["peer_id"])
    player.set_network_master(player_info["peer_id"])
    var peer_id = get_tree().get_network_unique_id()
    if player_info["peer_id"]==peer_id:
        player.set_master(true)
    else:
        player.set_master(false)
    player.set_ground_position(player_info["cur_posi"])

remote func sync_mob_and_player(mob_player_list):
    var mob_list=mob_player_list["mobs"]
    for mob_info in mob_list:
        var mob=mob_res.instance()
        mob.name=mob_info["name"]
        mob.on_create(self)
        get_node(mobs_path).add_child(mob)
        mob.start_move(deseri_cur_path(mob_info["cur_path"]),mob_info["path_index"])
        mob.set_ground_position(Global.list_2_v3(mob_info["posi"]))

remote func on_user_enter_done():
    get_node(login_ui_path).visible=false
    

