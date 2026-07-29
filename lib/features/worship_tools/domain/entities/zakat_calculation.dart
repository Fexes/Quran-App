import 'package:equatable/equatable.dart';

enum NisabBasis { silver, gold }

class ZakatAssetCategory extends Equatable {
  const ZakatAssetCategory({
    required this.id,
    required this.label,
    required this.hint,
  });

  final String id;
  final String label;
  final String hint;

  @override
  List<Object> get props => [id, label, hint];
}

const zakatAssetCategories = [
  ZakatAssetCategory(
    id: 'cash',
    label: 'Cash & bank balances',
    hint: 'Money in hand and current or savings accounts',
  ),
  ZakatAssetCategory(
    id: 'gold',
    label: 'Gold',
    hint: 'Current market value of gold included in your calculation',
  ),
  ZakatAssetCategory(
    id: 'silver',
    label: 'Silver',
    hint: 'Current market value of silver included in your calculation',
  ),
  ZakatAssetCategory(
    id: 'investments',
    label: 'Investments',
    hint: 'Shares, funds, and other liquid investments',
  ),
  ZakatAssetCategory(
    id: 'business',
    label: 'Business assets',
    hint: 'Stock in trade and raw materials at current value',
  ),
  ZakatAssetCategory(
    id: 'receivables',
    label: 'Money owed to you',
    hint: 'Amounts you reasonably expect to receive',
  ),
];

class ZakatInput extends Equatable {
  const ZakatInput({
    required this.assets,
    required this.liabilities,
    required this.basis,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
  });

  final Map<String, double> assets;
  final double liabilities;
  final NisabBasis basis;
  final double goldPricePerGram;
  final double silverPricePerGram;

  @override
  List<Object> get props => [
    assets,
    liabilities,
    basis,
    goldPricePerGram,
    silverPricePerGram,
  ];
}

class ZakatResult extends Equatable {
  const ZakatResult({
    required this.totalAssets,
    required this.netWealth,
    required this.nisab,
    required this.meetsNisab,
    required this.zakatDue,
  });

  final double totalAssets;
  final double netWealth;
  final double nisab;
  final bool meetsNisab;
  final double zakatDue;

  @override
  List<Object> get props => [
    totalAssets,
    netWealth,
    nisab,
    meetsNisab,
    zakatDue,
  ];
}

class ZakatCalculator {
  const ZakatCalculator._();

  static const rate = 0.025;
  static const goldNisabGrams = 87.48;
  static const silverNisabGrams = 612.36;

  static ZakatResult calculate(ZakatInput input) {
    final totalAssets = input.assets.values.fold<double>(
      0,
      (total, amount) => total + (amount.isFinite && amount > 0 ? amount : 0),
    );
    final liabilities = input.liabilities.isFinite && input.liabilities > 0
        ? input.liabilities
        : 0;
    final netWealth = totalAssets - liabilities;
    final nisab = input.basis == NisabBasis.gold
        ? goldNisabGrams * input.goldPricePerGram
        : silverNisabGrams * input.silverPricePerGram;
    final meetsNisab = nisab > 0 && netWealth >= nisab;
    return ZakatResult(
      totalAssets: totalAssets,
      netWealth: netWealth,
      nisab: nisab,
      meetsNisab: meetsNisab,
      zakatDue: meetsNisab ? netWealth * rate : 0,
    );
  }
}
