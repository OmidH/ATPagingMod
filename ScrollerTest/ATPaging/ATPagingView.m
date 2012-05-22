//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
//  ATPagingView official version 1.1.
//
// modified by Omid Hashemi @ 05.01.2012

#import "ATPagingView.h"
#import "ContentScrollView.h"


//#define AT_PAGING_VIEW_TRACE_LAYOUT
#define AT_PAGING_VIEW_TRACE_DELEGATE_CALLS
//#define AT_PAGING_VIEW_TRACE_PAGE_LIFECYCLE


@interface ATPagingView () <UIScrollViewDelegate>

- (void)configurePages;
- (void)configurePage:(UIView *)page forIndex:(NSInteger)index;

- (CGRect)frameForScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;

- (void)recyclePage:(UIView *)page;

- (void)knownToBeMoving;
- (void)knownToBeIdle;

- (void) determineScrollDirection:(CGPoint) offset;

@end



@implementation ATPagingView

@synthesize delegate=_delegate;
@synthesize gapBetweenPages=_gapBetweenPages;
@synthesize pagesToPreload=_pagesToPreload;
@synthesize pageCount=_pageCount;
@synthesize currentPageIndex=_currentPageIndex;
@synthesize moving=_scrollViewIsMoving;
@synthesize previousPageIndex=_previousPageIndex;
@synthesize recyclingEnabled=_recyclingEnabled;
@synthesize horizontal = _horizontal;
@synthesize shouldScrollVertical = _shouldScrollVertical;
@synthesize isRootScroller = _isRootScroller;
@synthesize parentScroller = _parentScroller;


#pragma mark -
#pragma mark init/dealloc

- (void)commonInit {
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _currentPageIndex = 0;
    _gapBetweenPages = 0.0;
    _pagesToPreload = 1;
    _recyclingEnabled = YES;
    _firstLoadedPageIndex = _lastLoadedPageIndex = -1;
    _horizontal = YES;
    _shouldScrollVertical = YES;

    // We are using an oversized UIScrollView to implement interpage gaps,
    // and we need it to clipped on the sides. This is important when
    // someone uses ATPagingView in a non-fullscreen layout.
    self.clipsToBounds = YES;

    _scrollView = [[ContentScrollView alloc] initWithFrame:[self frameForScrollView]]; //[[UIScrollView alloc] initWithFrame:[self frameForScrollView]];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.pagingEnabled = YES;
    _scrollView.backgroundColor = [UIColor whiteColor];
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.showsHorizontalScrollIndicator = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _isRootScroller = NO;
    [self addSubview:_scrollView];
    
    NSLog(@"commonInit");
}

