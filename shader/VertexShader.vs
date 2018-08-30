////////////////////////////////////////////
// FileName : VertexShader.vs
////////////////////////////////////////////

////////////
// Global
////////////
cbuffer MatrixBuffer : register(b0)
{
	matrix WVPMatrix : packoffset(c0);
	matrix worldMatrix : packoffset(c4);
	matrix viewMatrix : packoffset(c8);
	matrix projectionMatrix : packoffset(c12);
	matrix VPInverse : packoffset(c16);
};

cbuffer CameraBuffer : register(b1)
{
    float3 cameraPosition : packoffset(c0);
    float farZ : packoffset(c1);
};

cbuffer TessBuffer : register(b2)
{
	float minTessDistance : packoffset(c0);
	float maxTessDistance : packoffset(c0.y);
	float minTessFactor : packoffset(c0.z);
	float maxTessFactor : packoffset(c0.w);
};

/////////////
// structure
/////////////
struct VertexInputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
};

struct PixelInputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
	float3 viewRay : TEXCOORD1;
	float4 worldPosition : TEXCOORD2;
	float4 localPosition : TEXCOORD3;
	uint RTlndex : SV_RenderTargetArrayIndex;
};

struct HullInputType
{
	float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
	float3 viewRay : TEXCOORD1;
	float4 worldPosition : TEXCOORD2;
	float4 localPosition : TEXCOORD3;
	uint RTlndex : SV_RenderTargetArrayIndex;
	float tessFactor : TESS;
};

static const float2 arrBasePos[4] =
{
	float2(-1.0f, 1.0f),
	float2(1.0f, 1.0f),
	float2(-1.0f, -1.0f),
	float2(1.0f, -1.0f),
};


///////////////////////
// Vertex Shader
///////////////////////
PixelInputType RenderPointLightShadowVertexMain(uint vertexID : SV_VertexID) //포인트 그림자 렌더링
{
	PixelInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);

	output.worldPosition = worldPosition;

	output.viewRay = worldPosition;

	output.viewRay.xyz = output.viewRay.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderDirectLightShadowVertexMain(uint vertexID : SV_VertexID) //다이렉션 그림자 렌더링
{
	PixelInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);

	output.worldPosition = worldPosition;

	output.viewRay = worldPosition;
	output.viewRay.xyz = output.viewRay.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderDirectionLightVertexMain(uint vertexID : SV_VertexID) //다이렉션 빛렌링
{
	PixelInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);
	
	output.worldPosition = worldPosition;

	output.viewRay = worldPosition.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderPointLightVertexMain(uint vertexID : SV_VertexID) //포인트 빛 렌더링
{
	PixelInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);
	
	output.worldPosition = worldPosition;

	output.viewRay = worldPosition.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}


PixelInputType RenderPointLightDepthShadowVertexMain(VertexInputType input) //포인트 쉐도우 큐브맵에 월드상의 거리 렌더링 
{
	PixelInputType output;

   input.position.w = 1.0f;
   output.position = mul( input.position , worldMatrix);
   output.worldPosition = output.position;

   output.RTlndex = 0;
   return output;
}

PixelInputType RenderDirectionLightDepthShadowVertexMain(VertexInputType input) //다이렉션 라이트 깊이버퍼에 깊이값 저장
{
   PixelInputType output;

   input.position.w = 1.0f;
   output.position = mul( input.position , WVPMatrix);

   output.RTlndex = 0;
   return output;
}

PixelInputType RenderSkyBoxVertexMain(VertexInputType input) //마지막 전 스카이큐브 렌더링
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.localPosition = input.position;

	output.RTlndex = 0;
	return output;
}

PixelInputType Render32BitTextureVertexMain(VertexInputType input) //32텍스쳐를 화면에 렌더링
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}


PixelInputType RenderTextureVertexMain(VertexInputType input) // 일반 텍스쳐를 화면에 렌더링
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderHDRWithBloomVertexMain(VertexInputType input) //HDR적용후 화면에 렌더링
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}

HullInputType RenderGBufferWithTessVertexMain(VertexInputType input) //GBuffer에 렌더링 + 테셀레이션
{
	HullInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용
	float distanceCameraVertex; //버텍스와 카메라의 거리
	float tessConst;

	input.position.w = 1.0f;

	output.position = mul(input.position, worldMatrix);

	output.tex = input.tex;

	//조명을 위해 법선벡터를 로컬에서 월드좌표계로 바꿈 
	output.normal = mul( input.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	output.tangent = mul(input.tangent, (float3x3)worldMatrix);
    output.tangent = normalize(output.tangent);

	output.binormal = mul(input.binormal, (float3x3)worldMatrix);
    output.binormal = normalize(output.binormal);

	output.worldPosition = mul(input.position, worldMatrix);

	output.RTlndex = 0;

	//테셀레이션 요소
	distanceCameraVertex = distance(output.position.xyz, cameraPosition);
	tessConst = saturate( (distanceCameraVertex - minTessDistance) / (maxTessDistance - minTessDistance) )  ;
	//[0,1] 을 확장
	output.tessFactor =  minTessFactor + (tessConst * (maxTessFactor - minTessFactor));

	return output;
}


PixelInputType RenderGBufferVertexMain(VertexInputType input) //GBuffer에 렌더링
{
	PixelInputType output;
	float4 worldPosition; //카메라 보는 픽셀 벡터 계산용
	float distanceCameraVertex; //버텍스와 카메라의 거리

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix); 

	output.tex = input.tex;

	//조명을 위해 법선벡터를 로컬에서 월드좌표계로 바꿈 
	output.normal = mul( input.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	output.tangent = mul(input.tangent, (float3x3)worldMatrix);
    output.tangent = normalize(output.tangent);

	output.binormal = mul(input.binormal, (float3x3)worldMatrix);
    output.binormal = normalize(output.binormal);

	output.worldPosition = mul(input.position, worldMatrix);

	output.RTlndex = 0;

	return output;
}