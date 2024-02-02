#import "VsdkPlugin.h"
#import "AppP2PApiPlugin.h"
#import "AppPlayerPlugin.h"

@implementation VsdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [AppP2PApiPlugin registerWithRegistrar:registrar];
    [AppPlayerPlugin registerWithRegistrar:registrar];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  
}

@end
