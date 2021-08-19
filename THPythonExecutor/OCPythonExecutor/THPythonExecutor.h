//
//  THPythonExecutor.h
//  THPythonExecutor
//
//  Created by Terence Yang on 2021/8/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface THPythonExecutor : NSObject

- (instancetype)initWithModuleName:(NSString * __nonnull)moduleName;


/// excute python methon
/// @param className python class name
/// @param methodName methon name
/// @param parameter argv
/// @param success success callback
/// @param fail fial callback
- (void)executeWithClass:(NSString *)className
              methodName:(NSString *)methodName
               parameter:(NSDictionary *)parameter
                 success:(void(^)(id result))success
                    fail:(void(^)(NSError *error))fail;

NS_ASSUME_NONNULL_END

@end
