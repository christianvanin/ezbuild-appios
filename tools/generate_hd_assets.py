import bpy
import bmesh
import math
import os

OUTPUT_DIR = os.path.abspath(r"SheriffGame\Models")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_mat(name, color_rgba, roughness=0.6, metallic=0.0, emission_rgba=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = color_rgba
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if emission_rgba:
        bsdf.inputs['Emission Color'].default_value = emission_rgba
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def assign_mat(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)

def export_obj(filename):
    filepath = os.path.join(OUTPUT_DIR, filename)
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    bpy.ops.wm.obj_export(
        filepath=filepath,
        export_selected_objects=True,
        apply_modifiers=True,
        export_materials=True
    )
    print(f"Exported: {filepath}")

# ==============================================================================
# 1. FPS REVOLVER (Colt .45 Peacemaker)
# ==============================================================================
def build_revolver():
    clear_scene()
    m_sleeve = create_mat("MatSleeve", (0.32, 0.18, 0.08, 1.0), roughness=0.85)
    m_skin = create_mat("MatSkin", (0.82, 0.62, 0.50, 1.0), roughness=0.5)
    m_steel = create_mat("MatSteel", (0.16, 0.18, 0.20, 1.0), roughness=0.25, metallic=0.9)
    m_gold = create_mat("MatGold", (0.85, 0.70, 0.22, 1.0), roughness=0.3, metallic=0.8)
    m_wood = create_mat("MatWood", (0.24, 0.12, 0.06, 1.0), roughness=0.7)

    # Braccio e polsino
    bpy.ops.mesh.primitive_cylinder_add(radius=0.052, depth=0.32, location=(0.26, -0.30, -0.20))
    arm = bpy.context.active_object
    arm.rotation_euler = (math.radians(22), math.radians(-12), math.radians(-18))
    assign_mat(arm, m_sleeve)

    # Mano
    bpy.ops.mesh.primitive_cube_add(size=0.065, location=(0.20, -0.20, -0.12))
    hand = bpy.context.active_object
    hand.scale = (0.7, 1.0, 0.85)
    assign_mat(hand, m_skin)

    # Impugnatura sagomata
    bpy.ops.mesh.primitive_cube_add(size=0.045, location=(0.18, -0.19, -0.10))
    grip = bpy.context.active_object
    grip.scale = (0.5, 0.8, 1.3)
    grip.rotation_euler = (math.radians(20), 0, 0)
    assign_mat(grip, m_wood)

    # Castello/Telaio revolver
    bpy.ops.mesh.primitive_cube_add(size=0.055, location=(0.18, -0.24, -0.06))
    frame = bpy.context.active_object
    frame.scale = (0.45, 1.25, 0.75)
    assign_mat(frame, m_steel)

    # Tamburo scanalato
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.024, depth=0.065, location=(0.18, -0.25, -0.06))
    cyl = bpy.context.active_object
    cyl.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(cyl, m_steel)

    # Dettaglio dorato sul tamburo
    bpy.ops.mesh.primitive_torus_add(major_radius=0.024, minor_radius=0.003, location=(0.18, -0.25, -0.06))
    ring = bpy.context.active_object
    ring.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(ring, m_gold)

    # Canna ottagonale lunga
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.015, depth=0.22, location=(0.18, -0.38, -0.055))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(barrel, m_steel)

    # Sotto-canna (espulsore bossoli)
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.007, depth=0.18, location=(0.192, -0.37, -0.07))
    ejector = bpy.context.active_object
    ejector.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(ejector, m_steel)

    # Cane e mirino anteriore
    bpy.ops.mesh.primitive_cube_add(size=0.012, location=(0.18, -0.48, -0.038))
    sight = bpy.context.active_object
    sight.scale = (0.3, 0.7, 0.9)
    assign_mat(sight, m_gold)

    bpy.ops.mesh.primitive_cube_add(size=0.014, location=(0.18, -0.18, -0.04))
    hammer = bpy.context.active_object
    hammer.scale = (0.4, 0.6, 1.2)
    assign_mat(hammer, m_steel)

    export_obj("fps_revolver.obj")

