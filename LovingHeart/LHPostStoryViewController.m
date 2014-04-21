//
//  LHPostStoryViewController.m
//  LovingHeart
//
//  Created by Edward Chiang on 2014/3/26.
//  Copyright (c) 2014年 LovineHeart. All rights reserved.
//

#import "LHPostStoryViewController.h"
#import <BlocksKit/UITextField+BlocksKit.h>
#import <SVProgressHUD.h>

@interface LHPostStoryViewController ()

@property (nonatomic, strong) LHStory *storyObject;

@end

@implementation LHPostStoryViewController {
  id _keyboardWillShowNotifyObserver;
  id _keyboardHideNotifyObserver;
  CLLocationManager *locationmanager;
  CLGeocoder *geocoder;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)awakeFromNib {
  self.storyImageView.clipsToBounds = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self.cancelButtonItem setTarget:self];
  [self.cancelButtonItem setAction:@selector(cancelPress:)];
  
  [self awakeFromNib];
  
  _doneButtonItem.enabled = NO;
  
  _storyObject = [[LHStory alloc] init];
  
  [self.userInputTextView setDelegate:self];
  
  locationmanager = [[CLLocationManager alloc] init];
  
  geocoder = [[CLGeocoder alloc] init];
  
  [self.locationButtonItem setTarget:self];
  [self.locationButtonItem setAction:@selector(getCurrentLocation:)];
  
  [self performSelector:@selector(getCurrentLocation:) withObject:nil];
  
  [self.cameraButtonItem setTarget:self];
  [self.cameraButtonItem setAction:@selector(openCameraPressed:)];
  
  // Load idea
  if (self.ideaObject) {
    
    NSLog(@"Load from idea :%@", self.ideaObject.Name);
    [_storyObject setIdeaPointer:self.ideaObject];
    
    [self.ideaNameLabel setText:self.ideaObject.Name];
    
    if (!_storyObject.graphicPointer && self.ideaObject.graphicPointer) {
      [_storyObject setGraphicPointer:self.ideaObject.graphicPointer];
      
      PFFile* file = (PFFile*)self.ideaObject.graphicPointer.imageFile;
      __block UIImageView *__storyImageView = self.storyImageView;
      [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
          UIImage *image = [UIImage imageWithData:data];
          __storyImageView.image = image;
          [__storyImageView setNeedsDisplay];
        }
      }];
    }
  } else {
    self.ideaNameLabel.hidden = YES;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  _keyboardWillShowNotifyObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    NSDictionary* userInfo = [note userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];

      [UIView beginAnimations:nil context:nil];
      [UIView setAnimationDuration:animationDuration];
      [UIView setAnimationCurve:animationCurve];
      
      [self.view setFrame:CGRectMake(self.view.left, self.view.top, self.view.frame.size.width, screenRect.size.height  - keyboardFrame.size.height)];
      self.userInputTextView.frame = CGRectMake(self.userInputTextView.left, self.userInputTextView.top, self.userInputTextView.width, self.additionalToolbar.top);

    
    [UIView commitAnimations];
  }];
  
  _keyboardHideNotifyObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    NSDictionary* userInfo = [note userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (screenRect.size.height - keyboardFrame.size.height > self.view.height) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [self.view setFrame:CGRectMake(self.view.left, self.view.top, self.view.frame.size.width, self.view.frame.size.height  + keyboardFrame.size.height)];
    [UIView commitAnimations];
    }
  }];
  
  [self.doneButtonItem setTarget:self];
  [self.doneButtonItem setAction:@selector(post:)];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardWillShowNotifyObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHideNotifyObserver];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)openCameraPressed:(id)sender {
  if (([UIImagePickerController isSourceTypeAvailable:
        UIImagePickerControllerSourceTypeCamera]) == NO) {
    return;
  }
  UIImagePickerController *cameraController = [[UIImagePickerController alloc] init];
  cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
  
  cameraController.delegate = self;
  
  [self presentViewController:cameraController animated:YES completion:nil];
      
}

