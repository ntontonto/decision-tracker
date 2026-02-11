import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Configuration parameters for the simulation.
class SimConfig {
  static const int particleCount = 120;
  static const double baseSize = 6.0;
  static const double minSize = 2.0;
  static const double maxSize = 12.0;
  
  // Flow field constants
  static const double flowStrength = 0.15;
  static const double flowScale = 0.005; // Spatial scale of noise
  static const double flowTimeScale = 0.001;
  static const double damping = 0.94;
  
  // Ripple constants
  static const double rippleStrength = 0.7; // Ultra-subtle sway (was 1.8)
  static const double rippleSpeed = 8.0;
  static const double rippleDecay = 0.99; // Lingers much longer as a faint wave (was 0.985)
  static const double rippleWavelength = 100.0;
  
  // Cursor & Alignment
  static const double cursorInfluenceRadius = 250.0;
  static const double alignStrengthNear = 0.15;
  static const double alignStrengthFar = 0.02;
  static const double alignSmoothing = 0.1;
  static const double eccentricityNear = 0.8; // Slightly oval even when close
  static const double eccentricityFar = 0.15; // Sharper (was 0.4)
  
  // Breathing & Instability
  static const double breathAmplitude = 0.2;
  static const double breathPeriod = 3000.0; // ms
  static const double breathInstability = 0.1; // instability of breathing
  
  // Heartbeat (Periodic Pulse)
  static const double heartbeatStrength = 0.4; // Subdued pulse
  static const double heartbeatInterval = 3000.0; // Synchronized with breathPeriod
  
  // Constraints
  static const double targetLerp = 0.08;
  
  // Refined Attraction & Vortex
  static const double minAttraction = 0.0005;
  static const double maxAttraction = 0.004;
  static const double vortexStrength = 0.12; // Swirling force

  // Inter-particle Repulsion
  static const double repulsionRadius = 45.0; // Further increased
  static const double repulsionStrength = 0.025;

  // Minimalist palette
  static const List<Color> palette = [
    Colors.white,
  ];
}

class Ripple {
  Offset origin;
  double radius = 0;
  double strength;
  double life = 1.0;

  Ripple({required this.origin, this.strength = SimConfig.rippleStrength});

  void update() {
    radius += SimConfig.rippleSpeed;
    life *= SimConfig.rippleDecay;
  }
}

class Particle {
  Offset pos;
  Offset vel = Offset.zero;
  double angle = 0;
  double phase; // For breathing oscillation
  double size = SimConfig.baseSize;
  double eccentricity = SimConfig.eccentricityFar;
  final double attractionStiffness;
  final Color color;

  Particle({
    required this.pos,
    required this.phase,
    required this.attractionStiffness,
    required this.color,
  }) {
    angle = math.Random().nextDouble() * math.pi * 2;
  }
}

class ParticleSimulationPage extends StatefulWidget {
  const ParticleSimulationPage({super.key});

  @override
  State<ParticleSimulationPage> createState() => _ParticleSimulationPageState();
}

class _ParticleSimulationPageState extends State<ParticleSimulationPage> with SingleTickerProviderStateMixin {
  late List<Particle> _particles;
  final List<Ripple> _ripples = [];
  Offset _targetPos = Offset.zero;
  Offset _cursorPos = Offset.zero;
  bool _isInteracting = false;
  
  late Ticker _ticker;
  double _time = 0;
  double _lastHeartbeatTime = 0;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _particles = List.generate(SimConfig.particleCount, (i) {
      return Particle(
        pos: Offset.zero,
        phase: random.nextDouble() * math.pi * 2,
        attractionStiffness: lerpDouble(SimConfig.minAttraction, SimConfig.maxAttraction, random.nextDouble())!,
        color: Colors.white.withValues(alpha: 0.8),
      );
    });

