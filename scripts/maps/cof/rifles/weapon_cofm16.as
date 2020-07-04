// Author: KernCore

#include "../base"

enum CoFM16Animations_e
{
	CoFM16_DRAW_SINGLE = 0,
	CoFM16_IDLE_SINGLE,
	CoFM16_SHOOT_SINGLE,
	CoFM16_RELOAD_SINGLE,
	CoFM16_RELOAD_EMPTY_SINGLE,
	CoFM16_HOLSTER_SINGLE,
	CoFM16_SINGLE_TO_BURST,
	CoFM16_DRAW_BURST,
	CoFM16_IDLE_BURST,
	CoFM16_SHOOT_BURST,
	CoFM16_RELOAD_BURST,
	CoFM16_RELOAD_EMPTY_BURST,
	CoFM16_HOLSTER_BURST,
	CoFM16_BURST_TO_SINGLE,
	CoFM16_SPRINT_TO,
	CoFM16_SPRINT_IDLE,
	CoFM16_SPRINT_FROM,
	CoFM16_SUICIDE,
	CoFM16_IRON_TO,
	CoFM16_IRON_IDLE,
	CoFM16_IRON_FROM,
	CoFM16_IRON_SHOOT,
	CoFM16_MELEE,
	CoFM16_SHOOT_NOSHOOT_SINGLE,
	CoFM16_SHOOT_NOSHOOT_BURST,
	CoFM16_IRON_SHOOT_NOSHOOT,
	CoFM16_FIDGET1_SINGLE,
	CoFM16_FIDGET2_SINGLE,
	CoFM16_FIDGET3_SINGLE,
	CoFM16_FIDGET1_BURST,
	CoFM16_FIDGET2_BURST,
	CoFM16_FIDGET3_BURST,
	CoFM16_IRON_SINGLE_TO_BURST,
	CoFM16_IRON_BURST_TO_SINGLE,
	CoFM16_JUMP_TO_SINGLE,
	CoFM16_JUMP_FROM_SINGLE,
	CoFM16_JUMP_TO,
	CoFM16_JUMP_FROM
};

namespace CoFM16
{
	//models
	string M16_W_MODEL        	= "models/cof/m16/wrd.mdl";
	string M16_V_MODEL        	= "models/cof/m16/vwm.mdl";
	string M16_P_MODEL        	= "models/cof/m16/plr.mdl";
	string M16_A_MODEL        	= "models/cof/m16/mag.mdl";
	string M16_MAGEMPTY_MODEL 	= "models/cof/m16/mag_e.mdl";
	//sound
	const string M16_SHOOT_SOUND 	= "cof/guns/m16/shoot.ogg";
	//weapon info
	const int M16_MAX_CARRY      	= (p_Customizable) ? 500 : 600;
	const int M16_MAX_CLIP       	= 20;
	const int M16_DEFAULT_GIVE   	= M16_MAX_CLIP * 3;
	const int M16_WEIGHT         	= 40;
	uint M16_DAMAGE               	= 22;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 5;
}