# ==============================================================================
# 2. FPS SHOTGUN (Doppietta Cal. 12)
# ==============================================================================
def build_shotgun():
    clear_scene()
    m_sleeve = create_mat("MatSleeve", (0.32, 0.18, 0.08, 1.0), roughness=0.85)
    m_skin = create_mat("MatSkin", (0.82, 0.62, 0.50, 1.0), roughness=0.5)
    m_steel = create_mat("MatDarkSteel", (0.12, 0.13, 0.14, 1.0), roughness=0.2, metallic=0.95)
    m_wood = create_mat("MatDarkWood", (0.22, 0.11, 0.05, 1.0), roughness=0.65)
    m_brass = create_mat("MatBrass", (0.80, 0.65, 0.20, 1.0), roughness=0.35, metallic=0.75)

    # Braccio e mano sinistra sotto l'astina
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.30, location=(0.12, -0.36, -0.22))
    arm_l = bpy.context.active_object
    arm_l.rotation_euler = (math.radians(35), math.radians(20), math.radians(-10))
    assign_mat(arm_l, m_sleeve)

    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0.14, -0.32, -0.13))
    hand_l = bpy.context.active_object
    hand_l.scale = (0.8, 1.1, 0.7)
    assign_mat(hand_l, m_skin)

    # Calcio in legno intagliato
    bpy.ops.mesh.primitive_cube_add(size=0.07, location=(0.20, -0.14, -0.12))
    stock = bpy.context.active_object
    stock.scale = (0.45, 1.6, 0.95)
    stock.rotation_euler = (math.radians(16), 0, 0)
    assign_mat(stock, m_wood)

    # Calciolo in ottone posteriore
    bpy.ops.mesh.primitive_cube_add(size=0.035, location=(0.20, -0.05, -0.15))
    plate = bpy.context.active_object
    plate.scale = (0.5, 0.3, 1.6)
    assign_mat(plate, m_brass)

    # Ricevitore basculante con incisioni
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0.18, -0.25, -0.07))
    receiver = bpy.context.active_object
    receiver.scale = (0.55, 1.0, 0.75)
    assign_mat(receiver, m_steel)

    # Astina in legno sotto le canne
    bpy.ops.mesh.primitive_cube_add(size=0.045, location=(0.18, -0.34, -0.09))
    forend = bpy.context.active_object
    forend.scale = (0.7, 1.4, 0.6)
    assign_mat(forend, m_wood)

    # Doppie canne affiancate calibro 12
    for offset_x in [-0.016, 0.016]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.014, depth=0.34, location=(0.18 + offset_x, -0.42, -0.065))
        barrel = bpy.context.active_object
        barrel.rotation_euler = (math.radians(90), 0, 0)
        assign_mat(barrel, m_steel)

    # Bindella ventilata superiore
    bpy.ops.mesh.primitive_cube_add(size=0.012, location=(0.18, -0.42, -0.05))
    rib = bpy.context.active_object
    rib.scale = (0.6, 14.0, 0.25)
    assign_mat(rib, m_steel)

    # Mirino a perla in ottone
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.005, location=(0.18, -0.58, -0.048))
    bead = bpy.context.active_object
    assign_mat(bead, m_brass)

    export_obj("fps_shotgun.obj")

# ==============================================================================
# 3. FPS RIFLE (Winchester 1873 a Leva)
# ==============================================================================
def build_rifle():
    clear_scene()
    m_sleeve = create_mat("MatSleeve", (0.32, 0.18, 0.08, 1.0), roughness=0.85)
    m_skin = create_mat("MatSkin", (0.82, 0.62, 0.50, 1.0), roughness=0.5)
    m_steel = create_mat("MatGunMetal", (0.18, 0.19, 0.22, 1.0), roughness=0.22, metallic=0.92)
    m_wood = create_mat("MatWalnut", (0.26, 0.13, 0.06, 1.0), roughness=0.6)
    m_brass = create_mat("MatBrass", (0.85, 0.72, 0.22, 1.0), roughness=0.3, metallic=0.8)

    # Calcio slanciato
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0.19, -0.12, -0.12))
    stock = bpy.context.active_object
    stock.scale = (0.42, 1.8, 0.85)
    stock.rotation_euler = (math.radians(14), 0, 0)
    assign_mat(stock, m_wood)

    # Castello in ottone "Yellow Boy"
    bpy.ops.mesh.primitive_cube_add(size=0.055, location=(0.18, -0.24, -0.07))
    frame = bpy.context.active_object
    frame.scale = (0.48, 1.3, 0.82)
    assign_mat(frame, m_brass)

    # Leva di caricamento inferiore a passante
    bpy.ops.mesh.primitive_torus_add(major_radius=0.022, minor_radius=0.004, location=(0.18, -0.22, -0.12))
    lever = bpy.context.active_object
    lever.rotation_euler = (0, math.radians(90), math.radians(20))
    assign_mat(lever, m_brass)

    # Canna ottagonale lunga
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.013, depth=0.48, location=(0.18, -0.48, -0.06))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(barrel, m_steel)

    # Serbatoio tubolare sotto la canna
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.011, depth=0.46, location=(0.18, -0.47, -0.082))
    tube = bpy.context.active_object
    tube.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(tube, m_steel)

    # Astina paramano in legno
    bpy.ops.mesh.primitive_cube_add(size=0.042, location=(0.18, -0.37, -0.076))
    handguard = bpy.context.active_object
    handguard.scale = (0.6, 2.8, 0.7)
    assign_mat(handguard, m_wood)

    # Fascette di ritenzione in ottone
    for z_off in [-0.32, -0.48]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.016, minor_radius=0.003, location=(0.18, z_off, -0.07))
        band = bpy.context.active_object
        band.rotation_euler = (math.radians(90), 0, 0)
        assign_mat(band, m_brass)

    export_obj("fps_rifle.obj")

