import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Free OpenStreetMap map (flutter_map) showing the bus and the child's
/// pickup/drop-off point. The tile provider can be swapped later without
/// touching callers — mirroring the backend MapProvider abstraction.
class TransportBusMap extends StatelessWidget {
  const TransportBusMap({
    super.key,
    this.busLat,
    this.busLng,
    this.childLat,
    this.childLng,
    this.height = 300,
  });

  final double? busLat;
  final double? busLng;
  final double? childLat;
  final double? childLng;

  final double height;

  @override
  Widget build(BuildContext context) {
    final hasBus = busLat != null && busLng != null;
    final hasChild = childLat != null && childLng != null;

    final center = hasBus
        ? LatLng(busLat!, busLng!)
        : hasChild
            ? LatLng(childLat!, childLng!)
            : const LatLng(24.7136, 46.6753);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: hasBus || hasChild ? 14 : 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.school.mobile',
            ),
            MarkerLayer(
              markers: [
                if (hasBus)
                  Marker(
                    point: LatLng(busLat!, busLng!),
                    width: 44,
                    height: 44,
                    child: const _BusMarker(),
                  ),
                if (hasChild)
                  Marker(
                    point: LatLng(childLat!, childLng!),
                    width: 36,
                    height: 36,
                    child: const _ChildMarker(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BusMarker extends StatelessWidget {
  const _BusMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff007AFF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
    );
  }
}

class _ChildMarker extends StatelessWidget {
  const _ChildMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff34C759),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
    );
  }
}
