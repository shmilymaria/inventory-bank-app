import 'package:flutter/material.dart';
import 'package:inventori_bank/pages/login_page.dart';
import 'package:inventori_bank/pages/inventory_page.dart';
import 'package:inventori_bank/pages/profile_page.dart';

class DashboardPage extends StatelessWidget {

  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF5F7FA),

      bottomNavigationBar:

          BottomNavigationBar(

        currentIndex: 0,

        selectedItemColor:
            const Color(0xFF0F3D75),

        unselectedItemColor:
            Colors.grey,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          child: Padding(

            padding:
                const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // HEADER

                Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    Row(

                      children: [

                        CircleAvatar(

                          radius: 25,

                          backgroundColor:
                              Colors.blue,

                          child: const Icon(

                            Icons.person,

                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                            width: 15),

                        const Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(

                              "Bank XYZ",

                              style: TextStyle(

                                fontSize: 26,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            Text(
                              "Welcome, Admin",
                            ),
                          ],
                        ),
                      ],
                    ),

                    PopupMenuButton(

  icon: const Icon(
    Icons.more_vert,
    size: 30,
  ),

  itemBuilder: (context) => [

    const PopupMenuItem(

      value: 'logout',

      child: Row(

        children: [

          Icon(Icons.logout),

          SizedBox(width: 10),

          Text("Logout"),
        ],
      ),
    ),
  ],

  onSelected: (value) {

    if (value == 'logout') {

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (context)
              => const LoginPage(),
        ),
      );
    }
  },
),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(

                  "Overview Statistics",

                  style: TextStyle(

                    fontSize: 24,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // STATISTICS

                buildStatisticCard(

                  title:
                      "TOTAL INVENTORY",

                  value: "1,284",

                  color: Colors.blue,

                  icon:
                      Icons.inventory_2,
                ),

                const SizedBox(height: 15),

                buildStatisticCard(

                  title:
                      "LOW STOCK",

                  value: "24",

                  color: Colors.red,

                  icon:
                      Icons.warning_amber,
                ),

                const SizedBox(height: 15),

                buildStatisticCard(

                  title:
                      "PENDING REQUESTS",

                  value: "48",

                  color: Colors.orange,

                  icon:
                      Icons.access_time,
                ),

                const SizedBox(height: 15),

                buildStatisticCard(

                  title:
                      "DISTRIBUTED ITEMS",

                  value: "856",

                  color: Colors.green,

                  icon:
                      Icons.outbound,
                ),

                const SizedBox(height: 30),

                const Text(

                  "Management Portal",

                  style: TextStyle(

                    fontSize: 24,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // MENU GRID

                GridView.count(

                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  crossAxisCount: 2,

                  crossAxisSpacing: 15,

                  mainAxisSpacing: 15,

                  childAspectRatio: 1.1,

                  children: [

                    buildMenuCard(
                      title: "Inventory",
                      icon: Icons.inventory,
                    ),

                    buildMenuCard(
                      title: "Requests",
                      icon:
                          Icons.request_page,
                    ),

                    buildMenuCard(
                      title: "Distribution",
                      icon:
                          Icons.local_shipping,
                    ),

                    buildMenuCard(
                      title: "Reports",
                      icon:
                          Icons.bar_chart,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // CHART CARD

                Container(

                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      BoxDecoration(

                    color:
                        const Color(
                            0xFF0F3D75),

                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),

                  child: const Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        "Inventory Health Trend",

                        style: TextStyle(

                          color:
                              Colors.white,

                          fontSize: 24,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(

                        "Stable growth across all regional branches for Q3.",

                        style: TextStyle(

                          color:
                              Colors.white70,

                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 20),

                      Icon(

                        Icons.show_chart,

                        color:
                            Colors.white,

                        size: 100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStatisticCard({

    required String title,

    required String value,

    required Color color,

    required IconData icon,

  }) {

    return Container(

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

              Icon(
                icon,
                color: color,
                size: 35,
              ),

              const SizedBox(width: 15),

              Text(

                title,

                style: const TextStyle(

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          Text(

            value,

            style: TextStyle(

              fontSize: 28,

              fontWeight:
                  FontWeight.bold,

              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuCard({

    required String title,

    required IconData icon,

  }) {

    return Container(

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

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(

            icon,

            size: 45,

            color:
                const Color(0xFF0F3D75),
          ),

          const SizedBox(height: 15),

          Text(

            title,

            style: const TextStyle(

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}