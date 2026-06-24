"""
Blender Python script to create 3D building models for Arab City.
Run with: blender --background --python create_buildings.py
Creates .fbx files for each building type.
"""
import bpy
import bmesh
import math
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/exports"
os.makedirs(OUTPUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for col in bpy.data.collections:
        if col.name != "Collection":
            bpy.data.collections.remove(col)


def new_material(name, color, metallic=0.0, roughness=0.5, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1.0:
        mat.blend_method = 'BLEND'
        bsdf.inputs["Alpha"].default_value = alpha
    return mat


def add_cube(name, location, scale, material=None):
    bpy.ops.mesh.primitive_cube_add(location=location, scale=scale)
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    return obj


def add_cylinder(name, location, radius, depth, material=None, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location
    )
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    return obj


def add_plane(name, location, size, material=None):
    bpy.ops.mesh.primitive_plane_add(size=size, location=location)
    obj = bpy.context.active_object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    return obj


def export_fbx(filepath):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=True,
        apply_scale_options='FBX_SCALE_ALL',
        mesh_smooth_type='FACE',
        add_leaf_bones=False,
    )


# ============================================================
# Materials
# ============================================================
def create_materials():
    mats = {}
    mats["wall_light"] = new_material("WallLight", (0.85, 0.87, 0.9))
    mats["wall_dark"] = new_material("WallDark", (0.25, 0.27, 0.3))
    mats["wall_brick"] = new_material("WallBrick", (0.6, 0.3, 0.2), roughness=0.8)
    mats["wall_cream"] = new_material("WallCream", (0.92, 0.88, 0.8))
    mats["wall_white"] = new_material("WallWhite", (0.95, 0.96, 0.97))
    mats["concrete"] = new_material("Concrete", (0.55, 0.55, 0.55), roughness=0.9)
    mats["glass"] = new_material("Glass", (0.5, 0.75, 0.9), metallic=0.1, roughness=0.1, alpha=0.3)
    mats["glass_dark"] = new_material("GlassDark", (0.1, 0.2, 0.3), metallic=0.2, roughness=0.05, alpha=0.4)
    mats["metal"] = new_material("Metal", (0.4, 0.42, 0.45), metallic=0.9, roughness=0.3)
    mats["metal_dark"] = new_material("MetalDark", (0.15, 0.15, 0.18), metallic=0.9, roughness=0.3)
    mats["roof_dark"] = new_material("RoofDark", (0.2, 0.22, 0.25))
    mats["roof_tile"] = new_material("RoofTile", (0.45, 0.25, 0.15), roughness=0.8)
    mats["wood"] = new_material("Wood", (0.45, 0.3, 0.15), roughness=0.7)
    mats["wood_dark"] = new_material("WoodDark", (0.25, 0.15, 0.08), roughness=0.7)
    mats["floor_marble"] = new_material("FloorMarble", (0.9, 0.88, 0.85), roughness=0.2)
    mats["floor_tile"] = new_material("FloorTile", (0.7, 0.68, 0.65), roughness=0.4)
    mats["gold"] = new_material("Gold", (0.83, 0.69, 0.22), metallic=0.95, roughness=0.2)
    mats["neon_cyan"] = new_material("NeonCyan", (0.0, 0.9, 1.0))
    mats["neon_pink"] = new_material("NeonPink", (1.0, 0.0, 0.47))
    mats["red"] = new_material("Red", (0.8, 0.15, 0.15))
    mats["blue"] = new_material("Blue", (0.15, 0.3, 0.7))
    mats["green"] = new_material("Green", (0.2, 0.55, 0.2))
    mats["fabric_brown"] = new_material("FabricBrown", (0.4, 0.25, 0.12), roughness=0.9)
    mats["fabric_gray"] = new_material("FabricGray", (0.5, 0.5, 0.52), roughness=0.85)
    mats["fabric_white"] = new_material("FabricWhite", (0.9, 0.9, 0.92), roughness=0.85)
    mats["plastic_white"] = new_material("PlasticWhite", (0.95, 0.95, 0.95), roughness=0.4)
    mats["screen_black"] = new_material("ScreenBlack", (0.02, 0.02, 0.03))
    return mats


# ============================================================
# Building: Residential House (Arabic villa style)
# ============================================================
def create_residential_house(mats):
    clear_scene()

    # Main body
    add_cube("MainBody", (0, 0, 1.5), (3.5, 3, 1.5), mats["wall_cream"])

    # Second floor (smaller, setback)
    add_cube("SecondFloor", (0, -0.5, 3.5), (2.5, 2.5, 1), mats["wall_cream"])

    # Roof terrace railing
    for x in [-2.5, 2.5]:
        add_cube(f"Railing_{x}", (x, -0.5, 4.7), (0.05, 2.5, 0.2), mats["wall_light"])
    for z in [-3, 3]:
        add_cube(f"RailingZ_{z}", (0, z - 0.5, 4.7), (2.5, 0.05, 0.2), mats["wall_light"])

    # Flat roof with slight overhang
    add_cube("Roof", (0, 0, 3.1), (3.8, 3.3, 0.1), mats["roof_dark"])

    # Entrance porch with arch
    add_cube("Porch", (0, 3.2, 1), (1.5, 0.3, 1), mats["wall_cream"])
    add_cube("PorchRoof", (0, 3.2, 2.1), (1.8, 0.5, 0.1), mats["roof_dark"])
    # Porch columns
    add_cylinder("PorchCol_L", (-1.2, 3.2, 1), 0.1, 2, mats["wall_light"])
    add_cylinder("PorchCol_R", (1.2, 3.2, 1), 0.1, 2, mats["wall_light"])

    # Door
    add_cube("Door", (0, 3.05, 0.9), (0.5, 0.05, 0.9), mats["wood_dark"])

    # Windows - Front (arched top style)
    for x in [-2, 2]:
        add_cube(f"Window_F_{x}", (x, 3.05, 1.2), (0.5, 0.05, 0.6), mats["glass"])
        add_cube(f"WindowFrame_F_{x}", (x, 3.07, 1.2), (0.55, 0.02, 0.65), mats["wall_dark"])

    # Windows - Sides
    for y in [-3.05, 3.05]:
        for x in [-1.5, 1.5]:
            add_cube(f"Window_S_{x}_{y}", (x, y, 1.2), (0.5, 0.05, 0.6), mats["glass"])

    # Second floor windows
    for x in [-1.2, 0, 1.2]:
        add_cube(f"Window_2F_{x}", (x, 2.55, 3.5), (0.4, 0.05, 0.5), mats["glass"])

    # Balcony on second floor
    add_cube("Balcony", (0, 3.3, 3.0), (1.8, 0.8, 0.05), mats["concrete"])
    add_cube("BalconyRail", (0, 3.7, 3.3), (1.8, 0.05, 0.3), mats["metal"])

    # Decorative elements - Arabic pattern trim
    add_cube("TrimTop", (0, 0, 2.95), (3.55, 3.05, 0.05), mats["gold"])

    # Garden wall
    add_cube("GardenWall_L", (-4, 1.5, 0.5), (0.1, 1.5, 0.5), mats["wall_cream"])
    add_cube("GardenWall_R", (4, 1.5, 0.5), (0.1, 1.5, 0.5), mats["wall_cream"])
    add_cube("GardenWall_F", (0, 4.5, 0.5), (4, 0.1, 0.5), mats["wall_cream"])

    # Garage
    add_cube("Garage", (-3, -1, 1), (1.2, 2, 1), mats["wall_cream"])
    add_cube("GarageDoor", (-3, 1, 0.8), (1, 0.05, 0.8), mats["metal_dark"])

    export_fbx(os.path.join(OUTPUT_DIR, "residential_house.fbx"))
    print("Exported: residential_house.fbx")


# ============================================================
# Building: Apartment Building (multi-story)
# ============================================================
def create_apartment_building(mats):
    clear_scene()

    # Main tower
    add_cube("MainTower", (0, 0, 4), (4, 4, 4), mats["wall_light"])

    # Floor separators
    for z in [2, 4, 6]:
        add_cube(f"FloorSep_{z}", (0, 0, z), (4.1, 4.1, 0.05), mats["concrete"])

    # Windows grid (4 floors x 4 windows per side)
    for floor in range(4):
        z = 1 + floor * 2
        for i in range(4):
            x = -2.5 + i * 1.7
            # Front
            add_cube(f"Win_F_{floor}_{i}", (x, 4.05, z), (0.5, 0.02, 0.6), mats["glass"])
            # Back
            add_cube(f"Win_B_{floor}_{i}", (x, -4.05, z), (0.5, 0.02, 0.6), mats["glass"])

    # Balconies (alternating)
    for floor in range(1, 4):
        z = 0.5 + floor * 2
        for i in range(2):
            x = -1.5 + i * 3
            add_cube(f"Balcony_{floor}_{i}", (x, 4.3, z), (0.8, 0.3, 0.05), mats["concrete"])
            add_cube(f"BalcRail_{floor}_{i}", (x, 4.5, z + 0.3), (0.8, 0.05, 0.25), mats["metal"])

    # Roof structure
    add_cube("Roof", (0, 0, 8.1), (4.2, 4.2, 0.1), mats["roof_dark"])
    # Rooftop water tank
    add_cylinder("WaterTank", (1.5, 1.5, 8.8), 0.5, 1.2, mats["metal"])
    # Rooftop AC units
    add_cube("AC_1", (-1.5, -1.5, 8.5), (0.5, 0.5, 0.3), mats["plastic_white"])
    add_cube("AC_2", (-1.5, 1.5, 8.5), (0.5, 0.5, 0.3), mats["plastic_white"])

    # Entrance canopy
    add_cube("Canopy", (0, 4.5, 2.3), (2, 0.8, 0.05), mats["metal_dark"])
    add_cube("EntranceDoor", (0, 4.05, 1), (0.7, 0.02, 1), mats["glass_dark"])

    # Ground floor shops
    add_cube("ShopFront", (-2, 4.05, 0.7), (1.5, 0.02, 0.7), mats["glass"])
    add_cube("ShopFront2", (2, 4.05, 0.7), (1.5, 0.02, 0.7), mats["glass"])

    export_fbx(os.path.join(OUTPUT_DIR, "apartment_building.fbx"))
    print("Exported: apartment_building.fbx")


# ============================================================
# Building: Bank (grand, serious architecture)
# ============================================================
def create_bank(mats):
    clear_scene()

    # Main structure
    add_cube("MainBody", (0, 0, 2.5), (5, 4, 2.5), mats["wall_dark"])

    # Grand entrance with columns
    for x in [-2, -0.7, 0.7, 2]:
        add_cylinder(f"Column_{x}", (x, 4, 2), 0.2, 4, mats["floor_marble"])

    # Pediment (triangular top)
    add_cube("Pediment", (0, 4, 4.5), (3, 0.3, 0.5), mats["wall_dark"])
    add_cube("PedimentTop", (0, 4, 5.1), (2, 0.2, 0.3), mats["gold"])

    # Entrance steps
    for i in range(3):
        add_cube(f"Step_{i}", (0, 4.5 + i * 0.3, i * 0.15), (2.5 - i * 0.2, 0.15, 0.15), mats["floor_marble"])

    # Vault door (gold accent)
    add_cube("VaultDoor", (0, 4.05, 1.5), (1, 0.05, 1.5), mats["gold"])
    add_cylinder("VaultHandle", (0, 4.15, 1.5), 0.3, 0.05, mats["metal"])

    # Windows (small, secure-looking)
    for floor in range(2):
        z = 1.5 + floor * 2
        for x in [-3, -1.5, 1.5, 3]:
            add_cube(f"Win_{floor}_{x}", (x, 4.05, z), (0.4, 0.02, 0.5), mats["glass_dark"])
            # Window bars
            for b in range(3):
                bx = x - 0.15 + b * 0.15
                add_cube(f"Bar_{floor}_{x}_{b}", (bx, 4.08, z), (0.02, 0.01, 0.5), mats["metal"])

    # Roof with parapet
    add_cube("Roof", (0, 0, 5.1), (5.2, 4.2, 0.1), mats["roof_dark"])
    add_cube("Parapet_F", (0, 4.2, 5.5), (5.2, 0.1, 0.4), mats["wall_dark"])
    add_cube("Parapet_B", (0, -4.2, 5.5), (5.2, 0.1, 0.4), mats["wall_dark"])

    # Security cameras
    add_cube("Camera1", (3, 4.1, 4.5), (0.1, 0.15, 0.1), mats["metal_dark"])
    add_cube("Camera2", (-3, 4.1, 4.5), (0.1, 0.15, 0.1), mats["metal_dark"])

    # ATM machines outside
    add_cube("ATM_1", (3.5, 4.1, 0.7), (0.3, 0.15, 0.7), mats["metal"])
    add_cube("ATM_2", (-3.5, 4.1, 0.7), (0.3, 0.15, 0.7), mats["metal"])

    export_fbx(os.path.join(OUTPUT_DIR, "bank.fbx"))
    print("Exported: bank.fbx")


# ============================================================
# Building: Hospital
# ============================================================
def create_hospital(mats):
    clear_scene()

    # Main building (wide, clean)
    add_cube("MainBody", (0, 0, 3), (6, 4, 3), mats["wall_white"])

    # Emergency wing (side extension)
    add_cube("EmergencyWing", (-5, 0, 1.5), (2, 3, 1.5), mats["wall_white"])

    # Red cross on front
    add_cube("Cross_H", (0, 4.05, 5), (1.2, 0.05, 0.3), mats["red"])
    add_cube("Cross_V", (0, 4.05, 5), (0.3, 0.05, 1.2), mats["red"])

    # Entrance with ambulance bay
    add_cube("Canopy", (0, 5, 2.5), (3, 1.5, 0.05), mats["metal"])
    add_cube("CanopySupport_L", (-2, 5.5, 1.25), (0.1, 0.1, 1.25), mats["metal"])
    add_cube("CanopySupport_R", (2, 5.5, 1.25), (0.1, 0.1, 1.25), mats["metal"])

    # Automatic doors
    add_cube("AutoDoor_L", (-0.5, 4.05, 1.2), (0.45, 0.02, 1.2), mats["glass"])
    add_cube("AutoDoor_R", (0.5, 4.05, 1.2), (0.45, 0.02, 1.2), mats["glass"])

    # Windows (many, evenly spaced)
    for floor in range(3):
        z = 1 + floor * 2
        for x_i in range(8):
            x = -5 + x_i * 1.5
            add_cube(f"Win_{floor}_{x_i}", (x, 4.05, z), (0.5, 0.02, 0.6), mats["glass"])

    # Helipad on roof
    add_cylinder("Helipad", (0, 0, 6.15), 1.5, 0.1, mats["concrete"])
    add_cube("HelipadH_1", (0, 0, 6.25), (0.8, 0.1, 0.1), mats["red"])
    add_cube("HelipadH_2", (0, 0, 6.25), (0.1, 0.8, 0.1), mats["red"])

    # Ambulance parking
    add_cube("AmbParking", (-5, 4, 0.05), (2, 2, 0.05), mats["concrete"])

    # Emergency sign
    add_cube("EmSign", (-5, 3.05, 2), (1.5, 0.05, 0.3), mats["red"])

    export_fbx(os.path.join(OUTPUT_DIR, "hospital.fbx"))
    print("Exported: hospital.fbx")


# ============================================================
# Building: Mall (modern glass and steel)
# ============================================================
def create_mall(mats):
    clear_scene()

    # Main structure (2 levels visible)
    add_cube("MainBody", (0, 0, 2.5), (8, 5, 2.5), mats["wall_light"])

    # Glass curtain wall (front)
    add_cube("GlassFront", (0, 5.05, 2.5), (7.5, 0.05, 2.3), mats["glass"])

    # Steel frame on glass
    for x in range(-6, 7, 3):
        add_cube(f"SteelV_{x}", (x, 5.1, 2.5), (0.05, 0.02, 2.5), mats["metal_dark"])
    for z in [1, 2.5, 4]:
        add_cube(f"SteelH_{z}", (0, 5.1, z), (8, 0.02, 0.05), mats["metal_dark"])

    # Entrance (grand double height)
    add_cube("EntranceFrame", (0, 5.2, 1.5), (2, 0.3, 1.5), mats["metal_dark"])
    add_cube("EntranceDoor_L", (-0.6, 5.05, 1), (0.5, 0.02, 1), mats["glass"])
    add_cube("EntranceDoor_R", (0.6, 5.05, 1), (0.5, 0.02, 1), mats["glass"])

    # Roof with skylights
    add_cube("Roof", (0, 0, 5.1), (8.2, 5.2, 0.1), mats["roof_dark"])
    for i in range(3):
        add_cube(f"Skylight_{i}", (-3 + i * 3, 0, 5.25), (1.5, 1.5, 0.05), mats["glass"])

    # Signage area
    add_cube("SignBoard", (0, 5.1, 4.5), (4, 0.05, 0.5), mats["metal_dark"])

    # Second floor visible balcony inside
    add_cube("Mezzanine", (0, 0, 2.5), (7, 1, 0.05), mats["concrete"])

    # Parking structure hint (side)
    add_cube("ParkingRamp", (-8.5, 0, 1), (1, 3, 1), mats["concrete"])

    export_fbx(os.path.join(OUTPUT_DIR, "mall.fbx"))
    print("Exported: mall.fbx")


# ============================================================
# Building: Police Station
# ============================================================
def create_police_station(mats):
    clear_scene()

    # Main body
    add_cube("MainBody", (0, 0, 2), (4.5, 3.5, 2), mats["blue"])

    # Watch tower
    add_cube("Tower", (3, -2, 3.5), (1, 1, 1.5), mats["blue"])
    add_cube("TowerGlass", (3, -2, 4.5), (0.8, 0.8, 0.4), mats["glass"])

    # Entrance
    add_cube("Entrance", (0, 3.55, 1.5), (2, 0.3, 1.5), mats["wall_dark"])
    add_cube("Door", (0, 3.55, 1), (0.7, 0.05, 1), mats["glass_dark"])

    # Police badge/shield decor on front
    add_cylinder("Badge", (0, 3.6, 3.2), 0.5, 0.05, mats["gold"], 6)

    # Garage for patrol cars
    add_cube("Garage", (-2.5, 3.55, 1.2), (1.5, 0.3, 1.2), mats["wall_dark"])
    add_cube("GarageDoor", (-2.5, 3.55, 0.9), (1.3, 0.05, 0.9), mats["metal"])

    # Antenna
    add_cylinder("Antenna", (2, -1, 5.5), 0.03, 3, mats["metal"])

    # Floodlights
    add_cube("Light_L", (-4, 2, 3.5), (0.2, 0.2, 0.15), mats["plastic_white"])
    add_cube("Light_R", (4, 2, 3.5), (0.2, 0.2, 0.15), mats["plastic_white"])

    # Windows
    for x in [-2, 0, 2]:
        add_cube(f"Win_F_{x}", (x, 3.55, 2.5), (0.5, 0.02, 0.5), mats["glass_dark"])
    for x in [-2, 0, 2]:
        add_cube(f"Win_B_{x}", (x, -3.55, 2.5), (0.5, 0.02, 0.5), mats["glass_dark"])

    # Barrier/gate
    add_cube("Barrier", (0, 5, 0.4), (0.1, 2, 0.4), mats["red"])

    export_fbx(os.path.join(OUTPUT_DIR, "police_station.fbx"))
    print("Exported: police_station.fbx")


# ============================================================
# Building: Fire Station
# ============================================================
def create_fire_station(mats):
    clear_scene()

    # Main body
    add_cube("MainBody", (0, 0, 2.5), (5, 4, 2.5), mats["red"])

    # Large garage doors (3 bays)
    for i in range(3):
        x = -2.5 + i * 2.5
        add_cube(f"GarageDoor_{i}", (x, 4.05, 1.5), (1, 0.02, 1.5), mats["metal"])
        add_cube(f"GarageFrame_{i}", (x, 4.07, 1.5), (1.1, 0.01, 1.6), mats["metal_dark"])

    # Training tower
    add_cube("TrainTower", (4, -2, 4), (1.2, 1.2, 4), mats["concrete"])
    # Tower windows (small)
    for z in [2, 4, 6]:
        add_cube(f"TowerWin_{z}", (4, -0.85, z), (0.3, 0.02, 0.3), mats["glass_dark"])

    # Hose drying rack
    add_cube("HoseRack_L", (5.5, 0, 3), (0.05, 0.05, 3), mats["metal"])
    add_cube("HoseRack_R", (5.5, 1, 3), (0.05, 0.05, 3), mats["metal"])
    add_cube("HoseRack_Top", (5.5, 0.5, 6), (0.05, 0.5, 0.05), mats["metal"])

    # Siren on roof
    add_cylinder("Siren", (0, 0, 5.5), 0.2, 0.5, mats["red"])

    # Upper floor windows
    for x in [-3, -1.5, 0, 1.5, 3]:
        add_cube(f"Win_U_{x}", (x, 4.05, 3.8), (0.5, 0.02, 0.5), mats["glass"])

    # Roof
    add_cube("Roof", (0, 0, 5.1), (5.2, 4.2, 0.1), mats["roof_dark"])

    export_fbx(os.path.join(OUTPUT_DIR, "fire_station.fbx"))
    print("Exported: fire_station.fbx")


# ============================================================
# Building: Airport Terminal
# ============================================================
def create_airport_terminal(mats):
    clear_scene()

    # Main terminal (long, curved roof effect via flat)
    add_cube("MainBody", (0, 0, 2.5), (10, 4, 2.5), mats["wall_light"])

    # Curved roof simulation (tiered)
    add_cube("RoofLow", (0, 0, 5.1), (10.5, 4.5, 0.1), mats["metal"])
    add_cube("RoofMid", (0, 0, 5.5), (8, 3, 0.1), mats["metal"])
    add_cube("RoofHigh", (0, 0, 5.8), (5, 2, 0.1), mats["metal"])

    # Glass curtain wall (full front)
    add_cube("GlassFront", (0, 4.05, 2.5), (9.5, 0.05, 2.3), mats["glass"])
    # Mullions
    for x in range(-9, 10, 2):
        add_cube(f"Mullion_{x}", (x, 4.1, 2.5), (0.03, 0.02, 2.5), mats["metal_dark"])

    # Control tower
    add_cube("ControlBase", (8, -2, 4), (1, 1, 4), mats["concrete"])
    add_cube("ControlTop", (8, -2, 8.5), (1.5, 1.5, 0.8), mats["glass_dark"])
    add_cylinder("ControlBeacon", (8, -2, 9.5), 0.15, 0.3, mats["red"])

    # Entrance canopy
    add_cube("Canopy", (0, 5.5, 3), (6, 1.5, 0.05), mats["metal"])
    for x in [-3, -1, 1, 3]:
        add_cylinder(f"CanopyPillar_{x}", (x, 5.5, 1.5), 0.1, 3, mats["metal"])

    # Boarding bridges (2)
    add_cube("Bridge_1", (-5, -4.5, 2.5), (0.8, 2, 0.8), mats["metal"])
    add_cube("Bridge_2", (5, -4.5, 2.5), (0.8, 2, 0.8), mats["metal"])

    # Runway lights (decorative)
    for i in range(10):
        add_cube(f"RunwayLight_{i}", (-9 + i * 2, -6, 0.1), (0.1, 0.1, 0.1), mats["neon_cyan"])

    export_fbx(os.path.join(OUTPUT_DIR, "airport_terminal.fbx"))
    print("Exported: airport_terminal.fbx")


# ============================================================
# Building: VIP Lounge (luxury, dark with gold)
# ============================================================
def create_vip_lounge(mats):
    clear_scene()

    # Main body (dark, luxurious)
    add_cube("MainBody", (0, 0, 2), (4, 3, 2), mats["wall_dark"])

    # Gold trim lines
    for z in [0.1, 2, 4]:
        add_cube(f"GoldTrim_{z}", (0, 3.05, z), (4, 0.02, 0.05), mats["gold"])

    # Entrance (VIP red carpet area)
    add_cube("Carpet", (0, 4, 0.02), (1, 2, 0.02), mats["red"])

    # Grand doors (gold frame)
    add_cube("DoorFrame", (0, 3.05, 1.5), (1.2, 0.08, 1.5), mats["gold"])
    add_cube("Door_L", (-0.35, 3.05, 1.5), (0.3, 0.03, 1.3), mats["glass_dark"])
    add_cube("Door_R", (0.35, 3.05, 1.5), (0.3, 0.03, 1.3), mats["glass_dark"])

    # Columns at entrance
    add_cylinder("Col_L", (-1.5, 3.5, 2), 0.15, 4, mats["gold"])
    add_cylinder("Col_R", (1.5, 3.5, 2), 0.15, 4, mats["gold"])

    # VIP star on top
    add_cube("StarBase", (0, 3.1, 3.8), (0.8, 0.05, 0.8), mats["gold"])

    # Tinted windows
    for x in [-2.5, 2.5]:
        add_cube(f"Win_{x}", (x, 3.05, 2.5), (0.6, 0.02, 0.8), mats["glass_dark"])

    # Velvet rope (simplified as cubes)
    add_cylinder("Rope_L", (-1, 5, 0.4), 0.05, 0.8, mats["gold"])
    add_cylinder("Rope_R", (1, 5, 0.4), 0.05, 0.8, mats["gold"])
    add_cube("RopeChain", (0, 5, 0.6), (1, 0.02, 0.02), mats["red"])

    # Roof with parapet
    add_cube("Roof", (0, 0, 4.1), (4.3, 3.3, 0.1), mats["roof_dark"])
    add_cube("Parapet", (0, 3.2, 4.5), (4.3, 0.1, 0.3), mats["gold"])

    export_fbx(os.path.join(OUTPUT_DIR, "vip_lounge.fbx"))
    print("Exported: vip_lounge.fbx")


# ============================================================
# Building: Car Dealership (modern showroom)
# ============================================================
def create_car_dealership(mats):
    clear_scene()

    # Main showroom (glass box)
    add_cube("MainBody", (0, 0, 2), (6, 5, 2), mats["wall_light"])

    # Full glass front
    add_cube("GlassFront", (0, 5.05, 2), (5.5, 0.03, 1.8), mats["glass"])

    # Showroom floor (polished)
    add_cube("Floor", (0, 0, 0.05), (6, 5, 0.05), mats["floor_marble"])

    # Display platforms
    for i in range(3):
        x = -3 + i * 3
        add_cylinder(f"Platform_{i}", (x, 0, 0.2), 1, 0.2, mats["metal_dark"])

    # Upper office area
    add_cube("Office", (0, -3, 3.5), (5, 1.5, 0.8), mats["wall_light"])
    add_cube("OfficeGlass", (0, -1.55, 3.5), (5, 0.03, 0.7), mats["glass"])

    # Roof
    add_cube("Roof", (0, 0, 4.1), (6.3, 5.3, 0.1), mats["roof_dark"])

    # Signage
    add_cube("SignBoard", (0, 5.1, 3.5), (3, 0.05, 0.5), mats["metal_dark"])

    # Test drive area
    add_cube("TestDrive", (7, 0, 0.05), (2, 5, 0.05), mats["concrete"])

    export_fbx(os.path.join(OUTPUT_DIR, "car_dealership.fbx"))
    print("Exported: car_dealership.fbx")


# ============================================================
# Furniture: Living Room Set
# ============================================================
def create_furniture_livingroom(mats):
    clear_scene()

    # Sofa (L-shaped)
    add_cube("SofaBase", (0, 0, 0.25), (1.5, 0.5, 0.25), mats["fabric_brown"])
    add_cube("SofaBack", (0, -0.45, 0.55), (1.5, 0.05, 0.3), mats["fabric_brown"])
    add_cube("SofaArm_L", (-1.5, 0, 0.4), (0.1, 0.5, 0.4), mats["fabric_brown"])
    add_cube("SofaArm_R", (1.5, 0, 0.4), (0.1, 0.5, 0.4), mats["fabric_brown"])
    # Cushions
    add_cube("Cushion_1", (-0.6, 0, 0.52), (0.4, 0.35, 0.05), mats["fabric_gray"])
    add_cube("Cushion_2", (0.6, 0, 0.52), (0.4, 0.35, 0.05), mats["fabric_gray"])

    # Coffee table
    add_cube("CoffeeTable", (0, 1.2, 0.2), (0.6, 0.4, 0.02), mats["wood"])
    for x, y in [(-0.5, 0.9), (0.5, 0.9), (-0.5, 1.5), (0.5, 1.5)]:
        add_cylinder(f"TableLeg_{x}_{y}", (x, y, 0.1), 0.03, 0.2, mats["metal"])

    # TV stand + TV
    add_cube("TVStand", (0, 2.5, 0.3), (1, 0.25, 0.3), mats["wood_dark"])
    add_cube("TV", (0, 2.5, 0.8), (1.2, 0.03, 0.4), mats["screen_black"])

    # Bookshelf
    add_cube("ShelfFrame", (-2, -0.3, 0.6), (0.15, 0.5, 0.6), mats["wood"])
    for z in [0.2, 0.5, 0.8]:
        add_cube(f"Shelf_{z}", (-2, -0.3, z), (0.15, 0.45, 0.02), mats["wood"])

    # Rug
    add_cube("Rug", (0, 0.6, 0.02), (1.2, 0.8, 0.01), mats["red"])

    # Lamp
    add_cylinder("LampBase", (1.8, -0.3, 0.02), 0.1, 0.04, mats["metal_dark"])
    add_cylinder("LampPole", (1.8, -0.3, 0.5), 0.02, 1, mats["metal"])
    add_cylinder("LampShade", (1.8, -0.3, 1.0), 0.15, 0.2, mats["fabric_white"], 8)

    export_fbx(os.path.join(OUTPUT_DIR, "furniture_livingroom.fbx"))
    print("Exported: furniture_livingroom.fbx")


# ============================================================
# Furniture: Bedroom Set
# ============================================================
def create_furniture_bedroom(mats):
    clear_scene()

    # Bed frame
    add_cube("BedFrame", (0, 0, 0.2), (1, 1.2, 0.2), mats["wood_dark"])
    # Mattress
    add_cube("Mattress", (0, 0, 0.4), (0.95, 1.15, 0.12), mats["fabric_white"])
    # Pillow
    add_cube("Pillow_1", (-0.3, -0.9, 0.55), (0.25, 0.2, 0.07), mats["fabric_white"])
    add_cube("Pillow_2", (0.3, -0.9, 0.55), (0.25, 0.2, 0.07), mats["fabric_white"])
    # Headboard
    add_cube("Headboard", (0, -1.2, 0.6), (1, 0.05, 0.4), mats["wood_dark"])

    # Nightstand
    add_cube("Nightstand", (-1.3, -0.8, 0.25), (0.25, 0.25, 0.25), mats["wood_dark"])
    # Lamp on nightstand
    add_cylinder("NightLamp", (-1.3, -0.8, 0.55), 0.05, 0.1, mats["metal"])
    add_cube("NightLampShade", (-1.3, -0.8, 0.65), (0.1, 0.1, 0.07), mats["fabric_white"])

    # Wardrobe
    add_cube("Wardrobe", (1.5, 0, 0.7), (0.4, 0.8, 0.7), mats["wood"])
    add_cube("WardrobeDoor_L", (1.3, 0, 0.7), (0.02, 0.75, 0.65), mats["wood"])
    add_cube("WardrobeDoor_R", (1.7, 0, 0.7), (0.02, 0.75, 0.65), mats["wood"])
    # Handles
    add_cube("Handle_L", (1.32, 0.1, 0.7), (0.01, 0.05, 0.02), mats["metal"])
    add_cube("Handle_R", (1.68, -0.1, 0.7), (0.01, 0.05, 0.02), mats["metal"])

    # Dresser with mirror
    add_cube("Dresser", (-1.5, 0.8, 0.35), (0.4, 0.3, 0.35), mats["wood"])
    add_cube("Mirror", (-1.5, 0.8, 0.9), (0.35, 0.02, 0.3), mats["glass"])
    add_cube("MirrorFrame", (-1.5, 0.8, 0.9), (0.37, 0.025, 0.32), mats["gold"])

    export_fbx(os.path.join(OUTPUT_DIR, "furniture_bedroom.fbx"))
    print("Exported: furniture_bedroom.fbx")


# ============================================================
# Furniture: Kitchen Set
# ============================================================
def create_furniture_kitchen(mats):
    clear_scene()

    # Counter (L-shaped)
    add_cube("Counter", (0, 0, 0.45), (1.5, 0.3, 0.45), mats["floor_marble"])
    add_cube("CounterBase", (0, 0, 0.2), (1.5, 0.3, 0.2), mats["wood"])
    # Counter side
    add_cube("CounterSide", (-1.3, -0.7, 0.45), (0.3, 1, 0.45), mats["floor_marble"])
    add_cube("CounterSideBase", (-1.3, -0.7, 0.2), (0.3, 1, 0.2), mats["wood"])

    # Sink
    add_cube("Sink", (0.5, 0, 0.47), (0.3, 0.2, 0.03), mats["metal"])
    add_cylinder("Faucet", (0.5, -0.15, 0.6), 0.02, 0.2, mats["metal"])

    # Stove
    add_cube("Stove", (-0.5, 0, 0.47), (0.35, 0.28, 0.02), mats["metal_dark"])
    # Burners
    for x, y in [(-0.6, -0.05), (-0.4, -0.05), (-0.6, 0.1), (-0.4, 0.1)]:
        add_cylinder(f"Burner_{x}_{y}", (x, y, 0.49), 0.05, 0.01, mats["metal"])

    # Refrigerator
    add_cube("Fridge", (1.8, 0, 0.7), (0.4, 0.35, 0.7), mats["metal"])
    add_cube("FridgeHandle", (1.6, 0.1, 0.9), (0.01, 0.02, 0.2), mats["metal_dark"])
    add_cube("FridgeHandle2", (1.6, 0.1, 0.3), (0.01, 0.02, 0.15), mats["metal_dark"])

    # Upper cabinets
    add_cube("Cabinet_1", (-0.5, -0.28, 1.2), (0.4, 0.02, 0.3), mats["wood"])
    add_cube("Cabinet_2", (0.5, -0.28, 1.2), (0.4, 0.02, 0.3), mats["wood"])

    # Dining table
    add_cube("DiningTable", (0, 1.5, 0.4), (0.6, 0.4, 0.02), mats["wood"])
    for x, y in [(-0.4, 1.2), (0.4, 1.2), (-0.4, 1.8), (0.4, 1.8)]:
        add_cylinder(f"DTableLeg_{x}_{y}", (x, y, 0.2), 0.03, 0.4, mats["wood"])
    # Chairs
    for x in [-0.4, 0.4]:
        add_cube(f"Chair_{x}", (x, 2.1, 0.25), (0.2, 0.2, 0.25), mats["wood"])
        add_cube(f"ChairBack_{x}", (x, 2.25, 0.55), (0.2, 0.02, 0.2), mats["wood"])

    export_fbx(os.path.join(OUTPUT_DIR, "furniture_kitchen.fbx"))
    print("Exported: furniture_kitchen.fbx")


# ============================================================
# Furniture: Office Set (for bank/police interiors)
# ============================================================
def create_furniture_office(mats):
    clear_scene()

    # Office desk
    add_cube("Desk", (0, 0, 0.38), (1.2, 0.5, 0.02), mats["wood"])
    add_cube("DeskPanel_L", (-1.1, 0, 0.19), (0.02, 0.45, 0.19), mats["wood"])
    add_cube("DeskPanel_R", (1.1, 0, 0.19), (0.02, 0.45, 0.19), mats["wood"])
    add_cube("DeskBack", (0, -0.45, 0.19), (1.2, 0.02, 0.19), mats["wood"])

    # Computer monitor
    add_cube("Monitor", (0, -0.2, 0.6), (0.4, 0.02, 0.25), mats["screen_black"])
    add_cube("MonitorStand", (0, -0.2, 0.42), (0.05, 0.05, 0.05), mats["metal"])
    add_cube("MonitorBase", (0, -0.2, 0.39), (0.15, 0.08, 0.01), mats["metal"])
    # Keyboard
    add_cube("Keyboard", (0, 0.1, 0.4), (0.25, 0.08, 0.01), mats["metal_dark"])

    # Office chair
    add_cylinder("ChairSeat", (0, 0.8, 0.3), 0.25, 0.05, mats["fabric_gray"])
    add_cube("ChairBack", (0, 1.0, 0.55), (0.2, 0.02, 0.2), mats["fabric_gray"])
    add_cylinder("ChairPole", (0, 0.8, 0.15), 0.03, 0.3, mats["metal"])
    # Chair wheels
    for angle in range(0, 360, 72):
        rad = math.radians(angle)
        wx = 0.15 * math.cos(rad)
        wy = 0.8 + 0.15 * math.sin(rad)
        add_cube(f"Wheel_{angle}", (wx, wy, 0.03), (0.02, 0.02, 0.03), mats["metal_dark"])

    # Filing cabinet
    add_cube("FileCabinet", (-1.8, -0.2, 0.4), (0.25, 0.3, 0.4), mats["metal"])
    for z in [0.15, 0.4, 0.65]:
        add_cube(f"Drawer_{z}", (-1.78, -0.2, z), (0.22, 0.27, 0.1), mats["metal"])
        add_cube(f"DrawerHandle_{z}", (-1.56, -0.2, z), (0.01, 0.05, 0.02), mats["metal_dark"])

    # Potted plant
    add_cube("Pot", (1.5, -0.3, 0.15), (0.12, 0.12, 0.15), mats["fabric_brown"])
    add_cube("Plant", (1.5, -0.3, 0.4), (0.2, 0.2, 0.15), mats["green"])

    export_fbx(os.path.join(OUTPUT_DIR, "furniture_office.fbx"))
    print("Exported: furniture_office.fbx")


# ============================================================
# Main execution
# ============================================================
if __name__ == "__main__":
    mats = create_materials()

    print("=== Creating Arab City 3D Building Models ===")
    create_residential_house(mats)
    create_apartment_building(mats)
    create_bank(mats)
    create_hospital(mats)
    create_mall(mats)
    create_police_station(mats)
    create_fire_station(mats)
    create_airport_terminal(mats)
    create_vip_lounge(mats)
    create_car_dealership(mats)

    print("\n=== Creating Furniture Sets ===")
    create_furniture_livingroom(mats)
    create_furniture_bedroom(mats)
    create_furniture_kitchen(mats)
    create_furniture_office(mats)

    print("\n=== All models exported successfully! ===")
