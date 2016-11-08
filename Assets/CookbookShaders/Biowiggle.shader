	Shader "CookbookShaders/Biowiggle" {
     Properties {
       _MainTex ("Texture", 2D) = "white" {}
       _TimeScale ("Time Scaling", Range(0,10)) = 1.0
       _XAmount ("X Wiggle", Range(0,5)) = 1.0
       _YAmount ("Y Wiggle", Range(0,5)) = 1.0
     }
     SubShader {
       Tags { "RenderType" = "Opaque" }
       Cull Off
       CGPROGRAM
       #pragma surface surf Lambert vertex:vert
     
       
       struct Input {
           float2 uv_MainTex;
       };
       float _XAmount;
       float _YAmount;
       float _TimeScale;
       void vert(inout appdata_full v)
       {
         float time = _TimeScale * _Time.y;
         float iny = v.vertex.y * _YAmount + time;
         float wiggleX = sin(iny) * _XAmount;
         float wiggleY = cos(iny) * _XAmount;
         v.normal.y = v.normal.y + wiggleY;
         normalize(v.normal);
         v.vertex.x = v.vertex.x + wiggleX;
         
       }
       
       sampler2D _MainTex;
 
       void surf (Input IN, inout SurfaceOutput o) {
           
           o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb;
 
       }
       ENDCG
     }
     Fallback "Diffuse"
   }