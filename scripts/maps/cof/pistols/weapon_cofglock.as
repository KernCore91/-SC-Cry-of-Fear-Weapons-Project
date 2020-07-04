// Author: KernCore

#include "../base"

enum CoFGLOCKAnimations_e
{
	CoFGLOCK_IDLE = 0,
	CoFGLOCK_IDLE_NOSHOOT,
	CoFGLOCK_SHOOT1,
	CoFGLOCK_SHOOT1_EMPTY,
	CoFGLOCK_RELOAD,
	CoFGLOCK_RELOAD_NOSHOOT,
	CoFGLOCK_DRAW,
	CoFGLOCK_DRAW_NOSHOOT,
	CoFGLOCK_HOLSTER,
	CoFGLOCK_HOLSTER_NOSHOOT,
	CoFGLOCK_SPRINT_TO,
	CoFGLOCK_SPRINT_TO_NOSHOOT,
	CoFGLOCK_SPRINT_IDLE,
	CoFGLOCK_SPRINT_IDLE_NOSHOOT,
	CoFGLOCK_SPRINT_FROM,
	CoFGLOCK_SPRINT_FROM_NOSHOOT,
	CoFGLOCK_SUICIDE,
	CoFGLOCK_SWITCH_ON,
	CoFGLOCK_SWITCH_OFF,
	CoFGLOCK_SWITCH_ON_NOSHOOT,
	CoFGLOCK_SWITCH_OFF_NOSHOOT,
	CoFGLOCK_SUICIDE_NOSHOOT,
	CoFGLOCK_SHOOT_NOSHOOT,
	CoFGLOCK_FIDGET1,
	CoFGLOCK_FIDGET1_NOSHOOT,
	CoFGLOCK_FIDGET2,
	CoFGLOCK_FIDGET2_NOSHOOT,
	CoFGLOCK_FIDGET3,
	CoFGLOCK_FIDGET3_NOSHOOT,
	CoFGLOCK_MELEE,
	CoFGLOCK_MELEE_NOSHOOT,
	CoFGLOCK_DRAW_FIRST,
	CoFGLOCK_IRON_TO,
	CoFGLOCK_IRON_TO_NOSHOOT,
	CoFGLOCK_IRON_IDLE,
	CoFGLOCK_IRON_IDLE_NOSHOOT,
	CoFGLOCK_IRON_SHOOT,
	CoFGLOCK_IRON_SHOOT_NOSHOOT,
	CoFGLOCK_IRON_FROM,
	CoFGLOCK_IRON_FROM_NOSHOOT,
	CoFGLOCK_IRON_SHOOT_EMPTY,
	CoFGLOCK_JUMP_TO,
	CoFGLOCK_JUMP_TO_EMPTY,
	CoFGLOCK_JUMP_FROM,
	CoFGLOCK_JUMP_FROM_NOSHOOT,
	CoFGLOCK_IRON_SWITCH_ON,
	CoFGLOCK_IRON_SWITCH_OFF,
	CoFGLOCK_IRON_SWITCH_ON_NOSHOOT,
	CoFGLOCK_IRON_SWITCH_OFF_NOSHOOT
};

enum CoFLASERMODE_e
{
	CoF_MODE_LASEROFF = 0,
	CoF_MODE_LASERON
};

enum CoFGLOCKBodyGroups_e
{
	CoFGLOCKBD_LASEROFF = 0,
	CoFGLOCKBD_LASERON
};

namespace CoFGLOCK
{
	//models
	string GLOCK_W_MODEL        	= "models/cof/glock/wrd.mdl";
	string GLOCK_V_MODEL        	= "models/cof/glock/vwm.mdl";
	string GLOCK_P_MODEL        	= "models/cof/glock/plr.mdl";
	string GLOCK_A_MODEL        	= "models/cof/glock/mag.mdl";
	string GLOCK_MAGEMPTY_MODEL 	= "models/cof/glock/mag_e.mdl";
	//sounds
	const string GLOCK_SHOOT_SOUND  	= "cof/guns/glock/shoot.ogg";
	//weapon information
	const int GLOCK_MAX_CARRY    	= (p_Customizable) ? 360 : 250;
	const int GLOCK_MAX_CLIP     	= 15;
	const int GLOCK_DEFAULT_GIVE 	= GLOCK_MAX_CLIP * 2;
	const int GLOCK_WEIGHT       	= 17;
	uint GLOCK_DAMAGE             	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 1;
	uint POSITION 	= 5;
}

