// Author: KernCore

#include "../base"

enum CoFMP5Animations_e
{
	CoFMP5_DRAW = 0,
	CoFMP5_IDLE,
	CoFMP5_RELOAD,
	CoFMP5_RELOAD_NOSHOOT,
	CoFMP5_SHOOT1,
	CoFMP5_SHOOT2,
	CoFMP5_SHOOT3,
	CoFMP5_SHOOT_NOSHOOT,
	CoFMP5_IRON_TO,
	CoFMP5_IRON_IDLE,
	CoFMP5_IRON_SHOOT,
	CoFMP5_IRON_FROM,
	CoFMP5_SUICIDE,
	CoFMP5_SPRINT_TO,
	CoFMP5_SPRINT_IDLE,
	CoFMP5_SPRINT_FROM,
	CoFMP5_JUMP,
	CoFMP5_LAND,
	CoFMP5_MELEE,
	CoFMP5_HOLSTER
};

namespace CoFMP5
{
	//models
	string MP5_W_MODEL      	= "models/cof/mp5/wrd.mdl";
	string MP5_V_MODEL      	= "models/cof/mp5/vwm.mdl";
	string MP5_P_MODEL      	= "models/cof/mp5/plr.mdl";
	string MP5_A_MODEL      	= "models/cof/mp5/mag.mdl";
	string MP5_MAGEMPTY_MODEL	= "models/cof/mp5/mag_e.mdl";
	//sounds
	//const string MP5_SHOOT_SOUND 	= "cof/guns/mp5/mp5_fire.ogg"; //Old
	const string LOOP_SOUND 	= "cof/guns/mp5/shoot_loop.ogg";
	const string LOOP_SOUND_END	= "cof/guns/mp5/shoot_end.ogg";
	//weapon info
	const int MP5_MAX_CARRY   	= (p_Customizable) ? 360 : 250;
	const int MP5_MAX_CLIP    	= 30;
	const int MP5_DEFAULT_GIVE 	= MP5_MAX_CLIP * 2;
	const int MP5_WEIGHT      	= 15;
	uint MP5_DAMAGE          	= 13;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 2;
	uint POSITION 	= 4;
}

