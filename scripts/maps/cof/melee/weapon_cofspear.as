// Author: KernCore

#include "../base"

enum CoFSPEARAnimations_e
{
	CoFSPEAR_IDLE = 0,
	CoFSPEAR_STAB_START,
	CoFSPEAR_STAB_MISS,
	CoFSPEAR_STAB,
	CoFSPEAR_DRAW,
	CoFSPEAR_ELECTROCUTED
};

namespace CoFSPEAR
{
	// Models
	string SPEAR_W_MODEL	= "models/cof/spear/wld.mdl";
	string SPEAR_V_MODEL	= "models/cof/spear/vwm.mdl";
	string SPEAR_P_MODEL	= "models/cof/spear/wld.mdl";
	// Sounds
	const string SPEAR_SWING_S	= "cof/guns/spear/swing.ogg";
	const string SPEAR_HITB_S	= "cof/guns/spear/hitb.ogg";
	const string SPEAR_HITW_S	= "cof/guns/spear/hitw.ogg";
	//weapon info
	const int SPEAR_WEIGHT	= 5;
	uint SPEAR_DAMAGE    	= 65; // Swing
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 11;
}

class weapon_cofspear : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private array<string> spearSounds = {
		CoFSPEAR::SPEAR_SWING_S,
		CoFSPEAR::SPEAR_HITB_S,
		CoFSPEAR::SPEAR_HITW_S,
		"cof/guns/spear/electrocute.ogg"
	};

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFSPEAR::SPEAR_W_MODEL ) );
		self.m_iClip    	= -1;
		self.m_flCustomDmg 	= self.pev.dmg;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( CoFSPEAR::SPEAR_W_MODEL );
		g_Game.PrecacheModel( CoFSPEAR::SPEAR_V_MODEL );
		g_Game.PrecacheModel( CoFSPEAR::SPEAR_P_MODEL );

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( spearSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/melee/weapon_cofspear.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot   	= CoFSPEAR::SLOT;
		info.iPosition 	= CoFSPEAR::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iWeight 	= CoFSPEAR::SPEAR_WEIGHT;
		return true;
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

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFSPEAR::SPEAR_V_MODEL, CoFSPEAR::SPEAR_P_MODEL, CoFSPEAR_DRAW, "bow", 1 );
			DeploySleeve();
			float deployTime = 0.87f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
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
			
			// We are pulling back our spear
			self.SendWeaponAnim( CoFSPEAR_STAB_START, 0, 0 );
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
			
			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.35;
		}
	}

	void DoHeavyAttack()
	{
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFSPEAR::SPEAR_SWING_S, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		// Lets do another tracehull check for the animations
		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 50;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				EHandle hHit = g_EntityFuncs.Instance( tr.pHit );
				if( hHit.GetEntity() is null || hHit.GetEntity().IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			//Miss
			self.SendWeaponAnim( CoFSPEAR_STAB_MISS, 0, 0 );
		}
		else
		{
			//Hit
			self.SendWeaponAnim( CoFSPEAR_STAB, 0, 0 );
		}
		/* Params in order
		Distance;
		Attack Speed;
		Damage;
		Animation Timing; (Should be anim frames/fps - initial thinktime)
		Hit Body sounds;
		Hit Wall sounds;
		Damage Bits.
		*/
		HeavySmack( 50, (tr.flFraction >= 1.00) ? 0.7f : 1.0f, CoFSPEAR::SPEAR_DAMAGE, (tr.flFraction >= 1.00) ? 0.7f : 1.0f, CoFSPEAR::SPEAR_HITB_S, CoFSPEAR::SPEAR_HITW_S, DMG_CLUB | DMG_SLASH );

		m_pPlayer.pev.punchangle.z = (Math.RandomLong(0, 1) < 0.5) ? Math.RandomLong( -8, -4 ) : Math.RandomLong( 4, 8 );
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void ItemPreFrame()
	{
		if( m_pPlayer.pev.waterlevel > WATERLEVEL_DRY )
		{
			if( m_pPlayer.m_bitsDamageType & DMG_SHOCK != 0 )
			{
				SetThink( null );
				m_IsPullingBack = false;
				self.SendWeaponAnim( CoFSPEAR_ELECTROCUTED, 0, 0 );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "cof/guns/spear/electrocute.ogg", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
				m_pPlayer.m_flNextAttack = 2.3f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + 2.3f;
			}
		}
		BaseClass.ItemPreFrame();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CoFSPEAR_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 4, 5 );
	}
}

string CoFSPEARName()
{
	return "weapon_cofspear";
}

void RegisterCoFSPEAR()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFSPEARName(), CoFSPEARName() );
	g_ItemRegistry.RegisterWeapon( CoFSPEARName(), "cof/melee" );
}