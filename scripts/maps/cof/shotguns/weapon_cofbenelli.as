// Author: KernCore

#include "../base"
#include "ammo_12gauge"

enum CoFBENELLIAnimations_e
{
	CoFBENELLI_IDLE = 0,
	CoFBENELLI_DRAW,
	CoFBENELLI_HOLSTER,
	CoFBENELLI_DRAW_FIRST,
	CoFBENELLI_SHOOT1,
	CoFBENELLI_SHOOT2,
	CoFBENELLI_SHOOT_LAST,
	CoFBENELLI_SHOOT_EMPTY,
	CoFBENELLI_RELOAD_START,
	CoFBENELLI_RELOAD_START_EMPTY,
	CoFBENELLI_RELOAD_INSERT,
	CoFBENELLI_RELOAD_END,
	CoFBENELLI_IRON_IDLE,
	CoFBENELLI_IRON_SHOOT1,
	CoFBENELLI_IRON_SHOOT2,
	CoFBENELLI_IRON_SHOOT_LAST,
	CoFBENELLI_IRON_SHOOT_EMPTY,
	CoFBENELLI_IRON_TO,
	CoFBENELLI_IRON_FROM,
	CoFBENELLI_MELEE
};

namespace CoFBENELLI
{
	//models
	string BENELLI_W_MODEL 	= "models/cof/benelli/wrd.mdl";
	string BENELLI_V_MODEL 	= "models/cof/benelli/vwm.mdl";
	string BENELLI_P_MODEL 	= "models/cof/benelli/plr.mdl";
	//sounds
	const string BENELLI_SHOOT_SND 	= "cof/guns/benelli/shoot.ogg";
	const string BENELLI_EMPTY_SND 	= "cof/guns/benelli/empty.ogg";
	//weapon info
	const int BENELLI_MAX_CARRY  	= (p_Customizable) ? 180 : 125;
	const int BENELLI_MAX_CLIP   	= 8;
	const int BENELLI_DEFAULT_GIVE 	= BENELLI_MAX_CLIP * 3;
	const int BENELLI_WEIGHT     	= 20;
	uint BENELLI_DAMAGE          	= 4;
	const uint BENELLI_PELLETCOUNT 	= 8;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 6;
}

