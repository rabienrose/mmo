extends BaseChara

var ai_type="passive"
var mob_name=""

func on_die(killer):
	world.create_more_mobs()
	killer.add_exp(Global.mob_infos[mob_name]["mob_exp"])
	.on_die(killer)

func init_unit_data():
	set_base_attr_by_info(Global.mob_infos[mob_name])
	cal_attr()

func _ready():
	set_ai_scheme("rand_walk",{})
	get_node(char_ui_path).toggle_hpbar(false)
	get_node(char_ui_path).set_name(mob_name)

func on_tar_die():
	set_ai_scheme("rand_walk",{})
