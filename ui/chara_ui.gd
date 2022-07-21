extends Spatial

export (Resource) var bar_red
export (Resource) var bar_green
export (Resource) var bar_yellow

export (NodePath) var hp_bar_path
export (NodePath) var sp_bar_path

var hp_bar
var sp_bar

func _ready():
    hp_bar=get_node(hp_bar_path)
    sp_bar=get_node(sp_bar_path)

func toggle_hpbar(b_show):
    hp_bar.visible=b_show

func toggle_spbar(b_show):
    sp_bar.visible=b_show

func update_sp_bar(amount):
    sp_bar.value = amount

func update_hp_bar(amount, full):
    hp_bar.texture_progress = bar_green
    if amount < 0.75 * full:
        hp_bar.texture_progress = bar_yellow
    if hp_bar.value < 0.45 * full:
        hp_bar.texture_progress = bar_red
    hp_bar.value = amount
