import bpy
from io_scene_gltf2.blender.exp import gltf2_blender_get
from io_scene_gltf2.blender.exp import gltf2_blender_gather_texture_info
from io_scene_gltf2.blender.exp import gltf2_blender_search_node_tree

bl_info = {
    "name": "Anisotropy Extension",
    "extension_name": "WEBGI_materials_anisotropy",
    "category": "GLTF Exporter",
    "version": (1, 0, 0),
    "blender": (2, 92, 0),
    'location': 'File > Export > glTF 2.0',
    'description': 'Extension to export anisotropy factor and texture from PBS materials.',
    'tracker_url': '',  # Replace with your issue tracker
    'isDraft': False,
    'developer': "Palash Bansal",
    'url': 'https://repalash.com',
}


# https://github.com/KhronosGroup/glTF-Blender-IO/tree/master/example-addons/example_gltf_extension

# glTF extensions are named following a convention with known prefixes.
# See: https://github.com/KhronosGroup/glTF/tree/master/extensions#about-gltf-extensions
# also: https://github.com/KhronosGroup/glTF/blob/master/extensions/Prefixes.md

extension_is_required = False


class AnisotropyExtensionProperties(bpy.types.PropertyGroup):
    enabled: bpy.props.BoolProperty(
        name=bl_info["name"],
        description='Include this extension in the exported glTF file.',
        default=True
    )
    extension_name: bpy.props.StringProperty(
        name="Extension",
        description='GLTF extension name.',
        default=bl_info["extension_name"]
    )
    directional_map_flag: bpy.props.StringProperty(
        name="Directional Map Flag",
        description='Set this to 1 in material custom properties to indicate that the map is directional.',
        default='anisotropyTextureDirectional'
    )

def register():
    bpy.utils.register_class(AnisotropyExtensionProperties)
    bpy.types.Scene.AnisotropyExtensionProperties = bpy.props.PointerProperty(type=AnisotropyExtensionProperties)

def register_panel():
    try:
        bpy.utils.register_class(GLTF_PT_AnisotropyExtensionPanel)
    except Exception:
        pass

def unregister_panel():
    try:
        bpy.utils.unregister_class(GLTF_PT_AnisotropyExtensionPanel)
    except Exception:
        pass

def unregister():
    unregister_panel()
    bpy.utils.unregister_class(AnisotropyExtensionProperties)
    del bpy.types.Scene.AnisotropyExtensionProperties


class GLTF_PT_AnisotropyExtensionPanel(bpy.types.Panel):

    bl_space_type = 'FILE_BROWSER'
    bl_region_type = 'TOOL_PROPS'
    bl_label = "Enabled"
    bl_parent_id = "GLTF_PT_export_user_extensions"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        sfile = context.space_data
        operator = sfile.active_operator
        return operator.bl_idname == "EXPORT_SCENE_OT_gltf"

    def draw_header(self, context):
        props = bpy.context.scene.AnisotropyExtensionProperties
        self.layout.prop(props, 'enabled')

    def draw(self, context):
        layout = self.layout
        layout.use_property_split = True
        layout.use_property_decorate = False  # No animation.

        props = bpy.context.scene.AnisotropyExtensionProperties
        layout.active = props.enabled

        box = layout.box()
        box.label(text=props.extension_name)

        layout.prop(props, 'extension_name', text="GLTF extension name")


class glTF2ExportUserExtension:

    def __init__(self):
        # We need to wait until we create the gltf2AnisotropyExtension to import the gltf2 modules
        # Otherwise, it may fail because the gltf2 may not be loaded yet
        from io_scene_gltf2.io.com.gltf2_io_extensions import Extension
        self.Extension = Extension
        self.properties = bpy.context.scene.AnisotropyExtensionProperties


    def gather_material_hook(self, gltf2_material, blender_material, export_settings):


        def __has_image_node_from_socket(socket):
            result = gltf2_blender_search_node_tree.from_socket(
                socket,
                gltf2_blender_search_node_tree.FilterByType(bpy.types.ShaderNodeTexImage))
            if not result:
                return False
            return True


        if self.properties.enabled:

            aniso = gltf2_blender_get.get_socket(blender_material, "Anisotropic")
            if aniso is None:
                gltf2_blender_get.get_socket_old(blender_material, "Anisotropic")

            if aniso is None:
                return

            aniso = gltf2_blender_get.get_factor_from_socket(aniso, kind='VALUE')

            if abs(aniso) < 0.01:
                return

            anisoRot = gltf2_blender_get.get_socket(blender_material, "Anisotropic Rotation")
            if anisoRot is None:
                anisoRot = gltf2_blender_get.get_socket_old(blender_material, "Anisotropic Rotation")

            anisoTextureMode = 'CONSTANT'
            if anisoRot is None:
                anisoRot = 0
            elif __has_image_node_from_socket(anisoRot):
                anisoRot = gltf2_blender_gather_texture_info.gather_texture_info(anisoRot, (anisoRot,), export_settings)
                anisoTextureMode = 'ROTATION'
                if self.properties.directional_map_flag in blender_material.keys() and blender_material[self.properties.directional_map_flag] > 0:
                    anisoTextureMode = 'DIRECTION'
            else:
                anisoRot = gltf2_blender_get.get_factor_from_socket(anisoRot, kind='VALUE')

            extension_data = {'anisotropyFactor': aniso, 'anisotropyRotation': anisoRot, 'anisotropyTextureMode': anisoTextureMode}

            gltf2_material.extensions[self.properties.extension_name] = self.Extension(
                name=self.properties.extension_name,
                extension=extension_data,
                required=extension_is_required)


def dump(obj):
    for attr in dir(obj):
        if hasattr( obj, attr ):
            print( "obj.%s = %s" % (attr, getattr(obj, attr)))
