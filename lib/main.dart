import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() => runApp(const AdanaApp());

const burgundy = Color(0xFF4A1018);
const wine = Color(0xFF721E2A);
const gold = Color(0xFFE8B85A);
const cream = Color(0xFFFFF5E8);


// ВАЖНО: замени IP на IPv4-адрес компьютера, где запущен FastAPI.
const String apiBaseUrl = 'http://192.168.1.3:8000';

String formatPrice(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

class FoodItem {
  final String id, name, description, category, emoji;
  final int categoryId, mass;
  final double price;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.price,
    required this.mass,
    required this.emoji,
  });
}


class AdanaApp extends StatelessWidget {
  const AdanaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Адана донер — Вкус Турции',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: Colors.white, colorScheme: ColorScheme.fromSeed(seedColor: wine, primary: wine, secondary: gold), fontFamily: 'Roboto'),
    home: const MenuPage(),
  );
}

class MenuPage extends StatefulWidget { const MenuPage({super.key}); @override State<MenuPage> createState() => _MenuPageState(); }
class _MenuPageState extends State<MenuPage> {
  final Map<String, int> cart = {};
  String category = 'Все';
  bool searchOpen = false;
  String searchQuery = '';
  bool isLoading = true;
  String? loadError;
  List<FoodItem> foods = [];
  List<String> categories = ['Все'];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/dishes/')).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$apiBaseUrl/categories/')).timeout(const Duration(seconds: 15)),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        throw Exception(
          'Ошибка API: блюда — ${responses[0].statusCode}, категории — ${responses[1].statusCode}',
        );
      }

      final dishesJson = jsonDecode(utf8.decode(responses[0].bodyBytes)) as List<dynamic>;
      final categoriesJson = jsonDecode(utf8.decode(responses[1].bodyBytes)) as List<dynamic>;

      final categoryNames = <int, String>{};
      for (final raw in categoriesJson) {
        final item = raw as Map<String, dynamic>;
        categoryNames[(item['id'] as num).toInt()] = item['name']?.toString() ?? 'Другое';
      }

      final loadedFoods = dishesJson.map((raw) {
        final item = raw as Map<String, dynamic>;
        final categoryId = (item['category_id'] as num).toInt();
        final categoryName = categoryNames[categoryId] ?? 'Другое';
        final name = item['name']?.toString() ?? 'Без названия';
        final description = item['description']?.toString() ?? '';
        final price = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
        final mass = (item['mass'] as num?)?.toInt() ?? 0;

        String emoji = '🍽️';
        final text = '$name $categoryName'.toLowerCase();
        if (text.contains('drink') || text.contains('напит')) {
          emoji = '🥤';
        } else if (text.contains('chicken') || text.contains('кур')) {
          emoji = '🍗';
        } else if (text.contains('kebab') || text.contains('кебаб') || text.contains('донер')) {
          emoji = '🥙';
        }

        return FoodItem(
          id: item['id'].toString(),
          name: name,
          description: description,
          category: categoryName,
          categoryId: categoryId,
          price: price,
          mass: mass,
          emoji: emoji,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        foods = loadedFoods;
        categories = ['Все', ...categoryNames.values.toSet()];
        isLoading = false;
        loadError = null;
        if (!categories.contains(category)) category = 'Все';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  int get totalCount => cart.values.fold(0, (a, b) => a + b);
  double get total => foods.fold(0.0, (sum, f) => sum + f.price * (cart[f.id] ?? 0));
  void add(FoodItem item) => setState(() => cart[item.id] = (cart[item.id] ?? 0) + 1);
  void change(FoodItem item, int delta) => setState(() { final n = (cart[item.id] ?? 0) + delta; if (n <= 0) { cart.remove(item.id); } else { cart[item.id] = n; } });

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final visible = foods.where((f) {
      final matchesCategory = category == 'Все' || f.category == category;
      final matchesSearch = q.isEmpty || f.name.toLowerCase().contains(q) || f.description.toLowerCase().contains(q) || f.category.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
    return Scaffold(
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(
            height: 116,
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: _header(),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 8),
          child: Row(children: [
            const Expanded(child: Text('Наше меню', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: burgundy))),
            IconButton(
              tooltip: 'Поиск блюд',
              onPressed: () => setState(() { searchOpen = !searchOpen; if (!searchOpen) { searchQuery = ''; searchController.clear(); } }),
              icon: Icon(searchOpen ? Icons.close : Icons.search, color: burgundy, size: 28),
            ),
          ]),
        )),
        if (searchOpen) SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: searchController,
            onChanged: (value) => setState(() => searchQuery = value),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Найти блюдо...',
              prefixIcon: const Icon(Icons.search, color: wine),
              suffixIcon: searchQuery.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() => searchQuery = ''); }),
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        )),
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(
            height: 58,
            child: SizedBox(height: 58, child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final c = categories[i]; final selected = c == category; return ChoiceChip(label: Text(c), selected: selected, onSelected: (_) => setState(() => category = c), selectedColor: wine, backgroundColor: Colors.white, labelStyle: TextStyle(color: selected ? Colors.white : burgundy, fontWeight: FontWeight.w700), side: BorderSide(color: selected ? wine : const Color(0xFFE9D9CC))); }),
            )),
          ),
        ),
        if (isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: wine)),
            ),
          )
        else if (loadError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 42, color: wine),
                  const SizedBox(height: 10),
                  const Text('Не удалось загрузить меню', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        loadError = null;
                      });
                      _loadMenu();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          )
        else if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('В этой категории пока нет блюд')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _foodCard(visible[i]),
                childCount: visible.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .72,
              ),
            ),
          ),
      ])),
      bottomNavigationBar: totalCount == 0 ? null : SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: wine, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _openCart, icon: const Icon(Icons.shopping_bag_outlined), label: Text('Корзина · $totalCount шт. · ${formatPrice(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))),
    );
  }

