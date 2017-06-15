/mob
	var/list/injured_limbs = list()
	var/list/limbs = list()
	var/list/organs = list()
	var/list/organs_by_key = list()
	var/sitting = FALSE

/mob/proc/GetOrgansByKey(var/organ)
	return organs_by_key[organ]

/mob/proc/GetOrganByKey(var/organ)
	var/list/organs = GetOrgansByKey(organ)
	if(istype(organs, /list) && organs.len)
		return pick(organs)

/mob/proc/GetHealthyOrgansByKey(var/organ_key)
	var/list/organs = GetOrgansByKey(organ_key)
	if(organs)
		for(var/thing in organs.Copy())
			var/obj/item/organ/organ = thing
			if(!organ.IsHealthy())
				organs -= organ
		if(organs.len)
			return organs

/mob/proc/GetOrganEffectVolume(var/organ_key)
	var/volume = 0
	for(var/thing in GetHealthyOrgansByKey(organ_key))
		var/obj/item/organ/organ = thing
		volume += organ.effects.len
	return volume

/mob/proc/GetHealthyOrganByKey(var/organ_key)
	var/list/organs = GetHealthyOrgansByKey(organ_key)
	if(organs && organs.len)
		return pick(organs)

/mob/proc/GetLimb(var/limb_key)
	return limbs[limb_key]

/mob/proc/CanUseLimb(var/slot)
	var/obj/item/limb/hand = GetLimb(slot)
	if(!istype(hand))
		Notify("You are missing that limb!")
		return FALSE
	if(hand.broken)
		Notify("Your [hand.name] is broken and unusable.")
		return FALSE
	return TRUE

/mob/proc/CanUseInvSlot(var/slot)
	var/obj/ui/inv/inv_slot = inventory_slots[slot]
	if(!istype(inv_slot))
		Notify("You cannot use that limb.")
		return FALSE
	if(inv_slot.associated_limb)
		return CanUseLimb(inv_slot.associated_limb)
	return TRUE

/mob/proc/CreateLimbs()
	limbs[BP_CHEST] = new /obj/item/limb(src, "body", 'icons/objects/items/limbs/chest.dmi', BP_CHEST, _root = TRUE, _vital = TRUE, _size = 10)

/mob/proc/CreateOrgans()
	return

/mob/proc/ToggleSitting()
	sitting = !sitting
	for(var/limb in list(BP_LEFT_LEG, BP_RIGHT_LEG, BP_LEFT_FOOT, BP_RIGHT_FOOT))
		var/obj/item/limb/bp = GetLimb(limb)
		if(istype(bp))
			bp.SetNotMoving(sitting)
	UpdateIcon()
