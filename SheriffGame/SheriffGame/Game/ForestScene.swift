import Foundation
import SceneKit
import UIKit

class ForestScene {
    let scene: SCNScene
    var cabinNodes: [SCNNode] = []
    var chestLocations: [(position: SCNVector3, cabinIndex: Int)] = []
    var gateNode: SCNNode?

    init() {
        scene = SCNScene()
        setupAtmosphereAndLighting()
        buildTerrain()
        buildPerimeterFence()
        placeCabins()
        placeForestVegetation()
        placeExitGate()
    }

    private func setupAtmosphereAndLighting() {
        // Nebbia atmosferica notturna
        let nightColor = UIColor(red: 0.03, green: 0.05, blue: 0.08, alpha: 1.0)
        scene.background.contents = nightColor
        scene.fogColor = nightColor
        scene.fogStartDistance = 6.0
        scene.fogEndDistance = 55.0
        scene.fogDensityExponent = 1.0

        // Luce ambientale fioca (notte profonda)
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
        ambientLight.intensity = 180

        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        // Luce lunare azzurro-argentata (Moonlight)
        let moonLight = SCNLight()
        moonLight.type = .directional
        moonLight.color = UIColor(red: 0.45, green: 0.55, blue: 0.75, alpha: 1.0)
        moonLight.intensity = 450
        moonLight.castsShadow = true
        moonLight.shadowMode = .deferred
        moonLight.shadowSampleCount = 4

        let moonNode = SCNNode()
        moonNode.light = moonLight
        moonNode.eulerAngles = SCNVector3(math_radians(-55), math_radians(35), 0)
        scene.rootNode.addChildNode(moonNode)
    }

