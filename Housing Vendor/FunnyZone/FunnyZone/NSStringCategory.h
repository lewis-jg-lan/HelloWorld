//
//  NSStringCategory.h
//  FunnyZone
//
//  Created by Kyle Yu on 11-12-28.
//  Copyright 2011年 PEGATRON. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSStringCategory)

/*
 * Kyle 2012.12.28
 * method     : ContainString:
 * abstract   : judge whether self include in a string
 * 
 */
- (BOOL)ContainString:(NSString *)szStr;

/*
 * Kyle 2012.12.28
 * method     : SubFrom:include:
 * abstract   : self substring from a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubFrom:(NSString *)szStr include:(BOOL) include;

/*
 * Kyle 2012.12.28
 * method     : SubTo:include:
 * abstract   : self substring to a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubTo:(NSString *)szStr include:(BOOL) include;
@end
