import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_panel_screen.dart';
import '../widgets/product_card.dart';
import '../screens/product_detail_screen.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/screens/order_history_screen.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/widgets/notification_icon.dart';
import 'package:ecommerce_app/screens/chat_screen.dart';
import 'package:ecommerce_app/screens/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedCategory = 'All';  // Default to all for catorgory filter

  // settings for price range
  final double _minPrice = 0.0;
  final double _maxPrice = 50000.0;
  // price range
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _priceRange = RangeValues(_minPrice, _maxPrice);
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'];
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Used by Category featur for filetring products by category.
  Widget _buildCategoryChip(String category) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shows all products and lets user filter them by price or category.
    // Each product has a heart icon to add it to wishlist.
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Image.asset(
          'assets/images/app_logo.png',
          height: 50,
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  tooltip: 'Cart',
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const NotificationIcon(), // Assuming this already has its own tooltip if needed
          IconButton( // WishList button


            // Summary: “This button opens the wishlist screen when tapped.
            // It uses a heart icon, waits for the screen to close, and
            // refreshes the home screen in case any products were added or
            // removed from the wishlist.”
            tooltip: 'Wishlist',  // Shows a small message when you hover over the button (on web or desktop)
            icon: const Icon(Icons.favorite_border), // heart outline icon
            onPressed: () async { // Defines what happens when the button is tapped.
              await Navigator.of(context).push( // new screen on top of the current one.
                MaterialPageRoute(
                  builder: (context) => const WishlistScreen(),
                ), // Specifies which screen to open. In this case, it opens the WishlistScreen, showing all saved products.
              );
              setState(() {}); // Tells Flutter “something might have changed, redraw the screen”.
            },
          ),
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          if (_userRole == 'admin')
            IconButton(
              tooltip: 'Admin Panel',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${_currentUser?.email ?? 'User'} 👋',
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground, // more consistent with standard text
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find the perfect lighting for your home',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.8), // softer secondary text
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- CATEGORY CHIPS ---
            // Category Filter:
            // Lets user select a product type (like Table Lamp or Chair).
            // Only shows products from the chosen category.

            // category chips are just like buttins
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  // building category button for ALL products
                  // saves ALL _selectedCategory varaible, will be used by query later on
                  _buildCategoryChip('All'),
                  const SizedBox(width: 8),

                  // building category button for Table Lamps products
                  // saves Table Lamps _selectedCategory varaible, will be used by query later on
                  _buildCategoryChip('Table Lamps'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Floor Lamps'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Hanging Lights'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Wall Lamps'),
                ],
              ),
            ),

            // --- PRICE FILTER ---
            // Price Range Slider:
            // Lets user pick min and max price.
            // Updates product list immediately when slider moves.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shows the current selected price range.
                  Text(
                    'Price: ₱${_priceRange.start.round()} - ₱${_priceRange.end.round()}',
                    style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Price slider
                  // Lets the user select a minimum and maximum price at the same time.
                  RangeSlider(
                    // Current positions of the slider handles.
                    values: _priceRange,

                    // Defines the lowest and highest price the slider can go.
                    min: _minPrice,
                    max: _maxPrice,

                    // Breaks the slider into 100 steps, making it easier to select exact values.
                    divisions: 100,
                    // Shows the current min and max values above the slider handles.
                    labels: RangeLabels(
                      '₱${_priceRange.start.round()}',
                      '₱${_priceRange.end.round()}',
                    ),
                    activeColor: theme.colorScheme.primary,

                    // auto update price range when slider moves
                    onChanged: (newValues) {
                      setState(() { // updates _priceRange
                        // refreshes the grid to show only products within the selected price range.
                        _priceRange = RangeValues(
                          newValues.start.roundToDouble(),
                          newValues.end.roundToDouble(),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

          // --- PRODUCTS GRID ---
          Expanded(
          child: StreamBuilder<QuerySnapshot>(

            // Query for products supporting Category filter
            stream: _firestore
                .collection('products')
                // category filter applies here
                .where('category', isEqualTo: _selectedCategory == 'All' ? null : _selectedCategory)

                // price filter applies here
                .where('price', isGreaterThanOrEqualTo: _priceRange.start)
                .where('price', isLessThanOrEqualTo: _priceRange.end)

                .orderBy('price')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: theme.textTheme.bodyMedium));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                      'No products found.', style: theme.textTheme.bodyMedium),
                );
              }

              final products = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productDoc = products[index];
                  final productData = productDoc.data() as Map<String, dynamic>;

                  return ProductCard(
                    productId: productDoc.id,
                    productName: productData['name'],
                    price: productData['price'],
                    imageUrl: productData['imageUrl'],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(
                                productData: productData,
                                productId: productDoc.id,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          ),
          ],
        ),
      ),

      // Floating Chat Button
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            unreadCount = data?['unreadByUserCount'] ?? 0;
          }

          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: FloatingActionButton.extended(
              tooltip: 'Contact Admin',
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : null,
    );
  }
}
