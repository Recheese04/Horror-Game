extends StaticBody3D

var is_reading = false

func get_interaction_prompt() -> String:
	return "Look at photo"

func interact():
	if is_reading: return
	is_reading = true
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("show_subtitle"):
		player.show_subtitle("Ang iyang Tatay. Batan-on pa. Nagpahiyom. Nagtindog sa atubangan sa ilang balay.")
		await get_tree().create_timer(3.5).timeout
		player.show_subtitle("Sa iyang tupad — usa ka babaye. Tigulang. Puti og buhok. Malumo og pahiyom. Si Nang Caring.")
		await get_tree().create_timer(4.0).timeout
		player.show_subtitle("Wala ra gyud ni panumbalinga ni Christian kaniadto. Ang tanan naay litrato uban ni Nang Caring.")
		await get_tree().create_timer(4.0).timeout
		player.show_subtitle("Dugay na kaayo siya sa barangay, mas dugay pa kaysa sa mahinumduman sa tanan.")
		await get_tree().create_timer(4.0).timeout
		player.hide_subtitle()
	is_reading = false
