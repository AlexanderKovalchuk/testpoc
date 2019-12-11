import 'dart:collection';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  try {
    await authenticate();
    runApp(POCApp());
  } catch (error) {
    print('Locator setup has failed');
  }
}

Future<void> authenticate() async {
  final LocalAuthentication auth = LocalAuthentication();
  bool authenticated = false;
  authenticated = await auth.authenticateWithBiometrics(
      localizedReason: 'Scan your fingerprint to authenticate',
      useErrorDialogs: true,
      stickyAuth: true);
}

class POCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "F24 POC",
      home: new MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  //modified
  @override //new
  State createState() => new MainScreenState(); //new
}

class MainScreenState extends State<MainScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();
  final TextEditingController _numberTextController =
  new TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  new FlutterLocalNotificationsPlugin();
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);

    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    _firebaseMessaging.configure(
      // ignore: missing_return
      onMessage: (Map<String, dynamic> message) {
        print('on message ${message}');
        // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
        displayNotification(message);
        // _showItemDialog(message);
      },
      // ignore: missing_return
      onResume: (Map<String, dynamic> message) {
        print('on resume $message');
      },
      // ignore: missing_return
      onLaunch: (Map<String, dynamic> message) {
        print('on launch $message');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print(token);
    });
  }

  Future displayNotification(Map<String, dynamic> message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'channelid', 'flutterfcm', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      message['notification']['title'],
      message['notification']['body'],
      platformChannelSpecifics,
      payload: 'hello',
    );
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    ChatMessage message = new ChatMessage(payload, "backend", Colors.red);
    setState(() {
      _messages.insert(0, message);
    });

    await Fluttertoast.showToast(
        msg: "Notification Clicked",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0);
    /*Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new SecondScreen(payload)),
    );*/
  }

  Future onDidRecieveLocalNotification(int id, String title, String body,
      String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) =>
      new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Fluttertoast.showToast(
                  msg: "Notification Clicked",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIos: 1,
                  backgroundColor: Colors.black54,
                  textColor: Colors.white,
                  fontSize: 16.0);
            },
          ),
        ],
      ),
    );
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override //new
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("F24 POC")),
      body: new Column(
        //modified
        children: <Widget>[
          //new
          new Flexible(
            //new
            child: new ListView.builder(
              //new
              padding: new EdgeInsets.all(8.0), //new
              reverse: true, //new
              itemBuilder: (_, int index) => _messages[index], //new
              itemCount: _messages.length, //new
            ), //new
          ), //new
          new Divider(height: 1.0), //new
          new Container(
            //new
            decoration:
            new BoxDecoration(color: Theme
                .of(context)
                .cardColor), //new
            child: _buildTextComposer(), //modified
          ), //new
        ], //new
      ),
    );
  }

  Future _sendRequest(String url, String number, String message) async {
//    var response = await http.get(url);
    http.post(url,
        headers: {
          'Authorization':
          'Basic VFNULVVLQkFQNjVGOjNjODc4YTM2OTkzNTQyZTFhMWU0MTI4NzE1NTU4ZDM0',
          'Content-Type': 'application/json',
        },
        body: "{'message': '" + message + "', 'to': ['+49" + number + "']}");
//    print('Response status: ${response.statusCode}');
//    print('Response body: ${response.body}');
//    ChatMessage message = new ChatMessage(response.body, "Backend");
//    setState(() {
//      _messages.insert(0, message);
//    });
  }

  void _handleSubmitted(String text) {
    ChatMessage message = new ChatMessage(text, null, null);
    setState(() {
      _messages.insert(0, message);
    });
    _sendRequest("https://tc-dev-api.trustcase.com/basic/v1/bulk/posts",
        _numberTextController.text, _textController.text);
    _textController.clear();
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      //new
      data: new IconThemeData(color: Theme
          .of(context)
          .accentColor), //new
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row( //new
              children: <Widget>[
                new Flexible(
                    child: new TextField(
                      controller: _numberTextController,
                      onSubmitted: _handleSubmitted,
                      keyboardType: TextInputType.number,
                      decoration: new InputDecoration.collapsed(
                          hintText: "Input german number"),
                    )),
                new Flexible(
                    child: new TextField(
                      controller: _textController,
                      onSubmitted: _handleSubmitted,
                      decoration:
                      new InputDecoration.collapsed(hintText: "Send a message"),
                    )),
                new Container(
                  //new
                  margin: new EdgeInsets.symmetric(horizontal: 4.0), //new
                  child: new IconButton(
                    //new
                      icon: new Icon(Icons.send), //new
                      onPressed: () =>
                          _handleSubmitted(_textController.text)), //new
                ),
              ])),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage(String text, String name, Color color) {
    if (name != null && !name.isEmpty) {
      _name = name;
    }
    if (color != null) {
      this.color = color;
    }
    this.text = text;
  }

  String _name = "Alex";
  Color color = Colors.blue[50];
  String text;

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(
              child: new Text(_name[0]), backgroundColor: color),
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(_name, style: Theme
                  .of(context)
                  .textTheme
                  .subhead),
              new Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: new Text(text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
