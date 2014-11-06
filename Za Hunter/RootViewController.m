//
//  ViewController.m
//  Za Hunter
//
//  Created by Alex on 11/5/14.
//  Copyright (c) 2014 Alexey Emelyanov. All rights reserved.
//

#import "RootViewController.h"
#import "Pizzeria.h"
@import CoreLocation;
@import MapKit;

@interface RootViewController () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property CLLocationManager *locationManager;
@property NSArray *searchArray;
@property NSMutableArray *tableViewArray;
@property double globalETA;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager = [CLLocationManager new];
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;

    self.searchArray = [NSArray array];
//    self.tableViewArray = [NSMutableArray array];

    //need to be moved later!
    [self.locationManager startUpdatingLocation];
    self.navigationItem.title = @"Locating you...";



}

//MARK: Delegation methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    NSString *name = [self.tableViewArray[indexPath.row] name];
    cell.textLabel.text = name;


    MKPlacemark *placemark = [self.tableViewArray[indexPath.row] placemark];
    NSString *address = [NSString stringWithFormat:@"%@ %@., %@, %@ %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.postalCode];

    cell.detailTextLabel.text = address;
//    cell.detailTextLabel.text = [self.tableViewArray[indexPath.row] distanceFromMe];
    //    cell.backgroundColor = [UIColor clearColor];
    return cell;


}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewArray.count;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self networkAlertWindow:error.localizedDescription];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in  locations)
    {
        if (location.verticalAccuracy <100 && location.horizontalAccuracy < 100)
        {
            self.navigationItem.title = @"Found Ya! Reverse geocoding now...";
            [self reverseGeocode:location];
            [self.locationManager stopUpdatingLocation];

            break;
        }
    }
}



//MARK: Custom methods

-(void) reverseGeocode:(CLLocation *)location
{

    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, id error) {
        CLPlacemark *placemark = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@ %@, %@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality];
        self.navigationItem.title = [NSString stringWithFormat:@"%@", address];
        [self findPlacesNearMe:placemark.location];
    }];
}

-(void)findPlacesNearMe:(CLLocation *)location
{
//    self.globalETA = 0;
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"Pizzeria";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1,1));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         self.searchArray = [response.mapItems mutableCopy];
         self.tableViewArray = [NSMutableArray array];
         MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
//         MKMapItem *destination = [MKMapItem new];
         int i=0;
         for (MKMapItem *mapItem in self.searchArray)
         {
             if([mapItem.placemark.location distanceFromLocation:location] < 20000 && i < 4)
             {
                 [self.tableViewArray addObject:mapItem];

                 [self getTravelETAfrom:source destination:mapItem];
                 source = mapItem;

                 i++;
             }

         }
         [self.tableView reloadData];


//         NSString *string = [self.tableViewArray.firstObject name];
//         for (MKMapItem *mapItem in mapItems)
//         {
//
//         }
//         MKMapItem *mapItem = mapItems.firstObject;

//         self.myTextView.text = [NSString stringWithFormat:@"You should go to %@", mapItem.name];
//         [self getDirectionsTo:mapItem];
     }];
}

-(void)getDirectionsTo:(MKMapItem *)destinationItem
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destinationItem;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, id error)
     {
         NSArray *routes = response.routes;
         MKRoute *route = routes.firstObject;


         int x = 1;
         NSMutableString *directionsString = [NSMutableString string];

         for (MKRouteStep *step in route.steps)
         {

             [directionsString appendFormat:@"%d: %@\n", x, step.instructions];
             x++;


             NSLog(@"%@", step.instructions);
         }
//         self.myTextView.text = directionsString;
     }];
}

-(void)getTravelETAfrom:(MKMapItem *)sourceItem destination:(MKMapItem *)destinationItem
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.transportType = MKDirectionsTransportTypeWalking;
    request.source = sourceItem; //[MKMapItem mapItemForCurrentLocation];
    request.destination = destinationItem;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
        double timeInt = response.expectedTravelTime;
        self.globalETA = self.globalETA + timeInt + 3000;

            int valueInMin = (int)(self.globalETA/60);
            self.navigationItem.title = [NSString stringWithFormat:@"ETA including meals: %d minutes",valueInMin];

    }];


}




-(void)networkAlertWindow:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"MKay..." style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}




@end
