// Author: KernCore

#include "../base"

enum CoFTMPAnimations_e
{
	CoFTMP_IDLE = 0,
	CoFTMP_DRAW,
	CoFTMP_DRAW_FIRST,
	CoFTMP_HOLSTER,
	CoFTMP_SHOOT,
	CoFTMP_RELOAD,
	CoFTMP_RELOAD_EMPTY,
	CoFTMP_SPRINT_TO,
	CoFTMP_SPRINT_IDLE,
	CoFTMP_SPRINT_FROM,
	CoFTMP_IRON_TO,
	CoFTMP_IRON_IDLE,
	CoFTMP_IRON_FROM,
	CoFTMP_IRON_SHOOT,
	CoFTMP_MELEE,
	CoFTMP_SUICIDE
};

namespace CoFTMP
{
	//models
	string TMP_W_MODEL      	= "models/cof/tmp/wrd.mdl";
	string TMP_V_MODEL      	= "models/cof/tmp/vwm.mdl";
	string TMP_P_MODEL      	= "models/cof/tmp/plr.mdl";
	string TMP_A_MODEL      	= "models/cof/tmp/mag.mdl";
	string TMP_MAGEMPTY_MODEL	= "models/cof/tmp/mag_e.mdl";
	//sounds
	//const string TMP_SHOOT_SOUND  	= "cof/guns/tmp/tmp_fire.ogg"; //Old
	const string LOOP_SOUND 	= "cof/guns/tmp/shoot_loop.ogg";
	const string LOOP_SOUND_END	= "cof/guns/tmp/shoot_end.ogg";
	//weapon information
	const int TMP_MAX_CARRY   	= (p_Customizable) ? 360 : 250;
	const int TMP_MAX_CLIP    	= 30;
	const int TMP_DEFAULT_GIVE 	= TMP_MAX_CLIP * 2;
	const int TMP_WEIGHT      	= 24;
	uint TMP_DAMAGE          	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 5;
}

class weapon_coftmp : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	bool m_WasDrawn;
	private int m_iTmpMagEmpty, mag_counter;
	private bool isLooping;
	private float LoopTimer;

	// Other Sounds
	private array<string> tmpSounds = {
		"cof/guns/tmp/bltback.ogg",
		"cof/guns/tmp/bltfwrd.ogg",
		"cof/guns/tmp/magin.ogg",
		"cof/guns/tmp/magout.ogg",
		"cof/guns/tmp/stock.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFTMP::TMP_W_MODEL );

		self.m_iDefaultAmmo	= CoFTMP::TMP_DEFAULT_GIVE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		m_WasDrawn = false;

		iAnimation  = CoFTMP_MELEE;
		iAnimation2 = CoFTMP_MELEE;

		mag_counter = CoFTMP::TMP_MAX_CLIP;
		isLooping = false;
		LoopTimer = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFTMP::TMP_W_MODEL );
		g_Game.PrecacheModel( CoFTMP::TMP_V_MODEL );
		g_Game.PrecacheModel( CoFTMP::TMP_P_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		g_Game.PrecacheModel( CoFTMP::TMP_A_MODEL );
		m_iTmpMagEmpty	= g_Game.PrecacheModel( CoFTMP::TMP_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( tmpSounds );

		g_SoundSystem.PrecacheSound( CoFTMP::LOOP_SOUND );
		g_SoundSystem.PrecacheSound( CoFTMP::LOOP_SOUND_END );
		g_Game.PrecacheGeneric( "sound/" + CoFTMP::LOOP_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFTMP::LOOP_SOUND_END );

		//Old
		/*g_SoundSystem.PrecacheSound( CoFTMP::TMP_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFTMP::TMP_SHOOT_SOUND );*/

		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/smg/weapon_coftmp.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFTMP::TMP_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFTMP::TMP_MAX_CLIP;
		info.iSlot  	= CoFTMP::SLOT;
		info.iPosition 	= CoFTMP::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFTMP::TMP_WEIGHT;

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
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFTMP::TMP_V_MODEL, CoFTMP::TMP_P_MODEL, CoFTMP_DRAW_FIRST, "onehanded", 1 );
				deployTime = 1.5f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFTMP::TMP_V_MODEL, CoFTMP::TMP_P_MODEL, CoFTMP_DRAW, "onehanded", 1 );
				deployTime = 1.0f;
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

	private void TurnLoopOff()
	{
		isLooping = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFTMP::LOOP_SOUND );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFTMP::LOOP_SOUND_END, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		//g_Game.AlertMessage( at_console, "Loop Sound Off\n" );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		EffectsFOVOFF();
		canReload = false;

		if( isLooping )
			TurnLoopOff();

		SetThink( null );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			//Turn the looping off
			if( isLooping )
				TurnLoopOff();

			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;

			return;
		}

		if( ( !(m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) || (m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) ) && !isLooping )
		{
			isLooping = true;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFTMP::LOOP_SOUND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			LoopTimer = self.m_flNextPrimaryAttack + 0.2;
			//g_Game.AlertMessage( at_console, "Loop Sound On\n" );
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 666 );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
		
		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFTMP_IRON_SHOOT, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFTMP_SHOOT, 0, 1 );
		}

		// Accuracy
		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}
		// Fire the Bullet
		FireTrueBullet( string_t(), false, CoFTMP::TMP_DAMAGE, vecCone, 8192, false, DMG_GENERIC, false, true );
		// Recoil
		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.50f, -1.00f ) : Math.RandomFloat( -2.00f, -2.50f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.75f, -2.25f ) : Math.RandomFloat( -3.15f, -2.75f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.2f, -0.1f ) );

		Vector vecShellVelocity, vecShellOrigin;
		
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 6.5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 22, 1.5, -4, false, false );

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );

		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFTMP_IRON_TO, 0, 1 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFTMP_IRON_FROM, 0, 1 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.0f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void ItemPreFrame()
	{
		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
		{
			if( isLooping && LoopTimer < g_Engine.time )
			{
				if ( !( ( m_pPlayer.pev.button & IN_ATTACK ) != 0 ) || self.m_iClip == 0 )
				{
					LoopTimer = 0;
					isLooping = false;
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFTMP::LOOP_SOUND_END, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
					//g_Game.AlertMessage( at_console, "Loop Sound Off\n" );
				}
			}
		}

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFTMP::TMP_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		//Turn the looping off
		if( isLooping )
			TurnLoopOff();

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFTMP_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.18;
			m_pPlayer.m_flNextAttack = 0.18;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFTMP::TMP_MAX_CLIP, CoFTMP_RELOAD_EMPTY, 3.66f, 1 ) : Reload( CoFTMP::TMP_MAX_CLIP, CoFTMP_RELOAD, 2.5f, 1 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 1.0f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFTMP::TMP_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -24 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iTmpMagEmpty, false, 0 );
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
			self.SendWeaponAnim( CoFTMP_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFTMP_IDLE, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.0f, 22, true );
	}
}

class Parabellum9mm_TMP : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFTMP::TMP_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFTMP::TMP_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFTMP::TMP_MAX_CLIP, CoFTMP::TMP_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFTMPAmmoName()
{
	return "ammo_9mm_tmp";
}

string CoFTMPName()
{
	return "weapon_coftmp";
}

void RegisterCoFTMP()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFTMPName(), CoFTMPName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_TMP", CoFTMPAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFTMPName(), "cof/smg", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFTMPAmmoName() );
}