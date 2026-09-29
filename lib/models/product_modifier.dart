import 'product.dart';

class ModifierOption {
  final String id;
  final String name;
  final double extraPrice;

  const ModifierOption({
    required this.id,
    required this.name,
    this.extraPrice = 0.0,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraPrice': extraPrice,
    };
  }
}

class ModifierGroup {
  final String id;
  final String name; // e.g. "Ukuran / Size", "Level Gula", "Level Es", "Tambahan Topping"
  final bool isRequired;
  final bool allowMultiple;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.allowMultiple = false,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isRequired': isRequired,
      'allowMultiple': allowMultiple,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class SelectedModifier {
  final String groupId;
  final String groupName;
  final String optionId;
  final String optionName;
  final double extraPrice;

  const SelectedModifier({
    required this.groupId,
    required this.groupName,
    required this.optionId,
    required this.optionName,
    this.extraPrice = 0.0,
  });

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      optionId: json['optionId'] as String? ?? '',
      optionName: json['optionName'] as String? ?? '',
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'optionId': optionId,
      'optionName': optionName,
      'extraPrice': extraPrice,
    };
  }
}

class CustomerCartItem {
  final String id;
  final Product product;
  final int quantity;
  final List<SelectedModifier> selectedModifiers;
  final String note;

  const CustomerCartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.note = '',
  });

  double get unitPrice {
    final modifiersTotal = selectedModifiers.fold(0.0, (s, m) => s + m.extraPrice);
    return product.price + modifiersTotal;
  }

  double get subtotal => unitPrice * quantity;

  CustomerCartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<SelectedModifier>? selectedModifiers,
    String? note,
  }) {
    return CustomerCartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      note: note ?? this.note,
    );
  }
}
