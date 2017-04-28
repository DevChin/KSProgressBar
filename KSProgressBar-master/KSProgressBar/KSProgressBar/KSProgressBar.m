//
//  KSProgressBar.m
//  KSProgressBar
//
//  Created by DouQu on 17/4/25.
//  Copyright © 2017年 Chipen. All rights reserved.
//

#import "KSProgressBar.h"

#define force_line __inline__ __attribute__((always_inline))
#define ROTATEFORAWEEKTIME 2.0  //rotate for a week time

@interface KSProgressBar ()
{
    @private
    /*
     drawing timer
     */
    NSTimer* _drawTimer;
    /*
     rotate timer
     */
    NSTimer* _rotateTimer;
    /*
     ＊  be added to _rotateAnimationView
     ＊  ready to draw path on this layer to showing progress
     */
    CAShapeLayer* _drawPathLayer;
    /*
     current progress angle
     */
    double _currentAngle;
    /*
     the original progress
     */
    double _originalDrawAngle;
    /*
     *  the view will be animationing
     *  used to rotate view
     */
    UIView* _rotateAnimationView;
    /*
     check the Animation weather finished
     */
    BOOL _animationFinished;
    /*
     *
     *  heavy here slowy Began slow down the drawing
     *
     */
    double _beginReduceAngle;
    /*
     time of begin reduce
     */
    double _beginReduceTime;
    /*
     speed of begin reduce
     */
    double _beginReduceSpeed;
    /*
     the last angle
     */
    double _beforeAngle;
}
@end

@implementation KSProgressBar

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _color = [UIColor blueColor];
        _lineWidth  = 10.0f;
        [self _setUp];
    }
    return self;
}

- (void) _setUp {
    
    _rotateAnimationView = [[UIView alloc] initWithFrame:self.bounds];
    _rotateAnimationView.backgroundColor=[UIColor clearColor];
    [self addSubview:_rotateAnimationView];

    CAShapeLayer * layer = [[CAShapeLayer alloc] init];
    layer.frame = self.bounds;
    layer.lineWidth = _lineWidth;
    layer.strokeColor = _color.CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    [_rotateAnimationView.layer addSublayer:layer];
    _drawPathLayer = layer;
    
    //开始旋转
    _rotateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(_rotate) userInfo:nil repeats:YES];
    [_rotateTimer fire];
    [[NSRunLoop currentRunLoop] addTimer:_rotateTimer forMode:NSRunLoopCommonModes];
    
    [self _increaseProgressTimer];
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    _drawPathLayer.lineWidth = _lineWidth;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    _drawPathLayer.strokeColor = _color.CGColor;
}

- (void) _rotate {
    static double currentTime = 0;
    /*
     begin timer ...
     */
    currentTime+=(1.0/60/ROTATEFORAWEEKTIME);
    _rotateAnimationView.transform = CGAffineTransformMakeRotation(M_PI*2*currentTime);
}

- (void) _increaseProgressTimer {
    _drawTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/180 target:self selector:@selector(_increaseProgress) userInfo:nil repeats:YES];
    [_drawTimer fire];
    [[NSRunLoop currentRunLoop] addTimer:_drawTimer forMode:NSRunLoopCommonModes];
}

- (void) _increaseProgress {
    
    static double currentTime = 0;

    /*
     begin timer ...
     */
    currentTime+=(1.0/140);
    CGPathRef pathRef = [self pathForTimeInterval:currentTime andType:0];
    if (pathRef)
        _drawPathLayer.path = pathRef;
    //如果角度达到了 就结束
    if (_animationFinished) {
        //cancel timer
        currentTime = 0;
        [_drawTimer invalidate];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _animationFinished = NO;
            [self _reduceProgressTimer];
        });
    }
}

/*
 get angle increment with timeInterval
 */

static force_line double getIncreamentAngle(double timeInterval) {
    double angel = M_PI_2 * 3 * 1.0 / 1.0;
    return timeInterval*angel*0.01;
}

static force_line CGPoint Center (UIView* view) {
    return CGPointMake(view.frame.size.width/2,view.frame.size.height/2);
}

