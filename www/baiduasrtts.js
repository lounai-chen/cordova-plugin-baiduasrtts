var exec = require('cordova/exec');

exports.startSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "Baiduasrtts", "startSpeechRecognize", [arg0]);
};

exports.closeSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "Baiduasrtts", "closeSpeechRecognize", [arg0]);
};

exports.cancelSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "Baiduasrtts", "cancelSpeechRecognize", [arg0]);
};

exports.addEventListener = function (success, error) {
    exec(success, error, "Baiduasrtts", "addEventListener");
};

exports.initTTSconfig = function (success, error) {
    exec(success, error, "Baiduasrtts", "initTTSconfig");
};

exports.synthesizeSpeech = function (arg0,success, error) {
    exec(success, error, "Baiduasrtts", "synthesizeSpeech", [arg0]);
};