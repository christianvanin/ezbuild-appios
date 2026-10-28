import Foundation
import SceneKit
import UIKit

public class ForestScene {
    public let scene: SCNScene
    public var chestLocations: [(position: SCNVector3, id: Int)] = []
    public var pointOfInterests: [(name: String, position: SCNVector3)] = []

    public init() {
        scene = SCNScene()
        setupAtmosphereAndLighting()
        buildTerrainAndRoads()
        placeWesternTown()
        placeGraveyardAndMine()
        placeDenseVegetationAndGrass()
        placeChests()
    }

    private func setupAtmosphereAndLighting() {
        // Cielo notturno del Far West e nebbia atmosferica
        let nightSky = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1.0)
        scene.background.contents = nightSky
        scene.fogColor = nightSky
        scene.fogStartDistance = 8.0
        scene.fogEndDistance = 75.0
        scene.fogDensityExponent = 1.0

        // Luce ambientale lunare notturna
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1.0)
        ambientLight.intensity = 240

        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        // Luce lunare azzurro-argentata (Moonlight) con ombre
        let moonLight = SCNLight()
        moonLight.type = .directional
        moonLight.color = UIColor(red: 0.50, green: 0.60, blue: 0.82, alpha: 1.0)
        moonLight.intensity = 550
        moonLight.castsShadow = true
        moonLight.shadowMode = .deferred
        moonLight.shadowSampleCount = 4

        let moonNode = SCNNode()
        moonNode.light = moonLight
        moonNode.eulerAngles = SCNVector3(math_radians(-50), math_radians(40), 0)
        scene.rootNode.addChildNode(moonNode)
    }

    private func buildTerrainAndRoads() {
        // Terreno principale 160m x 160m
        let floorGeo = SCNFloor()
        floorGeo.reflectivity = 0.01

        let grassMat = SCNMaterial()
        grassMat.lightingModel = .physicallyBased
        grassMat.diffuse.contents = UIColor(red: 0.12, green: 0.18, blue: 0.10, alpha: 1.0)
        grassMat.roughness.contents = 0.95
        grassMat.metalness.contents = 0.0
        floorGeo.materials = [grassMat]

        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.name = "Ground"
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scene.rootNode.addChildNode(floorNode)

        // Sentiero in terra battuta principale da Sud a Nord e incrocio a Est/Ovest
        let dirtMat = SCNMaterial()
        dirtMat.lightingModel = .physicallyBased
        dirtMat.diffuse.contents = UIColor(red: 0.28, green: 0.20, blue: 0.12, alpha: 1.0)
        dirtMat.roughness.contents = 0.9

        let mainRoadGeo = SCNPlane(width: 8.0, height: 140.0)
        mainRoadGeo.materials = [dirtMat]
        let mainRoad = SCNNode(geometry: mainRoadGeo)
        mainRoad.position = SCNVector3(0, 0.02, 0)
        mainRoad.eulerAngles = SCNVector3(math_radians(-90), 0, 0)
        scene.rootNode.addChildNode(mainRoad)

        let crossRoadGeo = SCNPlane(width: 100.0, height: 7.0)
        crossRoadGeo.materials = [dirtMat]
        let crossRoad = SCNNode(geometry: crossRoadGeo)
        crossRoad.position = SCNVector3(0, 0.03, -12.0)
        crossRoad.eulerAngles = SCNVector3(math_radians(-90), 0, 0)
        scene.rootNode.addChildNode(crossRoad)

        // Recinzione perimetrale della mappa a 75 metri dal centro
        let boundarySize: Float = 75.0
        let fenceMat = SCNMaterial()
        fenceMat.diffuse.contents = UIColor(red: 0.24, green: 0.15, blue: 0.08, alpha: 1.0)

        for edge in [(-boundarySize, 0, Float.pi/2), (boundarySize, 0, Float.pi/2), (0, -boundarySize, 0), (0, boundarySize, 0)] {
            let wallBox = SCNBox(width: 150, height: 3.0, length: 0.8, chamferRadius: 0)
            wallBox.materials = [fenceMat]
            let wallNode = SCNNode(geometry: wallBox)
            wallNode.position = SCNVector3(edge.0, 1.5, edge.1)
            wallNode.eulerAngles = SCNVector3(0, edge.2, 0)
            scene.rootNode.addChildNode(wallNode)
        }
    }

    private func placeWesternTown() {
        // SALOON a sinistra della strada (X = -18, Z = -12)
        let saloon = loadModel(named: "saloon")
        saloon.position = SCNVector3(-18, 0, -12)
        saloon.eulerAngles = SCNVector3(0, math_radians(90), 0)
        scene.rootNode.addChildNode(saloon)
        pointOfInterests.append(("Saloon", saloon.position))

        // Lanterna calda ad olio fuori dal Saloon
        attachLantern(to: saloon, localPos: SCNVector3(0, 2.8, 4.8), intensity: 900)

        // UFFICIO DELLO SCERIFFO a destra della strada (X = 18, Z = -12)
        let sheriffOffice = loadModel(named: "sheriff_office")
        sheriffOffice.position = SCNVector3(18, 0, -12)
        sheriffOffice.eulerAngles = SCNVector3(0, math_radians(-90), 0)
        scene.rootNode.addChildNode(sheriffOffice)
        pointOfInterests.append(("Ufficio Sceriffo", sheriffOffice.position))

        attachLantern(to: sheriffOffice, localPos: SCNVector3(0, 2.5, 4.2), intensity: 850)

        // Staccionate lungo la strada cittadina
        for z in stride(from: Float(-35), through: Float(20), by: Float(6.0)) {
            if abs(z + 12.0) < 8.0 { continue } // Varco per gli ingressi degli edifici
            let fenceL = loadModel(named: "fence_segment")
            fenceL.position = SCNVector3(-4.5, 0, z)
            fenceL.eulerAngles = SCNVector3(0, math_radians(90), 0)
            scene.rootNode.addChildNode(fenceL)

            let fenceR = loadModel(named: "fence_segment")
            fenceR.position = SCNVector3(4.5, 0, z)
            fenceR.eulerAngles = SCNVector3(0, math_radians(90), 0)
            scene.rootNode.addChildNode(fenceR)
        }
    }

    private func placeGraveyardAndMine() {
        // CIMITERO ABBANDONATO a Nord-Est (X = 36, Z = -45)
        let graveyard = loadModel(named: "graveyard_tomb")
        graveyard.position = SCNVector3(36, 0, -45)
        graveyard.eulerAngles = SCNVector3(0, math_radians(-30), 0)
        scene.rootNode.addChildNode(graveyard)
        pointOfInterests.append(("Cimitero Maledetto", graveyard.position))

        // Nebbia azzurrina e luce spettrale nel cimitero
        let cryptLight = SCNLight()
        cryptLight.type = .omni
        cryptLight.color = UIColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1.0)
        cryptLight.intensity = 400
        cryptLight.attenuationEndDistance = 14.0
        let cLightNode = SCNNode()
        cLightNode.light = cryptLight
        cLightNode.position = SCNVector3(36, 1.2, -45)
        scene.rootNode.addChildNode(cLightNode)

        // MINIERA D'ORO ABBANDONATA a Nord-Ovest (X = -38, Z = -50)
        let mine = loadModel(named: "mine_entrance")
        mine.position = SCNVector3(-38, 0, -50)
        mine.eulerAngles = SCNVector3(0, math_radians(25), 0)
        scene.rootNode.addChildNode(mine)
        pointOfInterests.append(("Miniera d'Oro", mine.position))

        attachLantern(to: mine, localPos: SCNVector3(0, 3.2, 2.5), intensity: 750)
    }

    private func placeDenseVegetationAndGrass() {
        var rng = PseudoRNG(seed: 12345)

        // 1. Erba Volumetrica 3D Densamente distribuita (oltre 240 ciuffi d'erba 3D)
        for _ in 0..<260 {
            let gx = rng.nextFloat(min: -65, max: 65)
            let gz = rng.nextFloat(min: -65, max: 65)

            // Evita di spawnare in mezzo alla strada battuta o dentro gli edifici principali
            if abs(gx) < 4.5 || (abs(gz + 12.0) < 6.0 && abs(gx) < 25.0) {
                continue
            }

            let grass = loadModel(named: "grass_clump")
            let scale = rng.nextFloat(min: 0.7, max: 1.4)
            grass.scale = SCNVector3(scale, scale * rng.nextFloat(min: 0.8, max: 1.2), scale)
            grass.position = SCNVector3(gx, 0, gz)
            grass.eulerAngles = SCNVector3(0, rng.nextFloat(min: 0, max: Float.pi * 2), 0)
            scene.rootNode.addChildNode(grass)
        }

        // 2. Alberi di Pino Voxel HD (circa 120 pini)
        for _ in 0..<130 {
            let tx = rng.nextFloat(min: -68, max: 68)
            let tz = rng.nextFloat(min: -68, max: 68)

            if abs(tx) < 6.0 || (abs(tz + 12.0) < 12.0 && abs(tx) < 28.0) || (abs(tx - 36.0) < 10.0 && abs(tz + 45.0) < 10.0) || (abs(tx + 38.0) < 12.0 && abs(tz + 50.0) < 12.0) {
                continue
            }

            let tree = loadModel(named: "pine_tree")
            let scale = rng.nextFloat(min: 0.85, max: 1.5)
            tree.scale = SCNVector3(scale, scale, scale)
            tree.position = SCNVector3(tx, 0, tz)
            tree.eulerAngles = SCNVector3(0, rng.nextFloat(min: 0, max: Float.pi * 2), 0)
            scene.rootNode.addChildNode(tree)
        }

        // 3. Rocce PBR (45 rocce)
        for _ in 0..<45 {
            let rx = rng.nextFloat(min: -65, max: 65)
            let rz = rng.nextFloat(min: -65, max: 65)

            if abs(rx) < 5.0 || (abs(rz + 12.0) < 8.0 && abs(rx) < 25.0) {
                continue
            }

            let rock = loadModel(named: "rock")
            let scale = rng.nextFloat(min: 0.8, max: 1.8)
            rock.scale = SCNVector3(scale, scale * 0.7, scale)
            rock.position = SCNVector3(rx, 0, rz)
            rock.eulerAngles = SCNVector3(0, rng.nextFloat(min: 0, max: Float.pi * 2), 0)
            scene.rootNode.addChildNode(rock)
        }
    }

    private func placeChests() {
        let chestCoords: [(x: Float, z: Float, id: Int)] = [
            (-18, -4, 1),   // Saloon (dietro le botti)
            (18, -4, 2),    // Ufficio Sceriffo (nella cella)
            (36, -38, 3),   // Cimitero
            (-38, -42, 4)   // Ingresso Miniera
        ]

        for coord in chestCoords {
            chestLocations.append((SCNVector3(coord.x, 0.35, coord.z), coord.id))
        }
    }

    private func attachLantern(to parent: SCNNode, localPos: SCNVector3, intensity: CGFloat) {
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor(red: 1.0, green: 0.75, blue: 0.35, alpha: 1.0)
        light.intensity = intensity
        light.attenuationStartDistance = 0.5
        light.attenuationEndDistance = 14.0

        let node = SCNNode()
        node.light = light
        node.position = localPos
        parent.addChildNode(node)

        // Effetto fiamma tremolante realistico
        let flickerUp = SCNAction.customAction(duration: 0.15) { n, _ in
            n.light?.intensity = intensity + CGFloat.random(in: -100...120)
        }
        let flickerDown = SCNAction.customAction(duration: 0.18) { n, _ in
            n.light?.intensity = intensity - CGFloat.random(in: -80...100)
        }
        node.runAction(SCNAction.repeatForever(SCNAction.sequence([flickerUp, flickerDown])))
    }

    public func loadModel(named name: String) -> SCNNode {
        if let url = Bundle.main.url(forResource: name, withExtension: "obj") {
            if let objScene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
                let wrapper = SCNNode()
                for child in objScene.rootNode.childNodes {
                    wrapper.addChildNode(child.clone())
                }
                return wrapper
            }
        }
        let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        return SCNNode(geometry: box)
    }
}

private func math_radians(_ deg: Float) -> Float {
    return deg * Float.pi / 180.0
}

private struct PseudoRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func nextFloat(min: Float, max: Float) -> Float {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let val = Float((state >> 32) & 0xFFFFFF) / Float(0xFFFFFF)
        return min + val * (max - min)
    }
}
