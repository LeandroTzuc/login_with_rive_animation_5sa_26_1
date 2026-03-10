import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Para usar Timer y simular un proceso de inicio de sesión

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar u ocultar la contraseña
  bool _obscureText = true;
  
  //Crear el cerebrro de la animacion 
  StateMachineController? _controller;
  //SMI: State Machine Input
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  
  //2.1 variable para el recorrido de la mirada
  SMINumber? _numLook;

//1.1)crear variables para focusnode
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  //timer para detener mirada al dejar de escribir
  Timer? _typingDebounce;

  // 4.1 Controllers
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // 4.2 Errores para mostrar en la UI
  String? emailError;
  String? passError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Acción al botón
  void onLogin() {
    // De lo que escribio el usuario, eliminar espacios en blanco
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalcular errores
    final eError = isValidEmail(email) ? null : 'Email inválido';
    final pError =
        isValidPassword(pass)
            ? null
            : 'Mínimo 8 caracteres, 1 mayúscula,  1 minúscula, 1 número y 1 caracter especial';

    // 4.5 Para avisar que hubo un cambio
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // 4.6 Cerrar el teclado y bajar manos
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0; // Mirada neutral

    // 4.7 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

//1.2)Listeners para detectar cuando el usuario enfoca o desenfoca los campos de texto
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
        //No tapes los ojos al ver email
        _isHandsUp?.change(false);
        //2.2 Mirada neutral
        _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocusNode.addListener(() {
      //manos arriba al enfocar el campo de contraseña
        _isHandsUp?.change(_passwordFocusNode.hasFocus);
        });
      }

  @override
  Widget build(BuildContext context) {
    //para obtener el tamaño de la pantalla y usarlo para ajustar el diseño
    final Size size = MediaQuery.of(context).size;
 
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height:250,
                child: RiveAnimation.asset('assets/animated_login_bear.riv', 
                stateMachines: ['Login Machine'],
                //Al iniciar la animacion
                onInit: (artboard) {
                  _controller = StateMachineController.fromArtboard(artboard, 'Login Machine');
                  //Verifica que inicio bien
                  if(_controller == null) return;
                  //Agrega el controlador al tablero/escenario
                  artboard.addController(_controller!);
                  //Vincular variables
                  _isChecking = _controller!.findSMI('isChecking');
                  _isHandsUp = _controller!.findSMI('isHandsUp');
                  _trigSuccess = _controller!.findSMI('trigSuccess');
                  _trigFail = _controller!.findSMI('trigFail');
        
                  //2.3 vincular numlook
                  _numLook = _controller!.findSMI('numLook');
        
                }
                
                )
                ),
                //Para separacion
                const SizedBox(height: 10),
                //Campo de texto para el email
                TextField(
                  //4.8 enlazanr texfield
                  controller: emailCtrl,
                  //1.3)Asignar los focusnode a los campos de texto
                  focusNode: _emailFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No tapes los ojos al ver email
                    // _isHandsUp!.change(false);
                    }
                    if (_isChecking == null) return;
                    //Activa  el modo chisme
                    _isChecking!.change(true);
                    //implementar numLook
                    //Ajustes de limites de 0 a 100
                    //80 como medida de calibracion
                    final look = (value.length/80.0*100)
                    .clamp(0.0, 100.0); //clamp es el rango (abrazadera)
                    _numLook?.value = look;
        
                    //3.3 Debounce: sivuelve a teclear reinicia el contador
                    //cancelar cualquier timer existente
                    _typingDebounce?.cancel();
                    //crear un nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 2), () {
                      //si se cierra la pantalla, quita el contador
                      if (!mounted) return;
                    //mirada neutra
                    _isChecking?.change(false);
                    });
        
                  },
                  //Para mostrar un tipo de tecleado
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      //Para redondear los bordes del campo de texto
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  //4.9 mostrar el texto de error
                  controller: passCtrl,
        
                  //1.3)Asignar los focusnode a los campos de texto
                  focusNode: _passwordFocusNode,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No modo chisme
                      //_isChecking!.change(false);
                    }
                    if (_isHandsUp == null) return;
                    //Arriba las manos
                    _isHandsUp!.change(true);
                  },
        
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    //4.9 mostrar el texto de error
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),//Cerrado o Seguro
                    suffixIcon: IconButton(
        
                      //if terniario
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        //Refresca el widget para mostrar u ocultar la contraseña
                        setState(() {
                          //Cambiar el estado de _obscureText para mostrar u ocultar la contraseña
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
        
        
                SizedBox(
                  width: size.width,
                  child: const Text (
                    "Forgot password?",
                    //alinearlo a la derecha
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                    ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: onLogin,
                  child: Text("Login",style: TextStyle(
                      color: Colors.white)),
                ),
                //no tienes cuenta? registrate
                const SizedBox(height: 20),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            //subrayado
                            decoration: TextDecoration.underline,
                            //negrita
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  //Liberar recursos de los focusnode
  @override
  void dispose() {
    //4.11 liberar controller
    emailCtrl.dispose();
    passCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
    _typingDebounce?.cancel(); //Cancelar el timer si existe
  }
}