- (CGPathRef)pathForTimeInterval:(double)timeInterval andType:(int)type {
    
    double angel = M_PI_2 * 3 * 1.0 / 1.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (type == 0) {
        [path moveToPoint:[self getPointWithAngel:_currentAngle]];
        //如果小于整个进度的0.1 那就是要预先绘制 防止出现绘制的时候 突变(突然变长)
        if (timeInterval*angel < angel*0.1 && _originalDrawAngle > 0) {
            [path addArcWithCenter:Center(self) radius:self.frame.size.width/2 startAngle:_currentAngle endAngle:_currentAngle + angel*0.1 clockwise:YES];
        }else{
            //变长
            if (timeInterval*angel + getIncreamentAngle(timeInterval) >= angel*0.9) {
                if (_currentAngle+_beginReduceAngle + _beginReduceSpeed/2*(timeInterval - _beginReduceTime) >= angel) {
                    //慢慢减速
                    [path addArcWithCenter:Center(self) radius:self.frame.size.width/2 startAngle:_currentAngle endAngle:_currentAngle + (_beginReduceAngle + _beginReduceSpeed/2*(timeInterval - _beginReduceTime)) clockwise:YES];
                    _currentAngle += ((_beginReduceAngle + _beginReduceSpeed/2*(timeInterval - _beginReduceTime)));
                    _beforeAngle = _beginReduceAngle + _beginReduceSpeed/2*(timeInterval - _beginReduceTime);
                    _animationFinished = YES;
                    _beginReduceAngle = 0;
                    _beginReduceTime = 0;
                    return path.CGPath;
                    
                }else{
                    //在0.5秒内速度减为0
                    //匀减速运动
                    /*
                     S = (v1 + v2) * t / 2;
                     */
                    //慢慢减速
                    [path addArcWithCenter:Center(self) radius:self.frame.size.width/2 startAngle:_currentAngle endAngle:_currentAngle+_beginReduceAngle + _beginReduceSpeed/2*(timeInterval - _beginReduceTime)  clockwise:YES];
                }
            }else {
                [path addArcWithCenter:Center(self) radius:self.frame.size.width/2 startAngle:_currentAngle endAngle:_currentAngle+timeInterval*angel + getIncreamentAngle(timeInterval) clockwise:YES];
                _beginReduceSpeed = (1.0/140*angel + getIncreamentAngle(timeInterval)) / (1.0/140);
                _beginReduceAngle = timeInterval*angel + getIncreamentAngle(timeInterval);
                _beginReduceTime = timeInterval;
            }
        }
    }else{
        
        //不让进度条 完全消失
        //if (timeInterval >= 0.9)
        //timeInterval = 0.9;
        
        [path moveToPoint:[self getPointWithAngel:_currentAngle - _beforeAngle + angel*timeInterval + getIncreamentAngle(timeInterval)]];
        //变短
        [path addArcWithCenter:Center(self) radius:self.frame.size.width/2 startAngle:_currentAngle - _beforeAngle + angel*timeInterval + getIncreamentAngle(timeInterval) endAngle:_currentAngle clockwise:YES];
        
        if (_beforeAngle - angel*timeInterval - getIncreamentAngle(timeInterval) <= angel*0.1) {
            _animationFinished = YES;
        }
    }
    return path.CGPath;
}

- (CGPoint)getPointWithAngel:(double)angel {
    CGFloat radius = _drawPathLayer.frame.size.height/2;
    return CGPointMake(cos(angel)*radius+radius,sin(angel)*radius+radius);
}

- (void) _reduceProgressTimer {
    _drawTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/180 target:self selector:@selector(_reduceProgress) userInfo:nil repeats:YES];
    [_drawTimer fire];
    [[NSRunLoop currentRunLoop] addTimer:_drawTimer forMode:NSRunLoopCommonModes];
}

- (void) _reduceProgress {
    static double currentTime = 0;
    /*
     begin timer ...
     */
    currentTime+=(1.0/140);
    _drawPathLayer.path = [self pathForTimeInterval:currentTime andType:1];
    //如果时间到了 就结束
    if (_animationFinished) {
        currentTime = 0;
        //取消定时器
        [_drawTimer invalidate];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _currentAngle -= M_PI_2*3*0.1;
            _originalDrawAngle = _currentAngle;
            _animationFinished = NO;
            [self _increaseProgressTimer];
        });
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
