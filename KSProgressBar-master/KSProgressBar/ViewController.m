//
//  ViewController.m
//  KSProgressBar
//
//  Created by DouQu on 17/4/10.
//  Copyright © 2017年 Chipen. All rights reserved.
//

#import "ViewController.h"
#import "KSProgressBar.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KSProgressBar* bar = [[KSProgressBar alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2-20,self.view.bounds.size.height-120,40,40)];
    bar.lineWidth = 6.0f;
    bar.color = [UIColor blueColor];
    [self.view addSubview:bar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
