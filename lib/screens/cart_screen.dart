import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Text(
          'Your cart is empty.',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 120), // leave space for bottom button
        itemCount: cart.items.length + 1, // +1 for price breakdown card
        itemBuilder: (context, index) {
          if (index < cart.items.length) {
            final cartItem = cart.items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(cartItem.name[0], style: theme.textTheme.titleMedium),
                ),
                title: Text(cartItem.name, style: theme.textTheme.titleMedium),
                subtitle: Text('Qty: ${cartItem.quantity}', style: theme.textTheme.bodyMedium),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: theme.colorScheme.error),
                      onPressed: () => cart.removeItem(cartItem.id),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Price breakdown card at the end of list
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceRow('Subtotal:', cart.subtotal, theme),
                    const SizedBox(height: 8),
                    _buildPriceRow('VAT (12%):', cart.vat, theme),
                    const Divider(height: 20, thickness: 1),
                    _buildPriceRow('Total:', cart.totalPriceWithVat, theme, isTotal: true),
                  ],
                ),
              ),
            );
          }
        },
      ),

      // --- Sticky Proceed to Payment Button ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: cart.items.isEmpty
                ? null
                : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    totalAmount: cart.totalPriceWithVat,
                  ),
                ),
              );
            },
            child: Text(
              'Proceed to Payment',
              style: theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, ThemeData theme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: isTotal
              ? theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
