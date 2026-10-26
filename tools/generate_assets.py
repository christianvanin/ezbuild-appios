import bpy
import bmesh
import math
import os

OUTPUT_DIR = os.path.abspath(r"SheriffGame\SheriffGame\Models")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, color_rgba, roughness=0.6, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = color_rgba
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    return mat

def assign_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)

def export_active_obj(filename):
    filepath = os.path.join(OUTPUT_DIR, filename)
    # Select all mesh objects
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
# 1. FPS REVOLVER (Braccio sceriffo + Revolver in prima persona)
# ==============================================================================
def build_fps_revolver():
    clear_scene()
    
    mat_sleeve = create_material("MatSleeve", (0.35, 0.20, 0.10, 1.0), roughness=0.8) # Pelle/cuoio marrone
    mat_skin = create_material("MatSkin", (0.85, 0.65, 0.55, 1.0), roughness=0.5)     # Mano
    mat_steel = create_material("MatSteel", (0.15, 0.16, 0.18, 1.0), roughness=0.3, metallic=0.9) # Acciaio brunito
    mat_brass = create_material("MatBrass", (0.80, 0.65, 0.20, 1.0), roughness=0.4, metallic=0.7) # Ottone / Dettagli
    mat_wood = create_material("MatWood", (0.28, 0.15, 0.08, 1.0), roughness=0.7)     # Calcio legno

    # Braccio/Avambraccio destro (entra da destra in basso)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.35, location=(0.28, -0.32, -0.22))
    sleeve = bpy.context.active_object
    sleeve.rotation_euler = (math.radians(25), math.radians(-15), math.radians(-20))
    assign_material(sleeve, mat_sleeve)

    # Mano destra
    bpy.ops.mesh.primitive_cube_add(size=0.07, location=(0.22, -0.22, -0.14))
    hand = bpy.context.active_object
    hand.scale = (0.7, 1.1, 0.9)
    hand.rotation_euler = (math.radians(20), math.radians(-10), math.radians(-15))
    assign_material(hand, mat_skin)

    # Impugnatura Revolver (Grip in legno)
    bpy.ops.mesh.primitive_cube_add(size=0.05, location=(0.20, -0.20, -0.12))
    grip = bpy.context.active_object
    grip.scale = (0.5, 0.8, 1.4)
    grip.rotation_euler = (math.radians(20), math.radians(0), math.radians(0))
    assign_material(grip, mat_wood)

    # Castello/Telaio Revolver (Steel frame)
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0.20, -0.25, -0.07))
    frame = bpy.context.active_object
    frame.scale = (0.45, 1.3, 0.8)
    assign_material(frame, mat_steel)

    # Tamburo (Cylinder a 6 colpi)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.026, depth=0.07, location=(0.20, -0.26, -0.07))
    cylinder = bpy.context.active_object
    cylinder.rotation_euler = (math.radians(90), 0, 0)
    assign_material(cylinder, mat_steel)

    # Canna del Revolver (Lunga, ottagonale)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.016, depth=0.22, location=(0.20, -0.40, -0.065))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    assign_material(barrel, mat_steel)

    # Mirino anteriore (Front Sight)
    bpy.ops.mesh.primitive_cube_add(size=0.01, location=(0.20, -0.50, -0.045))
    sight = bpy.context.active_object
    sight.scale = (0.3, 0.8, 1.0)
    assign_material(sight, mat_brass)

    # Cane del cane (Hammer)
    bpy.ops.mesh.primitive_cube_add(size=0.015, location=(0.20, -0.19, -0.05))
    hammer = bpy.context.active_object
    hammer.scale = (0.4, 0.6, 1.2)
    assign_material(hammer, mat_steel)

    export_active_obj("fps_revolver.obj")

