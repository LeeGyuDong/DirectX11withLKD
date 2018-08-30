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
PixelInputType RenderPointLightShadowVertexMain(uint vertexID : SV_VertexID) //����Ʈ �׸��� ������
{
	PixelInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);

	output.worldPosition = worldPosition;

	output.viewRay = worldPosition;

	output.viewRay.xyz = output.viewRay.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderDirectLightShadowVertexMain(uint vertexID : SV_VertexID) //���̷��� �׸��� ������
{
	PixelInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);

	output.worldPosition = worldPosition;

	output.viewRay = worldPosition;
	output.viewRay.xyz = output.viewRay.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderDirectionLightVertexMain(uint vertexID : SV_VertexID) //���̷��� ������
{
	PixelInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);
	
	output.worldPosition = worldPosition;

	output.viewRay = worldPosition.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderPointLightVertexMain(uint vertexID : SV_VertexID) //����Ʈ �� ������
{
	PixelInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����

	output.position = float4(arrBasePos[vertexID].xy, 0.0f, 1.0f);

	output.tex = float2( (output.position.x + 1.0f), (output.position.y * -1.0f + 1.0f)) / 2.0f  ;

	worldPosition = mul(float4(arrBasePos[vertexID].xy, 1.0f, 1.0f) * farZ, VPInverse);
	
	output.worldPosition = worldPosition;

	output.viewRay = worldPosition.xyz - cameraPosition.xyz;

	output.RTlndex = 0;
	return output;
}


PixelInputType RenderPointLightDepthShadowVertexMain(VertexInputType input) //����Ʈ ������ ť��ʿ� ������� �Ÿ� ������ 
{
	PixelInputType output;

   input.position.w = 1.0f;
   output.position = mul( input.position , worldMatrix);
   output.worldPosition = output.position;

   output.RTlndex = 0;
   return output;
}

PixelInputType RenderDirectionLightDepthShadowVertexMain(VertexInputType input) //���̷��� ����Ʈ ���̹��ۿ� ���̰� ����
{
   PixelInputType output;

   input.position.w = 1.0f;
   output.position = mul( input.position , WVPMatrix);

   output.RTlndex = 0;
   return output;
}

PixelInputType RenderSkyBoxVertexMain(VertexInputType input) //������ �� ��ī��ť�� ������
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.localPosition = input.position;

	output.RTlndex = 0;
	return output;
}

PixelInputType Render32BitTextureVertexMain(VertexInputType input) //32�ؽ��ĸ� ȭ�鿡 ������
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}


PixelInputType RenderTextureVertexMain(VertexInputType input) // �Ϲ� �ؽ��ĸ� ȭ�鿡 ������
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}

PixelInputType RenderHDRWithBloomVertexMain(VertexInputType input) //HDR������ ȭ�鿡 ������
{
	PixelInputType output;

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix);

	output.tex = input.tex;

	output.RTlndex = 0;
	return output;
}

HullInputType RenderGBufferWithTessVertexMain(VertexInputType input) //GBuffer�� ������ + �׼����̼�
{
	HullInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����
	float distanceCameraVertex; //���ؽ��� ī�޶��� �Ÿ�
	float tessConst;

	input.position.w = 1.0f;

	output.position = mul(input.position, worldMatrix);

	output.tex = input.tex;

	//������ ���� �������͸� ���ÿ��� ������ǥ��� �ٲ� 
	output.normal = mul( input.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	output.tangent = mul(input.tangent, (float3x3)worldMatrix);
    output.tangent = normalize(output.tangent);

	output.binormal = mul(input.binormal, (float3x3)worldMatrix);
    output.binormal = normalize(output.binormal);

	output.worldPosition = mul(input.position, worldMatrix);

	output.RTlndex = 0;

	//�׼����̼� ���
	distanceCameraVertex = distance(output.position.xyz, cameraPosition);
	tessConst = saturate( (distanceCameraVertex - minTessDistance) / (maxTessDistance - minTessDistance) )  ;
	//[0,1] �� Ȯ��
	output.tessFactor =  minTessFactor + (tessConst * (maxTessFactor - minTessFactor));

	return output;
}


PixelInputType RenderGBufferVertexMain(VertexInputType input) //GBuffer�� ������
{
	PixelInputType output;
	float4 worldPosition; //ī�޶� ���� �ȼ� ���� ����
	float distanceCameraVertex; //���ؽ��� ī�޶��� �Ÿ�

	input.position.w = 1.0f;

	output.position = mul(input.position, WVPMatrix); 

	output.tex = input.tex;

	//������ ���� �������͸� ���ÿ��� ������ǥ��� �ٲ� 
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