/********* CDVBaiduasrtts.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
#import "BDSSpeechSynthesizer.h"
#import <AVFoundation/AVFoundation.h>

#define READ_SYNTHESIS_TEXT_FROM_FILE (NO)
static BOOL isSpeak = YES;
static BOOL textFromFile = READ_SYNTHESIS_TEXT_FROM_FILE;
static BOOL displayAllSentences = !READ_SYNTHESIS_TEXT_FROM_FILE;

@interface CDVBaiduasrtts : CDVPlugin<BDSClientASRDelegate, UIAlertViewDelegate> {
    // Member variables go here.
    NSString* API_KEY;
    NSString* SECRET_KEY;
    NSString* APP_ID;
    NSString *callbackId;
}

@property (strong, nonatomic) BDSEventManager *asrEventManager;
@property (strong, nonatomic) NSBundle *bdsClientBundle;
@property(nonatomic, strong) NSFileHandle *fileHandler;

- (void)startSpeechRecognize:(CDVInvokedUrlCommand *)command;
- (void)closeSpeechRecognize:(CDVInvokedUrlCommand *)command;
- (void)cancelSpeechRecognize:(CDVInvokedUrlCommand *)command;
- (void)initTTSconfig:(CDVInvokedUrlCommand *)command;
- (void)synthesizeSpeech:(CDVInvokedUrlCommand *)command;

@end

@implementation CDVBaiduasrtts

- (NSBundle *)bdsClientBundle {
    if (!_bdsClientBundle) {
        NSString *strResourcesBundle = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
        //NSLog(@"strResourcesBundle,的路径：%@",strResourcesBundle)；
         NSLog(@"%@ 输出strResourcesBundle字符串\n", strResourcesBundle);
        _bdsClientBundle = [NSBundle bundleWithPath:strResourcesBundle];
    }
    
    return _bdsClientBundle;
}

- (void)pluginInitialize {
    NSLog(@"初始化。。。。。");
    [self.commandDelegate runInBackground:^{
        CDVViewController *viewController = (CDVViewController *)self.viewController;
        APP_ID = [viewController.settings objectForKey:@"baiduasrttsappid"];
        API_KEY = [viewController.settings objectForKey:@"baiduasrttsapikey"];
        SECRET_KEY = [viewController.settings objectForKey:@"baiduasrttssecretkey"];
        
        [self initAsrEventManager];
    }];
}

- (NSInteger)checkMicPermission {
    NSInteger flag = 0;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        //没有询问是否开启麦克风
        flag = 1;
        break;
        case AVAuthorizationStatusRestricted:
        //未授权，家长限制
        flag = 0;
        break;
        case AVAuthorizationStatusDenied:
        //玩家未授权
        flag = 0;
        break;
        case AVAuthorizationStatusAuthorized:
        //玩家授权
        flag = 2;
        break;
        default:
        break;
    }
    NSString *wwFlag = [NSString stringWithFormat:@"%d",flag];
    NSLog(@"语音权限状态");
    NSLog(wwFlag);
    return flag;
}


- (void)startSpeechRecognize:(CDVInvokedUrlCommand*)command
{
    NSLog(@"开始识别。。。。。。。。");
    [self.commandDelegate runInBackground:^{
        if ([self checkMicPermission] == 0) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您还未授权使用麦克风" delegate:self
                                                  cancelButtonTitle:@"知道了" otherButtonTitles:@"去设置", nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        } else {
            NSLog(@"发送指令：启动识别");
            // 发送指令：启动识别
            [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
        }
    }];
    
}

- (void)closeSpeechRecognize:(CDVInvokedUrlCommand *)command {
    NSLog(@"停止识别");
    [self.commandDelegate runInBackground:^{
        [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
    }];
    
}

- (void)cancelSpeechRecognize:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self.asrEventManager sendCommand:BDS_ASR_CMD_CANCEL];
    }];
    
}

- (void)addEventListener:(CDVInvokedUrlCommand *)command {
    NSLog(@"您好，开始监听录音了");
    NSLog(command.callbackId);
    [self.commandDelegate runInBackground:^{
        callbackId = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}



- (void)initAsrEventManager {
    NSLog(@"创建语音识别对象");
    // 创建语音识别对象
    self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
    // 设置语音识别代理
    [self.asrEventManager setDelegate:self];
    NSLog(APP_ID);
    // 参数配置：在线身份验证
    [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    NSLog(@"完成身份验证 ");
    //设置 APPID
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    NSLog(@"完成 设置 APPID ");
    //配置端点检测（二选一）
    //[self configModelVAD];
    [self configDNNMFE];
    NSLog(@"完成 配置端点检测 ");
    //     [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
    // ---- 语义与标点 -----
    [self enableNLU];
    NSLog(@"全部完成配置");
    //    [self enablePunctuation];
    // ------------------------
}

- (void) enableNLU {
    // ---- 开启语义理解 -----
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    [self.asrEventManager setParameter:@"1536" forKey:BDS_ASR_PRODUCT_ID];
}

- (void) enablePunctuation {
    // ---- 开启标点输出 -----
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_DISABLE_PUNCTUATION];
    // 普通话标点
    //    [self.asrEventManager setParameter:@"1537" forKey:BDS_ASR_PRODUCT_ID];
    // 英文标点
    [self.asrEventManager setParameter:@"1737" forKey:BDS_ASR_PRODUCT_ID];
    
}


- (void)configModelVAD {
    NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    
    //NSString *modelVAD_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    [self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
    
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    
    [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
}

- (void)configDNNMFE {
    NSString *mfe_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_dnn" ofType:@"dat"];
    
    //NSString *mfe_dnn_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_mfe_dnn" ofType:@"dat"];
    [self.asrEventManager setParameter:mfe_dnn_filepath forKey:BDS_ASR_MFE_DNN_DAT_FILE];
    NSString *cmvn_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_cmvn" ofType:@"dat"];
    
    //NSString *cmvn_dnn_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_mfe_cmvn" ofType:@"dat"];
    [self.asrEventManager setParameter:cmvn_dnn_filepath forKey:BDS_ASR_MFE_CMVN_DAT_FILE];
    // 自定义静音时长
    //    [self.asrEventManager setParameter:@(501) forKey:BDS_ASR_MFE_MAX_SPEECH_PAUSE];
    //    [self.asrEventManager setParameter:@(500) forKey:BDS_ASR_MFE_MAX_WAIT_DURATION];
}

#pragma mark - MVoiceRecognitionClientDelegate

- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
    NSLog(@"开启代理");
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            NSLog(@"录音数据回调 EVoiceRecognitionClientWorkStatusNewRecordData");
                       [self.fileHandler writeData:(NSData *)aObj];
            break;
        }
        
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            NSLog(@"识别开始");
            NSDictionary *logDic = [self parseLogToDic:aObj];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: start vr, log: %@\n", logDic]];
            NSDictionary *dict = @{
                                   @"type": @"asrReady",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: {
            NSLog(@"检查到用户开始说话");
            NSDictionary *dict = @{
                                   @"type": @"asrBegin",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
            NSLog(@"asrEnd:本地声音采集结束，等待识别结果返回并结束录音");
            NSDictionary *dict = @{
                                   @"type": @"asrEnd",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            NSLog(@"语音识别结果1");
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: partial result - %@.\n\n", [self getDescriptionForDic:aObj]]];
            if (aObj && [aObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = @{
                                       @"type": @"asrText",
                                       @"message" :aObj
                                       };
                
                [self sendEvent:dict];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            NSLog(@"语音识别结果2");
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: asr finish - %@.\n\n", [self getDescriptionForDic:aObj]]];
            
            if (aObj && [aObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = @{
                                       @"type": @"asrText",
                                       @"message" :aObj
                                       };
                
                [self sendEvent:dict];
            }
            NSDictionary *dict = @{
                                   @"type": @"asrFinish",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            NSLog(@"语音EVoiceRecognitionClientWorkStatusMeterLevely");
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            NSDictionary *dict = @{
                                   @"type": @"asrCancel",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            NSLog(@"识别发生错误");
            //NSLog(@"");
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            [self sendError:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLoaded: {
            NSLog(@"CALLBACK1");
            [self printLogTextView:@"CALLBACK: offline engine loaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            
            [self printLogTextView:@"CALLBACK: offline engine unLoaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk 3-party data length: %lu\n", (unsigned long)[(NSData *)aObj length]]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk NLU data: %@\n", nlu]];
            NSLog(@"%@", nlu);
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk end, sn: %@.\n", aObj]];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusFeedback: {
            NSDictionary *logDic = [self parseLogToDic:aObj];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            [self printLogTextView:@"CALLBACK: recorder closed.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            [self printLogTextView:@"CALLBACK: Long Speech end.\n"];
            break;
        }
        default:
        break;
    }
}

- (void)sendEvent:(NSDictionary *)dict {
    if (!callbackId) return;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    
}

- (void)sendError:(NSString *)errMsg {
    if (!callbackId) return;
    
    NSDictionary *dict = @{
                           @"type": @"asrError",
                           @"message": errMsg
                           };
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}



- (void)printLogTextView:(NSString *)logString
{
    NSLog(@"%@", logString);
}

- (NSDictionary *)parseLogToDic:(NSString *)logString
{
    NSArray *tmp = NULL;
    NSMutableDictionary *logDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSArray *items = [logString componentsSeparatedByString:@"&"];
    for (NSString *item in items) {
        tmp = [item componentsSeparatedByString:@"="];
        if (tmp.count == 2) {
            [logDic setObject:tmp.lastObject forKey:tmp.firstObject];
        }
    }
    return logDic;
}

- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
    if (dic) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                              options:NSJSONWritingPrettyPrinted
                                                                                error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            NSString *urlStr = [NSString stringWithFormat:@"prefs:root=%@", [[NSBundle mainBundle] bundleIdentifier]];
            url= [NSURL URLWithString:urlStr];
            
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
}

- (void)initTTSconfig:(CDVInvokedUrlCommand *)command {
    NSLog(@"启动。TTS version info: %@", [BDSSpeechSynthesizer version]);
    [BDSSpeechSynthesizer setLogLevel:BDS_PUBLIC_LOG_VERBOSE];
    [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate:self];
    [self configureOnlineTTS];
    [self configureOfflineTTS];
}

-(void)configureOnlineTTS{
    
    [[BDSSpeechSynthesizer sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    //    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(BDS_SYNTHESIZER_SPEAKER_DYY) forKey:BDS_SYNTHESIZER_PARAM_SPEAKER];
    //    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(10) forKey:BDS_SYNTHESIZER_PARAM_ONLINE_REQUEST_TIMEOUT];
}


-(void)displayError:(NSError*)error withTitle:(NSString*)title{
    NSString* errMessage = error.localizedDescription;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:errMessage preferredStyle:UIAlertControllerStyleAlert];
    if(alert){
        UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {}];
        [alert addAction:dismiss];
       // [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        UIAlertView *alertv = [[UIAlertView alloc] initWithTitle:title message:errMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        if(alertv){
            [alertv show];
        }
    }
}

-(void)configureOfflineTTS{
    
    NSError *err = nil;
    // 在这里选择不同的离线音库（请在XCode中Add相应的资源文件），同一时间只能load一个离线音库。根据网络状况和配置，SDK可能会自动切换到离线合成。
    NSString* offlineEngineSpeechData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Speech_Female" ofType:@"dat"];
    
    NSString* offlineChineseAndEnglishTextData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Text" ofType:@"dat"];
    
    err = [[BDSSpeechSynthesizer sharedInstance] loadOfflineEngine:offlineChineseAndEnglishTextData speechDataPath:offlineEngineSpeechData licenseFilePath:nil withAppCode:APP_ID];
    if(err){
        NSLog(@"失败：Offline TTS init failed");
        [self displayError:err withTitle:@"Offline TTS init failed"];
        return;
    }
    //[TTSConfigViewController loadedAudioModelWithName:@"Chinese female" forLanguage:@"chn"];
    //[TTSConfigViewController loadedAudioModelWithName:@"English female" forLanguage:@"eng"];
}


- (void)synthesizeSpeech:(CDVInvokedUrlCommand *)command {
    NSLog(@"开始语音合成...");
    // 获取传来的参数
    NSString* speech_test = [command.arguments objectAtIndex:0];
    NSAttributedString* string = [[NSAttributedString alloc] initWithString:speech_test];
    NSInteger sentenceID;
    NSError* err = nil;
    if(isSpeak)
        sentenceID = [[BDSSpeechSynthesizer sharedInstance] speakSentence:[string string] withError:&err];
    else
        sentenceID = [[BDSSpeechSynthesizer sharedInstance] synthesizeSentence:[string string] withError:&err];
    if(err == nil){
        NSMutableDictionary *addedString = [[NSMutableDictionary alloc] initWithObjects:@[string, [NSNumber numberWithInteger:sentenceID], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0]] forKeys:@[@"TEXT", @"ID", @"SPEAK_LEN", @"SYNTH_LEN"]];
    }
    else{
        [self displayError:err withTitle:@"Add sentence Error"];
        NSLog(@"错误：Add sentence Error");
    }
}



@end

