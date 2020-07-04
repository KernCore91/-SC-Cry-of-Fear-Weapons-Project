// Author: KernCore

#include "../base"

enum CoFFAMASAnimations_e
{
	CoFFAMAS_IDLE = 0,
	CoFFAMAS_DRAW,
	CoFFAMAS_DRAW_FIRST, // Why would you ever do such thing to a weapon? :/
	CoFFAMAS_HOLSTER,
	CoFFAMAS_SHOOT,
	CoFFAMAS_RELOAD,
	CoFFAMAS_RELOAD_EMPTY,
	CoFFAMAS_SWITCH,
	CoFFAMAS_SPRINT_TO,
	CoFFAMAS_SPRINT_IDLE,
	CoFFAMAS_SPRINT_FROM,
	CoFFAMAS_MELEE,
	CoFFAMAS_FIDGET1,
	CoFFAMAS_FIDGET2,
	CoFFAMAS_FIDGET3,
	CoFFAMAS_IRON_TO,
	CoFFAMAS_IRON_IDLE,
	CoFFAMAS_IRON_SHOOT,
	CoFFAMAS_IRON_FROM,
	CoFFAMAS_SUICIDE,
	CoFFAMAS_SHOOT_EMPTY,
	CoFFAMAS_IRON_SHOOT_EMPTY,
	CoFFAMAS_JUMP_TO,
	CoFFAMAS_JUMP_FROM,
	CoFFAMAS_IRON_SWITCH
};

namespace CoFFAMAS
{
	//models
	string FAMAS_W_MODEL       	= "models/cof/famas/wrd.mdl";
	string FAMAS_V_MODEL       	= "models/cof/famas/vwm.mdl";
	string FAMAS_P_MODEL       	= "models/cof/famas/plr.mdl";
	string FAMAS_A_MODEL       	= "models/cof/famas/mag.mdl";
	string FAMAS_MAGEMPTY_MODEL	= "models/cof/famas/mag_e.mdl";
	//sound
	const string FAMAS_SHOOT_SOUND  	= "cof/guns/famas/shoot.ogg";
	//weapon information
	const int FAMAS_MAX_CARRY    	= (p_Customizable) ? 500 : 600;
	const int FAMAS_MAX_CLIP     	= 30;
	const int FAMAS_DEFAULT_GIVE 	= FAMAS_MAX_CLIP * 3;
	const int FAMAS_WEIGHT       	= 45;
	uint FAMAS_DAMAGE             	= 18;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 6;
}