# ==============================================================================
# 4. FPS SNIPER (Sharps con Cannocchiale in Ottone)
# ==============================================================================
def build_sniper():
    clear_scene()
    m_steel = create_mat("MatBluedSteel", (0.10, 0.12, 0.15, 1.0), roughness=0.2, metallic=0.95)
    m_wood = create_mat("MatRichWood", (0.20, 0.09, 0.04, 1.0), roughness=0.6)
    m_brass = create_mat("MatPolishedBrass", (0.88, 0.74, 0.20, 1.0), roughness=0.25, metallic=0.85)
    m_lens = create_mat("MatLens", (0.3, 0.7, 0.9, 1.0), roughness=0.1, metallic=0.1)

    # Calcio pesante da tiro
    bpy.ops.mesh.primitive_cube_add(size=0.065, location=(0.19, -0.10, -0.11))
    stock = bpy.context.active_object
    stock.scale = (0.42, 1.9, 0.9)
    stock.rotation_euler = (math.radians(12), 0, 0)
    assign_mat(stock, m_wood)

    # Meccanismo blocco cadente Sharps
    bpy.ops.mesh.primitive_cube_add(size=0.055, location=(0.18, -0.23, -0.065))
    action = bpy.context.active_object
    action.scale = (0.45, 1.1, 0.75)
    assign_mat(action, m_steel)

    # Canna lunga pesante rigata
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.015, depth=0.55, location=(0.18, -0.52, -0.06))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(barrel, m_steel)

    # Cannocchiale telescopico in ottone
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.012, depth=0.38, location=(0.18, -0.34, -0.025))
    scope = bpy.context.active_object
    scope.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(scope, m_brass)

    # Supporti/Anelli di montaggio cannocchiale
    for y_pos in [-0.22, -0.42]:
        bpy.ops.mesh.primitive_cube_add(size=0.018, location=(0.18, y_pos, -0.042))
        mount = bpy.context.active_object
        mount.scale = (0.5, 0.3, 1.1)
        assign_mat(mount, m_brass)

    # Lente anteriore e posteriore
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.011, depth=0.005, location=(0.18, -0.53, -0.025))
    lens_f = bpy.context.active_object
    lens_f.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(lens_f, m_lens)

    export_obj("fps_sniper.obj")

# ==============================================================================
# 5. FPS DYNAMITE (Candelotto di Dinamite con Miccia)
# ==============================================================================
def build_dynamite():
    clear_scene()
    m_red = create_mat("MatTNT", (0.85, 0.15, 0.12, 1.0), roughness=0.7)
    m_rope = create_mat("MatRope", (0.55, 0.45, 0.30, 1.0), roughness=0.9)
    m_fuse = create_mat("MatFuse", (0.25, 0.22, 0.20, 1.0), roughness=0.9)
    m_spark = create_mat("MatSpark", (1.0, 0.9, 0.2, 1.0), roughness=0.1, emission_rgba=(1.0, 0.8, 0.1, 1.0), emission_strength=5.0)

    # Fascio di 3 candelotti legati insieme
    positions = [(0.17, -0.25, -0.08), (0.195, -0.25, -0.08), (0.182, -0.25, -0.06)]
    for pos in positions:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.016, depth=0.18, location=pos)
        stick = bpy.context.active_object
        stick.rotation_euler = (math.radians(65), 0, math.radians(-15))
        assign_mat(stick, m_red)

    # Nastri/Corde di legatura
    for y_off in [-0.22, -0.28]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.032, minor_radius=0.005, location=(0.182, y_off, -0.073))
        strap = bpy.context.active_object
        strap.rotation_euler = (math.radians(65), 0, math.radians(-15))
        assign_mat(strap, m_rope)

    # Miccia curva
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.004, depth=0.06, location=(0.17, -0.34, -0.03))
    fuse = bpy.context.active_object
    fuse.rotation_euler = (math.radians(35), math.radians(20), 0)
    assign_mat(fuse, m_fuse)

    # Scintilla luminescente sulla punta
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.008, location=(0.165, -0.37, -0.015))
    spark = bpy.context.active_object
    assign_mat(spark, m_spark)

    export_obj("fps_dynamite.obj")

