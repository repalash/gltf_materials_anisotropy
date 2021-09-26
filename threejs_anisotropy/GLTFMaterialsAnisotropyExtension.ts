class GLTFMaterialsAnisotropyExtension implements THREE.GLTFLoaderPlugin {
    public name: string
    public parser: THREE.GLTFParser

    constructor(parser:THREE.GLTFParser) {

        this.parser = parser
        this.name = 'WEBGI_materials_anisotropy'

    }

    async extendMaterialParams(materialIndex: number, materialParams: any) {

        const parser = this.parser
        const materialDef = parser.json.materials[ materialIndex ]

        if (!materialDef.extensions || !materialDef.extensions[ this.name ]) {

            return Promise.resolve()

        }

        const pending = []

        const extension = materialDef.extensions[ this.name ]

        if (!materialParams.userData) materialParams.userData = {}
        materialParams.userData.isAnisotropic = true
        materialParams.userData.anisotropyFactor = extension.anisotropyFactor ?? 0.5
        materialParams.userData.anisotropyNoise = extension.anisotropyNoise ?? 0.
        const {anisotropyTextureMode, anisotropyRotation} = extension
        materialParams.userData.anisotropyTextureMode = anisotropyTextureMode ?? 'CONSTANT'
        if (anisotropyTextureMode === 'ROTATION' || anisotropyTextureMode === 'DIRECTION') {
            pending.push(parser.assignTexture(materialParams.userData, 'anisotropyRotationMap', anisotropyRotation).then((t: any)=>{
                t.encoding = THREE.sRGBEncoding
            }))
            // pending.push(parser.assignTexture(materialParams, 'map', anisotropyRotation))
        } else {
            materialParams.userData.anisotropyRotation = anisotropyRotation ?? 0
        }
        return Promise.all(pending)

    }

}
