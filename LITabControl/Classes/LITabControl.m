//
//  LITabControl.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/12/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITabControl.h"
#import "LITabCell.h"

#import <QuartzCore/QuartzCore.h>

#define DF_MIN_TAB_WIDTH    (72.f * 2.75)
#define DF_MAX_TAB_WIDTH    (72.f * 3.25)

@interface LITabControl()

@property(nonatomic, strong) NSArray        *items;

@property(nonatomic, strong) NSScrollView   *scrollView;
@property(nonatomic, strong) NSButton       *addButton, *scrollLeftButton, *scrollRightButton, *draggingTab;

- (NSButton *)existingTabWithItem:(id)item;

@end

@implementation LITabControl

+ (Class)cellClass {
    return [LITabCell class];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self configureSubviews];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureSubviews];
}

- (void)configureSubviews {
    if (_scrollView == nil) {
        [self setWantsLayer:YES];

        _minTabWidth = DF_MIN_TAB_WIDTH;
        _maxTabWidth = DF_MAX_TAB_WIDTH;

        [self.cell setTitle:@""];
        [self.cell setBorderMask:LIBorderMaskBottom];
        [self.cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:13]];
        
        _scrollView         = [self viewWithClass:[NSScrollView class]];
        
        [_scrollView setDrawsBackground:NO];
        [_scrollView setBackgroundColor:[NSColor redColor]];
        
        _addButton          = [self buttonWithImageNamed:@"LITabPlusTemplate" target:self action:@selector(add:)];
        _scrollLeftButton   = [self buttonWithImageNamed:@"LITabLeftTemplate" target:self action:@selector(goLeft:)];
        _scrollRightButton  = [self buttonWithImageNamed:@"LITabRightTemplate" target:self action:@selector(goRight:)];
        
        [_scrollLeftButton setContinuous:YES];
        [_scrollRightButton setContinuous:YES];

        [_scrollLeftButton.cell sendActionOn:NSLeftMouseDownMask|NSPeriodicMask];
        [_scrollRightButton.cell sendActionOn:NSLeftMouseDownMask|NSPeriodicMask];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView, _addButton, _scrollLeftButton, _scrollRightButton);
        
        [self setSubviews:@[_scrollView, _addButton, _scrollLeftButton, _scrollRightButton]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_addButton][_scrollView]-(-1)-[_scrollLeftButton][_scrollRightButton]|" options:0 metrics:nil views:views]];
        
        for (NSView *view in views.allValues) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view": view}]];
        }
        
        [_addButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_addButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:48]];
        [_scrollLeftButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_scrollLeftButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:24]];

        [_scrollRightButton addConstraint:
         [NSLayoutConstraint constraintWithItem:_scrollRightButton attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:24]];
        
        [_addButton.cell setBorderMask:[_addButton.cell borderMask] | LIBorderMaskRight];
        [_scrollLeftButton.cell setBorderMask:[_scrollLeftButton.cell borderMask] | LIBorderMaskLeft];

        [self startObservingScrollView];
        [self updateButtons];
    }
}

- (void)dealloc {
    [self stopObservingScrollView];
}

- (void)updateButtons {
    [_addButton setEnabled:(self.addAction != NULL)];

    NSClipView *contentView = self.scrollView.contentView;

    BOOL isDocumentClipped = (contentView != nil) && (self.items.count * self.minTabWidth > NSWidth(contentView.bounds));
    
    if (isDocumentClipped) {
        [_scrollLeftButton  setHidden:NO];
        [_scrollRightButton setHidden:NO];
    } else {
        [_scrollLeftButton  setHidden:YES];
        [_scrollRightButton setHidden:YES];
    }
}

- (NSButton *)buttonWithImageNamed:(NSString *)name target:(id)target action:(SEL)action {
    NSButton *button = [self viewWithClass:[NSButton class]];

    [button setCell:[[self cell] copy]];

    [button setTarget:target];
    [button setAction:action];

    [button setEnabled:action != NULL];
    
    [button setImagePosition:NSImageOnly];
    [button setImage:[NSImage imageNamed:name]];
    
    return button;
}

