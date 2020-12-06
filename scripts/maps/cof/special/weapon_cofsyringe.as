// Author: KernCore

#include "../base"

enum CoFSYRINGEAnimations_e
{
	CoFSYRINGE_IDLE = 0,
	CoFSYRINGE_DEPLOY,
	CoFSYRINGE_HOLSTER,
	CoFSYRINGE_USE,
	CoFSYRINGE_STAB,
	CoFSYRINGE_STAB_MISS
};

namespace CoFSYRINGE
{
	//models
	string SYRINGE_W_MODEL     	= "models/cof/syringe/wld.mdl";
	string SYRINGE_V_MODEL     	= "models/cof/syringe/vwm.mdl";
	string SYRINGE_P_MODEL     	= "models/cof/syringe/wld.mdl";
	//weapon info
	const int SYRINGE_MAX_CARRY      	= 10;
	const int SYRINGE_MAX_WEIGHT     	= 2;
	const int SYRINGE_DEFAULT_GIVE   	= 1;
	const int SYRINGE_MAX_HEAL       	= 80;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 0;
	uint POSITION 	= 5;
}

class weapon_cofsyringe : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private int max_health_give = CoFSYRINGE::SYRINGE_MAX_HEAL;
	private bool canStartHeal;
	private float m_healTime = 0;
	private array<string> syringeSounds = {
		"cof/guns/syringe/inject.ogg",
		"cof/guns/syringe/insert.ogg",
		"cof/guns/syringe/sleeve.ogg",
		"cof/guns/syringe/miss.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFSYRINGE::SYRINGE_W_MODEL );
		self.m_iDefaultAmmo = CoFSYRINGE::SYRINGE_DEFAULT_GIVE;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFSYRINGE::SYRINGE_W_MODEL );
		g_Game.PrecacheModel( CoFSYRINGE::SYRINGE_V_MODEL );
		g_Game.PrecacheModel( CoFSYRINGE::SYRINGE_P_MODEL );

		PrecacheSound( syringeSounds );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheModel( "sprites/cof/special/ammo_syringe.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "cof/special/ammo_syringe.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/special/weapon_cofsyringe.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFSYRINGE::SYRINGE_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot  	= CoFSYRINGE::SLOT;
		info.iPosition 	= CoFSYRINGE::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE | ITEM_FLAG_ESSENTIAL;
		info.iWeight 	= CoFSYRINGE::SYRINGE_MAX_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return CommonAddToPlayer( pPlayer );
	}

	void Materialize()
	{
		BaseClass.Materialize();
		//SetTouch( TouchFunction( this.CustomTouch ) );
		//SetUse( UseFunction( this.CustomUse ) );
	}

	void CustomTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() || !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if( pPlayer.HasNamedPlayerItem( "weapon_cofsyringe" ) !is null )
		{
			if( pPlayer.GiveAmmo( CoFSYRINGE::SYRINGE_DEFAULT_GIVE, "weapon_cofsyringe", CoFSYRINGE::SYRINGE_MAX_CARRY ) != -1 )
			{
				self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::ITEM_SOUND_PICK, 1, ATTN_NORM );
				self.AttachToPlayer( pPlayer );
				g_EntityFuncs.Remove( self );
			}
			return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::WEAPON_SOUND_GET, 1, ATTN_NORM );
		}
	}

	void CustomUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if( !pActivator.IsPlayer() || !pActivator.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

		if( pPlayer.HasNamedPlayerItem( "weapon_cofsyringe" ) !is null )
		{
			if( pPlayer.GiveAmmo( CoFSYRINGE::SYRINGE_DEFAULT_GIVE, "weapon_cofsyringe", CoFSYRINGE::SYRINGE_MAX_CARRY ) != -1 )
			{
				self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::ITEM_SOUND_PICK, 1, ATTN_NORM );
				self.AttachToPlayer( pPlayer );
				g_EntityFuncs.Remove( self );
			}
			return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::WEAPON_SOUND_GET, 1, ATTN_NORM );
		}
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = Deploy( CoFSYRINGE::SYRINGE_V_MODEL, CoFSYRINGE::SYRINGE_P_MODEL, CoFSYRINGE_DEPLOY, "hive", 1 );

			DeploySleeve();
			float deployTime = 1;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void DestroyThink()
	{
		SetThink( null );
		self.DestroyItem();
		g_EntityFuncs.Remove( self );
	}

	bool CanHaveDuplicates()
	{
		return true;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		SetThink( null );
		m_pPlayer.pev.viewmodel = string_t();
		canStartHeal = false;
		max_health_give = CoFSYRINGE::SYRINGE_MAX_HEAL;
		m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = 0;

		//g_Game.AlertMessage( at_console, "Ammo Reserve Holster1: " + m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + "\n" );

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 && !m_fDropped )
		{
			m_pPlayer.pev.weapons &= ~( 0 << g_ItemRegistry.GetIdForName( self.pev.classname ) );
			//g_Game.AlertMessage( at_console, "Ammo Reserve Holster2: " + m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + "\n" );
			SetThink( ThinkFunction( DestroyThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.health < m_pPlayer.pev.max_health )
		{
			self.SendWeaponAnim( CoFSYRINGE_USE, 0, 0 );
			SetThink( ThinkFunction( HealSelf ) );
			self.pev.nextthink = g_Engine.time + 1.5f;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 3.46f;
		}
	}

	TraceResult tr;
	EHandle eHit;

	void SecondaryAttack()
	{
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 35;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, ignore_glass, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() == true )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				eHit = g_EntityFuncs.Instance( tr.pHit );

				if( eHit.GetEntity().IsAlive() && (eHit.GetEntity().IsPlayerAlly() || eHit.GetEntity().IsPlayer()) && !eHit.GetEntity().IsMachine() )
				{
					if( eHit.GetEntity().pev.health < eHit.GetEntity().pev.max_health )
					{
						SetThink( ThinkFunction( HealPlayer ) );
						self.pev.nextthink = g_Engine.time + 1.55;
						m_pPlayer.SetMaxSpeedOverride( 0 ); //m_pPlayer.pev.maxspeed = -1;
						self.SendWeaponAnim( CoFSYRINGE_STAB, 0, 0 );
						self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 2.63f;
					}
					else
					{
						self.SendWeaponAnim( CoFSYRINGE_STAB_MISS, 0, 0 );
						self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.1f;
					}
				}
				else if( eHit.GetEntity() is null || eHit.GetEntity().IsBSPModel() || eHit.GetEntity().IsMachine() || 
						!eHit.GetEntity().IsAlive() || !eHit.GetEntity().IsPlayerAlly() )
				{
					self.SendWeaponAnim( CoFSYRINGE_STAB_MISS, 0, 0 );
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.1f;
				}
			}
		}
		else if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( CoFSYRINGE_STAB_MISS, 0, 0 );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.1f;
		}
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
	}

	void HealPlayer()
	{
		if( eHit.GetEntity().pev.health < eHit.GetEntity().pev.max_health )
		{
			float health_to_give;
			if( eHit.GetEntity().pev.max_health <= 100 )
			{
				health_to_give = eHit.GetEntity().pev.max_health - eHit.GetEntity().pev.health;
				eHit.GetEntity().pev.health += health_to_give;
			}
			else
			{
				eHit.GetEntity().pev.health += CoFSYRINGE::SYRINGE_MAX_HEAL;

				if( eHit.GetEntity().pev.health >= eHit.GetEntity().pev.max_health )
					eHit.GetEntity().pev.health = eHit.GetEntity().pev.max_health;
			}

			if( eHit.GetEntity().IsPlayer() )
			{
				CBasePlayer@ ePlayer = cast<CBasePlayer@>( eHit.GetEntity() );
				if( ePlayer.m_bitsDamageType & DMG_POISON != 0 )
					ePlayer.m_bitsDamageType &= ~DMG_POISON;
			}
			else if( eHit.GetEntity().IsMonster() )
			{
				CBaseMonster@ eMonster = cast<CBaseMonster@>( eHit.GetEntity() );
				if( eMonster.m_bitsDamageType & DMG_POISON != 0 )
					eMonster.m_bitsDamageType &= ~DMG_POISON;

				eMonster.m_hEnemy = null;
				for( uint i = 1; i <= 4; i++ )
					eMonster.PopEnemy();

				eMonster.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
				eMonster.ClearSchedule();
			}
			m_pPlayer.pev.frags += 5;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 1 )
		{
			SetThink( ThinkFunction( DeployAgain ) );
			self.pev.nextthink = g_Engine.time + 1.0f;
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = 0;
	}

	void DeployAgain()
	{
		self.SendWeaponAnim( CoFSYRINGE_DEPLOY, 0, 0 );
		DeploySleeve();
		m_pPlayer.SetAnimation( PLAYER_DEPLOY );
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0f;
	}

	void HealSelf()
	{
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		canStartHeal = true;
		m_healTime = g_Engine.time + 0.1;
		SetThink( null );
	}

	void ItemPreFrame()
	{
		if( canStartHeal && m_healTime < g_Engine.time )
		{
			SyringeSelfHeal();
			m_healTime = g_Engine.time + 0.1;
		}

		BaseClass.ItemPreFrame();
	}

	void SyringeSelfHeal()
	{
		if( max_health_give > 0 )
		{
			if( m_pPlayer.pev.health < m_pPlayer.pev.max_health )
				m_pPlayer.pev.health += 5;

			if( m_pPlayer.pev.health <= m_pPlayer.pev.max_health )
				max_health_give -= 5;
			else
				m_pPlayer.pev.health = m_pPlayer.pev.max_health;

			if( m_pPlayer.m_bitsDamageType & DMG_POISON != 0 )
				m_pPlayer.m_bitsDamageType &= ~DMG_POISON;
		}
		else if( max_health_give <= 0 )
		{
			canStartHeal = false;
			max_health_give = CoFSYRINGE::SYRINGE_MAX_HEAL;

			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
			{
				DeployAgain();
			}
			else
			{
				self.Holster();
			}
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CoFSYRINGE_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 6, 7 );
	}
}

string CoFSYRINGEName()
{
	return "weapon_cofsyringe";
}

void RegisterCoFSYRINGE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFSYRINGEName(), CoFSYRINGEName() );
	g_ItemRegistry.RegisterWeapon( CoFSYRINGEName(), "cof/special", "weapon_cofsyringe", "", "weapon_cofsyringe" );
}