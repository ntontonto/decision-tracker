import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/reaction_providers.dart';
import '../../domain/providers/reflection_metrics_provider.dart';

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
  Color color;
  final double celebrateColorIndex; // 0.0 to 1.0 for palette selection

  Particle({
    required this.pos,
    required this.phase,
    required this.attractionStiffness,
    required this.color,
  }) : celebrateColorIndex = math.Random().nextDouble() {
    angle = math.Random().nextDouble() * math.pi * 2;
  }
}

class ParticleSimulationPage extends ConsumerStatefulWidget {
  const ParticleSimulationPage({super.key});

  @override
  ConsumerState<ParticleSimulationPage> createState() => _ParticleSimulationPageState();
}

class _ParticleSimulationPageState extends ConsumerState<ParticleSimulationPage> with SingleTickerProviderStateMixin {
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

  // Live Tuning Parameters (driven by reflection metrics)
  double _vortexStrength = SimConfig.vortexStrength;
  double _targetActivity = SimConfig.targetActivity;
  double _heartbeatInterval = SimConfig.heartbeatInterval;
  double _heartbeatStrength = SimConfig.heartbeatStrength;
  
  // Current metrics for display
  ReflectionMetrics _currentMetrics = ReflectionMetrics.empty;

  // Reaction Parameters
  double _reactionFactor = 0.0;
  ParticleReaction _activeReaction = ParticleReaction.none;

  // Warp State
  WarpState _warp = WarpState();

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

