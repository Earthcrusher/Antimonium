/obj/ui/inv
	name = "Inventory"
	var/obj/item/holding
	var/slot_id
	var/slot_flags = 0
	var/unmodified_name
	var/concealable = FALSE

/obj/ui/inv/New(var/mob/_owner, var/nname, var/nscreen_loc, var/nslot_id, var/_slot_flags)
	. = ..()
	if(nname)
		name = nname
	unmodified_name = name
	if(nscreen_loc)
		screen_loc = nscreen_loc
	if(nslot_id)
		slot_id = nslot_id
	icon_state = "inv_[slot_id]"
	slot_flags |= _slot_flags
	if(concealable) // Defaults to on.
		invisibility = INVISIBILITY_MAXIMUM

/obj/ui/inv/destroy()
	holding = null
	. = ..()

/obj/ui/inv/proc/set_held(var/obj/item/thing)
	holding = thing
	update_icon()

/obj/ui/inv/proc/forget_held()
	holding = null
	update_icon()

/obj/ui/inv/update_icon(var/list/supplied = list())
	name = unmodified_name
	overlays.Cut()
	if(holding)
		name = "[name] - [holding.name]"
		overlays += holding.get_inv_icon()
