import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class CommAdmin extends StatefulWidget {
  final BluetoothDevice server;

  const CommAdmin({this.server});

  @override
  _CommPage createState() => new _CommPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _CommPage extends State<CommAdmin> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  final _formKey = GlobalKey<FormState>();

  TextEditingController wifissid = TextEditingController();
  TextEditingController passphrase = TextEditingController();
  TextEditingController pin = TextEditingController();
  TextEditingController deviceName = TextEditingController();
  String initwifi="";
  String initpassp="";
  String initpin="";
  String initname="";
  int messageCount=-1;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
    _sendMessage("info");

  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();
  */
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber[800],
          title: (isConnecting
              ? Text('Connecting to ' + widget.server.name + '...',style: TextStyle( ),)
              : isConnected
                  ? Text('Connected with ' + widget.server.name)
                  : Text('Previously connected with ' + widget.server.name)),
            actions: <Widget>[IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    String toChange="";
                    if (wifissid.text!=initwifi)
                      {toChange=toChange+"/sw"+wifissid.text+"/ew";}
                    if (pin.text!=initpin)
                      {toChange=toChange+"/spi"+pin.text+"/epi";}
                    if (passphrase.text!=initpassp)
                      {toChange=toChange+"/spp"+passphrase.text+"/epp";}
                    if (deviceName.text!=initname)
                      {toChange=toChange+"/sdn"+wifissid.text+"/edn";}    
                  _sendMessage(
                    toChange
                  ); // try to change the function such that there is no requirement of text as input

                },
                ),
                messageCount==messages.length?
                FittedBox( 
                              child: Container( 
                                margin: new EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]),
                                ),
                              ),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                            )
                :            
                IconButton(
                  icon: Icon(Icons.replay),
                  onPressed: () {  
                  Timer(Duration(seconds: 1),(){_sendMessage("info");});

               
                setState(() {
                   messageCount=messages.length;
                });
                }
                )
        ],),
      body: Center(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: <Widget>[
                    Form(
                  key: _formKey,
                  child: Column(
                    children : <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    controller: wifissid,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'wifissid',
                    ),
                    validator: (String value){
                      if(value==""){
                      return 'This is mandatory';
                    }
              
                     return null;
              
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    obscureText: true,
                    controller: passphrase,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                      
                    ),
                  validator :(String value){
                        if(value.isEmpty){
                          return 'This is Essential';
                        }
                        return null;
                      },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    obscureText: true,
                    controller: pin,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'PIN - device',
                    ),
                    validator :(String value){
                        if(value==""){
                          return 'this is mandatory';
                        }
                        return null;
                      },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    controller: deviceName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Device-Name',
                    ),
                    validator :(String value){
                        if(value==""){
                          return 'this is mandatory';
                        }
                        return null;
                      },
                  ),
                ),
                  ],
                  ),
                    ),
                  ],
                  //children: list), try to put in a form or table to edit
              ),
              ),
            /*Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                                ? 'Type your message...'
                                : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )*/
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
    if (dataString.indexOf("/sw")!=-1)
      {wifissid.text=dataString.substring(dataString.indexOf("/sw")+4,dataString.indexOf("/ew"));initwifi=wifissid.text;}
    if (dataString.indexOf("/spp")!=-1)
      {passphrase.text=dataString.substring(dataString.indexOf("/spp")+5,dataString.indexOf("/epp"));initpassp=passphrase.text;}
    if (dataString.indexOf("/spi")!=-1)
      {pin.text=dataString.substring(dataString.indexOf("/spi")+5,dataString.indexOf("/epi"));initpin=pin.text;}
    if (dataString.indexOf("/sdn")!=-1)
      {deviceName.text=dataString.substring(dataString.indexOf("/sdn")+5,dataString.indexOf("/edn"));initname=deviceName.text;}
    print(dataString);
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text+"\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
