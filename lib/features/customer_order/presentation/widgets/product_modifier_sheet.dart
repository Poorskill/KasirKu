import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_product_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/product.dart';
import '../../../../models/product_modifier.dart';
import '../customer_order_provider.dart';

class ProductModifierSheet extends ConsumerStatefulWidget {
  final Product product;

  const ProductModifierSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, {required Product product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ProductModifierSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductModifierSheet> createState() =>
      _ProductModifierSheetState();
}

class _ProductModifierSheetState extends ConsumerState<ProductModifierSheet> {
  int _quantity = 1;
  final _noteController = TextEditingController();
  final Map<String, SelectedModifier> _selectedSingle = {};
  final Set<SelectedModifier> _selectedMultiple = {};

  late List<ModifierGroup> _modifierGroups;

  @override
  void initState() {
    super.initState();
    _initModifiers();
  }

  void _initModifiers() {
    final cat = widget.product.categoryId.toLowerCase();
    if (cat.contains('minuman')) {
      _modifierGroups = [
        const ModifierGroup(
          id: 'grp-size',
          name: 'Ukuran Porsi',
          isRequired: true,
          allowMultiple: false,
          options: [
            ModifierOption(id: 'sz-reg', name: 'Regular', extraPrice: 0),
            ModifierOption(id: 'sz-lrg', name: 'Large (Besar)', extraPrice: 5000),
          ],
        ),
        const ModifierGroup(
          id: 'grp-sugar',
          name: 'Level Gula',
          isRequired: false,
          allowMultiple: false,
          options: [
            ModifierOption(id: 'sgr-norm', name: 'Normal', extraPrice: 0),
            ModifierOption(id: 'sgr-less', name: 'Less Sugar', extraPrice: 0),
            ModifierOption(id: 'sgr-none', name: 'No Sugar', extraPrice: 0),
          ],
        ),
        const ModifierGroup(
          id: 'grp-ice',
          name: 'Level Es',
          isRequired: false,
          allowMultiple: false,
          options: [
            ModifierOption(id: 'ice-norm', name: 'Normal Ice', extraPrice: 0),
            ModifierOption(id: 'ice-less', name: 'Less Ice', extraPrice: 0),
            ModifierOption(id: 'ice-none', name: 'No Ice (Hangat)', extraPrice: 0),
          ],
        ),
      ];
      // Default selections
      _selectedSingle['grp-size'] = const SelectedModifier(
        groupId: 'grp-size',
        groupName: 'Ukuran Porsi',
        optionId: 'sz-reg',
        optionName: 'Regular',
        extraPrice: 0,
      );
      _selectedSingle['grp-sugar'] = const SelectedModifier(
        groupId: 'grp-sugar',
        groupName: 'Level Gula',
        optionId: 'sgr-norm',
        optionName: 'Normal',
        extraPrice: 0,
      );
      _selectedSingle['grp-ice'] = const SelectedModifier(
        groupId: 'grp-ice',
        groupName: 'Level Es',
        optionId: 'ice-norm',
        optionName: 'Normal Ice',
        extraPrice: 0,
      );
    } else {
      // Food / Snack modifiers
      _modifierGroups = [
        const ModifierGroup(
          id: 'grp-spicy',
          name: 'Tingkat Kepedasan',
          isRequired: false,
          allowMultiple: false,
          options: [
            ModifierOption(id: 'spc-mild', name: 'Sedang / Tidak Pedas', extraPrice: 0),
            ModifierOption(id: 'spc-hot', name: 'Pedas', extraPrice: 0),
            ModifierOption(id: 'spc-extra', name: 'Extra Pedas', extraPrice: 0),
          ],
        ),
        const ModifierGroup(
          id: 'grp-topping',
          name: 'Tambahan Topping',
          isRequired: false,
          allowMultiple: true,
          options: [
            ModifierOption(id: 'top-egg', name: 'Telur Ceplok / Dadar', extraPrice: 4000),
            ModifierOption(id: 'top-cheese', name: 'Keju Parut Melimpah', extraPrice: 4000),
            ModifierOption(id: 'top-krupuk', name: 'Kerupuk Gurih', extraPrice: 2000),
          ],
        ),
      ];
      _selectedSingle['grp-spicy'] = const SelectedModifier(
        groupId: 'grp-spicy',
        groupName: 'Tingkat Kepedasan',
        optionId: 'spc-mild',
        optionName: 'Sedang / Tidak Pedas',
        extraPrice: 0,
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _itemUnitPrice {
    double total = widget.product.price;
    for (final sm in _selectedSingle.values) {
      total += sm.extraPrice;
    }
    for (final sm in _selectedMultiple) {
      total += sm.extraPrice;
    }
    return total;
  }

  double get _grandTotal => _itemUnitPrice * _quantity;

  void _addToCart() {
    final allModifiers = [
      ..._selectedSingle.values,
      ..._selectedMultiple,
    ];

    final cartItem = CustomerCartItem(
      id: const Uuid().v4().substring(0, 8),
      product: widget.product,
      quantity: _quantity,
      selectedModifiers: allModifiers,
      note: _noteController.text.trim(),
    );

    ref.read(customerCartNotifierProvider.notifier).addItem(cartItem);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ditambahkan ke pesanan'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle Bar
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Product Preview Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppProductImage(
                        imageUrl: widget.product.imageUrl,
                        width: 80,
                        height: 80,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(widget.product.price),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            if (widget.product.description != null &&
                                widget.product.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.product.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Modifier Groups
                  ..._modifierGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (group.isRequired) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Wajib',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Options
                          ...group.options.map((opt) {
                            if (group.allowMultiple) {
                              final isSelected = _selectedMultiple.any(
                                  (m) => m.optionId == opt.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(opt.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                secondary: opt.extraPrice > 0
                                    ? Text(
                                        '+${CurrencyFormatter.format(opt.extraPrice)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary),
                                      )
                                    : null,
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedMultiple.add(
                                        SelectedModifier(
                                          groupId: group.id,
                                          groupName: group.name,
                                          optionId: opt.id,
                                          optionName: opt.name,
                                          extraPrice: opt.extraPrice,
                                        ),
                                      );
                                    } else {
                                      _selectedMultiple.removeWhere(
                                          (m) => m.optionId == opt.id);
                                    }
                                  });
                                },
                              );
                            } else {
                              final isSelected =
                                  _selectedSingle[group.id]?.optionId == opt.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedSingle[group.id] = SelectedModifier(
                                      groupId: group.id,
                                      groupName: group.name,
                                      optionId: opt.id,
                                      optionName: opt.name,
                                      extraPrice: opt.extraPrice,
                                    );
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 20,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (opt.extraPrice > 0)
                                        Text(
                                          '+${CurrencyFormatter.format(opt.extraPrice)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    );
                  }),

                  // Special Notes Input
                  AppTextField(
                    label: 'Catatan Khusus (Opsional)',
                    hint: 'Contoh: Jangan terlalu pedas, bungkus pisah, dll.',
                    controller: _noteController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Sticky Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Quantity Control
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBtnBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Add Button with total price
                    Expanded(
                      child: AppButton(
                        text: 'Pesan • ${CurrencyFormatter.format(_grandTotal)}',
                        icon: Icons.add_shopping_cart_rounded,
                        height: 48,
                        onPressed: _addToCart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
