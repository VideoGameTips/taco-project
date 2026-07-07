#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

@interface PixelCrabView : NSView
@property BOOL facingRight;
@property NSTimeInterval animationTime;
@property BOOL angry;
@property BOOL friendly;
@property BOOL sad;
@property BOOL nuclearAngry;
@property BOOL dead;
@property(copy) NSString *weaponSymbol;
@end

@implementation PixelCrabView
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, false);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);

    CGFloat bob = round(sin(self.animationTime * 9) * 2);
    CGFloat step = sin(self.animationTime * 13) > 0 ? 2 : 0;
    CGContextTranslateCTM(context, 0, bob);
    if (!self.facingRight) {
        CGContextTranslateCTM(context, self.bounds.size.width, 0);
        CGContextScaleCTM(context, -1, 1);
    }

    NSColor *orange = [NSColor colorWithCalibratedRed:0.86 green:0.38 blue:0.23 alpha:1];
    CGContextSetFillColorWithColor(context, orange.CGColor);
    CGContextFillRect(context, CGRectMake(32, 13 + step, 9, 29));
    CGContextFillRect(context, CGRectMake(48, 15 - step, 9, 29));
    CGContextFillRect(context, CGRectMake(65, 13 + step, 9, 29));
    CGContextFillRect(context, CGRectMake(82, 15 - step, 9, 29));
    CGContextFillRect(context, CGRectMake(24, 34, 72, 44));
    CGContextFillRect(context, CGRectMake(8, 47, 20, 15));
    CGContextFillRect(context, CGRectMake(92, 47, 20, 15));

    CGContextSetFillColorWithColor(context, [NSColor colorWithCalibratedWhite:0.08 alpha:1].CGColor);
    CGContextFillRect(context, CGRectMake(40, 64, 7, 7));
    CGContextFillRect(context, CGRectMake(76, 64, 7, 7));
    if (self.angry) {
        CGContextFillRect(context, CGRectMake(37, 73, 12, 3));
        CGContextFillRect(context, CGRectMake(74, 73, 12, 3));
    }
    if (self.sad) {
        CGContextSetFillColorWithColor(context, NSColor.systemBlueColor.CGColor);
        CGContextFillRect(context, CGRectMake(41, 55, 3, 8));
        CGContextFillRect(context, CGRectMake(79, 55, 3, 8));
    }
    CGContextRestoreGState(context);

    if (self.friendly) {
        [NSColor.systemPinkColor setFill];
        NSRectFill(NSMakeRect(54, 83, 6, 6));
        NSRectFill(NSMakeRect(62, 83, 6, 6));
        NSRectFill(NSMakeRect(57, 78, 8, 8));
    }
    if (self.weaponSymbol) {
        [self.weaponSymbol drawAtPoint:NSMakePoint(self.facingRight ? 91 : 5, 43)
                        withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:20]}];
    }
    if (self.nuclearAngry) {
        [@"☢️" drawAtPoint:NSMakePoint(49, 38)
             withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:19]}];
    }
    if (self.dead) {
        [@"💀" drawAtPoint:NSMakePoint(47, 48)
             withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:25]}];
    }
}
@end

@interface CrabPet : NSObject
@property(nonatomic, readonly) BOOL dragging;
@property(nonatomic, readonly) BOOL angry;
@property(nonatomic, readonly) BOOL friendly;
@property(nonatomic, readonly) BOOL sad;
@property(nonatomic, readonly) BOOL nuclearAngry;
@property(nonatomic, readonly) BOOL dead;
@property(nonatomic, copy) void (^deathHandler)(CrabPet *crab);
@property(nonatomic, readonly) BOOL wasFriendlyWhenGrabbed;
- (instancetype)initAtPoint:(NSPoint)point;
- (void)startWalking;
- (void)dismiss;
- (BOOL)containsPoint:(NSPoint)point;
- (CGFloat)distanceTo:(CrabPet *)other;
- (void)setFriendlyState:(BOOL)friendly;
- (void)beginDragAt:(NSPoint)point;
- (void)dragTo:(NSPoint)point;
- (void)endDragAt:(NSPoint)point;
- (void)becomeAngry;
- (void)becomeSad;
- (void)becomeNuclearAngry;
- (NSDictionary *)attackIfReadyAt:(NSTimeInterval)now;
@end