# ==============================================================================
# 2. FPS SHOTGUN (Doppietta a canne mozze / Shotgun pesante)
# ==============================================================================
def build_fps_shotgun():
    clear_scene()
    
    mat_sleeve = create_material("MatSleeve", (0.35, 0.20, 0.10, 1.0), roughness=0.8)
    mat_skin = create_material("MatSkin", (0.85, 0.65, 0.55, 1.0), roughness=0.5)
    mat_darksteel = create_material("MatDarkSteel", (0.12, 0.13, 0.14, 1.0), roughness=0.25, metallic=0.95)
    mat_wood = create_material("MatWoodDark", (0.22, 0.11, 0.05, 1.0), roughness=0.6)

    # Braccio destro impugnatura
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.35, location=(0.26, -0.30, -0.24))
    r_arm = bpy.context.active_object
    r_arm.rotation_euler = (math.radians(20), math.radians(-10), math.radians(-15))
    assign_material(r_arm, mat_sleeve)

    # Mano destra
    bpy.ops.mesh.primitive_cube_add(size=0.07, location=(0.20, -0.22, -0.16))
    r_hand = bpy.context.active_object
    r_hand.scale = (0.7, 1.1, 0.9)
    assign_material(r_hand, mat_skin)

    # Braccio sinistro supporto anteriore (sale da sinistra)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.35, location=(-0.10, -0.38, -0.26))
    l_arm = bpy.context.active_object
    l_arm.rotation_euler = (math.radians(35), math.radians(20), math.radians(30))
    assign_material(l_arm, mat_sleeve)

    # Mano sinistra sotto l'astina
    bpy.ops.mesh.primitive_cube_add(size=0.065, location=(0.04, -0.38, -0.14))
    l_hand = bpy.context.active_object
    l_hand.scale = (1.0, 0.8, 0.8)
    assign_material(l_hand, mat_skin)

    # Calcio in legno massiccio
    bpy.ops.mesh.primitive_cube_add(size=0.07, location=(0.17, -0.16, -0.15))
    stock = bpy.context.active_object
    stock.scale = (0.5, 2.0, 1.2)
    stock.rotation_euler = (math.radians(15), math.radians(-6), 0)
    assign_material(stock, mat_wood)

    # Ricevitore / Bascula in acciaio
    bpy.ops.mesh.primitive_cube_add(size=0.07, location=(0.13, -0.28, -0.11))
    receiver = bpy.context.active_object
    receiver.scale = (0.7, 1.3, 0.8)
    assign_material(receiver, mat_darksteel)

    # Astina paramano in legno
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0.10, -0.40, -0.12))
    forend = bpy.context.active_object
    forend.scale = (0.9, 1.8, 0.7)
    assign_material(forend, mat_wood)

    # Doppia Canna (Canne affiancate calibro 12)
    for offset_x in [-0.022, 0.022]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.019, depth=0.38, location=(0.10 + offset_x, -0.50, -0.095))
        barrel = bpy.context.active_object
        barrel.rotation_euler = (math.radians(90), 0, 0)
        assign_material(barrel, mat_darksteel)

    # Mirino in ottone
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.008, location=(0.10, -0.68, -0.075))
    bead = bpy.context.active_object
    mat_brass = create_material("MatBrassShot", (0.85, 0.70, 0.20, 1.0), roughness=0.3, metallic=0.8)
    assign_material(bead, mat_brass)

    export_active_obj("fps_shotgun.obj")

