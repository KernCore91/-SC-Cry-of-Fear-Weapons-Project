// Author: KernCore

#include "../base"

enum CoFBOOKLASERAnimations_e
{
	CoFBOOKLASER_IDLE = 0,
	CoFBOOKLASER_SHOOT,
	CoFBOOKLASER_DRAW,
	CoFBOOKLASER_HOLSTER,
	CoFBOOKLASER_SPRINT_TO,
	CoFBOOKLASER_SPRINT_IDLE,
	CoFBOOKLASER_FROM
};

namespace CoFBOOKLASER
{
	//models
	string BOOK_W_MODEL    	= "models/cof/book/wld.mdl";
	string BOOK_V_MODEL    	= "models/cof/book/vwm.mdl";
	string BOOK_P_MODEL    	= "models/cof/book/wld.mdl";
	//sprites
	const array<string> iFlame = {
		"sprites/cof/flame1.spr",
		"sprites/cof/flame2.spr",
		"sprites/cof/flame3.spr",
		"sprites/cof/flame4.spr",
		"sprites/cof/flame5.spr"
	};
	//sounds
	const string BOOK_S_FLAMEI   	= "cof/guns/book/start.ogg";
	const string BOOK_S_FLAMEB   	= "cof/guns/book/burn.ogg";
	const string BOOK_S_FLAMEE   	= "cof/guns/book/end.ogg";
	//weapon info
	const int BOOKL_WEIGTH   	= 15;
	uint32 BOOKL_BASEDAMAGE  	= 5;
	//iSlot and iPosition in the Hud
	uint SLOT     	= 6;
	uint POSITION 	= 2;
}

class CFlame : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CoFBOOKLASER::iFlame[Math.RandomLong( 0, CoFBOOKLASER::iFlame.length() - 1 )] );

		self.pev.rendermode = kRenderTransAdd;
		self.pev.rendercolor.x = 255;
		self.pev.rendercolor.y = 255;
		self.pev.rendercolor.z = 255;
		self.pev.renderamt = 250;
		self.pev.scale = 0.1;
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		self.pev.frame = 0;
		SetThink( ThinkFunction( this.AnimateThink ) );
		self.pev.nextthink = g_Engine.time + 0.1;
		SetTouch( TouchFunction( this.FlameTouch ) );

		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );
	}

	void FlameTouch( CBaseEntity@ pOther )
	{
		// don't hit the guy that launched this flame or itself
		if( @pOther.edict() == @self.pev.owner )
			return;

		if( pOther.pev.ClassNameIs( self.pev.classname ) || @pOther.edict() == @self.edict()  )
			return;

		SetTouch( null );

		entvars_t@ pevOwner;
		if( self.pev.owner !is null )
			@pevOwner = @self.pev.owner.vars;
		else
			@pevOwner = self.pev;

		TraceResult tr = g_Utility.GetGlobalTrace();
		if( pOther.pev.takedamage != DAMAGE_NO && pOther.IsAlive() )
		{
			g_WeaponFuncs.ClearMultiDamage();

			if( pOther.pev.classname == "monster_cleansuit_scientist" || pOther.IsMachine() )
				pOther.TraceAttack( pevOwner, CoFBOOKLASER::BOOKL_BASEDAMAGE * 0.30, self.pev.velocity.Normalize(), tr, DMG_SLOWBURN | DMG_NEVERGIB );
			else if( pOther.pev.classname == "monster_gargantua" || pOther.pev.classname == "monster_babygarg" )
				pOther.TraceAttack( pevOwner, CoFBOOKLASER::BOOKL_BASEDAMAGE * 0.50, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB );
			else
				pOther.TraceAttack( pevOwner, CoFBOOKLASER::BOOKL_BASEDAMAGE, self.pev.velocity.Normalize(), tr, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB );

			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
		}

		if( pOther is null || pOther.IsBSPModel() )
			g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong( 1, 2 ) );

		self.pev.solid = SOLID_NOT;
		self.pev.movetype = MOVETYPE_NONE;
	}

	void AnimateThink()
	{
		self.pev.nextthink = g_Engine.time + 0.01;
		self.pev.framerate++;

		if( self.pev.framerate > 2 )
		{
			self.pev.frame++;
			self.pev.scale += 0.1;
			self.pev.framerate = 0;
		}

		if( self.pev.frame == 13 && g_EngineFuncs.PointContents( self.pev.origin ) != CONTENTS_WATER )
		{
			NetworkMessage smk_msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
				smk_msg.WriteByte( TE_SMOKE ); //MSG type enum
				smk_msg.WriteCoord( self.pev.origin.x ); //pos
				smk_msg.WriteCoord( self.pev.origin.y ); //pos
				smk_msg.WriteCoord( self.pev.origin.z ); //pos
				smk_msg.WriteShort( g_Game.PrecacheModel( "sprites/steam1.spr" ) );
				smk_msg.WriteByte( Math.RandomLong( 5, 10 ) ); //scale
				smk_msg.WriteByte( 50 ); //framerate
			smk_msg.End();
		}

		if( self.pev.frame > 19 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
	}
}

CFlame@ CreateFlames( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ cbeFlame = g_EntityFuncs.CreateEntity( "Flame", null, false );
	CFlame@ pFlame = cast<CFlame@>( CastToScriptClass( cbeFlame ) );

	g_EntityFuncs.SetOrigin( pFlame.self, vecStart );
	g_EntityFuncs.DispatchSpawn( pFlame.self.edict() );

	pFlame.pev.velocity = vecVelocity;
	pFlame.pev.angles = Math.VecToAngles( pFlame.pev.velocity );
	@pFlame.pev.owner = pevOwner.pContainingEntity;

	return pFlame;
}