- (void)displayEditorForImage:(UIImage *)imageToEdit {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [AFPhotoEditorController setAPIKey:kAviaryAPIKey secret:kAviarySecret];
  });
  [AFOpenGLManager beginOpenGLLoad];
  
  AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
  [editorController setDelegate:self];
  [self.navigationController presentViewController:editorController animated:YES completion:^{
    
  }];
}

- (void)cancelPress:(id)selector {
  [self.navigationController dismissViewControllerAnimated:YES completion:^{
    // Complete dismiss
  }];
}

- (void)getCurrentLocation:(id)sender {
  locationmanager.delegate = self;
  locationmanager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;

  [self.locationLabel setText:NSLocalizedString(@"Loading", @"Loading")];
  [locationmanager startUpdatingLocation];
}

- (void)post:(id)sender {
  [_storyObject setStoryTeller:[LHUser currentUser]];
  [_storyObject setContent:self.userInputTextView.text];
  [SVProgressHUD showWithStatus:@"Posting" maskType:SVProgressHUDMaskTypeGradient];
  [_storyObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!error) {
      [SVProgressHUD showSuccessWithStatus:@"Done"];
      [self dismissViewControllerAnimated:YES completion:^{
        // Open to that story
      }];
    } else {
      [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
  }];
}

#pragma mark - UITextFieldDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
  if (textView.text != nil && textView.text.length > 0) {
    [textView setText:nil];
  }
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.text != nil && textView.text.length > 0) {
    _doneButtonItem.enabled = YES;
  } else {
    _doneButtonItem.enabled = NO;
  }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
  NSLog(@"locationManager didFailWithError: %@", error.localizedDescription);
  [_locationLabel setText:error.localizedDescription];
}

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations {
  if (locations.count > 0) {
    CLLocation *currentLocation = locations[0];
    
    [_storyObject setGeoPoint:[PFGeoPoint geoPointWithLocation:currentLocation]];
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
      if (placemarks.count > 0) {
        CLPlacemark *placemark = [placemarks lastObject];
        NSString *areaName = [NSString stringWithFormat:@"%@, %@",
        placemark.locality,
        placemark.administrativeArea];
        [_locationLabel setText:areaName];
        [_locationLabel setTextColor:[UIColor grayColor]];
        [_storyObject setAreaName:areaName];
        [_locationButtonItem setTintColor:kColorWithBlue];
      }

    }];
  }
}

#pragma mark - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
  // Handle the result image here// Handle cancellation here
  [editor dismissViewControllerAnimated:YES completion:^{
    
    
    // Upload here
    NSData *imageData = UIImagePNGRepresentation(image);
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    LHGraphicImage *graphicImage = [[LHGraphicImage alloc] init];
    graphicImage.imageType = @"file";
    graphicImage.imageFile = imageFile;
    [SVProgressHUD showWithStatus:@"Uploading Photo"];
    [graphicImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (succeeded) {
        _storyImageView.image = image;
        [SVProgressHUD showSuccessWithStatus:@"Done"];
        _storyObject.graphicPointer = graphicImage;
        
        [_cameraButtonItem setTintColor:kColorWithBlue];
      } else {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
      }
    }];
  }];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
  // Handle cancellation here
  [editor dismissViewControllerAnimated:YES completion:^{
    
  }];
}

#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
  
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage, *editedImage, *imageToSave;
  

    
    editedImage = (UIImage *) [info objectForKey:
                               UIImagePickerControllerEditedImage];
    originalImage = (UIImage *) [info objectForKey:
                                 UIImagePickerControllerOriginalImage];
    
    if (editedImage) {
      imageToSave = editedImage;
    } else {
      imageToSave = originalImage;
    }
    
    // Save the new image (original or edited) to the Camera Roll
    UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
  __block LHPostStoryViewController *__self = self;
  [picker dismissViewControllerAnimated:YES completion:^{
    
      [__self displayEditorForImage:imageToSave];
    
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:^{
    
  }];
}

@end
