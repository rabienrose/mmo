extends Node

var is_server=false
var SERVER_PORT=8000
var MAX_PLAYERS=20
var SERVER_IP="127.0.0.1"

var token=""

var device_id_path="user://device.txt"
var token_path="user://token.txt"
var server_data_path="user://data.txt"

var config_folder="config"

var device_id

var server_data={}
var mob_infos={}
var level_info={}

var server_save_period=10

var init_player_attr={
    "str":5,
    "vit":10,
    "agi":1,
    "int":1,
    "dex":1,
    "luk":1,
    "mov_spd":2.0,
    "lv":1,
    "exp":0,
    "remain_points":10
}

var attr_type={
    "str":"int",
    "vit":"int",
    "agi":"int",
    "int":"int",
    "dex":"int",
    "luk":"int",
    "mov_spd":"float",
    "mob_exp":"int",
    "lv":"int",
    "min_atk":"int",
    "max_atk":"int",
    "max_hp":"int",
    "flee":"int",
    "hit":"int",
    "atk_range":"float",
    "atk_spd":"float",
    "crit":"float",
    "rate_def":"float",
    "add_def":"int",
    "m_def":"float",
    "m_atk":"int",
    "atk_type":"str",
    "spwan_area":"str",
    "num":"int",
    "walk_range":"int",
    "res_name":"str",
}

var rng = RandomNumberGenerator.new()

func load_level_infos():
    var f=File.new()
    var info_file=config_folder+"/level.dat"
    if f.file_exists(info_file):
        f.open(info_file, File.READ)
        var line_text=f.get_line()
        var first_line=true
        while line_text!="":
            if first_line:
                first_line=false
                line_text=f.get_line()
                continue
            var splited_line=line_text.split(",")
            var lv=int(splited_line[0])
            var lv_exp=int(splited_line[1])
            level_info[lv]={"exp":lv_exp}
            line_text=f.get_line()

func load_mob_infos():
    var f=File.new()
    var mobs_info_file=config_folder+"/mobs.dat"
    if f.file_exists(mobs_info_file):
        f.open(mobs_info_file, File.READ)
        var line_text=f.get_line()
        var header=line_text.split(",")
        var first_line=true
        
        while line_text!="":
            if first_line:
                first_line=false
                line_text=f.get_line()
                continue
            var splited_line=line_text.split(",")
            var mob_name=splited_line[0]
            var mob_info={}
            for i in range(1, len(header)):
                var val=splited_line[i]
                if attr_type[header[i]]=="int":
                    val=int(val)
                if attr_type[header[i]]=="float":
                    val=float(val)
                mob_info[header[i]]=val
            line_text=f.get_line()
            mob_infos[mob_name]=mob_info

func _ready():
    #rng.randomize()
    var args = OS.get_cmdline_args() 
    load_mob_infos()
    load_level_infos()
    if args.size()>=1 and args[0]=="server":
        is_server=true
    if args.size()>=1 and args[0]=="client":
        token=args[1]

func check_token():
    if token!="":
        return true
    var f=File.new()
    if f.file_exists(token_path):
        f.open(token_path, File.READ)
        var content = f.get_as_text()
        token=content
        f.close()
        return true
    else:
        return false

func store_token():
    var f=File.new()
    f.open(token_path, File.WRITE)
    f.store_string(token)
    f.close()

func v3_2_list(p):
    return [p.x, p.y, p.z]

func list_2_v3(p):
    return Vector3(p[0], p[1], p[2])