- (void)dealloc {
    _scrollView = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

//- (void)dealloc {
//    [_scrollView release], _scrollView = nil;
//    _delegate = nil;
//    [_recycledPages release], _recycledPages = nil;
//    [_visiblePages release], _visiblePages = nil;
//    [super dealloc];
//}


#pragma mark Properties

- (void)setGapBetweenPages:(CGFloat)value {
    _gapBetweenPages = value;
    [self setNeedsLayout];
}

- (void)setPagesToPreload:(NSInteger)value {
    BOOL reconfigure = _pagesToPreload != value;
    _pagesToPreload = value;
    if (reconfigure) {
        [self configurePages];
    }
}

-(void)setHorizontal:(BOOL)value {
    BOOL reconfigure = _horizontal != value;
    _horizontal = value;
    if (reconfigure) {
        [self layoutIfNeeded]; // force call to layoutSubview to set _scrollView.frame
        [self configurePages];
    }
}

#pragma mark -
#pragma mark Data

- (void)reloadData {
    _pageCount = [_delegate numberOfPagesInPagingView:self];

    // recycle all pages
    for (UIView *view in _visiblePages) {
        [self recyclePage:view];
    }
    [_visiblePages removeAllObjects];

    [self configurePages];
}


#pragma mark -
#pragma mark Page Views

- (UIView *)viewForPageAtIndex:(NSUInteger)index {
    for (UIView *page in _visiblePages)
        if (page.tag == index)
            return page;
    return nil;
}

- (void)configurePages {
    
    if (_horizontal && (_scrollView.frame.size.width <= _gapBetweenPages + 1e-6)) {
        return;  // not our time yet
    } else if (_scrollView.frame.size.height <= _gapBetweenPages + 1e-6) {
        return;  // not our time yet
    }
    
    if (_pageCount == 0 && _currentPageIndex > 0)
        return;  // still not our time

    // normally layoutSubviews won't even call us, but protect against any other calls too (e.g. if someones does reloadPages)
    if (_rotationInProgress){
        NSLog(@"=====> _rotationInProgress");
        return;
    }

    // to avoid hiccups while scrolling, do not preload invisible pages temporarily
    BOOL quickMode = (_scrollViewIsMoving && _pagesToPreload > 0);

    CGSize contentSize;
    if (_horizontal) {
        contentSize = CGSizeMake(_scrollView.frame.size.width * _pageCount, _scrollView.frame.size.height);
    } else {
        contentSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height * _pageCount);
    }
    
    if (!CGSizeEqualToSize(_scrollView.contentSize, contentSize)) {
//#ifdef AT_PAGING_VIEW_TRACE_LAYOUT
        NSLog(@"(%@) configurePages: _scrollView.frame == %@, <<setting>> _scrollView.contentSize = %@",
              ((_isRootScroller)?@"Root":@"Node"), NSStringFromCGRect(_scrollView.frame), NSStringFromCGSize(contentSize));
//#endif
        _scrollView.contentSize = contentSize;
        if (_horizontal) {
            _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * _currentPageIndex, 0);
        } else {
            _scrollView.contentOffset = CGPointMake(0, _scrollView.frame.size.height * _currentPageIndex);
            NSLog(@"#### %@", NSStringFromCGPoint(_scrollView.contentOffset));
        }
        
    } else {
//#ifdef AT_PAGING_VIEW_TRACE_LAYOUT
        NSLog(@"(%@) configurePages: _scrollView.frame == %@, _scrollView.contentOffset == %@", ((_isRootScroller)?@"Root":@"Node"), NSStringFromCGRect(_scrollView.frame), NSStringFromCGPoint(_scrollView.contentOffset));
//#endif
    }

    CGRect visibleBounds = _scrollView.bounds;
    NSInteger newPageIndex;
    if (_horizontal) {
        newPageIndex = MIN(MAX(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)), 0), _pageCount - 1);
    } else {
        newPageIndex = MIN(MAX(floorf(CGRectGetMidY(visibleBounds) / CGRectGetHeight(visibleBounds)), 0), _pageCount - 1);
        NSLog(@"(%@) visibleBounds:%@ CGRectGetMidY(%f), CGRectGetHeight(%f), floorf(%f) => newpageindex:%d", ((_isRootScroller)?@"Root":@"Node"), NSStringFromCGRect(visibleBounds), CGRectGetMidY(visibleBounds), CGRectGetHeight(visibleBounds), floorf(CGRectGetMidY(visibleBounds) / CGRectGetHeight(visibleBounds)), newPageIndex);
    }
    
#ifdef AT_PAGING_VIEW_TRACE_LAYOUT
    NSLog(@"(%@) newPageIndex == %d Bounds:%@", ((_isRootScroller)?@"Root":@"Node"), newPageIndex, NSStringFromCGRect(visibleBounds));
#endif

    newPageIndex = MAX(0, MIN(_pageCount, newPageIndex));

    // calculate which pages are visible
    int firstVisiblePage = self.firstVisiblePageIndex;
    int lastVisiblePage  = self.lastVisiblePageIndex;
    int firstPage = MAX(0,            MIN(firstVisiblePage, newPageIndex - _pagesToPreload));
    int lastPage  = MIN(_pageCount-1, MAX(lastVisiblePage,  newPageIndex + _pagesToPreload));

    // recycle no longer visible pages
    NSMutableSet *pagesToRemove = [NSMutableSet set];
    for (UIView *page in _visiblePages) {
        if (page.tag < firstPage || page.tag > lastPage) {
            [self recyclePage:page];
            [pagesToRemove addObject:page];
        }
    }
    [_visiblePages minusSet:pagesToRemove];

