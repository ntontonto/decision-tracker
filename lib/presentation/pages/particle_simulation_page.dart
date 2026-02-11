import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Configuration parameters for the simulation.
class SimConfig {
  static const int particleCount = 120;
  static const double baseSize = 6.0;
  static const double sizeScalingRange = 400.0;
  static const double sizeScalingPeak = 140.0;
  static const double sizeScalingExponent = 1.2;
  static const double minSizeFactor = 0.05;
  static const double sizeWobbleStrength = 40.0; // Max deviation of the ring
  static const double sizeNoiseFrequency = 0.0003; // Speed of the wobble
  
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
  static const double targetActivity = 2.0; // Master control for wander speed/amplitude
  
  // Refined Attraction & Vortex
  static const double minAttraction = 0.0005;
  static const double maxAttraction = 0.004;
  static const double vortexStrength = 0.2; // Swirling force

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
  double _targetVortexDir = 1.0;
  double _currentVortexDir = 1.0;
  double _nextVortexSwitchTime = 15000.0; // Random switch interval
  Size _screenSize = Size.zero;

  // Live Tuning Parameters
  double _vortexStrength = SimConfig.vortexStrength;
  double _targetActivity = SimConfig.targetActivity;
  double _heartbeatInterval = SimConfig.heartbeatInterval;
  double _heartbeatStrength = SimConfig.heartbeatStrength;
  final bool _showDebugUI = false;

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
    
    // Initial random switch time (5s to 10s)
    _nextVortexSwitchTime = 5000.0 + random.nextDouble() * 5000.0;

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
        // Base frequencies/amplitudes scaled by activity
        double freqScale = _targetActivity;
        double ampScale = math.sqrt(_targetActivity); // Milder growth for amplitude to keep flock together
        
        double driftX = math.sin(_time * 0.0005 * freqScale) * 40.0 * ampScale + 
                        math.cos(_time * 0.0003 * freqScale) * 20.0 * ampScale;
        double driftY = math.cos(_time * 0.0004 * freqScale) * 40.0 * ampScale + 
                        math.sin(_time * 0.0002 * freqScale) * 20.0 * ampScale;
        goal = Offset(_screenSize.width / 2 + driftX, _screenSize.height / 2 + driftY);
      }
      _targetPos = Offset.lerp(_targetPos, goal, SimConfig.targetLerp)!;

      // 0. Dynamic Vortex Direction Reversal
      if (_time >= _nextVortexSwitchTime) {
        _targetVortexDir *= -1.0;
        // Set next switch time (5s to 10s later)
        _nextVortexSwitchTime = _time + 5000.0 + math.Random().nextDouble() * 5000.0;
      }
      // Extremely smooth transition for reversal (lerp)
      _currentVortexDir = lerpDouble(_currentVortexDir, _targetVortexDir, 0.005)!;

      // 0. Periodic Heartbeat
      if (_time - _lastHeartbeatTime >= _heartbeatInterval) {
        _lastHeartbeatTime = _time;
        _ripples.add(Ripple(
          origin: _targetPos,
          strength: _heartbeatStrength,
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
          double orbitSpeed = (_vortexStrength * _currentVortexDir) / (math.sqrt(toTargetCenter.distance) * 0.5 + 1.0);
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

        // Distance-based size scaling (Organic Bubble Ring)
        double sizeFactor = SimConfig.minSizeFactor;
        if (distToCenter < SimConfig.sizeScalingRange) {
          // 1. Wobble the peak radius based on angle and time for a ring-like deformation
          double angle = math.atan2(toTargetCenter.dy, toTargetCenter.dx);
          double wobble = _noise(
            math.cos(angle) * 0.5, 
            math.sin(angle) * 0.5, 
            _time * SimConfig.sizeNoiseFrequency
          );
          double peakedRadius = SimConfig.sizeScalingPeak + (wobble * SimConfig.sizeWobbleStrength);

          // 2. Add local jitter to the distance calculation for diffuse boundaries
          double localNoise = _noise(p.pos.dx * 0.01, p.pos.dy * 0.01, _time * 0.001);
          double jitteredDist = distToCenter + (localNoise * 15.0);

          double normalizedDist = (jitteredDist / peakedRadius).clamp(0.0, 5.0);
          
          // Bell curve formula to create the ring effect
          sizeFactor = math.pow(normalizedDist, SimConfig.sizeScalingExponent) * 
                       math.exp(1.0 - math.pow(normalizedDist, SimConfig.sizeScalingExponent));
          
          sizeFactor = sizeFactor.clamp(SimConfig.minSizeFactor, 1.0);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // ... (existing code omitted for brevity in thought, but tool needs exact match)
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
        return Stack(
          children: [
            GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: (_) => _handleInteractionEnd(),
              onTapCancel: () => _handleInteractionEnd(),
              onPanStart: (d) => setState(() {
                _cursorPos = d.localPosition;
                _isInteracting = true;
              }),
              onPanUpdate: _handlePanUpdate,
              onPanEnd: (_) => _handleInteractionEnd(),
              child: CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(
                  particles: _particles,
                  ripples: _ripples,
                ),
              ),
            ),
            // Debug Panel (Hidden by default, can be toggled via external means if needed)
            if (_showDebugUI)
              Positioned(
                top: 50,
                right: 20,
                child: _buildDebugPanel(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDebugPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          color: Colors.white.withValues(alpha: 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSlider("Vortex", _vortexStrength, 0.0, 0.6, (v) => setState(() => _vortexStrength = v)),
              _buildSlider("Activity", _targetActivity, 0.0, 3.0, (v) => setState(() => _targetActivity = v)),
              _buildSlider("Pulse Interval", _heartbeatInterval, 1000.0, 60000.0, (v) => setState(() => _heartbeatInterval = v)),
              _buildSlider("Pulse Power", _heartbeatStrength, 0.0, 0.5, (v) => setState(() => _heartbeatStrength = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.white70,
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
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
