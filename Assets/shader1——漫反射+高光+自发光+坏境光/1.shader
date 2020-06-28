// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/1"
{
    Properties
    {
        _Diffuse("【漫反射颜色】Diffuse",Color)=(0,0,0,0)
        _DiffuseType("漫反射类型【1=逐顶点 2=逐像素 3=半兰伯特模型】",float)=2
        _Specular("【高光颜色】Specular",Color)=(0,0,0,0)
        _Gloss("【高光光点大小系数】",Range(8.0,255))=20
        _SpecularType("高光反射类型【1=逐顶点 2=逐像素 3=Blinn-Phong】",float)=1
        
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            float _DiffuseType;
            fixed4 _Specular;
            float _Gloss;
            float _SpecularType;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 specularWorldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 specularColor : TEXCOORD3;
                fixed3 color: COLOR;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                if(_DiffuseType == 1)
                {
                   fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                   fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                   fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                   o.color = diffuse + ambient; 
                }
                if(_DiffuseType == 2)
                {
                   o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                }
                
                if(_SpecularType ==1)
                {
                  fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                  fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                  //反射方向
                  fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                  //视角方向
                  fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos );
                  fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)), _Gloss);
                  o.specularColor = specular;
                }
                if(_SpecularType ==2 || _SpecularType ==3)
                {
                   o.specularWorldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                   o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                }
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col;
                
                if(_DiffuseType == 1)
                {
                    col = i.color;
                } 
                if(_DiffuseType == 2)
                {
                   fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                   fixed3 worldNormal = normalize(i.worldNormal);
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                   fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                   col = diffuse + ambient;                   
                }
                 if(_DiffuseType == 3)
                {
                   fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                   fixed3 worldNormal = normalize(i.worldNormal);
                   fixed3 worldLightDir =  normalize(_WorldSpaceLightPos0.xyz);
                   
                   //将结果从【-1，1】映射到[0,1] 视觉增强 暗除也有明暗变化。没有物理依据
                   fixed halfLambert = dot(worldNormal,worldLightDir) * 0.5 + 0.5;
                   fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;
                   col = diffuse + ambient;               
                }
                
                if(_SpecularType ==1)
                {
                   col = col + i.specularColor;
                }
                if(_SpecularType ==2)
                {
                   fixed3 worldNormal = normalize(i.specularWorldNormal);
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0).xyz;
                   fixed3 worldPos = normalize(i.worldPos);
                   //模型视角
                   fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                   //反射光
                   fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                   fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)),_Gloss);
                   col = col + specular;
                }
                if(_SpecularType==3)
                {
                   fixed3 worldNormal = normalize(i.specularWorldNormal);
                   fixed3 worldLightDir = normalize(_WorldSpaceLightPos0).xyz;
                   fixed3 worldPos = normalize(i.worldPos);
                   
                   fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                   //Blinn-Phong 更符合实际情形
                   fixed3 halfDir = normalize(worldLightDir + viewDir);
                   fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)),_Gloss);
                   col = col + specular;
                }
                return fixed4(col,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