# ==============================================================================
# 6. ZOMBIE WALKER (Zombi Voxel Far West)
# ==============================================================================
def build_zombie_walker():
    clear_scene()
    m_skin = create_mat("MatZSkin", (0.35, 0.52, 0.32, 1.0), roughness=0.8)
    m_shirt = create_mat("MatZShirt", (0.28, 0.32, 0.40, 1.0), roughness=0.9)
    m_pants = create_mat("MatZPants", (0.20, 0.18, 0.15, 1.0), roughness=0.9)
    m_boots = create_mat("MatZBoots", (0.12, 0.08, 0.05, 1.0), roughness=0.9)
    m_star = create_mat("MatRustyStar", (0.65, 0.50, 0.20, 1.0), roughness=0.6, metallic=0.5)
    m_eye = create_mat("MatEyeGlow", (1.0, 0.15, 0.1, 1.0), emission_rgba=(1.0, 0.15, 0.1, 1.0), emission_strength=3.5)

    # Gambe e stivali
    for x in [-0.15, 0.15]:
        bpy.ops.mesh.primitive_cube_add(size=0.18, location=(x, 0, 0.35))
        leg = bpy.context.active_object
        leg.scale = (0.75, 0.75, 2.0)
        assign_mat(leg, m_pants)

        bpy.ops.mesh.primitive_cube_add(size=0.16, location=(x, -0.02, 0.10))
        boot = bpy.context.active_object
        boot.scale = (0.78, 1.1, 0.7)
        assign_mat(boot, m_boots)

    # Torso con camicia stracciata
    bpy.ops.mesh.primitive_cube_add(size=0.38, location=(0, 0, 0.95))
    torso = bpy.context.active_object
    torso.scale = (1.0, 0.6, 1.3)
    assign_mat(torso, m_shirt)

    # Stella da sceriffo arrugginita sul petto
    bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=0.045, depth=0.015, location=(0.09, -0.12, 1.08))
    star = bpy.context.active_object
    star.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(star, m_star)

    # Braccia protese in avanti stile orda
    for x_sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=0.14, location=(x_sign * 0.27, -0.22, 1.05))
        arm = bpy.context.active_object
        arm.scale = (0.8, 2.2, 0.8)
        assign_mat(arm, m_skin)

    # Testa squadrata voxel
    bpy.ops.mesh.primitive_cube_add(size=0.28, location=(0, -0.02, 1.36))
    head = bpy.context.active_object
    assign_mat(head, m_skin)

    # Occhi rossi luminosi
    for eye_x in [-0.07, 0.07]:
        bpy.ops.mesh.primitive_cube_add(size=0.04, location=(eye_x, -0.16, 1.38))
        eye = bpy.context.active_object
        eye.scale = (1.0, 0.3, 0.7)
        assign_mat(eye, m_eye)

    export_obj("zombie_walker.obj")

