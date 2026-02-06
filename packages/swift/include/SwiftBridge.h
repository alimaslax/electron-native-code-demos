#import <Foundation/Foundation.h>

@interface SwiftBridge : NSObject

+ (NSString *)helloWorld:(NSString *)input;
+ (NSString *)searchApplications:(NSString *)query;
+ (void)launchApplication:(NSString *)id;

+ (void)setTodoAddedCallback:(void (^)(NSString *))callback;
+ (void)setTodoUpdatedCallback:(void (^)(NSString *))callback;
+ (void)setTodoDeletedCallback:(void (^)(NSString *))callback;

@end
