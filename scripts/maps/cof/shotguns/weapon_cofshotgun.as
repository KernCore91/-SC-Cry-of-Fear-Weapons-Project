// Author: KernCore

#include "../base"
#include "ammo_12gauge"

enum CoFSHOTGUNAnimations_e
{
	CoFSHOTGUN_IDLE1 = 0,
	CoFSHOTGUN_SHOOT,
	CoFSHOTGUN_RELOAD_START,
	CoFSHOTGUN_RELOAD_INSERT,
	CoFSHOTGUN_RELOAD_END,
	CoFSHOTGUN_RELOAD_END_NOSHOOT,
	CoFSHOTGUN_DRAW,
	CoFSHOTGUN_HOLSTER,
	CoFSHOTGUN_SPRINT_TO,
	CoFSHOTGUN_SPRINT_IDLE,
	CoFSHOTGUN_SPRINT_FROM,
	CoFSHOTGUN_FIDGET1,
	CoFSHOTGUN_FIDGET2,
	CoFSHOTGUN_FIDGET3,
	CoFSHOTGUN_IRON_TO,
	CoFSHOTGUN_IRON_IDLE,
	CoFSHOTGUN_IRON_SHOOT,
	CoFSHOTGUN_IRON_FROM,
	CoFSHOTGUN_MELEE,
	CoFSHOTGUN_SUICIDE
};

namespace CoFSHOTGUN
{
	//models
	string SHOTGUN_W_MODEL 	= "models/cof/shotgun/wrd.mdl";
	string SHOTGUN_V_MODEL 	= "models/cof/shotgun/vwm.mdl";
	string SHOTGUN_P_MODEL 	= "models/cof/shotgun/plr.mdl";
	//sounds
	const string SHOTGUN_SHOOT_SND 	= "cof/guns/shotgun/shoot.ogg";
	//weapon info
	const int SHOTGUN_MAX_CARRY  	= (p_Customizable) ? 180 : 125;
	const int SHOTGUN_MAX_CLIP   	= 5;
	const int SHOTGUN_DEFAULT_GIVE 	= SHOTGUN_MAX_CLIP * 3;
	const int SHOTGUN_WEIGHT     	= 20;
	uint SHOTGUN_DAMAGE          	= 6;
	const uint SHOTGUN_PELLETCOUNT 	= 8;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 9;
}

