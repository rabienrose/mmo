extends Node

func gen_level_info():
	var out_str="lv,exp\n"
	for i in range(1, 100):
		var exp_t=int(pow(1.15,i)*100)
		out_str=out_str+str(i)+","+str(exp_t)+"\n"
	var f=File.new()
	f.open("res://config/level.dat", File.WRITE)
	f.store_string(out_str)
	f.close()

func _ready():
	gen_level_info()
