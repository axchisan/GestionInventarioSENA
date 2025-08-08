import 'package:flutter/material.dart';
import '../../widgets/common/sena_app_bar.dart';
import '../../widgets/common/sena_card.dart';
import '../../widgets/common/status_badge.dart';

class InventoryHistoryScreen extends StatefulWidget {
  final String itemId;
  final String itemName;

  const InventoryHistoryScreen({
    Key? key,
    required this.itemId,
    required this.itemName,
  }) : super(key: key);

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  String selectedFilter = 'Todos';
  final List<String> filters = ['Todos', 'Préstamos', 'Mantenimiento', 'Ubicación', 'Estado'];

  final List<Map<String, dynamic>> historyEvents = [
    {
      'id': '1',
      'type': 'loan',
      'title': 'Préstamo realizado',
      'description': 'Equipo prestado a Juan Pérez - Programa TI',
      'date': '2024-01-15 09:30',
      'status': 'completed',
      'user': 'Juan Pérez',
      'location': 'Aula 201'
    },
    {
      'id': '2',
      'type': 'maintenance',
      'title': 'Mantenimiento preventivo',
      'description': 'Limpieza y verificación de componentes',
      'date': '2024-01-10 14:00',
      'status': 'completed',
      'user': 'Carlos Técnico',
      'location': 'Taller de mantenimiento'
    },
    {
      'id': '3',
      'type': 'location',
      'title': 'Cambio de ubicación',
      'description': 'Movido desde Aula 101 a Aula 201',
      'date': '2024-01-08 11:15',
      'status': 'completed',
      'user': 'Ana Supervisora',
      'location': 'Aula 201'
    },
    {
      'id': '4',
      'type': 'status',
      'title': 'Cambio de estado',
      'description': 'Estado cambiado de "En reparación" a "Disponible"',
      'date': '2024-01-05 16:45',
      'status': 'completed',
      'user': 'Sistema',
      'location': 'Taller de mantenimiento'
    },
    {
      'id': '5',
      'type': 'loan',
      'title': 'Devolución de préstamo',
      'description': 'Equipo devuelto por María García',
      'date': '2024-01-03 10:20',
      'status': 'completed',
      'user': 'María García',
      'location': 'Aula 101'
    }
  ];

  List<Map<String, dynamic>> get filteredEvents {
    if (selectedFilter == 'Todos') return historyEvents;
    
    String filterType = {
      'Préstamos': 'loan',
      'Mantenimiento': 'maintenance',
      'Ubicación': 'location',
      'Estado': 'status'
    }[selectedFilter] ?? '';
    
    return historyEvents.where((event) => event['type'] == filterType).toList();
  }

  IconData getEventIcon(String type) {
    switch (type) {
      case 'loan':
        return Icons.person_outline;
      case 'maintenance':
        return Icons.build_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'status':
        return Icons.info_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Color getEventColor(String type) {
    switch (type) {
      case 'loan':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'location':
        return Colors.green;
      case 'status':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SenaAppBar(
        title: 'Historial - ${widget.itemName}',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Información del equipo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00324D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/sena-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.itemName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${widget.itemId}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(
                            text: 'Disponible',
                            type: StatusType.success, // Ejemplo de mapeo a un estado
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF00324D),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Timeline de eventos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                final isLast = index == filteredEvents.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: getEventColor(event['type']),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            getEventIcon(event['type']),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 60,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Event content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SenaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    event['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    event['date'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event['description'],
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event['user'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event['location'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}