@implementation CrabPet {
    NSWindow *_window;
    PixelCrabView *_crabView;
    NSTimer *_timer;
    NSPoint _velocity;
    NSArray<NSValue *> *_platforms;
    NSTimeInterval _lastPlatformRefresh;
    NSRect _climbPlatform;
    BOOL _isClimbing;
    CGFloat _climbDirection;
    CGImageRef _latestScreenshot;
    BOOL _captureInFlight;
    NSPoint _dragOffset;
    NSPoint _lastDragPoint;
    NSPoint _dragVelocity;
    NSTimeInterval _lastDragTime;
    CGFloat _fallApex;
    NSTimeInterval _nextAttackTime;
    BOOL _dragging;
    BOOL _angry;
    BOOL _friendly;
    BOOL _sad;
    BOOL _nuclearAngry;
    BOOL _wasFriendlyWhenGrabbed;
    BOOL _dead;
    NSTimeInterval _lastUpdate;
    NSTimeInterval _nextTurn;
}

- (instancetype)initAtPoint:(NSPoint)point {
    self = [super init];
    if (self) {
        NSSize size = NSMakeSize(120, 100);
        NSRect frame = NSMakeRect(point.x - 60, point.y - 50, size.width, size.height);
        _window = [[NSWindow alloc] initWithContentRect:frame
                                             styleMask:NSWindowStyleMaskBorderless
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        _crabView = [[PixelCrabView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
        _crabView.facingRight = YES;
        CGFloat direction = arc4random_uniform(2) ? 1 : -1;
        _velocity = NSMakePoint(direction * [self randomFrom:45 to:75], 0);
        _platforms = @[];
        _fallApex = frame.origin.y + 13;
        _nextTurn = NSProcessInfo.processInfo.systemUptime + [self randomFrom:2 to:5];

        _window.opaque = NO;
        _window.backgroundColor = NSColor.clearColor;
        _window.hasShadow = NO;
        _window.ignoresMouseEvents = YES;
        _window.level = NSFloatingWindowLevel;
        _window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorFullScreenAuxiliary |
                                     NSWindowCollectionBehaviorStationary |
                                     NSWindowCollectionBehaviorIgnoresCycle;
        _window.contentView = _crabView;
        [_window orderFrontRegardless];
    }
    return self;
}

- (CGFloat)randomFrom:(CGFloat)minimum to:(CGFloat)maximum {
    return minimum + ((CGFloat)arc4random() / UINT32_MAX) * (maximum - minimum);
}

- (void)startWalking {
    _lastUpdate = NSProcessInfo.processInfo.systemUptime;
    __weak CrabPet *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:1.0 / 60.0 repeats:YES block:^(NSTimer *timer) {
        [weakSelf update];
    }];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)dismiss {
    [_timer invalidate];
    _timer = nil;
    [_window orderOut:nil];
}

- (BOOL)dragging { return _dragging; }
- (BOOL)angry { return _angry; }
- (BOOL)friendly { return _friendly; }
- (BOOL)sad { return _sad; }
- (BOOL)nuclearAngry { return _nuclearAngry; }
- (BOOL)dead { return _dead; }
- (BOOL)wasFriendlyWhenGrabbed { return _wasFriendlyWhenGrabbed; }

- (BOOL)containsPoint:(NSPoint)point {
    return !_dead && NSPointInRect(point, NSInsetRect(_window.frame, 12, 8));
}

- (CGFloat)distanceTo:(CrabPet *)other {
    NSPoint a = NSMakePoint(NSMidX(_window.frame), NSMidY(_window.frame));
    NSPoint b = NSMakePoint(NSMidX(other->_window.frame), NSMidY(other->_window.frame));
    return hypot(a.x - b.x, a.y - b.y);
}

- (void)setFriendlyState:(BOOL)friendly {
    if (_angry || _sad) return;
    _friendly = friendly;
    _crabView.friendly = friendly;
    _crabView.needsDisplay = YES;
}

- (void)beginDragAt:(NSPoint)point {
    _dragging = YES;
    _wasFriendlyWhenGrabbed = _friendly;
    _dragOffset = NSMakePoint(point.x - NSMinX(_window.frame), point.y - NSMinY(_window.frame));
    _lastDragPoint = point;
    _lastDragTime = NSProcessInfo.processInfo.systemUptime;
    _dragVelocity = NSZeroPoint;
    _velocity = NSZeroPoint;
    _isClimbing = NO;
    [_window orderFrontRegardless];
}

- (void)dragTo:(NSPoint)point {
    if (!_dragging) return;
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    NSTimeInterval elapsed = MAX(now - _lastDragTime, 1.0 / 120.0);
    _dragVelocity = NSMakePoint(
        (point.x - _lastDragPoint.x) / elapsed,
        (point.y - _lastDragPoint.y) / elapsed
    );
    [_window setFrameOrigin:NSMakePoint(point.x - _dragOffset.x, point.y - _dragOffset.y)];
    _lastDragPoint = point;
    _lastDragTime = now;
}

- (void)endDragAt:(NSPoint)point {
    if (!_dragging) return;
    [self dragTo:point];
    _dragging = NO;
    _velocity = NSMakePoint(
        MAX(-520, MIN(520, _dragVelocity.x)),
        MAX(-520, MIN(520, _dragVelocity.y))
    );
    _fallApex = NSMinY(_window.frame) + 13;
}

- (void)becomeAngry {
    if (_dead) return;
    _angry = YES;
    _sad = NO;
    _friendly = NO;
    _crabView.angry = YES;
    _crabView.sad = NO;
    _crabView.friendly = NO;
    _nextAttackTime = NSProcessInfo.processInfo.systemUptime + 0.3;
    _crabView.needsDisplay = YES;
}

- (void)becomeSad {
    if (_dead) return;
    _sad = YES;
    _angry = NO;
    _nuclearAngry = NO;
    _friendly = NO;
    _velocity.x *= 0.22;
    _crabView.sad = YES;
    _crabView.angry = NO;
    _crabView.friendly = NO;
    _crabView.nuclearAngry = NO;
    _crabView.weaponSymbol = nil;
    _crabView.needsDisplay = YES;
}

- (void)becomeNuclearAngry {
    if (_dead) return;
    [self becomeAngry];
    _nuclearAngry = YES;
    _crabView.nuclearAngry = YES;
    _nextAttackTime = NSProcessInfo.processInfo.systemUptime + 0.15;
}

- (NSDictionary *)attackIfReadyAt:(NSTimeInterval)now {
    if (!_angry || _dragging || now < _nextAttackTime) return nil;
    _nextAttackTime = now + (_nuclearAngry
        ? [self randomFrom:0.28 to:0.62]
        : [self randomFrom:0.65 to:1.45]);
    if (_nuclearAngry) {
        _crabView.weaponSymbol = @"☢️";
        _crabView.needsDisplay = YES;
        return @{
            @"origin": [NSValue valueWithPoint:NSMakePoint(NSMidX(_window.frame), NSMidY(_window.frame))],
            @"symbol": @"☢️"
        };
    }
    NSArray *symbols = @[@"🚀", @"💣", @"🍅", @"🔧", @"🥾", @"💥"];
    NSArray *weapons = @[@"🔫", @"🧨", @"🚀"];
    NSString *symbol = symbols[arc4random_uniform((uint32_t)symbols.count)];
    _crabView.weaponSymbol = weapons[arc4random_uniform((uint32_t)weapons.count)];
    _crabView.needsDisplay = YES;
    __weak PixelCrabView *weakView = _crabView;
    [NSTimer scheduledTimerWithTimeInterval:0.22 repeats:NO block:^(NSTimer *timer) {
        weakView.weaponSymbol = nil;
        weakView.needsDisplay = YES;
    }];
    return @{
        @"origin": [NSValue valueWithPoint:NSMakePoint(NSMidX(_window.frame), NSMidY(_window.frame))],
        @"symbol": symbol
    };
}

- (NSRect)screenBoundsForFrame:(NSRect)frame {
    NSPoint center = NSMakePoint(NSMidX(frame), NSMidY(frame));
    for (NSScreen *screen in NSScreen.screens) {
        if (NSPointInRect(center, screen.frame)) return screen.visibleFrame;
    }
    return NSScreen.mainScreen ? NSScreen.mainScreen.visibleFrame : NSMakeRect(0, 0, 1440, 900);
}

- (void)update {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    NSTimeInterval elapsed = MIN(now - _lastUpdate, 0.05);
    _lastUpdate = now;
    if (_dead) return;
    if (_dragging) {
        _crabView.animationTime = now;
        _crabView.needsDisplay = YES;
        return;
    }

    if (now >= _nextTurn) {
        _velocity.x += [self randomFrom:-12 to:12];
        CGFloat direction = _velocity.x < 0 ? -1 : 1;
        _velocity.x = direction * MAX(42, MIN(fabs(_velocity.x), 78));
        _nextTurn = now + [self randomFrom:2 to:5];
    }

    NSRect frame = _window.frame;
    NSRect bounds = [self screenBoundsForFrame:frame];
    [self refreshPlatformsIfNeeded:now];

    if (_isClimbing) {
        frame.origin.x = _climbDirection > 0
            ? NSMinX(_climbPlatform) - 96
            : NSMaxX(_climbPlatform) - 24;
        frame.origin.y += 72 * elapsed;

        if (frame.origin.y + 13 >= NSMaxY(_climbPlatform)) {
            frame.origin.y = NSMaxY(_climbPlatform) - 13;
            frame.origin.x = _climbDirection > 0
                ? NSMinX(_climbPlatform) - 34
                : NSMaxX(_climbPlatform) - 87;
            _isClimbing = NO;
            _velocity.y = 0;
        }
    } else {
        NSRect oldFrame = frame;
        CGFloat proposedX = frame.origin.x + _velocity.x * elapsed;
        NSRect wall;
        if ([self wallHitFrom:oldFrame proposedX:proposedX result:&wall]) {
            _climbPlatform = wall;
            _climbDirection = _velocity.x < 0 ? -1 : 1;
            _isClimbing = YES;
            _velocity.y = 0;
        } else {
            frame.origin.x = proposedX;
            _velocity.y -= 900 * elapsed;
            frame.origin.y += _velocity.y * elapsed;
            _fallApex = MAX(_fallApex, frame.origin.y + 13);
            [self landFrame:&frame previousFrame:oldFrame];
        }
    }

    if (NSMinX(frame) <= NSMinX(bounds)) {
        frame.origin.x = NSMinX(bounds);
        _velocity.x = fabs(_velocity.x);
    } else if (NSMaxX(frame) >= NSMaxX(bounds)) {
        frame.origin.x = NSMaxX(bounds) - frame.size.width;
        _velocity.x = -fabs(_velocity.x);
    }
    if (frame.origin.y + 13 <= NSMinY(bounds)) {
        [self registerLandingAt:NSMinY(bounds)];
        frame.origin.y = NSMinY(bounds) - 13;
        _velocity.y = 0;
    }

    [_window setFrameOrigin:frame.origin];
    _crabView.facingRight = _velocity.x >= 0;
    _crabView.animationTime = now;
    _crabView.needsDisplay = YES;
}

- (void)landFrame:(NSRect *)frame previousFrame:(NSRect)previousFrame {
    if (_velocity.y > 0) return;
    CGFloat previousFeet = previousFrame.origin.y + 13;
    CGFloat nextFeet = frame->origin.y + 13;
    CGFloat footLeft = frame->origin.x + 32;
    CGFloat footRight = frame->origin.x + 91;
    CGFloat bestTop = -CGFLOAT_MAX;

    for (NSValue *value in _platforms) {
        NSRect platform = value.rectValue;
        CGFloat top = NSMaxY(platform);
        if ((previousFeet >= top - 1 ||
             (NSMaxY(previousFrame) >= top && previousFeet < top)) &&
            nextFeet <= top &&
            footRight >= NSMinX(platform) &&
            footLeft <= NSMaxX(platform)) {
            bestTop = MAX(bestTop, top);
        }
    }

    if (bestTop > -CGFLOAT_MAX) {
        [self registerLandingAt:bestTop];
        frame->origin.y = bestTop - 13;
        _velocity.y = 0;
    }
}

- (void)registerLandingAt:(CGFloat)height {
    CGFloat fallDistance = _fallApex - height;
    if (fallDistance > 520) {
        [self die];
    } else if (fallDistance > 240) {
        [self becomeAngry];
    }
    _fallApex = height;
}

- (void)die {
    if (_dead) return;
    _dead = YES;
    _dragging = NO;
    _angry = NO;
    _friendly = NO;
    _velocity = NSZeroPoint;
    _crabView.dead = YES;
    _crabView.angry = NO;
    _crabView.friendly = NO;
    _crabView.sad = NO;
    _crabView.weaponSymbol = nil;
    _crabView.needsDisplay = YES;
    __weak CrabPet *weakSelf = self;
    [NSTimer scheduledTimerWithTimeInterval:0.9 repeats:NO block:^(NSTimer *timer) {
        CrabPet *strongSelf = weakSelf;
        if (strongSelf.deathHandler) strongSelf.deathHandler(strongSelf);
    }];
}

- (BOOL)wallHitFrom:(NSRect)frame proposedX:(CGFloat)proposedX result:(NSRect *)result {
    CGFloat bodyBottom = frame.origin.y + 15;
    CGFloat bodyTop = frame.origin.y + 78;
    BOOL found = NO;
    CGFloat closest = _velocity.x > 0 ? CGFLOAT_MAX : -CGFLOAT_MAX;

    for (NSValue *value in _platforms) {
        NSRect platform = value.rectValue;
        if (!(bodyTop > NSMinY(platform) && bodyBottom < NSMaxY(platform) - 2)) continue;

        if (_velocity.x > 0) {
            CGFloat oldEdge = frame.origin.x + 96;
            CGFloat newEdge = proposedX + 96;
            if (oldEdge <= NSMinX(platform) + 2 &&
                newEdge >= NSMinX(platform) &&
                NSMinX(platform) < closest) {
                closest = NSMinX(platform);
                *result = platform;
                found = YES;
            }
        } else {
            CGFloat oldEdge = frame.origin.x + 24;
            CGFloat newEdge = proposedX + 24;
            if (oldEdge >= NSMaxX(platform) - 2 &&
                newEdge <= NSMaxX(platform) &&
                NSMaxX(platform) > closest) {
                closest = NSMaxX(platform);
                *result = platform;
                found = YES;
            }
        }
    }
    return found;
}

- (void)refreshPlatformsIfNeeded:(NSTimeInterval)now {
    if (now - _lastPlatformRefresh < 0.5) return;
    _lastPlatformRefresh = now;

    CFArrayRef rawInfo = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
        kCGNullWindowID
    );
    NSArray *windowInfo = CFBridgingRelease(rawInfo);
    NSMutableArray<NSValue *> *result = [NSMutableArray array];
    pid_t ownPID = NSProcessInfo.processInfo.processIdentifier;
    CGFloat mainScreenTop = NSScreen.mainScreen ? NSMaxY(NSScreen.mainScreen.frame) : 0;

    for (NSDictionary *info in windowInfo) {
        if ([info[(id)kCGWindowOwnerPID] intValue] == ownPID) continue;
        if ([info[(id)kCGWindowLayer] intValue] != 0) continue;
        if (info[(id)kCGWindowAlpha] && [info[(id)kCGWindowAlpha] doubleValue] <= 0.05) continue;

        CGRect cgRect;
        if (!CGRectMakeWithDictionaryRepresentation(
                (__bridge CFDictionaryRef)info[(id)kCGWindowBounds], &cgRect)) continue;
        if (cgRect.size.width <= 100 || cgRect.size.height <= 40) continue;

        NSRect platform = NSMakeRect(
            cgRect.origin.x,
            mainScreenTop - CGRectGetMaxY(cgRect),
            cgRect.size.width,
            cgRect.size.height
        );
        [result addObject:[NSValue valueWithRect:platform]];
    }

    if (AXIsProcessTrusted()) {
        NSRunningApplication *frontmost = NSWorkspace.sharedWorkspace.frontmostApplication;
        if (frontmost && frontmost.processIdentifier != ownPID) {
            AXUIElementRef application = AXUIElementCreateApplication(frontmost.processIdentifier);
            NSInteger count = 0;
            [self collectPlatformsFromElement:application
                                        depth:0
                                        count:&count
                                         into:result
                                mainScreenTop:mainScreenTop];
            CFRelease(application);
        }
    }
    _platforms = [self visiblyRenderedPlatforms:result mainScreenTop:mainScreenTop];
}

- (NSArray<NSValue *> *)visiblyRenderedPlatforms:(NSArray<NSValue *> *)candidates
                                    mainScreenTop:(CGFloat)mainScreenTop {
    if (!CGPreflightScreenCaptureAccess()) return @[];

    CGRect captureBounds = CGDisplayBounds(CGMainDisplayID());
    [self requestScreenshotForBounds:captureBounds];
    CGImageRef image = _latestScreenshot;
    if (!image || CGImageGetBitsPerPixel(image) != 32) return @[];

    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const UInt8 *bytes = CFDataGetBytePtr(pixelData);
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    NSMutableArray<NSValue *> *visible = [NSMutableArray array];

    for (NSValue *value in candidates) {
        NSRect platform = value.rectValue;
        CGFloat cgTop = mainScreenTop - NSMaxY(platform);
        if (NSMinX(platform) < CGRectGetMinX(captureBounds) ||
            NSMaxX(platform) > CGRectGetMaxX(captureBounds) ||
            cgTop < CGRectGetMinY(captureBounds) + 4 ||
            cgTop > CGRectGetMaxY(captureBounds) - 4) {
            continue;
        }

        NSInteger samples = 28;
        NSInteger edgeSamples = 0;
        CGFloat inset = MIN(10, platform.size.width * 0.08);
        for (NSInteger index = 0; index < samples; index++) {
            CGFloat fraction = (index + 0.5) / samples;
            CGFloat screenX = NSMinX(platform) + inset +
                fraction * MAX(1, platform.size.width - inset * 2);
            NSInteger pixelX = (NSInteger)round(
                (screenX - CGRectGetMinX(captureBounds)) /
                captureBounds.size.width * (width - 1)
            );
            NSInteger centerY = (NSInteger)round(
                (cgTop - CGRectGetMinY(captureBounds)) /
                captureBounds.size.height * (height - 1)
            );
            NSInteger aboveY = MAX(0, centerY - 3);
            NSInteger belowY = MIN((NSInteger)height - 1, centerY + 3);
            const UInt8 *above = bytes + aboveY * bytesPerRow + pixelX * 4;
            const UInt8 *below = bytes + belowY * bytesPerRow + pixelX * 4;
            NSInteger difference =
                labs((long)above[0] - below[0]) +
                labs((long)above[1] - below[1]) +
                labs((long)above[2] - below[2]);
            if (difference >= 36) edgeSamples++;
        }

        if (edgeSamples >= 6) [visible addObject:value];
    }

    CFRelease(pixelData);
    return visible;
}

- (void)requestScreenshotForBounds:(CGRect)bounds {
    if (_captureInFlight) return;
    if (@available(macOS 15.2, *)) {
        _captureInFlight = YES;
        __weak CrabPet *weakSelf = self;
        [SCScreenshotManager captureImageInRect:bounds
                              completionHandler:^(CGImageRef image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CrabPet *strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf->_captureInFlight = NO;
                if (image) {
                    if (strongSelf->_latestScreenshot) {
                        CGImageRelease(strongSelf->_latestScreenshot);
                    }
                    strongSelf->_latestScreenshot = CGImageRetain(image);
                }
            });
        }];
    }
}

