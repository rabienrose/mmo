extends KinematicBody

class_name BaseChara

var ai_status="idle"
var ai_proc_step=30
var ai_proc_count=0

var world
var mov_spd=0.01

var cur_path=[]
var path_index=-1 

export (NodePath) var ground_ray_cast_path
export (NodePath) var model_path
export (NodePath) var anim_tree_path

var model

var ground_ray_cast

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

var atk
var def
var m_atk
var m_def
var flee
var hit
var crit

func on_create(_world):
    world=_world

remotesync func on_damaged(path_node):
    pass

remotesync func on_dead(path_node):
    pass

remotesync func attack(path_node):
    pass

func cal_attr():
    pass

remotesync func on_move_to(path_node, path_ind=0):
    path_index=path_ind
    cur_path=path_node
    set_anima_walk()

remote func request_move_to(ground_posi):
    var t_path = world.get_navi_path(global_transform.origin, ground_posi)
    rpc("on_move_to", t_path)

func set_ground_position(posi_ground):
    global_transform.origin=posi_ground
    ground_ray_cast.force_raycast_update()
    if ground_ray_cast.is_colliding():
        var ground_point=ground_ray_cast.get_collision_point()
        global_transform.origin.y=ground_point.y

func set_anima_idle():
    if get_tree().is_network_server()==false:
        get_node(anim_tree_path).set("parameters/WalkIdle/current",1)

func set_anima_walk():
    if get_tree().is_network_server()==false:
        get_node(anim_tree_path).set("parameters/WalkIdle/current",0)

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
                global_transform.origin=global_transform.origin+dir_n*mov_spd
                ground_ray_cast.force_raycast_update()
                if ground_ray_cast.is_colliding():
                    var ground_point=ground_ray_cast.get_collision_point()
                    global_transform.origin.y=ground_point.y
        else:
            set_anima_idle()
            cur_path=[]
            path_index=-1
            

func _ready():
    ground_ray_cast=get_node(ground_ray_cast_path)
    model=get_node(model_path)

