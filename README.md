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