- (void)dealloc {
    if (_latestScreenshot) CGImageRelease(_latestScreenshot);
}

- (void)collectPlatformsFromElement:(AXUIElementRef)element
                              depth:(NSInteger)depth
                              count:(NSInteger *)count
                               into:(NSMutableArray<NSValue *> *)result
                      mainScreenTop:(CGFloat)mainScreenTop {
    if (depth > 9 || *count > 700) return;
    (*count)++;

    CFTypeRef roleValue = NULL;
    NSString *role = nil;
    if (AXUIElementCopyAttributeValue(element, kAXRoleAttribute, &roleValue) == kAXErrorSuccess) {
        role = CFBridgingRelease(roleValue);
    }

    NSSet<NSString *> *platformRoles = [NSSet setWithArray:@[
        (__bridge NSString *)kAXTextAreaRole,
        (__bridge NSString *)kAXTextFieldRole,
        (__bridge NSString *)kAXScrollAreaRole
    ]];

    if ([platformRoles containsObject:role]) {
        CFTypeRef positionValue = NULL;
        CFTypeRef sizeValue = NULL;
        if (AXUIElementCopyAttributeValue(element, kAXPositionAttribute, &positionValue) == kAXErrorSuccess &&
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute, &sizeValue) == kAXErrorSuccess &&
            positionValue && sizeValue &&
            CFGetTypeID(positionValue) == AXValueGetTypeID() &&
            CFGetTypeID(sizeValue) == AXValueGetTypeID()) {
            CGPoint position;
            CGSize size;
            if (AXValueGetValue((AXValueRef)positionValue, kAXValueCGPointType, &position) &&
                AXValueGetValue((AXValueRef)sizeValue, kAXValueCGSizeType, &size) &&
                size.width > 120 && size.height > 35 && size.height < 650) {
                NSRect platform = NSMakeRect(
                    position.x,
                    mainScreenTop - position.y - size.height,
                    size.width,
                    size.height
                );
                [result addObject:[NSValue valueWithRect:platform]];
            }
        }
        if (positionValue) CFRelease(positionValue);
        if (sizeValue) CFRelease(sizeValue);
    }

    CFTypeRef childrenValue = NULL;
    if (AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, &childrenValue) == kAXErrorSuccess &&
        childrenValue && CFGetTypeID(childrenValue) == CFArrayGetTypeID()) {
        NSArray *children = CFBridgingRelease(childrenValue);
        for (id child in children) {
            [self collectPlatformsFromElement:(__bridge AXUIElementRef)child
                                        depth:depth + 1
                                        count:count
                                         into:result
                                mainScreenTop:mainScreenTop];
            if (*count > 700) break;
        }
    } else if (childrenValue) {
        CFRelease(childrenValue);
    }
}
@end

