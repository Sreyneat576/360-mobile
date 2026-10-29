import '../../core/utils/formatters.dart';

class Bank {
  const Bank({
    required this.id,
    required this.name,
    this.accountName,
    this.accountNumber,
    this.openingBalance,
    this.currentBalance,
    this.status,
  });

  final int id;
  final String name;
  final String? accountName;
  final String? accountNumber;
  final double? openingBalance;
  final double? currentBalance;
  final String? status;

  factory Bank.fromJson(Map<String, dynamic> j) => Bank(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        accountName: j.stringOf('accountName'),
        accountNumber: j.stringOf('accountNumber'),
        openingBalance: j.doubleOf('openingBalance'),
        currentBalance: j.doubleOf('currentBalance'),
        status: j.stringOf('status'),
      );
}

class BankRequest {
  const BankRequest({
    required this.name,
    required this.accountName,
    required this.accountNumber,
    required this.openingBalance,
    this.currentBalance,
    this.status = 'ACT',
  });

  final String name;
  final String accountName;
  final String accountNumber;
  final double openingBalance;
  final double? currentBalance;
  final String status;

  Map<String, dynamic> toJson() => {
        'name': name,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'openingBalance': openingBalance,
        'currentBalance': currentBalance ?? openingBalance,
        'status': status,
      };
}

class Currency {
  const Currency({
    required this.id,
    this.code,
    required this.name,
    this.operation,
    this.rate,
    this.symbol,
    this.status,
  });

  final int id;
  final String? code;
  final String name;
  final String? operation;
  final double? rate;
  final String? symbol;
  final String? status;

  factory Currency.fromJson(Map<String, dynamic> j) => Currency(
        id: j.intOf('id') ?? 0,
        code: j.stringOf('code'),
        name: j.stringOf('name') ?? '',
        operation: j.stringOf('operation'),
        rate: j.doubleOf('rate'),
        symbol: j.stringOf('symbol'),
        status: j.stringOf('status'),
      );
}

class CurrencyRequest {
  const CurrencyRequest({
    required this.code,
    required this.name,
    this.operation,
    required this.rate,
    this.symbol,
    this.status = 'ACT',
  });

  final String code;
  final String name;
  final String? operation;
  final double rate;
  final String? symbol;
  final String status;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'operation': operation,
        'rate': rate,
        'symbol': symbol,
        'status': status,
      };
}
