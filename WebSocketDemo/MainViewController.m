//
//  MainViewController.m
//  WebSocketDemo
//
//  Created by walker on 2018/10/18.
//  Copyright © 2018 walker. All rights reserved.
//

#import "MainViewController.h"
#import "SocketRocket.h"

#define WS_URL_Key @"wss_url_userdefault"


@interface MainViewController ()<SRWebSocketDelegate,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *wsUrlTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *sendMsgTextFiled;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

/** socket */
@property (strong, nonatomic) SRWebSocket *socket;

/** log */
@property (strong, nonatomic) NSMutableString *logString;

/** url */
@property (strong, nonatomic) NSURL *url;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"WebSocket网络测试Demo";
    
    [self p_setPlaceHolder];
    
    [self setUpUI];
    
    [self p_updateLogWithString:@"请先输入WebSocket地址"];
    
    // 添加背景手势
    [self p_addBackGroundTapGesture];
}

/* 设置占位文字 */
- (void)p_setPlaceHolder {
    
    NSString *lastUrl = [[NSUserDefaults standardUserDefaults] objectForKey:WS_URL_Key];
    self.wsUrlTextFiled.text = @"ws://echo.websocket.org";
    
    if (lastUrl && lastUrl.length > 0) {
        self.wsUrlTextFiled.text = lastUrl;
    }
}

/* 设置UI */
- (void)setUpUI {
    
    self.wsUrlTextFiled.keyboardType = UIKeyboardTypeWebSearch;
    self.wsUrlTextFiled.autocorrectionType = UITextAutocorrectionTypeNo;
    self.wsUrlTextFiled.clearButtonMode = UITextFieldViewModeWhileEditing;

    self.logTextView.layer.borderColor = [UIColor grayColor].CGColor;
    self.logTextView.layer.borderWidth = 1.0f;
    self.logTextView.font = [UIFont systemFontOfSize:12.0f];
    if (@available(iOS 11.0, *)) {
        self.logTextView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.logTextView.editable = NO;
    self.logTextView.delegate = self;
    
}

// 连接socket按钮事件
- (IBAction)p_connectAction:(UIButton *)sender {
    
    NSString *urlString = [self.wsUrlTextFiled text];
    self.url = [NSURL URLWithString:urlString];
    
    [self p_openSocket];    // 开启
}

// 关闭socket按钮事件
- (IBAction)p_disConnectAction:(UIButton *)sender {
    
    [self p_closeSocket]; // 关闭
    
}
// 复制日志
- (IBAction)p_pasteAction:(UIButton *)sender {
    
    [[UIPasteboard generalPasteboard] setString:self.logTextView.text];
    
    [self p_updateLogWithString:@"log复制成功"];
}

// 清除日志
- (IBAction)p_clearLogAction:(UIButton *)sender {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"⚠️警告" message:@"确定清除所有日志？" preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self)weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // TODO:确定按钮事件
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.logString = @"".mutableCopy;
            [weakSelf.logTextView setText:self.logString];
        });
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"点错了" style:UIAlertActionStyleDefault handler:nil];
    
    [alertVC addAction:okAction];
    [alertVC addAction:cancelAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];

}

// 发送消息
- (IBAction)p_sendMsgAction:(UIButton *)sender {
    
    if (self.socket && self.socket.readyState == SR_OPEN) {
        NSData *sendData = [self.sendMsgTextFiled.text dataUsingEncoding:NSUTF8StringEncoding];
        if (sendData && sendData.length > 0) {
            [self p_updateLogWithString:[NSString stringWithFormat:@"发送消息:%@",self.sendMsgTextFiled.text]];
            [self.socket send:sendData];
        }else {
            [self p_updateLogWithString:@"发送数据为空！"];
        }
        
        
    }else {
        [self p_updateLogWithString:@"请检查socket是否在开启状态！"];
    }
}

#pragma mark - 私有方法 --

// 开始socket
- (void)p_openSocket {
    
    if(!([self.url.absoluteString hasPrefix:@"ws://"] || [self.url.absoluteString hasPrefix:@"wss://"])) {
        
        [self p_updateLogWithString:@"请输入正确的socket地址！"];
        return;
    }
    
    // 开启前必须关闭，重复开启导致崩溃
    if (self.socket) {
        [self p_updateLogWithString:@"请先关闭socket!"];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.url.absoluteString forKey:WS_URL_Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.socket = [[SRWebSocket alloc] initWithURL:self.url];
    self.socket.delegate = self;
    [self.socket open];
    [self p_updateLogWithString:@"正在开启socket..."];
}

// 关闭socket
- (void)p_closeSocket {
    
    if (self.socket) {
        [self.socket close];
        self.socket = nil;
        [self p_updateLogWithString:@"正在关闭Socket..."];
    }else {
        [self p_updateLogWithString:@"socket已经关闭!"];
    }
}

/**
 添加日志

 @param logString 日志字符串
 */
- (void)p_updateLogWithString:(NSString *)logString {
    
    if(!self.logString) {
        self.logString = @"".mutableCopy;
    }
    
    // 时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH-mm-ss";
    NSString *time = [formatter stringFromDate:[NSDate date]];
    
    // 日志展示
    [self.logString appendFormat:@"\n\n%@【%@】",logString,time];
    self.logTextView.text = self.logString;
    
    // 日志移动到最后
    if (self.logTextView.contentSize.height >= (self.logTextView.frame.size.height + 100.0f)) {
        CGFloat offsetY = self.logTextView.contentSize.height - self.logTextView.frame.size.height;
        
        offsetY = (offsetY <= self.logTextView.frame.size.height) ? 0.0f : offsetY;
        
        CGPoint offsetPoint = CGPointMake(0.0f, offsetY);
        
        [self.logTextView setContentOffset:offsetPoint animated:YES];
    }
}

// 添加点击背景视图关闭键盘手势
- (void)p_addBackGroundTapGesture {
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_backGroundTap:)]];
    
}

- (void)p_backGroundTap:(UITapGestureRecognizer *)tap {
    
    [self.view endEditing:YES];
    
}

#pragma mark - socket 代理 --

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    
    [self p_updateLogWithString:[NSString stringWithFormat:@"socket开启成功(url:%@)",webSocket.url.absoluteString]];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
    [self p_updateLogWithString:[NSString stringWithFormat:@"接收到pongPayLoad:%@",pongPayload]];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    [self p_updateLogWithString:[NSString stringWithFormat:@"连接失败,error:%@",error.description]];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    NSString *msg = @"";
    if ([message isKindOfClass:[NSString class]]) { // 判断是否是字符串类型
        msg = (NSString *)message;
    }else if([message isKindOfClass:[NSData class]]) {  // 判断是否是NSData类型
        msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    }else {
        msg = @"接到非NSString 或 NSData 类型数据，请查看！";
    }
    
    [self p_updateLogWithString:[NSString stringWithFormat:@"接收到数据<%@>：%@",[message class],msg]];

}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
    [self p_updateLogWithString:[NSString stringWithFormat:@"socket已经被关闭，code:%ld,reason:%@",code,reason]];
    webSocket.delegate = nil;
}


#pragma mark - textView --
// 拖动textView收回键盘
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if (scrollView == self.logTextView) {
        [self.view endEditing:YES];
    }
}

@end
