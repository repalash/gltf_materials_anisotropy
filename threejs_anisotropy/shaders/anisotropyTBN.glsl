
float rnd = (random2(vUv.xy, frameCount)-0.5) * anisotropyNoise * material.roughness;

#if ANISOTROPY_TEX_MODE < 2
#if ANISOTROPY_TEX_MODE == 0 // CONSTANT rotation
float rot = saturate(anisotropyRotation) ;
//vec3 anisotropicT = normalize(mix(tangent, bitangent, rot));
#else // ROTATION map
float rot = (anisotropyRotationMapTexelToLinear(texture2D(anisotropyRotationMap, vUv)).r);
#endif
rot = rot * 2. * PI + rnd;

// Rotate tangent from cycles https://github.com/mcneel/cycles/blob/ad3f1826cdeebc9a44c530ed450ed94f9148b5e6/src/kernel/shaders/node_principled_bsdf.osl#L56
//vec3 anisotropicT = normalize(rotate(tangent, rot, normal)); // rotate fn at the bottom
vec3 anisotropicT = (tangent * sin(rot) + bitangent * cos(rot));

#else // DIRECTION map
vec2 rot2 = (anisotropyRotationMapTexelToLinear(texture2D(anisotropyRotationMap, vUv)).rg * 2. - 1.) + vec2(rnd, rnd);
rot2 = normalize(rot2);
vec3 anisotropicT = (tangent * rot2.x + bitangent * rot2.y);
#endif

// reproject on normal plane
anisotropicT = normalize(anisotropicT - normal * dot(anisotropicT, normal));
vec3 anisotropicB = normalize(cross(normal, anisotropicT));

