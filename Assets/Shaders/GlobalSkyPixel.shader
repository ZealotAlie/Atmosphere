Shader "Custom/GlobalSkyPixel"
{
	Properties
	{
		_RayleighZenithDepth("Rayleigh Zenith Depth", Range(0,1)) = 0.084
		_MieZenithDepth("Rayleigh Zenith Depth", Range(0,1)) = 0.0125
		_SunE("Sun Energy Scale", Range(0,100)) = 1
		_Pow("Sun Color Pow", Range(0,5)) = 1
		_G("Mie Phase G", Range(-1,1)) = 0.75
	}

		CGINCLUDE
#include "UnityCG.cginc"

#define E_VALUE 2.7182818284f
	const half INVERSED_E				= 1.0f / E_VALUE;
	const half ZENITH_DEPTH_FACTORY		= 1 / (1 - 1.0f / E_VALUE);

	uniform half _RayleighZenithDepth;
	uniform half _MieZenithDepth;
	uniform half _SunE;
	uniform half _Pow;
	uniform half _G;

	uniform half3 _SunAtmosphereTint;
	uniform half3 _SunDirection;//Not the sun light direction
	uniform half3 _Beta;
	uniform half3 _MieBeta;

	//To keep calculation sample, we make the astomsphere thckness as "1"
	//All physical distance will be related to the atmosphere thckness
	uniform half3	_CameraPosition;
	uniform half3	_CoreToCameraDir;
	uniform half	_CameraHeight;
	uniform half	_PlanetRadius;
	uniform half	_SkyRadius;

	//From PreethamSig2003.
	inline half RayleighPhase(half cosTheta)
	{
		return 0.1875 * (1.0 + cosTheta * cosTheta);
	}

	inline half MiePhase(float cosTheta, float g)
	{
		float gSq = g * g;
		return 1.5 * ((1.0 - gSq) / (2.0 + gSq)) * (1.0 + cosTheta * cosTheta) / pow(1.0 + gSq - 2.0 * g * cosTheta, 1.5);
	}

	//Optical Depth from H to h.
	inline half ZenithOpticalDepth(half h)
	{
		return ZENITH_DEPTH_FACTORY * (exp(-h) - INVERSED_E);
	}

	inline half OpticalDepthScale(half cos)
	{
		half x = 1.0 - cos;
		return exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25))));
	}

	inline half3 AtmosphericScattering(half height, half rDepth, half mDepth)
	{
		half relativeDesity = exp(-height);
		half3 attenuate = exp(-(_Beta * rDepth + _MieBeta * mDepth));

		return _SunE * relativeDesity * attenuate;
	}

	//Input horizon to Zenith cos value and sun position to Zenith cos value, and return how the sun is blocked by planet.
	inline half GetAccessibleSunLightFactor(half horizonLineCos, half sunCos)
	{
		return sunCos > horizonLineCos ? 1 : 0.1;
	}

	struct appdata
	{
		half4 vertex : POSITION;
	};

	struct v2f
	{
		half3 dir			: NORMAL0;
		half4 vertex		: SV_POSITION;
	};

	v2f vert(appdata_base v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o);

		o.dir		= normalize(mul(unity_ObjectToWorld, v.vertex).xyz);
		o.vertex	= UnityObjectToClipPos(v.vertex);
		return o;
		//============================================================================================================================
	}


	half4 frag(v2f input) : SV_Target
	{
		half3 skyDir = input.dir;
		half3 skyPos = skyDir * _SkyRadius;

		half3 cameraToSky		= skyPos - _CameraPosition;
		half3 cameraToSkyDir	= normalize(cameraToSky);

		const int nSampler = 50;

		half fSampler		= (half)nSampler;
		half3 samplerOffset	= cameraToSky / fSampler;
		half3 samplerPos	= _CameraPosition + samplerOffset * 0.5;
		half totalDepth		= OpticalDepthScale(dot(_CoreToCameraDir,cameraToSkyDir));
		half scatterScale	= 1 / fSampler;
		half planetRadiusSq	= _PlanetRadius * _PlanetRadius;

		half3 scatteringColor = 0;
		[unroll]
		for (int i = 0; i < nSampler; ++i)
		{
			half disToCoreSq = dot(samplerPos, samplerPos);
			half distanceToPlanetCore = sqrt(disToCoreSq);
			half height = distanceToPlanetCore - _PlanetRadius;

			half horizonLineCos = -sqrt(disToCoreSq - planetRadiusSq) / distanceToPlanetCore;
			half cosSunSampler	= dot(samplerPos, _SunDirection) / distanceToPlanetCore;
			half cosSkySampler	= dot(samplerPos, cameraToSkyDir) / distanceToPlanetCore;

			half sunThroughFactor = GetAccessibleSunLightFactor(horizonLineCos, cosSunSampler);

			half samplerZenithDepth		= ZenithOpticalDepth(height);
			half skyToSamplerDepthScale	= OpticalDepthScale(cosSkySampler);
			half sunToSamplerDepthScale = OpticalDepthScale(cosSunSampler);

			half depth = totalDepth
				+ samplerZenithDepth * (sunToSamplerDepthScale - skyToSamplerDepthScale);

			scatteringColor += 
				sunThroughFactor * scatterScale * 
				AtmosphericScattering(height, depth * _RayleighZenithDepth, depth * _MieZenithDepth);

			samplerPos += samplerOffset;
		}

		half3 rColor = scatteringColor * _Beta;
		half3 mColor = scatteringColor * _MieBeta;


		half cosVal = dot(normalize(cameraToSkyDir), _SunDirection);
		half rPhase = RayleighPhase(cosVal);
		half mPhase = MiePhase(cosVal, _G);

		half4 color = half4(rPhase * rColor + mPhase * mColor,1);
		color.rgb = pow(color.rgb, _Pow);

		return color;
	}

		ENDCG

		SubShader
	{
		Tags
		{
			"Queue" = "Background+1600"
			"RenderType" = "Background"
			"IgnoreProjector" = "True"
		}

			Pass
		{

			Cull Off
			ZWrite Off
			ZTest
			LEqual
			Blend One One
			Fog{ Mode Off }

			CGPROGRAM

				#pragma vertex   vert
				#pragma fragment frag
				#pragma target	 3.0
			ENDCG

			//===============================================================================================
		}
	}

	Fallback "Diffuse"
}
