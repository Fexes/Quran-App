import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    connectionOptions.urlContexts.forEach { HomeWidgetBridge.accept($0.url) }
  }

  override func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: contexts)
    contexts.forEach { HomeWidgetBridge.accept($0.url) }
  }
}
