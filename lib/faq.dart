import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildSidebar(context),
            ),
            Expanded(
              flex: 3,
              child: _buildMainContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: _buildMainContent(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
      ),
      elevation: 0,
      title: Text(
        'EcoCalc',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            // Show info dialog or navigate to info page
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF1E3A8A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white10,
              ),
              child: _buildLogo(),
            ),
            _buildDrawerItem(context, Icons.home, 'Home'),
            _buildDrawerItem(context, Icons.calculate, 'Calculator'),
            _buildDrawerItem(context, Icons.info, 'About'),
            _buildDrawerItem(context, Icons.lightbulb, 'Tips'),
            _buildDrawerItem(context, Icons.emoji_objects, 'Fun Facts'),
            _buildDrawerItem(context, Icons.question_answer, 'FAQ'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        if (title != 'FAQ') {
          // Navigate to the corresponding page
          Navigator.pop(context); // Go back to previous page (likely HomePage)
        }
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: Colors.white10,
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          _buildLogo(),
          SizedBox(height: 60),
          _buildNavItem(context, Icons.home, 'Home'),
          _buildNavItem(context, Icons.calculate, 'Calculator'),
          _buildNavItem(context, Icons.info, 'About'),
          _buildNavItem(context, Icons.lightbulb, 'Tips'),
          _buildNavItem(context, Icons.emoji_objects, 'Fun Facts'),
          _buildNavItem(context, Icons.question_answer, 'FAQ'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: TextStyle(color: Colors.white70)),
      onTap: () {
        if (label != 'FAQ') {
          Navigator.pop(context); // Go back to previous page (likely HomePage)
        }
      },
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.eco, color: Colors.greenAccent, size: 40),
        SizedBox(width: 8),
        Text(
          'EcoCalc',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 40),
            _buildFAQList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Find answers to common questions about carbon footprint and environmental impact.',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('faq').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Something went wrong',
                  style: TextStyle(color: Colors.white)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Colors.greenAccent));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildFAQCard(snapshot.data!.docs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildFAQCard(QueryDocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Colors.white70,
        ),
        child: ExpansionTile(
          title: Text(
            data['question'] ?? 'No question available',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                data['answer'] ?? 'No answer available',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