# ==============================================================================
# 3. ZOMBIE (Nemico non-morto low-poly con braccia protese)
# ==============================================================================
def build_zombie():
    clear_scene()

    mat_skin = create_material("MatZombieSkin", (0.28, 0.44, 0.24, 1.0), roughness=0.8) # Verde putrefatto
    mat_eyes = create_material("MatZombieEyes", (0.75, 0.10, 0.10, 1.0), roughness=0.4) # Occhi rossi incandescenti
    mat_clothes = create_material("MatZombieShirt", (0.20, 0.30, 0.35, 1.0), roughness=0.9) # Camicia lacerata
    mat_pants = create_material("MatZombiePants", (0.12, 0.14, 0.18, 1.0), roughness=0.9)  # Pantaloni scuri
    mat_boots = create_material("MatZombieBoots", (0.08, 0.06, 0.05, 1.0), roughness=0.7)  # Scarponi

    # Testa squadrata (Minecraft-style)
    bpy.ops.mesh.primitive_cube_add(size=0.32, location=(0, 0, 1.62))
    head = bpy.context.active_object
    assign_material(head, mat_skin)

    # Occhi rossi spettrali
    for eye_x in [-0.08, 0.08]:
        bpy.ops.mesh.primitive_cube_add(size=0.05, location=(eye_x, -0.165, 1.64))
        eye = bpy.context.active_object
        eye.scale = (0.9, 0.2, 0.6)
        assign_material(eye, mat_eyes)

    # Bocca spalancata
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0, -0.165, 1.52))
    mouth = bpy.context.active_object
    mouth.scale = (1.2, 0.1, 0.4)
    mat_mouth = create_material("MatMouth", (0.05, 0.02, 0.02, 1.0))
    assign_material(mouth, mat_mouth)

    # Torso
    bpy.ops.mesh.primitive_cube_add(size=0.45, location=(0, 0, 1.15))
    torso = bpy.context.active_object
    torso.scale = (0.9, 0.55, 1.25)
    assign_material(torso, mat_clothes)

    # Braccia protese in avanti stile classico zombie (-Y)
    for arm_x in [-0.28, 0.28]:
        bpy.ops.mesh.primitive_cube_add(size=0.14, location=(arm_x, -0.28, 1.25))
        arm = bpy.context.active_object
        arm.scale = (0.9, 3.2, 0.9)
        assign_material(arm, mat_skin)

    # Gambe
    for leg_x in [-0.11, 0.11]:
        bpy.ops.mesh.primitive_cube_add(size=0.16, location=(leg_x, 0, 0.50))
        leg = bpy.context.active_object
        leg.scale = (0.95, 0.95, 4.2)
        assign_material(leg, mat_pants)
        
        # Scarponi
        bpy.ops.mesh.primitive_cube_add(size=0.17, location=(leg_x, -0.03, 0.10))
        boot = bpy.context.active_object
        boot.scale = (0.98, 1.4, 1.0)
        assign_material(boot, mat_boots)

    export_active_obj("zombie.obj")

# ==============================================================================
# 4. CABINA IN LEGNO CON INTERNI CALPESTABILI (Open doorway)
# ==============================================================================
def build_cabin():
    clear_scene()

    mat_log = create_material("MatLog", (0.35, 0.22, 0.12, 1.0), roughness=0.85)     # Tronchi pareti
    mat_floor = create_material("MatFloor", (0.42, 0.28, 0.16, 1.0), roughness=0.7)  # Pavimento assi
    mat_roof = create_material("MatRoof", (0.22, 0.13, 0.07, 1.0), roughness=0.8)    # Tetto spiovente
    mat_trim = create_material("MatTrim", (0.18, 0.11, 0.06, 1.0), roughness=0.9)    # Travi angolari

    # Pavimento 6m x 6m
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.05))
    floor = bpy.context.active_object
    floor.scale = (6.0, 6.0, 0.1)
    assign_material(floor, mat_floor)

    # Parete Posteriore (+Y)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 2.9, 1.4))
    wall_back = bpy.context.active_object
    wall_back.scale = (6.0, 0.25, 2.6)
    assign_material(wall_back, mat_log)

    # Parete Sinistra (-X)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.9, 0, 1.4))
    wall_left = bpy.context.active_object
    wall_left.scale = (0.25, 6.0, 2.6)
    assign_material(wall_left, mat_log)

    # Parete Destra (+X)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.9, 0, 1.4))
    wall_right = bpy.context.active_object
    wall_right.scale = (0.25, 6.0, 2.6)
    assign_material(wall_right, mat_log)

    # Parete Anteriore (-Y): DIVISA IN DUE CON PORTA APERTA CENTRALE
    # Apertura porta: da x=-0.9 a x=0.9 (larghezza 1.8m, altezza 2.3m)
    # Porzione sinistra facciata: da x=-2.9 a x=-0.9 (larghezza 2.0m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.9, -2.9, 1.4))
    wall_front_l = bpy.context.active_object
    wall_front_l.scale = (2.1, 0.25, 2.6)
    assign_material(wall_front_l, mat_log)

    # Porzione destra facciata: da x=0.9 a x=2.9 (larghezza 2.0m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.9, -2.9, 1.4))
    wall_front_r = bpy.context.active_object
    wall_front_r.scale = (2.1, 0.25, 2.6)
    assign_material(wall_front_r, mat_log)

    # Architrave sopra la porta (tra z=2.3 e z=2.7)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -2.9, 2.5))
    lintel = bpy.context.active_object
    lintel.scale = (1.9, 0.25, 0.4)
    assign_material(lintel, mat_trim)

    # Pilastri angolari verticali
    for px, py in [(-2.95, -2.95), (2.95, -2.95), (-2.95, 2.95), (2.95, 2.95)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, py, 1.4))
        pillar = bpy.context.active_object
        pillar.scale = (0.4, 0.4, 2.7)
        assign_material(pillar, mat_trim)

    # Falde del tetto a spiovente (sinistra e destra)
    # Falda sinistra
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.6, 0, 3.25))
    roof_l = bpy.context.active_object
    roof_l.scale = (3.6, 6.4, 0.15)
    roof_l.rotation_euler = (0, math.radians(28), 0)
    assign_material(roof_l, mat_roof)

    # Falda destra
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.6, 0, 3.25))
    roof_r = bpy.context.active_object
    roof_r.scale = (3.6, 6.4, 0.15)
    roof_r.rotation_euler = (0, math.radians(-28), 0)
    assign_material(roof_r, mat_roof)

    # Tavolo interno rustico (sul retro della cabina)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 2.0, 0.45))
    table = bpy.context.active_object
    table.scale = (1.6, 1.0, 0.7)
    assign_material(table, mat_trim)

    export_active_obj("cabin.obj")

