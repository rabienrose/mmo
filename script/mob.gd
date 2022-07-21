extends BaseChara

var ai_type="passive"

func on_damaged():
    print(name," on_damaged")

func _ready():
    ai_scheme="rand_walk"
    set_idle()
    set_anima_idle()
