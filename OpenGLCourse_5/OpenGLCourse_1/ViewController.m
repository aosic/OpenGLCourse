//
//  ViewController.m
//  OpenGLCourse_1
//
//  Created by 智衡宋 on 2017/9/19.
//  Copyright © 2017年 智衡宋. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLESView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view = [[OpenGLESView alloc] initWithFrame:self.view.bounds];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
