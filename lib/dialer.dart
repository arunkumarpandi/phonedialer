import 'dart:convert';
import 'dart:io' as io;
import 'package:call_log/call_log.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialpad/flutter_dialpad.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:mobile_number/sim_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class Dialer extends StatefulWidget {
  Dialer({Key? key}) : super(key: key);

  @override
  _DialerState createState() => _DialerState();
}

class _DialerState extends State<Dialer> {
  String _mobileNumber = '';
  List<SimCard> _simCard = <SimCard>[];
  static const platform = MethodChannel('Record');

  List files = [];
  String directory = '';
  String uploadURL = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //Get Sim Number
    initMobileNumberState();
  }

  Future<void> initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return;
    }
    String mobileNumber = '';
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      mobileNumber = (await MobileNumber.mobileNumber)!;
      _simCard = (await MobileNumber.getSimCards)!;
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile number because of '${e.message}'");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _mobileNumber = mobileNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: DialPad(
            buttonTextColor: Colors.white,
            enableDtmf: true,
            outputMask: "(000) 000-0000",
            backspaceButtonIconColor: Colors.red,
            makeCall: (number) {
              print(number);
              _makePhoneCall('tel:$number');
              recordCall();
            }));
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  getCallLog() async {
    Iterable<CallLogEntry> entries = await CallLog.query(
      number: _mobileNumber,
    );
    var json = jsonEncode(entries.map((e) => e).toList());

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('CallLog', json);
  }

  recordCall() async {
    await platform.invokeMethod('CallRecord');
  }

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  clearLogsAndFiles() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove('CallLog');
    final dir = io.Directory("$directory/CALLRECORDDIR/");
    dir.deleteSync(recursive: true);
  }

  uploadLogsAndFiles() async {
    check().then((intenet) {
      if (intenet) {
        // Internet Present Case
        listofFiles();
        if (files.length > 0) {
          upload();
        }
      }
      // No-Internet Case
    });
  }

  upload() async {
    var uri = Uri.parse(uploadURL);
    var request = new http.MultipartRequest("POST", uri);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String v = sharedPreferences.getString('CallLog') ?? '';
    Iterable<CallLogEntry> entries = json.decode(v);
    request.fields['callLogs'] = entries.toList().toString();
    for (var i = 0; i < files.length; i++) {
      File f = io.File(files[i]);
      var stream = new http.ByteStream(DelegatingStream.typed(f.openRead()));
      var length = await f.length();
      var multipartFile = new http.MultipartFile('file', stream, length,
          filename: basename(f.path));

      request.files.add(multipartFile);
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      print(response.statusCode);
      clearLogsAndFiles();
      response.stream.transform(utf8.decoder).listen((value) {
        print(value);
      });
    }
  }

  void listofFiles() async {
    directory = (await getApplicationDocumentsDirectory()).path;
    files.clear();
    setState(() {
      files = io.Directory("$directory/CALLRECORDDIR/")
          .listSync(); //use your folder name insted of resume.
    });
  }
}
