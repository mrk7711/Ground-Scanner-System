import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'page_3d.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2D Heatmap with Zoom',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const Page2D(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 2D Heatmap
class Page2D extends StatefulWidget {
  const Page2D({super.key});

  @override
  State<Page2D> createState() => _Page2D();
}

class _Page2D extends State<Page2D> {
  static const List<List<double>> data = [
    [3, 5, 2, 8],
    [6, 7, 3, 4],
    [9, 3, 5, 1],
    [4, 6, 8, 7],
  ];

  double? touchedX;
  double? touchedY;
  double? touchedValue;

  @override
  Widget build(BuildContext context) {
    final flatData = data.expand((e) => e).toList();
    final maxValue = flatData.isNotEmpty ? flatData.reduce(math.max) : 0.0;
    final minValue = flatData.isNotEmpty ? flatData.reduce(math.min) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('2D Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.threed_rotation),
            tooltip: 'Go to 3D',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Page3D()),
              );
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth; // اندازه کامل صفحه

          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: GestureDetector(
                onPanDown: (details) => _handleTouch(details.localPosition, size, minValue, maxValue),
                onPanUpdate: (details) => _handleTouch(details.localPosition, size, minValue, maxValue),
                onPanEnd: (_) => setState(() {
                  touchedX = null;
                  touchedY = null;
                  touchedValue = null;
                }),
                child: Stack(
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: HeatmapPainter(data: data, min: minValue, max: maxValue),
                      ),
                    ),
                    if (touchedValue != null)
                      Positioned(
                        left: touchedX!.clamp(0, size - 60),
                        top: touchedY!.clamp(0, size - 30),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          color: Colors.black.withOpacity(0.7),
                          child: Text(
                            touchedValue!.toStringAsFixed(2),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTouch(Offset localPos, double size, double min, double max) {
    double fx = (localPos.dx / size) * (data[0].length - 1);
    double fy = (localPos.dy / size) * (data.length - 1);
    double value = HeatmapPainter(data: data, min: min, max: max).interpolate(fx, fy, data);

    setState(() {
      touchedX = localPos.dx;
      touchedY = localPos.dy;
      touchedValue = value;
    });
  }
}

class HeatmapPainter extends CustomPainter {
  final List<List<double>> data;
  final double min;
  final double max;

  HeatmapPainter({required this.data, required this.min, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    int rows = data.length;
    int cols = data[0].length;

    double cellWidth = size.width / (cols - 1);
    double cellHeight = size.height / (rows - 1);

    Paint paint = Paint();

    int resolution = 20;
    double stepX = cellWidth / resolution;
    double stepY = cellHeight / resolution;

    for (double y = 0; y < size.height; y += stepY) {
      for (double x = 0; x < size.width; x += stepX) {
        double fx = (x / cellWidth);
        double fy = (y / cellHeight);

        double value = interpolate(fx, fy, data);
        Color color = getJetColor(value, min, max);
        paint.color = color;

        canvas.drawRect(Rect.fromLTWH(x, y, stepX + 1, stepY + 1), paint);
      }
    }
  }

  double interpolate(double x, double y, List<List<double>> data) {
    int x0 = x.floor().clamp(0, data[0].length - 1);
    int x1 = (x0 + 1).clamp(0, data[0].length - 1);
    int y0 = y.floor().clamp(0, data.length - 1);
    int y1 = (y0 + 1).clamp(0, data.length - 1);

    double dx = x - x0;
    double dy = y - y0;

    double v00 = data[y0][x0];
    double v10 = data[y0][x1];
    double v01 = data[y1][x0];
    double v11 = data[y1][x1];

    double v0 = v00 * (1 - dx) + v10 * dx;
    double v1 = v01 * (1 - dx) + v11 * dx;
    return v0 * (1 - dy) + v1 * dy;
  }

  Color getJetColor(double value, double min, double max) {
    double normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);

    if (normalized < 0.125) {
      return Color.lerp(Colors.blue.shade900, Colors.blue, normalized / 0.125)!;
    } else if (normalized < 0.375) {
      return Color.lerp(Colors.blue, Colors.cyan, (normalized - 0.125) / 0.25)!;
    } else if (normalized < 0.625) {
      return Color.lerp(Colors.cyan, Colors.yellow, (normalized - 0.375) / 0.25)!;
    } else if (normalized < 0.875) {
      return Color.lerp(Colors.yellow, Colors.orange, (normalized - 0.625) / 0.25)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (normalized - 0.875) / 0.125)!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
