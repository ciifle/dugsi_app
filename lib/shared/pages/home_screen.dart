import 'dart:async';

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color brandRed = Color(0xFFF21B1B);
  static const Color ink = Color(0xFF151820);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFEFEFF2);

  static const List<String> sliderImages = [
    'assets/images/slider_1.png',
    'assets/images/slider_2.png',
    'assets/images/slider_3.png',
    'assets/images/slider_4.png',
    'assets/images/slider_5.png',
  ];

  static const List<RestaurantPreview> restaurants = [
    RestaurantPreview(
      name: 'Burger House',
      image: 'assets/images/food_1.png',
      deliveryTime: '30-40 min',
      priceLevel: r'$$',
      rating: '4.7',
    ),
    RestaurantPreview(
      name: 'Pizza Palace',
      image: 'assets/images/food_2.png',
      deliveryTime: '25-35 min',
      priceLevel: r'$$',
      rating: '4.6',
    ),
    RestaurantPreview(
      name: 'Tasty Bites',
      image: 'assets/images/food_3.png',
      deliveryTime: '20-30 min',
      priceLevel: r'$$',
      rating: '4.8',
    ),
    RestaurantPreview(
      name: 'Grill Spot',
      image: 'assets/images/food_7.png',
      deliveryTime: '25-40 min',
      priceLevel: r'$$',
      rating: '4.5',
    ),
    RestaurantPreview(
      name: 'Rice Corner',
      image: 'assets/images/food_8.png',
      deliveryTime: '30-45 min',
      priceLevel: r'$',
      rating: '4.6',
    ),
    RestaurantPreview(
      name: 'Fresh Bites',
      image: 'assets/images/food_9.png',
      deliveryTime: '20-35 min',
      priceLevel: r'$$',
      rating: '4.7',
    ),
  ];

  static const List<DishPreview> dishes = [
    DishPreview(
      name: 'Beef Burger',
      description: 'Juicy beef burger\nwith cheese',
      image: 'assets/images/food_4.png',
      price: r'$4.99',
    ),
    DishPreview(
      name: 'Pepperoni Pizza',
      description: 'Classic pepperoni\nwith cheese',
      image: 'assets/images/food_5.png',
      price: r'$7.99',
    ),
    DishPreview(
      name: 'Fried Chicken',
      description: 'Crispy & spicy\nfried chicken',
      image: 'assets/images/food_6.png',
      price: r'$5.49',
    ),
    DishPreview(
      name: 'Chef Special',
      description: 'Fresh house meal\nready fast',
      image: 'assets/images/food_7.png',
      price: r'$6.49',
    ),
    DishPreview(
      name: 'Family Plate',
      description: 'Shareable meal\nwith sides',
      image: 'assets/images/food_8.png',
      price: r'$9.99',
    ),
    DishPreview(
      name: 'Snack Box',
      description: 'Quick bites\nfor anytime',
      image: 'assets/images/food_9.png',
      price: r'$3.99',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
                  sliver: SliverList.list(
                    children: const [
                      HomeHeader(),
                      SizedBox(height: 18),
                      DeliveryLocationRow(),
                      SizedBox(height: 24),
                      HomeSearchBar(),
                      SizedBox(height: 22),
                      PromoSlider(images: sliderImages),
                      SizedBox(height: 24),
                      CategorySelector(),
                      SizedBox(height: 30),
                      HomeSectionHeader(title: 'Popular Restaurants'),
                      SizedBox(height: 14),
                      PopularRestaurantsSection(items: restaurants),
                      SizedBox(height: 30),
                      HomeSectionHeader(title: 'Popular Dishes'),
                      SizedBox(height: 14),
                      PopularDishesSection(items: dishes),
                      SizedBox(height: 30),
                      FirstOrderPromoCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const FloatingHomeNavigation(),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          height: 76,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => const Text(
                'Raac',
                style: TextStyle(
                  color: HomeScreen.brandRed,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const NotificationButton(),
      ],
    );
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
              size: 34,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 23,
              height: 23,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: HomeScreen.brandRed,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryLocationRow extends StatelessWidget {
  const DeliveryLocationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.location_on_rounded, color: HomeScreen.brandRed, size: 36),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deliver to',
                style: TextStyle(
                  color: HomeScreen.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hamar Weyne, Mogadishu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: HomeScreen.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: HomeScreen.ink,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: HomeScreen.line),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: HomeScreen.ink, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Search for food or restaurants...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: HomeScreen.brandRed,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: HomeScreen.brandRed.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 31),
        ),
      ],
    );
  }
}

class PromoSlider extends StatefulWidget {
  const PromoSlider({super.key, required this.images});

