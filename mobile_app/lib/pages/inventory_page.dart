import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {

  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF0F3D75),

        title: const Text(

          "Inventory",

          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: ListView(

        padding:
            const EdgeInsets.all(20),

        children: [

          buildItemCard(
            "Dell Latitude 7420",
            "Available",
            Colors.green,
          ),

          buildItemCard(
            "HP LaserJet Printer",
            "Low Stock",
            Colors.orange,
          ),

          buildItemCard(
            "Cisco Router",
            "Out of Stock",
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget buildItemCard(

    String title,

    String status,

    Color color,

  ) {

    return Container(

      margin:
          const EdgeInsets.only(bottom: 20),

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(

            color: Colors.black12,

            blurRadius: 5,
          )
        ],
      ),

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [

          Row(

            children: [

              const Icon(
                Icons.inventory_2,
                size: 40,
              ),

              const SizedBox(width: 15),

              Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style:
                        const TextStyle(

                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(status),
                ],
              ),
            ],
          ),

          Container(

            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration:
                BoxDecoration(

              color: color,

              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Text(

              status,

              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}