- (id)viewWithClass:(Class)clss {
    id view = [[clss alloc] initWithFrame:NSZeroRect];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];

    return view;
}

#pragma mark -
#pragma mark ScrollView Observation

static char LIScrollViewFrameObservationContext;
static char LISCrollViewDocumentFrameObservationContext;

- (void)startObservingScrollView {
    [self.scrollView addObserver:self forKeyPath:@"frame" options:0 context:&LIScrollViewFrameObservationContext];
    [self.scrollView addObserver:self forKeyPath:@"documentView.frame" options:0 context:&LISCrollViewDocumentFrameObservationContext];
}
- (void)stopObservingScrollView {
    [self.scrollView removeObserver:self forKeyPath:@"frame" context:&LIScrollViewFrameObservationContext];
    [self.scrollView removeObserver:self forKeyPath:@"documentView.frame" context:&LISCrollViewDocumentFrameObservationContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &LIScrollViewFrameObservationContext || context == &LISCrollViewDocumentFrameObservationContext) {
        [self updateButtons];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Properties

- (void)setBorderColor:(NSColor *)borderColor {
    [self.cell setBorderColor:borderColor];
    
}
- (void)setBackgroundColor:(NSColor *)backgroundColor {
    [self.cell setBackgroundColor:backgroundColor];
}

#pragma mark -
#pragma mark Actions

- (void)setAddAction:(SEL)addAction {
    if (_addAction != addAction) {
        _addAction = addAction;
        
        [self updateButtons];
    }
}

- (void)add:(id)sender {
    [[NSApplication sharedApplication] sendAction:self.addAction to:self.addTarget from:self];
}

- (void)goLeft:(id)sender {
}

- (void)goRight:(id)sender {
}

- (void)selectTab:(id)sender {
    NSButton *selectedButton = sender;

    for (NSButton *button in [self.scrollView.documentView subviews]) {
        [button setState:(button == selectedButton) ? 1 : 0];
    }

    [[NSApplication sharedApplication] sendAction:self.action to:self.target from:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:LITabControlDidChangeSelectionNotification object:self];

    if ([self.dataSource tabControl:self canReorderItem:[[sender cell] representedObject]]) {
        [self reorderTab:sender withEvent:[NSApp currentEvent]];
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setAllowsImplicitAnimation:YES];
        [selectedButton scrollRectToVisible:[selectedButton bounds]];
    } completionHandler:nil];
}

#pragma mark -
#pragma mark Reordering

