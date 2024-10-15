import 'dart:ui';
import 'package:carbonfootprint/faq.dart';
import 'package:carbonfootprint/funfacts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  String _carModel = '';
  double _distance = 0;
  double _mileage = 0;
  double _carbonFootprint = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to sign in with Google. Please try again.')),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _calculateCarbonFootprint() {
    if (_user == null) {
      _showSignInDialog();
      return;
    }
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _carbonFootprint = (_distance / _mileage) * 2.31;
      });
      _showResultDialog();
    }
  }

  void _navigateToFunFacts() {
    if (_user == null) {
      _showSignInDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FunFactPage()),
      );
    }
  }

  void _navigateToFAQ() {
    if (_user == null) {
      _showSignInDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FAQPage()),
      );
    }
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign In Required'),
          content: Text('Please sign in to access this feature.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Sign In'),
              onPressed: () {
                Navigator.of(context).pop();
                _signInWithGoogle();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Container(
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
                child: _buildSidebar(),
              ),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDesktopHeader(),
                        SizedBox(height: 40),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildCalculatorForm(),
                            ),
                            SizedBox(width: 40),
                            Expanded(
                              flex: 1,
                              child: _buildInfoCard(),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        _buildChart(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildHeader()),
        _buildUserActions(),
      ],
    );
  }

  Widget _buildUserActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_user != null)
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          )
        else
          TextButton(
            child: Text('Sign In', style: TextStyle(color: Colors.white)),
            onPressed: _signInWithGoogle,
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 30),
                  _buildCalculatorForm(),
                  SizedBox(height: 30),
                  _buildInfoCard(),
                  SizedBox(height: 30),
                  _buildChart(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      foregroundColor: Colors.white,
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
      title: Row(
        children: [
          Icon(Icons.eco, color: Colors.greenAccent, size: 24),
          SizedBox(width: 8),
          Text(
            'EcoCalc',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_user != null)
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          )
        else
          TextButton(
            child: Text('Sign In', style: TextStyle(color: Colors.white)),
            onPressed: _signInWithGoogle,
          ),
      ],
    );
  }

  Widget _buildDrawer() {
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
            _buildDrawerItem(Icons.home, 'Home'),
            _buildDrawerItem(Icons.lightbulb, 'FAQ', onTap: _navigateToFAQ),
            _buildDrawerItem(Icons.emoji_objects, 'Fun Facts',
                onTap: _navigateToFunFacts),
            if (_user != null)
              _buildDrawerItem(Icons.logout, 'Sign Out', onTap: _signOut)
            else
              _buildDrawerItem(Icons.login, 'Sign In',
                  onTap: _signInWithGoogle),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        if (onTap != null) {
          onTap();
        }
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.white10,
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          _buildLogo(),
          SizedBox(height: 60),
          _buildNavItem(Icons.home, 'Home'),
          _buildNavItem(Icons.lightbulb, 'FAQ', onTap: _navigateToFAQ),
          _buildNavItem(Icons.emoji_objects, 'Fun Facts',
              onTap: _navigateToFunFacts),
          if (_user != null)
            _buildNavItem(Icons.logout, 'Sign Out', onTap: _signOut)
          else
            _buildNavItem(Icons.login, 'Sign In', onTap: _signInWithGoogle),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: TextStyle(color: Colors.white70)),
      onTap: onTap,
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carbon Footprint Calculator',
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
          'Measure your impact and take steps towards a greener future.',
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

  Widget _buildCalculatorForm() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Details',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildInputField(
              icon: Icons.directions_car,
              label: 'Car Model',
              onSaved: (value) => _carModel = value!,
            ),
            SizedBox(height: 20),
            _buildInputField(
              icon: Icons.speed,
              label: 'Distance Travelled (km)',
              keyboardType: TextInputType.number,
              onSaved: (value) => _distance = double.parse(value!),
            ),
            SizedBox(height: 20),
            _buildInputField(
              icon: Icons.local_gas_station,
              label: 'Car Mileage (km/l)',
              keyboardType: TextInputType.number,
              onSaved: (value) => _mileage = double.parse(value!),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _calculateCarbonFootprint,
              child: Text('Calculate'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Did You Know?',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'The average car emits about 4.6 metric tons of carbon dioxide per year.',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToFunFacts,
            child: Text('Learn More'),
            style: ElevatedButton.styleFrom(
              // primary: Colors.transparent,
              // onPrimary: Colors.greenAccent,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carbon Footprint Trend',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 1),
                    ],
                    isCurved: true,
                    // colors: [Colors.greenAccent],
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      // colors: [Colors.greenAccent.withOpacity(0.3)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E3A8A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Your Carbon Footprint',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Based on your input:',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.greenAccent, size: 40),
                  SizedBox(width: 20),
                  Text(
                    '${_carbonFootprint.toStringAsFixed(2)} kg CO2',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text('Tips to reduce your footprint:',
                  style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              _buildTip('Use public transportation'),
              _buildTip('Carpool with colleagues'),
              _buildTip('Consider an electric vehicle'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.greenAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(tip, style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