class weapon_cofmp5 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	private int m_iMp5MagEmpty, mag_counter;
	private bool isLooping;
	private float LoopTimer;

	// Other Sounds
	private array<string> mp5Sounds = {
		"cof/guns/mp5/bltback.ogg",
		"cof/guns/mp5/bltfwrd.ogg",
		"cof/guns/mp5/magin.ogg",
		"cof/guns/mp5/magout.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFMP5::MP5_W_MODEL );

		iAnimation  = CoFMP5_MELEE;
		iAnimation2 = CoFMP5_MELEE;
		self.m_iDefaultAmmo = CoFMP5::MP5_DEFAULT_GIVE;
		g_iMode_ironsights  = CoF_MODE_NOTAIMED;
		mag_counter = CoFMP5::MP5_MAX_CLIP;
		isLooping = false;
		LoopTimer = 0;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFMP5::MP5_W_MODEL );
		g_Game.PrecacheModel( CoFMP5::MP5_V_MODEL );
		g_Game.PrecacheModel( CoFMP5::MP5_P_MODEL );
		g_Game.PrecacheModel( CoFMP5::MP5_A_MODEL );

		g_Game.PrecacheModel( g_watersplash_spr );
		m_iMp5MagEmpty	= g_Game.PrecacheModel( CoFMP5::MP5_MAGEMPTY_MODEL );
		m_iShell    	= g_Game.PrecacheModel( mShellModel[0] ); //9mm

		CommonPrecache(); //Common sounds to all weapons

		PrecacheSound( mp5Sounds );

		g_SoundSystem.PrecacheSound( CoFMP5::LOOP_SOUND );
		g_SoundSystem.PrecacheSound( CoFMP5::LOOP_SOUND_END );
		g_Game.PrecacheGeneric( "sound/" + CoFMP5::LOOP_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFMP5::LOOP_SOUND_END );

		//Old
		/*g_SoundSystem.PrecacheSound( CoFMP5::MP5_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFMP5::MP5_SHOOT_SOUND );*/

		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "events/" + "muzzle_cofMP5.txt" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/smg/weapon_cofmp5.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFMP5::MP5_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFMP5::MP5_MAX_CLIP;
		info.iSlot  	= CoFMP5::SLOT;
		info.iPosition 	= CoFMP5::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFMP5::MP5_WEIGHT;

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
		bool bResult;
		{
			bResult = Deploy( CoFMP5::MP5_V_MODEL, CoFMP5::MP5_P_MODEL, CoFMP5_DRAW, "mp5", 0 );

			DeploySleeve();
			isLooping = false;

			float deployTime = 1.0f;
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
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFMP5::LOOP_SOUND );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFMP5::LOOP_SOUND_END, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		//g_Game.AlertMessage( at_console, "Loop Sound Off\n" );
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		EffectsFOVOFF();
		SetThink( null );
		canReload = false;

		//Turn the looping off
		if( isLooping )
			TurnLoopOff();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			//Turn the looping off
			if( isLooping )
				TurnLoopOff();

			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.43f;

			if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
				self.SendWeaponAnim( CoFMP5_SHOOT_NOSHOOT, 0, 0 );

			return;
		}

		if( ( !(m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) || (m_pPlayer.m_afButtonPressed & IN_ATTACK == 0) ) && !isLooping )
		{
			isLooping = true;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFMP5::LOOP_SOUND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			LoopTimer = self.m_flNextPrimaryAttack + 0.2;
			//g_Game.AlertMessage( at_console, "Loop Sound On\n" );
		}

		mag_counter--;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 850 );
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.1;
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.3;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
		
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFMP5_SHOOT1 + Math.RandomLong( 0, 2 ), 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFMP5_IRON_SHOOT, 0, 0 );
		}

		//Play it before the punchangle, so the accuracy doesn't get screwed
		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_3DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( string_t(), false, CoFMP5::MP5_DAMAGE, vecCone, 9216, false, DMG_GENERIC, false, true );

		float m_iPunchAngle;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.75f, -1.50f ) : Math.RandomFloat( -2.25f, -2.75f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -3.00f, -2.75f ) : Math.RandomFloat( -3.50f, -3.25f );
		}
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.3f, -0.1f ) );

		Vector vecShellVelocity, vecShellOrigin;

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 6, -7.1, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 3.1, -4, false, false );

		vecShellVelocity.y *= 1;
		
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.23;
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		switch( g_iMode_ironsights )
		{
			case CoF_MODE_NOTAIMED:
			{
				self.SendWeaponAnim( CoFMP5_IRON_TO, 0, 0 );
				EffectsFOVON( 40 );
				break;
			}
			case CoF_MODE_AIMED:
			{
				self.SendWeaponAnim( CoFMP5_IRON_FROM, 0, 0 );
				EffectsFOVOFF();
				break;
			}
		}
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 0, 1.2f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 0, 1.2f, 22, true );
	}

	void ItemPreFrame()
	{
		if( m_iDroppedClip == 1 )
			m_iDroppedClip = 0;

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
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFMP5::LOOP_SOUND_END, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
					//g_Game.AlertMessage( at_console, "Loop Sound Off\n" );
				}
			}
		}

		BaseClass.ItemPreFrame();
	}

	void Reload()
	{
		if( self.m_iClip == CoFMP5::MP5_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		//Turn the looping off
		if( isLooping )
			TurnLoopOff();

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFMP5_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.2;
			m_pPlayer.m_flNextAttack = 0.2;
			canReload = true;
		}

		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFMP5::MP5_MAX_CLIP, CoFMP5_RELOAD_NOSHOOT, 3.8f, 0 ) : Reload( CoFMP5::MP5_MAX_CLIP, CoFMP5_RELOAD, 3.05f, 0 );
			canReload = false;
		}

		if( mag_counter <= 0 )
		{
			self.pev.nextthink = (self.m_iClip == 0) ? WeaponTimeBase() + 1.7f : WeaponTimeBase() + 1.33f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFMP5::MP5_MAX_CLIP;
		Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -50, -16 ) + g_Engine.v_up * 16 + g_Engine.v_forward * Math.RandomLong( 16, 50 );
		ClipCasting( m_pPlayer.pev.origin, vecVelocity, m_iMp5MagEmpty, false, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_AIMED) ? CoFMP5_IRON_IDLE : CoFMP5_IDLE, 0, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

class Parabellum9mm_MP5 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFMP5::MP5_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFMP5::MP5_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFMP5::MP5_MAX_CLIP, CoFMP5::MP5_MAX_CARRY, (p_Customizable) ? "ammo_9mmpara" : "9mm" );
	}
}

string CoFMP5AmmoName()
{
	return "ammo_9mm_mp5";
}

string CoFMP5Name()
{
	return "weapon_cofmp5";
}

void RegisterCoFMP5()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFMP5Name(), CoFMP5Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Parabellum9mm_MP5", CoFMP5AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFMP5Name(), "cof/smg", (p_Customizable) ? "ammo_9mmpara" : "9mm", "", CoFMP5AmmoName() );
}