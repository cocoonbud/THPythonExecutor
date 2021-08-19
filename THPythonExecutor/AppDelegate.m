//
//  AppDelegate.m
//  THPythonExecutor
//
//  Created by Terence Yang on 2021/8/12.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ViewController *controller = [[ViewController alloc]init];
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:controller];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
