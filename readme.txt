Thank you for downloading this pack.
This pack include a reworked format of BuyMenu thanks to Zode.

If you want to register these weapons as plugins on your server, you may do so using the register
file called: cofregister.as. This file will register all CoF and AoMDC weapons along with BuyMenu and view actions weapon.
If you're looking to register only a few weapons into your map, you may do so by using another
registering file (i.e: cofkernregister.as) and including all the weapons you want in that file, and
then calling: map_script cof/yourregfile (i.e: map_script cof/cofkernregister) on the map's .cfg file.
If you do not need to use of BuyMenu on your map you can remove it from register file you created
as it's only needed for server owners, so their players are able to use this script.

If you want to release a map using these weapons on scmapdb/gamebanana/svencoop forums, you will
have to credit KernCore, D.N.I.O. 071, and R4to0 for making this project possible, you may also
not forget to thank: Team Psykskallar, Sporkeh, Norman Roger and DGF. You are obliged to include
along with your release the Credits.txt file comes with this pack. Forgetting to include that
file in your release and/or earning money from the usage of this pack may result in copyright
takedown from Team Psykskallar or anyone involved in the making of this pack.

Additionally there's a file named: createcof.cfg. If you have administrator privileges in your server and you have sv_cheats set
to 1 or 2, you can type in your console: exec createcof.cfg. This will allow you to spawn all CoF weapons and ammo in front of you.

Re-releasing this pack on another website without the KernCore/D.N.I.O. 071's consent is prohibited.

You can modify: Weapon damage and HUD Slot/Position only if really needed, 

Here are some instructions regarding the weapons:
-They DO NOT auto reload, in CoF every action is made with the player's input, this pack aims to replicate that.

-If you want auto reload, remove the flag ITEM_FLAG_NOAUTORELOAD from the scripts.

-It makes use of certain buttons: Mouse1(+attack bind), Mouse2(+attack2 bind), Middle Scroll(+alt1 bind), and for certain
weapons the Use(+use bind) along with the R button(+reload bind), this is made because of a button limitation
in the engine, E+R is used to change firerates on the M16, Famas, and switch on/off the laser on the Glock.

-For balacing issues, the Camera is somewhat limited when comparing it to the original CoF: It has a 5 second delay to
reset the monsters; it doesn't work on certain monsters (monster_generic/machines/boss-like), and some monsters can
even glitch out (such as male_assassin and human_grunt); holstering/dropping the Camera will also reset them.

-Each weapon has it's own ammo entity (with some weapons even sharing ammo), they're custom and CAN'T be shared
with the default weapons.

-If you want them to share ammo with the default ones change p_Customizable in cofcommon.as to false.

This has been a project between KernCore and D.N.I.O. 071, with help from:
 Norman the Loli Pirate, 
 R4to0, 
 Vitorhunter,
 Solokiller,
 MrOats,
 Der Graue Fuchs.