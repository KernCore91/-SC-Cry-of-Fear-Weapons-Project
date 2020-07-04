// Author: KernCore

#include "../base"

enum CoFCAMERAAnimations_e
{
	CoFCAMERA_IDLE = 0,
	CoFCAMERA_DRAW_FIRST,
	CoFCAMERA_HOLSTER,
	CoFCAMERA_SHOOT,
	CoFCAMERA_FIDGET1,
	CoFCAMERA_JUMP_TO,
	CoFCAMERA_JUMP_FROM,
	CoFCAMERA_DRAW,
	CoFCAMERA_FIDGET2,
	CoFCAMERA_FIDGET3,
	CoFCAMERA_SPRINT_TO,
	CoFCAMERA_SPRINT_IDLE,
	CoFCAMERA_SPRINT_FROM,
	CoFCAMERA_MELEE	
};

namespace CoFCAMERA
{
	//models
	string CAMERA_W_MODEL  	= "models/cof/camera/wld.mdl";
	string CAMERA_V_MODEL  	= "models/cof/camera/vwm.mdl";
	string CAMERA_P_MODEL  	= "models/cof/camera/wld.mdl";
	//sounds
	const string CAMERA_S_SHOOT  	= "cof/guns/camera/photo.ogg";
	const string CAMERA_S_CHARGE 	= "cof/guns/camera/charge.ogg";
	const string CAMERA_S_LEVER 	= "cof/guns/camera/lever.ogg";
	//weapon info
	const int CAMERA_WEIGHT  	= 10;
	//iSlot and iPosition in the Hud
	uint SLOT      	= 6;
	uint POSITION 	= 3;
}

