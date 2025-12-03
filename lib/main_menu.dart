import 'package:flutter/material.dart';
import 'page_2d.dart';
import 'page_3d.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Widget buildMenuButton(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("MAIN MENU"),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 120),

              buildMenuButton(
                context,
                Icons.grid_on,
                "2D View",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Page2D()),
                  );
                },
              ),

              buildMenuButton(
                context,
                Icons.abc_outlined,
                "3D View",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Page3D()),
                  );
                },
              ),

              buildMenuButton(
                context,
                Icons.settings,
                "Settings",
                    () {},
              ),

              buildMenuButton(
                context,
                Icons.insert_chart,
                "Statistics",
                    () {},
              ),

              buildMenuButton(
                context,
                Icons.info_outline,
                "About",
                    () {},
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
