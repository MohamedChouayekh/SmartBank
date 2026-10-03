import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/partner_establishment.dart';
import '../models/partner_promotion.dart';
import '../services/api_service.dart';

class BiatPrivilegesMapScreen extends StatefulWidget {
  const BiatPrivilegesMapScreen({super.key});

  @override
  State<BiatPrivilegesMapScreen> createState() =>
      _BiatPrivilegesMapScreenState();
}

class _BiatPrivilegesMapScreenState extends State<BiatPrivilegesMapScreen> {
  final ApiService _apiService = ApiService();

  List<PartnerEstablishment> _establishments = [];
  List<PartnerPromotion> _promotions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _mapGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _establishments = [];
      _promotions = [];
    });

    try {
      final results = await Future.wait<dynamic>([
        _apiService.getPartnerEstablishments(),
        _apiService.getPartnerPromotions(),
      ]);

      final establishments = (results[0] as List<PartnerEstablishment>)
          .where((establishment) => establishment.active)
          .toList(growable: false);
      final promotions = results[1] as List<PartnerPromotion>;

      if (!mounted) return;

      setState(() {
        _establishments = establishments;
        _promotions = promotions;
        _mapGeneration++;
        _isLoading = false;
      });
    } on ApiServiceException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Impossible de charger les établissements. Vérifiez votre connexion puis réessayez.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIAT Privilèges — Carte'),
        actions: [
          IconButton(
            tooltip: 'Actualiser les établissements',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_outlined,
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      );
    }

    if (_establishments.isEmpty) {
      return _buildMessageState(
        icon: Icons.location_off_outlined,
        message: 'Aucun établissement partenaire disponible actuellement.',
      );
    }

    final firstEstablishment = _establishments.first;

    return GoogleMap(
      key: ValueKey(_mapGeneration),
      initialCameraPosition: CameraPosition(
        target: LatLng(
          firstEstablishment.latitude,
          firstEstablishment.longitude,
        ),
        zoom: _establishments.length == 1 ? 14 : 7,
      ),
      markers: _establishments.map(_buildMarker).toSet(),
      onMapCreated: _fitAllMarkers,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  Marker _buildMarker(PartnerEstablishment establishment) {
    return Marker(
      markerId: MarkerId('partner-establishment-${establishment.id}'),
      position: LatLng(establishment.latitude, establishment.longitude),
      infoWindow: InfoWindow(
        title: establishment.name,
        snippet: '${establishment.category} · ${establishment.city}',
      ),
      onTap: () => _showEstablishmentDetails(establishment),
    );
  }

  void _fitAllMarkers(GoogleMapController controller) {
    if (_establishments.length < 2) return;

    final latitudes = _establishments.map((item) => item.latitude);
    final longitudes = _establishments.map((item) => item.longitude);
    final south = latitudes.reduce((a, b) => a < b ? a : b);
    final north = latitudes.reduce((a, b) => a > b ? a : b);
    final west = longitudes.reduce((a, b) => a < b ? a : b);
    final east = longitudes.reduce((a, b) => a > b ? a : b);

    if (south == north || west == east) return;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        48,
      ),
    );
  }

  void _showEstablishmentDetails(PartnerEstablishment establishment) {
    final establishmentPromotions = _promotions
        .where((promotion) => promotion.establishmentId == establishment.id)
        .toList(growable: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.48,
        minChildSize: 0.32,
        maxChildSize: 0.88,
        builder: (context, scrollController) => _buildDetailsSheet(
          context,
          scrollController,
          establishment,
          establishmentPromotions,
        ),
      ),
    );
  }

  Widget _buildDetailsSheet(
    BuildContext context,
    ScrollController scrollController,
    PartnerEstablishment establishment,
    List<PartnerPromotion> promotions,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            establishment.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            establishment.category,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow(theme, Icons.location_city_outlined, establishment.city),
          const SizedBox(height: 9),
          _detailRow(theme, Icons.place_outlined, establishment.address),
          const SizedBox(height: 20),
          Text(
            'Offres disponibles',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (promotions.isEmpty)
            Text(
              'Aucune promotion active associée à cet établissement.',
              style: theme.textTheme.bodyMedium,
            )
          else
            for (var index = 0; index < promotions.length; index++) ...[
              if (index > 0) const Divider(height: 24),
              _buildPromotionDetails(theme, promotions[index]),
            ],
        ],
      ),
    );
  }

  Widget _buildPromotionDetails(ThemeData theme, PartnerPromotion promotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '-${_formatPercent(promotion.discountPercent)} %',
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF087A5B),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (promotion.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(promotion.description!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 6),
        Text(
          'Du ${_formatDate(promotion.startDate)} au ${_formatDate(promotion.endDate)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  String _formatPercent(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');

    return formatted.replaceAll('.', ',');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} à $hour:$minute';
  }
}
