import 'dart:math' as math;
import 'package:flutter/material.dart';

class Page3D extends StatefulWidget {
  const Page3D({super.key});

  @override
  State<Page3D> createState() => _Page3D();
}

class _Page3D extends State<Page3D> {
  static const rawData = [
    [3.0, 5.0, 2.0, 8.0],
    [6.0, 7.0, 3.0, 4.0],
    [9.0, 3.0, 5.0, 1.0],
    [4.0, 6.0, 8.0, 7.0],
  ];

  static const interpolationFactor = 20;
  static const spacingRatio = 0.0;
  static const verticalScale = 90.0;
  static const sceneSize = Size(600, 600);
  static const minZoom = 0.4;
  static const maxZoom = 3.5;

  late final List<List<double>> data =
  upscaleGrid(rawData, interpolationFactor);

  double rotationX = 65;
  double rotationY = -40;
  double zoom = 1.2;
  double _baseZoom = 1.2;
  Offset? _lastDragPoint;

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = zoom;
    _lastDragPoint = details.pointerCount == 1 ? details.focalPoint : null;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount > 1) {
        zoom = (_baseZoom * details.scale).clamp(minZoom, maxZoom);
        _lastDragPoint = null;
      } else {
        final currentPoint = details.focalPoint;
        if (_lastDragPoint != null) {
          final delta = currentPoint - _lastDragPoint!;
          rotationY += delta.dx * 0.4;
          rotationX -= delta.dy * 0.4;
        }
        _lastDragPoint = currentPoint;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastDragPoint = null;
  }

  @override
  Widget build(BuildContext context) {
    final flattened = data.expand((row) => row).toList();
    final maxValue = flattened.reduce(math.max);
    final minValue = flattened.reduce(math.min);

    return Scaffold(
      appBar: AppBar(title: const Text('3D Heightmap Surface')),
      body: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Center(
          child: ClipRect(
            child: Transform.scale(
              scale: zoom,
              alignment: Alignment.center,
              child: SizedBox(
                width: sceneSize.width,
                height: sceneSize.height,
                child: CustomPaint(
                  painter: HeightmapSurfacePainter(
                    data: data,
                    min: minValue,
                    max: maxValue,
                    rotationX: rotationX,
                    rotationY: rotationY,
                    spacingRatio: spacingRatio,
                    scaleZ: verticalScale,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<List<double>> upscaleGrid(List<List<double>> source, int factor) {
  if (factor <= 1) return source;

  final rows = source.length;
  final cols = source[0].length;
  final newRows = (rows - 1) * factor + 1;
  final newCols = (cols - 1) * factor + 1;

  final result = List.generate(
    newRows,
        (_) => List<double>.filled(newCols, 0.0),
  );

  for (int r = 0; r < rows - 1; r++) {
    for (int c = 0; c < cols - 1; c++) {
      final topLeft = source[r][c];
      final topRight = source[r][c + 1];
      final bottomLeft = source[r + 1][c];
      final bottomRight = source[r + 1][c + 1];

      for (int i = 0; i <= factor; i++) {
        final verticalT = i / factor;
        final left = _lerp(topLeft, bottomLeft, verticalT);
        final right = _lerp(topRight, bottomRight, verticalT);

        for (int j = 0; j <= factor; j++) {
          final horizontalT = j / factor;
          result[r * factor + i][c * factor + j] =
              _lerp(left, right, horizontalT);
        }
      }
    }
  }

  return result;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

class HeightmapSurfacePainter extends CustomPainter {
  final List<List<double>> data;
  final double min;
  final double max;
  final double rotationX;
  final double rotationY;
  final double spacingRatio;
  final double scaleZ;
  final double perspective;

  HeightmapSurfacePainter({
    required this.data,
    required this.min,
    required this.max,
    required this.rotationX,
    required this.rotationY,
    this.spacingRatio = 0.0,
    this.scaleZ = 40.0,
    this.perspective = 0.0025,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = data.length;
    final cols = data[0].length;
    if (rows < 2 || cols < 2) return;

    final cellSize = math.min(size.width / cols, size.height / rows);
    final pitch = cellSize * (1 + spacingRatio);
    final cx = size.width / 2;
    final cy = size.height / 2;

    final radX = rotationX * math.pi / 180;
    final radY = rotationY * math.pi / 180;
    final cosX = math.cos(radX);
    final sinX = math.sin(radX);
    final cosY = math.cos(radY);
    final sinY = math.sin(radY);

    final vertexGrid = List.generate(rows, (row) {
      return List<_Vertex>.generate(cols, (col) {
        final normalized =
        max - min == 0 ? 0.0 : (data[row][col] - min) / (max - min);
        final height = normalized * scaleZ;

        final worldX = (col - (cols - 1) / 2) * pitch;
        final worldZ = (row - (rows - 1) / 2) * pitch;
        final world = _Vector3(worldX, height, worldZ);
        final camera = _rotate(world, cosX, sinX, cosY, sinY);

        final perspectiveScale = 1 / (1 + camera.z * perspective);
        final px = cx + camera.x * perspectiveScale;
        final py = cy - camera.y * perspectiveScale;

        return _Vertex(
          screen: Offset(px, py),
          camera: camera,
          depth: camera.z,
          value: data[row][col],
        );
      });
    });

    final faces = <_Face>[];
    final lightDir = _Vector3(-0.5, 1.0, 0.7).normalized();
    const ambientStrength = 0.3;
    const specularStrength = 0.4;
    const shininess = 32.0;

    for (int y = 0; y < rows - 1; y++) {
      for (int x = 0; x < cols - 1; x++) {
        final v00 = vertexGrid[y][x];
        final v10 = vertexGrid[y][x + 1];
        final v11 = vertexGrid[y + 1][x + 1];
        final v01 = vertexGrid[y + 1][x];

        final avgDepth = (v00.depth + v10.depth + v11.depth + v01.depth) / 4;
        final avgValue = (v00.value + v10.value + v11.value + v01.value) / 4;

        final normal = _computeNormal(v00.camera, v10.camera, v01.camera);

        // **Diffuse**
        double diffuse = math.max(normal.dot(lightDir), 0.0);

        // **Ambient**
        double ambient = ambientStrength;

        // **Specular approximation**
        final viewDir = _Vector3(0, 0, 1);
        final reflectDir =
        (normal * 2 * normal.dot(lightDir) - lightDir).normalized();
        double spec =
            math.pow(math.max(viewDir.dot(reflectDir), 0.0), shininess)
                .toDouble() *
                specularStrength;

        double intensity = (ambient + diffuse + spec).clamp(0.0, 1.0);

        faces.add(
          _Face(
            points: [v00, v10, v11, v01].map((v) => v.screen).toList(),
            color: _shadeColor(_getJetColor(avgValue), intensity),
            depth: avgDepth,
          ),
        );
      }
    }

    faces.sort((a, b) => b.depth.compareTo(a.depth));

    final paint = Paint();
    for (final face in faces) {
      final path = Path()
        ..moveTo(face.points[0].dx, face.points[0].dy)
        ..lineTo(face.points[1].dx, face.points[1].dy)
        ..lineTo(face.points[2].dx, face.points[2].dy)
        ..lineTo(face.points[3].dx, face.points[3].dy)
        ..close();
      paint.color = face.color;
      canvas.drawPath(path, paint);
    }
  }

  _Vector3 _computeNormal(_Vector3 a, _Vector3 b, _Vector3 c) {
    final ab = b - a;
    final ac = c - a;
    return ab.cross(ac).normalized();
  }

  Color _shadeColor(Color base, double intensity) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness * intensity).clamp(0.0, 1.0))
        .toColor();
  }

  Color _getJetColor(double value) {
    if (max - min == 0) return Colors.blue;
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    if (normalized < 0.125) {
      return Color.lerp(Colors.blue.shade900, Colors.blue, normalized / 0.125)!;
    } else if (normalized < 0.375) {
      return Color.lerp(Colors.blue, Colors.cyan, (normalized - 0.125) / 0.25)!;
    } else if (normalized < 0.625) {
      return Color.lerp(
          Colors.cyan, Colors.yellow, (normalized - 0.375) / 0.25)!;
    } else if (normalized < 0.875) {
      return Color.lerp(
          Colors.yellow, Colors.orange, (normalized - 0.625) / 0.25)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red,
          (normalized - 0.875) / 0.125)!;
    }
  }

  @override
  bool shouldRepaint(covariant HeightmapSurfacePainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.data != data ||
        oldDelegate.spacingRatio != spacingRatio ||
        oldDelegate.scaleZ != scaleZ;
  }
}

class _Vertex {
  final Offset screen;
  final _Vector3 camera;
  final double depth;
  final double value;

  const _Vertex({
    required this.screen,
    required this.camera,
    required this.depth,
    required this.value,
  });
}

class _Face {
  final List<Offset> points;
  final Color color;
  final double depth;

  const _Face({
    required this.points,
    required this.color,
    required this.depth,
  });
}

class _Vector3 {
  final double x;
  final double y;
  final double z;

  const _Vector3(this.x, this.y, this.z);

  _Vector3 operator -(_Vector3 other) =>
      _Vector3(x - other.x, y - other.y, z - other.z);

  _Vector3 operator *(double t) => _Vector3(x * t, y * t, z * t);

  _Vector3 cross(_Vector3 other) => _Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double dot(_Vector3 other) => x * other.x + y * other.y + z * other.z;

  _Vector3 normalized() {
    final len = math.sqrt(x * x + y * y + z * z);
    if (len == 0) return const _Vector3(0, 0, 0);
    return _Vector3(x / len, y / len, z / len);
  }
}

_Vector3 _rotate(_Vector3 point, double cosX, double sinX, double cosY,
    double sinY) {
  final x1 = point.x * cosY + point.z * sinY;
  final z1 = -point.x * sinY + point.z * cosY;

  final y2 = point.y * cosX - z1 * sinX;
  final z2 = point.y * sinX + z1 * cosX;

  return _Vector3(x1, y2, z2);
}