#pragma mark - debug point add pages
    // add missing pages
    for (int index = firstPage; index <= lastPage; index++) {
        if ([self viewForPageAtIndex:index] == nil) {
            // only preload visible pages in quick mode
            if (quickMode && (index < firstVisiblePage || index > lastVisiblePage))
                continue;
            UIView *page = [_delegate viewForPageInPagingView:self atIndex:index];
            [self configurePage:page forIndex:index];
            [_scrollView addSubview:page];
            [_visiblePages addObject:page];
            
            //debug
            NSString *str;
            
            for (UIView *vv in _visiblePages) {
                str = [NSString stringWithFormat:@"%@, %d", str, vv.tag];
            }
            
            NSLog(@"-----------------------> (%@) f:%d, l:%d count visiblePages: %d [%@]",((_isRootScroller)?@"Root":@"Node"), firstPage, lastPage, [_visiblePages count], str);
        }
    }

    // update loaded pages info
    BOOL loadedPagesChanged;
    if (quickMode) {
        // Delay the notification until we actually load all the promised pages.
        // Also don't update _firstLoadedPageIndex and _lastLoadedPageIndex, so
        // that the next time we are called with quickMode==NO, we know that a
        // notification is still needed.
        loadedPagesChanged = NO;
    } else {
        loadedPagesChanged = (_firstLoadedPageIndex != firstPage || _lastLoadedPageIndex != lastPage);
        if (loadedPagesChanged) {
            _firstLoadedPageIndex = firstPage;
            _lastLoadedPageIndex  = lastPage;
//#ifdef AT_PAGING_VIEW_TRACE_DELEGATE_CALLS
//            NSLog(@"loadedPagesChanged: first == %d, last == %d", _firstLoadedPageIndex, _lastLoadedPageIndex);
//#endif
        }
    }

    // update current page index
    BOOL pageIndexChanged = (newPageIndex != _currentPageIndex);
    if (pageIndexChanged) {
        _previousPageIndex = _currentPageIndex;
        _currentPageIndex = newPageIndex;
        if ([_delegate respondsToSelector:@selector(currentPageDidChangeInPagingView:)])
            [_delegate currentPageDidChangeInPagingView:self];
#ifdef AT_PAGING_VIEW_TRACE_DELEGATE_CALLS
        NSLog(@"(%@) _currentPageIndex == %d", ((_isRootScroller)?@"Root":@"Node"), _currentPageIndex);
#endif
        if(!_isRootScroller && _currentPageIndex > 0)
            _parentScroller.pagingView.shouldScrollVertical = NO;
        else 
            _parentScroller.pagingView.shouldScrollVertical = YES;
    }

    if (loadedPagesChanged || pageIndexChanged) {
        if ([_delegate respondsToSelector:@selector(pagesDidChangeInPagingView:)]) {
#ifdef AT_PAGING_VIEW_TRACE_DELEGATE_CALLS
            NSLog(@"pagesDidChangeInPagingView");
#endif
            [_delegate pagesDidChangeInPagingView:self];
        }
    }
}

- (void)configurePage:(UIView *)page forIndex:(NSInteger)index {
    page.tag = index;
    CGRect rect = [self frameForPageAtIndex:index];
    page.frame = rect;
    [page setNeedsDisplay]; // just in case
}


#pragma mark -
#pragma mark Rotation

// Why do we even have to handle rotation separately, instead of just sticking
// more magic inside layoutSubviews?
//
// This is how I've been doing rotatable paged screens since long ago.
// However, since layoutSubviews is more or less an equivalent of
// willAnimateRotation, and since there is probably a way to catch didRotate,
// maybe we can get rid of this special case.
//
// Just needs more work.

