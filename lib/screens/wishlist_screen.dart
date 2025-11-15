import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Future<void> _removeNonExistentProduct(
      CollectionReference wishlistRef, String productId) async {
    await Future.delayed(Duration.zero);
    await wishlistRef.doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your wishlist.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Get reference to user’s wishlist in Firebase
    // This points to where the current user’s wishlist items are stored in Firebase.
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wishlist ❤️', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: wishlistRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle empty wishlist
          // show emoty message if empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Your wishlist is empty.',
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            );
          }

          final wishlistItems = snapshot.data!.docs;

          // Loop through each wishlist item
          // For each saved product, show a card with product image, name, price, and delete button.
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final productId = wishlistItems[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) return const SizedBox.shrink();

                  if (!productSnapshot.data!.exists) {
                    _removeNonExistentProduct(wishlistRef, productId);
                    return const SizedBox.shrink();
                  }

                  final productData =
                  productSnapshot.data!.data() as Map<String, dynamic>;

                  // card with product image, name, price, and delete button.
                  return Card(
                    margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // product image
                        child: Image.network(
                          productData['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image,
                                  size: 40,
                                  color:
                                  theme.colorScheme.onSurface.withOpacity(0.3)),
                        ),
                      ),
                      // name
                      title: Text(
                        productData['name'],
                        style: theme.textTheme.bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '₱${productData['price'].toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error),
                        onPressed: () async {
                          await wishlistRef.doc(productId).delete();
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productData: productData,
                              productId: productId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