# ==============================================================================
# 7. ZOMBIE RUNNER (Veloce, Snello e Feroce)
# ==============================================================================
def build_zombie_runner():
    clear_scene()
    m_skin = create_mat("MatPaleSkin", (0.42, 0.48, 0.38, 1.0), roughness=0.7)
    m_rags = create_mat("MatTornRags", (0.15, 0.15, 0.15, 1.0), roughness=0.95)
    m_yellow_eye = create_mat("MatYellowGlow", (1.0, 0.9, 0.1, 1.0), emission_rgba=(1.0, 0.9, 0.1, 1.0), emission_strength=4.0)

    # Postura curva in avanti da scatto
    bpy.ops.mesh.primitive_cube_add(size=0.14, location=(-0.14, -0.08, 0.32))
    leg1 = bpy.context.active_object
    leg1.scale = (0.7, 0.7, 2.2)
    leg1.rotation_euler = (math.radians(-15), 0, 0)
    assign_mat(leg1, m_rags)

    bpy.ops.mesh.primitive_cube_add(size=0.14, location=(0.14, 0.10, 0.32))
    leg2 = bpy.context.active_object
    leg2.scale = (0.7, 0.7, 2.2)
    leg2.rotation_euler = (math.radians(20), 0, 0)
    assign_mat(leg2, m_rags)

    # Torso magro proteso
    bpy.ops.mesh.primitive_cube_add(size=0.30, location=(0, -0.10, 0.88))
    torso = bpy.context.active_object
    torso.scale = (0.9, 0.55, 1.3)
    torso.rotation_euler = (math.radians(25), 0, 0)
    assign_mat(torso, m_rags)

    # Braccia lunghe con artigli protesi
    for x in [-0.23, 0.23]:
        bpy.ops.mesh.primitive_cube_add(size=0.11, location=(x, -0.28, 0.82))
        arm = bpy.context.active_object
        arm.scale = (0.7, 2.8, 0.7)
        arm.rotation_euler = (math.radians(45), 0, 0)
        assign_mat(arm, m_skin)

    # Testa reclinata con occhi gialli famelici
    bpy.ops.mesh.primitive_cube_add(size=0.24, location=(0, -0.24, 1.18))
    head = bpy.context.active_object
    assign_mat(head, m_skin)

    for eye_x in [-0.06, 0.06]:
        bpy.ops.mesh.primitive_cube_add(size=0.035, location=(eye_x, -0.36, 1.20))
        eye = bpy.context.active_object
        assign_mat(eye, m_yellow_eye)

    export_obj("zombie_runner.obj")

# ==============================================================================
# 8. ZOMBIE BRUTE (Minatore Corazzato Massiccio)
# ==============================================================================
def build_zombie_brute():
    clear_scene()
    m_skin = create_mat("MatDarkZSkin", (0.28, 0.40, 0.28, 1.0), roughness=0.85)
    m_iron = create_mat("MatRustedIron", (0.20, 0.20, 0.22, 1.0), roughness=0.45, metallic=0.85)
    m_leather = create_mat("MatHeavyLeather", (0.22, 0.14, 0.08, 1.0), roughness=0.8)
    m_eye = create_mat("MatPurpleGlow", (0.8, 0.1, 0.9, 1.0), emission_rgba=(0.8, 0.1, 0.9, 1.0), emission_strength=4.5)

    # Gambe massicce
    for x in [-0.22, 0.22]:
        bpy.ops.mesh.primitive_cube_add(size=0.26, location=(x, 0, 0.40))
        leg = bpy.context.active_object
        leg.scale = (0.9, 0.9, 1.8)
        assign_mat(leg, m_leather)

    # Torso colossale corazzato
    bpy.ops.mesh.primitive_cube_add(size=0.58, location=(0, 0, 1.15))
    torso = bpy.context.active_object
    torso.scale = (1.2, 0.85, 1.2)
    assign_mat(torso, m_leather)

    # Corazza a piastre in ferro sul petto
    bpy.ops.mesh.primitive_cube_add(size=0.48, location=(0, -0.24, 1.18))
    plate = bpy.context.active_object
    plate.scale = (1.05, 0.12, 0.85)
    assign_mat(plate, m_iron)

    # Braccia titaniche con paramani in ferro
    for x_s in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=0.22, location=(x_s * 0.44, -0.15, 1.10))
        arm = bpy.context.active_object
        arm.scale = (1.0, 1.6, 1.0)
        assign_mat(arm, m_skin)

        bpy.ops.mesh.primitive_cube_add(size=0.24, location=(x_s * 0.44, -0.28, 0.95))
        gauntlet = bpy.context.active_object
        gauntlet.scale = (1.05, 0.7, 1.05)
        assign_mat(gauntlet, m_iron)

    # Elmetto da minatore pesante con visiera
    bpy.ops.mesh.primitive_cube_add(size=0.34, location=(0, 0, 1.60))
    head = bpy.context.active_object
    assign_mat(head, m_skin)

    bpy.ops.mesh.primitive_cube_add(size=0.38, location=(0, 0, 1.68))
    helmet = bpy.context.active_object
    helmet.scale = (1.05, 1.05, 0.6)
    assign_mat(helmet, m_iron)

    # Occhi viola minacciosi
    for eye_x in [-0.08, 0.08]:
        bpy.ops.mesh.primitive_cube_add(size=0.05, location=(eye_x, -0.17, 1.60))
        eye = bpy.context.active_object
        assign_mat(eye, m_eye)

    export_obj("zombie_brute.obj")

