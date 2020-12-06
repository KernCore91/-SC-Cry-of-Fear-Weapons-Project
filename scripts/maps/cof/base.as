// Author: KernCore

enum CoFIRONSIGHTS_e
{
	CoF_MODE_NOTAIMED = 0,
	CoF_MODE_AIMED
};

enum CoFBURSTMODE_e
{
	CoF_MODE_BURST = 0,
	CoF_MODE_SINGLE,
	CoF_MODE_AUTO
};

namespace CoFCOMMON
{
	const string DEPLOY_SLEEVE1   	= "cof/guns/foley1.ogg";
	const string DEPLOY_SLEEVE2   	= "cof/guns/foley2.ogg";
	const string DEPLOY_SLEEVE3   	= "cof/guns/foley3.ogg";
	// For heavier weapons
	const string MELEE_R_SOUND_HIT 	= "cof/guns/m_hit.ogg";
	const string MELEE_R_SOUND_MISS	= "cof/guns/m_swing.ogg";
	// For ligher weapons
	const string MELEE_P_SOUND_HIT 	= "cof/guns/p_smack.ogg";
	const string MELEE_P_SOUND_MISS	= "cof/guns/p_swing2.ogg";
	// For Ammo Pickups
	const string ITEM_SOUND_PICK 	= "cof/items/itemget.ogg";
	const string WEAPON_SOUND_GET 	= "cof/items/weapget.ogg";
	const string FIREMODE_SPRT  	= "cof/rof.spr";
}

