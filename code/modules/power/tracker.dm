//Solar tracker

//Machine that tracks the sun and reports it's direction to the solar controllers
//As long as this is working, solar panels on same powernet will track automatically

/obj/machinery/power/tracker
	name = "solar tracker"
	desc = "A solar directional tracker."
	icon = 'icons/obj/power.dmi'
	icon_state = "tracker"
	anchored = 1
	density = 1
	use_power = 0

	var/id = 0
	var/sun_angle = 0		// sun angle as set by sun datum
	var/obj/machinery/power/solar_control/control = null

/obj/machinery/power/tracker/New(var/turf/loc, var/obj/item/solar_assembly/S)
	..(loc)
	Make(S)
	connect_to_network()

/obj/machinery/power/tracker/Destroy()
	unset_control() //remove from control computer
	..()

//set the control of the tracker to a given computer if closer than SOLAR_MAX_DIST
/obj/machinery/power/tracker/proc/set_control(var/obj/machinery/power/solar_control/SC)
	if(!SC)//&& (get_dist(src, SC) > SOLAR_MAX_DIST))
		return 0
	control = SC
	return 1

//set the control of the tracker to null and removes it from the previous control computer if needed
/obj/machinery/power/tracker/proc/unset_control()
	if(control)
		control.connected_tracker = null
	control = null

/obj/machinery/power/tracker/proc/Make(var/obj/item/solar_assembly/S)
	if(!S)
		S = new /obj/item/solar_assembly(src)
		S.glass_type = /obj/item/stack/material/glass
		S.tracker = 1
		S.anchored = 1
	S.forceMove(src)
	update_icon()

//updates the tracker icon and the facing angle for the control computer
/obj/machinery/power/tracker/proc/set_angle(var/angle)
	if(!control)
		return
	sun_angle = angle

	//set icon dir to show sun illumination
	set_dir(turn(NORTH, -angle - 22.5))	// 22.5 deg bias ensures, e.g. 67.5-112.5 is EAST

	if(powernet && (powernet == control.powernet)) //update if we're still in the same powernet
		control.cdir = angle

/obj/machinery/power/tracker/attackby(var/obj/item/weapon/tool/crowbar/C, var/mob/user)
	if(isCrowbar(C))
		playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
		user.visible_message("<span class='notice'>[user] begins to take the glass off the solar tracker.</span>")
		if(C.use_tool(user, src, 5 SECONDS))
			user.visible_message("<span class='notice'>[user] takes the glass off the tracker.</span>")
			dismantle()
		return 1
	return ..()

/obj/machinery/power/tracker/dismantle()
	var/obj/item/solar_assembly/S = locate() in src
	if(S)
		S.dropInto(loc)
		S.give_glass()
	. = ..()

// Tracker Electronic

/obj/item/weapon/tracker_electronics

	name = "tracker electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = ITEM_SIZE_SMALL