  void _triggerReaction(ParticleReaction type) {
    setState(() {
      _activeReaction = type;
      _reactionFactor = 1.0;
      
      // Add multiple ripples for big impact
      if (type == ParticleReaction.celebrate) {
        for (int i = 0; i < 3; i++) {
          Future.delayed(Duration(milliseconds: i * 300), () {
            if (mounted) {
              setState(() {
                _ripples.add(Ripple(
                  origin: _targetPos,
                  strength: SimConfig.rippleStrength * 1.5,
                ));
              });
            }
          });
        }
      }
    });
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
      
      // Decay reaction factor
      if (_reactionFactor > 0) {
        double decayRate = _activeReaction == ParticleReaction.celebrate ? 0.002 : 0.005;
        _reactionFactor -= decayRate;
        if (_reactionFactor < 0) {
          _reactionFactor = 0;
          _activeReaction = ParticleReaction.none;
        }
      }
      // Update target position
      Offset goal;
      if (_isInteracting) {
        goal = _cursorPos;
      } else {
        // Soft wandering when idle
        double activityBoost = _activeReaction == ParticleReaction.celebrate ? _reactionFactor * 2.5 : 0.0;
        double freqScale = _targetActivity + activityBoost;
        double ampScale = math.sqrt(_targetActivity) + activityBoost * 0.8; 
        
        double driftX = math.sin(_time * 0.0005 * freqScale) * 40.0 * ampScale + 
                        math.cos(_time * 0.0003 * freqScale) * 20.0 * ampScale;
        double driftY = math.cos(_time * 0.0004 * freqScale) * 40.0 * ampScale + 
                        math.sin(_time * 0.0002 * freqScale) * 20.0 * ampScale;
        goal = Offset(_screenSize.width / 2 + driftX, _screenSize.height / 2 + driftY);
      }
      _targetPos = Offset.lerp(_targetPos, goal, SimConfig.targetLerp)!;

      // Dynamic Vortex Direction Reversal
      if (_time >= _nextVortexSwitchTime) {
        _targetVortexDir *= -1.0;
        _nextVortexSwitchTime = _time + 5000.0 + math.Random().nextDouble() * 5000.0;
      }
      _currentVortexDir = lerpDouble(_currentVortexDir, _targetVortexDir, 0.005)!;

      // Periodic Heartbeat
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
        // Freeze physics if holding at the destination
        if (_warp.type == WarpType.holding) {
          continue;
        }

        // Warp Scaling
        double warpSpeedMult = 1.0;
        if (_warp.type == WarpType.entering) {
          warpSpeedMult = 1.0 + _warp.factor * 15.0; // Rapidly accelerate
        } else if (_warp.type == WarpType.exiting) {
          // High speed return from edge
          warpSpeedMult = 1.0 + _warp.factor * 8.0; 
        }

        // 1. Flow Field
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
        
        // Boost attraction during return
        double attractionMult = _warp.type == WarpType.exiting ? 2.5 : 1.0;
        p.vel += toTargetCenter * p.attractionStiffness * attractionMult;

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

        // Warp Force (Centrifugal/Centripetal)
        Offset warpForce = Offset.zero;
        if (_warp.type == WarpType.entering) {
          // Push away from center
          Offset fromCenter = p.pos - _targetPos;
          if (fromCenter.distance > 0.1) {
            warpForce = (fromCenter / fromCenter.distance) * _warp.factor * 2.5;
          }
        }

        // Breathing cycle & Dynamic Instability... (rest as before)
        double breathT = (_time / SimConfig.breathPeriod * math.pi * 2 + p.phase);
        double breathSin = math.sin(breathT);
        double breath = breathSin * SimConfig.breathAmplitude;
        double expansionFactor = math.cos(breathT).clamp(0.0, 1.0);
        
        double instNoiseMult = 1.0 + (expansionFactor * SimConfig.breathInstability * 5.0);
        Offset dynamicFlow = flow * instNoiseMult;
        double currentDamping = SimConfig.damping + (expansionFactor * SimConfig.breathInstability * 0.04).clamp(0.0, 0.05);

        // Centripetal Rotation
        if (toTargetCenter.distance > 10.0) {
          Offset tangential = Offset(-toTargetCenter.dy, toTargetCenter.dx) / toTargetCenter.distance;
          double vortexBoost = _activeReaction == ParticleReaction.celebrate ? _reactionFactor * 1.2 : 0.0;
          double orbitSpeed = ((_vortexStrength + vortexBoost) * _currentVortexDir) / (math.sqrt(toTargetCenter.distance) * 0.4 + 1.0);
          p.vel += tangential * orbitSpeed;
        }

        // Pulse Force
        Offset pulseDir = toTargetCenter.distance > 0.1 ? -toTargetCenter / (toTargetCenter.distance + 1) : Offset.zero;
        Offset pulseForce = pulseDir * (expansionFactor * SimConfig.breathInstability * 0.4);

        // Update velocity and position
        Offset jitter = Offset.zero;
        if (_activeReaction == ParticleReaction.jitter && _reactionFactor > 0) {
          double jitterAmp = _reactionFactor * 5.0;
          jitter = Offset(math.sin(_time * 0.05 + p.phase) * jitterAmp, math.cos(_time * 0.05 + p.phase) * jitterAmp);
        }

        p.vel = (p.vel + dynamicFlow + rippleForce + pulseForce + warpForce) * currentDamping;
        p.pos += (p.vel * warpSpeedMult + jitter);

        // Alignment & Appearance logic
        double distToCenter = toTargetCenter.distance;
        double targetAngle = math.atan2(toTargetCenter.dy, toTargetCenter.dx);
        
        double baseStrength = 0.15;
        double alignmentStrength = 0.01;
        if (distToCenter < 600) {
          double t = (distToCenter / 600.0).clamp(0.0, 1.0);
          alignmentStrength = baseStrength * math.pow(1.0 - t, 2.0).toDouble();
          alignmentStrength = alignmentStrength.clamp(0.005, baseStrength);
          if (_isInteracting) alignmentStrength *= 1.5;
        }

        double diff = targetAngle - p.angle;
        while (diff > math.pi) {
          diff -= math.pi * 2;
        }
        while (diff < -math.pi) {
          diff += math.pi * 2;
        }
        p.angle += diff * alignmentStrength;
        
        double eccInfluence = (1.0 - (distToCenter / 200.0)).clamp(0.0, 1.0);
        p.eccentricity = lerpDouble(SimConfig.eccentricityFar, SimConfig.eccentricityNear, eccInfluence)!;

        // Size scaling
        double sizeFactor = SimConfig.minSizeFactor;
        if (distToCenter < SimConfig.sizeScalingRange) {
          double angle = math.atan2(toTargetCenter.dy, toTargetCenter.dx);
          double wobble = _noise(math.cos(angle) * 0.5, math.sin(angle) * 0.5, _time * SimConfig.sizeNoiseFrequency);
          double peakedRadius = SimConfig.sizeScalingPeak + (wobble * SimConfig.sizeWobbleStrength);
          double localNoise = _noise(p.pos.dx * 0.01, p.pos.dy * 0.01, _time * 0.001);
          double jitteredDist = distToCenter + (localNoise * 15.0);
          double normalizedDist = (jitteredDist / peakedRadius).clamp(0.0, 5.0);
          sizeFactor = math.pow(normalizedDist, SimConfig.sizeScalingExponent) * math.exp(1.0 - math.pow(normalizedDist, SimConfig.sizeScalingExponent));
          sizeFactor = sizeFactor.clamp(SimConfig.minSizeFactor, 1.0);
        }

        double reactionSizeBoost = 1.0;
        if (_activeReaction == ParticleReaction.celebrate && _reactionFactor > 0) {
          reactionSizeBoost = 1.2 + math.sin(_time * 0.03 + p.phase * 10.0) * 0.25 * _reactionFactor;
        }

        p.size = SimConfig.baseSize * (1.0 + breath) * sizeFactor * reactionSizeBoost;
        
        // Warp Opacity/Color (Fade out as they warp away)
        double warpOpacity = 1.0;
        if (_warp.type == WarpType.entering) {
          warpOpacity = (1.0 - _warp.factor).clamp(0.0, 1.0);
        } else if (_warp.type == WarpType.exiting) {
          // Appear as you return
          warpOpacity = (1.0 - _warp.factor).clamp(0.0, 1.0);
        } else if (_warp.type == WarpType.holding) {
          // Hide while in constellation view
          warpOpacity = 0.0;
        }

        if (_reactionFactor > 0) {
          if (_activeReaction == ParticleReaction.celebrate) {
            const palette = [Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00), Color(0xFF4CD964), Color(0xFF5AC8FA), Color(0xFF007AFF), Color(0xFF5856D6), Color(0xFFAF52DE)];
            int idx = (p.celebrateColorIndex * palette.length).floor().clamp(0, palette.length - 1);
            double shimmer = math.sin(_time * 0.015 + p.phase * 5.0) * 0.5 + 0.5;
            Color gleamColor = Color.lerp(palette[idx], Colors.white, shimmer * 0.35)!;
            p.color = Color.lerp(Colors.white.withValues(alpha: 0.8 * warpOpacity), gleamColor.withValues(alpha: warpOpacity), _reactionFactor)!;
          } else if (_activeReaction == ParticleReaction.jitter) {
            p.color = Color.lerp(Colors.white.withValues(alpha: 0.8 * warpOpacity), const Color(0xFFFF4500).withValues(alpha: warpOpacity), _reactionFactor)!;
          }
        } else {
          p.color = Colors.white.withValues(alpha: 0.8 * warpOpacity);
        }
      }
    });
  }

  double _noise(double x, double y, double z) {
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
    ref.listen(reactionProvider, (previous, next) {
      if (next.type != ParticleReaction.none) _triggerReaction(next.type);
    });

    // Warp state listener
    final warpState = ref.watch(warpProvider);
    if (_warp != warpState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _warp = warpState);
        }
      });
    }
    
    final metricsAsync = ref.watch(reflectionMetricsProvider);
    metricsAsync.whenData((metrics) {
      if (_currentMetrics != metrics) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _currentMetrics = metrics;
            _vortexStrength = metrics.reviewCompletionRate * 0.6;
            _targetActivity = metrics.intrinsicMotivationRatio * 3.0;
            final inputRatio = metrics.inputFrequency / 7.0;
            _heartbeatInterval = 60000.0 - (inputRatio * 59000.0);
            _heartbeatStrength = ((metrics.satisfactionScoreAverage - 1.0) / 4.0) * 0.5;
          });
        });
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_screenSize == Size.zero) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          _targetPos = Offset(_screenSize.width / 2, _screenSize.height / 2);
          _cursorPos = _targetPos;
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
                  warp: _warp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final List<Ripple> ripples;
  final WarpState warp;

  ParticlePainter({required this.particles, required this.ripples, required this.warp});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      
      // Calculate stretch based on velocity and warp
      double velocityMag = p.vel.distance;
      double stretch = 1.0;
      double angle = p.angle;

      if (warp.type != WarpType.none && warp.factor > 0) {
        // Stretch along travel vector for motion blur
        stretch = 1.0 + (velocityMag * 2.0 * warp.factor).clamp(0.0, 10.0);
        angle = math.atan2(p.vel.dy, p.vel.dx);
      }

      canvas.rotate(angle);
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * stretch,
          height: p.size * p.eccentricity,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
