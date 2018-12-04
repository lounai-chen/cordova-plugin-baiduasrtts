###  前言
这是一个百度语音识别和语音合成的cordova插件。 

 
官网链接：  

[http://ai.baidu.com/docs#/ASR-Android-SDK/top](http://ai.baidu.com/docs#/ASR-Android-SDK/top)
 

    
       
       
 
 
支持平台： 

Android
iOS

---
### 安装

在线url安装:  
cordova plugin add
https://gitlab.com/zzl_public/cordova-plugin-baiduasrtts.git --variable APIKEY=[your apikey] --variable SECRETKEY=[your secretkey] --variable APPID=[your appid]

本地安装:  
cordova plugin add /your localpath --variable APIKEY=[your apikey] --variable SECRETKEY=[your secretkey] --variable APPID=[your appid]

---

### API使用 

 
```

function initTTSconfig(){
  Baiduasrtts.initTTSconfig(function(e){},function(r){});
  Baiduasrtts.synthesizeSpeech("你好，世界",function(e){},function(r){});
}

function startSpeechRecognize(){

  document.getElementById('v_status').innerHTML="";
  document.getElementById('v_result').innerHTML="";
 // 开启语音识别
  Baiduasrtts.startSpeechRecognize(null,function(e){},function(r){});

 // 语音识别事件监听
  Baiduasrtts.addEventListener(function (res) {
     // res参数都带有一个type
     if (!res) {
       return;
     }

     switch (res.type) {
       case "asrReady": {
         // 识别工作开始，开始采集及处理数据
         document.getElementById('v_status').innerHTML="识别工作开始，开始采集及处理数据"
         break;
       }

       case "asrBegin": {
         // 检测到用户开始说话
         document.getElementById('v_status').innerHTML="检测到用户开始说话"
          //  alert("检测到用户开始说话");

         break;
       }

       case "asrEnd": {
         // 本地声音采集结束，等待识别结果返回并结束录音
          document.getElementById('v_status').innerHTML="本地声音采集结束，等待识别结果返回并结束录音"
          //  alert("本地声音采集结束，等待识别结果返回并结束录音");

         break;
       }

       case "asrText": {
         // 语音识别结果

           var message =  JSON.parse(res.message);
           var results = message["results_recognition"];
           document.getElementById('v_result').innerHTML=results;

         break;
       }

       case "asrFinish": {
         // 语音识别功能完成
         var rse = document.getElementById('v_result').innerHTML
         Baiduasrtts.synthesizeSpeech(rse,function(e){},function(r){});
         break;
       }

       case "asrCancel": {
         // 语音识别取消

         break;
       }

       default:
         break;
     }

   }, function (err) {
      document.getElementById('v_status').innerHTML= "未检测到语音识别数据";
   });
}
```


## 注意事项
以下文件太大，需自己去百度官网SDK下载

src\ios\BDSClientLib\ASR\bds_easr_input_model.dat

src\ios\BDSClientLib\ASR\libBaiduSpeechSDK.a
 

src\ios\BDSClientLib\TTS\libBaiduSpeech_TTS_SDK.a
