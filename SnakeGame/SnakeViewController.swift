//
//  SnakeViewController.swift
//  Streamar
//
//  Created by Ahmed Bekhit on 4/14/18.
//  Copyright © 2018 Ahmed Bekhit. All rights reserved.
//

import UIKit
import SceneKit

import ARVideoKit
import LFLiveKit

class SnakeViewController: UIViewController {
    
    @IBOutlet var frameBuffers: UIImageView!
    @IBOutlet var mainSceneView: SCNView!
    @IBOutlet var playLbl: UILabel!
    
    var gameController: GameController = GameController()

    // Declare a RecordAR object
    var recorder:RecordAR?

    // Declare and Initialize a LFLiveSession object
    var session: LFLiveSession = {
        /*----👇---- LFLiveKit Configuration ----👇----*/
        let audioConfiguration = LFLiveAudioConfiguration.defaultConfiguration(for: LFLiveAudioQuality.high)
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: LFLiveVideoQuality.high2)
        
        // Initialize LFLiveKit session using the audio and video configurations above
        let twitchSession = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration, captureType: LFLiveCaptureTypeMask.captureMaskAudioInputVideo)
        
        // Assign the initalized LFLiveSession to `var session:LFLiveSession`
        return twitchSession!
    }()
    
    // Retrieve user's stream key from UserDefaults. If user's key is nil, return an empty string.
    var userStreamKey:String = {
        if let key = UserDefaults.standard.object(forKey: "userStreamKey_Twitch") as? String {
            return key
        }else{
            return ""
        }
    }()
    // Store `userStreamKey` new value to UserDefaults.
    {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "userStreamKey_Twitch")
        }
    }
    
    
    // Live Stream Control UI
    // Declare and Initialize an alert controller to request the user's stream key.
    var streamKeyAlert: UIAlertController = {
        let requestKeyAlert = UIAlertController(title: "Enter your Stream Key", message: "Please enter your Twitch Stream Key to begin your live stream", preferredStyle: UIAlertControllerStyle.alert)
        
        requestKeyAlert.addTextField { textField in
            textField.placeholder = "Insert Twitch Stream Key"
            textField.isSecureTextEntry = true
        }
        
        let goToTwitch = UIAlertAction(title: "Get Key from Twitch", style: .default) { _ in
            guard let url = URL(string: "https://www.twitch.tv/broadcast/dashboard/streamkey") else {return}
            UIApplication.shared.open(url, options: [:])
        }
        
        requestKeyAlert.addAction(UIAlertAction(title: "Save Stream Key", style: .default))
        requestKeyAlert.addAction(goToTwitch)
        requestKeyAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        return requestKeyAlert
    }()
    
    // Start Live Stream button
    var startLive:UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add Twitch Stream Key", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.backgroundColor = .white
        btn.frame = CGRect(x: 0, y: 0, width: 180, height: 60)
        btn.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height*0.93)
        btn.layer.cornerRadius = btn.bounds.height/2
        btn.tag = 0
        return btn
    }()
    
    // Status Label
    var statusLbl:UILabel = {
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 65))
        lbl.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        lbl.center = CGPoint(x: UIScreen.main.bounds.width/2, y: lbl.bounds.height/2)
        lbl.text = "Preparing Live Stream..."
        lbl.textColor = .yellow
        lbl.textAlignment = .center
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupGameController()
        
        // Initialize ARVideoKit recorder
        recorder = RecordAR(SceneKit: mainSceneView)
        /*----👇---- ARVideoKit Configuration ----👇----*/
        
        // Set the renderer's delegate
        recorder?.renderAR = self
        
        recorder?.requestMicPermission = .manual

        // Configure the renderer to retrieve the rendered buffers and push it a live stream 📺
        recorder?.onlyRenderWhileRecording = false
        
        // Set the LFLiveSession's delegate
        session.delegate = self
        session.preView = self.view
        
        // Add Start Live button to superview and connect to startEndLive(:_) functions
        startLive.addTarget(self, action: #selector(startEndLive(_:)), for: .touchUpInside)
        self.view.addSubview(startLive)
        self.view.addSubview(statusLbl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Prepare ARVideoKit recorder with the new configurations
        recorder?.prepare()
        
        // Check if user stream key is stored. If so, enable Start Live Stream button. Otherwise, enable "Add Twitch Stream Key" button.
        if userStreamKey.count > 8 {
            startLive.setTitle("Start Live Video", for: .normal)
            startLive.setTitleColor(.black, for: .normal)
        }else{
            startLive.setTitle("Add Twitch Stream Key", for: .normal)
            startLive.setTitleColor(.red, for: .normal)
        }
        
    }

    // MARK: - Hide Status Bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Live Stream Functions
    @objc func startEndLive(_ sender: UIButton) {
        // Check if user stream key is stored. If so, enable Start Live Stream button. Otherwise, ask for user's stream key.
        if userStreamKey.count > 8 {
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                sender.setTitle("End Live Video", for: UIControlState())
                
                // Prepare RTMP server address
                let stream = LFLiveStreamInfo()
                stream.url = "\(TwitchRTMPCity.jfk.rawValue)\(userStreamKey)"
                
                // Begin a live stream to the RTMP address above
                self.session.running = true
                self.session.startLive(stream)
                
                // Update current Live stream status UI
                self.statusLbl.alpha = 1
                self.statusLbl.text = "Preparing Live Stream..."
                self.statusLbl.textColor = .yellow

                SwiftSpinner.show("Connecting...")
            }else{
                sender.setTitle("Start Live Video", for: UIControlState())
                // End the live stream
                self.session.running = false
                self.session.stopLive()
                
                // Update current Live stream status UI
                self.statusLbl.alpha = 1
                self.statusLbl.text = "Live Video ended"
                self.statusLbl.textColor = .gray

                SwiftSpinner.show("Ending...")
            }
        }else{
            streamKeyAlert.textFields?.first?.text = ""
            streamKeyAlert.textFields?.first?.delegate = self
            present(streamKeyAlert, animated: true)
        }
    }
    
    @IBAction func playRestart(_ sender: UIButton) {
        if sender.tag == 0 {
            sender.tag = 1
            playLbl.text = "Restart"
            sender.setImage(#imageLiteral(resourceName: "restart_game.png"), for: .normal)
        }
        gameController.reset()
        gameController.startGame()
    }
    
}