class weapon_cofbenelli : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private float m_flNextReload;
	private bool m_fShotgunReload;
	private bool m_WasDrawn;

	// Other Sounds
	private array<string> benelliSounds = {
		"cof/guns/benelli/insert.ogg",
		"cof/guns/benelli/pmpback.ogg",
		"cof/guns/benelli/pmpfwrd.ogg",
		"cof/guns/benelli/sinsert.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFBENELLI::BENELLI_W_MODEL );

		iAnimation       	= CoFBENELLI_MELEE;
		iAnimation2      	= CoFBENELLI_MELEE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		self.m_iDefaultAmmo	= CoFBENELLI::BENELLI_DEFAULT_GIVE;
		m_WasDrawn       	= false;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFBENELLI::BENELLI_W_MODEL );
		g_Game.PrecacheModel( CoFBENELLI::BENELLI_V_MODEL );
		g_Game.PrecacheModel( CoFBENELLI::BENELLI_P_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iShell = g_Game.PrecacheModel( mShellModel[6] ); //buckshot

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( benelliSounds );

		g_SoundSystem.PrecacheSound( CoFBENELLI::BENELLI_SHOOT_SND );
		g_SoundSystem.PrecacheSound( CoFBENELLI::BENELLI_EMPTY_SND );
		g_Game.PrecacheGeneric( "sound/" + CoFBENELLI::BENELLI_SHOOT_SND );
		g_Game.PrecacheGeneric( "sound/" + CoFBENELLI::BENELLI_EMPTY_SND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/shotgun/weapon_cofbenelli.txt" );
		g_Game.PrecacheGeneric( "events/" + "muzzle_cofSG.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFBENELLI::BENELLI_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFBENELLI::BENELLI_MAX_CLIP;
		info.iSlot  	= CoFBENELLI::SLOT;
		info.iPosition 	= CoFBENELLI::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFBENELLI::BENELLI_WEIGHT;

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
		float deployTime;
		bool bResult;
		{
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFBENELLI::BENELLI_V_MODEL, CoFBENELLI::BENELLI_P_MODEL, CoFBENELLI_DRAW_FIRST, "shotgun", 0 );
				deployTime = 2.15f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFBENELLI::BENELLI_V_MODEL, CoFBENELLI::BENELLI_P_MODEL, CoFBENELLI_DRAW, "shotgun", 0 );
				deployTime = 0.69f;
			}

			DeploySleeve();

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool CanDeploy()
	{
		return true;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		m_fShotgunReload = false;
		EffectsFOVOFF();
		canReload = false;

		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, CoFBENELLI::BENELLI_EMPTY_SND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}

		return false;
	}

	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, float flDamage )
	{
		TraceResult tr;
		float x, y;

		for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );

			Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 3072;

			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( pHit !is null )
					{
						g_WeaponFuncs.ClearMultiDamage();
						pHit.TraceAttack( m_pPlayer.pev, flDamage, vecEnd, tr, DMG_LAUNCH );
						g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
					}

					g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CUSTOMDAMAGE );

					if( tr.fInWater == 0.0 )
						water_bullet_effects(vecSrc, tr.vecEndPos);
					
					if( pHit is null || pHit.IsBSPModel() == true )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
				}
			}
		}
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFBENELLI_SHOOT_EMPTY : CoFBENELLI_IRON_SHOOT_EMPTY, 0, 0 );
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.775f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.775f;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.775f;

		Vector vecSrc   	= m_pPlayer.GetGunPosition();
		Vector vecAiming	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		--self.m_iClip;

		if( self.m_iClip > 0 )
		{
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFBENELLI_SHOOT1 + Math.RandomLong( 0, 1 ) : CoFBENELLI_IRON_SHOOT1 + Math.RandomLong( 0, 1 ), 0, 0 );
			SetThink( ThinkFunction(ShellShotEjectThink) );
			self.pev.nextthink = WeaponTimeBase() + 0.525;
		}
		else
		{
			SetThink( null );
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFBENELLI_SHOOT_LAST : CoFBENELLI_IRON_SHOOT_LAST, 0, 0 );
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		Vector VECTOR_CONE_SHOTGUN( Math.DegreesToRadians( Math.RandomFloat( 2.0, 2.25 ) ), Math.DegreesToRadians( Math.RandomFloat( 2.0, 2.25 ) ), 0.00 );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFBENELLI::BENELLI_SHOOT_SND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		m_pPlayer.FireBullets( CoFBENELLI::BENELLI_PELLETCOUNT, vecSrc, vecAiming, VECTOR_CONE_SHOTGUN, 3072, BULLET_PLAYER_CUSTOMDAMAGE, 0, CoFBENELLI::BENELLI_DAMAGE );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 ); // HEV suit - indicate out of ammo condition

		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_SHOTGUN, CoFBENELLI::BENELLI_PELLETCOUNT, CoFBENELLI::BENELLI_DAMAGE );

		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;

		CoFDynamicLight( m_pPlayer.EyePosition() + g_Engine.v_forward * 64, 18, 240, 180, 25, 1, 100 );

		m_pPlayer.pev.punchangle.y = Math.RandomFloat( -0.5, 0.5 );
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			m_pPlayer.pev.punchangle.x = Math.RandomLong( -6, -5 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			m_pPlayer.pev.punchangle.x = Math.RandomLong( -9, -8 );
		}
		//AngleRecoil( Math.RandomFloat( -1.0f, -0.5f ), Math.RandomFloat( -0.05f, 0.05f ) );
	}

	void ShellReloadEjectThink() //For the think function used in reload
	{
		SetThink( null );
		Vector vecShellVelocity, vecShellOrigin;
		CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 14, 2.55, -6.75, false, false );
		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHOTSHELL );
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		self.m_iClip = 1;
	}

	void ShellShotEjectThink()
	{
		SetThink( null );
		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 18, 6.25, -8.2, false, false );
		}
		else
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 18, 1.25, -4.75, false, false );
		}

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHOTSHELL );
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.13;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFBENELLI_IRON_TO, 0, 0 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFBENELLI_IRON_FROM, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( CheckButton() && m_fShotgunReload && m_flNextReload <= g_Engine.time )
		{
			self.SendWeaponAnim( CoFBENELLI_RELOAD_END, 0, 0 );
			self.m_flTimeWeaponIdle = g_Engine.time + 0.66;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
			m_fShotgunReload = false;
		}
		BaseClass.ItemPostFrame();
	}

	void Reload()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( iAmmo <= 0 || self.m_iClip == CoFBENELLI::BENELLI_MAX_CLIP )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFBENELLI_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			EffectsFOVOFF();
			canReload = true;
		}

		if( m_reloadTimer < g_Engine.time )
		{
			if( m_flNextReload > WeaponTimeBase() )
				return;

			// don't reload until recoil is done
			if( self.m_flNextPrimaryAttack > WeaponTimeBase() && !m_fShotgunReload )
			{
				m_fShotgunReload = false;
				return;
			}
			if( !m_fShotgunReload )
			{
				if( self.m_iClip <= 0 )
				{
					self.SendWeaponAnim( CoFBENELLI_RELOAD_START_EMPTY, 0, 0 );
					SetThink( ThinkFunction(ShellReloadEjectThink) );
					self.pev.nextthink = WeaponTimeBase() + 0.525;
					m_pPlayer.m_flNextAttack     	= 2.18f; //Always uses a relative time due to prediction
					self.m_flTimeWeaponIdle      	= WeaponTimeBase() + 2.18f;
					self.m_flNextPrimaryAttack   	= WeaponTimeBase() + 2.18f;
					self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 2.18f;
					self.m_flNextTertiaryAttack  	= WeaponTimeBase() + 2.18f;
				}
				else
				{
					self.SendWeaponAnim( CoFBENELLI_RELOAD_START, 0, 0 );
					m_pPlayer.m_flNextAttack     	= 0.65f; //Always uses a relative time due to prediction
					self.m_flTimeWeaponIdle      	= WeaponTimeBase() + 0.65f;
					self.m_flNextPrimaryAttack   	= WeaponTimeBase() + 0.65f;
					self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 0.65f;
					self.m_flNextTertiaryAttack  	= WeaponTimeBase() + 0.65f;
				}

				canReload = false;
				m_fShotgunReload = true;
				return;
			}
			else if( m_fShotgunReload )
			{
				if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
					return;

				if( self.m_iClip == CoFBENELLI::BENELLI_MAX_CLIP )
				{
					m_fShotgunReload = false;
					return;
				}

				self.SendWeaponAnim( CoFBENELLI_RELOAD_INSERT, 0, 0 );

				m_flNextReload              	= WeaponTimeBase() + 0.55f;
				self.m_flNextPrimaryAttack  	= WeaponTimeBase() + 0.55f;
				self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 0.55f;
				self.m_flNextTertiaryAttack 	= WeaponTimeBase() + 0.55f;
				self.m_flTimeWeaponIdle     	= WeaponTimeBase() + 0.55f;

				self.m_iClip += 1;
				iAmmo -= 1;
			}
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
		BaseClass.Reload();
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				//self.Reload();
			}
			else if( m_fShotgunReload )
			{
				if( self.m_iClip != CoFBENELLI::BENELLI_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( CoFBENELLI_RELOAD_END, 0, 0 );

					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 0.66;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
				}
			}
			else
			{
				self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFBENELLI_IRON_IDLE : CoFBENELLI_IDLE, 0, 0 );
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 23, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.0f, 23, true );
	}
}

string CoFBENELLIName()
{
	return "weapon_cofbenelli";
}

void RegisterCoFBENELLI()
{
	if( !g_CustomEntityFuncs.IsCustomEntity( CoFBUCKSHOT::GetName() ) )
		CoFBUCKSHOT::Register();

	g_CustomEntityFuncs.RegisterCustomEntity( CoFBENELLIName(), CoFBENELLIName() );
	g_ItemRegistry.RegisterWeapon( CoFBENELLIName(), "cof/shotgun", (p_Customizable) ? "ammo_12gauge" : "buckshot", "", CoFBUCKSHOT::GetName() );
}