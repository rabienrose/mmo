extends KinematicBody

class_name BaseChara

export (NodePath) var ground_ray_cast_path
export (NodePath) var model_path
export (NodePath) var anim_tree_path
var ground_ray_cast
var world
var model

var ai_base_status="idle"
var ai_scheme="idle"
var ai_battle_target=null
var cur_path=[]
var path_index=-1 

var max_hp
var max_sp
var hp=100
var sp=10
var lv=1
var exp_a=1
var str_a=5
var vit=5
var agi=5
var int_a=5
var dex=5
var luk=5
var nickname=""
var atk_range=1
var atk_spd=1
var atk
var def
var m_atk
var m_def
var flee
var hit
var crit
var mov_spd=1
var b_dead=false

var last_idle_time
var last_atk_time
var last_ai_time
var last_path_find_time
var ai_update_t=200
var path_update_t=1000
var idle_time=2000

func on_create(_world):
    world=_world

func cal_attr():
    pass

func set_ground_position(posi_ground):
    global_transform.origin=posi_ground
    ground_ray_cast.force_raycast_update()
    if ground_ray_cast.is_colliding():
        var ground_point=ground_ray_cast.get_collision_point()
        global_transform.origin.y=ground_point.y

func on_damaged():
    pass

remote func request_battle(tar_name):
    var tar_obj=null
    if is_in_group("Mob"):
        tar_obj=world.get_player_by_name(tar_name)
    if is_in_group("Player"):
        tar_obj=world.get_mob_by_name(tar_name)
    if tar_obj!=null:
        start_battle(tar_obj)
    else:
        print("error: no battle target")

func start_battle(target):
    ai_scheme="battle"
    ai_battle_target=target

remotesync func start_move(path_node, path_ind=0):
    path_index=path_ind
    cur_path=path_node
    set_anima_walk()
    if get_tree().is_network_server():
        ai_base_status="move"

remote func request_move_to(ground_posi):
    var t_path = world.get_navi_path(global_transform.origin, ground_posi)
    rpc("start_move", t_path)

remote func set_anima_idle():
    if get_tree().is_network_server()==false:
        get_node(anim_tree_path).set("parameters/WalkIdle/current",1)

remote func set_anima_walk():
    if get_tree().is_network_server()==false:
        get_node(anim_tree_path).set("parameters/WalkIdle/current",0)

remote func trigger_anima_atk():
    if get_tree().is_network_server()==false:
        get_node(anim_tree_path).set("parameters/AttackOn/active",true)

func set_idle():
    if get_tree().is_network_server():
        ai_base_status="idle"
        last_idle_time=OS.get_ticks_msec()

func on_move_end():
    if ai_scheme=="battle":
        pass
    elif ai_scheme=="rand_walk":
        set_idle()
        rpc("set_anima_idle")
    elif ai_scheme=="escape":
        pass

func on_idle_end():
    if ai_scheme=="rand_walk":
        var chance =Global.rng.randf_range(0,1)
        if chance>0.5:
            var posi = world.get_rand_free_spot()
            request_move_to(posi)

func _physics_process(delta):
    if cur_path.size()>0:
        if path_index<cur_path.size():
            var dir=cur_path[path_index]-global_transform.origin
            dir.y=0
            if dir.length()<0.3:
                path_index=path_index+1
            else:
                var dir_n=dir.normalized()
                var dir_angle=atan2(dir_n.x,dir_n.z)+PI
                model.rotation.y=dir_angle
                global_transform.origin=global_transform.origin+dir_n*delta*mov_spd
                ground_ray_cast.force_raycast_update()
                if ground_ray_cast.is_colliding():
                    var ground_point=ground_ray_cast.get_collision_point()
                    global_transform.origin.y=ground_point.y
        else:
            cur_path=[]
            path_index=-1
    var cur_time=OS.get_ticks_msec()
    if get_tree().is_network_server() and cur_time-last_ai_time>ai_update_t:
        last_ai_time=cur_time
        if ai_base_status=="move":
            if cur_path.size()==0:
                on_move_end()
        elif ai_base_status=="atk":
            if cur_time-last_atk_time>1.0/atk_spd*1000:
                if ai_battle_target.b_dead==false:
                    var dist=(ai_battle_target.global_transform.origin-global_transform.origin).length()
                    if dist<atk_range:
                        rpc("trigger_anima_atk")
                        ai_battle_target.on_damaged()    
        elif ai_base_status=="idle":
            if cur_time-last_idle_time>idle_time:
                on_idle_end()
        if ai_scheme=="battle":
            var dist=(ai_battle_target.global_transform.origin-global_transform.origin).length()
            if dist<atk_range:
                if ai_base_status!="atk":
                    ai_base_status="atk"
            else:
                if cur_time-last_path_find_time>path_update_t:
                    last_path_find_time=cur_time
                    request_move_to(ai_battle_target.global_transform.origin)

func _ready():
    ground_ray_cast=get_node(ground_ray_cast_path)
    model=get_node(model_path)
    last_atk_time=OS.get_ticks_msec()
    last_ai_time=last_atk_time
    last_path_find_time=last_atk_time
    last_idle_time=last_atk_time