- (void)reorderTab:(NSButton *)tab withEvent:(NSEvent *)event {
    // note existing tabs which will be reordered over
    // the course of our drag; while the dragging tab maintains
    // its position over the course of the dragging operation
    
    NSView          *tabView        = self.scrollView.documentView;
    NSMutableArray  *orderedTabs    = [[NSMutableArray alloc] initWithArray:tabView.subviews];
    
    // create a dragging tab used to represent our drag,
    // and constraint its position and its size; the first
    // constraint sets position - we'll be varying this one
    // during our drag...
    
    CGFloat   tabX                  = NSMinX(tab.frame);
    NSPoint   dragPoint             = [tabView convertPoint:event.locationInWindow fromView:nil];
    
    
    NSButton *draggingTab           = [self tabWithTitle:tab.title];
    NSArray  *draggingConstraints   = @[[NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeLeading
                                                                    multiplier:1 constant:tabX],                                // VARIABLE
                                        
                                        [NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeTop
                                                                    multiplier:1 constant:0],                                   // CONSTANT
                                        [NSLayoutConstraint constraintWithItem:draggingTab attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:tabView attribute:NSLayoutAttributeBottom
                                                                    multiplier:1 constant:0]];                                  // CONSTANT
    
    LITabCell *cellCopy = [tab.cell copy];
    
    cellCopy.borderMask = cellCopy.borderMask | LIBorderMaskLeft | LIBorderMaskRight;
    
    [draggingTab setCell:cellCopy];

    [tabView addSubview:draggingTab];
    [tabView addConstraints:draggingConstraints];
    
    [tab setHidden:YES];
    
    BOOL reordered = NO;
    
    while (event.type != NSLeftMouseUp) {
        event = [self.window nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask];
        
        // move the dragged tab
        NSPoint nextPoint = [tabView convertPoint:event.locationInWindow fromView:nil];
        
        CGFloat nextX = tabX + (nextPoint.x - dragPoint.x);
        
        [draggingConstraints[0] setConstant:nextX];
        [tabView layoutSubtreeIfNeeded];
        [draggingTab scrollRectToVisible:draggingTab.bounds];
        
        // test for reordering...
        if (NSMidX(draggingTab.frame) < NSMinX(tab.frame) && tab != tabView.subviews.firstObject) {
            // shift left
            NSUInteger index = [orderedTabs indexOfObject:tab];
            [orderedTabs exchangeObjectAtIndex:index withObjectAtIndex:index - 1];
            
            [self layoutTabs:orderedTabs inView:tabView];
            [tabView addConstraints:draggingConstraints];
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setAllowsImplicitAnimation:YES];
                [tabView layoutSubtreeIfNeeded];
            } completionHandler:nil];
            
            reordered = YES;
            
        } else if (NSMidX(draggingTab.frame) > NSMaxX(tab.frame) && tab != tabView.subviews.lastObject) {
            // shift right
            NSUInteger index = [orderedTabs indexOfObject:tab];
            [orderedTabs exchangeObjectAtIndex:index+1 withObjectAtIndex:index];
            
            [self layoutTabs:orderedTabs inView:tabView];
            [tabView addConstraints:draggingConstraints];
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setAllowsImplicitAnimation:YES];
                [tabView layoutSubtreeIfNeeded];
            } completionHandler:nil];
            
            
            reordered = YES;
        }
    }

    [tab setHidden:NO];

    [draggingTab removeFromSuperview];
    [tabView removeConstraints:draggingConstraints];
    
    
    if (reordered) {
        NSArray *orderedItems = [orderedTabs valueForKeyPath:@"cell.representedObject"];
        [self.dataSource tabControlDidReorderItems:self orderedItems:orderedItems];
        [self reloadData]; // mildly expensive but ensures state...
    }
}

#pragma mark -
#pragma mark Selection

- (id)selectedItem {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if ([button state] == 1) {
            return [[button cell] representedObject];
        }
    }
    return nil;
}
- (void)setSelectedItem:(id)selectedItem {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        [button setState:[[[button cell] representedObject] isEqual:selectedItem] ? 1 : 0];
    }
}

#pragma mark -
#pragma mark Data Source

- (void)setDataSource:(id<LITabDataSource>)dataSource {
    if (_dataSource != dataSource) {
        
        if (_dataSource && [_dataSource respondsToSelector:@selector(tabControlDidChangeSelection:)])
            [[NSNotificationCenter defaultCenter] removeObserver:_dataSource name:LITabControlDidChangeSelectionNotification object:self];
        
        _dataSource = dataSource;
        
        if (_dataSource && [_dataSource respondsToSelector:@selector(tabControlDidChangeSelection:)])
            [[NSNotificationCenter defaultCenter] addObserver:_dataSource selector:@selector(tabControlDidChangeSelection:) name:LITabControlDidChangeSelectionNotification object:self];
        
        [self reloadData];
    }
}