# ==============================================================================
# 9. SALOON (Iconico Saloon del Far West a 2 Piani)
# ==============================================================================
def build_saloon():
    clear_scene()
    m_wood = create_mat("MatSaloonWood", (0.38, 0.24, 0.14, 1.0), roughness=0.75)
    m_dark = create_mat("MatDarkTimber", (0.22, 0.14, 0.08, 1.0), roughness=0.85)
    m_sign = create_mat("MatSaloonSign", (0.80, 0.70, 0.40, 1.0), roughness=0.5)
    m_glass = create_mat("MatWindowGlass", (0.2, 0.3, 0.4, 0.7), roughness=0.2)

    # Corpo principale a due piani (Larghezza 8m, Profondità 9m, Altezza 6m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.0))
    body = bpy.context.active_object
    body.scale = (8.0, 9.0, 6.0)
    assign_mat(body, m_wood)

    # Facciata rialzata Far West (False Front)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 4.5, 6.8))
    front = bpy.context.active_object
    front.scale = (8.4, 0.4, 2.0)
    assign_mat(front, m_dark)

    # Insegna "SALOON" grande
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 4.75, 6.8))
    sign = bpy.context.active_object
    sign.scale = (4.5, 0.15, 1.1)
    assign_mat(sign, m_sign)

    # Portico frontale con colonne di sostegno
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 6.0, 3.2))
    porch_roof = bpy.context.active_object
    porch_roof.scale = (8.2, 3.0, 0.25)
    assign_mat(porch_roof, m_dark)

    for x_col in [-3.8, -1.3, 1.3, 3.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x_col, 7.3, 1.6))
        col = bpy.context.active_object
        col.scale = (0.25, 0.25, 3.2)
        assign_mat(col, m_dark)

    # Balconata secondo piano
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 7.3, 3.7))
    balcony_rail = bpy.context.active_object
    balcony_rail.scale = (8.0, 0.1, 0.8)
    assign_mat(balcony_rail, m_dark)

    # Porte a battente (Batwing doors) al centro del portico
    for x_door in [-0.5, 0.5]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x_door, 4.55, 1.3))
        door = bpy.context.active_object
        door.scale = (0.8, 0.1, 1.4)
        assign_mat(door, m_dark)

    export_obj("saloon.obj")

# ==============================================================================
# 10. SHERIFF OFFICE (Ufficio Sceriffo con Prigione)
# ==============================================================================
def build_sheriff_office():
    clear_scene()
    m_wood = create_mat("MatSheriffPlanks", (0.35, 0.22, 0.12, 1.0), roughness=0.8)
    m_dark = create_mat("MatSheriffTimber", (0.20, 0.12, 0.06, 1.0), roughness=0.9)
    m_star = create_mat("MatGoldSheriffStar", (0.90, 0.75, 0.20, 1.0), roughness=0.3, metallic=0.7)
    m_bars = create_mat("MatIronBars", (0.12, 0.13, 0.15, 1.0), roughness=0.3, metallic=0.9)

    # Edificio principale (6.5m x 7m x 4.2m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.1))
    main = bpy.context.active_object
    main.scale = (6.5, 7.0, 4.2)
    assign_mat(main, m_wood)

    # Portale sopraelevato con stella dello sceriffo
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 3.55, 4.6))
    gable = bpy.context.active_object
    gable.scale = (6.7, 0.3, 1.2)
    assign_mat(gable, m_dark)

    bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=0.45, depth=0.1, location=(0, 3.75, 4.6))
    star = bpy.context.active_object
    star.rotation_euler = (math.radians(90), 0, 0)
    assign_mat(star, m_star)

    # Finestra della prigione con sbarre di ferro
    for x_b in [-2.2, -2.0, -1.8, -1.6]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.03, depth=1.2, location=(x_b, 3.55, 2.0))
        bar = bpy.context.active_object
        assign_mat(bar, m_bars)

    # Tettoia d'ingresso e palo per cavalli
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 4.6, 2.8))
    awning = bpy.context.active_object
    awning.scale = (6.8, 2.2, 0.18)
    assign_mat(awning, m_dark)

    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.06, depth=3.0, location=(0, 5.2, 0.85))
    hitch = bpy.context.active_object
    hitch.rotation_euler = (0, math.radians(90), 0)
    assign_mat(hitch, m_dark)

    export_obj("sheriff_office.obj")

