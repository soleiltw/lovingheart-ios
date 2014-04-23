//
//  LHIdeaGroupListViewController.m
//  LovingHeart
//
//  Created by Edward Chiang on 2014/4/23.
//  Copyright (c) 2014年 LovineHeart. All rights reserved.
//

#import "LHIdeaGroupListViewController.h"
#import "LHIdea.h"
#import "LHIdeaActionCardCell.h"
#import "LHIdeaCardViewController.h"
#import <UIAlertView+BlocksKit.h>
#import "LHLoginViewController.h"
#import "DAProgressOverlayView.h"
#import "LHCategoriesPickController.h"

@implementation LHIdeaGroupListViewController

- (void)awakeFromNib {
  self.parseClassName = @"IdeaGroupMapping";
  self.pullToRefreshEnabled = YES;
  self.paginationEnabled = YES;
  self.objectsPerPage = 10;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (PFQuery *)queryForTable {
  PFQuery *query = [LHIdeaGroupMapping query];
  
  [query includeKey:@"Idea"];
  [query includeKey:@"Idea.categoryPointer"];
  [query includeKey:@"Idea.graphicPointer"];
  [query includeKey:@"IdeaGroup"];
  [query whereKey:@"IdeaGroup" equalTo:self.ideaGroup];
  [query whereKey:@"status" notEqualTo:@"close"];
  
  // If no objects are loaded in memory, we look to the cache first to fill the table
  // and then subsequently do a query against the network.
  if (self.objects.count == 0) {
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  }
  
  [query orderByDescending:@"createdAt"];
  
  return query;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(LHIdeaGroupMapping *)ideaMappingObject {
  
  LHIdeaActionCardCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IdeaCardViewCell"];
  
  if (ideaMappingObject.Idea.graphicPointer) {
    
    cell.ideaImageView.image = [UIImage imageNamed:@"card_default"];
    cell.progressOverlayView.frame = cell.ideaImageView.bounds;
    
    PFFile* file = (PFFile*)ideaMappingObject.Idea.graphicPointer.imageFile;
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if (!error) {
        UIImage *image = [UIImage imageWithData:data];
        LHIdeaActionCardCell* cell = (LHIdeaActionCardCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.ideaImageView.image = image;
        [cell setNeedsDisplay];
      }
    } progressBlock:^(int percentDone) {
      float perenctDownFloat = (float)percentDone / 100.f;
      NSLog(@"Download %@ progress: %f", file.url, perenctDownFloat);
      if (perenctDownFloat == 0) {
        [cell.progressOverlayView displayOperationWillTriggerAnimation];
        cell.progressOverlayView.hidden = NO;
      }
      if (perenctDownFloat < 1) {
        cell.progressOverlayView.progress = perenctDownFloat;
      } else {
        [cell.progressOverlayView displayOperationDidFinishAnimation];
        double delayInSeconds = cell.progressOverlayView.stateChangeAnimationDuration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          cell.progressOverlayView.progress = 0.;
          cell.progressOverlayView.hidden = YES;
        });
        
      }
    }];
    
  }
  
  [cell.categoryTitleLabel setText:ideaMappingObject.Idea.categoryPointer.Name];
  [cell.ideaTitleLabel setText:ideaMappingObject.Idea.Name];
  [cell.ideaTitleLabel sizeToFit];
  
  [cell.ideaDescriptionLabel setText:ideaMappingObject.Idea.Description];
  [cell.ideaDescriptionLabel sizeToFit];
  
  if (ideaMappingObject.Idea.doneCount.intValue > 1) {
    [cell.ideaDoneCountLabel setText:[NSString stringWithFormat:@"Done %i times", ideaMappingObject.Idea.doneCount.intValue]];
    cell.ideaDoneCountLabel.hidden = NO;
  } else if (ideaMappingObject.Idea.doneCount.intValue == 1) {
    [cell.ideaDoneCountLabel setText:[NSString stringWithFormat:@"Done %i time", ideaMappingObject.Idea.doneCount.intValue]];
    cell.ideaDoneCountLabel.hidden = NO;
  } else {
    cell.ideaDoneCountLabel.hidden = YES;
  }
  
  return cell;
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
  PFTableViewCell *cell  = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                  reuseIdentifier:@"loadCell"];
  UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithFrame:cell.bounds];
  spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  [spinner startAnimating];
  [cell addSubview:spinner];
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == self.objects.count) {
    [self loadNextPage];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (indexPath.row < self.objects.count) {
    LHIdea *currentIdea = (LHIdea *)[self.objects objectAtIndex:indexPath.row];
    
    //Calculate the expected size based on the font and linebreak mode of your label
    CGSize maximumIdeaContentLabelSize = CGSizeMake(320.f, FLT_MAX);
    
    NSDictionary *stringArrtibutes = [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:17.f] forKey:NSFontAttributeName];
    
    CGSize expectedIdeaTitleSize = [currentIdea.Name boundingRectWithSize:maximumIdeaContentLabelSize options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:stringArrtibutes context:nil].size;
    
    return expectedIdeaTitleSize.height + 120;
  }
  
  return 120.f;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  
  if ([segue.identifier isEqual:@"pushIdeaCardViewController"]) {
    LHIdeaCardViewController *viewController = segue.destinationViewController;
    NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
    LHIdeaGroupMapping *ideaMapping = (LHIdeaGroupMapping *)[self objectAtIndexPath:selectedPath];
    [viewController setIdea:ideaMapping.Idea];
  }
  
}

@end