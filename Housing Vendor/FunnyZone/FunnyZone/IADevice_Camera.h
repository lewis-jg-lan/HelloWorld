//
//  IADevice_Camera.h
//  FunnyZone
//
//  Created by Winter on 11/28/11.
//  Copyright 2011 PEGATRON. All rights reserved.
//

#import "TestProgress.h"
#import "IADevice_TestingCommands.h"


@interface TestProgress (IADevice_Camera)

//2011-12-10 add by Winter
// Combine a serial of hexadecimal datas without "0x".
// Ex:  0x0 : 0x30 0xF4 0x29 0x9F 0x64  
//      0x8 : 0xB4 0x2 0xA 0x81 0x0 0x0
// After combine: 30F4299F64B4020A810000
// Param:
//      NSString **strSourceData     : Numbers Source Data
//      int   iStart           : The start index in these numbers.
//      int   iLast            : The end index in these numbers.
// Return:
//      Actions result
-(BOOL)combineNVMForQT0:(NSString **)strSourceData startIndex:(int)iStart DeleLastIndex:(int)iLast;

//2011-12-10 add by Winter
// Catch useful strings from strReturnValue, and set memories for "FCMB"/"BCMB"
// Param:
//       NSDictionary    *dicContents        : Settings in script
//       NSMutableString *strReturnValue     : Return value
// Return:
//      Actions result
-(NSNumber*)CATCH_NVM_VALUE:(NSDictionary*)dicContents RETURN_VALUE:(NSMutableString*)strReturnValue;

/* combine  string red, green and blue
 * method     : combineVGAsn: ReturnValue
 * abstract   : get values form dicpare ,and combine the values to a string
 * key        : 
 *            
 */
- (NSNumber *)combineVGAsn:(NSDictionary *)dicpara RETURN_VALUE:(NSMutableString*)strReturnValue;

@end
