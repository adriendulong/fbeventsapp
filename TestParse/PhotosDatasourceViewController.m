//
//  WYPhotosDatasourceViewController.m
//  WYPopoverDemoSegue
//
//  Created by Jérémy on 03/02/2014.
//  Copyright (c) 2014 Nicolas CHENG. All rights reserved.
//

#import "PhotosDatasourceViewController.h"
#import "PhotosDatasourceCell.h"

@interface PhotosDatasourceViewController ()

@end

@implementation PhotosDatasourceViewController

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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.assetsGroupList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"PDSCell";
    PhotosDatasourceCell *cell = (PhotosDatasourceCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ALAssetsGroup *assetsGroup = self.assetsGroupList[indexPath.row];
    
    cell.datasourceName.text = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    cell.nbPhotos.text = [NSString stringWithFormat:@"%i %@", assetsGroup.numberOfAssets, (assetsGroup.numberOfAssets > 1) ? @"photos" : @"photo"];
    cell.lastPhoto.image = [UIImage imageWithCGImage:assetsGroup.posterImage];
    
    
    
    //cell.accessoryType = (indexPath.row == self.selectedRow) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    cell.accessoryType = ([[assetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:self.selectedGroupPersistentID]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //self.selectedRow = indexPath.row;
    
    ALAssetsGroup *assetsGroup = self.assetsGroupList[indexPath.row];
    
    [self.delegate photosDatasourceViewController:self
                            didSelectedDatasource:[assetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID]
                                andDatasourceName:[assetsGroup valueForProperty:ALAssetsGroupPropertyName]];
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

@end