- (void)willAnimateRotation {
    _rotationInProgress = YES;

#pragma mark - debug point remove
    // recycle non-current pages, otherwise they might show up during the rotation
    NSMutableSet *pagesToRemove = [NSMutableSet set];
    for (UIView *view in _visiblePages)
        if (view.tag != _currentPageIndex) {
            [self recyclePage:view];
            [pagesToRemove addObject:view];
        }
    [_visiblePages minusSet:pagesToRemove];
    
    NSLog(@"\n(%@)visible pages: %@ \nremove:%@", ((_isRootScroller)?@"root":@"node"),[_visiblePages debugDescription], [pagesToRemove debugDescription]);

    // We're inside an animation block, this has two consequences:
    //
    // 1) we need to resize the page view now (so that the size change is animated);
    //
    // 2) we cannot update the scroll view's contentOffset to align it with the new
    // page boundaries (since any such change will be animated in very funny ways).
    //
    // (Note that the scroll view has already been resized by now.)
    //
    // So we set the new size, but keep the old position here.
    CGSize pageSize = _scrollView.frame.size;
    if (_horizontal) {
        [self viewForPageAtIndex:_currentPageIndex].frame = CGRectMake(_scrollView.contentOffset.x + _gapBetweenPages/2, 0, pageSize.width - _gapBetweenPages, pageSize.height);
    } else {
        [self viewForPageAtIndex:_currentPageIndex].frame = CGRectMake(0, _scrollView.contentOffset.y + _gapBetweenPages/2, pageSize.width, pageSize.height - _gapBetweenPages);
    }
}

- (void)didRotate {
    // Adjust frames according to the new page size - this does not cause any visible
    // changes, because we move the pages and adjust contentOffset simultaneously.
    for (UIView *view in _visiblePages) {
        if ([view isKindOfClass:[ATPagingView class]]) {
            [(ATPagingView *) view didRotate];
        }
        [self configurePage:view forIndex:view.tag];
    }
    
    if (_horizontal) {
        _scrollView.contentOffset = CGPointMake(_currentPageIndex * _scrollView.frame.size.width, 0);	
    } else {
        _scrollView.contentOffset = CGPointMake(0, _currentPageIndex * _scrollView.frame.size.height);
    }

    _rotationInProgress = NO;
    actualScreenOffset = _scrollView.contentOffset;

    [self configurePages];
}


#pragma mark -
#pragma mark Page navigation

- (void)setCurrentPageIndex:(NSInteger)newPageIndex Animated:(BOOL) animated {
#ifdef AT_PAGING_VIEW_TRACE_LAYOUT
    NSLog(@"(%@) setCurrentPageIndex(%d): _scrollView.frame == %@", ((_isRootScroller)?@"Root":@"Node"), newPageIndex, NSStringFromCGRect(_scrollView.frame));
#endif
    if (_horizontal && (_scrollView.frame.size.width > 0 && fabsf(_scrollView.frame.origin.x - (-_gapBetweenPages/2)) < 1e-6) ) {
        if(!animated)
            _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * newPageIndex, 0);
        else
            [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width * newPageIndex, 0) animated:YES];
    } else if (_scrollView.frame.size.height > 0 && fabsf(_scrollView.frame.origin.y - (-_gapBetweenPages/2)) < 1e-6) {
        if(!animated)
            _scrollView.contentOffset = CGPointMake(0, _scrollView.frame.size.height * newPageIndex);
        else
            [_scrollView setContentOffset:CGPointMake(0, _scrollView.frame.size.height * newPageIndex) animated:YES];
    }
    _currentPageIndex = newPageIndex;
}

