//
//  MemoriesViewController.m
//  FbEvents
//
//  Created by Adrien Dulong on 23/11/2013.
//  Copyright (c) 2013 Adrien Dulong. All rights reserved.
//

#import "MemoriesViewController.h"
#import "PhotosCollectionViewController.h"
#import "MemorieCell.h"
#import "FirstMemorieCell.h"

@interface MemoriesViewController ()

@end

@implementation MemoriesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadMemoriesFromSever];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.memoriesInvitations count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 44;
    }
    else{
        return 195;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    

    if (indexPath.row==0) {
        static NSString *CellIdentifier = @"FirstCell";
        
        FirstMemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[FirstMemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        return cell;
    }
    else{
        static NSString *CellIdentifier = @"Cell";
        
        int indexPosition = indexPath.row-1;
        
        MemorieCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MemorieCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        
        //Get the event object.
        PFObject *event = [self.memoriesInvitations objectAtIndex:indexPosition][@"event"];
        
        //Date
        NSDate *start_date = event[@"start_time"];
        //Formatter for the hour
        NSDateFormatter *formatterHourMinute = [NSDateFormatter new];
        [formatterHourMinute setDateFormat:@"HH:mm"];
        NSDateFormatter *formatterMonth = [NSDateFormatter new];
        [formatterMonth setDateFormat:@"MMM"];
        NSDateFormatter *formatterDay = [NSDateFormatter new];
        [formatterDay setDateFormat:@"d"];
        
        //Fill the cell
        cell.nameLabel.text = event[@"name"];
        cell.placeLabel.text = [NSString stringWithFormat:@"%@", event[@"location"]];
        cell.monthLabel.text = [[NSString stringWithFormat:@"%@", [formatterMonth stringFromDate:start_date]] uppercaseString];
        cell.dayLabel.text = [NSString stringWithFormat:@"%@", [formatterDay stringFromDate:start_date]];
        
        NSLog(@" NB PHOTOS : %i", [[self.photosEvent objectAtIndex:indexPosition] count]);
        if ([[self.photosEvent objectAtIndex:indexPosition] count]>0) {
            NSMutableArray *arrayPhotos = [self.photosEvent objectAtIndex:indexPosition];
            [cell.coverImage setHidden:YES];
            
            for (int i=0; i<[arrayPhotos count]; i++) {
                PFObject *photo =[arrayPhotos objectAtIndex:i];
                
                PFImageView *imageView = (PFImageView *)[cell viewWithTag:i+1];
                
                if (photo[@"facebookId"]) {
                    [imageView setImageWithURL:photo[@"facebook_url_low"] placeholderImage:[UIImage imageNamed:@"covertestinfos.png"]];
                }
                else{
                    imageView.image = [UIImage imageNamed:@"covertest"]; // placeholder image
                    imageView.file = (PFFile *)photo[@"low_image"]; // remote image
                    
                    [imageView loadInBackground];
                }
            }
        }
        else{
            [cell.coverImage setHidden:NO];
            [cell.coverImage setImageWithURL:[NSURL URLWithString:event[@"cover"]]
                            placeholderImage:[UIImage imageNamed:@"covertest.png"]];
        }
        
        return cell;
    }
    
    
    
    
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */


#pragma mark - Parse Events

-(void)loadMemoriesFromSever{
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query whereKey:@"start_time" lessThan:[NSDate date]];
    [query whereKey:@"rsvp_status" notEqualTo:FacebookEventNotReplied];
    [query whereKey:@"rsvp_status" notEqualTo:FacebookEventDeclined];
    [query includeKey:@"event"];
    [query orderByDescending:@"start_time"];
    
    //Cache then network
    //query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"LOADED PAST");
            self.memoriesInvitations = objects;
            self.photosEvent = [[NSMutableArray alloc] init];
            
            int i=0;
            for(PFObject *memorieInvit in self.memoriesInvitations){
                NSMutableArray *mutableArrayTemp = [[NSMutableArray alloc] init];
                [self.photosEvent addObject:mutableArrayTemp];
                [self loadPhotosOfEvent:memorieInvit[@"event"] atPosition:i];
                i++;
            }
            
            [self.tableView reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Problème de chargement");
        }
    }];
}


-(void)loadPhotosOfEvent: (PFObject *)event atPosition:(int)position{
    PFQuery *queryPhotos = [PFQuery queryWithClassName:@"Photo"];
    [queryPhotos whereKey:@"event" equalTo:event];
    [queryPhotos orderByDescending:@"createdAt"];
    queryPhotos.limit = 9;

    
    [queryPhotos findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.photosEvent replaceObjectAtIndex:position withObject:objects];
            [self.tableView reloadData];
        }
    }];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"DetailEvent"]) {
        
        self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        //Selected row
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        
        
        PhotosCollectionViewController *photosCollectionViewController = segue.destinationViewController;
        photosCollectionViewController.invitation = [self.memoriesInvitations objectAtIndex:selectedRowIndex.row];
    }

}

@end
