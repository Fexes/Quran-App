import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../domain/entities/zakat_calculation.dart';

class ZakatPage extends StatefulWidget {
  const ZakatPage({super.key});

  @override
  State<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends State<ZakatPage> {
  static const _storageKey = 'worship-tools:zakat-inputs';

  late final LibraryUserDataStore _store;
  final _currency = TextEditingController(text: 'PKR');
  final _goldPrice = TextEditingController();
  final _silverPrice = TextEditingController();
  final _liabilities = TextEditingController();
  final _assets = <String, TextEditingController>{
    for (final category in zakatAssetCategories)
      category.id: TextEditingController(),
  };
  NisabBasis _basis = NisabBasis.silver;
  DateTime _priceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _store = getIt<LibraryUserDataStore>();
    _restore();
    for (final controller in [
      _currency,
      _goldPrice,
      _silverPrice,
      _liabilities,
      ..._assets.values,
    ]) {
      controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _currency,
      _goldPrice,
      _silverPrice,
      _liabilities,
      ..._assets.values,
    ]) {
      controller
        ..removeListener(_changed)
        ..dispose();
    }
    super.dispose();
  }

  void _restore() {
    final raw = _store.noteFor(_storageKey);
    if (raw.isEmpty) {
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _currency.text = json['currency'] as String? ?? 'PKR';
      _goldPrice.text = json['goldPrice']?.toString() ?? '';
      _silverPrice.text = json['silverPrice']?.toString() ?? '';
      _liabilities.text = json['liabilities']?.toString() ?? '';
      _basis = json['basis'] == 'gold' ? NisabBasis.gold : NisabBasis.silver;
      _priceDate =
          DateTime.tryParse(json['priceDate'] as String? ?? '') ??
          DateTime.now();
      final assets = json['assets'] as Map? ?? const {};
      for (final entry in _assets.entries) {
        entry.value.text = assets[entry.key]?.toString() ?? '';
      }
    } catch (_) {
      // Ignore an old or malformed local draft.
    }
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
    _save();
  }

  Future<void> _save() {
    return _store.saveNote(
      _storageKey,
      jsonEncode({
        'currency': _currency.text,
        'goldPrice': _goldPrice.text,
        'silverPrice': _silverPrice.text,
        'liabilities': _liabilities.text,
        'basis': _basis.name,
        'priceDate': _priceDate.toIso8601String(),
        'assets': {
          for (final entry in _assets.entries) entry.key: entry.value.text,
        },
      }),
    );
  }

  ZakatResult get _result {
    return ZakatCalculator.calculate(
      ZakatInput(
        assets: {
          for (final entry in _assets.entries)
            entry.key: _number(entry.value.text),
        },
        liabilities: _number(_liabilities.text),
        basis: _basis,
        goldPricePerGram: _number(_goldPrice.text),
        silverPricePerGram: _number(_silverPrice.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final pricesReady =
        _number(_goldPrice.text) > 0 && _number(_silverPrice.text) > 0;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).zakatTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          PremiumSurface(
            padding: const EdgeInsets.all(20),
            prominent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ZAKAT DUE • 2.5%',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  pricesReady ? _money(result.zakatDue) : 'Enter metal prices',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pricesReady
                      ? result.meetsNisab
                            ? 'Net wealth is at or above the selected Nisab.'
                            : 'Net wealth is below the selected Nisab.'
                      : 'Both current per-gram prices make the assumptions visible.',
                ),
                const Divider(height: 24),
                _ResultRow(
                  label: 'Total assets',
                  value: _money(result.totalAssets),
                ),
                _ResultRow(
                  label: 'Net wealth',
                  value: _money(result.netWealth),
                ),
                _ResultRow(
                  label: 'Nisab (${_basis.name})',
                  value: pricesReady ? _money(result.nisab) : 'Not set',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Educational estimate, not a fatwa. This covers monetary assets '
            'at 2.5% after a lunar year when net wealth reaches the selected '
            'Nisab. Agriculture, livestock, khums, pensions, jewelry opinions, '
            'and unusual cases are outside this calculator. Consult a qualified scholar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.68),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Nisab assumptions',
            children: [
              TextField(
                controller: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency code or symbol',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _goldPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Gold price per gram',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _silverPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Silver price per gram',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Price date'),
                subtitle: Text(DateFormat.yMMMd().format(_priceDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _priceDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setState(() => _priceDate = selected);
                    await _save();
                  }
                },
              ),
              SegmentedButton<NisabBasis>(
                segments: const [
                  ButtonSegment(
                    value: NisabBasis.silver,
                    label: Text('Silver 612.36g'),
                  ),
                  ButtonSegment(
                    value: NisabBasis.gold,
                    label: Text('Gold 87.48g'),
                  ),
                ],
                selected: {_basis},
                onSelectionChanged: (value) {
                  setState(() => _basis = value.first);
                  _save();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Zakatable assets',
            children: [
              for (final category in zakatAssetCategories) ...[
                TextField(
                  controller: _assets[category.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: category.label,
                    helperText: category.hint,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Deductions',
            children: [
              TextField(
                controller: _liabilities,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Immediate liabilities',
                  helperText: 'Debts and bills due now',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset amounts'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    for (final controller in [
      _goldPrice,
      _silverPrice,
      _liabilities,
      ..._assets.values,
    ]) {
      controller.clear();
    }
    setState(() {
      _basis = NisabBasis.silver;
      _priceDate = DateTime.now();
    });
    _save();
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  String _money(double amount) {
    final currency = _currency.text.trim().isEmpty
        ? ''
        : '${_currency.text.trim()} ';
    return '$currency${NumberFormat('#,##0.00').format(amount)}';
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
