extends BaseChara

var ai_type="passive"

func on_create(_world):
    .on_create(_world)

remotesync func on_damaged(path_node):
    .on_damaged(path_node)

func _ready():
    pass # Replace with function body.

func set_idle():
    ai_status="idle"
        
func set_rand_walk():
    var posi = world.get_rand_free_spot()
    request_move_to(posi)
    ai_status="move"

func _physics_process(delta):
    if get_tree().is_network_server():
        ai_proc_count=ai_proc_count+1
        if ai_proc_count<ai_proc_step:
            return
        ai_proc_count=0
        if ai_status=="idle":
            var chance =Global.rng.randf_range(0,1)
            if chance>0.5:
                set_rand_walk()
        elif ai_status=="move":
            if cur_path.size()==0:
                set_idle()