# ==============================================================================
# 5. BAULE DEL TESORO (Base e Coperchio separato con pivot di rotazione)
# ==============================================================================
def build_chest_base():
    clear_scene()

    mat_wood = create_material("MatChestWood", (0.40, 0.22, 0.10, 1.0), roughness=0.7)
    mat_iron = create_material("MatChestIron", (0.15, 0.16, 0.18, 1.0), roughness=0.4, metallic=0.85)
    mat_gold = create_material("MatChestGold", (0.85, 0.70, 0.15, 1.0), roughness=0.3, metallic=0.9)

    # BASE DEL BAULE (0.8m x 0.5m x 0.4m)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.20))
    base = bpy.context.active_object
    base.scale = (0.80, 0.50, 0.40)
    assign_material(base, mat_wood)

    # Fasce metalliche angolari
    for bx in [-0.38, 0.38]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, 0, 0.20))
        band = bpy.context.active_object
        band.scale = (0.06, 0.52, 0.41)
        assign_material(band, mat_iron)

    # Serratura dorata centrale
    bpy.ops.mesh.primitive_cube_add(size=0.06, location=(0, -0.26, 0.32))
    lock = bpy.context.active_object
    lock.scale = (1.0, 0.3, 1.4)
    assign_material(lock, mat_gold)

    export_active_obj("chest_base.obj")

def build_chest_lid():
    clear_scene()

    mat_wood = create_material("MatChestLidWood", (0.40, 0.22, 0.10, 1.0), roughness=0.7)
    mat_iron = create_material("MatChestLidIron", (0.15, 0.16, 0.18, 1.0), roughness=0.4, metallic=0.85)
    mat_gold = create_material("MatChestLidGold", (0.85, 0.70, 0.15, 1.0), roughness=0.3, metallic=0.9)

    # Coperchio del baule: centrato sull'asse del cardine
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.25, 0.08))
    lid = bpy.context.active_object
    lid.scale = (0.82, 0.52, 0.16)
    assign_material(lid, mat_wood)

    # Fasce metalliche coperchio
    for bx in [-0.38, 0.38]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, -0.25, 0.09))
        band = bpy.context.active_object
        band.scale = (0.07, 0.53, 0.17)
        assign_material(band, mat_iron)

    # Staffa di chiusura
    bpy.ops.mesh.primitive_cube_add(size=0.05, location=(0, -0.51, 0.04))
    clasp = bpy.context.active_object
    clasp.scale = (0.8, 0.3, 1.2)
    assign_material(clasp, mat_gold)

    export_active_obj("chest_lid.obj")

# ==============================================================================
# 6. PINO DELLA FORESTA (Low-poly Pine Tree)
# ==============================================================================
def build_pine_tree():
    clear_scene()

    mat_trunk = create_material("MatTrunk", (0.30, 0.18, 0.10, 1.0), roughness=0.9)
    mat_leaves = create_material("MatPineLeaves", (0.08, 0.24, 0.12, 1.0), roughness=0.8)

    # Tronco
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.22, depth=2.0, location=(0, 0, 1.0))
    trunk = bpy.context.active_object
    assign_material(trunk, mat_trunk)

    # 3 Livelli di chioma a cono
    levels = [
        (1.8, 2.0, 2.2), # raggio, altezza, z_center
        (1.4, 1.8, 3.4),
        (0.9, 1.5, 4.4)
    ]
    for r, h, z in levels:
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=r, radius2=0.0, depth=h, location=(0, 0, z))
        cone = bpy.context.active_object
        assign_material(cone, mat_leaves)

    export_active_obj("pine_tree.obj")

