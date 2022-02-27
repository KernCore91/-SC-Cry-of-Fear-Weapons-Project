/********************************************************************
* READ THE readme.txt FILE FIRST BEFORE MODIFYING THIS FILE         *
*********************************************************************/

const bool p_Customizable = true; // Needed to define custom/default ammo

// Original Cry of Fear weapons
#include "melee/weapon_cofswitchblade"
#include "melee/weapon_cofbranch"
#include "melee/weapon_cofnightstick"
#include "melee/weapon_cofaxe"
#include "melee/weapon_cofsledgehammer"
#include "pistols/weapon_cofglock"
#include "pistols/weapon_cofp345"
#include "pistols/weapon_cofrevolver"
#include "pistols/weapon_cofvp70"
#include "smgs/weapon_coftmp"
#include "smgs/weapon_cofmp5"
#include "shotguns/weapon_cofshotgun"
#include "rifles/weapon_cofg43"
#include "rifles/weapon_cofm16"
#include "rifles/weapon_cofrifle"
#include "rifles/weapon_coffamas"
#include "special/weapon_cofcamera"
#include "special/weapon_cofsyringe"
#include "special/weapon_cofbooklaser"
#include "special/weapon_coflantern"
// Removed from Cry of Fear
#include "smgs/weapon_cofm76"
// From the "Out of it" custom campaign
#include "rifles/weapon_cofak74"
// From the AoMDC campaign
#include "pistols/weapon_cofdeagle"
#include "pistols/weapon_cofglock18"
#include "pistols/weapon_cofanaconda"
#include "pistols/weapon_cofberetta"
#include "pistols/weapon_cofp228"
#include "melee/weapon_cofknife"
#include "melee/weapon_cofhammer"
#include "melee/weapon_cofspear"
#include "smgs/weapon_cofmp5k"
#include "smgs/weapon_cofuzi"
#include "shotguns/weapon_cofbenelli"
#include "rifles/weapon_cofl85"
#include "special/weapon_cofgolden"
#include "special/v_actions"

// Buymenu
#include "BuyMenu"

BuyMenu::BuyMenu g_CoFMenu;

