uniform float anisotropyFactor;
uniform float anisotropyNoise;
#if ANISOTROPY_TEX_MODE == 0
uniform float anisotropyRotation;
#else
uniform sampler2D anisotropyRotationMap;
#endif
const float MIN_ROUGHNESS = 0.05;
// https://github.com/repalash/Open-Shaders/blob/aede763ff6fb68c348092574d060c56200a255f5/Engines/filament/brdf.fs#L81
float D_GGX_Anisotropy(float at, float ab, float ToH, float BoH, float NoH) {
    // Burley 2012, "Physically-Based Shading at Disney"

    // The values at and ab are perceptualRoughness^2, a2 is therefore perceptualRoughness^4
    // The dot product below computes perceptualRoughness^8. We cannot fit in fp16 without clamping
    // the roughness to too high values so we perform the dot product and the division in fp32
    float a2 = at * ab;
    highp vec3 d = vec3(ab * ToH, at * BoH, a2 * NoH);
    highp float d2 = dot(d, d);
    float b2 = a2 / d2;
    return a2 * b2 * b2 * (1.0 / PI);
}

// https://github.com/repalash/Open-Shaders/blob/aede763ff6fb68c348092574d060c56200a255f5/Engines/filament/brdf.fs#L121
float V_GGX_SmithCorrelated_Anisotropy(float at, float ab, float ToV, float BoV, float ToL, float BoL, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float lambdaV = NoL * length(vec3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(vec3(at * ToL, ab * BoL, NoL));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturate( v );
}
// https://github.com/repalash/Open-Shaders/blob/f226a633874528ca1e7c3120512fc4a3bef3d1a6/Engines/filament/light_indirect.fs#L139

vec3 indirectAnisotropyBentNormal(const in vec3 normal, const in vec3 viewDir, const in float roughness, const in vec3 anisotropicT, const in vec3 anisotropicB) {
    vec3 aDirection = anisotropyFactor >= 0.0 ? anisotropicB : anisotropicT;
    vec3 aTangent = cross(aDirection, viewDir);
    vec3 aNormal = cross(aTangent, aDirection);
    float bendFactor = abs(anisotropyFactor) * saturate(5.0 * max(roughness, MIN_ROUGHNESS));
    return normalize(mix(normal, aNormal, bendFactor));
}

// ShaderChunk.bsdfs
//https://github.com/repalash/Open-Shaders/blob/f226a633874528ca1e7c3120512fc4a3bef3d1a6/Engines/filament/shading_model_standard.fs#L31
vec3 BRDF_GGX_Anisotropy( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 f0, const in float f90, const in float roughness, const in vec3 anisotropicT, const in vec3 anisotropicB ) {

    float alpha = pow2( roughness ); // UE4's roughness

    vec3 halfDir = normalize( lightDir + viewDir );

    float dotNL = saturate( dot( normal, lightDir ) );
    float dotNV = saturate( dot( normal, viewDir ) );
    float dotNH = saturate( dot( normal, halfDir ) );
    float dotVH = saturate( dot( viewDir, halfDir ) );

    float dotTV =  dot(anisotropicT, viewDir) ;
    float dotBV =  dot(anisotropicB, viewDir) ;
    float dotTL =  dot(anisotropicT, lightDir) ;
    float dotBL =  dot(anisotropicB, lightDir) ;
    float dotTH =  dot(anisotropicT, halfDir) ;
    float dotBH =  dot(anisotropicB, halfDir) ;

    // Anisotropic parameters: at and ab are the roughness along the tangent and bitangent
    // to simplify materials, we derive them from a single roughness parameter
    // Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
    //    float at = max(alpha * (1.0 + anisotropyFactor), MIN_ROUGHNESS);
    //    float ab = max(alpha * (1.0 - anisotropyFactor), MIN_ROUGHNESS);

    // slide 26, Disney 2012, "Physically Based Shading at Disney"
    // https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf
    float aspect = sqrt(1.0 - min(1.-MIN_ROUGHNESS, abs(anisotropyFactor) * 0.9));
    if (anisotropyFactor > 0.0) aspect = 1.0 / aspect;
    float at = roughness * aspect;
    float ab = roughness / aspect;

    // specular anisotropic BRDF
    vec3 F = F_Schlick( f0, f90, dotVH );

    float V = V_GGX_SmithCorrelated_Anisotropy( at, ab, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );

    float D = D_GGX_Anisotropy( at, ab, dotTH, dotBH, dotNH );

    //    vec3 F = F_Schlick( f0, f90, dotVH );
    //    float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
    //    float D = D_GGX( alpha, dotNH );

    return F * ( V * D );

}