class weapon_cofm16 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//weapon funcs
	private int m_iM16MagEmpty, mag_counter;
	private int m_iBurstCount = 0;
	private int m_iBurstLeft = 0;
	private float m_flNextBurstFireTime = 0;
	Vector vecShellVelocity, vecShellOrigin, vecCone;
	private float e_usetimer, m_iPunchAngle;

	// Other Sounds
	private array<string> m16Sounds = {
		"cof/guns/m16/bltback.ogg",
		"cof/guns/m16/bltfwrd.ogg",
		"cof/guns/m16/magin.ogg",
		"cof/guns/m16/magout.ogg",
		"cof/guns/m16/magtap.ogg",
		"cof/guns/m16/switch.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFM16::M16_W_MODEL );
		
		self.m_iDefaultAmmo	= CoFM16::M16_DEFAULT_GIVE;
		g_iMode_ironsights	= CoF_MODE_NOTAIMED;
		iAnimation      	= CoFM16_MELEE;
		iAnimation2     	= CoFM16_MELEE;
		g_iMode_burst   	= CoF_MODE_BURST;
		e_usetimer      	= 0;
		mag_counter = CoFM16::M16_MAX_CLIP;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFM16::M16_W_MODEL );
		g_Game.PrecacheModel( CoFM16::M16_V_MODEL );
		g_Game.PrecacheModel( CoFM16::M16_P_MODEL );
		g_Game.PrecacheModel( CoFM16::M16_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iM16MagEmpty	= g_Game.PrecacheModel( CoFM16::M16_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[3] ); //556

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( m16Sounds );

		g_SoundSystem.PrecacheSound( CoFM16::M16_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFM16::M16_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheModel( "sprites/" + CoFCOMMON::FIREMODE_SPRT );

		g_Game.PrecacheGeneric( "events/" + "muzzle_cofM16.txt" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheGeneric( "sprites/" + "cof/arifle/weapon_cofm16.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CoFM16::M16_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= CoFM16::M16_MAX_CLIP;
		info.iSlot  	= CoFM16::SLOT;
		info.iPosition	= CoFM16::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight	= CoFM16::M16_WEIGHT;

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
			DisplayFiremodeSprite();

			bResult = Deploy( CoFM16::M16_V_MODEL, CoFM16::M16_P_MODEL, (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_DRAW_BURST : CoFM16_DRAW_SINGLE, "m16", 0 );
			DeploySleeve();

			float deployTime = 1.13f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = e_usetimer = g_Engine.time + deployTime;
			return bResult;
		}
	}

	bool CanDeploy()
	{
		return true;
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

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		// Cancel the Burst
		m_iBurstLeft = 0;
		// Reset FOV settings
		EffectsFOVOFF();
		// Reset Melee Settings
		SetThink( null );
		canReload = false;
		FiremodesSpr( FiremodesPos, 0, 0, 0 );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			{
				self.SendWeaponAnim( (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_SHOOT_NOSHOOT_BURST : CoFM16_SHOOT_NOSHOOT_SINGLE, 0, 1 );
			}
			else if( g_iMode_ironsights == CoF_MODE_AIMED )
			{
				self.SendWeaponAnim( CoFM16_IRON_SHOOT_NOSHOOT, 0, 1 );
			}
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		if( g_iMode_burst == CoF_MODE_SINGLE )
		{
			self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.135;
		}
		else if( g_iMode_burst == CoF_MODE_BURST )
		{
			//Fire at most 3 bullets.
			m_iBurstCount = Math.min( 3, self.m_iClip );
			m_iBurstLeft = m_iBurstCount - 1;
			m_flNextBurstFireTime = WeaponTimeBase() + 0.04;
			//Prevent primary attack before burst finishes. Might need to be finetuned.
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.45;
		}

		FirstAttackCommon();
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.2;
	}

	private void FirstAttackCommon()
	{
		// Accuracy checks
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? g_vecZero : VECTOR_CONE_2DEGREES;
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;

		FireTrueBullet( CoFM16::M16_SHOOT_SOUND, true, CoFM16::M16_DAMAGE, vecCone, 8192, false, DMG_GENERIC, true );
		mag_counter--;

		// Recoil checks
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			if( g_iMode_burst == CoF_MODE_BURST )
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.50f, -1.25f ) : Math.RandomFloat( -1.85f, -1.75f );
			else
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.25f, -2.00f ) : Math.RandomFloat( -3.00f, -2.75f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			if( g_iMode_burst == CoF_MODE_BURST )
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.95f, -1.85f ) : Math.RandomFloat( -2.25f, -2.15f );
			else
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.75f, -2.50f ) : Math.RandomFloat( -3.45f, -3.00f );
		}

		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.3, 0.3 ), true );
		// Shell Ejection position calculations
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 6, -8, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 19, 2, -6, false, false );

		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_SHOOT_BURST : CoFM16_SHOOT_SINGLE, 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFM16_IRON_SHOOT, 0, 0 );
		}
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = e_usetimer = WeaponTimeBase() + 0.1;

		if( !((m_pPlayer.pev.button & IN_USE) != 0) )
		{
			switch( g_iMode_ironsights )
			{
				case CoF_MODE_NOTAIMED:
				{
					self.SendWeaponAnim( CoFM16_IRON_TO, 0, 1 );
					EffectsFOVON( 40 );
					break;
				}
				case CoF_MODE_AIMED:
				{
					self.SendWeaponAnim( CoFM16_IRON_FROM, 0, 1 );
					EffectsFOVOFF();
					break;
				}
			}
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
	}

	void ChangeFirerate() // switch fire modes (support for only 2 modes)
	{
		if( m_pPlayer.pev.button & IN_USE == 0 || m_pPlayer.pev.button & IN_RELOAD == 0 )
			return;
		else if( (m_pPlayer.pev.button & IN_USE != 0) && (m_pPlayer.pev.button & IN_RELOAD != 0) )
		{
			if( e_usetimer < g_Engine.time )
			{
				if( g_iMode_burst == CoF_MODE_BURST )
				{
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFM16_BURST_TO_SINGLE  : CoFM16_IRON_BURST_TO_SINGLE, 0, 1 );
					g_iMode_burst = CoF_MODE_SINGLE;
				}
				else if( g_iMode_burst == CoF_MODE_SINGLE )
				{
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFM16_SINGLE_TO_BURST : CoFM16_IRON_SINGLE_TO_BURST, 0, 1 );
					g_iMode_burst = CoF_MODE_BURST;
				}
				DisplayFiremodeSprite();
				e_usetimer = g_Engine.time + 0.88f;
				m_pPlayer.m_flNextAttack = 0.66f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.66f;
			}
		}
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void ItemPostFrame()
	{
		if( g_iMode_burst == CoF_MODE_BURST )
		{
			if( m_iBurstLeft > 0 )
			{
				if( m_flNextBurstFireTime < WeaponTimeBase() )
				{
					if( self.m_iClip <= 0 )
					{
						m_iBurstLeft = 0;
						return;
					}
					else
					{
						--m_iBurstLeft;
					}

					FirstAttackCommon();

					if( m_iBurstLeft > 0 )
						m_flNextBurstFireTime = WeaponTimeBase() + 0.055;
					else
						m_flNextBurstFireTime = 0;
				}

				//While firing a burst, don't allow reload or any other weapon actions. Might be best to let some things run though.
				return;
			}
		}
		BaseClass.ItemPostFrame();
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.16f, 24, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.16f, 24, true );
	}

	void Reload()
	{
		ChangeFirerate();

		if( self.m_iClip == CoFM16::M16_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFM16_IRON_FROM, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}
	
		m_iBurstLeft = 0;
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			if( self.m_iClip == 0 )
			{
				Reload( CoFM16::M16_MAX_CLIP, (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_RELOAD_EMPTY_BURST : CoFM16_RELOAD_EMPTY_SINGLE, 4.0f, 1 );
			}
			else
			{
				Reload( CoFM16::M16_MAX_CLIP, (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_RELOAD_BURST : CoFM16_RELOAD_SINGLE, 3.0f, 1 );
			}
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.66f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFM16::M16_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -32 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iM16MagEmpty, false, 0 );
	}

	void WeaponIdle()
	{
		if( m_iDroppedClip == 1 )
		{
			m_iDroppedClip = 0;
		}

		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFM16_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( (g_iMode_burst == CoF_MODE_BURST) ? CoFM16_IDLE_BURST : CoFM16_IDLE_SINGLE, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Nato556_M16 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFM16::M16_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFM16::M16_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFM16::M16_MAX_CLIP, CoFM16::M16_MAX_CARRY, (p_Customizable) ? "ammo_556nato" : "556" );
	}
}

string CoFM16AmmoName()
{
	return "ammo_556_m16";
}

string CoFM16Name()
{
	return "weapon_cofm16";
}

void RegisterCoFM16()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFM16Name(), CoFM16Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Nato556_M16", CoFM16AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFM16Name(), "cof/arifle", (p_Customizable) ? "ammo_556nato" : "556", "", CoFM16AmmoName() );
}