//
//  ViewController.swift
//  PokeFinder
//
//  Created by George Kapoya on 2017/01/11.
//  Copyright © 2017 immedia. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import GeoFire
import MapKit

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {

	@IBOutlet weak var mapView: MKMapView!
	var mapHasCentredOnce = false
	var geoFire:GeoFire!
	var geoFireRef: FIRDatabaseReference!
	let locationManager = CLLocationManager()
	override func viewDidLoad() {
		super.viewDidLoad()

        mapView.delegate = self
		mapView.userTrackingMode  = MKUserTrackingMode.follow

	    geoFireRef = FIRDatabase.database().reference()
		geoFire  = GeoFire(firebaseRef: geoFireRef)

	}



	func locationAuthStatus()  {
		if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
			mapView.showsUserLocation = true
		}else{
			locationManager.requestWhenInUseAuthorization()
		}

	}


	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse {
			mapView.showsUserLocation  = true
		}
	}


	func centerMapOnLocation(location: CLLocation)  {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
		mapView.setRegion(coordinateRegion, animated: true)
	}

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		let annoIdentifier = "Pokemon"
		var annotationView: MKAnnotationView?
		if annotation.isKind(of: MKUserLocation.self) {
			annotationView  = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
			annotationView?.image  = #imageLiteral(resourceName: "ash")
		}else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
			annotationView = deqAnno
			annotationView?.annotation = annotation
		}else {
			  let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
			av.rightCalloutAccessoryView  = UIButton(type: .detailDisclosure)
			annotationView = av
		}


		if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
			annotationView.image  = UIImage(named: "\(anno.pokemonNumber)")
			let button = UIButton()
			button.frame  = CGRect(x: 0, y: 0, width: 30, height: 30)
			button.setImage(UIImage(named: "map"), for: .normal)
			annotationView.rightCalloutAccessoryView  = button
		}


		
	    return annotationView
	}

	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		if let loc = userLocation.location {
			if mapHasCentredOnce {
                centerMapOnLocation(location: loc)
				mapView.isZoomEnabled = true
				mapHasCentredOnce = true
			}
		}
	}


	func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
		let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
		showSightingsOnMap(location: loc)

	}


	func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int )  { 
        geoFire.setLocation(location, forKey: "\(pokeId)")

	}

	func showSightingsOnMap(location: CLLocation)  {
		let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
		_ = circleQuery?.observe(GFEventType.keyExited, with: {(key, location) in
			if let key = key, let location = location {
				let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
				self.mapView.addAnnotation(anno)
			}
		})

	}


	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

		if let anno = view.annotation as? PokeAnnotation {
			let place = MKPlacemark(coordinate: anno.coordinate)
			let destination = MKMapItem(placemark: place)
			destination.name   = "Pokemon Sighting"

			let regionDistance: CLLocationDistance  = 1000
			let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)

			let options = [MKLaunchOptionsMapCenterKey: NSValue (mkCoordinate: regionSpan.center),MKLaunchOptionsMapSpanKey: regionSpan.span , MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
			MKMapItem.openMaps(with: [destination], launchOptions: options)
			

		}

	}
	@IBAction func spotRandomPokemon(_ sender: Any) {
		let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
		let rand = arc4random_uniform(151) + 1
		createSighting(forLocation: loc, withPokemon: Int(rand))


	}

}