# ==============================================================================
# 7. ROCCIA DELLA FORESTA (Low-poly Rock)
# ==============================================================================
def build_rock():
    clear_scene()

    mat_rock = create_material("MatRock", (0.28, 0.30, 0.32, 1.0), roughness=0.9)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=(0, 0, 0.6))
    rock = bpy.context.active_object
    rock.scale = (1.4, 1.1, 0.8)
    assign_material(rock, mat_rock)

    export_active_obj("rock.obj")

# ==============================================================================
# 8. CHIAVE D'ORO ANTICA (Key per sbloccare il cancello)
# ==============================================================================
def build_key():
    clear_scene()

    mat_gold = create_material("MatKeyGold", (0.95, 0.78, 0.15, 1.0), roughness=0.25, metallic=0.9)

    # Anello impugnatura
    bpy.ops.mesh.primitive_torus_add(major_radius=0.10, minor_radius=0.025, location=(0, 0, 0.30))
    ring = bpy.context.active_object
    ring.rotation_euler = (math.radians(90), 0, 0)
    assign_material(ring, mat_gold)

    # Stelo
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.02, depth=0.32, location=(0, 0, 0.12))
    stem = bpy.context.active_object
    assign_material(stem, mat_gold)

    # Denti della chiave
    bpy.ops.mesh.primitive_cube_add(size=0.04, location=(0.035, 0, 0.04))
    teeth1 = bpy.context.active_object
    teeth1.scale = (1.2, 0.4, 0.8)
    assign_material(teeth1, mat_gold)

    bpy.ops.mesh.primitive_cube_add(size=0.04, location=(0.035, 0, -0.01))
    teeth2 = bpy.context.active_object
    teeth2.scale = (1.0, 0.4, 0.8)
    assign_material(teeth2, mat_gold)

    export_active_obj("key.obj")

# ==============================================================================
# 9. CANCELLO DI FUGA DELLA FORESTA (Exit Gate)
# ==============================================================================
def build_gate():
    clear_scene()

    mat_stone = create_material("MatGateStone", (0.35, 0.36, 0.38, 1.0), roughness=0.85)
    mat_iron = create_material("MatGateIron", (0.10, 0.10, 0.11, 1.0), roughness=0.3, metallic=0.95)
    mat_sign = create_material("MatGateSign", (0.50, 0.15, 0.10, 1.0), roughness=0.7)

    # Pilastri in pietra
    for px in [-2.2, 2.2]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, 0, 1.8))
        pillar = bpy.context.active_object
        pillar.scale = (0.7, 0.7, 3.6)
        assign_material(pillar, mat_stone)

    # Barre orizzontali del cancello
    for gz in [0.4, 1.5, 2.7]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.03, depth=3.8, location=(0, 0, gz))
        bar_h = bpy.context.active_object
        bar_h.rotation_euler = (0, math.radians(90), 0)
        assign_material(bar_h, mat_iron)

    # Barre verticali con punte a lancia
    for bx in [-1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=2.8, location=(bx, 0, 1.5))
        bar_v = bpy.context.active_object
        assign_material(bar_v, mat_iron)

        # Punta lancia
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.04, radius2=0.0, depth=0.18, location=(bx, 0, 3.0))
        spear = bpy.context.active_object
        assign_material(spear, mat_iron)

    # Cartello di legno sopra il cancello: "EXIT - SAFE ZONE"
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.4))
    sign = bpy.context.active_object
    sign.scale = (2.2, 0.1, 0.5)
    assign_material(sign, mat_sign)

    export_active_obj("gate.obj")

# ==============================================================================
# MAIN RUNNER
# ==============================================================================
if __name__ == "__main__":
    print(">>> Avvio generazione modelli 3D...")
    build_fps_revolver()
    build_fps_shotgun()
    build_zombie()
    build_cabin()
    build_chest_base()
    build_chest_lid()
    build_pine_tree()
    build_rock()
    build_key()
    build_gate()
    print(">>> Tutti gli asset 3D sono stati generati con successo in:", OUTPUT_DIR)