string GetFlameName()
{
	return "Flame";
}

void RegisterFlame()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CFlame", GetFlameName() );
}

class weapon_cofbooklaser : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private bool m_bShooting;
	private float m_flNextSound;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFBOOKLASER::BOOK_W_MODEL );

		m_bShooting = false;
		m_flNextSound = 0;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFBOOKLASER::BOOK_W_MODEL );
		g_Game.PrecacheModel( CoFBOOKLASER::BOOK_V_MODEL );
		g_Game.PrecacheModel( CoFBOOKLASER::BOOK_P_MODEL );

		for( uint i = 0; i < CoFBOOKLASER::iFlame.length(); i++ )
			g_Game.PrecacheModel( CoFBOOKLASER::iFlame[i] );

		g_SoundSystem.PrecacheSound( CoFBOOKLASER::BOOK_S_FLAMEI );
		g_SoundSystem.PrecacheSound( CoFBOOKLASER::BOOK_S_FLAMEB );
		g_SoundSystem.PrecacheSound( CoFBOOKLASER::BOOK_S_FLAMEE );
		g_Game.PrecacheGeneric( "sound/" + CoFBOOKLASER::BOOK_S_FLAMEI );
		g_Game.PrecacheGeneric( "sound/" + CoFBOOKLASER::BOOK_S_FLAMEB );
		g_Game.PrecacheGeneric( "sound/" + CoFBOOKLASER::BOOK_S_FLAMEE );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/special/weapon_cofbooklaser.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot  	= CoFBOOKLASER::SLOT;
		info.iPosition 	= CoFBOOKLASER::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= -1;
		info.iWeight 	= CoFBOOKLASER::BOOKL_WEIGTH;

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
			bResult = Deploy( CoFBOOKLASER::BOOK_V_MODEL, CoFBOOKLASER::BOOK_P_MODEL, CoFBOOKLASER_DRAW, "trip", 1 );

			DeploySleeve();

			float deployTime = 1.36f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;

		if( m_bShooting )
		{
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFBOOKLASER::BOOK_S_FLAMEB );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFBOOKLASER::BOOK_S_FLAMEE, 1.0, ATTN_NORM, 0, PITCH_NORM );
			m_bShooting = false;
		}

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		bool bDidShoot = !m_bShooting;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			if( m_bShooting )
			{
				self.SendWeaponAnim( CoFBOOKLASER_SHOOT, 0, 0 );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.86f;
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFBOOKLASER::BOOK_S_FLAMEB );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFBOOKLASER::BOOK_S_FLAMEE, 1.0, ATTN_NORM, 0, PITCH_NORM );
				m_bShooting = false;
			}

			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
			return;
		}

		if( !m_bShooting )
		{
			self.SendWeaponAnim( CoFBOOKLASER_SHOOT, 0, 0 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFBOOKLASER::BOOK_S_FLAMEI, 1.0, ATTN_NORM, 0, PITCH_NORM );
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_flNextSound = g_Engine.time + 0.1;
			m_bShooting = true;
		}
		else if( m_flNextSound <= g_Engine.time )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFBOOKLASER::BOOK_S_FLAMEB, 1.0, ATTN_NORM, 0, PITCH_NORM );
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
			m_flNextSound = g_Engine.time + 0.3;
			bDidShoot = true;
		}
		Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 15 + g_Engine.v_up * -8;
		Vector vecDir = g_Engine.v_forward * 455;

		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.065;
		CoFDynamicLight( m_pPlayer.pev.origin, 22, 253, 226, 51, 5, 50 );
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		CreateFlames( m_pPlayer.pev, vecSrc, vecDir );
	}

	void ItemPreFrame()
	{
		if( m_pPlayer.pev.button & IN_ATTACK != 0 && (m_pPlayer.pev.button & IN_ATTACK2 != 0 || m_pPlayer.pev.button & IN_ALT1 != 0) )
		{
			if( m_bShooting )
			{
				self.SendWeaponAnim( CoFBOOKLASER_SHOOT, 0, 0 );
				self.m_flTimeWeaponIdle = self.m_flNextTertiaryAttack = WeaponTimeBase() + 0.86f;
				m_pPlayer.m_flNextAttack = 0.5f;
				g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFBOOKLASER::BOOK_S_FLAMEB );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFBOOKLASER::BOOK_S_FLAMEE, 1.0, ATTN_NORM, 0, PITCH_NORM );
				m_bShooting = false;
			}
		}
		BaseClass.ItemPreFrame();
	}

	void WeaponIdle()
	{
		if( m_bShooting )
		{
			self.SendWeaponAnim( CoFBOOKLASER_SHOOT, 0, 0 );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.86f;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, CoFBOOKLASER::BOOK_S_FLAMEB );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFBOOKLASER::BOOK_S_FLAMEE, 1.0, ATTN_NORM, 0, PITCH_NORM );
			m_bShooting = false;
		}

		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( CoFBOOKLASER_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 30, 31 );
	}
}

string CoFBOOKLASERName()
{
	return "weapon_cofbooklaser";
}

void RegisterCoFBOOKLASER()
{
	RegisterFlame();
	g_CustomEntityFuncs.RegisterCustomEntity( CoFBOOKLASERName(), CoFBOOKLASERName() );
	g_ItemRegistry.RegisterWeapon( CoFBOOKLASERName(), "cof/special" );
}