# ==============================================================================
# 11. GRAVEYARD (Cimitero Abbandonato con Tombe e Cripta)
# ==============================================================================
def build_graveyard():
    clear_scene()
    m_stone = create_mat("MatOldStone", (0.35, 0.36, 0.38, 1.0), roughness=0.9)
    m_iron = create_mat("MatWroughtIron", (0.10, 0.10, 0.12, 1.0), roughness=0.4, metallic=0.8)
    m_earth = create_mat("MatMound", (0.20, 0.14, 0.08, 1.0), roughness=0.95)

    # Tumulo di terra recente
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.15))
    mound = bpy.context.active_object
    mound.scale = (1.2, 2.2, 0.3)
    assign_mat(mound, m_earth)

    # Lapide tombale ad arco
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 1.0, 0.65))
    headstone = bpy.context.active_object
    headstone.scale = (0.7, 0.18, 1.1)
    assign_mat(headstone, m_stone)

    # Croce gotica spezzata a fianco
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.5, 0.2, 0.75))
    cross_v = bpy.context.active_object
    cross_v.scale = (0.14, 0.14, 1.5)
    cross_v.rotation_euler = (0, 0, math.radians(-12))
    assign_mat(cross_v, m_stone)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.5, 0.2, 1.15))
    cross_h = bpy.context.active_object
    cross_h.scale = (0.75, 0.14, 0.14)
    cross_h.rotation_euler = (0, 0, math.radians(-12))
    assign_mat(cross_h, m_stone)

    # Recinzione ferro battuto spettrale
    for x in [-1.4, -0.7, 0, 0.7, 1.4]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.025, depth=1.0, location=(x, -1.3, 0.5))
        picket = bpy.context.active_object
        assign_mat(picket, m_iron)

    export_obj("graveyard_tomb.obj")

# ==============================================================================
# 12. MINE ENTRANCE (Miniera d'Oro con Carrello)
# ==============================================================================
def build_mine():
    clear_scene()
    m_rock = create_mat("MatDarkRock", (0.18, 0.17, 0.19, 1.0), roughness=0.9)
    m_beam = create_mat("MatMineBeam", (0.24, 0.14, 0.07, 1.0), roughness=0.85)
    m_rail = create_mat("MatIronRail", (0.15, 0.16, 0.18, 1.0), roughness=0.3, metallic=0.9)
    m_gold = create_mat("MatGoldNuggets", (0.90, 0.75, 0.15, 1.0), roughness=0.25, metallic=0.75, emission_rgba=(0.9, 0.75, 0.15, 1.0), emission_strength=1.5)

    # Roccia scavata della montagna (Arco montano)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.5))
    mountain = bpy.context.active_object
    mountain.scale = (7.5, 4.0, 7.0)
    assign_mat(mountain, m_rock)

    # Portale in travi di legno pesante
    for x in [-1.8, 1.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 2.1, 2.0))
        post = bpy.context.active_object
        post.scale = (0.45, 0.45, 4.0)
        assign_mat(post, m_beam)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 2.1, 4.1))
    header = bpy.context.active_object
    header.scale = (4.4, 0.48, 0.45)
    assign_mat(header, m_beam)

    # Binari ferroviari
    for x_r in [-0.55, 0.55]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x_r, 3.8, 0.08))
        rail = bpy.context.active_object
        rail.scale = (0.08, 4.5, 0.12)
        assign_mat(rail, m_rail)

    # Carrello minerario con oro
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 3.5, 0.65))
    cart = bpy.context.active_object
    cart.scale = (1.2, 1.6, 0.8)
    assign_mat(cart, m_beam)

    # Pepite d'oro all'interno del carrello
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 3.5, 0.95))
    nuggets = bpy.context.active_object
    nuggets.scale = (0.9, 1.3, 0.3)
    assign_mat(nuggets, m_gold)

    export_obj("mine_entrance.obj")

# ==============================================================================
# 13. GRASS CLUMP (Erba Volumetrica Realistica 3D)
# ==============================================================================
def build_grass():
    clear_scene()
    m_grass1 = create_mat("MatGrassLush", (0.16, 0.42, 0.12, 1.0), roughness=0.7)
    m_grass2 = create_mat("MatGrassOlive", (0.28, 0.48, 0.16, 1.0), roughness=0.65)

    # Ciuffo a fili d'erba multipli intrecciati (Crossed Quad Voxel)
    for rot, mat, h in [(0, m_grass1, 0.75), (45, m_grass2, 0.65), (90, m_grass1, 0.8), (135, m_grass2, 0.7)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, h * 0.5))
        blade = bpy.context.active_object
        blade.scale = (0.7, 0.04, h)
        blade.rotation_euler = (0, 0, math.radians(rot))
        assign_mat(blade, mat)

    export_obj("grass_clump.obj")

