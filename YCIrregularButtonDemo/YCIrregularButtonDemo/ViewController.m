//
//  ViewController.m
//  YCIrregularButtonDemo
//
//  Created by Sunyc on 2021/4/7.
//

#import "ViewController.h"
#import "YCIrregularButton.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)irregularBtnClick:(YCIrregularButton *)sender {
    NSLog(@"点击在按钮上");
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"点击在屏幕上");
}


@end
