//
//  NSStringCategory.m
//  Batch_Query_From_QCR
//
//  Created by Kyle Yu on 12-11-20.
//  Copyright 2012年 PEGATRON. All rights reserved.
//

#import "NSStringCategory.h"

@implementation NSString (NSStringCategory)
- (NSInteger)subStringLocation:(NSString *) szStr
{
    NSRange range = [self rangeOfString:szStr];
    
    if ((range.location != NSNotFound) && (range.length > 0) && (range.location+range.length<=[self length]))
	{
        return range.location;
    }
    else
    {
        return NSNotFound;
    }
}

/*
 * Kyle 2012.12.28
 * method     : ContainString:
 * abstract   : judge whether self include in a string
 * 
 */
- (BOOL)ContainString:(NSString *)szStr
{
    if ([self subStringLocation:szStr] != NSNotFound) 
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

/*
 * Kyle 2012.12.28
 * method     : SubFrom:include:
 * abstract   : self substring from a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubFrom:(NSString *)szStr include:(BOOL) include
{
    NSInteger iRet = [self subStringLocation:szStr];
    if (NSNotFound != iRet) 
    {
        if (include) 
        {
            return [self substringFromIndex:iRet];
        }
        else
        {
            return [self substringFromIndex:iRet + [szStr length]];
        }
    }
    return self;
}

/*
 * Kyle 2012.12.28
 * method     : SubTo:include:
 * abstract   : self substring to a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubTo:(NSString *)szStr include:(BOOL) include
{
    NSInteger iRet = [self subStringLocation:szStr];
    if (NSNotFound != iRet) 
    {
        if (include) 
        {
            return [self substringToIndex:(iRet + [szStr length])];
        }
        else
        {
            return [self substringToIndex:iRet];
        }
    }
    return self;
}
@end