@interface CursorProjectile : NSObject
@property(nonatomic, readonly) NSUUID *identifier;
- (instancetype)initAt:(NSPoint)origin
                 target:(NSPoint)target
                 symbol:(NSString *)symbol
             completion:(void (^)(NSUUID *identifier))completion;
- (void)start;
- (void)dismiss;
@end

@implementation CursorProjectile {
    NSWindow *_window;
    NSPoint _velocity;
    NSTimer *_timer;
    NSTimeInterval _lastUpdate;
    NSTimeInterval _lifetime;
    void (^_completion)(NSUUID *);
}

- (instancetype)initAt:(NSPoint)origin
                 target:(NSPoint)target
                 symbol:(NSString *)symbol
             completion:(void (^)(NSUUID *))completion {
    self = [super init];
    if (self) {
        _identifier = [NSUUID UUID];
        _completion = [completion copy];
        NSSize size = NSMakeSize(38, 38);
        _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(
            origin.x - 19, origin.y - 19, size.width, size.height
        ) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        NSTextField *label = [NSTextField labelWithString:symbol];
        label.font = [NSFont systemFontOfSize:[symbol isEqualToString:@"☢️"] ? 31 : 24];
        label.alignment = NSTextAlignmentCenter;
        label.frame = NSMakeRect(0, 0, size.width, size.height);
        _window.contentView = label;
        _window.opaque = NO;
        _window.backgroundColor = NSColor.clearColor;
        _window.hasShadow = NO;
        _window.ignoresMouseEvents = YES;
        _window.level = NSScreenSaverWindowLevel;
        _window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorFullScreenAuxiliary;

        CGFloat dx = target.x - origin.x;
        CGFloat dy = target.y - origin.y;
        CGFloat distance = MAX(1, hypot(dx, dy));
        CGFloat speed = [symbol isEqualToString:@"🚀"] ? 360 :
            ([symbol isEqualToString:@"☢️"] ? 230 : 270);
        _velocity = NSMakePoint(dx / distance * speed, dy / distance * speed);
        if ([symbol isEqualToString:@"💣"] || [symbol isEqualToString:@"☢️"]) {
            _velocity.y += 190;
        }
    }
    return self;
}