    private func buildTerrain() {
        // Terreno forestale calpestabile 120m x 120m
        let floorGeo = SCNFloor()
        floorGeo.reflectivity = 0.02
        floorGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.10, green: 0.14, blue: 0.09, alpha: 1.0)
        floorGeo.firstMaterial?.roughness.contents = 0.95

        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.name = "Ground"
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scene.rootNode.addChildNode(floorNode)
    }

    private func buildPerimeterFence() {
        // Recinzione perimetrale per delimitare l'area di gioco (-55 a +55)
        let fenceMaterial = SCNMaterial()
        fenceMaterial.diffuse.contents = UIColor(red: 0.25, green: 0.16, blue: 0.09, alpha: 1.0)

        let boundarySize: Float = 55.0
        let postHeight: Float = 3.0

        for edge in [(-boundarySize, 0, Float.pi/2), (boundarySize, 0, Float.pi/2), (0, -boundarySize, 0), (0, boundarySize, 0)] {
            let wallBox = SCNBox(width: 110, height: CGFloat(postHeight), length: 0.8, chamferRadius: 0)
            wallBox.firstMaterial = fenceMaterial

            let wallNode = SCNNode(geometry: wallBox)
            wallNode.position = SCNVector3(edge.0, postHeight * 0.5, edge.1)
            wallNode.eulerAngles = SCNVector3(0, edge.2, 0)
            wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            scene.rootNode.addChildNode(wallNode)
        }
    }

    private func placeCabins() {
        let cabinCoords: [(x: Float, z: Float, rot: Float)] = [
            (-26, -16, 0.2),  // Cabina 1 (Contiene Shotgun)
            (26, -20, -0.3),  // Cabina 2 (Contiene Chiave #1 + Medkit)
            (-18, 22, 1.5)    // Cabina 3 (Contiene Chiave #2 e #3)
        ]

        for (idx, coord) in cabinCoords.enumerated() {
            let cabinNode = loadModelNode(named: "cabin")
            cabinNode.name = "Cabin_\(idx + 1)"
            cabinNode.position = SCNVector3(coord.x, 0, coord.z)
            cabinNode.eulerAngles = SCNVector3(0, coord.rot, 0)

            // Lanterna calda all'interno della cabina
            let lanternLight = SCNLight()
            lanternLight.type = .omni
            lanternLight.color = UIColor(red: 1.0, green: 0.70, blue: 0.30, alpha: 1.0)
            lanternLight.intensity = 800
            lanternLight.attenuationEndDistance = 10.0

            let lanternNode = SCNNode()
            lanternNode.light = lanternLight
            lanternNode.position = SCNVector3(0, 2.2, 0)
            cabinNode.addChildNode(lanternNode)

            scene.rootNode.addChildNode(cabinNode)
            cabinNodes.append(cabinNode)

            // Posizione del baule: all'interno della cabina sul tavolo (y = 0.7, z = 1.9 locale)
            let chestWorldPos = cabinNode.convertPosition(SCNVector3(0, 0.72, 1.9), to: nil)
            chestLocations.append((chestWorldPos, idx + 1))
        }
    }

    private func placeForestVegetation() {
        // Posizionamento procedurale di pini e rocce attorno alle radure
        var rng = PseudoRNG(seed: 42)

        for _ in 0..<110 {
            let x = rng.nextFloat(min: -50, max: 50)
            let z = rng.nextFloat(min: -50, max: 50)

            // Evita spawn dentro o subito vicino alle cabine
            if isNearCabin(x: x, z: z, radius: 8.0) || isNearCenter(x: x, z: z, radius: 6.0) || (abs(x) < 5.0 && z < -40.0) {
                continue
            }

            let treeNode = loadModelNode(named: "pine_tree")
            let scale = rng.nextFloat(min: 0.85, max: 1.4)
            treeNode.scale = SCNVector3(scale, scale, scale)
            treeNode.position = SCNVector3(x, 0, z)
            treeNode.eulerAngles = SCNVector3(0, rng.nextFloat(min: 0, max: Float.pi * 2), 0)
            scene.rootNode.addChildNode(treeNode)
        }

        for _ in 0..<35 {
            let x = rng.nextFloat(min: -48, max: 48)
            let z = rng.nextFloat(min: -48, max: 48)
            if isNearCabin(x: x, z: z, radius: 7.0) || isNearCenter(x: x, z: z, radius: 5.0) {
                continue
            }

            let rockNode = loadModelNode(named: "rock")
            let scale = rng.nextFloat(min: 0.7, max: 1.5)
            rockNode.scale = SCNVector3(scale, scale, scale)
            rockNode.position = SCNVector3(x, 0, z)
            rockNode.eulerAngles = SCNVector3(0, rng.nextFloat(min: 0, max: Float.pi * 2), 0)
            scene.rootNode.addChildNode(rockNode)
        }
    }

    private func placeExitGate() {
        // Cancello di fuga a Nord (Z = -53, X = 0)
        let gate = loadModelNode(named: "gate")
        gate.name = "ExitGate"
        gate.position = SCNVector3(0, 0, -53.5)
        gate.eulerAngles = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(gate)
        self.gateNode = gate
    }

    private func isNearCabin(x: Float, z: Float, radius: Float) -> Bool {
        for cabin in cabinNodes {
            let dx = x - cabin.position.x
            let dz = z - cabin.position.z
            if sqrt(dx*dx + dz*dz) < radius {
                return true
            }
        }
        return false
    }

    private func isNearCenter(x: Float, z: Float, radius: Float) -> Bool {
        return sqrt(x*x + z*z) < radius
    }

    func loadModelNode(named modelName: String) -> SCNNode {
        if let url = Bundle.main.url(forResource: modelName, withExtension: "obj") {
            if let objScene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
                let wrapper = SCNNode()
                for child in objScene.rootNode.childNodes {
                    wrapper.addChildNode(child.clone())
                }
                return wrapper
            }
        }
        // Fallback procedurale di riserva
        let fallbackBox = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        return SCNNode(geometry: fallbackBox)
    }
}

private func math_radians(_ deg: Float) -> Float {
    return deg * Float.pi / 180.0
}

// Generatore pseudo-casuale deterministico leggero
private struct PseudoRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func nextFloat(min: Float, max: Float) -> Float {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let val = Float((state >> 32) & 0xFFFFFF) / Float(0xFFFFFF)
        return min + val * (max - min)
    }
}
