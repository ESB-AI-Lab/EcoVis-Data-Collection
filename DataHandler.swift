////
////  DataHandler.swift
////  EcoVis Data Collection
////
////  Created by Kanishka on 1/20/25.
////
//
//import CoreLocation
//import CoreMotion
//import CoreData
//import UIKit
//import Foundation
//
//class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
//    private let locationManager = CLLocationManager()
//    private let motionManager = CMMotionManager()
//
//    @Published var currentLocation: CLLocation?
//    @Published var roll: Double = 0
//    @Published var pitch: Double = 0
//    @Published var yaw: Double = 0
//
//    private lazy var dataHandler: DataHandler = {
//        return DataHandler.shared
//    }()
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.requestAlwaysAuthorization()
//        // Do not start updating location here, do it in startUpdating() method instead
//    }
//
//    func startUpdating() {
//        locationManager.startUpdatingLocation()
//        if motionManager.isDeviceMotionAvailable {
//            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
//            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
//                if let attitude = motion?.attitude {
//                    self.roll = attitude.roll
//                    self.pitch = attitude.pitch
//                    self.yaw = attitude.yaw
//                }
//            }
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.last {
//            currentLocation = location
//            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Location update failed: \(error)")
//    }
//    
//    func saveImageWithMetadata(image: UIImage, location: CLLocationCoordinate2D) {
//        dataHandler.saveImageAndMetadata(
//            image: image,
//            location: location,
//            roll: roll,
//            pitch: pitch,
//            yaw: yaw
//        )
//    }
//}
//
//
//class MotionManager {
//    private let motionManager = CMMotionManager()
//    
//    init() {
//        if motionManager.isDeviceMotionAvailable {
//            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
//            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
//                if let attitude = motion?.attitude {
//                    let roll = attitude.roll
//                    let pitch = attitude.pitch
//                    let yaw = attitude.yaw
//                    print("Roll: \(roll), Pitch: \(pitch), Yaw: \(yaw)")
//                }
//            }
//        }
//    }
//}
////To create and manage Core Data Stack and persistent container
//class AppDelegate: UIResponder, UIApplicationDelegate {
//    lazy var persistentContainer: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "AvacadoVisionData")
//        container.loadPersistentStores { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        }
//        return container
//    }()
//    //Ensure any unsaved changes are written to the database
//    func saveContext() {
//        let context = persistentContainer.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }
//}
//
////Singleton to simplify data handling with a streamlined API
//class DataHandler {
//    static let shared = DataHandler()
//    private let fileManager = FileManager.default
//    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    
//    private var imageMetadataList: [ImageData] = []
//    
//    private init() {
//        loadExistingMetadata()
//    }
//    
//    struct ImageData: Codable {
//        let imageFilename: String
//        let latitude: Double
//        let longitude: Double
//        let roll: Double
//        let pitch: Double
//        let yaw: Double
//    }
//    
//    private func loadExistingMetadata() {
//        let jsonFilePath = documentsURL.appendingPathComponent("metadata.json")
//        
//        if fileManager.fileExists(atPath: jsonFilePath.path) {
//            do {
//                let jsonData = try Data(contentsOf: jsonFilePath)
//                imageMetadataList = try JSONDecoder().decode([ImageData].self, from: jsonData)
//            } catch {
//                print("Error loading existing JSON: \(error)")
//            }
//        }
//    }
//    
//    func saveImageAndMetadata(image: UIImage, location: CLLocationCoordinate2D, roll: Double, pitch: Double, yaw: Double) {
//        let timestamp = Int(Date().timeIntervalSince1970)
//        let imageFilename = "image_\(timestamp).jpg"
//        let imagePath = documentsURL.appendingPathComponent(imageFilename)
//     
//        if let jpegData = image.jpegData(compressionQuality: 0.8) {
//            do {
//                try jpegData.write(to: imagePath)
//                print("Image saved: \(imagePath)")
//            } catch {
//                print("Error saving image: \(error)")
//                return
//            }
//        }
//
//        let newImageData = ImageData(
//            imageFilename: imageFilename,
//            latitude: location.latitude,
//            longitude: location.longitude,
//            roll: roll,
//            pitch: pitch,
//            yaw: yaw
//        )
//        
//        imageMetadataList.append(newImageData)
//
//        saveMetadataToJSON()
//    }
//    
//    private func saveMetadataToJSON() {
//        let jsonFilePath = documentsURL.appendingPathComponent("metadata.json")
//        
//        do {
//            let updatedJsonData = try JSONEncoder().encode(imageMetadataList)
//            try updatedJsonData.write(to: jsonFilePath)
//            print("Metadata saved: \(jsonFilePath)")
//        } catch {
//            print("Error writing JSON: \(error)")
//        }
//    }
//    
//    
//    func getMetadataList() -> [ImageData] {
//        return imageMetadataList
//    }
//    
//    func uploadDataToServer(serverURL: URL) {
//        var uploadData: [String: Any] = [:]
//        uploadData["metadata"] = imageMetadataList
//        
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: uploadData, options: []) else {
//            print("Error serializing metadata to JSON.")
//            return
//        }
//
//        var request = URLRequest(url: serverURL)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonData
//        
//        let session = URLSession.shared
//        session.dataTask(with: request) { (data, response, error) in
//            if let error = error {
//                print("Error uploading data: \(error.localizedDescription)")
//                return
//            }
//
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                print("Data uploaded successfully!")
//            } else {
//                print("Failed to upload data: \(String(describing: response))")
//            }
//        }.resume()
//    }
//}
//    
//        
//
