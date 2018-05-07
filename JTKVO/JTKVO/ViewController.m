//
//  ViewController.m
//  JTKVO
//
//  Created by Jeffrey on 2018/4/26.
//  Copyright © 2018年 JeffreyTaiT. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+JTKVO.h"
#import "Person.h"

@interface ViewController ()

@property (nonatomic, strong)Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.person = [[Person alloc] init];
    
    [self.person JT_addObserver:self forKeyPatch:@"name" withBlock:^(id observer, NSString *keyPath, id oldValue, id newValue) {
        NSLog(@"observer = %@\nkeyPath = %@\n\noldValue = %@\nnewValue = %@\n",observer, keyPath,oldValue,newValue);
    }];
    
    self.person.name = @"666";
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    self.person.name = [NSString stringWithFormat:@"%@*",self.person.name];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
