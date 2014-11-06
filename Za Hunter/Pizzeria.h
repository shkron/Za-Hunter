//
//  Pizzeria.h
//  Za Hunter
//
//  Created by Alex on 11/5/14.
//  Copyright (c) 2014 Alexey Emelyanov. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;

@interface Pizzeria : NSObject
@property NSString *name;
@property MKPlacemark *placemark;
@property NSString *url;

@end