- (void) determineScrollDirection:(CGPoint) offset {
    if (lastContentOffset.x > offset.x)
        scrollDirection = RIGHT;
    else if (lastContentOffset.x < offset.x) 
        scrollDirection = LEFT;
    else if (lastContentOffset.y < offset.y) 
        scrollDirection = UP;
    else if (lastContentOffset.y > offset.y) 
        scrollDirection = DOWN;
    
    lastContentOffset = offset;
}


#pragma mark -
#pragma mark Layouting

- (void)layoutSubviews {
    if (_rotationInProgress)
        return;

    CGRect oldFrame = _scrollView.frame;
    CGRect newFrame = [self frameForScrollView];
    if (!CGRectEqualToRect(oldFrame, newFrame)) {
        // Strangely enough, if we do this assignment every time without the above
        // check, bouncing will behave incorrectly.
        _scrollView.frame = newFrame;
    }

    if (_horizontal) {
        if (oldFrame.size.width != 0 && _scrollView.frame.size.width != oldFrame.size.width) {
            // rotation is in progress, don't do any adjustments just yet
        } else if (oldFrame.size.height != _scrollView.frame.size.height) {
            // some other height change (the initial change from 0 to some specific size,   
            // or maybe an in-call status bar has appeared or disappeared)
            [self configurePages];
        }
    } else {
        if (oldFrame.size.height != 0 && _scrollView.frame.size.height != oldFrame.size.height) {
            // rotation is in progress, don't do any adjustments just yet
        } else if (oldFrame.size.width != _scrollView.frame.size.width) {
            // some other width change ?
            [self configurePages];
        }
    }
}

- (NSInteger)firstVisiblePageIndex {
    CGRect visibleBounds = _scrollView.bounds;
    if (_horizontal) {
        return MAX(floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds)), 0);
    } else {
        return MAX(floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds)), 0);
    }
}

- (NSInteger)lastVisiblePageIndex {
    CGRect visibleBounds = _scrollView.bounds;
    if (_horizontal) {
        return MIN(floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds)), _pageCount - 1);
    } else {
        return MIN(floorf((CGRectGetMaxY(visibleBounds)-1) / CGRectGetHeight(visibleBounds)), _pageCount - 1);
    }
}

- (NSInteger)firstLoadedPageIndex {
    return _firstLoadedPageIndex;
}

- (NSInteger)lastLoadedPageIndex {
    return _lastLoadedPageIndex;
}

- (CGRect)frameForScrollView {
    CGSize size = self.bounds.size;
    
    if (_horizontal) {
        return CGRectMake(-_gapBetweenPages/2, 0, size.width + _gapBetweenPages, size.height);
    } else {
        return CGRectMake(0, -_gapBetweenPages/2, size.width, size.height + _gapBetweenPages);
    }
    
//    CGRect rect;
//    
//    if (_horizontal) {
//        rect = CGRectMake(-_gapBetweenPages/2, 0, size.width + _gapBetweenPages, size.height);
//    } else {
//        rect = CGRectMake(0, -_gapBetweenPages/2, size.width, size.height + _gapBetweenPages);
//    }
//    
//    NSLog(@"(%@) frameForScrollView => %@", ((_isRootScroller)?@"root":@"node"), NSStringFromCGRect(rect));
//    
//    return rect;
}

// not public because this is in scroll view coordinates
- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidthWithGap = _scrollView.frame.size.width;
    CGFloat pageHeightWithGap = _scrollView.frame.size.height;
    CGSize pageSize = self.bounds.size;

    if (_horizontal) {
        return CGRectMake(pageWidthWithGap * index + _gapBetweenPages/2, 0, pageSize.width, pageSize.height);
    } else {
        return CGRectMake(0, pageHeightWithGap * index + _gapBetweenPages/2, pageSize.width, pageSize.height);
    }
    
//    CGRect rect;
//    
//    if (_horizontal) {
//        rect = CGRectMake(pageWidthWithGap * index + _gapBetweenPages/2, 0, pageSize.width, pageSize.height);
//    } else {
//        rect = CGRectMake(0, pageHeightWithGap * index + _gapBetweenPages/2, pageSize.width, pageSize.height);
//    }
//    
//    NSLog(@"(%@) frameForPageAtIndex:%d => %@", ((_isRootScroller)?@"root":@"node"), index, NSStringFromCGRect(rect));
//    
//    return rect;
}

