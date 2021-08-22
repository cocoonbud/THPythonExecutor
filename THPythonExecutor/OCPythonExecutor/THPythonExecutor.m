//
//  THPythonExecutor.m
//  THPythonExecutor
//
//  Created by Terence Yang on 2021/8/12.
//

#import "THPythonExecutor.h"
#import "Python.h"

@interface THPythonExecutor ()

@property(nonatomic, copy) NSString *moduleName;

@property(nonatomic, copy) NSString *currentClass;

@property(nonatomic, strong) dispatch_queue_t pythonQ;

@property(nonatomic, assign) PyObject *pyInstance;

@property(nonatomic, copy) void(^failBlock)(NSError *error);

@property(nonatomic, copy) void(^successBlock)(id result);

@end

@implementation THPythonExecutor

- (void)dealloc {
    Py_Finalize();
    if (self.pyInstance) {
        Py_DECREF(self.pyInstance);
    }
    self.pythonQ = nil;
}

- (instancetype)initWithModuleName:(NSString * __nonnull)moduleName {
    self = [super init];
    if (self) {
        _moduleName = moduleName;
        
        [self p_setPythonPath];
        [self p_setHomePath];
        Py_Initialize();
    }
    
    return self;
}

#pragma mark - public
- (void)executeWithClass:(NSString *)className
              methodName:(NSString *)methodName
               parameter:(NSDictionary *)parameter
                 success:(void(^)(id result))success
                    fail:(void(^)(NSError *error))fail {
    if (className.length < 1) {
        [self p_handleFailCallbackWithErrorMsg:@"Class name cannot be empty."];
        return;
    }
    
    if (methodName.length < 1) {
        [self p_handleFailCallbackWithErrorMsg:@"Methon name cannot be empty."];
        return;
    }
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *paramterJsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if (error) {
        if (fail) {
            fail(error);
        }
        return;
    }
    self.successBlock = success;
    self.failBlock = fail;
    [self p_starTaskWithClassName:className methodName:methodName paramterJsonStr:paramterJsonStr];
}

#pragma mark - private
- (void)p_setPythonPath {
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"Python_script" ofType:@"bundle"];
    
    NSArray *pythonPathArray = [NSArray arrayWithObjects:resourcePath,
                                [resourcePath stringByAppendingPathComponent:@" "],
                                [resourcePath stringByAppendingPathComponent:@"Python"],
                                nil];

    int setenvRes = setenv("PYTHONPATH", [[pythonPathArray componentsJoinedByString:@":"] UTF8String], 1);
    
    if (setenvRes != 0) {
        NSLog(@"Setenv Python path error");
    }
}

- (void)p_starTaskWithClassName:(NSString *)className
                     methodName:(NSString *)methodName
                paramterJsonStr:(NSString *)paramterJsonStr {
    dispatch_async(self.pythonQ, ^{
        BOOL loadSuccess = [self p_importModuleWithClassName:className];
        
        if (loadSuccess) {
            [self p_performMethod:methodName paramterJsonString:paramterJsonStr];
        }
    });
}

- (BOOL)p_importModuleWithClassName:(NSString *)className {
    if ([self.currentClass isEqualToString:className]) {
        return YES;
    }
    
    self.currentClass = className;
    
    NSString *moudleName = self.moduleName;
    
    const char *fileName = [moudleName UTF8String];
    
    PyObject *pModule = PyImport_ImportModule(fileName);
    if (!pModule) {
        [self p_handleFailCallbackWithErrorMsg:@"Error when importing module."];
        return NO;
    }
    
    PyObject *pyClass = PyObject_GetAttrString(pModule, [className UTF8String]);
    if (!pyClass) {
        [self p_handleFailCallbackWithErrorMsg:@"Error when importing class."];
        return NO;
    }
    
    self.pyInstance = PyInstanceMethod_New(pyClass);
    
    Py_DECREF(pyClass);
    Py_DECREF(pModule);
    if (!self.pyInstance) {
        [self p_handleFailCallbackWithErrorMsg:@"Error when initializing python instance obj."];
        return NO;
    }
    return YES;
}

- (void)p_performMethod:(NSString *)methodName paramterJsonString:(NSString *)paramterStr {
    PyObject *result = PyObject_CallMethod(self.pyInstance, [methodName UTF8String], "(N,s)", [paramterStr UTF8String]);
    
    if (result == NULL) {
        [self p_handleFailCallbackWithErrorMsg:@"The result obtained by calling the python method is NULL."];
        return;
    }
    
    char *cStr = NULL;
    
    PyArg_Parse(result, "s", &cStr);
    Py_DECREF(result);
    
    if (cStr == NULL) {
        [self p_handleFailCallbackWithErrorMsg:@"Return value cannot be parsed after calling Python method."];
        return;
    }
    
    NSError *error = nil;
    
    NSString *resultJsonStr = [NSString stringWithUTF8String:cStr];
    
    NSData *jsonData = [resultJsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    
    if (error) {
        if (self.failBlock) {
            self.failBlock(error);
        }
        return;
    }
    
    if ([resultDic isKindOfClass:[NSNull class]]) {
        [self p_handleFailCallbackWithErrorMsg:@"Return value cannot be parsed after calling Python method."];
        return;
    }
    
    if (self.successBlock) {
        self.successBlock(resultDic);
    }
}

- (void)p_setHomePath {
    NSString *pythonHome = [NSString stringWithFormat:@"%@/Python3.8.bundle/Resources", [[NSBundle mainBundle] resourcePath], nil];
       
    wchar_t *wPythonHome = Py_DecodeLocale([pythonHome UTF8String], NULL);
    
    Py_SetPythonHome(wPythonHome);
}

- (void)p_handleFailCallbackWithErrorMsg:(NSString *)errorMsg {
    if (self.failBlock) {
        NSError *error = [NSError errorWithDomain:errorMsg code:-1001 userInfo:nil];
        
        self.failBlock(error);
    }
}

#pragma mark - getter
- (dispatch_queue_t)pythonQ {
    if (!_pythonQ) {
        _pythonQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return _pythonQ;
}

@end
