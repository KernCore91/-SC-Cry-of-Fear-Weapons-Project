// Author: KernCore

#include "../base"

enum CoFL85Animations_e
{
	CoFL85_IDLE = 0,
	CoFL85_DRAW_FIRST,
	CoFL85_DRAW,
	CoFL85_HOLSTER,
	CoFL85_SHOOT,
	CoFL85_SHOOT2,
	CoFL85_SHOOT_EMPTY,
	CoFL85_SWITCH,
	CoFL85_RELOAD,
	CoFL85_RELOAD_EMPTY,
	CoFL85_IRON_IDLE,
	CoFL85_IRON_SHOOT,
	CoFL85_IRON_SHOOT_EMPTY,
	CoFL85_IRON_SWITCH,
	CoFL85_IRON_TO,
	CoFL85_IRON_FROM,
	CoFL85_MELEE,
};

namespace CoFL85
{
	//models
	string L85_W_MODEL      	= "models/cof/l85/wrd.mdl";
	string L85_V_MODEL      	= "models/cof/l85/vwm.mdl";
	string L85_P_MODEL      	= "models/cof/l85/plr.mdl";
	string L85_A_MODEL      	= "models/cof/l85/mag.mdl";
	string L85_MAGEMPTY_MODEL	= "models/cof/l85/mag_e.mdl";
	//sound
	const string L85_SHOOT_SOUND 	= "cof/guns/l85/shoot.ogg";
	//weapon information
	const int L85_MAX_CARRY  	= (p_Customizable) ? 500 : 600;
	const int L85_MAX_CLIP   	= 30;
	const int L85_DEFAULT_GIVE 	= L85_MAX_CLIP * 3;
	const int L85_WEIGHT     	= 45;
	uint L85_DAMAGE           	= 18;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 5;
	uint POSITION 	= 8;
}

