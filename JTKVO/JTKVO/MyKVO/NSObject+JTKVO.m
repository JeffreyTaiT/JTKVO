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

@interface JTKVO_info:NSObject

@property (nonatomic, weak)NSObject *observer;

@property (nonatomic, copy)NSString *keyPath;

@property (nonatomic, copy)JTKVOBlock jtBlock;

@end

@implementation JTKVO_info

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
    
    NSLog(@"beforSelf = %@",self);
    
    //1.利用setter方法 判断 keypath是否存在
    SEL setterSeletor = NSSelectorFromString(setterForGetter(keyPath));
    Class superClass = object_getClass(self);
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@:not this setter method",self] userInfo:nil];
    }
    
    //2.动态创建JTKVO
    NSString *superClassName = NSStringFromClass(superClass);
    Class newClass;
    if (![superClassName hasPrefix:kJTKVOPrefix]) {
        newClass = [self creatClassFromSuperName:superClassName];
        object_setClass(self, newClass);//替换类
    }
    
    //3.添加setter方法 此时self--->子类
    NSLog(@"nowSelf = %@",self);
    
    if (![self hasSeletor:setterSeletor]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(newClass, setterSeletor, (IMP)JTKVO_Setter, types);
    }
    
    JTKVO_info *jtInfo = [[JTKVO_info alloc] initWithObserver:observer forKeyPath:keyPath withJTBlock:jtBlock];
    NSMutableArray *observerInfoArray = objc_getAssociatedObject(self, (__bridge const void *_Nonnull)(kJTKVOAssiociateKey));
    
    if (!observerInfoArray) {
        observerInfoArray = [NSMutableArray array];
        
        objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kJTKVOAssiociateKey), observerInfoArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [observerInfoArray addObject:jtInfo];
    
}


- (void)JT_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    
    NSMutableArray *observerInfoArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kJTKVOAssiociateKey));
    JTKVO_info *infoRemoved = nil;
    
    for (JTKVO_info *info in observerInfoArray) {
        if (info.observer == observer && [info.keyPath isEqualToString:keyPath]) {
            infoRemoved = info;
            break;
        }
    }
    
    [observerInfoArray removeObject:infoRemoved];
}

- (Class)creatClassFromSuperName:(NSString *)superName{
    Class superClass = NSClassFromString(superName);
    NSString *newClassName = [kJTKVOPrefix stringByAppendingString:superName];
    Class newClass = NSClassFromString(newClassName);
    if (newClass) {
        return newClass;
    }
    newClass = objc_allocateClassPair(superClass, newClassName.UTF8String, 0);
    
    Method classMethod = class_getClassMethod(superClass, @selector(class));
    const char *types = method_getTypeEncoding(classMethod);
    
    class_addMethod(newClass, @selector(class), (IMP)JTKVO_Class, types);
    
    objc_registerClassPair(newClass);
    
    return newClass;
}

- (BOOL)hasSeletor:(SEL)selector{
    Class observedClass = object_getClass(self);
    unsigned int methodCount = 0;
    
    Method *methodList = class_copyMethodList(observedClass, &methodCount);//获取方法列表
    for (int i = 0; i<methodCount; i++) {
        SEL sel = method_getName(methodList[i]);
        if (selector == sel) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

static void JTKVO_Setter(id self,SEL _cmd,id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    if (!getterName) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@ not instance getter",self] userInfo:nil];
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    

    struct objc_super superClassStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    [self willChangeValueForKey:getterName];

    void (*objc_msgSendSuperJTKVO)(void *,SEL,id) = (void *) objc_msgSendSuper;
    objc_msgSendSuperJTKVO(&superClassStruct,_cmd,newValue);
    
    [self didChangeValueForKey:getterName];
    
    NSMutableArray *observerInfoArray = objc_getAssociatedObject(self, (__bridge const void *_Nonnull)(kJTKVOAssiociateKey));
    
    for (JTKVO_info *info in observerInfoArray) {
        if ([info.keyPath isEqualToString:getterName]) {
            dispatch_async(dispatch_queue_create(0, 0), ^{
                info.jtBlock(self, info.keyPath, oldValue, newValue);
            });
        }
    }
}

static Class JTKVO_Class(id self){
    return class_getSuperclass(object_getClass(self));
}

static NSString * setterForGetter(NSString *getter){
    if (getter.length <= 0) {
        return nil;
    }
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}

static NSString * getterForSetter(NSString *setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    return getter;
}

@end
