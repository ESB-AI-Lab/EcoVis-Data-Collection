//
//  DataHandler.swift
//  EcoVis Data Collection
//
//  Created by Kanishka on 1/20/25.
//

import CoreLocation
import CoreMotion
import CoreData
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
    @Published var currentLocation: CLLocation?
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    @Published var yaw: Double = 0
    
    private lazy var dataHandler: DataHandler = {
        return DataHandler.shared
    }()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                if let attitude = motion?.attitude {
                    self.roll = attitude.roll
                    self.pitch = attitude.pitch
                    self.yaw = attitude.yaw
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")

            dataHandler.saveLocationData(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude,
                                          roll: roll,
                                          pitch: pitch,
                                          yaw: yaw)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error)")
    }
}

class MotionManager {
    private let motionManager = CMMotionManager()
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                if let attitude = motion?.attitude {
                    let roll = attitude.roll
                    let pitch = attitude.pitch
                    let yaw = attitude.yaw
                    print("Roll: \(roll), Pitch: \(pitch), Yaw: \(yaw)")
                }
            }
        }
    }
}
//To create and manage Core Data Stack and persistent container
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "YourDataModelName")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    //Ensure any unsaved changes are written to the database
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
//Singleton to simplify data handling with a streamlined API
class DataHandler {
    static let shared = DataHandler()
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveLocationData(latitude: Double, longitude: Double, roll: Double, pitch: Double, yaw: Double) {
        let newLocationData = NSEntityDescription.insertNewObject(forEntityName: "LocationData", into: context)
        newLocationData.setValue(latitude, forKey: "latitude")
        newLocationData.setValue(longitude, forKey: "longitude")
        newLocationData.setValue(Date(), forKey: "timestamp")
        newLocationData.setValue(roll, forKey: "roll")
        newLocationData.setValue(pitch, forKey: "pitch")
        newLocationData.setValue(yaw, forKey: "yaw")
        
        do {
            try context.save()
            print("Data saved successfully!")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
}

    
        