class weapon_cofcamera : ScriptBasePlayerWeaponEntity, weapon_base
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	bool m_WasDrawn;
	int m_CameraRadius = 38;
	private float resetCounter = 0;
	private bool canReset, notargeton;
	array<EHandle> monsters;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, CoFCAMERA::CAMERA_W_MODEL );

		iAnimation  	= CoFCAMERA_MELEE;
		iAnimation2 	= CoFCAMERA_MELEE;
		m_WasDrawn = false;
		self.m_iClip = -1;
		m_bUseCustomScale = true;
		self.pev.scale = 1.3;

		self.FallInit();
	}

	void Materialize()
	{
		BaseClass.Materialize();
		//g_Game.AlertMessage( at_console, "materialized" );
		CommonMaterialize();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( CoFCAMERA::CAMERA_W_MODEL );
		g_Game.PrecacheModel( CoFCAMERA::CAMERA_V_MODEL );
		g_Game.PrecacheModel( CoFCAMERA::CAMERA_P_MODEL );

		g_SoundSystem.PrecacheSound( CoFCAMERA::CAMERA_S_SHOOT );
		g_SoundSystem.PrecacheSound( CoFCAMERA::CAMERA_S_CHARGE );
		g_SoundSystem.PrecacheSound( CoFCAMERA::CAMERA_S_LEVER );
		g_Game.PrecacheGeneric( "sound/" + CoFCAMERA::CAMERA_S_SHOOT );
		g_Game.PrecacheGeneric( "sound/" + CoFCAMERA::CAMERA_S_CHARGE );
		g_Game.PrecacheGeneric( "sound/" + CoFCAMERA::CAMERA_S_LEVER );

		g_Game.PrecacheModel( "sprites/cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/wpn_sel01.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "cof/special/weapon_cofcamera.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot  	= CoFCAMERA::SLOT;
		info.iPosition 	= CoFCAMERA::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= -1;
		info.iWeight 	= CoFCAMERA::CAMERA_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return CommonAddToPlayer( pPlayer );
	}

	bool Deploy()
	{
		float deployTime;
		bool bResult;
		{
			if( m_WasDrawn == false )
			{
				bResult = Deploy( CoFCAMERA::CAMERA_V_MODEL, CoFCAMERA::CAMERA_P_MODEL, CoFCAMERA_DRAW_FIRST, "trip", 0 );
				deployTime = 1.63f;
				m_WasDrawn = true;
			}
			else if( m_WasDrawn == true )
			{
				bResult = Deploy( CoFCAMERA::CAMERA_V_MODEL, CoFCAMERA::CAMERA_P_MODEL, CoFCAMERA_DRAW, "trip", 0 );
				deployTime = 1.0f;
			}

			DeploySleeve();

			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	/** Player just holstered/dropped the weapon */
	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		SetThink( null );

		if( notargeton )
		{
			m_pPlayer.pev.flags &= ~FL_NOTARGET;
			notargeton = false;
		}

		/** Reset the monster straight away */
		if( monsters !is null )
		{
			ResetState( monsters );
			monsters.resize( 0 );
		}

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		self.SendWeaponAnim( CoFCAMERA_SHOOT );
		CoFDynamicLight( m_pPlayer.EyePosition(), m_CameraRadius, 254, 254, 254, 1, 100 );

		CameraConfigs();
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, CoFCAMERA::CAMERA_S_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, CoFCAMERA::CAMERA_S_CHARGE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.3f;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
	}

	void NoTargetThink()
	{
		m_pPlayer.pev.flags &= ~FL_NOTARGET;
		notargeton = false;
		//g_Game.AlertMessage( at_console, "Notarget off\n" );
	}

	/* Ignore List */
	bool checkClassname( CBaseEntity@ m_Entity )
	{
		return m_Entity.pev.classname != "monster_generic" && /* Can cause bugs and break the map */
			m_Entity.pev.classname != "monster_gargantua" && /* Too big */ 
			m_Entity.pev.classname != "monster_bigmomma" && /* Too big */
			m_Entity.pev.classname != "monster_nihilanth" && /* Way too big */
			m_Entity.pev.classname != "monster_tentacle" && /* Cannot see flashes */
			m_Entity.pev.classname != "monster_barnacle" && /* Can cause bugs */
			m_Entity.pev.classname != "monster_kingpin"; /* Too big */
	}

	void CameraConfigs()
	{
		CBaseEntity@ pEntity = null;
		while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, m_pPlayer.GetGunPosition(), m_CameraRadius * 5, "*", "classname" ) ) !is null )
		{
			EHandle g_ehandle = pEntity;
			if( g_ehandle.GetEntity().IsMonster() && !g_ehandle.GetEntity().IsNetClient() ) /** Found monster*/
			{
				if( g_ehandle.GetEntity().IsAlive() && !g_ehandle.GetEntity().IsPlayerAlly() && !g_ehandle.GetEntity().IsMachine() ) /** Monster is alive/ is not ally/ is not machine*/
				{
					if( checkClassname( g_ehandle.GetEntity() ) ) /** Monster is not one of these*/
					{
						monsters.insertLast( g_ehandle ); //Monster was added to array
						StopMonster( g_ehandle ); //Monster is completely stuck

						notargeton = true;
						m_pPlayer.pev.flags |= FL_NOTARGET;
						SetThink( ThinkFunction( NoTargetThink ) ); //Set notarget in the player, fixes getting attention of the stopped monster
						self.pev.nextthink = WeaponTimeBase() + 0.1;

						resetCounter = g_Engine.time + 5.0f; //Timer is set
						canReset = true;
					}
				}
			}
		}
	}

	void ItemPreFrame()
	{
		if( resetCounter < g_Engine.time && canReset )
		{
			ResetState( monsters ); // Monster reseted
			resetCounter = 0;

			if( monsters !is null )
				monsters.resize( 0 );

			canReset = false;
		}

		BaseClass.ItemPreFrame();
	}

	void StopMonster( EHandle& in eMonster )
	{
		CBaseMonster@ stop_monster = cast<CBaseMonster@>( eMonster.GetEntity() );

		stop_monster.SetState( MONSTERSTATE_PLAYDEAD );
		stop_monster.CanPlaySentence( false );
		stop_monster.Stop();
		stop_monster.StopAnimation();
	}

	void ResetState( array<EHandle>& in eMonster )
	{
		for( uint i = 0; i < eMonster.length(); i++ )
		{
			CBaseMonster@ monster_resume = cast<CBaseMonster@>( eMonster[i].GetEntity() );
			if( monster_resume !is null )
			{
				if( !monster_resume.IsNetClient() )
				{
					if( monster_resume.IsAlive() )
					{
						monster_resume.RunAI();
						monster_resume.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
						monster_resume.ClearSchedule();
						monster_resume.SetState( MONSTERSTATE_IDLE );
						monster_resume.CanPlaySentence( true );
						monster_resume.StartMonster();
						monster_resume.ResetSequenceInfo();
					}
				}
			}
		}
	}

	void SecondaryAttack()
	{
		if( !Swing( 1, 37, 1, 0.95f, 15, false ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
	}

	void ItemPostFrame()
	{
		BaseClass.ItemPostFrame();
	}

	void SwingAgain()
	{
		Swing( 0, 37, 1, 0.95f, 15, false );
	}

	void WeaponIdle()
	{
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;

		switch( Math.RandomLong( 0, 3 ) )
		{
			case 0:	iAnim = CoFCAMERA_IDLE;
			break;
			
			case 1: iAnim = CoFCAMERA_FIDGET1;
			break;

			case 2: iAnim = CoFCAMERA_FIDGET2;
			break;

			case 3: iAnim = CoFCAMERA_FIDGET3;
			break;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 2, 4 );
	}
}

string CoFCAMERAName()
{
	return "weapon_cofcamera";
}

void RegisterCoFCAMERA()
{
	g_CustomEntityFuncs.RegisterCustomEntity( CoFCAMERAName(), CoFCAMERAName() );
	g_ItemRegistry.RegisterWeapon( CoFCAMERAName(), "cof/special" );
}