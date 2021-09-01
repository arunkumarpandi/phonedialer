package com.example.phonedialer;

import android.app.Service;
import android.media.MediaRecorder;
import android.os.Environment;

public abstract class CallRecord extends Service {

    public static CallRecord callRecord;

    @Override
    public void onCreate() {
        super.onCreate();


//        callRecord = new CallRecord.Builder(this)
//                .setRecordFileName("test")
//                .setRecordDirName("Download")
//                .setRecordDirPath(Environment.getExternalStorageDirectory().getPath()) // optional & default value
//                .setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB) // optional & default value
//                .setOutputFormat(MediaRecorder.OutputFormat.AMR_NB) // optional & default value
//                .setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION) // optional & default value
//                .setShowSeed(false) // optional, default=true ->Ex: RecordFileName_incoming.amr || RecordFileName_outgoing.amr
//                .build();
//        callRecord.
//        callRecord.enableSaveFile();
//        callRecord.startCallReceiver();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
//        callRecord.stopCallReceiver();
    }
}