void CoFRegister()
{
	//DO NOT MODIFY
	//CREATE YOUR OWN REGISTER FILE
	g_CoFMenu.RemoveItems();

	// Melees
	CoFKNIFE::POSITION = 11;
	CoFSB::POSITION = 12;
	CoFHAMMER::POSITION = 13;
	CoFBRANCH::POSITION = 14;
	CoFNIGHTSTICK::POSITION = 15;
	CoFSPEAR::POSITION = 16;
	CoFSH::POSITION = 17;
	CoFAXE::POSITION = 18;
	RegisterCoFKNIFE();
	RegisterCoFSWITCHBLADE();
	RegisterCoFHAMMER();
	RegisterCoFBRANCH();
	RegisterCoFNIGHTSTICK();
	RegisterCoFSPEAR();
	RegisterCoFSLEDGEHAMMER();
	RegisterCoFAXE();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Kitchen Knife", CoFKNIFEName(), 5, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Switchblade", CoFSWITCHBLADEName(), 7, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Branch", CoFBRANCHName(), 9, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Hammer", CoFHAMMERName(), 10, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Nightstick", CoFNIGHTSTICKName(), 14, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Spear", CoFSPEARName(), 20, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Sledgehammer", CoFSLEDGEHAMMERName(), 35, "primary", "melee" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "David Leatherhoff's Axe", CoFAXEName(), 45, "primary", "melee" ) );

	// Handguns
	CoFBERETTA::POSITION = 10;
	CoFGLOCK::POSITION = 11;
	CoFVP70::POSITION = 12;
	CoFREVOLVER::POSITION = 13;
	CoFP228::POSITION = 14;
	CoFP345::POSITION = 15;
	CoFGLOCK18::POSITION = 16;
	CoFDEAGLE::POSITION = 17;
	CoFANACONDA::POSITION = 18;
	RegisterCoFBERETTA();
	RegisterCoFGLOCK();
	RegisterCoFVP70();
	RegisterCoFREVOLVER();
	RegisterCoFP228();
	RegisterCoFP345();
	RegisterCoFGLOCK18();
	RegisterCoFDEAGLE();
	RegisterCoFANACONDA();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "M9 Beretta", CoFBERETTAName(), 10, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Glock 19", CoFGLOCKName(), 12, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "H&K VP-70", CoFVP70Name(), 15, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Taurus UL. Model 85 Revolver", CoFREVOLVERName(), 18, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "SIG P228", CoFP228Name(), 20, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Ruger P345", CoFP345Name(), 23, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Glock 18", CoFGLOCK18Name(), 25, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "IMI Desert Eagle", CoFDEAGLEName(), 30, "secondary", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Colt Anaconda", CoFANACONDAName(), 35, "secondary", "" ) );
	
	// Smgs
	CoFMP5::POSITION = 10;
	CoFTMP::POSITION = 11;
	CoFMP5K::POSITION = 13;
	CoFUZI::POSITION = 14;
	CoFM76::POSITION = 16;
	RegisterCoFMP5();
	RegisterCoFTMP();
	RegisterCoFMP5K();
	RegisterCoFUZI();
	RegisterCoFM76();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "H&K MP5", CoFMP5Name(), 21, "primary", "smg" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "B&T MP9", CoFTMPName(), 25, "primary", "smg" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "H&K MP5K", CoFMP5KName(), 27, "primary", "smg" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "IMI Uzi", CoFUZIName(), 30, "primary", "smg" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "S&W M76", CoFM76Name(), 35, "primary", "smg" ) );

	//Shotguns
	CoFBENELLI::POSITION = 12;
	CoFSHOTGUN::POSITION = 15;
	RegisterCoFBENELLI();
	RegisterCoFSHOTGUN();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Benelli Super M3", CoFBENELLIName(), 33, "primary", "shotgun" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Remington 870", CoFSHOTGUNName(), 36, "primary", "shotgun" ) );

	// Assault Rifles
	CoFM16::POSITION = 10;
	CoFFAMAS::POSITION = 11;
	CoFL85::POSITION = 13;
	CoFAK74::POSITION = 14;
	RegisterCoFM16();
	RegisterCoFFAMAS();
	RegisterCoFL85();
	RegisterCoFAK74();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Colt M16A2", CoFM16Name(), 25, "primary", "assault" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "FAMAS G2", CoFFAMASName(), 30, "primary", "assault" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Enfield L85A2", CoFL85Name(), 35, "primary", "assault" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "AKS-74", CoFAK74Name(), 40, "primary", "assault" ) );

	// Rifles
	CoFRIFLE::POSITION = 12;
	CoFG43::POSITION = 15;
	RegisterCoFRIFLE();
	RegisterCoFGEWEHR();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Lee-Enfield Mk.III", CoFRIFLEName(), 50, "primary", "rifle" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Walther Gewehr 43", CoFGEWEHRName(), 60, "primary", "rifle" ) );

	// Special Purpose
	CoFBOOKLASER::POSITION = 10;
	CoFCAMERA::POSITION = 11;
	CoFGOLDEN::POSITION = 12;
	RegisterCoFCAMERA();
	RegisterCoFBOOKLASER();
	RegisterCoFGOLDEN();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Simon's Book", CoFBOOKLASERName(), 150, "primary", "special" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Digital Camera", CoFCAMERAName(), 100, "primary", "special" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Golden Colt Anaconda", CoFGOLDENName(), 300, "primary", "special" ) );

	// Utility
	CoFSYRINGE::POSITION = 10;
	CoFLANTERN::POSITION = 10;
	RegisterCoFSYRINGE();
	RegisterCoFLANTERN();
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Healing Syringe", CoFSYRINGEName(), 5, "equipment", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "Lantern", CoFLANTERNName(), 7, "equipment", "" ) );

	// Ammo
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM Glock-19 Mag", CoFGLOCKAmmoName(), 3, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( ".45 ACP P345 Mag", CoFP345AmmoName(), 4, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( ".38 Taurus Box", CoFREVOLVERAmmoName(), 4, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "12 Gauge Shotgun Box", CoFBUCKSHOT::GetName(), 6, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( ".303 Enfield Box", CoFRIFLEAmmoName(), 5, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "7.92 Gewehr Mag", CoFGEWEHRAmmoName(), 8, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "5.56 M16 Mag", CoFM16AmmoName(), 5, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( ".50 AE Desert Eagle Mag", CoFDEAGLEAmmoName(), 7, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( ".454 Casull Clip", CoFANACONDAAmmoName(), 7, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "5.45 AK-74 Mag", CoFAK74AmmoName(), 9, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "5.56 Famas Mag", CoFFAMASAmmoName(), 6, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "5.56 L85 Mag", CoFL85AmmoName(), 6, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM P228 Mag", CoFP228AmmoName(), 2, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM M9 Beretta Mag", CoFBERETTAAmmoName(), 3, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM VP-70 Mag", CoFVP70AmmoName(), 4, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM Glock-18 Mag", CoFGLOCK18AmmoName(), 5, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM MP5 Mag", CoFMP5AmmoName(), 7, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM MP5K Mag", CoFMP5KAmmoName(), 7, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM MP9 Mag", CoFTMPAmmoName(), 7, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM UZI Mag", CoFUZIAmmoName(), 8, "ammo", "" ) );
	g_CoFMenu.AddItem( BuyMenu::BuyableItem( "9MM M76 Mag", CoFM76AmmoName(), 9, "ammo", "" ) );

	// For specific actions such as: Punching, swimming and flying
	RegisterCoFACTIONS();

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @cof_PlayerPreThink );
}