class weapon_cofshotgun : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private float m_flNextReload;
	private bool m_fShotgunReload, m_AmmoDry;

	// Other Sounds
	private array<string> shotgunSounds = {
		"cof/guns/shotgun/insert.ogg",
		"cof/guns/shotgun/pmpback.ogg",
		"cof/guns/shotgun/pmpfwrd.ogg",
		"cof/guns/shotgun/pmpseq.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFSHOTGUN::SHOTGUN_W_MODEL );

		iAnimation      	= CoFSHOTGUN_MELEE;
		iAnimation2     	= CoFSHOTGUN_MELEE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		self.m_iDefaultAmmo	= CoFSHOTGUN::SHOTGUN_DEFAULT_GIVE;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFSHOTGUN::SHOTGUN_W_MODEL );
		g_Game.PrecacheModel( CoFSHOTGUN::SHOTGUN_V_MODEL );
		g_Game.PrecacheModel( CoFSHOTGUN::SHOTGUN_P_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iShell = g_Game.PrecacheModel( mShellModel[6] ); //buckshot

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( shotgunSounds );

		g_SoundSystem.PrecacheSound( CoFSHOTGUN::SHOTGUN_SHOOT_SND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFSHOTGUN::SHOTGUN_SHOOT_SND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/shotgun/weapon_cofshotgun.txt" );
		g_Game.PrecacheGeneric( "events/" + "muzzle_cofSG.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFSHOTGUN::SHOTGUN_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFSHOTGUN::SHOTGUN_MAX_CLIP;
		info.iSlot  	= CoFSHOTGUN::SLOT;
		info.iPosition 	= CoFSHOTGUN::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFSHOTGUN::SHOTGUN_WEIGHT;

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
			bResult = Deploy( CoFSHOTGUN::SHOTGUN_V_MODEL, CoFSHOTGUN::SHOTGUN_P_MODEL, CoFSHOTGUN_DRAW, "shotgun", 0 );

			DeploySleeve();

			float deployTime = 1.0f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			if( m_AmmoDry && self.m_iClip > 0 )
			{
				SetThink( ThinkFunction( UndryThink ) );
				self.pev.nextthink = g_Engine.time + deployTime;
			}
			return bResult;
		}
	}

	void UndryThink()
	{
		self.SendWeaponAnim( CoFSHOTGUN_RELOAD_END_NOSHOOT, 0, 0 );
		m_AmmoDry = false;
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.66;
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, EMPTY_SHOOT_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
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
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.775f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.775f;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.775f;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFSHOTGUN_IRON_SHOOT, 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFSHOTGUN_SHOOT, 0, 0 );
		}

		Vector vecSrc   	= m_pPlayer.GetGunPosition();
		Vector vecAiming	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		Vector VECTOR_CONE_SHOTGUN( Math.DegreesToRadians( Math.RandomFloat( 2.0, 3.0 ) ), Math.DegreesToRadians( Math.RandomFloat( 2.0, 3.0 ) ), 0.00  );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFSHOTGUN::SHOTGUN_SHOOT_SND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		m_pPlayer.FireBullets( CoFSHOTGUN::SHOTGUN_PELLETCOUNT, vecSrc, vecAiming, VECTOR_CONE_SHOTGUN, 3072, BULLET_PLAYER_CUSTOMDAMAGE, 0, CoFSHOTGUN::SHOTGUN_DAMAGE );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 ); // HEV suit - indicate out of ammo condition

		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_SHOTGUN, CoFSHOTGUN::SHOTGUN_PELLETCOUNT, CoFSHOTGUN::SHOTGUN_DAMAGE );

		if( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 5.0;

		CoFDynamicLight( m_pPlayer.EyePosition() + g_Engine.v_forward * 64, 18, 240, 180, 25, 1, 100 );

		m_pPlayer.pev.punchangle.y = Math.RandomFloat( -0.5, 0.5 );
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			m_pPlayer.pev.punchangle.x = Math.RandomLong( -5, -4 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			m_pPlayer.pev.punchangle.x = Math.RandomLong( -8, -7 );
		}
		//AngleRecoil( Math.RandomFloat( -1.0f, -0.5f ), Math.RandomFloat( -0.05f, 0.05f ) );

		SetThink( ThinkFunction(BulletEjectThink) );
		self.pev.nextthink = WeaponTimeBase() + 0.46;
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
				self.SendWeaponAnim( CoFSHOTGUN_IRON_TO, 0, 0 );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFSHOTGUN_IRON_FROM, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void Reload()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( iAmmo <= 0 || self.m_iClip == CoFSHOTGUN::SHOTGUN_MAX_CLIP )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFSHOTGUN_IRON_FROM, 0, 0 );
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
				self.SendWeaponAnim( CoFSHOTGUN_RELOAD_START, 0, 0 );
				canReload = false;
				m_pPlayer.m_flNextAttack 	= 0.5; //Always uses a relative time due to prediction
				self.m_flTimeWeaponIdle     	= WeaponTimeBase() + 0.5;
				self.m_flNextPrimaryAttack  	= WeaponTimeBase() + 0.5;
				self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 0.5;
				self.m_flNextTertiaryAttack 	= WeaponTimeBase() + 0.5;
				m_fShotgunReload = true;
				return;
			}
			else if( m_fShotgunReload )
			{
				if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
					return;

				if( self.m_iClip == CoFSHOTGUN::SHOTGUN_MAX_CLIP )
				{
					m_fShotgunReload = false;
					return;
				}

				self.SendWeaponAnim( CoFSHOTGUN_RELOAD_INSERT, 0, 0 );

				m_flNextReload              	= WeaponTimeBase() + 0.66;
				self.m_flNextPrimaryAttack  	= WeaponTimeBase() + 0.66;
				self.m_flNextSecondaryAttack 	= WeaponTimeBase() + 0.66;
				self.m_flNextTertiaryAttack 	= WeaponTimeBase() + 0.66;
				self.m_flTimeWeaponIdle     	= WeaponTimeBase() + 0.66;

				self.m_iClip += 1;
				iAmmo -= 1;
			}
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
		BaseClass.Reload();
	}

	void ItemPreFrame()
	{
		if( self.m_iClip == 0 )
			m_AmmoDry = true;

		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void ItemPostFrame()
	{
		// Checks if the player pressed one of the attack buttons, stops the reload and then attack
		if( CheckButton() && m_fShotgunReload && m_flNextReload <= g_Engine.time )
		{
			self.SendWeaponAnim( (m_AmmoDry == true && self.m_iClip != 0) ? CoFSHOTGUN_RELOAD_END_NOSHOOT : CoFSHOTGUN_RELOAD_END, 0, 0 );
			if( self.m_iClip > 0 )
			{
				m_AmmoDry = false;
			}
			self.m_flTimeWeaponIdle = (m_AmmoDry == false) ? g_Engine.time + 0.66 : g_Engine.time + 0.5;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
			m_fShotgunReload = false;
		}
		BaseClass.ItemPostFrame();
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
				if( self.m_iClip != CoFSHOTGUN::SHOTGUN_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( (m_AmmoDry == true) ? CoFSHOTGUN_RELOAD_END_NOSHOOT : CoFSHOTGUN_RELOAD_END, 0, 0 );
					if( self.m_iClip > 0 )
					{
						m_AmmoDry = false;
					}

					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = (m_AmmoDry == false) ? g_Engine.time + 0.66 : g_Engine.time + 0.5;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
				}
			}
			else
			{
				int iAnim;
				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 3 ) )
				{
					case 0:
					iAnim = (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFSHOTGUN_IRON_IDLE : CoFSHOTGUN_IDLE1;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + (60.0/12.0);
					break;

					case 1:
					iAnim = (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFSHOTGUN_IRON_IDLE : CoFSHOTGUN_FIDGET1;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
					break;

					case 2:
					iAnim = (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFSHOTGUN_IRON_IDLE : CoFSHOTGUN_FIDGET2;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
					break;

					case 3:
					iAnim = (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFSHOTGUN_IRON_IDLE : CoFSHOTGUN_FIDGET3;
					self.m_flTimeWeaponIdle = WeaponTimeBase() + (20.0/9.0);
					break;
				}
				self.SendWeaponAnim( iAnim, 0, 0 );
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

	void BulletEjectThink()
	{
		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 16, 6, -8, false, false );
		}
		else
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 16, 0, -5, false, false );
		}

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHOTSHELL );
	}
}

string CoFSHOTGUNName()
{
	return "weapon_cofshotgun";
}

void RegisterCoFSHOTGUN()
{
	if( !g_CustomEntityFuncs.IsCustomEntity( CoFBUCKSHOT::GetName() ) )
		CoFBUCKSHOT::Register();

	g_CustomEntityFuncs.RegisterCustomEntity( CoFSHOTGUNName(), CoFSHOTGUNName() );
	g_ItemRegistry.RegisterWeapon( CoFSHOTGUNName(), "cof/shotgun", (p_Customizable) ? "ammo_12gauge" : "buckshot", "", CoFBUCKSHOT::GetName() );
}