class weapon_cofl85 : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	//for weapon functions/modes
	int m_iL85MagEmpty;
	float e_usetimer;
	int mag_counter;
	bool m_WasDrawn;

	// Other Sounds
	private array<string> l85Sounds = {
		"cof/guns/l85/bltback.ogg",
		"cof/guns/l85/bltrel.ogg",
		"cof/guns/l85/rof.ogg",
		"cof/guns/l85/hit.ogg",
		"cof/guns/l85/magin.ogg",
		"cof/guns/l85/magout.ogg",
		"cof/guns/l85/magrel.ogg"
	};

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( CoFL85::L85_W_MODEL ) );

		self.m_iDefaultAmmo	= CoFL85::L85_DEFAULT_GIVE;
		g_iMode_ironsights 	= CoF_MODE_NOTAIMED;
		g_iMode_burst    	= CoF_MODE_AUTO;
		e_usetimer       	= 0;

		iAnimation       	= CoFL85_MELEE;
		iAnimation2      	= CoFL85_MELEE;

		mag_counter = CoFL85::L85_MAX_CLIP;
		m_WasDrawn = false;
		
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFL85::L85_W_MODEL );
		g_Game.PrecacheModel( CoFL85::L85_V_MODEL );
		g_Game.PrecacheModel( CoFL85::L85_P_MODEL );
		g_Game.PrecacheModel( CoFL85::L85_A_MODEL );
		g_Game.PrecacheModel( g_watersplash_spr );
		m_iL85MagEmpty 	= g_Game.PrecacheModel( CoFL85::L85_MAGEMPTY_MODEL );
		m_iShell       	= g_Game.PrecacheModel( mShellModel[3] ); //556

		CommonPrecache(); //Common sounds to all weapons
		PrecacheSound( l85Sounds );

		g_SoundSystem.PrecacheSound( CoFL85::L85_SHOOT_SOUND );
		g_SoundSystem.PrecacheSound( EMPTY_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + CoFL85::L85_SHOOT_SOUND );
		g_Game.PrecacheGeneric( "sound/" + EMPTY_SHOOT_SOUND );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel02.spr" );
		g_Game.PrecacheModel( "sprites/" + CoFCOMMON::FIREMODE_SPRT );

		g_Game.PrecacheGeneric( "sprites/" + CoFCOMMON::FIREMODE_SPRT );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel02.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/arifle/weapon_cofl85.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= CoFL85::L85_MAX_CARRY;
		info.iMaxAmmo2 	= 5;
		info.iMaxClip 	= CoFL85::L85_MAX_CLIP;
		info.iSlot   	= CoFL85::SLOT;
		info.iPosition 	= CoFL85::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags  	= ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY;
		info.iWeight 	= CoFL85::L85_WEIGHT;

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

			float deployTime;
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFL85::L85_V_MODEL, CoFL85::L85_P_MODEL, CoFL85_DRAW_FIRST, "m16", 0 );
				deployTime = 2.0f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFL85::L85_V_MODEL, CoFL85::L85_P_MODEL, CoFL85_DRAW, "m16", 0 );
				deployTime = 0.7f;
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
		EffectsFOVOFF();
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
				self.SendWeaponAnim( CoFL85_SHOOT_EMPTY, 0, 0 );
			}
			else if( g_iMode_ironsights == CoF_MODE_AIMED )
			{
				self.SendWeaponAnim( CoFL85_IRON_SHOOT_EMPTY, 0, 0 );
			}
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		if( g_iMode_burst == CoF_MODE_AUTO )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + GetFireRate( 650 );
		}
		else if( g_iMode_burst == CoF_MODE_SINGLE )
		{
			if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
				return;

			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
		}

		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFL85_SHOOT, 0, 0 );
		}
		else if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFL85_IRON_SHOOT, 0, 0 );
		}

		Vector vecCone;
		if( m_pPlayer.pev.velocity == g_vecZero ) // Player is not moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_1DEGREES : VECTOR_CONE_3DEGREES;
		}
		else if( m_pPlayer.pev.velocity != g_vecZero ) // Player is moving
		{
			vecCone = (g_iMode_ironsights == CoF_MODE_AIMED) ? VECTOR_CONE_2DEGREES : VECTOR_CONE_4DEGREES;
		}

		FireTrueBullet( CoFL85::L85_SHOOT_SOUND, true, CoFL85::L85_DAMAGE, vecCone, 8192, false, DMG_GENERIC );

		float m_iPunchAngle;
		if( (m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.25f, -1.50f ) : Math.RandomFloat( -3.25f, -3.00f );
		}
		else if( !(m_pPlayer.pev.flags & FL_DUCKING != 0) ) // Player is not ducking
		{
			m_iPunchAngle = (g_iMode_ironsights == CoF_MODE_AIMED) ? Math.RandomFloat( -1.35f, -1.55f ) : Math.RandomFloat( -4.00f, -3.00f );
		}
		Vector vecShellVelocity, vecShellOrigin;
		if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 9, 5, -7, false, false );
		else
			CoFGetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 9, 2, -4, false, false );
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );

		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
		mag_counter--;
		punchangle( m_iPunchAngle, Math.RandomFloat( -0.5, 0.5 ), Math.RandomFloat( 0.5f, 0.75f ) );
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
					self.SendWeaponAnim( CoFL85_IRON_TO, 0, 1 );
					EffectsFOVON( 25 );
					break;
				}
				case CoF_MODE_AIMED:
				{
					self.SendWeaponAnim( CoFL85_IRON_FROM, 0, 1 );
					EffectsFOVOFF();
					break;
				}
			}
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
	}

	void ItemPreFrame()
	{
		//m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 999 );

		if( m_reloadTimer < g_Engine.time && canReload )
			self.Reload();
			
		if( (m_pPlayer.pev.button & IN_USE != 0) && (m_pPlayer.pev.button & IN_ATTACK2 != 0) )
		{
			if( e_usetimer < g_Engine.time )
			{
				
			}
		}

		BaseClass.ItemPreFrame();
	}

	void ChangeFirerate() // switch fire modes (support for only 2 modes)
	{
		if( m_pPlayer.pev.button & IN_USE == 0 || m_pPlayer.pev.button & IN_RELOAD == 0 )
			return;
		else if( (m_pPlayer.pev.button & IN_USE != 0) && (m_pPlayer.pev.button & IN_RELOAD != 0) )
		{
			if( e_usetimer < g_Engine.time )
			{
				if( g_iMode_burst == CoF_MODE_AUTO )
				{
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFL85_SWITCH : CoFL85_IRON_SWITCH, 0, 0 );
					g_iMode_burst = CoF_MODE_SINGLE;
				}
				else if( g_iMode_burst == CoF_MODE_SINGLE )
				{
					self.SendWeaponAnim( (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? CoFL85_SWITCH : CoFL85_IRON_SWITCH, 0, 0 );
					g_iMode_burst = CoF_MODE_AUTO;
				}
				DisplayFiremodeSprite();
				e_usetimer = g_Engine.time + 0.83f;
				m_pPlayer.m_flNextAttack = 0.83f;
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.83f;
			}
		}
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

		if( self.m_iClip == CoFL85::L85_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;

		if( g_iMode_ironsights == CoF_MODE_AIMED )
		{
			self.SendWeaponAnim( CoFL85_IRON_FROM, 0, 0 );
			m_reloadTimer = g_Engine.time + 0.175f;
			m_pPlayer.m_flNextAttack = 0.175;
			canReload = true;
		}
		EffectsFOVOFF();

		if( m_reloadTimer < g_Engine.time )
		{
			(self.m_iClip == 0) ? Reload( CoFL85::L85_MAX_CLIP, CoFL85_RELOAD_EMPTY, 4.55f, 1 ) : Reload( CoFL85::L85_MAX_CLIP, CoFL85_RELOAD, 3.27f, 1 );
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
		mag_counter = CoFL85::L85_MAX_CLIP;
		ClipCasting( m_pPlayer.pev.origin, m_pPlayer.pev.view_ofs + g_Engine.v_right * -48 + g_Engine.v_up * 16 + g_Engine.v_forward * 8, m_iL85MagEmpty, false, 0 );
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
			self.SendWeaponAnim( CoFL85_IRON_IDLE, 0, 1 );
		}
		else if( g_iMode_ironsights == CoF_MODE_NOTAIMED )
		{
			self.SendWeaponAnim( CoFL85_IDLE, 0, 1 );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class Nato556_L85 : ScriptBasePlayerAmmoEntity, ammo_base
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFL85::L85_A_MODEL );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( CoFL85::L85_A_MODEL );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, CoFL85::L85_MAX_CLIP, CoFL85::L85_MAX_CARRY, (p_Customizable) ? "ammo_556nato" : "556" );
	}
}

string CoFL85AmmoName()
{
	return "ammo_556_l85";
}

string CoFL85Name()
{
	return "weapon_cofl85";
}

void RegisterCoFL85()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFL85Name(), CoFL85Name() );
	g_CustomEntityFuncs.RegisterCustomEntity( "Nato556_L85", CoFL85AmmoName() );
	g_ItemRegistry.RegisterWeapon( CoFL85Name(), "cof/arifle", (p_Customizable) ? "ammo_556nato" : "556", "", CoFL85AmmoName() );
}