-(void) scrollToPage:(int) index {
    [self setCurrentPageIndex:index Animated:NO];
}


#pragma mark -
#pragma mark Recycling

// It's the caller's responsibility to remove this page from _visiblePages,
// since this method is often called while traversing _visiblePages array.
- (void)recyclePage:(UIView *)page {
    if ([page respondsToSelector:@selector(prepareForReuse)]) {
        [(id)page prepareForReuse];
    }
    if (_recyclingEnabled) {
        [_recycledPages addObject:page];
    } else {
//#ifdef AT_PAGING_VIEW_TRACE_PAGE_LIFECYCLE
//        NSLog(@"(%@) Releasing page %d because recycling is disabled", ((_isRootScroller)?@"Root":@"Node"), page.tag);
//#endif
    }
    [page removeFromSuperview];
}

- (UIView *)dequeueReusablePage {
    UIView *result = [_recycledPages anyObject];
    if (result) {
        //[_recycledPages removeObject:[[result retain] autorelease]];
        [_recycledPages removeObject:result];
    }
    return result;
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_rotationInProgress)
        return;
    
    [self determineScrollDirection:scrollView.contentOffset];
    
    if(!_shouldScrollVertical && (scrollDirection == UP || scrollDirection == DOWN)) {
        [_scrollView setScrollEnabled:NO];
        [_scrollView setContentOffset:actualScreenOffset];
    } else {
        [_scrollView setScrollEnabled:YES];
    }
    
    [self configurePages];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self knownToBeMoving];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self knownToBeIdle];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self knownToBeIdle];
    [_scrollView setScrollEnabled:YES];
    actualScreenOffset = _scrollView.contentOffset;
}


#pragma mark -
#pragma mark Busy/Idle tracking

- (void)knownToBeMoving {
    if (!_scrollViewIsMoving) {
        _scrollViewIsMoving = YES;
        if ([_delegate respondsToSelector:@selector(pagingViewWillBeginMoving:)]) {
            [_delegate pagingViewWillBeginMoving:self];
        }
    }
}

- (void)knownToBeIdle {
    if (_scrollViewIsMoving) {
        _scrollViewIsMoving = NO;

        if (_pagesToPreload > 0) {
            // we didn't preload invisible pages during scrolling, so now is the time
            [self configurePages];
        }

        if ([_delegate respondsToSelector:@selector(pagingViewDidEndMoving:)]) {
            [_delegate pagingViewDidEndMoving:self];
        }
    }
}

@end

#pragma mark -

@implementation ATPagingViewController

@synthesize pagingView=_pagingView;


#pragma mark -
#pragma mark init/dealloc

//- (void)dealloc {
//    [_pagingView release], _pagingView = nil;
//    [super dealloc];
//}


#pragma mark -
#pragma mark View Loading

- (void)loadView {
    //self.view = self.pagingView = [[[ATPagingView alloc] init] autorelease];
    self.view = self.pagingView = [[ATPagingView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.pagingView.delegate == nil)
        self.pagingView.delegate = self;
}

- (ATPagingView *)pagingView {
    if (![self isViewLoaded]) {
        [self view];
    }
    return _pagingView;
}


#pragma mark Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    
//    NSLog(@"count: %d", self.pagingView.pageCount);
    
    if (self.pagingView.pageCount == 0)
        [self.pagingView reloadData];
}


#pragma mark -
#pragma mark Rotation


//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.pagingView willAnimateRotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.pagingView didRotate];
}


#pragma mark -
#pragma mark ATPagingViewDelegate methods

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
    return 0;
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
    return nil;
}

#pragma mark - methods

-(void) scrollToPage:(int) index {
    [self.pagingView scrollToPage:index];
}

@end
