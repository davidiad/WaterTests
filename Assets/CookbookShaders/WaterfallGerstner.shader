﻿Shader "CookbookShaders/WaterfallGerstner" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		//_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0



	_MainTex ("Fallback texture", 2D) = "black" {}
	_BumpMap ("Normals ", 2D) = "bump" {}

	_FlowMap ("Flow Map", 2D) = "white" {}
	_GMap ("Wave Map ", 2D) = "white" {}
	_CMap ("Color Map ", 2D) = "white" {}



	_DistortParams ("Distortions (Bump waves, Reflection, Fresnel power, Fresnel bias)", Vector) = (1.0 ,1.0, 2.0, 1.15)
	_InvFadeParemeter ("Auto blend parameter (Edge, Shore, Distance scale)", Vector) = (0.15 ,0.15, 0.5, 1.0)
	
	_AnimationTiling ("Animation Tiling (Displacement)", Vector) = (2.2 ,2.2, -1.1, -1.1)
	_AnimationDirection ("Animation Direction (displacement)", Vector) = (1.0 ,1.0, 1.0, 1.0)

	_BumpTiling ("Bump Tiling", Vector) = (1.0 ,1.0, -2.0, 3.0)
	_BumpDirection ("Bump Direction & Speed", Vector) = (1.0 ,1.0, -1.0, 1.0)
	
	_FresnelScale ("FresnelScale", Range (0.15, 4.0)) = 0.75

	_BaseColor ("Base color", COLOR)  = ( .54, .95, .99, 0.5)
	_ReflectionColor ("Reflection color", COLOR)  = ( .54, .95, .99, 0.5)
	_SpecularColor ("Specular color", COLOR)  = ( .72, .72, .72, 1)
	
	_WorldLightDir ("Specular light direction", Vector) = (0.0, 0.1, -0.5, 0.0)
	_Shininess ("Shininess", Range (2.0, 500.0)) = 200.0

		_GerstnerIntensity("Per vertex displacement", Float) = 1.0
		_GAmplitude ("Wave Amplitude", Vector) = (0.3 ,0.35, 0.25, 0.25)
		_GFrequency ("Wave Frequency", Vector) = (1.3, 1.35, 1.25, 1.25)
		_GSteepness ("Wave Steepness", Vector) = (1.0, 1.0, 1.0, 1.0)
		_GSpeed ("Wave Speed", Vector) = (1.2, 1.375, 1.1, 1.5)
		_GDirectionAB ("Wave Direction", Vector) = (0.3 ,0.85, 0.85, 0.25)
		_GDirectionCD ("Wave Direction", Vector) = (0.1 ,0.9, 0.5, 0.5)
	}


	CGINCLUDE

	#include "UnityCG.cginc"
	#include "WaterInclude.cginc"



	ENDCG



  SubShader {
    Tags { "RenderType" = "Opaque" }
    CGPROGRAM
    #pragma surface surf Standard vertex:vert
    struct Input {
        float4 color : COLOR;
        float2 uv_CMap;
    };
//    v2f vert (inout appdata_full v) {
//        v.vertex.xyz += v.normal * 0.5;
//    }




	struct appdata
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};

	// interpolator structs
	
	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 normalInterpolator : TEXCOORD0;
		float3 viewInterpolator : TEXCOORD1;
		float4 bumpCoords : TEXCOORD2;
		float4 screenPos : TEXCOORD3;
		float4 grabPassPos : TEXCOORD4;
		UNITY_FOG_COORDS(5)
	};

	// flow mapper (and gerstner wave map)
	sampler2D _FlowMap;
	sampler2D _GMap; // for gesrstner waves
	sampler2D _CMap; // for textured color

	float3 _terrainSize;
		#define TerrainSize _terrainSize
	float4 _SmallFlowPhases;
		#define BUMP_SMALL_FLOW_PHASE_0 _SmallFlowPhases.x
		#define BUMP_SMALL_FLOW_PHASE_1 _SmallFlowPhases.y
		#define FOAM_SMALL_FLOW_PHASE_0 _SmallFlowPhases.z
		#define FOAM_SMALL_FLOW_PHASE_1 _SmallFlowPhases.w
	float4 _LargeFlowPhases;
		#define BUMP_LARGE_FLOW_PHASE_0 _LargeFlowPhases.x
		#define BUMP_LARGE_FLOW_PHASE_1 _LargeFlowPhases.y
		#define FOAM_LARGE_FLOW_PHASE_0 _LargeFlowPhases.z
		#define FOAM_LARGE_FLOW_PHASE_1 _LargeFlowPhases.w



	uniform float4 _GAmplitude;
	uniform float4 _GFrequency;
	uniform float4 _GSteepness;
	uniform float4 _GSpeed;
	uniform float4 _GDirectionAB;
	uniform float4 _GDirectionCD;

	
	// shortcuts
	#define PER_PIXEL_DISPLACE _DistortParams.x
	#define REALTIME_DISTORTION _DistortParams.y
	#define FRESNEL_POWER _DistortParams.z
	#define VERTEX_WORLD_NORMAL i.normalInterpolator.xyz
	#define DISTANCE_SCALE _InvFadeParemeter.z
	#define FRESNEL_BIAS _DistortParams.w
	
	//
	// HQ VERSION
	//
	
	v2f vert(inout appdata_full v)
	{
	    //v.vertex.xyz += v.normal * frac(sin(_Time[0] * dot(float3(1.1, 2.2, 3.3) ,float3(12.9898,78.233,45.5432))) * 43758.5453);
		v2f o;

		// a float to hold the amount of intensity adjustment from the wave map
		float adjustmentFromWaveMap = (tex2Dlod(_GMap, half4(v.vertex.xz / 100.0, 1.0, 1.0)));

		half3 worldSpaceVertex = mul(unity_ObjectToWorld,(v.vertex)).xyz;
		half3 vtxForAni = (worldSpaceVertex).xzz;

		half3 nrml;
		half3 offsets;

		if (adjustmentFromWaveMap > 0.0001) {

		Gerstner (
			offsets, nrml, v.vertex.xyz, vtxForAni,						// offsets, nrml will be written
			_GAmplitude,												// amplitude
			_GFrequency,												// frequency
			_GSteepness,												// steepness
			_GSpeed,													// speed
			_GDirectionAB,												// direction # 1, 2
			_GDirectionCD												// direction # 3, 4
		);

		// adjust the factor (100.0 here) according to the size of the object
		offsets *= (tex2Dlod(_GMap, half4(v.vertex.xz / 100.0, 1.0, 1.0)));


		///// Adjust offset for normal of vertex
		offsets.x = offsets.x + v.normal.x;
		offsets.z = offsets.z + v.normal.z;
		offsets.y = offsets.y + v.normal.y;
		// I think normalizing was working beofre in Salmonid_23 -- why not now?
		//offsets = normalize(offsets - 0.5);
		//////////////////

		v.vertex.xyz += offsets;

		}
		
		half2 tileableUv = worldSpaceVertex.xz;
		
		//o.bumpCoords.xyzw = (tileableUv.xyxy + _Time.xxxx * _BumpDirection.xyzw) * _BumpTiling.xyzw;

		o.viewInterpolator.xyz = worldSpaceVertex - _WorldSpaceCameraPos;

		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		ComputeScreenAndGrabPassPos(o.pos, o.screenPos, o.grabPassPos);
		
		o.normalInterpolator.xyz = nrml;
		
		o.normalInterpolator.w = 1;//GetDistanceFadeout(o.screenPos.w, DISTANCE_SCALE);
		
		//UNITY_TRANSFER_FOG(o,o.pos);
		v.normal = nrml;
        normalize(v.normal);

		return o;
	}



	half _Metallic;
	half _Glossiness;

    void surf (Input IN, inout SurfaceOutputStandard o) {
    	fixed4 c = tex2D (_CMap, IN.uv_CMap);// * _Color;
    	o.Albedo = c.rgb;
       // o.Albedo = 1;
        o.Metallic = _Metallic;
		o.Smoothness = _Glossiness;

    }
    ENDCG
  }
  Fallback "Diffuse"
}