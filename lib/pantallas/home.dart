import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Librería para dar permisos
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'; // Librería para trabajar con bluetooth
import 'package:after_layout/after_layout.dart'; // Librería para pintar la interfaz y luego manda los hilos

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _bluetooth = FlutterBluetoothSerial
      .instance; // Objeto que va a manejar el dispositivo bluetooth
  bool BTstate =
      false; // Estado para saber si el bluetooth está aprendido o apagado desde el inicio
  bool BTconnected =
      false; // Estado para saber si el bluetooth está conectado o no desde el inicio
  BluetoothConnection? connection; // Realiza la conexión
  List<BluetoothDevice> devices =
      []; // Lista de dispositivos disponibles para conectarse
  BluetoothDevice? device; // Lee los dispositivos
  String contenido = "";

  @override
  void initState() {
    super.initState();
    permisos();
    estadoBT();
  }

  // Metodo para brindar permisos
  void permisos() async {
    await Permission.bluetoothConnect.request(); // Permiso para conectarse
    await Permission.bluetoothScan
        .request(); // Permiso para escanear dispositivos
    await Permission.bluetooth.request(); // Permiso para manipular bluetooth
    await Permission.location.request(); // Permiso para ver la localización
  }

  // Metodo para conocer el estado del bluetooth
  void estadoBT() {
    // Verificar si el estado del dispositivo viene prendido o apagado
    _bluetooth.state.then(
      (value) {
        setState(() {
          BTstate = value
              .isEnabled; // Si es enabled está apagado, si no, está prendido
        });
      },
    );

    // Manejador de eventos
    _bluetooth.onStateChanged().listen(
      (event) {
        switch (event) {
          case BluetoothState.STATE_ON: // Si el bluetooth está prendido...
            BTstate = true; // Cambia el estado del botón a prendido
            break;
          case BluetoothState.STATE_OFF: // Si el bluetooth está apagado...
            BTstate = false; // Cambia el estado del botón a apagado
            break;
          case BluetoothState
                .STATE_TURNING_ON: // Mientras el bluetooth se está prendiendo se hace algo...
            break;
          case BluetoothState
                .STATE_TURNING_OFF: // Mientras el bluetooth se está apagando se hace algo...
            break;
        }

        // Se modifica el estado del botón dependiendo si el bluetooth está prendido o apagado
        setState(() {});
      },
    );
  } // Fin del metodo

  // Metodo para prender el bluetooth
  void encenderBT() async {
    await _bluetooth.requestEnable();
  }

  // Metodo para apagar el bluetooth
  void apagarBT() async {
    await _bluetooth.requestDisable();
  }

  // Metodo que regresa un widget de boton switch
  Widget switchBT() {
    return SwitchListTile(
      title: BTstate
          ? const Text('Bluetooth Encendido')
          : const Text('Bluetooth Apagado'),
      activeColor: BTstate ? Colors.blueGrey : Colors.grey,
      tileColor: BTstate ? Colors.blue : Colors.grey,
      value: BTstate,
      onChanged: (bool value) {
        if (value) {
          encenderBT();
        } else {
          apagarBT();
        }
      },
      secondary: BTstate
          ? const Icon(Icons.bluetooth)
          : const Icon(Icons.bluetooth_disabled),
    );
  } // Fin del metodo

  Widget infoDisp() {
    return ListTile(
      title: device == null ? Text("Sin Dispositivo") : Text("${device?.name}"),
      subtitle:
          device == null ? Text("Sin Dispositivo") : Text("${device?.address}"),
      trailing: BTconnected
          ? IconButton(
              onPressed: () async {
                await connection?.finish();
                BTconnected = false;
                devices = [];
                device = null;
                setState(() {});
              },
              icon: const Icon(Icons.delete),
            )
          : IconButton(
              onPressed: () {
                listarDispositivos();
              },
              icon: const Icon(Icons.search),
            ),
    );
  }

  void listarDispositivos() async {
    devices = await _bluetooth.getBondedDevices();
    debugPrint(
        devices[0].name); // Dispositivo guardado en dispositivos bluetooth
    setState(() {});
  }

  Widget lista() {
    if (BTconnected) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          contenido,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 10.0,
            letterSpacing: 1,
            wordSpacing: 1,
          ),
        ),
      );
    } else {
      return devices.isEmpty
          ? const Text("No hay dispositivos")
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("${devices[index].name}"),
                  subtitle: Text("${devices[index].address}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.bluetooth_connected),
                    onPressed: () async {
                      connection = await BluetoothConnection.toAddress(
                          devices[index].address);
                      device = devices[index];
                      BTconnected = true;
                      recibirDatos();
                      setState(() {});
                    },
                  ),
                );
              },
            );
    }
  }

  void recibirDatos() {
    connection?.input?.listen(
      (event) {
        contenido = String.fromCharCodes(event);
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Bluetooth"),
      ),
      body: Column(
        children: <Widget>[
          switchBT(),
          const Divider(height: 5),
          infoDisp(),
          Expanded(child: lista())
        ],
      ),
    );
  }
}
