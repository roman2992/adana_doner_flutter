import 'package:flutter/material.dart';

void main() => runApp(const AdanaApp());

const burgundy = Color(0xFF4A1018);
const wine = Color(0xFF721E2A);
const gold = Color(0xFFE8B85A);
const cream = Color(0xFFFFF5E8);

class FoodItem {
  final String id, name, description, category, emoji;
  final int price;
  const FoodItem(this.id, this.name, this.description, this.category, this.price, this.emoji);
}

const foods = <FoodItem>[
  FoodItem('combo1', 'Комбо 1', 'Куриный донер в лаваше или пите, картофель фри, кола, кетчуп', 'Комбо', 450, '🥙'),
  FoodItem('combo2', 'Комбо 2', 'Говяжий донер в лаваше или пите, картофель фри, кола, кетчуп', 'Комбо', 550, '🥙'),
  FoodItem('bisk_beef', 'Искендер кебаб', 'Донер из говядины с соусом', 'Донер из говядины', 800, '🍖'),
  FoodItem('plate_beef', 'Донер на тарелке', 'Сочный говяжий донер с гарниром', 'Донер из говядины', 750, '🍽️'),
  FoodItem('rice_beef', 'Донер на тарелке с рисом', 'Говяжий донер с рисом', 'Донер из говядины', 750, '🍛'),
  FoodItem('lavash_beef', 'Донер в лаваше', 'Говяжий донер в тонком лаваше', 'Донер из говядины', 400, '🌯'),
  FoodItem('sarma_beef', 'Сарма донер с сыром', 'Говяжий донер с сыром', 'Донер из говядины', 800, '🧀'),
  FoodItem('pita_beef', 'Донер в пиде', 'Говяжий донер в турецкой лепёшке', 'Донер из говядины', 400, '🥙'),
  FoodItem('pide_meat_cheese', 'Пиде с мясом и сыром', 'Турецкая лепёшка с мясом и сыром', 'Турецкая выпечка', 700, '🥖'),
  FoodItem('pide_minced', 'Пиде с фаршем', 'Турецкая лепёшка с мясным фаршем', 'Турецкая выпечка', 550, '🥖'),
  FoodItem('pide_cheese', 'Пиде с сыром', 'Турецкая лепёшка с сыром', 'Турецкая выпечка', 500, '🧀'),
  FoodItem('pide_mix', 'Пиде с сыром и фаршем', 'Сыр и мясной фарш', 'Турецкая выпечка', 600, '🥖'),
  FoodItem('pide_assorti', 'Пиде ассорти', 'Ассорти из начинок', 'Турецкая выпечка', 700, '🥖'),
  FoodItem('soup_lentil', 'Чечевичный суп', 'Турецкий суп из красной чечевицы', 'Первые блюда', 250, '🍲'),
  FoodItem('soup_chicken', 'Куриный суп', 'Домашний суп с курицей', 'Первые блюда', 250, '🍜'),
  FoodItem('soup_mushroom', 'Крем-суп с грибами', 'Нежный сливочный суп с грибами', 'Первые блюда', 250, '🍄'),
  FoodItem('isk_chicken', 'Искендер кебаб', 'Искендер из курицы', 'Донер из курицы', 650, '🍗'),
  FoodItem('plate_chicken', 'Донер на тарелке', 'Куриный донер с гарниром', 'Донер из курицы', 600, '🍽️'),
  FoodItem('rice_chicken', 'Донер на тарелке с рисом', 'Куриный донер с рисом', 'Донер из курицы', 600, '🍛'),
  FoodItem('box_chicken', 'Донер бокс с курицей', 'Куриный донер в удобном боксе', 'Донер из курицы', 350, '🥡'),
  FoodItem('lavash_chicken', 'Донер в лаваше', 'Куриный донер в тонком лаваше', 'Донер из курицы', 300, '🌯'),
  FoodItem('sarma_chicken', 'Сарма донер с сыром', 'Куриный донер с сыром', 'Донер из курицы', 700, '🧀'),
  FoodItem('pita_chicken', 'Донер в пиде', 'Куриный донер в турецкой лепёшке', 'Донер из курицы', 320, '🥙'),
];

class AdanaApp extends StatelessWidget {
  const AdanaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Адана донер — Вкус Турции',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFFFF8F0), colorScheme: ColorScheme.fromSeed(seedColor: wine, primary: wine, secondary: gold), fontFamily: 'Roboto'),
    home: const MenuPage(),
  );
}

class MenuPage extends StatefulWidget { const MenuPage({super.key}); @override State<MenuPage> createState() => _MenuPageState(); }
class _MenuPageState extends State<MenuPage> {
  final Map<String, int> cart = {};
  String category = 'Все';
  final categories = const ['Все', 'Комбо', 'Донер из говядины', 'Донер из курицы', 'Турецкая выпечка', 'Первые блюда'];
  int get totalCount => cart.values.fold(0, (a, b) => a + b);
  int get total => foods.fold(0, (sum, f) => sum + f.price * (cart[f.id] ?? 0));
  void add(FoodItem item) => setState(() => cart[item.id] = (cart[item.id] ?? 0) + 1);
  void change(FoodItem item, int delta) => setState(() { final n = (cart[item.id] ?? 0) + delta; if (n <= 0) { cart.remove(item.id); } else { cart[item.id] = n; } });

  @override
  Widget build(BuildContext context) {
    final visible = foods.where((f) => category == 'Все' || f.category == category).toList();
    return Scaffold(
      body: SafeArea(child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 22, 18, 10), child: Text('Наше меню', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: burgundy)))),
        SliverToBoxAdapter(child: SizedBox(height: 48, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final c = categories[i]; final selected = c == category; return ChoiceChip(label: Text(c), selected: selected, onSelected: (_) => setState(() => category = c), selectedColor: wine, backgroundColor: Colors.white, labelStyle: TextStyle(color: selected ? Colors.white : burgundy, fontWeight: FontWeight.w700), side: BorderSide(color: selected ? wine : const Color(0xFFE9D9CC))); }))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 110), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, i) => _foodCard(visible[i]), childCount: visible.length), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .72))),
      ])),
      bottomNavigationBar: totalCount == 0 ? null : SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: wine, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _openCart, icon: const Icon(Icons.shopping_bag_outlined), label: Text('Корзина · $totalCount шт. · $total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))),
    );
  }

  Widget _header() => Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.fromLTRB(20, 20, 20, 18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [burgundy, Color(0xFF8C2935)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: burgundy.withOpacity(.2), blurRadius: 18, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.restaurant, color: burgundy, size: 29)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('АДАНА ДОНЕР', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)), Text('ВКУС ТУРЦИИ', style: TextStyle(color: gold, fontWeight: FontWeight.w800, letterSpacing: 3, fontSize: 11))])), const Icon(Icons.local_fire_department, color: gold, size: 28)]), const SizedBox(height: 18), const Text('Почувствуй вкус\nнастоящей Турции', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.12, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Свежий донер • ароматные специи • с любовью', style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 12)), const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/menu_board.jpg', height: 92, width: double.infinity, fit: BoxFit.cover))]));

  Widget _foodCard(FoodItem f) {
    final count = cart[f.id] ?? 0;
    return Container(
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
                    Expanded(child: Text('${f.price}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: wine))),
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
                      subtitle: Text('${f.price} × ${cart[f.id]}'),
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
                    Text('$total', style: const TextStyle(fontSize: 22, color: wine, fontWeight: FontWeight.w900)),
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
