/*
 * Copyright (C) 2013 Matthias Ringwald
 */

#import <ExternalAccessory/ExternalAccessory.h>

@interface NSString (BTstack)
+(NSString*) stringForData:(const uint8_t*) data withSize:(uint16_t) size;
@end

@implementation NSString (BTstatck)
+(NSString*) stringForData:(const uint8_t*) data withSize:(uint16_t) size{
    NSMutableString *output = [NSMutableString stringWithCapacity:size * 3];
    for(int i = 0; i < size; i++){
        [output appendFormat:@"%02x ",data[i]];
    }
    return output;
}
@end

%hook EAInputStream
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len{
    NSInteger result = %orig;
    NSString * hexData = @"";
    if (result > 0){
        hexData = [NSString stringForData:buffer withSize:result];
    }
    NSMutableString * asciiData = [[NSMutableString alloc] init];
    NSScanner *scanner = [[NSScanner alloc] initWithString:hexData];
    unsigned value;
    while([scanner scanHexInt:&value]) {
        [asciiData appendFormat:@"%c",(char)(value & 0xFF)];
    }
    NSLog(@"EAAccessoryLogger: READ(%p,%u) = %d, data: %@", buffer, len, result, asciiData);
    return result;
}
%end

%hook EAOutputStream
- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len{
    NSInteger result = %orig;
    NSString * hexData = [NSString stringForData:buffer withSize:len];
    NSMutableString * asciiData = [[NSMutableString alloc] init];
    NSScanner *scanner = [[NSScanner alloc] initWithString:hexData];
    unsigned value;
    while([scanner scanHexInt:&value]) {
        [asciiData appendFormat:@"%c",(char)(value & 0xFF)];
    }
    NSLog(@"EAAccessoryLogger: WRITE(%p,%u) = %d, data: %@", buffer, len, result, asciiData);
    return result;
}
%end

%hook EASession
-(id)initWithAccessory:(EAAccessory *)accessory forProtocol:(NSString *)protocolString{
    NSLog(@"EAAccessoryLogger: session (%p) created for accessory %@ with protocol: %@", self, accessory, protocolString);
    return %orig;
}
%end
