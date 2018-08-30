////////////////////////////////////////////
// FileName : VertexShader.vs
////////////////////////////////////////////

////////////
// Global
////////////
cbuffer GSMatrixBuffer
{
	matrix VPMatrix[6];
};

/////////////
// structure
/////////////
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

///////////////////////
// Geometric Shader
///////////////////////

[maxvertexcount(18)]
void RenderPointLightDepthShadowGeometricMain(triangle PixelInputType input[3],
	inout TriangleStream<PixelInputType> outStream)
{
	int surface; //텍스처 개수
	int vertex; //버텍스 개수

	for(surface = 0 ; surface < 6 ; surface++)
	{
		PixelInputType output;

		for(vertex = 0 ; vertex < 3 ; vertex++)
		{
			output = input[vertex];
			output.RTlndex = surface;
			output.position = mul(output.position, VPMatrix[surface]);
			outStream.Append(output);
		}
		outStream.RestartStrip();
	}
	
}