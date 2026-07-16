import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/doctor_filters.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../widgets/delete_account_dialog.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  UserRole? _selectedRole;
  String? _selectedEmpresa;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadDoctors());
  }

  void _applyFilters() {
    context.read<AdminBloc>().add(
          UpdateDoctorFilters(
            filters: DoctorFilters(
              rol: _selectedRole,
              empresaNombre: _selectedEmpresa,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Doctores'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocConsumer<AdminBloc, AdminState>(
              listener: (context, state) {
                if (state is DoctorDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                if (state is AdminError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DoctorsLoaded) {
                  if (state.doctors.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron doctores'),
                    );
                  }
                  return _buildDoctorList(state.doctors);
                }

                return const Center(child: Text('Deslice para cargar'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRoleChipFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmpresaDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChipFilter() {
    return Wrap(
      spacing: 6,
      children: [
        FilterChip(
          label: const Text('Todos', style: TextStyle(fontSize: 12)),
          selected: _selectedRole == null,
          onSelected: (_) {
            setState(() => _selectedRole = null);
            _applyFilters();
          },
        ),
        FilterChip(
          label: const Text('ADMIN', style: TextStyle(fontSize: 12)),
          selected: _selectedRole == UserRole.admin,
          onSelected: (_) {
            setState(() {
              _selectedRole =
                  _selectedRole == UserRole.admin ? null : UserRole.admin;
            });
            _applyFilters();
          },
          selectedColor: Colors.red.shade100,
        ),
        FilterChip(
          label: const Text('JEFE', style: TextStyle(fontSize: 12)),
          selected: _selectedRole == UserRole.jefe,
          onSelected: (_) {
            setState(() {
              _selectedRole =
                  _selectedRole == UserRole.jefe ? null : UserRole.jefe;
            });
            _applyFilters();
          },
          selectedColor: Colors.orange.shade100,
        ),
        FilterChip(
          label: const Text('USER', style: TextStyle(fontSize: 12)),
          selected: _selectedRole == UserRole.user,
          onSelected: (_) {
            setState(() {
              _selectedRole =
                  _selectedRole == UserRole.user ? null : UserRole.user;
            });
            _applyFilters();
          },
          selectedColor: Colors.blue.shade100,
        ),
      ],
    );
  }

  Widget _buildEmpresaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedEmpresa,
      hint: const Text('Empresa', style: TextStyle(fontSize: 13)),
      isDense: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Todas')),
      ],
      onChanged: (value) {
        setState(() => _selectedEmpresa = value);
        _applyFilters();
      },
    );
  }

  Widget _buildDoctorList(List<UserEntity> doctors) {
    return RefreshIndicator(
      onRefresh: () async => _applyFilters(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return _buildDoctorTile(doctor);
        },
      ),
    );
  }

  Widget _buildDoctorTile(UserEntity doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(doctor.rol).withValues(alpha: 0.2),
          child: Icon(
            Icons.person,
            color: _roleColor(doctor.rol),
          ),
        ),
        title: Text(
          doctor.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_roleLabel(doctor.rol)} · ${doctor.email}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteDialog(doctor),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(UserEntity doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteAccountDialog(doctorName: doctor.nombre),
    );

    if (confirmed == true && mounted) {
      context.read<AdminBloc>().add(DeleteDoctor(doctorId: doctor.id));
    }
  }

  Color _roleColor(UserRole rol) {
    switch (rol) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.jefe:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  String _roleLabel(UserRole rol) {
    switch (rol) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.jefe:
        return 'JEFE';
      case UserRole.user:
        return 'USER';
    }
  }
}
