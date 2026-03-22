import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  login() async {

    if(email.text.isEmpty || password.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Completá todos los campos"))
      );
      return;
    }

    try {

      var res = await http.post(
        Uri.parse("https://envivoonline.com.ar/me/api/login.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: "email=${email.text}&password=${password.text}"
      );

      print("RESPUESTA: ${res.body}");

      var data = json.decode(res.body);

      if(data["status"] == "ok"){

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomePage(data))
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["msg"] ?? "Error en login"))
        );

      }

    } catch(e){

      print("ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión"))
      );

    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff0f172a),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text("🔐 Login",
                  style: TextStyle(color: Colors.white, fontSize: 24)),

              SizedBox(height: 20),

              TextField(
                controller: email,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder()
                ),
              ),

              SizedBox(height: 10),

              TextField(
                controller: password,
                obscureText: true,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder()
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: login,
                child: Text("Ingresar"),
              )

            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final data;
  HomePage(this.data);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List tareas = [];
  int total = 0;
  int hechas = 0;

  String dia = "";
  String turno = "";

  @override
  void initState() {
    super.initState();

    turno = widget.data['turno'];

    Map dias = {
      1: "Lunes",
      2: "Martes",
      3: "Miércoles",
      4: "Jueves",
      5: "Viernes",
      6: "Sábado",
      7: "Domingo"
    };

    var hoy = DateTime.now();
    dia = dias[hoy.weekday];

    cargarTareas();
  }

  // 🔥 CARGAR TAREAS
  cargarTareas() async {

    var res = await http.get(
      Uri.parse("https://envivoonline.com.ar/me/api/obtener_tareas.php?turno=$turno&dia=$dia")
    );

    var data = json.decode(res.body);

    // agregar campo done a cada tarea
    for(var t in data){
      t['done'] = false;
    }

    setState(() {
      tareas = data;
      total = tareas.length;
      hechas = 0;
    });

  }

  // 🔥 MARCAR Y GUARDAR
  marcar(int index) async {

    if(tareas[index]['done'] == true) return;

    setState(() {
      tareas[index]['done'] = true;
      hechas++;
    });

    // 🔥 GUARDAR EN BASE
    await http.post(
      Uri.parse("https://envivoonline.com.ar/me/api/completar_tarea.php"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: {
        "empleado_id": widget.data['id'].toString(),
        "tarea_id": tareas[index]['id'].toString()
      }
    );

  }

  @override
  Widget build(BuildContext context) {

    double progreso = total > 0 ? (hechas / total) : 0;

    return Scaffold(
      backgroundColor: Color(0xff0f172a),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("👋 ${widget.data['nombre']}"),
      ),

      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [

            Text("$dia - Turno $turno",
                style: TextStyle(color: Colors.white, fontSize: 16)),

            SizedBox(height: 10),

            LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey,
              color: Colors.green,
            ),

            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: tareas.length,
                itemBuilder: (context, i){

                  bool done = tareas[i]['done'] == true;

                  return Card(
                    color: done ? Colors.green : Color(0xff1e293b),
                    child: ListTile(
                      title: Text(
                        tareas[i]['nombre'],
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: done
                          ? Icon(Icons.check, color: Colors.white)
                          : Icon(Icons.circle_outlined, color: Colors.white),
                      onTap: (){
                        marcar(i);
                      },
                    ),
                  );

                },
              ),
            )

          ],
        ),
      ),
    );
  }
}