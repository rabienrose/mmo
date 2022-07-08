extends Node

var is_server=false
var SERVER_PORT=8000
var MAX_PLAYERS=20
var SERVER_IP="127.0.0.1"

var token=""

var device_id_path="user://device.txt"
var token_path="user://token.txt"
var server_data_path="user://data.txt"

var device_id

var server_data={}

var rng = RandomNumberGenerator.new()


func _ready():
    #rng.randomize()
    var args = OS.get_cmdline_args() 
    if args.size()>=1 and args[0]=="server":
        is_server=true

func check_token():
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
