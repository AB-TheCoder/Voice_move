import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const VccnApp());
}

class VccnApp extends StatelessWidget {
  const VccnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedmodebanner: false,
        title: 'VCCN',
        home: const ClockScreen(),
        );
    }
}

class TimeControl {
    final String label;
    final int minutes;
    final int incrementsSeconds;

    const TimeControl(this.label, this.minute, this.incrementSecoonds);

}
const List<TimeControl> presets = [
    TimeControl("1 min", 1, 0),
    TimeControl("2 | 1", 2, 1),
    TimeControl("3 min", 3, 0),
    TimeControl("5 min", 5, 0),
    TimeControl("5 | 3", 5, 3),
    TimeControl("10 min", 10, 0),
    Timecontrol("15 | 10", 15, 10),
    TimeControl("30 min", 30, 0),
];


class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  TimeControl currentControl = presets[7]; //setting default to 15|10
  late Duration whiteTime = Duration(minutes: currentControl.minutes);
  late Duration blackTime = Duration(minutes: currentControl.minutes);
  int whiteMoves = 0;
  int blackMoves = 1;
  bool whiteToMove = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  viod _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
            if (whiteToMove) {
                whiteTime -= const Duration(seconds: 1);
            } else {
                blackTime -= const Duration(seconds: 1);
            }
        });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

   String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showTimeControlSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202020),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Select time control",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...presets.map((tc) => ListTile(
                  title: Text(tc.label, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      currentControl = tc;
                      whiteTime = Duration(minutes: tc.minutes);
                      blackTime = Duration(minutes: tc.minutes);
                    });
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContent context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Column(
                children: [
                    //m writing the code again for black and white
                ]
            )
        )
    )
  }


            // Black's side of the screen(inverted)
          Expanded(
            child: Transform.rotate(
              angle: pi, //i wrote pi instead of 3.141 coz im a cool boy lmao
              child: GestureDetector(
                onTap: () {},
                child:Container(
                    width: double.infinity,
                    color: const Color(0xFF8B8B8B),
                    child: Stack(
                        children: [

                            Positioned(
                                top: 20,
                                right: 20,
                                child: Text(
                                    "Moves: 1",
                                    style: textStyle(
                                        fontSize: 24,
                                        color: Colors.grey.shade900,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                            ),

                            const Center(
                                child: Text(
                                    '15:00',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 100,
                                        fontWeight: FontWeight.w700,
                                    ),
                                ),
                            ),

                            Positioned(
                                bottom: 30,
                                left: 0,
                                right:0,
                                child:Column(
                                    chilren: const [

                                        Icon(
                                            Icons.tune,
                                            size: 32, 
                                            color: Colors.black,
                                        ),

                                        SizedBox(height: 8),

                                        Text(
                                            "15 min | 10 sec",
                                            style: TextStyle(
                                                fontsize: 24,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                            ),

                                        ),

                                    ],

                                ),

                            ),

                        ],

                    ),

                ),

            ),

        ),

        // Control bar attempt

        Container(
            height: 75
            color: const Color(0xFF202020),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 34,
                        ),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: cnst Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                        ),
                    ),

                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 34,

                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 34,
                        ),
                    ),
                ],
            ),
        ),

        //white size now

        Expanded 