    _ticker = createTicker(_update);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update(Duration elapsed) {
    if (_screenSize == Size.zero) return;

    setState(() {
      _time = elapsed.inMilliseconds.toDouble();
      
      // Update target position
      Offset goal;
      if (_isInteracting) {
        goal = _cursorPos;
      } else {
        // Soft wandering when idle
        double driftX = math.sin(_time * 0.0005) * 40.0 + math.cos(_time * 0.0003) * 20.0;
        double driftY = math.cos(_time * 0.0004) * 40.0 + math.sin(_time * 0.0002) * 20.0;
        goal = Offset(_screenSize.width / 2 + driftX, _screenSize.height / 2 + driftY);
      }
      _targetPos = Offset.lerp(_targetPos, goal, SimConfig.targetLerp)!;

      // 0. Periodic Heartbeat
      if (_time - _lastHeartbeatTime >= SimConfig.heartbeatInterval) {
        _lastHeartbeatTime = _time;
        _ripples.add(Ripple(
          origin: _targetPos,
          strength: SimConfig.heartbeatStrength,
        ));
      }

      // Update ripples
      for (int i = _ripples.length - 1; i >= 0; i--) {
        _ripples[i].update();
        if (_ripples[i].life < 0.01) {
          _ripples.removeAt(i);
        }
      }

      // Update particles
      for (var p in _particles) {
        // 1. Flow Field (Noisier as it goes outwards)
        double distToTarget = (p.pos - _targetPos).distance;
        double noiseStrength = SimConfig.flowStrength * (0.5 + distToTarget / 400.0);
        double centerX = _screenSize.width / 2;
        double centerY = _screenSize.height / 2;
        double relX = p.pos.dx - centerX;
        double relY = p.pos.dy - centerY;

        double noiseX = _noise(_time * SimConfig.flowTimeScale, relX * SimConfig.flowScale, relY * SimConfig.flowScale);
        double noiseY = _noise(relX * SimConfig.flowScale, _time * SimConfig.flowTimeScale, relY * SimConfig.flowScale);
        Offset flow = Offset(noiseX, noiseY) * noiseStrength;

        // 2. Ripple Forces
        Offset rippleForce = Offset.zero;
        for (var r in _ripples) {
          double dist = (p.pos - r.origin).distance;
          double diff = dist - r.radius;
          if (diff.abs() < SimConfig.rippleWavelength / 2) {
            double mag = math.sin((diff / SimConfig.rippleWavelength) * math.pi * 2) * r.life * r.strength;
            rippleForce += (p.pos - r.origin) / (dist + 0.1) * mag;
          }
        }

        // 3. Constant soft attraction to center
        Offset toTargetCenter = _targetPos - p.pos;
        p.vel += toTargetCenter * p.attractionStiffness;

        // 3b. Inter-particle Repulsion
        for (var other in _particles) {
          if (p == other) continue;
          Offset diff = p.pos - other.pos;
          double d2 = diff.dx * diff.dx + diff.dy * diff.dy;
          if (d2 < SimConfig.repulsionRadius * SimConfig.repulsionRadius && d2 > 0.1) {
            double d = math.sqrt(d2);
            double force = (1.0 - d / SimConfig.repulsionRadius) * SimConfig.repulsionStrength;
            p.vel += diff / d * force;
          }
        }

        // Breathing cycle & Dynamic Instability
        double breathT = (_time / SimConfig.breathPeriod * math.pi * 2 + p.phase);
        double breathSin = math.sin(breathT);
        double breath = breathSin * SimConfig.breathAmplitude;
        
        // Expansion detection
        double breathCos = math.cos(breathT);
        double expansionFactor = breathCos.clamp(0.0, 1.0);
        
        // Unified Instability Side-effects
        double instNoiseMult = 1.0 + (expansionFactor * SimConfig.breathInstability * 5.0);
        Offset dynamicFlow = flow * instNoiseMult;
        double currentDamping = SimConfig.damping + (expansionFactor * SimConfig.breathInstability * 0.04).clamp(0.0, 0.05);

        // 3c. Centripetal Rotation (Vortex Effect)
        if (toTargetCenter.distance > 10.0) {
          Offset tangential = Offset(-toTargetCenter.dy, toTargetCenter.dx) / toTargetCenter.distance;
          double orbitSpeed = SimConfig.vortexStrength / (math.sqrt(toTargetCenter.distance) * 0.5 + 1.0);
          p.vel += tangential * orbitSpeed;
        }

        // 3d. Pulse Force (Outward push during expansion)
        Offset pulseDir = toTargetCenter.distance > 0.1 ? -toTargetCenter / (toTargetCenter.distance + 1) : Offset.zero;
        Offset pulseForce = pulseDir * (expansionFactor * SimConfig.breathInstability * 0.4);

        // 4. Update velocity and position
        p.vel = (p.vel + dynamicFlow + rippleForce + pulseForce) * currentDamping;
        p.pos += p.vel;

        // 5. Alignment & Appearance logic
        double distToCenter = toTargetCenter.distance;
        
        // Always face the current wandering or dragged target
        double targetAngle = math.atan2(toTargetCenter.dy, toTargetCenter.dx);
        
        // Alignment strength based on distance
        double baseStrength = 0.15;
        double alignmentStrength = 0.01;
        
        if (distToCenter < 600) {
          double t = (distToCenter / 600.0).clamp(0.0, 1.0);
          alignmentStrength = baseStrength * math.pow(1.0 - t, 2.0).toDouble();
          alignmentStrength = alignmentStrength.clamp(0.005, baseStrength);
          
          if (_isInteracting) {
            alignmentStrength *= 1.5;
          }
        }

        // Smoothly rotate
        double diff = targetAngle - p.angle;
        while (diff > math.pi) {
          diff -= math.pi * 2;
        }
        while (diff < -math.pi) {
          diff += math.pi * 2;
        }
        p.angle += diff * alignmentStrength;
        
        // Eccentricity
        double eccInfluence = (1.0 - (distToCenter / 200.0)).clamp(0.0, 1.0);
        p.eccentricity = lerpDouble(SimConfig.eccentricityFar, SimConfig.eccentricityNear, eccInfluence)!;

        // Distance-based size scaling
        double sizeFactor = 0.0;
        if (distToCenter < 500) {
          double normalizedDist = distToCenter / 140.0;
          sizeFactor = math.pow(normalizedDist, 1.2) * math.exp(1.0 - math.pow(normalizedDist, 1.2));
          sizeFactor = sizeFactor.clamp(0.05, 1.0);
        } else {
          sizeFactor = 0.05;
        }

        p.size = SimConfig.baseSize * (1.0 + breath) * sizeFactor;
      }
    });
  }

