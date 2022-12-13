extends Node

export (NodePath) var login_ui_path
export (NodePath) var world_path

var world

var peerid_user_table={}
var user_peerid_table={}
var last_server_save_time=0

signal update_char_ui()

func _ready():
    world=get_node(world_path)
    if Global.is_server:
        print("as server")
        var peer = NetworkedMultiplayerENet.new()
        peer.create_server(Global.SERVER_PORT,Global.MAX_PLAYERS)
        get_tree().network_peer = peer
    else:
        print("as client")
        var peer = NetworkedMultiplayerENet.new()
        peer.create_client(Global.SERVER_IP, Global.SERVER_PORT)
        get_tree().network_peer = peer
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")
    
func _player_connected(id):
    print("player connect: ", id)

func _player_disconnected(id):
    if get_tree().is_network_server():
        print("player disconnect: ", id)
        if id in peerid_user_table:
            var player_obj = world.get_player_by_name(str(id))
            player_obj.rpc("destroy_self")
            var account=peerid_user_table[id]
            peerid_user_table.erase(id)
            user_peerid_table.erase(account)

func _connected_ok():
    if Global.check_token():
        rpc_id(1,"on_user_enter",Global.token)
    else:
        get_node(login_ui_path).show_login_box(true)

func _server_disconnected():
    print("_server_disconnected")

func _connected_fail():
    print("_connected_fail")

remote func ask_cliet_exit():
    print("server sak to exit")
    get_tree().network_peer.close_connection()

func get_player_by_sender():
    var p = world.get_player_by_name(str(get_tree().get_rpc_sender_id()))
    return p

remote func request_modify_player_attr(info):
    if get_tree().is_network_server()==true: 
        var reply_info={}
        var player = get_player_by_sender()
        var used_point=0
        for attr in info:
            used_point = used_point + info[attr]
        var temp_r_point=player.remain_points - used_point
        if  temp_r_point>=0:
            change_attr_by_request(player, info)
            player.remain_points=temp_r_point
            reply_info["msg"]="ok"
            reply_info["payload"]={"remain_points":player.remain_points}
            reply_info["payload"]["attr"]=info
        else:
            reply_info["msg"]="error"
        rpc_id(int(player.name), "reply_modify_player_attr",reply_info)

func change_attr_by_request(player, info):
    for attr in info:
        var val=info[attr]
        if attr=="str":
            player.str_a=player.str_a+val
        elif attr=="vit":
            player.vit=player.vit+val
        elif attr=="agi":
            player.agi=player.agi+val
        elif attr=="dex":
            player.dex=player.dex+val
        elif attr=="int":
            player.int_a=player.int_a+val
        elif attr=="luk":
            player.luk=player.luk+val

remote func reply_modify_player_attr(reply_info):
    if get_tree().is_network_server()==false: 
        if reply_info["msg"]=="ok":
            change_attr_by_request(world.me, reply_info["payload"]["attr"])
            world.me.remain_points=reply_info["payload"]["remain_points"]
            emit_signal("update_char_ui")

remote func on_user_enter(token):
    var user_list=Global.server_data["user"]
    var sender_id = get_tree().get_rpc_sender_id()
    if token in user_list:
        var user_data=user_list[token]
        if token in user_peerid_table:
            print("already online")
            rpc_id(sender_id, "ask_cliet_exit")
            return
        peerid_user_table[sender_id]=token
        user_peerid_table[token]=[sender_id]
        var player_info={}
        if not "player_info" in user_data:
            player_info=Global.init_player_attr
            player_info["cur_posi"]=world.get_player_born_posi()
            player_info["account"]=token
        else:
            player_info=user_data["player_info"]
            player_info["cur_posi"]=Global.list_2_v3(player_info["cur_posi"])
        player_info["peer_id"]=sender_id
        var non_master_info={}
        non_master_info["peer_id"]=player_info["peer_id"]
        non_master_info["account"]=player_info["account"]
        non_master_info["cur_posi"]=player_info["cur_posi"]
        for user_peer in peerid_user_table:
            if user_peer!=sender_id:
                world.rpc_id(user_peer, "spawn_player",non_master_info)
        world.spawn_player(player_info)
        world.rpc_id(sender_id, "on_user_enter_done", player_info)
        var players=world.get_non_master_players_info(sender_id)
        var mobs=world.get_mobs_info()
        world.rpc_id(sender_id, "sync_mob_and_player",{"mobs":mobs,"players":players})
    else:
        print("no account")
        rpc_id(sender_id, "ask_cliet_exit")
        return

remote func login(account, pw):
    var user_list=Global.server_data["user"]
    var sender_id = get_tree().get_rpc_sender_id()
    if account in user_list:
        if user_list[account]["pw"]==pw:
            get_node(login_ui_path).rpc_id(sender_id, "login_result", {"code":"ok","data":{"account":account}})
        else:
            get_node(login_ui_path).rpc_id(sender_id, "login_result", {"code":"pw_not_right"})
    else:
        get_node(login_ui_path).rpc_id(sender_id, "login_result", {"code":"account_not_exist"})

func update_user_info(account, pw):
    if account in Global.server_data["user"]:
        Global.server_data["user"][account]["pw"]=pw
    else:
        Global.server_data["user"][account]={"pw":pw}

func save_server_data_2_file():
    world.update_player_server_data()
    var f=File.new()
    f.open(Global.server_data_path, File.WRITE)
    var data_str=JSON.print(Global.server_data)
    f.store_string(data_str)
    f.close()
    print("server saved")

func check_connected():
    if get_tree().network_peer.get_connection_status()==NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
        return true
    else:
        return false

func _physics_process(delta):
    var cur_time=OS.get_ticks_msec()
    if check_connected() and  get_tree().is_network_server():
        if last_server_save_time==0:
            last_server_save_time=cur_time
        if cur_time-last_server_save_time>Global.server_save_period*1000:
            last_server_save_time=cur_time
            save_server_data_2_file()

remote func regist(account, pw):
    var sender_id = get_tree().get_rpc_sender_id()
    if account in Global.server_data["user"]:
        get_node(login_ui_path).rpc_id(sender_id, "regist_result", {"code":"account_exist"})
    else:
        update_user_info(account, pw)
        save_server_data_2_file()
        get_node(login_ui_path).rpc_id(sender_id, "regist_result", {"code":"ok","data":{"account":account}})