- (void)reloadData {
    NSView *tabView = [self viewWithClass:[NSView class]];
    NSMutableArray *newItems = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0, count = [self.dataSource tabControlNumberOfTabs:self]; i < count; i++) {
        [newItems addObject:[self.dataSource tabControl:self itemAtIndex:i]];
    }
    
    NSMutableArray *newTabs = [[NSMutableArray alloc] init];
    
    for (id item in newItems) {
        NSButton *button = [self tabWithTitle:[self.dataSource tabControl:self titleForItem:item]];
        
        [[button cell] setRepresentedObject:item];
        
        NSMenu *menu = [self.dataSource tabControl:self menuForItem:item];
        if (menu != nil) {
            [[button cell] setMenu:menu];
            [button addTrackingArea:[[NSTrackingArea alloc] initWithRect:_scrollView.bounds
                                                                 options:NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect
                                                                   owner:self
                                                                userInfo:@{@"item" : item}]];
        }

        [newTabs addObject:button];
    }

    [tabView setSubviews:newTabs];
    [self layoutTabs:newTabs inView:tabView];
    
    self.items = newItems;
    self.scrollView.documentView = (self.items.count) ? tabView : nil;
    
    if (self.scrollView.documentView) {
        NSClipView *clipView = self.scrollView.contentView;
        NSView *documentView = self.scrollView.documentView;
        
        [clipView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[documentView]" options:0 metrics:nil views:@{@"documentView": documentView}]];
        [clipView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[documentView]|" options:0 metrics:nil views:@{@"documentView": documentView}]];
    }
    
    [self updateButtons];
}

- (void)layoutTabs:(NSArray *)tabs inView:(NSView *)tabView {
    // remove old constraints, if any...
    [tabView removeConstraints:tabView.constraints];
    
    // constrain passed tabs into a horizontal list...
    NSButton *prev = nil;
    for (NSButton *button in tabs) {
        [tabView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|" options:0 metrics:nil views:@{@"button":button}]];
        
        [tabView addConstraint:
         [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:(prev != nil ? prev : tabView)
                                      attribute:(prev != nil ? NSLayoutAttributeTrailing : NSLayoutAttributeLeading)
                                     multiplier:1 constant:0]];
        prev = button;
    }
    
    if (prev) {
        [tabView addConstraint:
         [NSLayoutConstraint constraintWithItem:prev attribute:NSLayoutAttributeTrailing
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:tabView attribute:NSLayoutAttributeTrailing
                                     multiplier:1 constant:0]];
    }
}

- (NSButton *)tabWithTitle:(NSString *)title {
    LITabCell *tabCell = [[LITabCell alloc] initTextCell:title];
    
    tabCell.target = self;
    tabCell.action = @selector(selectTab:);
    [tabCell sendActionOn:NSLeftMouseDownMask];

    tabCell.imagePosition   = NSNoImage;
    tabCell.borderMask      = LIBorderMaskRight|LIBorderMaskBottom;
    tabCell.font            = [NSFont fontWithName:@"HelveticaNeue-Medium" size:13];
    NSButton *tab = [self viewWithClass:[NSButton class]];

    [tab setCell:tabCell];
    
    [tab addConstraints:
     @[[NSLayoutConstraint constraintWithItem:tab attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                       toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                   multiplier:1.0 constant:self.minTabWidth],
       
       [NSLayoutConstraint constraintWithItem:tab attribute:NSLayoutAttributeWidth
                                    relatedBy:NSLayoutRelationLessThanOrEqual
                                       toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                   multiplier:1.0 constant:self.maxTabWidth]]];
    
    return tab;
}

- (NSButton *)existingTabWithItem:(id)item {
    for (NSButton *button in [self.scrollView.documentView subviews]) {
        if (button != self.draggingTab) {
            if ([[[button cell] representedObject] isEqual:item]) {
                return button;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark ScrollView Tracking

- (NSButton *)trackedButtonWithEvent:(NSEvent *)theEvent {
    id item = theEvent.trackingArea.userInfo[@"item"];
    return (item != nil) ? [self existingTabWithItem:item] : nil;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [[[self trackedButtonWithEvent:theEvent] cell] setShowsMenu:YES];
}
- (void)mouseExited:(NSEvent *)theEvent {
    [[[self trackedButtonWithEvent:theEvent] cell] setShowsMenu:NO];
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
    return YES;
}
- (BOOL)isFlipped {
    return YES;
}

@end

NSString *LITabControlDidChangeSelectionNotification = @"LITabControlDidChangeSelectionNotification";