HookReturnCode cof_PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( pPlayer.m_hActiveItem.GetEntity() is null )
	{
		pPlayer.GiveNamedItem( "weapon_cofaction" );
		pPlayer.SelectItem( "weapon_cofaction" );
	}
	return HOOK_CONTINUE;
}

CClientCommand buy( "buy", "Opens the BuyMenu", @CoF_Buy );

void CoF_Buy( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	if( args.ArgC() == 1 )
	{
		g_CoFMenu.Show( pPlayer );
	}
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ args = pParams.GetArguments();
	
	if( args.ArgC() == 1 && args.Arg(0) == "buy" || args.Arg(0) == "/buy" )
	{
		pParams.ShouldHide = true;
		g_CoFMenu.Show( pPlayer );
	}
	else if( args.ArgC() == 2 && args.Arg(0) == "buy" || args.Arg(0) == "/buy" )
	{
		pParams.ShouldHide = true;
		bool bItemFound = false;
		string szItemName;
		uint uiCost;

		if( g_CoFMenu.m_Items.length() > 0 )
		{
			for( uint i = 0; i < g_CoFMenu.m_Items.length(); i++ )
			{
				if( "weapon_" + args.Arg(1) == g_CoFMenu.m_Items[i].EntityName || "ammo_" + args.Arg(1) == g_CoFMenu.m_Items[i].EntityName )
				{
					bItemFound = true;
					szItemName = g_CoFMenu.m_Items[i].EntityName;
					uiCost = g_CoFMenu.m_Items[i].Cost;
					break;
				}
				else
					bItemFound = false;
			}

			if( bItemFound )
			{
				if( pPlayer.pev.frags <= 0 )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Not enough money (frags) - Cost: $" + uiCost + "\n" );
				}
				else
				{ 
					if( uint(pPlayer.pev.frags) >= uiCost )
					{
						pPlayer.pev.frags -= uiCost;
						pPlayer.GiveNamedItem( szItemName );
					}
					else
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Not enough money (frags) - Cost: $" + uiCost + "\n" );
				}
			}
			else
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Invalid item: " + args.Arg(1) + "\n" );
		}
	}
	return HOOK_CONTINUE;
}