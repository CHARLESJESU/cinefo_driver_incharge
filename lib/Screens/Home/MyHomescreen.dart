import 'package:flutter/material.dart';

class MyHomescreen extends StatefulWidget {
  const MyHomescreen({super.key});

  @override
  State<MyHomescreen> createState() => _MyHomescreenState();
}

class _MyHomescreenState extends State<MyHomescreen> {
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
                      backgroundImage: AssetImage('assets/logo.jpg'),
                      radius: 40,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {},
                ),
                // Add more drawer items here
              ],
            ),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/logo.jpg'),
                radius: 20,
                backgroundColor: Colors.white,
              ),
            ),
            actions: [
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
          body: Column(
            children: [
              SizedBox(height: 20), // Space from AppBar
              Container(
                height: 130,
                width: MediaQuery.of(context).size.width - 40,
                margin: EdgeInsets.symmetric(horizontal: 20),
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
              SizedBox(height: 20), // Space between containers
              Container(
                height: 130,
                width: MediaQuery.of(context).size.width - 40,
                margin: EdgeInsets.symmetric(horizontal: 20),
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
            ],
          ),
        )
      ],
    );
  }
}
