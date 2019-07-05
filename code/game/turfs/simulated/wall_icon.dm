/turf/simulated/wall/proc/update_full(var/propagate, var/integrity)
	update_material(integrity)
	update_connections(propagate)
	queue_icon_update()

/turf/simulated/wall/proc/update_material(var/integrity)

	if(!material)
		return

	if(reinf_material)
		state = 6
	else
		state = null
	if(!material)
		material = SSmaterials.get_material_by_name(DEFAULT_WALL_MATERIAL)
	if(material)
		if(integrity)
			src.integrity = MaxIntegrity()
		explosion_resistance = material.explosion_resistance
	if(reinf_material && reinf_material.explosion_resistance > explosion_resistance)
		explosion_resistance = reinf_material.explosion_resistance

	if(reinf_material)
		SetName("reinforced [material.display_name] [initial(name)]")
		desc = "It seems to be a section of hull reinforced with [reinf_material.display_name] and plated with [material.display_name]."
	else
		SetName("[material.display_name] [initial(name)]")
		desc = "It seems to be a section of hull plated with [material.display_name]."

	set_opacity(material.opacity >= 0.5)

	SSradiation.resistance_cache.Remove(src)
	update_connections(1)
	update_icon()


/turf/simulated/wall/proc/set_material(var/material/newmaterial, var/material/newrmaterial)
	material = newmaterial
	reinf_material = newrmaterial
	update_material()

/turf/simulated/wall/on_update_icon()

	..()

	if(!material)
		return
	
	LAZYCLEARLIST(overlays)

	if(!damage_overlays || damage_overlays && !damage_overlays[1]) //list hasn't been populated; note that it is always of fixed length, so we must check for membership.
		generate_overlays()

	var/image/I
	var/base_color = paint_color ? paint_color : material.icon_colour
	if(!density)
		I = image('icons/turf/wall_masks.dmi', "[material.icon_base]fwall_open")
		I.color = base_color
		overlays += I
		return

	for(var/i = 1 to 4)
		I = image('icons/turf/wall_masks.dmi', "[material.icon_base][wall_connections[i]]", dir = 1<<(i-1))
		I.color = base_color
		overlays += I
		if(other_connections[i] != "0")
			I = image('icons/turf/wall_masks.dmi', "[material.icon_base]_other[wall_connections[i]]", dir = 1<<(i-1))
			I.color = base_color
			overlays += I

	if(reinf_material)
		var/reinf_color = paint_color ? paint_color : reinf_material.icon_colour
		if(state != null && state < 6)
			I = image('icons/turf/wall_masks.dmi', "reinf_construct-[state]")
			I.color = reinf_color
			overlays += I
		else
			if("[reinf_material.icon_reinf]0" in icon_states('icons/turf/wall_masks.dmi'))
				// Directional icon
				for(var/i = 1 to 4)
					I = image('icons/turf/wall_masks.dmi', "[reinf_material.icon_reinf][wall_connections[i]]", dir = 1<<(i-1))
					I.color = reinf_color
					overlays += I
			else
				I = image('icons/turf/wall_masks.dmi', reinf_material.icon_reinf)
				I.color = reinf_color
				overlays += I

	if(stripe_color)
		for(var/i = 1 to other_connections.len)
			if(other_connections[i] != "0")
				I = image('icons/turf/wall_masks.dmi', "stripe_other[wall_connections[i]]", dir = GLOB.alldirs[i])
			else
				I = image('icons/turf/wall_masks.dmi', "stripe[wall_connections[i]]", dir = GLOB.alldirs[i])
			I.color = stripe_color
			overlays += I

	if(integrity != MaxIntegrity())
		var/overlay = Floor((MaxIntegrity() - integrity) / MaxIntegrity() * damage_overlays.len) + 1
		if(overlay > damage_overlays.len)
			overlay = damage_overlays.len

		overlays += damage_overlays[overlay]
	return

/turf/simulated/wall/proc/generate_overlays()
	var/alpha_inc = 256 / damage_overlays.len

	for(var/i = 1; i <= damage_overlays.len; i++)
		var/image/img = image(icon = 'icons/turf/walls.dmi', icon_state = "overlay_damage")
		img.blend_mode = BLEND_MULTIPLY
		img.alpha = (i * alpha_inc) - 1
		damage_overlays[i] = img


/turf/simulated/wall/proc/update_connections(propagate = FALSE)
	if(!material)
		return
	var/list/wall_dirs = list()
	var/list/other_dirs = list()

	for(var/turf/simulated/wall/W in orange(src, 1))
		switch(can_join_with(W))
			if(0)
				continue
			if(1)
				wall_dirs += get_dir(src, W)
			if(2)
				wall_dirs += get_dir(src, W)
				other_dirs += get_dir(src, W)
		if(propagate)
			W.update_connections()
			W.update_icon()

	for(var/turf/T in orange(src, 1))
		var/success = FALSE
		for(var/obj/O in T)
			for(var/b_type in blend_objects)
				if(istype(O, b_type))
					success = TRUE
				for(var/nb_type in noblend_objects)
					if(istype(O, nb_type))
						success = FALSE
				if(success)
					break
			if(success)
				break

		if(success)
			wall_dirs += get_dir(src, T)
			if(get_dir(src, T) in GLOB.cardinal)
				other_dirs += get_dir(src, T)

	wall_connections = dirs_to_corner_states(wall_dirs)
	other_connections = dirs_to_corner_states(other_dirs)

/turf/simulated/wall/proc/can_join_with(var/turf/simulated/wall/W)
	if(material && W.material && material.icon_base == W.material.icon_base)
		if((reinf_material && W.reinf_material) || (!reinf_material && !W.reinf_material))
			return 1
		return 2
	for(var/wb_type in blend_turfs)
		if(istype(W, wb_type))
			return 2
	return 0
