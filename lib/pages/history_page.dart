import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<HistoryItem> _historyItems = [
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
    HistoryItem(
      url: 'https://itunes.com',
      subtitle: 'Data',
      dateTime: '16 Dec 2022, 9:30 pm',
    ),
  ];

  void _deleteItem(int index) {
    setState(() {
      _historyItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFFB300);
    const Color darkBar = Color(0xFF2F2F31);
    const Color pageBg = Color(0xFFF2F2F2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 390,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: pageBg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(34),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 26, 26, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: _historyItems.isEmpty
                            ? const Center(
                          child: Text(
                            'No history yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                            : ListView.separated(
                          itemCount: _historyItems.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = _historyItems[index];
                            return _HistoryCard(
                              item: item,
                              onDelete: () => _deleteItem(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom bar
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 18,
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: darkBar,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BottomBarItem(
                            icon: Icons.image_outlined,
                            label: 'Gallery',
                            selected: false,
                            selectedColor: yellow,
                            onTap: () {},
                          ),
                          const SizedBox(width: 70),
                          _BottomBarItem(
                            icon: Icons.history,
                            label: 'History',
                            selected: true,
                            selectedColor: yellow,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center scan button
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD8D3C4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFBBB39E),
                          width: 4,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 34,
                          color: Color(0xFF575757),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFFB300);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF909090),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 34,
            color: yellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEAEAEA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: yellow,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.dateTime,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? selectedColor : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryItem {
  final String url;
  final String subtitle;
  final String dateTime;

  HistoryItem({
    required this.url,
    required this.subtitle,
    required this.dateTime,
  });
}