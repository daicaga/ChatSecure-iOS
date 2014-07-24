//
//  OTRDatabaseUnlockViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseUnlockViewController.h"
#import "OTRDatabaseManager.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"
#import "Strings.h"

@interface OTRDatabaseUnlockViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *passphraseTextField;
@property (nonatomic, strong) UIButton *unlockButton;
@property (nonatomic, strong) UIButton *forgotPassphraseButton;
@property (nonatomic, strong) NSLayoutConstraint *textFieldCenterXConstraint;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation OTRDatabaseUnlockViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.passphraseTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.passphraseTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.passphraseTextField.secureTextEntry = YES;
    self.passphraseTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passphraseTextField.returnKeyType = UIReturnKeyDone;
    self.passphraseTextField.delegate = self;
    
    [self.view addSubview:self.passphraseTextField];
    
    self.unlockButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.unlockButton setTitle:@"Unlock" forState:UIControlStateNormal];
    self.unlockButton.enabled = NO;
    [self.unlockButton addTarget:self action:@selector(unlockTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.unlockButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.unlockButton];
    
    self.forgotPassphraseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.forgotPassphraseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.forgotPassphraseButton setTitle:@"Forgot Passphrase?" forState:UIControlStateNormal];
    [self.forgotPassphraseButton addTarget:self action:@selector(forgotTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.forgotPassphraseButton];
    
    
    [self setupConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self keyboardDidShow:note];
    }];
    
    [self.passphraseTextField becomeFirstResponder];
}

- (void)setupConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_unlockButton,_passphraseTextField,_forgotPassphraseButton);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_unlockButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_forgotPassphraseButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(100)-[_passphraseTextField]-[_unlockButton]" options:0 metrics:nil views:views]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.forgotPassphraseButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.bottomConstraint];
    
    
    self.textFieldCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.passphraseTextField attribute:NSLayoutAttributeCenterX relatedBy:self.view toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.textFieldCenterXConstraint];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.passphraseTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.unlockButton attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
}

- (void)unlockTapped:(id)sender
{
    if(![self.passphraseTextField.text length]) {
        [self showPasswordError];
        return;
    }
    
    [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:self.passphraseTextField.text remember:NO error:nil];
    if ([[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName]) {
        [[OTRAppDelegate appDelegate] showConversationViewController];
    }
    else {
        [self showPasswordError];
    }
    
}

- (void)showPasswordError
{
    [self shake:self.passphraseTextField number:10 direction:1];
    [UIView animateWithDuration:0.1 animations:^{
        self.passphraseTextField.backgroundColor = [UIColor redColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.1 options:0 animations:^{
            self.passphraseTextField.backgroundColor = [UIColor whiteColor];
        } completion:nil];
    }];
}

- (void)forgotTapped:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Forgot Passphrase" message:@"Because the database contents is encrypted with your passphrase, you've lost access to your data and will need to delete and reinstall ChatSecure to continue. Password managers like 1Password or MiniKeePass can be helpful for generating and storing strong passwords." delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
    [alertView show];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSValue *endFrameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardEndFrame = [self.view convertRect:endFrameValue.CGRectValue fromView:nil];
    
    self.bottomConstraint.constant = keyboardEndFrame.size.height * -1;
    
    [self.view layoutIfNeeded];
}

-(void)shake:(UIView *)view number:(int)shakes direction:(int)direction
{
    if (shakes > 0) {
        self.textFieldCenterXConstraint.constant = 5*direction;
    }
    else {
        self.textFieldCenterXConstraint.constant = 0.0;
    }
    
    
    [UIView animateWithDuration:0.03 animations:^ {
        [self.view layoutIfNeeded];
    }
                     completion:^(BOOL finished)
    {
         if(shakes > 0)
         {
             [self shake:view number:shakes-1 direction:direction *-1];
         }
        
     }];
}

- (void) checkPasswordLength:(NSString *)password {
    if ([password length]) {
        self.unlockButton.enabled = YES;
    } else {
        self.unlockButton.enabled = NO;
    }
}

#pragma - mark UITextFieldDelegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        [self unlockTapped:textField];
        return NO;
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self checkPasswordLength:newString];
    return YES;
}

@end