  // Refined pseudo-noise function for better symmetry and less bias
  double _noise(double x, double y, double z) {
    // Combine multiple periodic functions with different phase offsets to reduce directional bias
    double n1 = math.sin(x + y) * math.cos(y - z) * math.sin(z + x);
    double n2 = math.sin(x * 1.5 - y * 1.2) * math.cos(y * 1.1 + z * 0.9);
    return (n1 + n2 * 0.5) / 1.5;
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _cursorPos = details.localPosition;
      _isInteracting = true;
      _ripples.add(Ripple(origin: _cursorPos));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _cursorPos = details.localPosition;
      _isInteracting = true;
    });
  }

  void _handleInteractionEnd() {
    setState(() {
      _isInteracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark sleek look
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_screenSize == Size.zero) {
            _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            _targetPos = Offset(_screenSize.width / 2, _screenSize.height / 2);
            _cursorPos = _targetPos;
            // Distribute particles initially
            final random = math.Random();
            for (var p in _particles) {
              double r = random.nextDouble() * 200;
              double a = random.nextDouble() * math.pi * 2;
              p.pos = _targetPos + Offset(math.cos(a) * r, math.sin(a) * r);
            }
          }
          return GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: (_) => _handleInteractionEnd(),
            onTapCancel: () => _handleInteractionEnd(),
            onPanStart: (d) => setState(() {
              _cursorPos = d.localPosition;
              _isInteracting = true;
            }),
            onPanUpdate: _handlePanUpdate,
            onPanEnd: (_) => _handleInteractionEnd(),
            onLongPressStart: (d) {
              _cursorPos = d.localPosition;
              _isInteracting = true;
            },
            onLongPressEnd: (_) => _handleInteractionEnd(),
            child: CustomPaint(
              size: Size.infinite,
              painter: ParticlePainter(
                particles: _particles,
                ripples: _ripples,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final List<Ripple> ripples;

  ParticlePainter({required this.particles, required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.angle);
      
      // Draw ellipse
      // width is size, height is size * eccentricity
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * p.eccentricity,
        ),
        paint,
      );
      canvas.restore();
    }

    // Optional: debug ripples
    /*
    for (var r in ripples) {
      canvas.drawCircle(
        r.origin,
        r.radius,
        Paint()
          ..color = Colors.white.withOpacity(r.life * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    */
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
