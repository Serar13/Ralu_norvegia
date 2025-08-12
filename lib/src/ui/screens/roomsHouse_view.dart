import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';

class WeeklyPlanner extends StatefulWidget {
  final String userId; // Add userId as a required parameter

  const WeeklyPlanner({Key? key, required this.userId}) : super(key: key);

  @override
  State<WeeklyPlanner> createState() => _WeeklyPlannerState();
}

class _WeeklyPlannerState extends State<WeeklyPlanner> {
  final List<String> tasks = ["Dormitor", "Bucătărie", "Living", "Baie", "Birou", "Dormitor copii", "relax"];
  final Map<String, String?> weekPlan = {
    "Luni": null,
    "Marti": null,
    "Miercuri": null,
    "Joi": null,
    "Vineri": null,
    "Sambata": null,
    "Duminica": null,
  };

  String? draggedTask;
  String? sourceDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planificator Săptămânal"),
      ),
      body: Column(
        children: [
          // Zona de preluare (Task Stack)
          DragTarget<String>(
            onAccept: (task) {
              setState(() {
                // Găsim ziua sursă și eliberăm locația
                if (sourceDay != null) {
                  weekPlan[sourceDay!] = null;
                }

                if (!tasks.contains(task)) {
                  tasks.add(task);
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                height: 150,
                child: Stack(
                  children: tasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    return Positioned(
                      left: index * 30.0, // Suprapunere ca un pachet de cărți
                      top: 30,
                      child: Draggable<String>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildTaskContainer(task, dragging: true),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildTaskContainer(task),
                        ),
                        child: _buildTaskContainer(task),
                        onDragStarted: () {
                          setState(() {
                            draggedTask = task;
                            sourceDay = null; // Sarcina vine din lista de sus
                          });
                        },
                        onDraggableCanceled: (_, __) {
                          setState(() {
                            draggedTask = null;
                            sourceDay = null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Planificatorul săptămânal (Zilele)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: weekPlan.keys.length,
              itemBuilder: (context, index) {
                final day = weekPlan.keys.elementAt(index);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titlul zilei
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      width: double.infinity,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Zona de drop pentru fiecare zi
                    DragTarget<String>(
                      onWillAccept: (data) => true,
                      onAccept: (task) {
                        setState(() {
                          // Găsim sarcina existentă în zi
                          final currentTask = weekPlan[day];

                          // Dacă vine din altă groapă
                          if (sourceDay != null && sourceDay != day) {
                            weekPlan[sourceDay!] = currentTask; // Mutăm sarcina curentă la sursă
                          }

                          // Dacă vine din lista de sus
                          if (sourceDay == null && currentTask != null) {
                            tasks.add(currentTask); // Adăugăm sarcina existentă în lista de sus
                          }

                          // Actualizăm groapa curentă
                          weekPlan[day] = task;

                          // Eliminăm sarcina din lista de sus
                          tasks.remove(task);
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 70,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: candidateData.isNotEmpty ? Colors.green : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                            color: weekPlan[day] != null ? Colors.blue[100] : Colors.grey[200],
                          ),
                          child: weekPlan[day] != null
                              ? LongPressDraggable<String>(
                            data: weekPlan[day]!,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Transform.translate(
                                offset: const Offset(50, 0),
                                child: _buildTaskContainer(
                                  weekPlan[day]!,
                                  dragging: true,
                                ),
                              ),
                            ),
                            childWhenDragging: const SizedBox.shrink(),
                            child: _buildTaskContainer(weekPlan[day]!),
                            onDragStarted: () {
                              setState(() {
                                draggedTask = weekPlan[day];
                                sourceDay = day; // Sarcina vine din această zi
                              });
                            },
                            onDraggableCanceled: (_, __) {
                              setState(() {
                                draggedTask = null;
                                sourceDay = null;
                              });
                            },
                          )
                              : const Center(
                            child: Text(
                              "Drop Here",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),

          // Buton pentru a trimite datele către review_chose
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                print(weekPlan);
                GoRouter.of(context).push(ReviewChosePath, extra: {'optionType': 'custom', 'weekPlan': weekPlan, 'userId': widget.userId});
              },
              child: const Text("Finalizează Configurația"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskContainer(String task, {bool dragging = false}) {
    return Container(
      width: 140,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dragging ? Colors.blue[300] : Colors.blue,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        task,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}