Widget _header() => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [burgundy, Color(0xFF8C2935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: burgundy.withOpacity(.2),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: double.infinity,
          child: Text(
          'АДАНА ДОНЕР',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        )),
        const SizedBox(height: 5),
        const SizedBox(
          width: double.infinity,
          child: Text(
          'ВКУС ТУРЦИИ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 11,
          ),
        )),
      ],
    ),
  );

  Widget _foodCard(FoodItem f) {
    final count = cart[f.id] ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openFoodDetails(f),
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E3D8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFFF0DB), Color(0xFFF9E1C4)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(child: Text(f.emoji, style: const TextStyle(fontSize: 57))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: burgundy, height: 1.1)),
                const SizedBox(height: 4),
                Text(f.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.brown.shade400, height: 1.2)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(child: Text(formatPrice(f.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: wine))),
                    if (count == 0)
                      InkWell(
                        onTap: () => add(f),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: wine, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                      )
                    else
                      Row(
                        children: [
                          _tinyButton(Icons.remove, () => change(f, -1)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold))),
                          _tinyButton(Icons.add, () => add(f)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
  void _openFoodDetails(FoodItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(.38),
        pageBuilder: (_, __, ___) => FoodDetailPage(
          item: item,
          onAddToCart: (quantity) {
            setState(() {
              cart[item.id] = (cart[item.id] ?? 0) + quantity;
            });
          },
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  Widget _tinyButton(IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9), child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFF5E8DD), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: wine)));

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, refresh) => Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
          decoration: const BoxDecoration(color: cream, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.brown.shade200, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 15),
                const Text('Ваша корзина', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: burgundy)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: foods.where((f) => (cart[f.id] ?? 0) > 0).map((f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${formatPrice(f.price)} × ${cart[f.id]}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tinyButton(Icons.remove, () { change(f, -1); refresh(() {}); }),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${cart[f.id]}')),
                          _tinyButton(Icons.add, () { add(f); refresh(() {}); }),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(formatPrice(total), style: const TextStyle(fontSize: 22, color: wine, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: wine, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: totalCount == 0 ? null : () { Navigator.pop(sheetContext); _checkout(); },
                    child: const Text('Оформить заказ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkout() {
    final name = TextEditingController();
    final phone = TextEditingController();
    final comment = TextEditingController();
    String delivery = 'Самовывоз';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, refresh) => Container(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
          decoration: const BoxDecoration(color: cream, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Оформление заказа', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: burgundy)),
                  const SizedBox(height: 14),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Ваше имя', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон', hintText: '+7 ...', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  const Text('Способ получения', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['Самовывоз', 'Доставка'].map((v) => ChoiceChip(
                      label: Text(v), selected: delivery == v, onSelected: (_) => refresh(() => delivery = v),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: comment, maxLines: 2, decoration: const InputDecoration(labelText: 'Комментарий к заказу', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: wine, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                        if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Укажите имя и телефон')));
                          return;
                        }
                        final order = foods.where((f) => (cart[f.id] ?? 0) > 0).map((f) => '${f.name} × ${cart[f.id]}').join('\n');
                        final orderTotal = total;
                        final customerName = name.text.trim();
                        Navigator.pop(sheetContext);
                        setState(() => cart.clear());
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Заказ подготовлен!'),
                            content: Text('Спасибо, $customerName!\n\n$order\n\nСпособ: $delivery\nИтого: $orderTotal\n\nЭто демонстрационный прототип: заказ пока не отправляется в кафе.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отлично'))],
                          ),
                        );
                      },
                      child: const Text('Подтвердить заказ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _CategoryHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) => height != oldDelegate.height || child != oldDelegate.child;
}

class FoodDetailPage extends StatefulWidget {
  final FoodItem item;
  final ValueChanged<int> onAddToCart;

  const FoodDetailPage({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  // Количество на странице блюда — временный выбор.
  // Оно не меняет корзину, пока пользователь не нажмёт кнопку добавления.
  int count = 1;
  double _downwardDrag = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _downwardDrag, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Шапка главного экрана: 116 px. Оставляем под ней
                // небольшой зазор около 1 мм (4 logical px).
                final topGap = MediaQuery.of(context).padding.top + 120;
                final sheetHeight = (constraints.maxHeight - topGap)
                    .clamp(0.0, constraints.maxHeight);
                return SizedBox(
                  height: sheetHeight,
                  width: double.infinity,
                  child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragStart: (_) {
                    setState(() => _downwardDrag = 0);
                  },
                  onVerticalDragUpdate: (details) {
                    // Карточка следует за пальцем, но с небольшим сопротивлением.
                    // Это делает начало свайпа мягким и не слишком резким.
                    final nextOffset = _downwardDrag + details.delta.dy * 0.88;
                    setState(() {
                      _downwardDrag = nextOffset.clamp(0.0, 520.0).toDouble();
                    });
                  },
                  onVerticalDragEnd: (details) {
                    final shouldClose = _downwardDrag > 115 ||
                        details.velocity.pixelsPerSecond.dy > 850;
                    if (shouldClose) {
                      Navigator.pop(context);
                    } else {
                      // Если жест короткий, карточка плавно возвращается наверх.
                      setState(() => _downwardDrag = 0);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 370,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFF0DB),
                          Color(0xFFF9E1C4),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 180),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                color: burgundy.withOpacity(.45),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: burgundy,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 15,
                            color: wine,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 16, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatPrice(item.price),
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: wine,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: count > 1
                                ? () => setState(() => count--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: wine,
                            iconSize: 34,
                          ),
                          Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => count++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: wine,
                            iconSize: 34,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: wine,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            widget.onAddToCart(count);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Добавлено в корзину: ${item.name} × $count',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(
                            'Добавить в корзину',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
