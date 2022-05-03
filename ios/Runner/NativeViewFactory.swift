//
//  NativeViewFactory.swift
//  Runner
//
//

import Foundation
import GoogleInteractiveMediaAds
import GSPlayer
class NativeViewFactory : NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

public class NativeView : NSObject, FlutterPlatformView,fullScreeenDelegate, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    
    deinit{
        stopTimer()
        playerView.pause()
    }
    
    private var _view: UIView
    var kTestAppContentUrl_MP4 = " "


    var settings = UIButton()
   
    var playerView =  VideoPlayerView()
    var controlView =  GSPlayerControlUIView()
    
    var paybackSlider = UISlider()

    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let controller = UIApplication.topViewController()

    var item : AVPlayerItem!

    var message : FlutterBinaryMessenger!
    weak var timer: Timer?
    
    static let kTestAppAdTagUrl =
      "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()

        if let argumentsDictionary = args as? Dictionary<String, Any> {
            self.kTestAppContentUrl_MP4 = argumentsDictionary["videoURL"] as! String
            print("test URL:", kTestAppContentUrl_MP4)
        }
        message = messenger
        
        let flutterChannel = FlutterMethodChannel(name: "bms_video_player",
                                             binaryMessenger: messenger!)
          
        flutterChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: FlutterResult) -> Void in
            switch call.method {
            case "pauseVideo":
                self.playerView.pause(reason: .userInteraction)
                if(self.adsManager.adPlaybackInfo.isPlaying) {
                    self.adsManager.pause()
                }
                return

            default:
                result(FlutterMethodNotImplemented)
            }
            })
         
    
        // iOS views can be created here

        setUpContentPlayer(view: _view)
        setUpAdsLoader()
        createNativeView(view: _view)
        startTimer()
       
        
    }
    
    func startTimer() {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.controlView.isHidden = true
        }
    }

    func stopTimer() {
        timer?.invalidate()
        self.playerView.pause()
    }

    // if appropriate, make sure to stop your timer in `deinit`

    
    
    func fullScreenTap() {
            print("fullScreen tapped!!")
        let flutterChannel = FlutterMethodChannel(name: "bms_video_player",
                                             binaryMessenger: message!)
        flutterChannel.invokeMethod("fullScreen",arguments: 0)
        
        playerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.height, height:UIScreen.main.bounds.size.width )
        controlView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.height, height: UIScreen.main.bounds.size.width)
        

        }
    
    func normalScreenTap() {
            print("normalScreen tapped!!")
        let flutterChannel = FlutterMethodChannel(name: "bms_video_player",
                                             binaryMessenger: message!)
        flutterChannel.invokeMethod("normalScreen",arguments: 0)
        
        playerView.frame = CGRect(x: 0, y: 0, width:UIScreen.main.bounds.size.height, height: 400)
        controlView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.height, height: 400)
        
        }
    
    
    
    
    func setUpContentPlayer(view _view: UIView) {
      // Load AVPlayer with path to our content.
        print("test URL1:", kTestAppContentUrl_MP4)
    
      
      guard let contentURL = URL(string: kTestAppContentUrl_MP4) else {
        print("ERROR: please use a valid URL for the content URL")
        return
      }
        
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: URL(string: kTestAppContentUrl_MP4)!)

        controller.player = player
        
        playerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 400)
        controlView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 400)

        playerView.contentMode = .scaleAspectFill
    
      

        playerView.play(for: contentURL)
    
    
        controlView.delegate = self
        controlView.populate(with: playerView)
        


      // Size, position, and display the AVPlayer.
        _view.addSubview(playerView)
        _view.addSubview(controlView)
        
        playerView.pause(reason: .userInteraction)
        controlView.isHidden = true
        controlView.bringSubviewToFront(_view)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.touchHappen(_:)))
        playerView.addGestureRecognizer(tap)
        playerView.isUserInteractionEnabled = true

       
        

        //_view.layer.addSublayer(playerLayer!)

      // Set up our content playhead and contentComplete callback.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: playerView.player!)

    }
    
    @objc func touchHappen(_ sender: UITapGestureRecognizer) {
        print("touchHappen")
        self.controlView.isHidden = false
    }
    
   

    @objc func applicationDidEnterBackground(_ notification: NSNotification) {
        playerView.pause(reason: .userInteraction)
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
      // Make sure we don't call contentComplete as a result of an ad completing.
     // if (notification.object as! AVPlayerItem) == playerView.playerLayer.player?.currentItem {
    //    adsLoader.contentComplete()
     // }
    }

    func setUpAdsLoader() {
      adsLoader = IMAAdsLoader(settings: nil)
      adsLoader.delegate = self
    }

    func requestAds(view _view: UIView) {
      // Create ad display container for ad rendering.
      let adDisplayContainer = IMAAdDisplayContainer(
        adContainer: _view, viewController: controller, companionSlots: nil)
      // Create an ad request with our ad tag, display container, and optional user context.
      let request = IMAAdsRequest(
        adTagUrl: NativeView.kTestAppAdTagUrl,
        adDisplayContainer: adDisplayContainer,
        contentPlayhead: contentPlayhead,
        userContext: controlView)

      adsLoader.requestAds(with: request)
        
    }
    public func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView){
        _view.backgroundColor = UIColor.black
        
        settings.addTarget(self, action: #selector(touchedSet), for: .touchUpInside)
                settings.setImage(UIImage(named: "play_48px"), for: .normal)
                settings.frame = CGRect(x: 200, y:200 , width: 50, height: 50)
        _view.addSubview(settings)
        _view.bringSubviewToFront(controlView)
        _view.bringSubviewToFront(settings)


    }

    
    @objc func touchedSet(sender: UIButton!) {
           print("You tapped the button")
        
        
        requestAds(view: _view)
           settings.isHidden = true
       }
    
    // MARK: - IMAAdsLoaderDelegate

    public func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
      // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
      adsManager = adsLoadedData.adsManager
      adsManager.delegate = self

      // Create ads rendering settings and tell the SDK to use the in-app browser.
      let adsRenderingSettings = IMAAdsRenderingSettings()
      adsRenderingSettings.linkOpenerPresentingController = controller

      // Initialize the ads manager.
      adsManager.initialize(with: adsRenderingSettings)
    }

    public func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        playerView.resume()
        controlView.isHidden = false

    }

    // MARK: - IMAAdsManagerDelegate

    public func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
      if event.type == IMAAdEventType.LOADED {
        // When the SDK notifies us that ads have been loaded, play them.
        adsManager.start()
      }
        if event.type == IMAAdEventType.RESUME {
        
            settings.addTarget(self, action: #selector(touchedSet), for: .touchUpInside)
                    settings.setImage(UIImage(named: "play_48px"), for: .normal)
                    settings.frame = CGRect(x: 200, y:200 , width: 50, height: 50)
            _view.addSubview(settings)
            }
            
            if event.type == IMAAdEventType.PAUSE {
              
                if(adsManager.adPlaybackInfo.isPlaying) {
                    adsManager.pause()
                }
                settings.addTarget(self, action: #selector(touchedSet), for: .touchUpInside)
                        settings.setImage(UIImage(named: "play_48px"), for: .normal)
                        settings.frame = CGRect(x:200, y:200 , width: 50, height: 50)
                _view.addSubview(settings)
            }
            
            if event.type == IMAAdEventType.TAPPED {
                // You can also add allow the user to tap anywhere on the Ad to resume play
                if(!adsManager.adPlaybackInfo.isPlaying) {
                    adsManager.resume()
                }
            }
                
    }

    public func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
      // Something went wrong with the ads manager after ads were loaded. Log the error and play the
      // content.
      print("AdsManager error: \(error.message ?? "nil")")
        playerView.resume()
        controlView.isHidden = false

    }

    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
      // The SDK is going to play ads, so pause the content.
        playerView.pause(reason: .userInteraction)
        controlView.isHidden = true

    }

    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
      // The SDK is done playing ads (at least for now), so resume the content.
        print("AdsManager resume: \("nil")")
        playerView.resume()
        controlView.isHidden = false

    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

