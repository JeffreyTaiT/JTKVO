//
//  NSObject+JTKVO.m
//  JTKVO
//
//  Created by Jeffrey on 2018/4/26.
//  Copyright © 2018年 JeffreyTaiT. All rights reserved.
//

#import "NSObject+JTKVO.h"
#import <objc/message.h>

static NSString *const kJTKVOPrefix = @"JTKVO_";
static NSString *const kJTKVOAssiociateKey = @"kJTKVOAssiociateKey";

@interface JTKVO:NSObject

@property (nonatomic, weak)NSObject *observer;

@property (nonatomic, copy)NSString *keyPath;

@property (nonatomic, copy)JTKVOBlock jtBlock;

@end

@implementation JTKVO

- (instancetype)initWithObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath withJTBlock:(JTKVOBlock)jtBlock{
    
    if (self == [super init]) {
        _observer = observer;
        _keyPath = keyPath;
        _jtBlock = jtBlock;
    }
    
    return self;
}

@end

@implementation NSObject (JTKVO)

- (void)JT_addObserver:(NSObject *)observer forKeyPatch:(NSString *)keyPath withBlock:(JTKVOBlock)jtBlock{
//    NSMutableArray *observerInfoArray
    SEL setterSeletor = NSSelectorFromString(setterForGetter(keyPath));
}


- (void)JT_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    
}

static Class JTKVO_Clsaa(id self){
    return class_getSuperclass(object_getClass(self));
}

static NSString * setterForGetter(NSString *getter){
    if (getter.length <= 0) {
        return nil;
    }
    NSString *firstString = [[getter substringFromIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}
@end