# ==============================================================================
# 14. FENCE SEGMENT (Staccionata del Far West)
# ==============================================================================
def build_fence():
    clear_scene()
    m_wood = create_mat("MatFenceTimber", (0.32, 0.20, 0.11, 1.0), roughness=0.85)

    # Pali verticali
    for x in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 0.65))
        post = bpy.context.active_object
        post.scale = (0.16, 0.16, 1.3)
        assign_mat(post, m_wood)

    # Assi orizzontali
    for z in [0.45, 0.95]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, z))
        rail = bpy.context.active_object
        rail.scale = (3.2, 0.08, 0.15)
        assign_mat(rail, m_wood)

    export_obj("fence_segment.obj")

# ==============================================================================
# 15. PINE TREE (Pino Voxel Dettagliato a 4 Livelli)
# ==============================================================================
def build_pine_tree():
    clear_scene()
    m_bark = create_mat("MatPineBark", (0.22, 0.14, 0.07, 1.0), roughness=0.85)
    m_foliage = create_mat("MatPineNeedles", (0.08, 0.24, 0.10, 1.0), roughness=0.7)

    # Tronco
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.25, depth=4.5, location=(0, 0, 2.25))
    trunk = bpy.context.active_object
    assign_mat(trunk, m_bark)

    # 4 Livelli piramidali di chioma
    levels = [(2.2, 2.2, 1.4), (3.3, 1.7, 1.3), (4.3, 1.2, 1.2), (5.2, 0.7, 1.0)]
    for z, rad, h in levels:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=rad, depth=h, location=(0, 0, z))
        tier = bpy.context.active_object
        assign_mat(tier, m_foliage)

    export_obj("pine_tree.obj")

# ==============================================================================
# 16. ROCK (Roccia Angolare PBR)
# ==============================================================================
def build_rock():
    clear_scene()
    m_rock = create_mat("MatRockGrey", (0.32, 0.30, 0.33, 1.0), roughness=0.85)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=(0, 0, 0.5))
    rock = bpy.context.active_object
    rock.scale = (1.4, 1.0, 0.75)
    assign_mat(rock, m_rock)

    export_obj("rock.obj")

# ==============================================================================
# 17. REINFORCED CHEST (Baule del Tesoro con Cerniere)
# ==============================================================================
def build_chest():
    # Base
    clear_scene()
    m_wood = create_mat("MatChestOak", (0.30, 0.16, 0.08, 1.0), roughness=0.75)
    m_iron = create_mat("MatChestIron", (0.15, 0.16, 0.18, 1.0), roughness=0.35, metallic=0.85)
    m_brass = create_mat("MatChestLock", (0.85, 0.70, 0.20, 1.0), roughness=0.3, metallic=0.75)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.22))
    base = bpy.context.active_object
    base.scale = (0.9, 0.6, 0.44)
    assign_mat(base, m_wood)

    # Bandelle di rinforzo in ferro
    for x in [-0.38, 0.38]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 0.22))
        strap = bpy.context.active_object
        strap.scale = (0.06, 0.62, 0.46)
        assign_mat(strap, m_iron)

    # Serratura
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.31, 0.28))
    lock = bpy.context.active_object
    lock.scale = (0.10, 0.03, 0.12)
    assign_mat(lock, m_brass)

    export_obj("chest_base.obj")

    # Coperchio
    clear_scene()
    m_wood_lid = create_mat("MatChestOakLid", (0.30, 0.16, 0.08, 1.0), roughness=0.75)
    m_iron_lid = create_mat("MatChestIronLid", (0.15, 0.16, 0.18, 1.0), roughness=0.35, metallic=0.85)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.31, depth=0.92, location=(0, 0, 0))
    lid = bpy.context.active_object
    lid.rotation_euler = (0, math.radians(90), 0)
    lid.scale = (1.0, 0.98, 1.0)
    assign_mat(lid, m_wood_lid)

    for x in [-0.38, 0.38]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.32, depth=0.06, location=(x, 0, 0))
        strap = bpy.context.active_object
        strap.rotation_euler = (0, math.radians(90), 0)
        assign_mat(strap, m_iron_lid)

    export_obj("chest_lid.obj")

if __name__ == "__main__":
    print("Inizio generazione asset HD per SheriffGame...")
    build_revolver()
    build_shotgun()
    build_rifle()
    build_sniper()
    build_dynamite()
    build_zombie_walker()
    build_zombie_runner()
    build_zombie_brute()
    build_saloon()
    build_sheriff_office()
    build_graveyard()
    build_mine()
    build_grass()
    build_fence()
    build_pine_tree()
    build_rock()
    build_chest()
    print("Tutti gli asset sono stati generati con successo in:", OUTPUT_DIR)