- (void)start {
    [_window orderFrontRegardless];
    _lastUpdate = NSProcessInfo.processInfo.systemUptime;
    __weak CursorProjectile *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:1.0 / 60.0 repeats:YES block:^(NSTimer *timer) {
        [weakSelf update];
    }];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)dismiss {
    [_timer invalidate];
    _timer = nil;
    [_window orderOut:nil];
}

- (void)update {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    NSTimeInterval elapsed = MIN(now - _lastUpdate, 0.05);
    _lastUpdate = now;
    _lifetime += elapsed;
    if (_lifetime > 4) {
        [self dismiss];
        if (_completion) _completion(_identifier);
        return;
    }
    NSPoint origin = _window.frame.origin;
    origin.x += _velocity.x * elapsed;
    origin.y += _velocity.y * elapsed;
    _velocity.y -= 90 * elapsed;
    [_window setFrameOrigin:origin];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate {
    NSMutableArray<CrabPet *> *_crabs;
    NSMutableDictionary<NSUUID *, CursorProjectile *> *_projectiles;
    CrabPet *_draggedCrab;
    NSTimer *_behaviorTimer;
    NSStatusItem *_statusItem;
    id _globalMonitor;
    id _localMonitor;
    NSInteger _clickCount;
    NSTimeInterval _lastClickTime;
    NSPoint _lastClickPoint;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    _crabs = [NSMutableArray array];
    _projectiles = [NSMutableDictionary dictionary];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self installStatusItem];

    NSDictionary *accessibilityOptions = @{
        (__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES
    };
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)accessibilityOptions);
    if (!CGPreflightScreenCaptureAccess()) {
        CGRequestScreenCaptureAccess();
    }

    __weak AppDelegate *weakSelf = self;
    NSEventMask interactionMask = NSEventMaskLeftMouseDown |
                                  NSEventMaskLeftMouseDragged |
                                  NSEventMaskLeftMouseUp |
                                  NSEventMaskRightMouseDown;
    _globalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:interactionMask
                                                            handler:^(NSEvent *event) {
        [weakSelf handlePointerEvent:event];
    }];
    _localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:interactionMask
                                                          handler:^NSEvent *(NSEvent *event) {
        [weakSelf handlePointerEvent:event];
        return event;
    }];
    _behaviorTimer = [NSTimer timerWithTimeInterval:0.35 repeats:YES block:^(NSTimer *timer) {
        [weakSelf updateBehavior];
    }];
    [NSRunLoop.mainRunLoop addTimer:_behaviorTimer forMode:NSRunLoopCommonModes];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [_behaviorTimer invalidate];
    if (_globalMonitor) [NSEvent removeMonitor:_globalMonitor];
    if (_localMonitor) [NSEvent removeMonitor:_localMonitor];
}

