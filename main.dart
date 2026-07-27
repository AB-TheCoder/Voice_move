import 'package:flutter/material.dart';

void main() {
    runApp(const VccnApp());
}

class VccnApp extends StatelessWeight {
    const VccnApp ({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'VCCN',
            home: const ClockScreen(),
        );
    }
}

class ClockScreen extends StatefulWidget {
    const ClockScreen({super.key});

    @override
    State<ClockScreen> createState => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
    @override 
    Widget build(BuildContext context) {
        return Scaffold(
            body: Center(
                child: Text("VCCN"),
            ),
        );
    }
}

class _ClockScreenState extends State<ClockScreen> {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.black,
            body: Column(
                children: [
                    //black players clock (top one), i rotated it 180 degrees so it reads
                    // right-side up for the opponent sitting across from me

                    Expanded(
                        child:Transform.rotate(
                            angle: 3.14159
                            child:  Container(
                                color: Colors.grey[600],
                                width:double.infinity,
                                child:const Center(
                                    child:Text(
                                        '15:00',
                                        style: TextStyle(
                                            color:Colors.black,
                                            fontsize: 72,
                                            fontweight: FontWeight.Bold,
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                // Middle control bar- reset/ play/ settings or sound icons
                // imma put these as just placeholders for now, no func wired up for now (11:30am July 26th )

                Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const[
                            Icon(Icons.refresh, color: Colors.white),
                            Icon(Icons.play_arrow, color: Colors.white),
                            Icon(Icons.tune, color: Colors.white),
                            Icon(Icons.volume_up, color: Colors.white),                    
                        ],
                    ),
                ),
                //White Player's clock (bottom)
                Expanded(
            child: Container(
              color: Colors.grey[600],
              width: double.infinity,
              child: const Center(
                child: Text(
                  '15:00',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
    

