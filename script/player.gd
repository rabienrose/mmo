extends BaseChara


export (NodePath) var cam_platform_path
export (NodePath) var cam_path
export (Resource) var mouse_icon_normal
export (Resource) var mouse_icon_atk

var state_space
var cam_platform
var cam

var hori_rot_spd=0.005
var veri_rot_spd=0.005
var zoom_spd=0.9
var pressed=false
var b_drag=false
var b_master=false
var account=""

var mouse_status="normal"

func get_player_info():
    var info={}
    info["hp"]=hp
    info["sp"]=sp
    info["lv"]=lv
    info["exp"]=exp_a
    info["str"]=str_a
    info["vit"]=vit
    info["agi"]=agi
    info["int"]=int_a
    info["dex"]=dex
    info["luk"]=luk
    info["nickname"]=nickname
    if is_inside_tree():
        info["cur_posi"]=Global.v3_2_list(global_transform.origin)
    else:
        info["cur_posi"]=[0,0,0]
    return info

func init_player_data():
    hp=100
    sp=10
    lv=1
    exp_a=1
    str_a=5
    vit=5
    agi=5
    int_a=5
    dex=5
    luk=5

remote func on_level_up(new_lv):
    pass

remotesync func on_kill_mob():
    pass

func set_master(b_true):
    b_master=b_true
    get_node(cam_path).current=b_master

func get_point_mob(screen_pos):
    var from = cam.project_ray_origin(screen_pos)
    var to= from +cam.project_ray_normal(screen_pos)*1000
    var result = state_space.intersect_ray(from, to,[],8)
    if result.size()!=0:
        return result.collider
    else:
        return null

func get_ground_posi(screen_pos):
    var from = cam.project_ray_origin(screen_pos)
    var to= from +cam.project_ray_normal(screen_pos)*1000
    var result = state_space.intersect_ray(from, to,[],4)
    if result.size()!=0:
        return result.position
    else:
        return null

remote func request_atk(mob_name):
    print(mob_name)

func _input(event):
    if b_master==false:
        return
    if event is InputEventMouseMotion:
        var collider = get_point_mob(event.position)
        if collider!=null and collider.is_in_group("Mob"):
            if mouse_status!="atk":
                Input.set_custom_mouse_cursor(mouse_icon_atk)
                mouse_status="atk"
        else:
            if mouse_status!="normal":
                Input.set_custom_mouse_cursor(mouse_icon_normal)
                mouse_status="normal"
        if pressed:
            b_drag=true
            cam_platform.rotation.y=cam_platform.rotation.y-event.relative.x*hori_rot_spd
            if cam_platform.rotation.y>PI:
                cam_platform.rotation.y=cam_platform.rotation.y-2*PI
            elif cam_platform.rotation.y<-PI:
                cam_platform.rotation.y=cam_platform.rotation.y+2*PI
            cam_platform.rotation.x=cam_platform.rotation.x-event.relative.y*veri_rot_spd
            if cam_platform.rotation.x>-PI/9:
                cam_platform.rotation.x=-PI/9
            elif cam_platform.rotation.x<-PI/2:
                cam_platform.rotation.x=-PI/2
            
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            pressed=event.is_pressed()
            if pressed:
                b_drag=false
            if pressed==false:
                if b_drag==false:
                    var collider = get_point_mob(event.position)
                    if collider!=null:
                        rpc_id(1, "request_atk", collider.name)
                    else:
                        var posi_ground = get_ground_posi(event.position)
                        if posi_ground!= null:
                            rpc_id(1, "request_move_to", posi_ground)
                b_drag=false

        if event.is_pressed():
            if event.button_index == BUTTON_WHEEL_UP:
                cam.translation.z=cam.translation.z*zoom_spd
                if cam.translation.z<1:
                    cam.translation.z=1
            if event.button_index == BUTTON_WHEEL_DOWN:
                cam.translation.z=cam.translation.z/zoom_spd
                if cam.translation.z>5:
                    cam.translation.z=5

func on_create(_world):
    .on_create(_world)

func _ready():
    state_space=get_world().direct_space_state
    cam_platform=get_node(cam_platform_path)
    cam=get_node(cam_path)