- (void)handlePointerEvent:(NSEvent *)event {
    NSPoint point = NSEvent.mouseLocation;
    if (event.type == NSEventTypeRightMouseDown) {
        [self deleteCrabAt:point];
        return;
    }
    if (event.type == NSEventTypeLeftMouseDragged) {
        [_draggedCrab dragTo:point];
        return;
    }
    if (event.type == NSEventTypeLeftMouseUp) {
        CrabPet *released = _draggedCrab;
        [released endDragAt:point];
        _draggedCrab = nil;
        if (released.wasFriendlyWhenGrabbed) {
            BOOL friendNearby = NO;
            for (CrabPet *other in _crabs) {
                if (other != released && [released distanceTo:other] < 230) {
                    friendNearby = YES;
                    break;
                }
            }
            if (!friendNearby) [released becomeAngry];
        }
        return;
    }
    if (event.type != NSEventTypeLeftMouseDown) return;

    for (CrabPet *crab in _crabs.reverseObjectEnumerator) {
        if ([crab containsPoint:point]) {
            _draggedCrab = crab;
            [crab beginDragAt:point];
            break;
        }
    }

    CGFloat distance = hypot(point.x - _lastClickPoint.x, point.y - _lastClickPoint.y);
    if (_clickCount > 0 && event.timestamp - _lastClickTime <= 0.48 && distance <= 28) {
        _clickCount++;
    } else {
        _clickCount = 1;
    }
    _lastClickTime = event.timestamp;
    _lastClickPoint = point;

    if (_clickCount == 3) {
        _clickCount = 0;
        [self summonAt:point];
    }
}

