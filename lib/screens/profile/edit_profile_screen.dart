import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _offeredSkillController;
  late TextEditingController _wantedSkillController;

  late List<String> _offeredSkills;
  late List<String> _wantedSkills;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _offeredSkillController = TextEditingController();
    _wantedSkillController = TextEditingController();
    _offeredSkills = List.from(widget.user.offeredSkills);
    _wantedSkills = List.from(widget.user.wantedSkills);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _offeredSkillController.dispose();
    _wantedSkillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _addOfferedSkill() {
    final skill = _offeredSkillController.text.trim();
    if (skill.isNotEmpty && !_offeredSkills.contains(skill)) {
      setState(() {
        _offeredSkills.add(skill);
        _offeredSkillController.clear();
      });
    }
  }

  void _addWantedSkill() {
    final skill = _wantedSkillController.text.trim();
    if (skill.isNotEmpty && !_wantedSkills.contains(skill)) {
      setState(() {
        _wantedSkills.add(skill);
        _wantedSkillController.clear();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userService = UserService();
        
        // 1. Upload image if selected
        if (_imageFile != null) {
          await userService.uploadProfileImage(widget.user.uid, _imageFile!);
        }

        // 2. Update profile data
        await userService.updateProfile(
          uid: widget.user.uid,
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          offeredSkills: _offeredSkills,
          wantedSkills: _wantedSkills,
        );
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _saveProfile,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Edit
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(50), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) 
                          : (widget.user.photoUrl.isNotEmpty ? NetworkImage(widget.user.photoUrl) : null) as ImageProvider?,
                        child: (_imageFile == null && widget.user.photoUrl.isEmpty)
                            ? Icon(Icons.person_rounded, size: 50, color: theme.colorScheme.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Info
              const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: _buildInputDecoration('Bio', Icons.info_outline_rounded).copyWith(
                  alignLabelWithHint: true,
                  hintText: 'Tell us about your skills and experience...',
                ),
              ),
              
              const SizedBox(height: 32),

              // Offered Skills
              _buildSkillManagement(
                title: 'Skills I Offer',
                controller: _offeredSkillController,
                skills: _offeredSkills,
                color: theme.colorScheme.primary,
                onAdd: _addOfferedSkill,
              ),

              const SizedBox(height: 24),

              // Wanted Skills
              _buildSkillManagement(
                title: 'Skills I Want',
                controller: _wantedSkillController,
                skills: _wantedSkills,
                color: theme.colorScheme.secondary,
                onAdd: _addWantedSkill,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillManagement({
    required String title,
    required TextEditingController controller,
    required List<String> skills,
    required Color color,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: _buildInputDecoration('Add a skill...', Icons.add_circle_outline_rounded),
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add_box_rounded, color: color, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Chip(
            label: Text(skill, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            backgroundColor: color.withAlpha(20),
            deleteIcon: Icon(Icons.close_rounded, size: 18, color: color),
            onDeleted: () {
              setState(() => skills.remove(skill));
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withAlpha(50))),
          )).toList(),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