mixin class weapon_base
{
	array<string> mShellModel = {
		"models/cof/shells/9mm.mdl", //9mm common, 0
		"models/cof/shells/38.mdl", //.38 special in Revolver, 1
		"models/cof/shells/45acp.mdl", //.45acp in P345, 2
		"models/cof/shells/556.mdl", //5.56 common, 3
		"models/cof/shells/792.mdl", //7.92mm Mauser, 4
		"models/cof/shells/303.mdl", //.303 British, 5
		"models/cof/shells/12g.mdl", //common 12 gauge buckshot, 6
		"models/cof/shells/545mm.mdl", //5.45mm in AK-74, 7
		"models/cof/shells/50ae.mdl", //.50 AE in Desert Eagle, 8
		"models/cof/shells/454c.mdl", //.454 Casull, 9
		"models/cof/shells/454c_g.mdl" //.454 Casull Special, 10
	};

	void CommonPrecache()
	{
		g_SoundSystem.PrecacheSound( CoFCOMMON::MELEE_R_SOUND_HIT );
		g_SoundSystem.PrecacheSound( CoFCOMMON::MELEE_R_SOUND_MISS );
		g_SoundSystem.PrecacheSound( CoFCOMMON::MELEE_P_SOUND_HIT );
		g_SoundSystem.PrecacheSound( CoFCOMMON::MELEE_P_SOUND_MISS );
		g_SoundSystem.PrecacheSound( CoFCOMMON::DEPLOY_SLEEVE1 );
		g_SoundSystem.PrecacheSound( CoFCOMMON::DEPLOY_SLEEVE2 );
		g_SoundSystem.PrecacheSound( CoFCOMMON::DEPLOY_SLEEVE3 );
		g_SoundSystem.PrecacheSound( CoFCOMMON::ITEM_SOUND_PICK );
		g_SoundSystem.PrecacheSound( CoFCOMMON::WEAPON_SOUND_GET );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::MELEE_R_SOUND_HIT );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::MELEE_R_SOUND_MISS );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::MELEE_P_SOUND_HIT );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::MELEE_P_SOUND_MISS );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::DEPLOY_SLEEVE1 );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::DEPLOY_SLEEVE2 );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::DEPLOY_SLEEVE3 );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::ITEM_SOUND_PICK );
		g_Game.PrecacheGeneric( "sound/" + CoFCOMMON::WEAPON_SOUND_GET );
	}

	void PrecacheSound( const array<string> pSound )
	{
		for( uint i = 0; i < pSound.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( pSound[i] );
			g_Game.PrecacheGeneric( "sound/" + pSound[i] );
		}
	}

	bool CommonAddToPlayer( CBasePlayer@ pPlayer ) // adds a weapon to the player
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			weapon.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
		weapon.End();

		return true;
	}

	string g_watersplash_spr = "sprites/wep_smoke_01.spr";
	void te_bubbletrail( Vector start, Vector end, string sprite = "sprites/bubble.spr", float height = 128.0f, uint8 count = 16, float speed = 16.0f, NetworkMessageDest msgType = MSG_BROADCAST )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, null );
			m.WriteByte( TE_BUBBLETRAIL);
			m.WriteCoord( start.x );
			m.WriteCoord( start.y );
			m.WriteCoord( start.z );
			m.WriteCoord( end.x );
			m.WriteCoord( end.y );
			m.WriteCoord( end.z );
			m.WriteCoord( height );
			m.WriteShort( g_Game.PrecacheModel( sprite ) );
			m.WriteByte( count );
			m.WriteCoord( speed );
		m.End();
	}

	void te_spritespray( Vector pos, Vector velocity, string sprite = "sprites/bubble.spr", uint8 count = 8, uint8 speed = 16, uint8 noise = 255, NetworkMessageDest msgType = MSG_BROADCAST )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, null );
			m.WriteByte( TE_SPRITE_SPRAY );
			m.WriteCoord( pos.x );
			m.WriteCoord( pos.y );
			m.WriteCoord( pos.z );
			m.WriteCoord( velocity.x );
			m.WriteCoord( velocity.y );
			m.WriteCoord( velocity.z );
			m.WriteShort( g_Game.PrecacheModel( sprite ) );
			m.WriteByte( count );
			m.WriteByte( speed );
			m.WriteByte( noise );
		m.End();

		switch( Math.RandomLong( 0, 2 ) )
		{
			case 0: g_SoundSystem.PlaySound( self.edict(), CHAN_STREAM, "player/pl_slosh1.wav", 1, ATTN_NORM, 0, PITCH_NORM, 0, true, pos ); break;
			case 1: g_SoundSystem.PlaySound( self.edict(), CHAN_STREAM, "player/pl_slosh2.wav", 1, ATTN_NORM, 0, PITCH_NORM, 0, true, pos ); break;
			case 2: g_SoundSystem.PlaySound( self.edict(), CHAN_STREAM, "player/pl_slosh3.wav", 1, ATTN_NORM, 0, PITCH_NORM, 0, true, pos ); break;
		}
	}

	void CustomTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if( pPlayer.HasNamedPlayerItem( self.pev.classname ) !is null )
			return;

		if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::WEAPON_SOUND_GET, 1, ATTN_NORM );
		}
	}

	void CustomUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if( !pActivator.IsPlayer() || !pActivator.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

		if( pPlayer.HasNamedPlayerItem( self.pev.classname ) !is null )
			return;

		if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::WEAPON_SOUND_GET, 1, ATTN_NORM );
		}
	}

	protected bool m_fDropped;
	CBasePlayerItem@ DropItem()
	{
		if( m_bUseCustomScale )
			self.pev.scale = 1.3;
		else
			self.pev.scale = 1.0;

		m_fDropped = true;
		return self;
	}

	void CommonMaterialize()
	{
		//SetTouch( TouchFunction( CustomTouch ) );
		//SetUse( UseFunction( CustomUse ) );
	}

	void CoFDynamicTracer( Vector start, Vector end, NetworkMessageDest msgType = MSG_PVS, edict_t@ dest = null )
	{
		NetworkMessage CoFDT( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
			CoFDT.WriteByte( TE_TRACER );
			CoFDT.WriteCoord( start.x );
			CoFDT.WriteCoord( start.y );
			CoFDT.WriteCoord( start.z );
			CoFDT.WriteCoord( end.x );
			CoFDT.WriteCoord( end.y );
			CoFDT.WriteCoord( end.z );
		CoFDT.End();
	}

	void PlayTracer( CBasePlayer@ pPlayer, Vector& in vecAttachOrigin, Vector& in vecAttachAngles, TraceResult& in tr )
	{
		g_EngineFuncs.GetAttachment( pPlayer.edict(), 0, vecAttachOrigin, vecAttachAngles );
		CoFDynamicTracer( vecAttachOrigin + g_Engine.v_forward * 64, tr.vecEndPos );
	}

	// water splashes and bubble trails for bullets
	void water_bullet_effects( Vector vecSrc, Vector vecEnd )
	{
		// bubble trails
		bool startInWater   	= g_EngineFuncs.PointContents( vecSrc ) == CONTENTS_WATER;
		bool endInWater     	= g_EngineFuncs.PointContents( vecEnd ) == CONTENTS_WATER;
		if( startInWater or endInWater )
		{
			Vector bubbleStart	= vecSrc;
			Vector bubbleEnd	= vecEnd;
			Vector bubbleDir	= bubbleEnd - bubbleStart;
			float waterLevel;

			// find water level relative to trace start
			Vector waterPos 	= (startInWater) ? bubbleStart : bubbleEnd;
			waterLevel      	= g_Utility.WaterLevel( waterPos, waterPos.z, waterPos.z + 1024 );
			waterLevel      	-= bubbleStart.z;

			// get percentage of distance travelled through water
			float waterDist	= 1.0f; 
			if( !startInWater or !endInWater )
				waterDist	-= waterLevel / (bubbleEnd.z - bubbleStart.z);
			if( !endInWater )
				waterDist	= 1.0f - waterDist;

			// clip trace to just the water portion
			if( !startInWater )
				bubbleStart	= bubbleEnd - bubbleDir*waterDist;
			else if( !endInWater )
				bubbleEnd 	= bubbleStart + bubbleDir*waterDist;

			// a shitty attempt at recreating the splash effect
			Vector waterEntry = (endInWater) ? bubbleStart : bubbleEnd;
			if( !startInWater or !endInWater )
			{
				te_spritespray( waterEntry, Vector( 0, 0, 1 ), g_watersplash_spr, 1, 64, 0);
			}

			// waterlevel must be relative to the starting point
			if( !startInWater or !endInWater )
				waterLevel = (bubbleStart.z > bubbleEnd.z) ? 0 : bubbleEnd.z - bubbleStart.z;

			// calculate bubbles needed for an even distribution
			int numBubbles = int( ( bubbleEnd - bubbleStart ).Length() / 128.0f );
			numBubbles = Math.max( 1, Math.min( 255, numBubbles ) );

			//te_bubbletrail( bubbleStart, bubbleEnd, "sprites/bubble.spr", waterLevel, numBubbles, 16.0f );
		}
	}

	edict_t@ ENT( const entvars_t@ pev )
	{
		return pev.pContainingEntity;
	}

	void Reload( int iAmmo, int iAnim, float iTimer, int iBodygroup )
	{
		self.DefaultReload( iAmmo, iAnim, iTimer, iBodygroup );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + iTimer;
	}

	bool Deploy( string& in vmodel, string& in pmodel, int& in iAnim, string& in pAnim, int& in iBodygroup )
	{
		self.pev.scale = 1.0;
		m_fDropped = false;
		self.DefaultDeploy( self.GetV_Model( vmodel ), self.GetP_Model( pmodel ), iAnim, pAnim, 0, iBodygroup );
		return true;
	}

	void punchangle( float& in punch_x, float& in punch_y, float& in punch_z, bool shouldrise = false )
	{
		if( shouldrise )
			m_pPlayer.pev.punchangle.x += punch_x;
		else
			m_pPlayer.pev.punchangle.x = punch_x;

		m_pPlayer.pev.punchangle.y = punch_y;
		m_pPlayer.pev.punchangle.z -= punch_z;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	void CoFGetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale, bool leftShell, bool downShell )
	{
		Vector vecForward, vecRight, vecUp;
	
		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
	
		const float fR = (leftShell == true) ? Math.RandomFloat( -120, -60 ) : Math.RandomFloat( 60, 120 );
		const float fU = (downShell == true) ? Math.RandomFloat( -150, -90 ) : Math.RandomFloat( 90, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * Math.RandomFloat( 1, 50 );
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}

	protected bool mIsLaserActivated;
	protected bool m_IsPullingBack = false;
	CSprite@ pdot;
	protected int iAnimation;
	protected int iAnimation2;
	protected int g_iMode_ironsights;
	TraceResult m_trHit;
	protected int m_iShell;
	protected int m_iDroppedClip;
	protected float m_reloadTimer = 0;
	protected bool canReload;
	// Sounds common to all classes to precache
	protected string EMPTY_SHOOT_SOUND 	= "cof/guns/wpn_empty.ogg";
	protected string LASER_SPRITE   	= "sprites/cof/laserdot.spr";
	protected int g_iMode_burst;
	protected bool m_bUseCustomScale = false;
	protected Vector2D FiremodesPos( -5, -60 );

	void FiremodesSpr( Vector2D POS, int frame, float holdTime = 1.0, int alpha = 255 ) // send firemode HUD sprites
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
		params.color1 = RGBA( 100, 130, 200, alpha );
		params.color2 = RGBA( 255, 0, 0, alpha );
		// Frame management
		params.frame = frame; // 0 = Full auto; 1 = Burst fire; 2 = Semi-auto
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

	void DisplayFiremodeSprite() // displays the fire mode sprite in the HUD
	{
		switch( g_iMode_burst )
		{
			case CoF_MODE_AUTO:
				FiremodesSpr( FiremodesPos, 0, -1 );
				break;
			
			case CoF_MODE_BURST:
				FiremodesSpr( FiremodesPos, 1, -1 );
				break;

			case CoF_MODE_SINGLE:
				FiremodesSpr( FiremodesPos, 2, -1 );
				break;
		}
		FiremodesTxt();
	}

	void FiremodesTxt() // displays text on the player's hud so he knows how to change the firemode
	{
		HUDTextParams params;
		params.channel = 4;
		params.fadeinTime = 0;
		params.fadeoutTime = 0.7;
		params.holdTime = 1.0;
		params.effect = 0;
		params.x = 0.9595;
		params.y = 0.857;
		params.r1 = RGBA_SVENCOOP.r;
		params.g1 = RGBA_SVENCOOP.g;
		params.b1 = RGBA_SVENCOOP.b;
		params.a1 = 255;
		g_PlayerFuncs.HudMessage( m_pPlayer, params, "E + R" );
	}

	void LaserConfigs()
	{
		// Create the laser and configurate it
		Vector vecColor( 255, 0, 0 );
		@pdot = g_EntityFuncs.CreateSprite( LASER_SPRITE, m_pPlayer.pev.origin, true, 100 );
		pdot.pev.rendermode = kRenderGlow;
		pdot.pev.renderfx 	= kRenderFxNoDissipation;
		pdot.pev.movetype 	= MOVETYPE_NONE;
		pdot.pev.solid  	= SOLID_NOT;
		pdot.pev.renderamt 	= 255;
		pdot.pev.rendercolor= vecColor;
		pdot.pev.scale  	= 0.4;
		// Make it appear away from the player, not inside of him (little bug)
		pdot.pev.origin 	= g_Engine.v_forward * 8192;
	}

	double GetFireRate( double& in roundspmin )
	{
		double firerate;
		roundspmin = (roundspmin / 60);
		firerate = (1 / roundspmin);
		return firerate;
	}

	void UpdateLaser()
	{
		// Checking nullity here in case the laser got killed somehow
		if( pdot !is null )
		{
			// Get data and traceline
			g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle );
			Vector vecSrc   	= m_pPlayer.GetGunPosition();
			Vector vecAiming	= g_Engine.v_forward * 8192;

			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecSrc + vecAiming, dont_ignore_monsters, m_pPlayer.edict(), tr );

			// Now, update the laser's position. Should appear at where the player's aiming
			g_EntityFuncs.SetOrigin( pdot, tr.vecEndPos );
		}
		else
		{
			// Our laser did indeed get killed somehow, set laser to inactive
			mIsLaserActivated = false;
			@pdot = @null;
		}
	}

	void DeploySleeve()
	{
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); break;
			case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); break;
			case 2: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, CoFCOMMON::DEPLOY_SLEEVE3, VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); break;
		}
	}

	void CoFDynamicLight( Vector& in vecPos, int& in radius, int& in r, int& in g, int& in b, int8& in life, int& in decay )
	{
		NetworkMessage CoFDL( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			CoFDL.WriteByte( TE_DLIGHT );
			CoFDL.WriteCoord( vecPos.x );
			CoFDL.WriteCoord( vecPos.y );
			CoFDL.WriteCoord( vecPos.z );
			CoFDL.WriteByte( radius );
			CoFDL.WriteByte( int(r) );
			CoFDL.WriteByte( int(g) );
			CoFDL.WriteByte( int(b) );
			CoFDL.WriteByte( life );
			CoFDL.WriteByte( decay );
		CoFDL.End();
	}

	void SetFOV( int fov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
	}
	
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom == true )
		{
			SetFOV( 0 ); // 0 means reset to default fov
		}
		else if ( self.m_fInZoom == false )
		{
			SetFOV( zoomedFOV );
		}
	}

	void EffectsFOVON( int value )
	{
		ToggleZoom( value );
		m_pPlayer.SetMaxSpeedOverride( 150 ); //m_pPlayer.pev.maxspeed = 150;
		m_pPlayer.SetVModelPos( Vector( 0, 0, 0 ) );
		g_iMode_ironsights = CoF_MODE_AIMED;
	}

	void EffectsFOVOFF()
	{
		ToggleZoom( 0 );
		m_pPlayer.SetMaxSpeedOverride( -1 ); //m_pPlayer.pev.maxspeed = 0;
		m_pPlayer.ResetVModelPos();
		g_iMode_ironsights = CoF_MODE_NOTAIMED;
	}

	bool CheckButton()
	{
		return m_pPlayer.pev.button & IN_ATTACK != 0 || m_pPlayer.pev.button & IN_ATTACK2 != 0 || m_pPlayer.pev.button & IN_ALT1 != 0;
	}

	// Works very well in lower ping servers, since it's not predicted by the client
	// you will experience weird snaps when using this function in high latency servers
	Vector AngleRecoil( float& in x, float& in y, float& in z = 0 )
	{
		Vector vecTemp = m_pPlayer.pev.v_angle;
		vecTemp.x += x;
		vecTemp.y += y;
		vecTemp.z += z;
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		return m_pPlayer.pev.angles;
	}

	void FireTrueBullet( const string iSoundName, bool iIsRifle, int iBulletDamage, Vector& in Vec_Accuracy, float iMaxDist, bool iMultiDamage, int iDamageBits, bool soundChange = false, bool isLoopable = false )
	{
		// Common between each weapon
		Vector vecSrc    	= m_pPlayer.GetGunPosition();
		Vector vecAiming 	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		m_pPlayer.m_iWeaponVolume 	= NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash 	= NORMAL_GUN_FLASH;

		if( !isLoopable )
			g_SoundSystem.EmitSoundDyn( self.pev.owner, (soundChange) ? CHAN_AUTO : CHAN_WEAPON, iSoundName, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		
		--self.m_iClip;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		CoFDynamicLight( m_pPlayer.EyePosition() + g_Engine.v_forward * 64, 18, 240, 180, 100, 1, 100 );
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Vec_Accuracy, iMaxDist, BULLET_PLAYER_CUSTOMDAMAGE, 2, iBulletDamage );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		TraceResult tr;
		float x, y;

		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir	= vecAiming + x * Vec_Accuracy.x * g_Engine.v_right + y * Vec_Accuracy.y * g_Engine.v_up;
		Vector vecEnd	= vecSrc + vecDir * iMaxDist;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		Vector vecTracerOr, vecTracerAn;

		if( iIsRifle == true )
		{
			PlayTracer( m_pPlayer, (g_iMode_ironsights == CoF_MODE_NOTAIMED) ? vecTracerOr : vecSrc, vecTracerAn, tr );
		}

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if( iMultiDamage == true )
				{
					if( pHit !is null )
					{
						g_WeaponFuncs.ClearMultiDamage();
						pHit.TraceAttack( m_pPlayer.pev, iBulletDamage, vecEnd, tr, iDamageBits );
						g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
					}
				}

				g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CUSTOMDAMAGE );

				if( tr.fInWater == 0.0 )
					water_bullet_effects( vecSrc, tr.vecEndPos );
				
				if( pHit is null || pHit.IsBSPModel() == true )
				{
					g_WeaponFuncs.DecalGunshot( tr, 100 );
				}
			}
		}
	}

	int RandomSeed()
	{
		return Math.RandomLong( 0, 1 );
	}

	bool Swing( int fFirst, float distance, int bodygroup, float firerate, float flDamage, bool isRifle )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * distance;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				self.SendWeaponAnim( ( self.m_iClip > 0 ) ? iAnimation : iAnimation2, 0, bodygroup );

				EffectsFOVOFF();
				m_pPlayer.pev.punchangle.z = Math.RandomLong( -7, -5 );
				self.m_flNextPrimaryAttack  = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + firerate;
				self.m_flTimeWeaponIdle = g_Engine.time + firerate + 0.5f;

				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, (isRifle) ? CoFCOMMON::MELEE_R_SOUND_MISS : CoFCOMMON::MELEE_P_SOUND_MISS, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			}
		}
		else
		{
			// hit
			fDidHit = true;
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			self.SendWeaponAnim( (self.m_iClip > 0) ? iAnimation : iAnimation2, 0, bodygroup );
			EffectsFOVOFF();
			m_pPlayer.pev.punchangle.z = Math.RandomLong( -7, -5 );

			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextTertiaryAttack + firerate < g_Engine.time )
			{
				// first swing does full damage and will launch the enemy a bit
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB | DMG_LAUNCH );
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper/KernCore) (50% less damage)
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB | DMG_LAUNCH );
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack  = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + firerate;
				self.m_flTimeWeaponIdle = g_Engine.time + firerate + 0.5f;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}

					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_ITEM, (isRifle) ? CoFCOMMON::MELEE_R_SOUND_HIT : CoFCOMMON::MELEE_P_SOUND_HIT, 1, ATTN_NORM );

					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR | BULLET_NONE );
				
				self.m_flNextPrimaryAttack  = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + firerate;
				self.m_flTimeWeaponIdle = g_Engine.time + firerate + 0.5f;
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.
				fvolbar = 1;

				// also play crowbar strike
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, (isRifle) ? CoFCOMMON::MELEE_R_SOUND_HIT : CoFCOMMON::MELEE_P_SOUND_HIT, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
			}

			// delay the decal a bit
			m_trHit = tr;
			//SetThink( ThinkFunction( this.Smack ) );
			//self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.2f, 0.4f );

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}

	bool HeavySmack( float flDistance, float flAttSpd, float flDamage, float anim_time, string s_HitBody, string s_HitWall, int dmgBits, bool shouldHealMachine = false )
	{
		TraceResult tr;
		bool bDamage = (flDamage >= 50) ? true : false;
		bool fDidHit = false;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * flDistance;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() == true )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			// miss
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flAttSpd;
			self.m_flTimeWeaponIdle = g_Engine.time + anim_time;
			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			// hit
			fDidHit = true;
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if( shouldHealMachine )
			{
				if( pEntity.IsMachine() && pEntity.IsPlayerAlly() )
				{
					if( pEntity.pev.health < pEntity.pev.max_health )
					{
						// Calculate the health of the machine and the ammount of damage we're going to heal
						pEntity.pev.health += (pEntity.pev.health + (flDamage / 1.5) < pEntity.pev.max_health ) ? (flDamage / 1.5) : pEntity.pev.max_health - pEntity.pev.health;
						m_pPlayer.pev.frags += 5;
					}
				}
				else
				{
					if( self.m_flNextPrimaryAttack + flAttSpd < g_Engine.time )
					{
						// first swing does full damage
						pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, dmgBits );  
					}
					else
					{
						// subsequent swings do 65% (Changed -Sniper/KernCore)
						pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.65, g_Engine.v_forward, tr, (bDamage) ? dmgBits : dmgBits | DMG_NEVERGIB );  
					}
				}
			}
			if( !shouldHealMachine )
			{
				if( self.m_flNextPrimaryAttack + flAttSpd < g_Engine.time )
				{
					// first swing does full damage
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, dmgBits );  
				}
				else
				{
					// subsequent swings do 65% (Changed -Sniper/KernCore)
					pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.65, g_Engine.v_forward, tr, (bDamage) ? dmgBits : dmgBits | DMG_NEVERGIB );  
				}
			}
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flAttSpd;
				self.m_flTimeWeaponIdle = g_Engine.time + anim_time;

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() == true )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}

					// play thwack or smack sound
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, s_HitBody, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

					m_pPlayer.m_iWeaponVolume = 128; 
					if( pEntity.IsAlive() == false )
					{
						SetThink( ThinkFunction( this.NoPulling ) );
						self.pev.nextthink = g_Engine.time + flAttSpd;
						return true;
					}
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line
			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CUSTOMDAMAGE );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flAttSpd;
				self.m_flTimeWeaponIdle = g_Engine.time + anim_time;

				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;
				// also play crowbar strike
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, s_HitWall, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			}

			// delay the decal a bit
			m_trHit = tr;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}

		// Lets wait until we can attack again
		SetThink( ThinkFunction( this.NoPulling ) );
		self.pev.nextthink = g_Engine.time + 0.01f;

		return fDidHit;
	}

	void NoPulling()
	{
		// We are no longer pulling back
		m_IsPullingBack = false;
	}
	
	void ClipCasting( const Vector& in origin, const Vector& in velocity, int iModelEmpty, bool i_isRevolver, int quantity )
	{
		if( !i_isRevolver )
		{
			if ( m_iDroppedClip == 1 ) // Check to see if I already dropped them
				return;
		}

		int lifetime = 100;
		int i = 0;

		if( self.m_iClip > 0 )
		{
			if( i_isRevolver == true )
			{
				while( i < quantity )
				{
					NetworkMessage buldrop( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						buldrop.WriteByte( TE_MODEL );
						buldrop.WriteCoord( origin.x );
						buldrop.WriteCoord( origin.y );
						buldrop.WriteCoord( origin.z );
						buldrop.WriteCoord( velocity.x + Math.RandomLong( -20, 20 ) ); // velocity
						buldrop.WriteCoord( velocity.y + Math.RandomLong( -20, 20 ) ); // velocity
						buldrop.WriteCoord( velocity.z + Math.RandomLong( -20, 20 ) ); // velocity
						buldrop.WriteAngle( Math.RandomFloat( 0, 180 ) ); // yaw
						buldrop.WriteShort( iModelEmpty ); // model
						buldrop.WriteByte( 1 ); // bouncesound
						buldrop.WriteByte( int( lifetime ) ); // decay time
					buldrop.End();
					i++;
				}
			}
			else
			{
				NetworkMessage magdrop( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
					magdrop.WriteByte( TE_BREAKMODEL );
					magdrop.WriteCoord( origin.x + 2 );
					magdrop.WriteCoord( origin.y );
					magdrop.WriteCoord( origin.z + Math.RandomLong( 4, 6 ) );
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( velocity.x + Math.RandomLong( -10, 10 ) );
					magdrop.WriteCoord( velocity.y + Math.RandomLong( -10, 10 ) );
					magdrop.WriteCoord( velocity.z + Math.RandomLong( -10, 10 ) );
					magdrop.WriteByte( 2 ); //speedNoise
					magdrop.WriteShort( iModelEmpty );
					magdrop.WriteByte( 1 ); //count
					magdrop.WriteByte( lifetime ); //time
					magdrop.WriteByte( 2 ); //flags
				magdrop.End();
			}
		}
		else
		{
			if( i_isRevolver == true )
			{
				while( i < quantity )
				{
					NetworkMessage buldrop( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						buldrop.WriteByte( TE_MODEL );
						buldrop.WriteCoord( origin.x );
						buldrop.WriteCoord( origin.y );
						buldrop.WriteCoord( origin.z );
						buldrop.WriteCoord( velocity.x + Math.RandomLong( -20, 20 )); // velocity
						buldrop.WriteCoord( velocity.y + Math.RandomLong( -20, 20 )); // velocity
						buldrop.WriteCoord( velocity.z + Math.RandomLong( -20, 20 )); // velocity
						buldrop.WriteAngle( Math.RandomFloat( 0, 180 ) ); // yaw
						buldrop.WriteShort( iModelEmpty ); // model
						buldrop.WriteByte( 1 ); // bouncesound
						buldrop.WriteByte( int( lifetime ) ); // decay time
					buldrop.End();
					i++;
				}
			}
			else
			{
				NetworkMessage magdrop( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
					magdrop.WriteByte( TE_BREAKMODEL );
					magdrop.WriteCoord( origin.x + 2 );
					magdrop.WriteCoord( origin.y );
					magdrop.WriteCoord( origin.z + Math.RandomLong( 4, 6 ) );
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( 0 ); //size
					magdrop.WriteCoord( velocity.x + Math.RandomLong( -10, 10 ) );
					magdrop.WriteCoord( velocity.y + Math.RandomLong( -10, 10 ) );
					magdrop.WriteCoord( velocity.z + Math.RandomLong( -10, 10 ) );
					magdrop.WriteByte( 2 ); //speedNoise
					magdrop.WriteShort( iModelEmpty );
					magdrop.WriteByte( 1 ); //count
					magdrop.WriteByte( lifetime ); //time
					magdrop.WriteByte( 2 ); //flags
				magdrop.End();
			}
		}

		m_iDroppedClip = 1;
	}
}

mixin class ammo_base
{
	bool CommonAddAmmo( CBaseEntity@ pOther, int& in iAmmoClip, int& in iAmmoCarry, string& in iAmmoType )
	{
		if( pOther.GiveAmmo( iAmmoClip, iAmmoType, iAmmoCarry ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, CoFCOMMON::ITEM_SOUND_PICK, 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}