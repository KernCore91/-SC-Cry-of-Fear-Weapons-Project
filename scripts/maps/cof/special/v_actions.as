// Author: KernCore

#include "../base"

enum CoFACTIONSAnimations_e
{
	CoFACTION_EMPTYIDLE = 0,
	CoFACTION_SWIM,
	CoFACTION_SWIM_BACK,
	CoFACTION_SWIM_LEFT,
	CoFACTION_SWIM_RIGHT,
	CoFACTION_SPRINTIDLE,
	CoFACTION_FLY_START,
	CoFACTION_FLY_LOOP,
	CoFACTION_FLY_END,
	CoFACTION_PUNCH1,
	CoFACTION_PUNCH2,
	CoFACTION_PUNCH1_MISS,
	CoFACTION_PUNCH2_MISS
};

namespace ACTION
{
	string MODEL 	= "models/cof/v_actions.mdl";
	uint DAMAGE  	= 15;
	uint SLOT    	= 0;
	uint POSITION 	= 0;
}

class v_action : ScriptBasePlayerWeaponEntity, weapon_base
{
	private bool isJumping/*, isSwimming*/;
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private CScheduledFunction@ m_DeleteItemSched = null;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, string_t() );
		isJumping        	= false;
		/*isSwimming       	= false;*/
		self.m_iClip     	= -1;
		self.m_flCustomDmg 	= self.pev.dmg;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( ACTION::MODEL );
		g_Game.PrecacheGeneric( "sprites/" + "cof/v_action.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot   	= ACTION::SLOT;
		info.iPosition 	= ACTION::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= ITEM_FLAG_ESSENTIAL;
		info.iWeight 	= -1;
		return true;
	}

	bool CanDeploy()
	{
		return false;
	}

	bool Deploy()
	{
		/* Since we cannot let the player draw the weapon through conventional means
		// We'll set the player's viewmodel to that of the weapon
		// Avoiding a null pointer in CanDeploy()*/

		self.pev.viewmodel = ACTION::MODEL;
		self.SendWeaponAnim( CoFACTION_EMPTYIDLE );
		m_pPlayer.pev.viewmodel = ACTION::MODEL;
		m_pPlayer.m_szAnimExtension = string_t();
		m_pPlayer.m_flNextAttack = 0.5f;
		return true;
	}

	CBasePlayerItem@ DropItem() // Doesn't let the player drop the weapon
	{
		return null;
	}

	bool CanHolster()
	{
		return true;
	}

	~v_action()
	{
		g_Scheduler.RemoveTimer( m_DeleteItemSched );
		@m_DeleteItemSched = @null;
	}

	void OnDestroy()
	{
		g_Scheduler.RemoveTimer( m_DeleteItemSched );
		@m_DeleteItemSched = @null;
	}

	void PostDropItem( CBasePlayer@ pPlayer )
	{
		CBaseEntity@ pWeaponbox = null;

		if( self.pev.owner !is null )
			@pWeaponbox = g_EntityFuncs.Instance( self.pev.owner );

		if( pWeaponbox is null || self.pev.owner is null )
		{
			g_Scheduler.RemoveTimer( m_DeleteItemSched );
			@m_DeleteItemSched = @null;
			return;
		}

		if( !pWeaponbox.pev.ClassNameIs( self.pev.classname ) )
			return;

		// Remove the 'actual' dropped weapon..
		g_EntityFuncs.Remove( pWeaponbox );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		// Don't let the player drop the weapon when he dies
		if( !m_pPlayer.IsAlive() )
		{
			if( m_DeleteItemSched !is null )
				g_Scheduler.RemoveTimer( m_DeleteItemSched );

			@m_DeleteItemSched = g_Scheduler.SetTimeout( @this, "PostDropItem", 0.1, @m_pPlayer );
		}

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( !isJumping /*|| !isSwimming*/ )
		{
			//HeavySmack( 32, 0.56f, ACTION::DAMAGE + Math.RandomLong( 0, 2 ), 0.63f, CoFCOMMON::MELEE_P_SOUND_HIT, CoFCOMMON::MELEE_P_SOUND_HIT, DMG_CLUB );
			Swing();
			DeploySleeve();
			self.SendWeaponAnim( CoFACTION_PUNCH2_MISS, 0, 0 );
			m_pPlayer.pev.punchangle.z = Math.RandomLong( 6, 5 );
		}
	}

	void SecondaryAttack()
	{
		if( !isJumping /*|| !isSwimming*/ )
		{
			//HeavySmack( 32, 0.56f, ACTION::DAMAGE + Math.RandomLong( 0, 2 ), 0.63f, CoFCOMMON::MELEE_P_SOUND_HIT, CoFCOMMON::MELEE_P_SOUND_HIT, DMG_CLUB );
			Swing();
			DeploySleeve();
			self.SendWeaponAnim( CoFACTION_PUNCH1_MISS, 0, 0 );
			m_pPlayer.pev.punchangle.z = Math.RandomLong( -6, -5 );
		}
	}

	private bool Swing()
	{
		bool fDidHit = false;

		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

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
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.56f;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.63f;
			//Miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			//Hit
			fDidHit = true;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			EHandle hEntity = g_EntityFuncs.Instance( tr.pHit );

			if( hEntity.GetEntity() !is null )
			{
				g_WeaponFuncs.ClearMultiDamage();
				if( !hEntity.GetEntity().IsBSPModel() )
				{
					if( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
					{
						hEntity.GetEntity().TraceAttack( m_pPlayer.pev, ACTION::DAMAGE, g_Engine.v_forward, tr, DMG_CLUB );
					}
					else
					{
						hEntity.GetEntity().TraceAttack( m_pPlayer.pev, ACTION::DAMAGE / 2, g_Engine.v_forward, tr, DMG_CLUB );
					}
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}
			}

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;
			if( hEntity.GetEntity() !is null )
			{
				self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.63f;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.63f;
				if( hEntity.GetEntity().Classify() != CLASS_NONE && hEntity.GetEntity().Classify() != CLASS_MACHINE && hEntity.GetEntity().BloodColor() != DONT_BLEED )
				{
					if( hEntity.GetEntity().IsPlayer() ) // lets pull them
					{
						hEntity.GetEntity().pev.velocity = hEntity.GetEntity().pev.velocity + ( self.pev.origin - hEntity.GetEntity().pev.origin ).Normalize() * 120;
					}

					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFCOMMON::MELEE_P_SOUND_HIT, 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

					m_pPlayer.m_iWeaponVolume = 128;
					if( !hEntity.GetEntity().IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CROWBAR );

				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.
				fvolbar = 1;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFCOMMON::MELEE_P_SOUND_HIT, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}
		}

		return fDidHit;
	}

	void ItemPreFrame()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD /*&& !isSwimming*/ )
		{
			if( m_pPlayer.pev.button & IN_FORWARD != 0 )
			{
				self.SendWeaponAnim( CoFACTION_SWIM, 0, 0 );
				m_pPlayer.m_flNextAttack = 1.46f;
				//self.m_flTimeWeaponIdle = g_Engine.time + 1.46f;
				//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 3.0;
			}
			else if( m_pPlayer.pev.button & IN_BACK != 0 )
			{
				self.SendWeaponAnim( CoFACTION_SWIM_BACK, 0, 0 );
				m_pPlayer.m_flNextAttack = 1.2f;
				//self.m_flTimeWeaponIdle = g_Engine.time + 1.2f;
				//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.5;
			}
			else if( m_pPlayer.pev.button & IN_MOVELEFT != 0 )
			{
				self.SendWeaponAnim( CoFACTION_SWIM_LEFT, 0, 0 );
				m_pPlayer.m_flNextAttack = 1.46f;
			}
			else if( m_pPlayer.pev.button & IN_MOVERIGHT != 0 )
			{
				self.SendWeaponAnim( CoFACTION_SWIM_RIGHT, 0, 0 );
				m_pPlayer.m_flNextAttack = 1.46f;
			}
			self.m_flTimeWeaponIdle = g_Engine.time + 0.3f;
			//isSwimming = true;
		}

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_DRY )
		{
			//isSwimming = false;
			if( !(m_pPlayer.pev.flags & FL_ONGROUND != 0) )
			{
				if( !m_pPlayer.IsOnLadder() )
				{
					TraceResult tr;
					g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + Vector( 0, 0, -128 ), dont_ignore_monsters, 
						(m_pPlayer.pev.flags & FL_DUCKING != 0) ? head_hull : human_hull, m_pPlayer.edict(), tr );
	
					if( tr.flFraction >= 1.0 && !isJumping )
					{
						if( g_EngineFuncs.PointContents( tr.vecEndPos ) != CONTENTS_WATER )
						{
							if( m_pPlayer.m_flFallVelocity >= 256 )
							{
								self.SendWeaponAnim( CoFACTION_FLY_START, 0, 0 );
								m_pPlayer.m_flNextAttack = 0.3f;
								self.m_flTimeWeaponIdle = g_Engine.time + 0.3f;
								isJumping = true;
							}
						}
					}
				}
			}
		}
		BaseClass.ItemPreFrame();
	}

	void ItemPostFrame()
	{
		if( (m_pPlayer.pev.flags & FL_ONGROUND != 0 || m_pPlayer.pev.waterlevel > WATERLEVEL_DRY || m_pPlayer.IsOnLadder()) && isJumping == true )
		{
			isJumping = false;
			self.SendWeaponAnim( CoFACTION_FLY_END, 0, 0 );
			m_pPlayer.m_flNextAttack = 0.13f;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.13f;
		}

		/*if( isSwimming && m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD )
		{
			isSwimming = false;
		}*/

		BaseClass.ItemPostFrame();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( isJumping == true )
		{
			//g_Game.AlertMessage( at_console, "Fall Velocity: " + m_pPlayer.m_flFallVelocity + "\n" );
			self.SendWeaponAnim( CoFACTION_FLY_LOOP, 0, 0 );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.63f;
		}
		else
		{
			self.SendWeaponAnim( CoFACTION_EMPTYIDLE, 0, 0 );
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 1, 2 );
		}
	}
}

void RegisterCoFACTIONS()
{
	//g_Scheduler.ClearTimerList();
	g_CustomEntityFuncs.RegisterCustomEntity( "v_action", "v_action" );
	g_ItemRegistry.RegisterWeapon( "v_action", "cof" );
}