  final List<String> images;

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || widget.images.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.images.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _currentPage = page);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.15,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, index) {
                  return Image.asset(
                    widget.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImageFallback(
                      icon: Icons.lunch_dining_rounded,
                      label: 'RAAC',
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: PromoPageIndicator(
                  count: widget.images.length,
                  activeIndex: _currentPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromoPageIndicator extends StatelessWidget {
  const PromoPageIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: isActive ? 28 : 6,
          height: isActive ? 5 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.48),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  static const List<CategoryItem> items = [
    CategoryItem(Icons.grid_view_rounded, 'All', true),
    CategoryItem(Icons.lunch_dining_outlined, 'Burgers', false),
    CategoryItem(Icons.local_pizza_outlined, 'Pizza', false),
    CategoryItem(Icons.set_meal_outlined, 'Chicken', false),
    CategoryItem(Icons.local_drink_outlined, 'Drinks', false),
    CategoryItem(Icons.cake_outlined, 'Desserts', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => CategoryCard(item: items[index]),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.item});

  final CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      decoration: BoxDecoration(
        color: item.selected ? const Color(0xFFFFF8F8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.selected
              ? HomeScreen.brandRed.withValues(alpha: 0.18)
              : HomeScreen.line,
        ),
        boxShadow: [
          BoxShadow(
            color: item.selected
                ? HomeScreen.brandRed.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: item.selected ? 20 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            color: item.selected ? HomeScreen.brandRed : HomeScreen.ink,
            size: 32,
          ),
          const SizedBox(height: 9),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.selected ? HomeScreen.brandRed : HomeScreen.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: HomeScreen.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const Text(
          'See all',
          style: TextStyle(
            color: HomeScreen.brandRed,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: HomeScreen.brandRed,
          size: 15,
        ),
      ],
    );
  }
}

class PopularRestaurantsSection extends StatelessWidget {
  const PopularRestaurantsSection({super.key, required this.items});

  final List<RestaurantPreview> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final visibleCardWidth = ((width - 28) / 3).clamp(112.0, 180.0);

        return SizedBox(
          height: visibleCardWidth + 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return RestaurantCard(
                item: items[index],
                width: visibleCardWidth,
              );
            },
          ),
        );
      },
    );
  }
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.item, required this.width});

  final RestaurantPreview item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final imageHeight = (width * 0.72).clamp(84.0, 120.0);

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeScreen.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FoodAssetImage(path: item.image),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: HomeScreen.ink,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: HomeScreen.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.deliveryTime}  -  ${item.priceLevel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeScreen.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: HomeScreen.brandRed,
                  size: 19,
                ),
                const SizedBox(width: 3),
                Text(
                  item.rating,
                  style: const TextStyle(
                    color: HomeScreen.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PopularDishesSection extends StatelessWidget {
  const PopularDishesSection({super.key, required this.items});

  final List<DishPreview> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final visibleCardWidth = ((width - 28) / 3).clamp(116.0, 210.0);

        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return DishCard(item: items[index], width: visibleCardWidth);
            },
          ),
        );
      },
    );
  }
}

class DishCard extends StatelessWidget {
  const DishCard({super.key, required this.item, required this.width});

  final DishPreview item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeScreen.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 62,
              height: 78,
              child: FoodAssetImage(path: item.image),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeScreen.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeScreen.muted,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeScreen.brandRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: HomeScreen.brandRed,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: HomeScreen.brandRed.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FirstOrderPromoCard extends StatelessWidget {
  const FirstOrderPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomeScreen.brandRed.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.brandRed.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: HomeScreen.brandRed,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get 20% OFF your first order!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HomeScreen.brandRed,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Text(
                      'Use code:',
                      style: TextStyle(
                        color: HomeScreen.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RAAC20',
                        style: TextStyle(
                          color: HomeScreen.brandRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeScreen.brandRed,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: HomeScreen.brandRed.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              'Order Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingHomeNavigation extends StatelessWidget {
  const FloatingHomeNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            height: 82,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                ),
                BottomNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Orders',
                ),
                BottomNavItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  badge: '3',
                ),
                BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? HomeScreen.brandRed : HomeScreen.ink;

    return SizedBox(
      width: 82,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 29),
                  if (badge != null)
                    Positioned(
                      top: -7,
                      right: -10,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: HomeScreen.brandRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: label.length > 10 ? 10.5 : 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
          if (selected)
            const Positioned(
              bottom: 0,
              child: SizedBox(
                width: 42,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: HomeScreen.brandRed,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FoodAssetImage extends StatelessWidget {
  const FoodAssetImage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const _ImageFallback(icon: Icons.restaurant_rounded, label: ''),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9B0008), HomeScreen.brandRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 44),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  const CategoryItem(this.icon, this.label, this.selected);

  final IconData icon;
  final String label;
  final bool selected;
}

class RestaurantPreview {
  const RestaurantPreview({
    required this.name,
    required this.image,
    required this.deliveryTime,
    required this.priceLevel,
    required this.rating,
  });

  final String name;
  final String image;
  final String deliveryTime;
  final String priceLevel;
  final String rating;
}

class DishPreview {
  const DishPreview({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
  });

  final String name;
  final String description;
  final String image;
  final String price;
}
