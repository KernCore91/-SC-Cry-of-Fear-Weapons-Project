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

## Screenshots
[![](https://i.imgur.com/GecS1Iym.png)](https://i.imgur.com/GecS1Iy.png)
[![](https://i.imgur.com/0rlBt4fm.png)](https://i.imgur.com/0rlBt4f.png)
[![](https://i.imgur.com/wuOnw2tm.png)](https://i.imgur.com/wuOnw2t.png)
[![](https://i.imgur.com/84E0GqLm.png)](https://i.imgur.com/84E0GqL.png)
[![](https://i.imgur.com/yszXhUnm.png)](https://i.imgur.com/yszXhUn.png)
[![](https://i.imgur.com/gYkANMzm.png)](https://i.imgur.com/gYkANMz.png)

## Installation Guide

1. Registering the weapons as plugins (Good for server operators, and most people):
	1. Download the pack from one of the download links below
	2. Extract it's contents inside **`Steam\steamapps\common\Sven Co-op\svencoop_addon\`**
	3. Open up *`default_plugins.txt`* located in **`Steam\steamapps\common\Sven Co-op\svencoop\`**
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
	2. Extract it's contents inside **`Steam\steamapps\common\Sven Co-op\svencoop_addon\`**
	3. Open up any map .cfg (i.e: *`svencoop1.cfg`*) and add this line to it:
	```
	map_script cof/cofregister
	```
	4. Load up the map you chose;

## Notes

Due to some engine/balance limitations we were forced to change somethings:

* All sounds are in .ogg format, which helps keeping their file size below 200kb while keeping the studio-like quality sounds of the weapons.

* The Camera has a 5 second timer that resets frozen monsters. It DOES NOT WORK on certain types of monsters such as: Machines, Barnacle, Generic, Nihilant, Tentacle, Gargantua, Big Momma and Kingpin.

* Holstering the Camera WILL reset frozen monsters.

* These weapons DO NOT feature Auto-reload.

* The Syringe CAN NOT revive players.

* Certain weapons include a alternative firemode/firerate/feature. By pressing your Use key + your Reload key (*+use* along with *+reload*) you can change them, such as: M16, Famas, L85, Glock-18 and Glock-19.

* It does not feature dual-wielding weapons.

* Includes a .fgd and .res (made by R4to0) file.

* Includes a debug map made by Cadaver (*`cryoffinal.bsp`*).


CONTROLS:
PRIMARY ATTACK KEY (+attack) -> Fire
SECONDARY ATTACK KEY (+attack2) -> Aim
TERTIARY ATTACK KEY (+alt1) -> Melee
USE KEY + RELOAD KEY (+use;+reload) -> Use alternative mode (Only works on Glock-19/M16/Famas/Glock-18/L85)

## Credits

Cry of Fear is made by Team Psykskallar, check it out [here!](http://store.steampowered.com/app/223710/)  
You are authorized to use any assets from this pack as long as you give credit to the creators.  
If you're wondering if we have permission to port them, you can check it out [here](https://i.imgur.com/0oqlaro.png).  
As of now, anyone who wants to port Cry of Fear weapons are permitted AS LONG AS:
* you give propper credits
* you don't earn any money from them.
Any other asset from Cry of Fear is strictly forbidden to be ported.

## Updates

### Update 1.4:
* Added Destructor to the v_action (avoiding Instance crashes, hopefully);
* Added a Laser sprite to the Glock 19;
* All firemodes buttons were changed to E + R instead of E + MOUSE2;
* All viewmodels were recompiled to support SetVModelPos, which removes the model movement (helping you aim better);
* Better handrig for viewmodels using Insurgency's skeleton;
* Changed M9 Beretta, MP5K and Benelli viewmodel animations;
* Changed Glock 19, VP-70, M16 and TMP's models to the ones used in Cry of Fear;
* Changed the Desert Eagle's model to a more optimized one by Norman;
* Changed M16/FAMAS/L85A2/Glock 18 Firemodes sprite;
* Fixed the G18 playing the wrong animation when changing the firemode shortly after reloading;
* Glock 19's laser and FAMAS' firemode is now toggleable while aiming down the sights;
* Improved flame colision on the booklaser;
* Improved burstfire code on the M16/VP70/FAMAS;
* Implemented a better bodygroup system for the Anaconda revolvers, viewmodel reload animation is no longer cut off;
* Mashed together all sprites into 3 512x512 files;
* Several Optimizations made to file names and path naming, hopefully reducing SendResources incidents; (Don't forget to change your default_plugins.txt file if you had it before this update!)
* Slightly improved hammer animations;
* Optimized World Models texture size and polygon count.

### Update 1.3:
***WORKAROUND: Due to the game not being able to play Schedules in the Holster() functions anymore, a temporary fix is to not let the players drop weapons
That means you'll not be able to drop the: Syringe***
* Added AoMDC weapons remastered into Cry of Fear format (Complete with melee animations):
	* Anaconda,
	* Benelli M3,
	* Beretta M9,
	* Desert Eagle,
	* Glock 18,
	* Golden Anaconda,
	* Hammer,
	* Kitchen Knife,
	* L85A2,
	* MP5K,
	* P228,
	* Spear,
	* UZI;
* Added previously removed weapon from CoF: S&W M76;
* Added view actions weapon (you can only deploy it if you don't have any guns in your hands);
* Added new fresh and organized Buymenu (Thanks Zode);
* Added support for ammo dropping;
* Changed AK-74's Shoot sound;
* Changed how recoil is handled in the following weapons: M16 (Burst Mode), Famas (Burst Mode), VP-70;
* Damage/Slot/Position values of each weapon are non-const and uint now, allowing you to change their values inside your register script;
* Debugging map "SvenofFear.bsp" is now called "cryoffinal.bsp";
* Famas, M16 and VP-70 now uses Audio Channel CHAN_AUTO instead of CHAN_WEAPON;
* Fixed bug that caused the lantern to crash the server if registered as a plugin (CopyConstructVector3D);
* Fixed P345's reload sounds being off;
* Fixed VP70 not playing the first shoot animation;
* Fixed not being able to pick up syringe ammo while healing yourself;
* Fixed holstering the shotgun while reloading not playing the RELOAD_END_NOSHOOT after deploying it again;
* Fixed issues with the Booklaser while holding Mouse2/Mouse3;
* Fixed ammo sprites being glitched in 5.15;
* Increased firerate on the M16(Single shot mode);
* Improved Glock-19's accuracy while moving;
* Lantern will now illuminate once dropped (Thanks anggara_nothing/Zorbos);
* Increased damage and lowered magazine on the Remington 870, improved pellet spread (should act more dinamically now) of it as well;
* Lowered firerate of the following weapons: AK-74, M16(Burst Mode);
* Reduced Axe's distance from 50 units to 46 units;
* Reduced the Camera/Lantern melee damage (20/24 to 15);
* Reduced the Lantern's Respawn Time to 5 seconds;
* Removed the new Angles Recoil from the G43/Revolver/Rifle/Shotgun (No clientside prediction made your angles snap when on a high ping server);
* TMP and MP5 now supports Sound Loops (Similiar to what happens in CoF), along with it, Rate of Fire changes to compensate them;
* The Syringe now uses TraceHull along with TraceLine;
* The Booklaser flames now display a smoke when going out;
* Various size optimizations on the shells models.

### Update 1.2:
* Added easy way to tweak damage values to the weapons;
* Added easy way to change slots and positions of the weapons.

### Update 1.1:
* Added "Out of it" custom weapon: AK-74;
* Added new recoil method for G43, Revolver, Rifle and Shotgun;
* Adjusted Famas aiming times;
* Fixed the Syringe not being destroyed after being depleted;
* Fixed various missing Generic Precaches for sounds/sprites;
* Increased Lantern's Brightness;
* Reduced Glock-19's underwater shoot distance by 1024 units.

### Update 1.0:
* Fixed Syringe being able to heal friendly machinery;
* Fixed svenoffear.bsp not loading the script.

## Download Links

Total Size Compressed: 22.3 MB

(.7z) [Dropbox](https://www.dropbox.com/s/dxiabho4rtxfktb/Sven-CoF_1-4.7z?dl=0)  
(.7z) [Mega](https://mega.nz/#!es1gUaiK!rNxwKnc1Jsocbby7mBRKCSW4qUFPwN1NhsBC99Jk0R8)  
(.7z) [HLDM-BR.NET](https://cdn.hldm-br.net/files/sc/cof/Sven-CoF_1-4.7z)  
(.7z) [Boderman.net](http://www.boderman.net/svencoop/Sven-CoF_1-4.7z)  