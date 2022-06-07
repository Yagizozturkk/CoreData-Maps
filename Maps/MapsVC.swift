//
//  ViewController.swift
//  Maps
//
//  Created by Yagiz Ozturk on 3.06.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    
    @IBOutlet weak var isimText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapV: MKMapView!
    
    var locManager = CLLocationManager()
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    var selectedName = ""
    var selectedId : UUID?
    
    var annotationTit = ""
    var annotationSubt = ""
    var annotationLat = Double()
    var annotationLong = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapV.delegate = self
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
        let gesturerec = UITapGestureRecognizer(target: self, action: #selector(klavyekapat))
        view.addGestureRecognizer(gesturerec)
        
        let gestureRecog = UILongPressGestureRecognizer(target: self, action: #selector(selectingLocation))
        gestureRecog.minimumPressDuration = 2
        mapV.addGestureRecognizer(gestureRecog)
        
        if selectedName != "" {
            
            if let uuidString = selectedId?.uuidString {
                let appdelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appdelegate.persistentContainer.viewContext
                
                let fetchreq = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
                fetchreq.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchreq.returnsObjectsAsFaults = false
                
                do{
                    let results = try context.fetch(fetchreq)
                    
                    if results.count > 0 {
                        
                        for result in results as! [NSManagedObject] {
                            if let name = result.value(forKey: "name") as? String {
                                annotationTit = name
                                if let comment  = result.value(forKey: "comment") as? String {
                                    annotationSubt = comment
                                    if let latitude = result.value(forKey: "latitude") as? Double{
                                        annotationLat = latitude
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLong = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTit
                                            annotation.subtitle = annotationSubt
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLat, longitude: annotationLong)
                                            annotation.coordinate = coordinate
                                            
                                            mapV.addAnnotation(annotation)
                                            isimText.text = annotationTit
                                            commentText.text = annotationSubt
                                            
                                            locManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapV.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("hata")
                }
            }
        }else {
            
        }
    }
    
    @objc func klavyekapat(){
        view.endEditing(true)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let newId = "myannotation"
        var pinV = mapView.dequeueReusableAnnotationView(withIdentifier: newId)
        
        if pinV == nil {
            pinV = MKPinAnnotationView(annotation: annotation, reuseIdentifier: newId)
            pinV?.canShowCallout = true
            pinV?.tintColor = .cyan
            
            let button = UIButton(type: .detailDisclosure)
            pinV?.rightCalloutAccessoryView = button
        } else {
            pinV?.annotation = annotation
        }
        return pinV
        
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != ""{
            
            let reqLoc = CLLocation(latitude: annotationLat, longitude: annotationLong)
            
            CLGeocoder().reverseGeocodeLocation(reqLoc) { placemark, hata in
                if let placemarks = placemark {
                    
                    if placemarks.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTit
                        
                        let launchOpt = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOpt)
                        
                    }
                }
                
            }
        }
    }
    @objc func selectingLocation(gestureRecog : UILongPressGestureRecognizer) {
        if gestureRecog.state == .began {
            let touchedloc = gestureRecog.location(in: mapV)
            let touchedcoord = mapV.convert(touchedloc, toCoordinateFrom: mapV)
            
            selectedLatitude = touchedcoord.latitude
            selectedLongitude = touchedcoord.longitude
            
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedcoord
            annotation.title = isimText.text
            annotation.subtitle = commentText.text
            mapV.addAnnotation(annotation)
            
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            let region = MKCoordinateRegion(center: location, span: span)
        
            mapV.setRegion(region, animated: true)
        }
    }

    @IBAction func saveLoc(_ sender: Any) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)
        
        newPlace.setValue(isimText.text, forKey: "name")
        newPlace.setValue(commentText.text, forKey: "comment")
        newPlace.setValue(selectedLatitude, forKey: "latitude")
        newPlace.setValue(selectedLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        do{
            try context.save()
            print("kayit edildi")
        }catch{
            print("hata")
        }
        NotificationCenter.default.post(name: NSNotification.Name("Newlocation"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

