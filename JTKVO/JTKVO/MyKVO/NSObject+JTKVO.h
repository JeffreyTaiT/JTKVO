//
//  NSObject+JTKVO.h
//  JTKVO
//
//  Created by Jeffrey on 2018/4/26.
//  Copyright © 2018年 JeffreyTaiT. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JTKVOBlock)(id observer,NSString *keyPath,id oldValue,id newValue);

@interface NSObject (JTKVO)

/**
 添加监听注册

 @param observer observer
 @param keyPath keyPath
 @param jtBlock 执行回调
 */
- (void)JT_addObserver:(NSObject *)observer forKeyPatch:(NSString *)keyPath withBlock:(JTKVOBlock)jtBlock;

/**
 移除监听

 @param observer observer
 @param keyPath keyPath
 */
- (void)JT_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end
