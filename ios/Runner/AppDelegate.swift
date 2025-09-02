import Flutter
import UIKit
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyBs8ZNbgXVMdVNp7pkCukkm3b6GGBRIMBk")

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
