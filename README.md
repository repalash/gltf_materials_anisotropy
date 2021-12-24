[![Blender](misc/Blender_logo.png)](http://www.blender.org/) [![glTF](misc/glTF_logo.png)](https://www.khronos.org/gltf/) [![three.js](misc/threejs_logo.png)](https://threejs.org/)

GLTF Material Anisotropy extension 
======================================

Custom extension to support anisotropy factor and anisotropic rotation/direction map in GLTF/GLB  

[Blender Addon](./blender_gltf_anisotropy_export_addon)
--------------
Export anisotropy factor and texture from PBS materials supported by cycles

To install, put the plugin directory in the addons folder of your blender installation.

For Mac its `/Applications/Blender.app/Contents/Resources/2.92/scripts/addons`

[Threejs Import](threejs_anisotropy/)
--------------

Import with custom GLTF loader extension. Adds the parameters and loaded texture to material `userData`. Change extension name if needed.

Register: 
```javascript
gltfLoader.register((p)=>new GLTFMaterialsAnisotropyExtension(p))
```

[Shaders](threejs_anisotropy/shaders)
--------------

Functions for adding anisotropy in Physical shader in threejs. Code taken mostly from filament. (Links in code)


## Sample threejs shader patching (for onBeforeCompile).
```typescript
 const rotMap: ITexture | undefined = material.materialObject.userData?.anisotropyRotationMap
 const bsdfs = glsl`
    #include <bsdfs>
    //#if ANISOTROPY_ENABLED
    ${randomHelpers}
    ${anisotropyBsdf}
` + (rotMap ? getTexelDecoding('anisotropyRotationMap', rotMap, renderer.capabilities.isWebGL2) : '')
shader.fragmentShader = shader.fragmentShader.replace('#include <bsdfs>', bsdfs)

shader.fragmentShader = shader.fragmentShader.replace('#include <lights_fragment_begin>', ShaderChunk.lights_fragment_begin)

shader.fragmentShader = shader.fragmentShader
    .replace('IncidentLight directLight;', anisotropyTBN + 'IncidentLight directLight;')
    .replaceAll('RE_Direct( directLight, geometry, material, reflectedLight )',
        'RE_Direct( directLight, geometry, material, reflectedLight, anisotropicT, anisotropicB )')

// eslint-disable-next-line @typescript-eslint/naming-convention
const lights_physical_pars_fragment = ShaderChunk.lights_physical_pars_fragment
    .replace('void RE_Direct_Physical( const in IncidentLight directLight, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {',
        'void RE_Direct_Physical( const in IncidentLight directLight, const in GeometricContext geometry, const in PhysicalMaterial material, inout ReflectedLight reflectedLight, const in vec3 anisotropicT, const in vec3 anisotropicB ) {')
    .replace('BRDF_GGX( directLight.direction, geometry.viewDir, geometry.normal, material.specularColor, material.specularF90, material.roughness )',
        'BRDF_GGX_Anisotropy( directLight.direction, geometry.viewDir, geometry.normal, material.specularColor, material.specularF90, material.roughness, anisotropicT, anisotropicB )')
shader.fragmentShader = shader.fragmentShader.replace('#include <lights_physical_pars_fragment>', lights_physical_pars_fragment)

// eslint-disable-next-line @typescript-eslint/naming-convention
const lights_fragment_maps = glsl`
    #if defined( USE_ENVMAP )
    vec3 anisotropyBentNormal = indirectAnisotropyBentNormal(geometry.normal, geometry.viewDir, material.roughness, anisotropicT, anisotropicB);
    #endif
` + ShaderChunk.lights_fragment_maps
    .replace('getIBLIrradiance( geometry.normal )',
        'getIBLIrradiance( anisotropyBentNormal )')
    .replace('getIBLRadiance( geometry.viewDir, geometry.normal, material.roughness )',
        'getIBLRadiance( geometry.viewDir, anisotropyBentNormal, material.roughness )')
shader.fragmentShader = shader.fragmentShader.replace('#include <lights_fragment_maps>', lights_fragment_maps)

;(shader as any).vertexUvs = true
;(shader as any).vertexTangents = true

```
