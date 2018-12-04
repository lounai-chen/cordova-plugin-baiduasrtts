package org.apache.cordova.baiduasrtts;

import android.Manifest;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.app.Activity;
import android.media.AudioManager;
import android.util.Log;
import android.widget.Toast;

import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;


import org.apache.cordova.CallbackContext;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;

import com.baidu.speech.EventListener;
import com.baidu.speech.EventManager;
import com.baidu.speech.EventManagerFactory;
import com.baidu.speech.asr.SpeechConstant;

import com.baidu.tts.client.SpeechError;
import com.baidu.tts.client.SpeechSynthesizer;
import com.baidu.tts.client.SpeechSynthesizerListener;
import com.baidu.tts.client.TtsMode;


/**
 * This class echoes a string called from JavaScript.
 */
public class Baiduasrtts extends CordovaPlugin implements EventListener {
    SpeechSynthesizer mSpeechSynthesizer;
    private CallbackContext bleCallbackContext = null;
    AudioManager mAudioManager;

    private EventManager asr;
    private static CallbackContext pushCallback;
    private String permission = Manifest.permission.RECORD_AUDIO;

    public static final String TAG = "Baiduasrtts";


    private Context getApplicationContext() {
        return this.cordova.getActivity().getApplicationContext();
    }

    protected void getMicPermission(int requestCode) {
        PermissionHelper.requestPermission(this, requestCode, permission);
    }


    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                Toast.makeText(getApplicationContext(), "用户未授权使用麦克风", Toast.LENGTH_LONG).show();
                return;
            }
        }

        //        startSpeechRecognize();
    }

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();

        asr = EventManagerFactory.create(getApplicationContext(), "asr");
        asr.registerListener(this);
    }

    @Override
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (null != asr) {
            asr = null;
        }
    }

    @Override
    public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {

        Log.e(TAG, "开始执行。。。 " + action);
        if ("startSpeechRecognize".equals(action)) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {

                    startSpeechRecognize();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
                }
            });
        } else if ("closeSpeechRecognize".equals(action)) {
            // 停止录音
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    asr.send(SpeechConstant.ASR_STOP, null, null, 0, 0);
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
                }
            });

        } else if ("cancelSpeechRecognize".equals(action)) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    asr.send(SpeechConstant.ASR_CANCEL, "{}", null, 0, 0);
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
                }
            });
        } else if ("addEventListener".equals(action)) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    pushCallback = callbackContext;
                    addEventListenerCallback(callbackContext);
                }
            });
        }
        else if ("synthesizeSpeech".equals(action)) {
            //  String text = arg_object.getString("text");
            //  String utteranceId = arg_object.getString("utteranceId");
            String speech_text = args.getString(0);
            Log.e(TAG, "要播报的文字：  " + speech_text);
            mSpeechSynthesizer.speak(speech_text);
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
        }
        else if ("initTTSconfig".equals(action)) {
            //initTTSconfig();
        }
        else {
            Log.e(TAG, "无当前命令： Invalid action : " + action);
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.INVALID_ACTION));
            return false;
        }

        return true;
    }

    /**
     * Called after plugin construction and fields have been initialized. Prefer to
     * use pluginInitialize instead since there is no value in having parameters on
     * the initialize() function.
     *
     * @param cordova
     * @param webView
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        Log.e(TAG, "初始化TTS。。。 " );
        super.initialize(cordova, webView);
        Context context = this.cordova.getActivity().getApplicationContext();
        mAudioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        ApplicationInfo applicationInfo = null;
        try {
            applicationInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(),
                    PackageManager.GET_META_DATA);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }

        // SpeechUtility.createUtility(context,
        // "appid="+applicationInfo.metaData.getString("com.blanktrack.appid"));

        // 初始化TTS
        mSpeechSynthesizer = SpeechSynthesizer.getInstance();
        mSpeechSynthesizer.setContext(getApplicationContext());
        mSpeechSynthesizer.setSpeechSynthesizerListener(new SpeechSynthesizerListener() {

            @Override
            public void onSynthesizeStart(String s) {
            }

            @Override
            public void onSynthesizeDataArrived(String s, byte[] bytes, int i) {
            }

            @Override
            public void onSynthesizeFinish(String s) {
                Log.i(TAG, "onSynthesizeFinish: ");
            }

            @Override
            public void onSpeechStart(String s) {
            }

            @Override
            public void onSpeechProgressChanged(String s, int i) {
            }

            @Override
            public void onSpeechFinish(String s) {
                Log.i(TAG, "onSpeechFinish: " + s);

                sendEvent("ttsStoped", s);

            }

            @Override
            public void onError(String s, SpeechError speechError) {

            }
        });

            String speech_APP_ID =  applicationInfo.metaData.getString("com.baidu.speech.APP_ID");
            // Log.e(TAG, "值com.baidu.speech.APP_ID。。。 " + speech_APP_ID);
            mSpeechSynthesizer.setAppId(applicationInfo.metaData.getString("com.baidu.speech.APP_ID"));
            mSpeechSynthesizer.setApiKey(applicationInfo.metaData.getString("com.baidu.speech.API_KEY"),
                    applicationInfo.metaData.getString("com.baidu.speech.SECRET_KEY"));

            // mSpeechSynthesizer.setAppId("10099877");
            // mSpeechSynthesizer.setApiKey("BEaA7Pk5LPkdvZnpNvM81xra","fda5a5cfbce396f20b21c3510412989d");
            // 5. 以下setParam 参数选填。不填写则默认值生效
            // 设置在线发声音人： 0 普通女声（默认） 1 普通男声 2 特别男声 3 情感男声<度逍遥> 4 情感儿童声<度丫丫>
            mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_SPEAKER, "0");
            // 设置合成的音量，0-9 ，默认 5
            mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_VOLUME, "9");
            // 设置合成的语速，0-9 ，默认 5
            mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_SPEED, "5");
            // 设置合成的语调，0-9 ，默认 5
            mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_PITCH, "5");
            mSpeechSynthesizer.setParam(SpeechSynthesizer.PARAM_MIX_MODE, SpeechSynthesizer.MIX_MODE_HIGH_SPEED_NETWORK);
            mSpeechSynthesizer.initTts(TtsMode.ONLINE);

    }

    private void registerNotifyCallback(CallbackContext callbackContext) {

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

    }

    private void startSpeechRecognize() {

        if (PermissionHelper.hasPermission(this, permission)) {
            Map<String, Object> params = new LinkedHashMap<String, Object>();
            String event = SpeechConstant.ASR_START; // 替换成测试的event

            params.put(SpeechConstant.ACCEPT_AUDIO_VOLUME, false);
            // params.put(SpeechConstant.NLU, "enable");
            // params.put(SpeechConstant.VAD_ENDPOINT_TIMEOUT, 0); // 长语音
            // params.put(SpeechConstant.IN_FILE, "res:///com/baidu/android/voicedemo/16k_test.pcm");
            // params.put(SpeechConstant.VAD, SpeechConstant.VAD_DNN);
            // params.put(SpeechConstant.PROP ,20000);
            // params.put(SpeechConstant.PID, 1537); // 中文输入法模型，有逗号
            // 请先使用如‘在线识别’界面测试和生成识别参数。 params同ActivityRecog类中myRecognizer.start(params);
            String json = new JSONObject(params).toString(); // 这里可以替换成你需要测试的json
            asr.send(event, json, null, 0, 0);
        } else {
            getMicPermission(0);
        }

    }

    private void addEventListenerCallback(CallbackContext callbackContext) {

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

    }

    //   EventListener  回调方法
    @Override
    public void onEvent(String name, String params, byte[] data, int offset, int length) {

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_READY)) {
            // 引擎就绪，可以说话，一般在收到此事件后通过UI通知用户可以说话了
            sendEvent("asrReady", "ok");
        }

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_BEGIN)) {
            // 检测到说话开始
            sendEvent("asrBegin", "ok");
        }

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_END)) {
            // 检测到说话结束
            sendEvent("asrEnd", "ok");
        }

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_FINISH)) {
            // 识别结束（可能含有错误信息）
            try {
                JSONObject jsonObject = new JSONObject(params);
                int errCode = jsonObject.getInt("error");

                if (errCode != 0) {
                    sendError("语音识别错误");
                } else {
                    sendEvent("asrFinish", "ok");
                }

            } catch (JSONException e) {
                Log.i(TAG, e.getMessage());
            }


        }

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_PARTIAL)) {
            // 识别结果
            sendEvent("asrText", params);
        }

        if (name.equals(SpeechConstant.CALLBACK_EVENT_ASR_CANCEL)) {
            sendEvent("asrCancel", "ok");
        }

    }


    private void sendEvent(String type, String msg) {
        JSONObject response = new JSONObject();
        try {
            response.put("type", type);
            response.put("message", msg);

            final PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, response);
            pluginResult.setKeepCallback(true);
            if (pushCallback != null) {
                pushCallback.sendPluginResult(pluginResult);
            }

        } catch (JSONException e) {
            Log.i(TAG, e.getMessage());
        }
    }

    private void sendError(String message) {
        JSONObject err = new JSONObject();
        try {
            err.put("type", "asrError");
            err.put("message", message);

            PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, err);
            pluginResult.setKeepCallback(true);
            if (pushCallback != null) {
                pushCallback.sendPluginResult(pluginResult);
            }

        } catch (JSONException e) {
            Log.i(TAG, e.getMessage());
        }


    }


}