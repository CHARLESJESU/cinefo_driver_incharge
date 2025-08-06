import 'package:flutter/material.dart';
import 'package:production/Profile/profilesccreen.dart';
import 'package:production/Profile/changepassword.dart';

class MyHomescreen extends StatefulWidget {
  const MyHomescreen({super.key});

  @override
  State<MyHomescreen> createState() => _MyHomescreenState();
}

class _MyHomescreenState extends State<MyHomescreen> {
  bool _showAllItems = false;

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF2B5682),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // TODO: Implement actual logout logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout functionality will be implemented'),
                    backgroundColor: Color(0xFF2B5682),
                  ),
                );
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2B5682),
                Color(0xFF24426B),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          endDrawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2B5682),
                    Color(0xFF24426B),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2B5682),
                          Color(0xFF24426B),
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        backgroundImage: AssetImage('assets/tenkrow.png'),
                        radius: 40,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // View Profile
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'View Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Profilesccreen(),
                        ),
                      );
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Change Password
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Changepassword(),
                        ),
                      ); // Close drawer first
                    },
                  ),

                  // White separator line
                  Divider(
                    color: Colors.white.withOpacity(0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                  // Logout
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/cinefo-logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: 100), // Add bottom padding to avoid navigation bar
              child: Column(
                children: [
                  SizedBox(height: 20), // Space from AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      //container 1
                      height: 130,
                      decoration: BoxDecoration(
                        color: Color(0xFF355E8C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 7),
                          const CircleAvatar(
                            radius: 48,
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Srinivasan.S",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text("CEO",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white70)),
                                Text("CHENNAI GREENCITY",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white70)),
                                Text("managing director",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Space between containers
                  // Avengers: Endgame container (different design)
                  //container 2
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A6FA5),
                            Color(0xFF2E4B73),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Avengers: Endgame",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Action • 2019",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Space after container 2
                  // List of items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        // Display first 3 items or all items based on _showAllItems
                        ...(_showAllItems
                            ? _getAllListItems()
                            : _getInitialListItems()),

                        SizedBox(height: 15),
                        // Show More/Less button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllItems = !_showAllItems;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Color(0xFF355E8C).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showAllItems ? "Show Less" : "Show More",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  _showAllItems
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  // Helper method to get initial 3 list items
  List<Widget> _getInitialListItems() {
    return [
      _buildListItem("CN364-Mid-Night", "10pm-6am(mid-night)", "04-08-2025"),
      _buildListItem("CN365-Morning", "6am-2pm(morning)", "05-08-2025"),
      _buildListItem("CN366-Evening", "2pm-10pm(evening)", "06-08-2025"),
    ];
  }

  // Helper method to get all 6 list items
  List<Widget> _getAllListItems() {
    return [
      _buildListItem("CN364-Mid-Night", "10pm-6am(mid-night)", "04-08-2025"),
      _buildListItem("CN365-Morning", "6am-2pm(morning)", "05-08-2025"),
      _buildListItem("CN366-Evening", "2pm-10pm(evening)", "06-08-2025"),
      _buildListItem("CN367-Night", "10pm-6am(night)", "07-08-2025"),
      _buildListItem("CN368-Day", "8am-8pm(day)", "08-08-2025"),
      _buildListItem("CN369-Late", "11pm-7am(late)", "09-08-2025"),
    ];
  }

  // Helper method to build individual list item
  Widget _buildListItem(String code, String timing, String date) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - Code and timing
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B5682),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  timing,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Right side - Date
          Expanded(
            flex: 1,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF355E8C),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
