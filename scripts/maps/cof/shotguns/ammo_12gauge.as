// Author: KernCore

#include "../base"

namespace CoFBUCKSHOT
{

string AMMO_MODEL = "models/cof/shotgun/box.mdl";

class Buckshot_12gauge : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, AMMO_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( AMMO_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, 12, (p_Customizable) ? 180 : 125, (p_Customizable) ? "ammo_12gauge" : "buckshot" );
	}
}

string GetName()
{
	return "ammo_12gauge";
}

void Register()
{
	g_Game.PrecacheModel( AMMO_MODEL );
	g_CustomEntityFuncs.RegisterCustomEntity( "CoFBUCKSHOT::Buckshot_12gauge", GetName() );
}

}