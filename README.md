# Cry of Fear Weapons Project
![](http://i.imgur.com/h0OZsxY.png)
>Custom weapons project for Sven Co-op.

This project is brought to you by D.N.I.O. 071 and me (KernCore).
It's a port of Cry of Fear's arsenal.

## The Weapons

* Switchblade (**weapon_cofswitchblade**)
* Nightstick (**weapon_cofnightstick**)
* Branch (**weapon_cofbranch**)
* Sledgehammer (**weapon_cofsledgehammer**)
* David Leatherhoff's Axe (**weapon_cofaxe**)
* Glock-19 (**weapon_cofglock**)
* VP-70 (**weapon_cofvp70**)
* Ruger P345 (**weapon_cofp345**)
* Taurus .357 Magnum (**weapon_cofrevolver**)
* Remington 870 (**weapon_cofshotgun**)
* Lee-Enfield Mk.3 Rifle (**weapon_cofrifle**)
* Colt M16A2 (**weapon_cofm16**)
* Gewehr 43 (**weapon_cofg43**)
* Steyr TMP (**weapon_coftmp**)
* H&K MP5 (**weapon_cofmp5**)
* FAMAS G2 (**weapon_coffamas**)
* Morphine Syringe (**weapon_cofsyringe**)
* Lantern (**weapon_coflantern**)
* Simon's Book (**weapon_cofbooklaser**)
* Digital Camera (**weapon_cofcamera**)
* "Out of it" AK-74 (**weapon_cofak74**)
* AoMDC's M9 Beretta (**weapon_cofberetta**)
* AoMDC's Desert Eagle (**weapon_cofdeagle**)
* AoMDC's P228 (**weapon_cofp228**)
* AoMDC's Glock-18 (**weapon_cofglock18**)
* AoMDC's Anaconda (**weapon_cofanaconda**)
* AoMDC's Golden Anaconda (**weapon_cofgolden**)
* AoMDC's UZI (**weapon_cofuzi**)
* AoMDC's L85A2 (**weapon_cofl85**)
* AoMDC's MP5K (**weapon_cofmp5k**)
* AoMDC's Benelli M3(**weapon_cofbenelli**)
* AoMDC's Kitchen Knife (**weapon_cofknife**)
* AoMDC's Hammer (**weapon_cofhammer**)
* AoMDC's Spear (**weapon_cofspear**)
* Previously Removed S&W M76 (**weapon_cofm76**)
* View Actions(**v_action**)

## Gameplay Videos

Video:
[![](https://i.ytimg.com/vi/4g6HBqL51Jo/maxresdefault.jpg)](https://www.youtube.com/watch?v=4g6HBqL51Jo)
*by VitorHunter.*

Video:
[![](https://i.ytimg.com/vi/okgo3OdCpIU/maxresdefault.jpg)](https://www.youtube.com/watch?v=okgo3OdCpIU)
*by SV BOY.*

Video:
[![](https://i.ytimg.com/vi/XtYBRp-wkjg/maxresdefault.jpg)](https://www.youtube.com/watch?v=XtYBRp-wkjg)
*by AlphaLeader772.*

## Installation Guide

1. Registering the weapons as plugins (Good for server operators, and most people):
	1. Download the pack from one of the download links below
	2. Extract it's contents inside Steam\steamapps\common\Sven Co-op\svencoop_addon\
	3. Open up default_plugins.txt located in Steam\steamapps\common\Sven Co-op\svencoop\
	4. Add these lines to the file:
	```
	"plugin"
	{
		"name"		"Cry of Fear"
		"script"	"../maps/cof/cofregister"
	}
	```
	5. Load any map of your preference;
2. Registering the weapons as map_scripts (Good for map makers):
	1. Download the pack from one of the download links below
	2. Extract it's contents inside Steam\steamapps\common\Sven Co-op\svencoop_addon\
	3. Open up any map .cfg (i.e: svencoop1.cfg) and add this line to it:
	```
	map_script cof/cofregister
	```
	4. Load up the map you chose;
