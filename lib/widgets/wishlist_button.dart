import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistButton extends StatefulWidget {
  final String productId;

  const WishlistButton({super.key, required this.productId});

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  bool _isWishlisted = false; // Keeps track of whether the product is in your wishlist.
  final _user = FirebaseAuth.instance.currentUser; // Who is the current logged-in user.
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkWishlist(); // When the button appears, it checks if the product is already saved.
  }

  Future<void> _checkWishlist() async {
    if (_user == null) return;

    final doc = await _firestore
        .collection('users') // Look in the “users” folder in the database.
        .doc(_user!.uid) // Pick the document for the current user by uid
        .collection('wishlist') // Inside the user’s folder, go to the “wishlist” folder.
        .doc(widget.productId) // Look for the specific product in the wishlist.
        .get(); // Returns a document if it exists, or nothing if it doesn’t.

    if (mounted) {
      setState(() {
        _isWishlisted = doc.exists; // true or false if the product exists
      });
    }
  }

  Future<void> _toggleWishlist() async {
    // When the heart is tapped:
    // Adds the product if it’s not saved.
    // Removes the product if it’s already saved.

    if (_user == null) return;

    final ref = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('wishlist')
        .doc(widget.productId);

    if (_isWishlisted) { // already saved in wishlist
      await ref.delete(); // Removes the product
      setState(() {
        _isWishlisted = false;
      });
    } else { // not saved.
      await ref.set({'addedAt': Timestamp.now()}); // Adds the product
      setState(() {
        _isWishlisted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // Tapping this button updates the wishlist in Firebase
      // and the icon immediately.
      icon: Icon(
        _isWishlisted
            ? Icons.favorite // icon used if saved
            : Icons.favorite_border, // icon used if not saved
        color: _isWishlisted
            ? Colors.redAccent  // red if saved, grey if not saved.
            : Colors.grey[600], // grey if not saved.
        size: 26,
      ),
      onPressed: _toggleWishlist,
    );
  }
}