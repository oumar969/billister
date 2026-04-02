import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';

class OrderHistoryScreen extends StatefulWidget {
  final ApiClient api;

  const OrderHistoryScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;
  int _selectedTab = 0; // 0 = as buyer, 1 = as seller

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    if (_selectedTab == 0) {
      _ordersFuture = widget.api.getMyOrders();
    } else {
      // In a real app, you'd fetch seller orders
      _ordersFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mine ordrer'), elevation: 0),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              isScrollable: false,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                  _loadOrders();
                });
              },
              tabs: [
                Tab(text: 'Som køber (${_selectedTab == 0 ? '...' : ''})'),
                Tab(text: 'Som sælger (${_selectedTab == 1 ? '...' : ''})'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Fejl: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _loadOrders()),
                          child: const Text('Prøv igen'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTab == 0
                              ? 'Du har ingen købs-ordrer endnu'
                              : 'Du har ingen salgs-ordrer endnu',
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderTile(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusDanish = order.statusDanish;

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getStatusIcon(order.status), color: statusColor),
      ),
      title: Text('Ordre ${order.id.substring(0, 8).toUpperCase()}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Annonce: ${order.listingId.substring(0, 8)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${order.amount.toStringAsFixed(0)} DKK',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusDanish,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oprettet: ${_formatDate(order.createdAtUtc)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailScreen(api: widget.api, order: order),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'shipped':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'paid':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class OrderDetailScreen extends StatelessWidget {
  final ApiClient api;
  final Order order;

  const OrderDetailScreen({Key? key, required this.api, required this.order})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Ordre detaljer'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: statusColor, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${order.statusDanish}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ordre: ${order.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Beløb',
                    '${order.amount.toStringAsFixed(0)} DKK',
                  ),
                  const Divider(),
                  _buildDetailRow('Annonce ID', order.listingId),
                  const Divider(),
                  _buildDetailRow(
                    'Oprettet',
                    '${_formatDate(order.createdAtUtc)} kl. ${_formatTime(order.createdAtUtc)}',
                  ),
                  if (order.paidAtUtc != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      'Betalt',
                      '${_formatDate(order.paidAtUtc!)} kl. ${_formatTime(order.paidAtUtc!)}',
                    ),
                  ],
                  if (order.updatedAtUtc != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      'Opdateret',
                      '${_formatDate(order.updatedAtUtc!)} kl. ${_formatTime(order.updatedAtUtc!)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (order.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to payment screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gå til betaling... (ikke implementeret)',
                              ),
                            ),
                          );
                        },
                        child: const Text('Gå til betaling'),
                      ),
                    ),
                  if (order.status == 'shipped')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bekræft modtagelse... (ikke implementeret)',
                              ),
                            ),
                          );
                        },
                        child: const Text('Bekræft modtagelse'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'shipped':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
