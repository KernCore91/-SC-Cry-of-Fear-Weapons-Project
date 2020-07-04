// Author: KernCore

#include "../base"

enum CoFNIGHTSTICKAnimations_e
{
	CoFNIGHTSTICK_IDLE1 = 0,
	CoFNIGHTSTICK_DRAW,
	CoFNIGHTSTICK_HOLSTER,
	CoFNIGHTSTICK_ATTACK1,
	CoFNIGHTSTICK_ATTACK2,
	CoFNIGHTSTICK_ATTACK3,
	CoFNIGHTSTICK_FIDGET1,
	CoFNIGHTSTICK_FIDGET2,
	CoFNIGHTSTICK_IDLE2,
	CoFNIGHTSTICK_FIDGET3,
	CoFNIGHTSTICK_SPRINT_TO,
	CoFNIGHTSTICK_SPRINT_IDLE,
	CoFNIGHTSTICK_SPRINT_FROM,
	CoFNIGHTSTICK_JUMP_TO,
	CoFNIGHTSTICK_JUMP_FROM
};

namespace CoFNIGHTSTICK
{
	// Models
	string NIGHTSTICK_W_MODEL   	= "models/cof/nstick/wld.mdl";
	string NIGHTSTICK_V_MODEL   	= "models/cof/nstick/vwm.mdl";
	string NIGHTSTICK_P_MODEL   	= "models/cof/nstick/wld.mdl";
	// Sounds
	const string NIGHTSTICK_S_HITB1   	= "cof/guns/nstick/hitb1.ogg";
	const string NIGHTSTICK_S_HITB2 	= "cof/guns/nstick/hitb2.ogg";
	const string NIGHTSTICK_S_HITW1 	= "cof/guns/nstick/hitw1.ogg";
	const string NIGHTSTICK_S_HITW2 	= "cof/guns/nstick/hitw2.ogg";
	const string NIGHTSTICK_S_SWNG  	= "cof/guns/nstick/swing.ogg";
	//weapon info
	const int NIGHTSTICK_WEIGHT  	= 10;
	uint NIGHTSTICK_DAMAGE      	= 45;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 10;
}

class weapon_cofnightstick : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	TraceResult m_trHit;

	// Other Sounds
	private array<string> nightstickSounds = {
		CoFNIGHTSTICK::NIGHTSTICK_S_HITB1,
		CoFNIGHTSTICK::NIGHTSTICK_S_HITB2,
		CoFNIGHTSTICK::NIGHTSTICK_S_HITW1,
		CoFNIGHTSTICK::NIGHTSTICK_S_HITW2,
		CoFNIGHTSTICK::NIGHTSTICK_S_SWNG
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFNIGHTSTICK::NIGHTSTICK_W_MODEL ) );
		self.m_iClip     	= -1;
		self.m_flCustomDmg 	= self.pev.dmg;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFNIGHTSTICK::NIGHTSTICK_W_MODEL );
		g_Game.PrecacheModel( CoFNIGHTSTICK::NIGHTSTICK_V_MODEL );
		g_Game.PrecacheModel( CoFNIGHTSTICK::NIGHTSTICK_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( nightstickSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofnightstick.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot   	= CoFNIGHTSTICK::SLOT;
		info.iPosition 	= CoFNIGHTSTICK::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= CoFNIGHTSTICK::NIGHTSTICK_WEIGHT;
		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFNIGHTSTICK::NIGHTSTICK_V_MODEL, CoFNIGHTSTICK::NIGHTSTICK_P_MODEL, CoFNIGHTSTICK_DRAW, "crowbar", 1 );
			DeploySleeve();
			float deployTime = 1.0f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return CommonAddToPlayer( pPlayer );
	}

	void Materialize()
	{
		BaseClass.Materialize();
		CommonMaterialize();
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );
		m_IsPullingBack = false;
		m_pPlayer.pev.viewmodel = string_t();
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( !m_IsPullingBack )
		{
			// We don't want the player to break/stop the animation or sequence.
			m_IsPullingBack = true;
			
			// We are pulling back our hammer
			self.SendWeaponAnim( CoFNIGHTSTICK_ATTACK1 + Math.RandomLong( 1, 2 ), 0, 0 );

			self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.3f;
		}
	}

	private string HitBodySounds()
	{
		string msz_Snd;
		switch( Math.RandomLong( 0, 1 ) )
		{
			case 0: msz_Snd = CoFNIGHTSTICK::NIGHTSTICK_S_HITB1;
				break;
			case 1: msz_Snd = CoFNIGHTSTICK::NIGHTSTICK_S_HITB2;
				break;
		}
		return msz_Snd;
	}

	private string HitWallSounds()
	{
		string msz_Snd;
		switch( Math.RandomLong( 0, 1 ) )
		{
			case 0: msz_Snd = CoFNIGHTSTICK::NIGHTSTICK_S_HITW1;
				break;
			case 1: msz_Snd = CoFNIGHTSTICK::NIGHTSTICK_S_HITW2;
				break;
		}
		return msz_Snd;
	}

	void DoHeavyAttack()
	{
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing; (Should be anim frames/fps - initial thinktime)
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 37, 0.54f, CoFNIGHTSTICK::NIGHTSTICK_DAMAGE, 1.0f - 0.3f, HitBodySounds(), HitWallSounds(), DMG_CLUB );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFNIGHTSTICK::NIGHTSTICK_S_SWNG, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.pev.punchangle.x = Math.RandomLong( 3, 4 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
		{
			case 0:	iAnim = CoFNIGHTSTICK_FIDGET1;
			break;

			case 1: iAnim = CoFNIGHTSTICK_FIDGET2;
			break;

			case 2: iAnim = CoFNIGHTSTICK_FIDGET3;
			break;

			case 3: iAnim = CoFNIGHTSTICK_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim, 0, 0 );

		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
	}
}

string CoFNIGHTSTICKName()
{
	return "weapon_cofnightstick";
}

void RegisterCoFNIGHTSTICK()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFNIGHTSTICKName(), CoFNIGHTSTICKName() );
	g_ItemRegistry.RegisterWeapon( CoFNIGHTSTICKName(), "cof/melee" );
}