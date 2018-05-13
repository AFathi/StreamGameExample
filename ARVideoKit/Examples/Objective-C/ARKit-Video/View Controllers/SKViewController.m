//
//  SKViewController.m
//  ARKit-Video
//
//  Created by Ahmed Bekhit on 1/11/18.
//  Copyright © 2018 Ahmed Fathi Bekhit. All rights reserved.
//

#import "SKViewController.h"
#import "Scene.h"

@interface SKViewController () <ARSKViewDelegate, RecordARDelegate, RenderARDelegate>
{
    RecordAR *recorder;
}
@end

@implementation SKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the view's delegate
    self.SKSceneView.delegate = self;
    
    // Show statistics such as fps and node count
    self.SKSceneView.showsFPS = YES;
    self.SKSceneView.showsNodeCount = YES;
    
    // Load the SKScene from 'Scene.sks'
    Scene *scene = (Scene *)[SKScene nodeWithFileNamed:@"Scene"];

    // Present the scene
    [self.SKSceneView presentScene:scene];

    // Initialize ARVideoKit recorder
    recorder = [[RecordAR alloc] initWithARSpriteKit:self.SKSceneView];
    
    /*----👇---- ARVideoKit Configuration ----👇----*/
    
    // Set the recorder's delegate
    recorder.delegate = self;
    
    // Set the renderer's delegate
    recorder.renderAR = self;
    
    // Configure the renderer to perform additional image & video processing 👁
    recorder.onlyRenderWhileRecording = YES;
    
    // Configure ARKit content mode. Default is .auto -- aspectFill is recommended for iPhone10-only apps
    recorder.contentMode = ARFrameModeAuto;
    
    // Configure RecordAR to store media files in local app directory
    recorder.deleteCacheWhenExported = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    
    // Run the view's session
    [self.SKSceneView.session runWithConfiguration:configuration];
    
    // Prepare the recorder with sessions configuration
    [recorder prepare:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.SKSceneView.session pause];
    
    if(recorder.status == RecordARStatusRecording) {
        [recorder stopAndExport:NULL];
    }
    recorder.onlyRenderWhileRecording = YES;
    
    // Switch off the orientation lock for UIViewControllers with AR Scenes
    [recorder rest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK:- Capture and Record methods
- (IBAction)capture:(UIButton *)sender {
    if (sender.tag == 0) {
        //Photo
        if (recorder.status == RecordARStatusReadyToRecord) {
            UIImage *image = [recorder photo];
            [recorder exportWithImage:NULL UIImage:image :NULL];
        }
    }else if (sender.tag == 1) {
        //Live Photo
        if (recorder.status == RecordARStatusReadyToRecord) {
            [recorder livePhotoWithExport:YES :NULL];
        }
    }else if (sender.tag == 2) {
        //GIF
        if (recorder.status == RecordARStatusReadyToRecord) {
            [recorder gifForDuration:3.0 export:YES :NULL];
        }
    }
}

- (IBAction)record:(UIButton *)sender {
    if (sender.tag == 0) {
        //Record
        if (recorder.status == RecordARStatusReadyToRecord) {
            [sender setTitle:@"Stop" forState: UIControlStateNormal];
            [self.pauseBtn setTitle:@"Pause" forState: UIControlStateNormal];
            self.pauseBtn.enabled = YES;
            [recorder record];
        }else if (recorder.status == RecordARStatusRecording) {
            [sender setTitle:@"Record" forState: UIControlStateNormal];
            [self.pauseBtn setTitle:@"Pause" forState: UIControlStateNormal];
            self.pauseBtn.enabled = NO;
            //URL, PHAuthorizationStatus, Bool
            [recorder stopAndExport:^(NSURL*_Nonnull filePath, PHAuthorizationStatus status, BOOL ready) {
                if (status == PHAuthorizationStatusAuthorized) {
                    NSLog(@"Video Exported Successfully!");
                }
            }];
        }
    }else if (sender.tag == 1) {
        //Record with duration
        if (recorder.status == RecordARStatusReadyToRecord) {
            [sender setTitle:@"Stop" forState: UIControlStateNormal];
            [self.pauseBtn setTitle:@"Pause" forState: UIControlStateNormal];
            self.pauseBtn.enabled = NO;
            self.recordBtn.enabled = NO;
            [recorder recordForDuration:10 :NULL];
        }else if (recorder.status == RecordARStatusRecording) {
            [sender setTitle:@"w/Duration" forState: UIControlStateNormal];
            [self.pauseBtn setTitle:@"Pause" forState: UIControlStateNormal];
            self.pauseBtn.enabled = NO;
            self.recordBtn.enabled = YES;
            [recorder stopAndExport:NULL];
        }
    }else if (sender.tag == 2) {
        //Pause
        if (recorder.status == RecordARStatusPaused) {
            [sender setTitle:@"Pause" forState: UIControlStateNormal];
            [recorder record];
        }else if (recorder.status == RecordARStatusRecording) {
            [sender setTitle:@"Resume" forState: UIControlStateNormal];
            [recorder pause];
        }
    }
}

- (IBAction)goBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// MARK:- ARKit protocol methods
- (SKNode *)view:(ARSKView *)view nodeForAnchor:(ARAnchor *)anchor {
    // Create and configure a node for the anchor added to the view's session.
    SKLabelNode *labelNode = [SKLabelNode labelNodeWithText:[self randoMoji]];
    labelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    return labelNode;
}

-(NSString*)randoMoji {
    NSArray *emojis = @[@"👾", @"🤓", @"🔥", @"😜", @"😇", @"🤣", @"🤗"];
    return emojis[arc4random_uniform((int)emojis.count)];
}
- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

// MARK:- ARVideoKit protocol methods
- (void)recorderWithDidEndRecording:(NSURL * _Nonnull)path with:(BOOL)noError {
    
}

- (void)recorderWithDidFailRecording:(NSError * _Nullable)error and:(NSString * _Nonnull)status {
    
}

- (void)recorderWithWillEnterBackground:(enum RecordARStatus)status {
    
}

- (void)frameWithDidRender:(CVPixelBufferRef _Nonnull)buffer with:(CMTime)time using:(CVPixelBufferRef _Nonnull)rawBuffer {
    
}

@end
