import 'package:flutter/material.dart';
import 'package:production/Screens/configuration/configdetailscreen.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    double titleFontSize = screenWidth * 0.045; // ~16 on 360 width
    double roleFontSize = screenWidth * 0.04;
    double countFontSize = screenWidth * 0.04;
    double iconSize = screenWidth * 0.06;

    // Responsive paddings
    double cardPadding = screenWidth * 0.04; // ~16 px
    double containerVerticalPadding = screenHeight * 0.015; // ~12 px
    double containerHorizontalPadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Configuration',
          style: TextStyle(color: Colors.black, fontSize: titleFontSize),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          elevation: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: containerVerticalPadding,
                  horizontal: containerHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.03)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB6C4FF), Color(0xFFF8F9FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Text(
                  'Lightman',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildRoleTile('Incharge', 0, roleFontSize, countFontSize,
                  iconSize, context),
              _buildRoleTile(
                  'Helper', 0, roleFontSize, countFontSize, iconSize, context),
              _buildRoleTile('No Break', 0, roleFontSize, countFontSize,
                  iconSize, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(
    String title,
    int count,
    double titleFontSize,
    double countFontSize,
    double iconSize,
    BuildContext context,
  ) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: titleFontSize)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: countFontSize, color: Colors.black),
            ),
            SizedBox(width: iconSize * 0.4),
            Icon(Icons.chevron_right, color: Colors.black, size: iconSize),
          ],
        ),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SelectMembersScreen()));
        },
      ),
    );
  }
}
