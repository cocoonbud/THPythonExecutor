//
//  ViewController.m
//  THPythonExecutor
//
//  Created by Terence Yang on 2021/8/12.
//

#import "ViewController.h"
#import "THPythonExecutor.h"

@interface ViewController ()

@property(nonatomic, strong) UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.btn];
}

#pragma mark - actions
- (void)btnClicked {
    THPythonExecutor *perfrom = [[THPythonExecutor alloc] initWithModuleName:@"Calculte"];
    
    NSDictionary *params = @{@"age" : @"forever 18"};
    
    [perfrom executeWithClass:@"cal" methodName:@"init" parameter:params success:^(id  _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)result;
                
                [self.btn setTitle:[dict description] forState:UIControlStateNormal];
            }
        });
    } fail:^(NSError * _Nonnull error) {
        NSLog(@"%@", [error localizedDescription]);
    }];
}

#pragma mark - getter
- (UIButton *)btn {
    if (!_btn) {
        _btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
        _btn.center = self.view.center;
        _btn.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.3];
        [_btn setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
        _btn.titleLabel.font = [UIFont systemFontOfSize:20];
        _btn.titleLabel.numberOfLines = 0;
        [_btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}

@end