class weapon_cofglock : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	bool m_WasDrawn;
	int m_iGlockMagEmpty;
	int g_iMode_laser; // Mode for Laser
	int bd_GlockLaserMode; // Set the bodygroups for the laser
	float e_usetimer;
	int mag_counter;

	// Other Sounds
	private array<string> glockSounds = {
		"cof/guns/glock/maghit.ogg",
		"cof/guns/glock/magin.ogg",
		"cof/guns/glock/magout.ogg",
		"cof/guns/glock/rack.ogg",
		"cof/guns/glock/slide.ogg",
		"cof/guns/glock/switch.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFGLOCK::GLOCK_W_MODEL );
		
		self.m_iDefaultAmmo = CoFGLOCK::GLOCK_DEFAULT_GIVE;
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
		m_WasDrawn = false;
		mag_counter = CoFGLOCK::GLOCK_MAX_CLIP;

		iAnimation  = CoFGLOCK_MELEE;
		iAnimation2 = CoFGLOCK_MELEE_NOSHOOT;
		mIsLaserActivated = false;
		e_usetimer = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFGLOCK::GLOCK_W_MODEL );
		g_Game.PrecacheModel( CoFGLOCK::GLOCK_V_MODEL );
		g_Game.PrecacheModel( CoFGLOCK::GLOCK_P_MODEL );
		g_Game.PrecacheModel( CoFGLOCK::GLOCK_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		g_Game.PrecacheModel( LASER_SPRITE );
		m_iGlockMagEmpty	= g_Game.PrecacheModel( CoFGLOCK::GLOCK_MAGEMPTY_MODEL );
		m_iShell        	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( glockSounds );

		g_SoundSystem.PrecacheSound( CoFGLOCK::GLOCK_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFGLOCK::GLOCK_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );

		g_Game.PrecacheGeneric( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/pistol/weapon_cofglock.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFGLOCK::GLOCK_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFGLOCK::GLOCK_MAX_CLIP;
		info.iSlot  	= CoFGLOCK::SLOT;
		info.iPosition 	= CoFGLOCK::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFGLOCK::GLOCK_WEIGHT;

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
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, EMPTY_SHOOT_SOUND, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}

		return false;
	}
	
	bool Deploy()
	{
		float deployTime;
		bool bResult;
		{
			LasersightsSpr( FiremodesPos, -1 );
			FiremodesTxt();

			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFGLOCK::GLOCK_V_MODEL, CoFGLOCK::GLOCK_P_MODEL, CoFGLOCK_DRAW_FIRST, "onehanded", bd_GlockLaserMode );
				deployTime = 2.3f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFGLOCK::GLOCK_V_MODEL, CoFGLOCK::GLOCK_P_MODEL, (self.m_iClip == 0) ? CoFGLOCK_DRAW_NOSHOOT : CoFGLOCK_DRAW, "onehanded", bd_GlockLaserMode );
				deployTime = 1;
			}

			// if the laser was previously on, make it apear again on deploy
			if( g_iMode_laser == CoF_MODE_LASERON )
			{
				if( pdot is null )
				{
					LaserConfigs();
				}
				mIsLaserActivated = true;
			}

			DeploySleeve();

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = e_usetimer = g_Engine.time + deployTime;
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
		EffectsFOVOFF();
		canReload = false;
		// Make the laser dot dissapear after the weapon was holstered
		if( pdot !is null )
		{
			g_EntityFuncs.Remove( pdot );
		}
		mIsLaserActivated = false;
		@pdot = @null;
		SetThink( null );
		LasersightsSpr( FiremodesPos, 0, 0 );

		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFGLOCK_IRON_SHOOT_NOSHOOT : CoFGLOCK_SHOOT_NOSHOOT, 0, bd_GlockLaserMode );
			return;
		}

		mag_counter--;
		
		self.m_flNextPrimaryAttack = e_usetimer = WeaponTimeBase() + 0.119;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFGLOCK::GLOCK_SHOOT_SOUND, false, CoFGLOCK::GLOCK_DAMAGE, vecCone, (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD) ? 3072 : 8192, false, DMG_GENERIC );

		float m_iPunchAngle;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.50f, -1.00f ) : Math.RandomFloat( -2.25f, -1.75f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.50f, -2.00f ) : Math.RandomFloat( -3.00f, -2.75f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.2, 0.2 ) );
		
		if( g_iMode_ironsights == CoF_MODE_AIMED )
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_IRON_SHOOT : CoFGLOCK_IRON_SHOOT_EMPTY, 0, bd_GlockLaserMode );
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_SHOOT1 : CoFGLOCK_SHOOT1_EMPTY, 0, bd_GlockLaserMode );

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 5, -7, false, false );
		}
		else
		{
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 23, 0, -2, false, false );
		}

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void ActivateThink()
	{
		if( !mIsLaserActivated )
		{
			LaserConfigs();
			mIsLaserActivated = true;
		}
	}

	void RemoveLaser()
	{
		if( pdot !is null )
		{
			g_EntityFuncs.Remove( pdot );
		}

		bd_GlockLaserMode = CoFGLOCKBD_LASEROFF;
		mIsLaserActivated = false;
		@pdot = @null;
	}

	void ItemPreFrame()
	{
		// Player won't reload until he's not aiming anymore
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void LasersightsSpr( Vector2D POS, float holdTime = 1.0, int alpha = 255 ) // send firemode HUD sprites
	{
		HUDSpriteParams params;
		params.channel = 4;

		// Default mode is additive, so no flag is needed to assign it
		params.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_DYNAMIC_ALPHA;
		params.spritename = CoFCOMMON::FIREMODE_SPRT;
		params.left = 0; // Offset
		params.top = 0; // Offset
		params.width = 0; // 0: auto; use total width of the sprite
		params.height = 0; // 0: auto; use total height of the sprite

		// Pre-flag positions
		//params.x = 0.94;
		//params.y = 0.92;
		params.x = POS.x;
		params.y = POS.y;

		// Default Sven HUD colors
		params.color1 = (g_iMode_laser == CoF_MODE_LASERON) ? RGBA( 100, 130, 200, alpha ) : RGBA( 255, 0, 0, alpha );
		params.color2 = (g_iMode_laser == CoF_MODE_LASERON) ? RGBA( 100, 130, 200, alpha ) : RGBA( 255, 0, 0, alpha );
		// Frame management
		params.frame = 3; // 3 Laser Sight (Glock extra)
		params.numframes = 3;
		params.framerate = 0;

		// Fading times, I expect the player to immediately see the icon (low fadeinTime) and slowly make it disappear (high fadeoutTime)
		params.fadeinTime = 0.2;
		params.fadeoutTime = 0.5;
		// Hold it on screen for a good amount of time (3 seconds)
		params.holdTime = holdTime;
		params.effect = HUD_EFFECT_NONE;

		g_PlayerFuncs.HudCustomSprite( m_pPlayer, params );
	}

	void ToggleLaserSights() // switch fire modes (support for only 2 modes)
	{
		if( m_pPlayer.pev.button & IN_USE == 0 || m_pPlayer.pev.button & IN_RELOAD == 0 )
			return;
		else if( (m_pPlayer.pev.button & IN_USE != 0) && (m_pPlayer.pev.button & IN_RELOAD != 0) )
		{
			if( e_usetimer < g_Engine.time )
			{
				if( g_iMode_laser == CoF_MODE_LASEROFF )
				{
					g_iMode_laser = CoF_MODE_LASERON;
					bd_GlockLaserMode = CoFGLOCKBD_LASERON;
					if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
						self.SendWeaponAnim( (self.m_iClip == 0) ? CoFGLOCK_SWITCH_ON_NOSHOOT : CoFGLOCK_SWITCH_ON, 0, bd_GlockLaserMode );
					else
						self.SendWeaponAnim( (self.m_iClip == 0) ? CoFGLOCK_IRON_SWITCH_ON_NOSHOOT : CoFGLOCK_IRON_SWITCH_ON, 0, bd_GlockLaserMode );

					// Set the Laser on based on the animation timing
					self.pev.nextthink = WeaponTimeBase() + 0.3f;
					SetThink( ThinkFunction( ActivateThink ) );
					m_pPlayer.m_flNextAttack = 0.3f;
				}
				else if( g_iMode_laser == CoF_MODE_LASERON )
				{
					if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
						self.SendWeaponAnim( (self.m_iClip == 0) ? CoFGLOCK_SWITCH_OFF_NOSHOOT : CoFGLOCK_SWITCH_OFF, 0, bd_GlockLaserMode );
					else
						self.SendWeaponAnim( (self.m_iClip == 0) ? CoFGLOCK_IRON_SWITCH_OFF_NOSHOOT : CoFGLOCK_IRON_SWITCH_OFF, 0, bd_GlockLaserMode );

					// Set the Laser off based on the animation timing
					SetThink( ThinkFunction( RemoveLaser ) );
					self.pev.nextthink = WeaponTimeBase() + 0.3f;
					g_iMode_laser = CoF_MODE_LASEROFF;
				}
				LasersightsSpr( FiremodesPos, -1 );
				FiremodesTxt();
				e_usetimer = g_Engine.time + 0.88f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.66f;
			}
		}
	}

	void ItemPostFrame()
	{
		if( mIsLaserActivated )
		{
			// Update laser position while idle
			UpdateLaser();
		}
		bd_GlockLaserMode = (g_iMode_laser == CoF_MODE_LASERON) ? CoFGLOCKBD_LASERON : CoFGLOCKBD_LASEROFF;
		BaseClass.ItemPostFrame();
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.119;
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_IRON_TO : CoFGLOCK_IRON_TO_NOSHOOT, 0, bd_GlockLaserMode );
				EffectsFOVON( 45 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_IRON_FROM : CoFGLOCK_IRON_FROM_NOSHOOT, 0, bd_GlockLaserMode );
				EffectsFOVOFF();
				break;
			}
		}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, bd_GlockLaserMode, 1.0f, 20, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, bd_GlockLaserMode, 1.0f, 20, false );
	}

	void Reload()
	{
		ToggleLaserSights();

		if( self.m_iClip == CoFGLOCK::GLOCK_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_IRON_FROM : CoFGLOCK_IRON_FROM_NOSHOOT, 0, bd_GlockLaserMode );
			m_reloadTimer = g_Engine.time + 0.175;
			m_pPlayer.m_flNextAttack = 0.175;
			canReload = true;
		}

		EffectsFOVOFF();
		// Deactivate the laser effects because we can't make it follow the crosshair while reloading
		if( pdot !is null )
		{
			g_EntityFuncs.Remove( pdot );
		}
		mIsLaserActivated = false;
		@pdot = @null;
		
		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFGLOCK::GLOCK_MAX_CLIP, CoFGLOCK_RELOAD_NOSHOOT, 3.5f, bd_GlockLaserMode ) : Reload( CoFGLOCK::GLOCK_MAX_CLIP, CoFGLOCK_RELOAD, 2.6f, bd_GlockLaserMode );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.3f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFGLOCK::GLOCK_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -28 + g_Engine.v_up * 16 + g_Engine.v_forward * 16, m_iGlockMagEmpty, false, 0 );
	}
	
	void WeaponIdle()
	{
		if( m_iDroppedClip == 1 )
		{
			m_iDroppedClip = 0;
		}

		// Make the laser dot appear again after reloading
		if( g_iMode_laser == CoF_MODE_LASERON )
		{
			if( pdot is null )
			{
				LaserConfigs();
			}
			mIsLaserActivated = true;
		}

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( (self.m_iClip > 0) ? CoFGLOCK_IRON_IDLE : CoFGLOCK_IRON_IDLE_NOSHOOT, 0, bd_GlockLaserMode );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
			{
				case 0:	iAnim = (self.m_iClip > 0) ? CoFGLOCK_IDLE : CoFGLOCK_IDLE_NOSHOOT;
				break;
			
				case 1: iAnim = (self.m_iClip > 0) ? CoFGLOCK_FIDGET1 : CoFGLOCK_FIDGET1_NOSHOOT;
				break;

				case 2: iAnim = (self.m_iClip > 0) ? CoFGLOCK_FIDGET2 : CoFGLOCK_FIDGET2_NOSHOOT;
				break;

				case 3: iAnim = (self.m_iClip > 0) ? CoFGLOCK_FIDGET3 : CoFGLOCK_FIDGET3_NOSHOOT;
				break;
			}

			self.SendWeaponAnim( iAnim, 0, bd_GlockLaserMode );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_GLOCK : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFGLOCK::GLOCK_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFGLOCK::GLOCK_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFGLOCK::GLOCK_MAX_CLIP, CoFGLOCK::GLOCK_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFGLOCKAmmoName()
{
	return "ammo_9mm_glock";
}

string CoFGLOCKName()
{
	return "weapon_cofglock";
}

void RegisterCoFGLOCK()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFGLOCKName(), CoFGLOCKName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_GLOCK", CoFGLOCKAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFGLOCKName(), "cof/pistol", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFGLOCKAmmoName() );
}