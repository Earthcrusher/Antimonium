/obj/item/limb
	var/list/wounds = list()
	var/list/organs = list()
	var/broken = FALSE

/obj/item/limb/proc/ExpandWoundOfType(var/wound_type = WOUND_CUT, var/wound_depth, var/wound_severity, var/obj/item/attacked_with, var/silent = FALSE)

	// First try to expand an existing wound.
	var/datum/wound/wound
	if(wounds.len)
		var/list/matching_wounds = list()
		for(var/datum/wound/old_wound in wounds)
			if(old_wound.wound_type == wound_type)
				matching_wounds += old_wound
		if(matching_wounds.len)
			wound = pick(matching_wounds)
			wound.depth += wound_depth
			wound.severity += wound_severity
			if(attacked_with)
				wound.left_by = attacked_with.name
			owner.Notify("<span class='danger'><b>A wound on your [name] worsens into [wound.GetDescriptor()]!</b></span>")
			SetPain(max(pain, wound.GetPain()))
			UpdateLimbState()
			if(wound.bleed_amount)
				wound.Reopen()

	// Otherwise, make a new wound.
	if(!wound)
		wound = new(src, wound_type, wound_depth, wound_severity, attacked_with ? attacked_with.name : "unknown")
		wounds += wound
		SetPain(max(pain, wound.severity))
		if(!silent)
			owner.Notify("<span class='danger'><b>The blow leaves your [name] with [wound.GetDescriptor()]!</b></span>")
		UpdateLimbState()

	if(owner && NeedProcess())
		owner.injured_limbs |= src

/obj/item/limb/proc/HandleAttacked(var/wound_depth, var/wound_severity, var/wound_type, var/attack_contact_size, var/obj/item/attacked_with)

	if(!owner)
		return

	cumulative_wound_depth += wound_depth
	cumulative_wound_severity += wound_severity

	if(wound_type == WOUND_CUT && wound_severity > 5)
		Splatter(get_turf(owner), owner.blood_material)

	ExpandWoundOfType(wound_type, wound_depth, wound_severity, attacked_with)

	// Damage internal organs.
	if(cumulative_wound_depth >= attack_contact_size && organs.len)
		var/obj/item/organ/organ = pick(organs)
		var/damaging = max(1,rand(round(wound_severity * 0.5), round(wound_severity * 0.75)))
		organ.TakeDamage(damaging)


/obj/item/limb/proc/HandleBurned(var/attack_weight, var/attack_sharpness, var/attack_contact_size, var/obj/item/attacked_with)
	ExpandWoundOfType(WOUND_BURN, 0, attack_contact_size, attacked_with, silent = TRUE)

/obj/item/limb/proc/BreakBone()
	owner.NotifyNearby("<span class='alert'><b>\The [owner]'s [name] makes a horrible cracking sound!</b></span>", MESSAGE_AUDIBLE)
	broken = TRUE
	HandleBreakEffects()

/obj/item/limb/proc/SeverLimb(var/obj/item/limb/severing, var/amputated = FALSE)

	if(!owner || root_limb)
		return

	not_moving = FALSE
	flags &= ~FLAG_ANCHORED
	owner.injured_limbs -= src
	owner.limbs_by_key[limb_id] = null
	owner.limbs_by_key -= limb_id
	owner.limbs -= src

	for(var/thing in organs)
		var/obj/item/organ/organ = thing
		organ.Remove()
		organ.ForceMove(src)

	if(severing)
		ForceMove(severing)
		for(var/obj/item/limb/child in children)
			child.SeverLimb(severing)
	else
		for(var/obj/item/limb/child in children)
			child.SeverLimb(src)
		if(parent)
			var/datum/wound/wound
			if(amputated)
				wound = new(parent, WOUND_CUT, 10, 20, "surgical amputation")
			else
				wound = new(parent, WOUND_CUT, 20, 40, "traumatic amputation")
			parent.wounds += wound
			parent.cumulative_wound_depth += wound.depth
			parent.cumulative_wound_severity += wound.severity
			owner.injured_limbs |= parent
			parent.children -= src
			parent = null

		var/matrix/M = matrix()
		M.Turn(pick(0,90,180,270))
		transform = M

		PlayLocalSound(src, pick(list('sounds/effects/gore1.ogg','sounds/effects/gore2.ogg','sounds/effects/gore3.ogg')), 100)
		if(amputated)
			owner.NotifyNearby("<span class='alert'><b>\The [owner]'s [name] has been cleanly severed!</b></span>", MESSAGE_VISIBLE)
			ForceMove(get_turf(owner))
		else
			owner.NotifyNearby("<span class='alert'><b>\The [owner]'s [name] flies off in an arc!</b></span>", MESSAGE_VISIBLE)
			ThrownAt(get_step(src, pick(all_dirs)))

		var/blood_mat = owner.blood_material
		spawn(1)
			Splatter(loc, blood_mat)

		owner.UpdateIcon()
		for(var/obj/item/limb/child in src)
			overlays += child.GetWornIcon("world")

	HandleSeverEffects()
	owner = null

/obj/item/limb/proc/HandleSeverEffects()
	if(vital)
		owner.Die("loss of a vital limb")

/obj/item/limb/proc/HandleBreakEffects()
	return