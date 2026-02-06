import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:foodbalance/widgets/slideUp_animation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/widgets/profile_menu_overlay.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillControllerData();
    });
  }

  void _fillControllerData() {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _usiaController.text = userProv.usia > 0 ? userProv.usia.toString() : "";
      _tinggiController.text = userProv.tinggi > 0
          ? userProv.tinggi.toString()
          : "";
      _beratController.text = userProv.berat > 0
          ? userProv.berat.toString()
          : "";
      _jenisKelamin = userProv.jenisKelamin.isNotEmpty
          ? userProv.jenisKelamin
          : null;

      if (userProv.tujuan == "Turun BB")
        _selectedGoalIndex = 0;
      else if (userProv.tujuan == "Jaga BB")
        _selectedGoalIndex = 1;
      else if (userProv.tujuan == "Naik BB")
        _selectedGoalIndex = 2;
    });
  }

  @override
  void dispose() {
    _usiaController.dispose();
    _tinggiController.dispose();
    _beratController.dispose();
    super.dispose();
  }

  final TextEditingController _usiaController = TextEditingController(text: "");
  final TextEditingController _tinggiController = TextEditingController(
    text: "",
  );
  final TextEditingController _beratController = TextEditingController(
    text: "",
  );
  String? _jenisKelamin;

  bool _isEditable = false;
  int _selectedGoalIndex = 1;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundYellow = Color(0xFFFDF7C3);

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final String? photoUrl = user?.photoURL;
    return Scaffold(
      backgroundColor: backgroundYellow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Profil",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        "Kelola Informasi Pribadi Anda",
                        style: TextStyle(
                          fontSize: 14, // Sedikit diperkecil agar pas
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Cari bagian CircleAvatar di Row Header kamu, ubah menjadi:
                  GestureDetector(
                    onTap: () => _showProfileDetail(),
                    child: Hero(
                      tag: 'profilePic', // Hero animation agar transisi halus
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : const AssetImage("assets/images/profile.png")
                                  as ImageProvider,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu Informasi Pribadi
              EntranceFaded(
                delay: const Duration(milliseconds: 200),
                child: _buildPersonalInfoCard(),
              ),
              const SizedBox(height: 20),

              // Kartu Tujuan (Goal)
              EntranceFaded(
                delay: const Duration(milliseconds: 400),
                child: _buildGoalSection(),
              ),
              const SizedBox(height: 20),

              // Letakkan ini di Column dalam build() setelah GoalSection
              EntranceFaded(
                delay: const Duration(milliseconds: 500),
                child: _buildAchievementTarget(userProv),
              ),
              const SizedBox(height: 20),

              // Tombol Simpan & Edit
              EntranceFaded(
                delay: const Duration(milliseconds: 600),
                child: _buildFooterButtons(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDetail() {
    final user = FirebaseAuth.instance.currentUser;

    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Klik di bagian gelap untuk menutup
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.5), // Efek gelap di kiri
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ProfileMenuOverlay(
          photoUrl: user?.photoURL,
          displayName: user?.displayName,
          email: user?.email,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // Animasi slide masuk dari kanan
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "Informasi Pribadi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputRow("Usia", "Tahun", _usiaController),
          _buildDropdownRow(),
          _buildInputRow("Tinggi Badan", "cm", _tinggiController),
          _buildInputRow("Berat Badan", "kg", _beratController),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String suffix,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: _isEditable,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isEditable ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: "",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    suffix,
                    style: TextStyle(
                      color: _isEditable ? Colors.white70 : Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Jenis Kelamin",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _jenisKelamin,
                  onChanged: _isEditable
                      ? (String? newValue) {
                          setState(() {
                            _jenisKelamin = newValue;
                          });
                        }
                      : null,
                  hint: const Center(
                    child: Text(
                      "Pilih",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1B4D3E),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  isExpanded: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  items: <String>['Laki - laki', 'Perempuan']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Center(child: Text(value)),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.track_changes, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                "Tujuan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              double itemWidth = (constraints.maxWidth - 20) / 3;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGoalItem(
                    "Turun BB",
                    "-500 kcal",
                    Icons.trending_down,
                    0,
                    itemWidth,
                  ),
                  _buildGoalItem(
                    "Jaga BB",
                    "Tetap Ideal",
                    Icons.balance,
                    1,
                    itemWidth,
                  ),
                  _buildGoalItem(
                    "Naik BB",
                    "+500 kcal",
                    Icons.trending_up,
                    2,
                    itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(
    String title,
    String subtitle,
    IconData icon,
    int index,
    double width,
  ) {
    bool isActive = _selectedGoalIndex == index;

    return GestureDetector(
      onTap: _isEditable
          ? () => setState(() => _selectedGoalIndex = index)
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1B5E20)
              : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFields() {
    setState(() {
      _usiaController.clear();
      _tinggiController.clear();
      _beratController.clear();
      _jenisKelamin = null;
      _selectedGoalIndex = 1;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditable = false;
      _fillControllerData(); // Mengambil data asli dari Provider
    });
    _showSnackBar("Perubahan dibatalkan");
  }

  Widget _buildFooterButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_isEditable) {
              if (_usiaController.text.isEmpty ||
                  _tinggiController.text.isEmpty ||
                  _beratController.text.isEmpty ||
                  _jenisKelamin == null) {
                _showSnackBar("Data tidak boleh kosong!");
                return;
              }

              double bb = double.tryParse(_beratController.text) ?? 0;
              double tb = double.tryParse(_tinggiController.text) ?? 0;
              int usia = int.tryParse(_usiaController.text) ?? 0;
              String jk = _jenisKelamin ?? "Laki - laki";

              List<String> goals = ["Turun BB", "Jaga BB", "Naik BB"];
              String goal = goals[_selectedGoalIndex];

              Provider.of<UserProvider>(
                context,
                listen: false,
              ).kalkulasiDanSimpan(
                bb: bb,
                tb: tb,
                age: usia,
                jk: jk,
                goal: goal,
              );

              setState(() => _isEditable = false);
              _showSnackBar("Informasi disimpan & Kalori dihitung!");
            }
          },
          child: _buildLongButton(
            "Simpan",
            Icons.bookmark_border,
            _isEditable ? primaryGreen : Colors.grey,
          ),
        ),

        if (_isEditable) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _clearFields,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.red.shade400, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.red.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Bersihkan Form",
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            if (_isEditable) {
              _cancelEdit();
            } else {
              setState(() => _isEditable = true);
            }
          },
          child: _buildLongButton(
            _isEditable ? "Batal Edit" : "Edit Profil",
            _isEditable ? Icons.close : Icons.edit_note,
            _isEditable ? Colors.orange.shade800 : primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildLongButton(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTarget(UserProvider userProv) {
    final bool isComplete = userProv.isProfileComplete;
    final String estimasi = userProv.estimasiWaktu;

    bool isSuccess =
        estimasi.contains("Tercapai") || estimasi.contains("Pertahankan");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Jika belum lengkap pakai warna abu-abu
          color: !isComplete
              ? Colors.grey.withOpacity(0.3)
              : (isSuccess
                    ? Colors.green.withOpacity(0.5)
                    : primaryGreen.withOpacity(0.3)),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Target Capaian",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // Teks jadi abu-abu jika belum lengkap
              color: !isComplete
                  ? Colors.grey
                  : (isSuccess ? Colors.green : primaryGreen),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // Ikon berubah jadi tanda tanya/info jika data kosong
                !isComplete
                    ? Icons.help_outline
                    : (isSuccess
                          ? Icons.check_circle_outline
                          : Icons.timer_outlined),
                color: !isComplete
                    ? Colors.grey
                    : (isSuccess ? Colors.green : Colors.orange),
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  !isComplete ? "Data Profil Belum Lengkap" : estimasi,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: !isComplete
                        ? Colors.grey
                        : (isSuccess ? Colors.green : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            // Catatan kaki berubah jika data belum lengkap
            !isComplete
                ? "Klik 'Edit Profil' di bawah untuk melengkapi data"
                : "*Estimasi berdasarkan progres sehat 0.5kg/minggu",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
      ),
    );
  }
}