extension SnakeViewController: LFLiveSessionDelegate, RenderARDelegate, UITextFieldDelegate {
    // MARK: - UITextField Delegate Method
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        guard let keyField = streamKeyAlert.textFields?.first, let key = keyField.text else { return }
        if reason == .committed && textField == keyField && key.count > 8 {
            userStreamKey = key
            
            // Enable "Start Live Video" button
            startLive.setTitle("Start Live Video", for: .normal)
            startLive.setTitleColor(.black, for: .normal)
        }
    }
    
    // MARK: - RenderAR Delegate Method
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        frameBuffers.image = UIImage(ciImage: CIImage(cvPixelBuffer: buffer))
        if session.running {
            session.pushVideo(buffer)
        }
    }
    
    // MARK: - LFLiveSession Delegate Method
    func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
        print("liveStateDidChange: \(state.rawValue)")
        switch state {
        case LFLiveState.ready:
            statusLbl.alpha = 1
            statusLbl.text = "Ready to start live video"
            statusLbl.textColor = .green
            SwiftSpinner.hide()
            break;
        case LFLiveState.pending:
            statusLbl.alpha = 1
            statusLbl.text = "Getting ready..."
            statusLbl.textColor = .red
            break;
        case LFLiveState.start:
            statusLbl.alpha = 1
            statusLbl.text = "You're LIVE!"
            statusLbl.textColor = .green
            SwiftSpinner.hide()
            break;
        case LFLiveState.error:
            statusLbl.alpha = 1
            statusLbl.text = "An Error Occurred. Try Again."
            statusLbl.textColor = .red
            
            let errorAlert = UIAlertController(title: "Error", message: "An error occurred while connecting to your Twitch Stream. Would you like to edit your Twitch stream key?", preferredStyle: .actionSheet)
            let editKey = UIAlertAction(title: "Edit Stream Key", style: .default) { _ in
                self.present(self.streamKeyAlert, animated: true)
            }
            errorAlert.addAction(editKey)
            errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(errorAlert, animated: true)

            SwiftSpinner.hide()
            break;
        case LFLiveState.stop:
            //ending video animation stops
            statusLbl.alpha = 1
            statusLbl.text = "Ready to start new live video"
            statusLbl.textColor = .green
            SwiftSpinner.hide()
            break;
        default:
            break;
        }
    }
}

// MARK: - Setup Game Controllers
extension SnakeViewController {
    func setupGameController() {
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/main.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        cameraNode.look(at: SCNVector3.init(0, 0, 0))
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 1)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        mainSceneView.scene = scene
        
        gameController.addToNode(rootNode: scene.rootNode)
        
        mainSceneView.showsStatistics = false
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft(_:)))
        swipeLeft.direction = .left
        mainSceneView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))
        swipeRight.direction = .right
        mainSceneView.addGestureRecognizer(swipeRight)
    }
    
    
    @objc func swipeLeft(_ sender: Any) {
        gameController.snake.turnLeft()
    }
    
    @objc func swipeRight(_ sender: Any) {
        gameController.snake.turnRight()
    }
}
