/mob
	var/pain = 0
	var/shock = 0
	var/blood = 100

	var/ideal_sight_value
	var/blindness_step_value
	var/vision_quality

/mob/proc/HandleLifeTick()

	// Update wounds, healing, shock, infection, etc.
	pain = 0
	for(var/thing in injured_limbs)
		var/obj/item/limb/limb = thing
		limb.Process()
		pain += limb.pain

	for(var/thing in organs)
		var/obj/item/organ/organ = thing
		organ.Process()

	// Various life processes.
	HandleVision()
	HandleBleeding()
	HandleConsumableEffects()
	HandleHunger()

	// Pass out if we're unconscious.
	if(unconsciousness > 0)
		unconsciousness--
		PassOut()

	// Apply updates as calculated above.
	UpdateVision()
	UpdateGrasp()
	UpdateStance()
	health.UpdateIcon()

	// Pain can kill you, so do this last.
	HandlePain()

/mob/proc/HandleVision()

	if(!ideal_sight_value)
		return

	vision_quality = 0 // Arbitrary magic numbers for now.
	if(unconsciousness <= 0)
		for(var/thing in GetHealthyOrgansByKey(ORGAN_EYE))
			var/obj/item/organ/eye = thing
			if(eye.IsBruised())
				vision_quality += 1
			else
				vision_quality += 2

/mob/proc/UpdateVision()
	var/target_alpha

	if(unconsciousness > 0)
		target_alpha = 255
	else if(!ideal_sight_value || vision_quality >= ideal_sight_value)
		target_alpha = 0
	else
		target_alpha = min(255,max(0,255 - (blindness_step_value * vision_quality)))
	if(target_alpha != blindness_overlay.alpha)
		animate(blindness_overlay, alpha = target_alpha, time = 3)

/mob/proc/HandlePain()
	switch(pain)
		if(100 to INFINITY)
			if(IsConscious())
				Notify("<span class='alert'>Agony overcomes you, and you black out.</span>")
			SetUnconscious(3)
			shock = min(shock+1, 100)
		if(90 to 100)
			if(prob(1))
				if(IsConscious())
					Notify("<span class='alert'>Agony overcomes you, and you black out.</span>")
				SetUnconscious(3)
		else
			shock = max(shock, 0)

	if(!dead && shock == 100)
		Die("traumatic shock")

/mob/proc/UpdateGrasp()
	//TODO: move this to limbs
	var/obj/item/holding = GetEquipped(SLOT_LEFT_HAND)
	if(istype(holding) && holding.Burn(src, SLOT_HANDS))
		Notify("<span class='alert'>\The [holding] sears your left hand and falls from your grasp!</span>")
		DropItem(holding)
	holding = GetEquipped(SLOT_RIGHT_HAND)
	if(istype(holding) && holding.Burn(src, SLOT_HANDS))
		Notify("<span class='alert'>\The [holding] sears your right hand and falls from your grasp!</span>")
		DropItem(holding)

/mob/proc/HandleBleeding()
	if(dead)
		return

	if(hunger > 0 && blood < 100)
		var/obj/item/organ/liver = GetHealthyOrganByKey(ORGAN_LIVER)
		if(liver)
			hunger--
			blood = min(100, blood + rand(1,3))

	var/effective_blood = blood
	if(!GetHealthyOrganByKey(ORGAN_HEART))
		effective_blood = 50

	if(effective_blood <= 60)
		var/obj/item/organ/brain = GetHealthyOrganByKey(ORGAN_BRAIN)
		if(brain)
			brain.TakeDamage(10)
		else
			Die("blood loss")

	else if(prob(10))
		switch(effective_blood)
			if(90 to 100)
				return
			if(80 to 90)
				Notify("<span class='warning'>You feel slightly light-headed.</span>")
			if(70 to 80)
				Notify("<span class='danger'>The world lurches sickeningly as dizziness overtakes you.</span>")
			if(60 to 70)
				Notify("<span class='alert'>Flickering darkness swims at the edges of vour vision as you struggle to remain conscious.</span>")
