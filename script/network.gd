extends Node

export (NodePath) var login_ui_path
export (NodePath) var world_path

var peerid_user_table={}
var user_peerid_table={}

func _ready():
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
    print("player disconnect: ", id)
    if id in peerid_user_table:
        var token=peerid_user_table[id]
        peerid_user_table.erase(id)
        user_peerid_table.erase(token)

func _connected_ok():
    if Global.check_token():
        rpc_id(1,"on_user_enter",Global.token)
    else:
        get_node(login_ui_path).show_login_box(true)

func _server_disconnected():
    print("_server_disconnected")

func _connected_fail():
    print("_connected_fail")

remote func on_user_enter(token):
    var user_list=Global.server_data["user"]
    if token in user_list:
        var user_data=user_list[token]
        var sender_id = get_tree().get_rpc_sender_id()
        if token in user_peerid_table:
            return
        peerid_user_table[sender_id]=token
        user_peerid_table[token]=[sender_id]
        var player_info={}
        if not "player_info" in user_data:
            player_info=get_node(world_path).get_init_player_info()
            player_info["cur_posi"]=get_node(world_path).get_player_born_posi()
            player_info["nickname"]=token
        else:
            player_info=user_data["player_info"]
            player_info["cur_posi"]=Global.list_2_v3(player_info["cur_posi"])
        player_info["peer_id"]=sender_id
        get_node(world_path).rpc("spawn_player",player_info)
        get_node(world_path).rpc_id(sender_id, "on_user_enter_done")
        var mobs=get_node(world_path).get_mobs_info()
        get_node(world_path).rpc_id(sender_id, "sync_mob_and_player",{"mobs":mobs})

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
    var f=File.new()
    f.open(Global.server_data_path, File.WRITE)
    var data_str=JSON.print(Global.server_data)
    f.store_string(data_str)
    f.close()

remote func regist(account, pw):
    var sender_id = get_tree().get_rpc_sender_id()
    if account in Global.server_data["user"]:
        get_node(login_ui_path).rpc_id(sender_id, "regist_result", {"code":"account_exist"})
    else:
        update_user_info(account, pw)
        get_node(world_path).update_player_server_data()
        save_server_data_2_file()
        get_node(login_ui_path).rpc_id(sender_id, "regist_result", {"code":"ok","data":{"account":account}})