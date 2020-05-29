import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './BluetoothDeviceListEntry.dart';
import './CommAdmin.dart';
//import './BackgroundCollectedPage.dart';

class MainPage extends StatefulWidget {
  
    final bool start;

  const MainPage({this.start = true});

  @override
  _MainPage createState() => new _MainPage();
}
class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();
  bool isDiscovering = false;
  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  bool _autoAcceptPairingRequests = false;
  BluetoothDevice selectedDevice=null;
  var selected=-1;
  
  @override
  void initState() {
    super.initState();

    

                
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

 _MainPage(){
     future() async {
                  if (!_bluetoothState.isEnabled){
                    await FlutterBluetoothSerial.instance.requestEnable();
                }}
    future().then((_) {
                  setState(() {});
      });
    if(_bluetoothState.isEnabled){
      if (isDiscovering) {
        _startDiscovery();
    }
    }
   }
   void _restartDiscovery() {
    print("I am restarting discovery");
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        results.add(r);
      });
    });

    _streamSubscription.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*BluetoothDevice selectedDevice=null;
    var selected=-1;*/
    print(results.length);
    return Scaffold(body:Builder(
      builder: (BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('KyuKey Bluetooth Interface'),
        backgroundColor: Colors.amber[900],
        actions: <Widget>[IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                },
                )
        ],
      ),
      body: Column(
        children: <Widget>[
        
            Divider(),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              activeColor: Colors.amberAccent[400],
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Divider(),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 1234'),
              activeColor: Colors.amberAccent[400],
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler(
                      (BluetoothPairingRequest request) {
                    print("Trying to auto-pair with Pin 1234");
                    if (request.pairingVariant == PairingVariant.Pin) {
                      return Future.value("1234");
                    }
                    return null;
                  });
                } else {
                  FlutterBluetoothSerial.instance
                      .setPairingRequestHandler(null);
                }
              },
            ),
            /*ListTile(
              title: RaisedButton(
                  child: const Text('Explore discovered devices'),
                  onPressed: () async {
                    final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoveryPage();
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),*/
            ListTile(
              title: RaisedButton(
                child: const Text('Connect'),
                highlightColor: Colors.tealAccent[400],
                color: Colors.greenAccent[400],
                onPressed: () async {
                  /*final BluetoothDevice selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );
                  */
                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    
                    Scaffold.of(context).showSnackBar(SnackBar(content: Text('This part is in development expect bugs :) \n the communication while happen in 3sec'),backgroundColor: Colors.redAccent[200],duration:Duration(seconds: 2), ));
                    Timer(Duration(seconds: 3),(){
                      print("loop in here");
                      _startChat(context, selectedDevice);
                      });
                    
                  } else {
                     Scaffold.of(context).showSnackBar(SnackBar(content: Text('Please select device from the list or try refreshing it.'),backgroundColor: Colors.grey[600],duration:Duration(seconds: 2), ));
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
            ListTile(
              title: 
                  (!_bluetoothState.isEnabled) ?
                  Column(children: <Widget>[Text("Enable Bluetooth to Discover Devices")],)
                  :
                  Column( children: <Widget>[ 
                          Row(children: <Widget> [
                            Expanded(child:Text("Active Devices",textAlign: TextAlign.center,)),
                            isDiscovering ?
                            FittedBox( 
                              child: Container( 
                                margin: new EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent[700]),
                                ),
                              ),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                            )
                            : IconButton(
                                icon: Icon(Icons.replay),
                                onPressed: _restartDiscovery,
                                alignment: Alignment.centerRight,
                              ),
                          ],
                          ), 
                   
                   ],
                  ),
              ),
              
          
      
       
          Expanded(child:   
            results.length > 0 ? 
            ListView.builder(
                          itemCount: results.length,
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemBuilder: (BuildContext context, index) {
                          BluetoothDiscoveryResult result = results[index];
                          return Ink
                          (
                            color: selected==index ?Colors.amber[400]:Colors.amber[100],
                            child:BluetoothDeviceListEntry(
                            device: result.device,
                            rssi: result.rssi,
                            onTap: () {
                              //Navigator.of(context).pop(result.device); Look into the connect page to understand what to do
                              //Navigator.of(context).pop(result.device);
                              print("This is pressed");
                              
                              setState(() {
                              
                              if (selected!=index){
                                selected=index;
                                selectedDevice=result.device;
                              }
                              else{
                                selected=-1;
                                selectedDevice=null;
                              }
                                
                              });
                              

                            },
                            onLongPress: () async {
                            try {
                            bool bonded = false;
                            if (result.device.isBonded) {
                            print('Unbonding from ${result.device.address}...');
                            await FlutterBluetoothSerial.instance
                                .removeDeviceBondWithAddress(result.device.address);
                            print('Unbonding from ${result.device.address} has succed');
                            } else {
                            print('Bonding with ${result.device.address}...');
                            bonded = await FlutterBluetoothSerial.instance
                            .bondDeviceAtAddress(result.device.address);
                            print(
                            'Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
                            }
                            setState(() {
                            results[results.indexOf(result)] = BluetoothDiscoveryResult(
                              device: BluetoothDevice(
                              name: result.device.name ?? '',
                              address: result.device.address,
                              type: result.device.type,
                              bondState: bonded
                                  ? BluetoothBondState.bonded
                                  : BluetoothBondState.none,
                                ),
                              rssi: result.rssi);
                            });
                            } catch (ex) {
                            showDialog(
                            context: context,
                            builder: (BuildContext context) {
                            return AlertDialog(
                            title: const Text('Error occured while bonding'),
                            content: Text("${ex.toString()}"),
                            actions: <Widget>[
                            new FlatButton(
                            child: new Text("Close"),
                            onPressed: () {
                            //Navigator.of(context).pop(); dont use this 
                            },
                          ),
                        ],
                      );
                    },
                   );
                  }
                },
              ));
            },
            )
            : Text("No Devices Found")
            ),
           
          ],
          )
        );
      }
     ) );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CommAdmin(server: server);
        },
      ),
    );
  }

}