- (void)deleteCrabAt:(NSPoint)point {
    CrabPet *deleted = nil;
    for (CrabPet *crab in _crabs.reverseObjectEnumerator) {
        if ([crab containsPoint:point]) {
            deleted = crab;
            break;
        }
    }
    if (!deleted) return;

    NSMutableArray<CrabPet *> *friends = [NSMutableArray array];
    for (CrabPet *other in _crabs) {
        if (other != deleted && other.friendly && [deleted distanceTo:other] < 180) {
            [friends addObject:other];
        }
    }

    if (_draggedCrab == deleted) _draggedCrab = nil;
    [deleted dismiss];
    [_crabs removeObject:deleted];
    for (CrabPet *friend in friends) {
        if (arc4random_uniform(2)) {
            [friend becomeSad];
        } else {
            [friend becomeNuclearAngry];
        }
    }
}

- (void)updateBehavior {
    for (CrabPet *crab in _crabs) {
        if (crab.angry || crab.dragging) continue;
        BOOL hasFriend = NO;
        for (CrabPet *other in _crabs) {
            if (other != crab && !other.dragging && [crab distanceTo:other] < 145) {
                hasFriend = YES;
                break;
            }
        }
        [crab setFriendlyState:hasFriend];
    }

    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    for (CrabPet *crab in _crabs) {
        NSDictionary *attack = [crab attackIfReadyAt:now];
        if (!attack) continue;
        __weak AppDelegate *weakSelf = self;
        CursorProjectile *projectile = [[CursorProjectile alloc]
            initAt:[attack[@"origin"] pointValue]
            target:NSEvent.mouseLocation
            symbol:attack[@"symbol"]
            completion:^(NSUUID *identifier) {
                AppDelegate *strongSelf = weakSelf;
                [strongSelf->_projectiles removeObjectForKey:identifier];
            }];
        _projectiles[projectile.identifier] = projectile;
        [projectile start];
    }
}