class weapon_coffamas : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iFamasMagEmpty;
	int m_iBurstLeft = 0;
	int m_iBurstCount = 0;
	float m_flNextBurstFireTime = 0;
	Vector vecShellVelocity, vecShellOrigin;
	float e_usetimer;
	Vector vecCone;
	float m_iPunchAngle;
	int mag_counter;

	// Other Sounds
	private array<string> famasSounds = {
		"cof/guns/famas/bltrel.ogg",
		"cof/guns/famas/magin.ogg",
		"cof/guns/famas/magout.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFFAMAS::FAMAS_W_MODEL ) );

		self.m_iDefaultAmmo	= CoFFAMAS::FAMAS_DEFAULT_GIVE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		g_iMode_burst    	= CoF_MODE_AUTO;
		e_usetimer       	= 0;

		iAnimation       	= CoFFAMAS_MELEE;
		iAnimation2      	= CoFFAMAS_MELEE;

		mag_counter = CoFFAMAS::FAMAS_MAX_CLIP;
		
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFFAMAS::FAMAS_W_MODEL );
		g_Game.PrecacheModel( CoFFAMAS::FAMAS_V_MODEL );
		g_Game.PrecacheModel( CoFFAMAS::FAMAS_P_MODEL );
		g_Game.PrecacheModel( CoFFAMAS::FAMAS_A_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		m_iFamasMagEmpty 	= g_Game.PrecacheModel( CoFFAMAS::FAMAS_MAGEMPTY_MODEL );
		m_iShell         	= g_Game.PrecacheModel( mShellModel[3] ); //556

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( famasSounds );

		g_SoundSystem.PrecacheSound( CoFFAMAS::FAMAS_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFFAMAS::FAMAS_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheModel( "sprites/" + CoFCOMMON::FIREMODE_SPRT );

		g_Game.PrecacheGeneric( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/arifle/weapon_coffamas.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFFAMAS::FAMAS_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= CoFFAMAS::FAMAS_MAX_CLIP;
		info.iSlot   	= CoFFAMAS::SLOT;
		info.iPosition 	= CoFFAMAS::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFFAMAS::FAMAS_WEIGHT;

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
			DisplayFiremodeSprite();

			bResult = Deploy( CoFFAMAS::FAMAS_V_MODEL, CoFFAMAS::FAMAS_P_MODEL, CoFFAMAS_DRAW, "m16", 0 );
			DeploySleeve();

			float deployTime = 1.0f;
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
		EffectsFOVOFF();
		m_iBurstLeft = 0;
		canReload = false;
		SetThink( null );
		FiremodesSpr( FiremodesPos, 0, 0, 0 );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;
				
			self.PlayEmptySound();
			if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			{
				self.SendWeaponAnim( CoFFAMAS_SHOOT_EMPTY, 0, 1 );
			}
			else if( g_iMode_ironsights == CoF_MODE_AIMED )
			{
				self.SendWeaponAnim( CoFFAMAS_IRON_SHOOT_EMPTY, 0, 1 );
			}
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		if( g_iMode_burst == CoF_MODE_AUTO )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + GetFireRate( Math.RandomFloat( 1000, 1100 ) );
		}
		else if( g_iMode_burst == CoF_MODE_BURST )
		{
			//Fire at most 3 bullets.
			m_iBurstCount = Math.min( 3, self.m_iClip );
			m_iBurstLeft = m_iBurstCount - 1;
			m_flNextBurstFireTime = WeaponTimeBase() + 0.054;
			//Prevent primary attack before burst finishes. Might need to be finetuned.
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.4;
		}
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );

		FirstAttackCommon();
		self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.2;
	}

	private void FirstAttackCommon()
	{
		self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFFAMAS_SHOOT : CoFFAMAS_IRON_SHOOT, 0, 1 );

		// Accuracy checks
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_4DEGREES;

		FireTrueBullet( CoFFAMAS::FAMAS_SHOOT_SOUND, true, CoFFAMAS::FAMAS_DAMAGE, vecCone, 8192, false, DMG_GENERIC, true );
		mag_counter--;

		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			if( g_iMode_burst == CoF_MODE_BURST )
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.55f, -1.30f ) : Math.RandomFloat( -1.90f, -1.80f );
			else
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -2.25f ) : Math.RandomFloat( -3.25f, -3.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			if( g_iMode_burst == CoF_MODE_BURST )
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.00f, -1.90f ) : Math.RandomFloat( -2.30f, -2.20f );
			else
				m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -2.75f, -2.25f ) : Math.RandomFloat( -4.00f, -3.00f );
		}

		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( -0.55, 0.55 ), (g_iMode_burst == CoF_MODE_AUTO) ? false : true );

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 6, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 6, 2, -4, false, false );
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;

		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	//Overridden to prevent WeaponIdle from being blocked by holding down buttons.
	void ItemPostFrame()
	{
		//If firing bursts, handle next shot.
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
					m_flNextBurstFireTime = WeaponTimeBase() + 0.075;
				else
					m_flNextBurstFireTime = 0;
			}

			//While firing a burst, don't allow reload or any other weapon actions. Might be best to let some things run though.
			return;
		}
		BaseClass.ItemPostFrame();
	}

	void SecondaryAttack()
	{
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = e_usetimer = WeaponTimeBase() + 0.2;

		if( !((m_pPlayer.pev.button & IN_USE) != 0) )
		{
			switch( g_iMode_ironsights )
			{
				case CoF_MODE_NOTAIMED:
				{
					self.SendWeaponAnim( CoFFAMAS_IRON_TO, 0, 1 );
					EffectsFOVON( 40 );
					break;
				}
				case CoF_MODE_AIMED:
				{
					self.SendWeaponAnim( CoFFAMAS_IRON_FROM, 0, 1 );
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
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFFAMAS_SWITCH : CoFFAMAS_IRON_SWITCH, 0, 0 );
					g_iMode_burst = CoF_MODE_AUTO;
				}
				else if( g_iMode_burst == CoF_MODE_AUTO )
				{
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFFAMAS_SWITCH : CoFFAMAS_IRON_SWITCH, 0, 0 );
					g_iMode_burst = CoF_MODE_BURST;
				}
				DisplayFiremodeSprite();
				e_usetimer = g_Engine.time + 1.0f;
				m_pPlayer.m_flNextAttack = 1.0f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 1.0f;
			}
		}
	}

	void ItemPreFrame()
	{
		//m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 999 );

		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();

		BaseClass.ItemPreFrame();
	}

	void TertiaryAttack()
	{
		if( !Swing( 1, 37, 1, 1.1f, 22, true ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 1.1f, 22, true );
	}

	void Reload()
	{
		ChangeFirerate();

		if( self.m_iClip == CoFFAMAS::FAMAS_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFFAMAS_IRON_FROM, 0, 1 );
			m_reloadTimer = g_Engine.time + 0.175f;
			m_pPlayer.m_flNextAttack = 0.175;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFFAMAS::FAMAS_MAX_CLIP, CoFFAMAS_RELOAD_EMPTY, 3.6f, 1 ) : Reload( CoFFAMAS::FAMAS_MAX_CLIP, CoFFAMAS_RELOAD, 3.0f, 1 );
			canReload = false;
		}
		if( mag_counter <= 0 )
		{
			self.pev.nextthink = WeaponTimeBase() + 0.85f;
			SetThink( ThinkFunction( EjectClipThink ) );
		}

		BaseClass.Reload();
	}

	void EjectClipThink()
	{
		mag_counter = CoFFAMAS::FAMAS_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -48 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iFamasMagEmpty, false, 0 );
	}

	void WeaponIdle()
	{
		int iAnim;

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
			self.SendWeaponAnim( CoFFAMAS_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 3 ) )
			{
				case 0:	iAnim = CoFFAMAS_IDLE;
				break;
			
				case 1: iAnim = CoFFAMAS_FIDGET1;
				break;

				case 2: iAnim = CoFFAMAS_FIDGET2;
				break;

				case 3: iAnim = CoFFAMAS_FIDGET3;
				break;
			}
			self.SendWeaponAnim( iAnim, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class Nato556_FAMAS : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFFAMAS::FAMAS_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFFAMAS::FAMAS_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFFAMAS::FAMAS_MAX_CLIP, CoFFAMAS::FAMAS_MAX_CARRY, (p_Customizable) ? "ammo_556nato" : "556" );
	}
}

string CoFFAMASAmmoName()
{
	return "ammo_556_famas";
}

string CoFFAMASName()
{
	return "weapon_coffamas";
}

void RegisterCoFFAMAS()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFFAMASName(), CoFFAMASName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Nato556_FAMAS", CoFFAMASAmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFFAMASName(), "cof/arifle", (p_Customizable) ? "ammo_556nato" : "556", "", CoFFAMASAmmoName() );
}