- (void)summonAt:(NSPoint)point {
    CrabPet *crab = [[CrabPet alloc] initAtPoint:point];
    __weak AppDelegate *weakSelf = self;
    crab.deathHandler = ^(CrabPet *deadCrab) {
        AppDelegate *strongSelf = weakSelf;
        if (strongSelf->_draggedCrab == deadCrab) strongSelf->_draggedCrab = nil;
        [deadCrab dismiss];
        [strongSelf->_crabs removeObject:deadCrab];
    };
    [_crabs addObject:crab];
    [crab startWalking];
}

- (void)installStatusItem {
    _statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    _statusItem.button.title = @"🦀";
    _statusItem.button.toolTip = @"Claude Crab";

    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *hint = [[NSMenuItem alloc] initWithTitle:@"Triple-click anywhere to summon"
                                                  action:nil keyEquivalent:@""];
    hint.enabled = NO;
    [menu addItem:hint];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Summon Crab" action:@selector(summonFromMenu:) keyEquivalent:@"n"].target = self;
    [menu addItemWithTitle:@"Clear All Crabs" action:@selector(clearCrabs:) keyEquivalent:@"k"].target = self;
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Quit Claude Crab" action:@selector(quit:) keyEquivalent:@"q"].target = self;
    _statusItem.menu = menu;
}

- (void)summonFromMenu:(id)sender { [self summonAt:NSEvent.mouseLocation]; }
- (void)clearCrabs:(id)sender {
    for (CrabPet *crab in _crabs) [crab dismiss];
    [_crabs removeAllObjects];
    for (CursorProjectile *projectile in _projectiles.allValues) [projectile dismiss];
    [_projectiles removeAllObjects];
}
- (void)quit:(id)sender { [NSApp terminate:nil]; }
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
