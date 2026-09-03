<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // ----------------------------------------------------------------
    // INDEX — Daftar seluruh user
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $query = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.id')
            ->select('users.*', 'roles.role_name');

        // Filter pencarian
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('users.nama_lengkap', 'like', "%{$search}%")
                  ->orWhere('users.username', 'like', "%{$search}%")
                  ->orWhere('users.bagian', 'like', "%{$search}%");
            });
        }

        // Filter role
        if ($request->filled('role')) {
            $query->where('users.role_id', $request->role);
        }

        // Filter status
        if ($request->filled('status')) {
            $query->where('users.status_aktif', $request->status);
        }

        $users = $query->orderBy('users.role_id')->orderBy('users.id', 'desc')
                       ->paginate(10)->withQueryString();

        $roles = Role::orderBy('id')->get();

        return view('user.index', compact('users', 'roles'));
    }

    // ----------------------------------------------------------------
    // CREATE — Form tambah user baru
    // ----------------------------------------------------------------
    public function create()
    {
        $roles = Role::orderBy('id')->get();
        return view('user.create', compact('roles'));
    }

    // ----------------------------------------------------------------
    // STORE — Simpan user baru
    // ----------------------------------------------------------------
    public function store(Request $request)
    {
        $request->validate([
            'role_id'      => 'required|exists:roles,id',
            'nama_lengkap' => 'required|string|max:100',
            'username'     => 'required|string|max:50|unique:users,username',
            'password'     => 'required|string|min:6|confirmed',
            'email'        => 'nullable|email|max:100|unique:users,email',
            'nomor_hp'     => 'nullable|string|max:20',
            'bagian'       => 'nullable|string|max:100',
            'jabatan'      => 'nullable|string|max:100',
            'status_aktif' => 'required|in:Aktif,Nonaktif',
        ], [
            'role_id.required'          => 'Role wajib dipilih.',
            'role_id.exists'            => 'Role tidak valid.',
            'nama_lengkap.required'     => 'Nama lengkap wajib diisi.',
            'username.required'         => 'Username wajib diisi.',
            'username.unique'           => 'Username sudah digunakan.',
            'password.required'         => 'Password wajib diisi.',
            'password.min'              => 'Password minimal 6 karakter.',
            'password.confirmed'        => 'Konfirmasi password tidak cocok.',
            'email.email'               => 'Format email tidak valid.',
            'email.unique'              => 'Email sudah digunakan.',
            'status_aktif.required'     => 'Status aktif wajib dipilih.',
        ]);

        User::create([
            'role_id'      => $request->role_id,
            'nama_lengkap' => $request->nama_lengkap,
            'username'     => strtolower(trim($request->username)),
            'password'     => Hash::make($request->password),
            'email'        => $request->email,
            'nomor_hp'     => $request->nomor_hp,
            'bagian'       => $request->bagian,
            'jabatan'      => $request->jabatan,
            'status_aktif' => $request->status_aktif,
        ]);

        return redirect()->route('user.index')
            ->with('success', 'User baru berhasil ditambahkan.');
    }

    // ----------------------------------------------------------------
    // SHOW — Detail user
    // ----------------------------------------------------------------
    public function show(int $id)
    {
        $user = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.id')
            ->select('users.*', 'roles.role_name')
            ->where('users.id', $id)
            ->firstOrFail();

        // Statistik aktivitas user
        $totalPermintaan = DB::table('permintaan')->where('user_id', $id)->count();
        $totalApproval   = DB::table('approval')->where('pimpinan_id', $id)->count();
        $totalDistribusi = DB::table('distribusi')->where('admin_id', $id)->count();

        return view('user.show', compact('user', 'totalPermintaan', 'totalApproval', 'totalDistribusi'));
    }

    // ----------------------------------------------------------------
    // EDIT — Form edit user
    // ----------------------------------------------------------------
    public function edit(int $id)
    {
        $user  = User::findOrFail($id);
        $roles = Role::orderBy('id')->get();
        return view('user.edit', compact('user', 'roles'));
    }

    // ----------------------------------------------------------------
    // UPDATE — Simpan perubahan user
    // ----------------------------------------------------------------
    public function update(Request $request, int $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'role_id'      => 'required|exists:roles,id',
            'nama_lengkap' => 'required|string|max:100',
            'username'     => 'required|string|max:50|unique:users,username,' . $id,
            'password'     => 'nullable|string|min:6|confirmed',
            'email'        => 'nullable|email|max:100|unique:users,email,' . $id,
            'nomor_hp'     => 'nullable|string|max:20',
            'bagian'       => 'nullable|string|max:100',
            'jabatan'      => 'nullable|string|max:100',
            'status_aktif' => 'required|in:Aktif,Nonaktif',
        ], [
            'role_id.required'      => 'Role wajib dipilih.',
            'nama_lengkap.required' => 'Nama lengkap wajib diisi.',
            'username.required'     => 'Username wajib diisi.',
            'username.unique'       => 'Username sudah digunakan user lain.',
            'password.min'          => 'Password minimal 6 karakter.',
            'password.confirmed'    => 'Konfirmasi password tidak cocok.',
            'email.email'           => 'Format email tidak valid.',
            'email.unique'          => 'Email sudah digunakan user lain.',
            'status_aktif.required' => 'Status aktif wajib dipilih.',
        ]);

        // Proteksi: akun admin utama (id=1) tidak boleh dinonaktifkan atau diganti role
        if ($id === 1) {
            if ($request->status_aktif === 'Nonaktif') {
                return redirect()->route('user.edit', $id)
                    ->with('error', 'Akun Administrator utama tidak dapat dinonaktifkan.');
            }
            if ($request->role_id != 1) {
                return redirect()->route('user.edit', $id)
                    ->with('error', 'Role Administrator utama tidak dapat diubah.');
            }
        }

        $data = [
            'role_id'      => $request->role_id,
            'nama_lengkap' => $request->nama_lengkap,
            'username'     => strtolower(trim($request->username)),
            'email'        => $request->email,
            'nomor_hp'     => $request->nomor_hp,
            'bagian'       => $request->bagian,
            'jabatan'      => $request->jabatan,
            'status_aktif' => $request->status_aktif,
        ];

        // Update password hanya jika diisi
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return redirect()->route('user.index')
            ->with('success', 'Data user berhasil diperbarui.');
    }

    // ----------------------------------------------------------------
    // DESTROY — Hapus user
    // ----------------------------------------------------------------
    public function destroy(int $id)
    {
        // Proteksi: akun admin utama tidak boleh dihapus
        if ($id === 1) {
            return redirect()->route('user.index')
                ->with('error', 'Akun Administrator utama tidak dapat dihapus.');
        }

        // Proteksi: cek apakah user sedang login
        if ($id === session('user_id')) {
            return redirect()->route('user.index')
                ->with('error', 'Tidak dapat menghapus akun yang sedang login.');
        }

        // Cek apakah user memiliki data terkait
        $adaPermintaan = DB::table('permintaan')->where('user_id', $id)->exists();
        $adaApproval   = DB::table('approval')->where('pimpinan_id', $id)->exists();
        $adaDistribusi = DB::table('distribusi')->where('admin_id', $id)->exists();

        if ($adaPermintaan || $adaApproval || $adaDistribusi) {
            return redirect()->route('user.index')
                ->with('error', 'User tidak dapat dihapus karena memiliki data transaksi terkait. Nonaktifkan user sebagai gantinya.');
        }

        // Hapus notifikasi user terlebih dahulu
        DB::table('notifikasi')->where('user_id', $id)->delete();

        User::findOrFail($id)->delete();

        return redirect()->route('user.index')
            ->with('success', 'User berhasil dihapus.');
    }

    // ----------------------------------------------------------------
    // TOGGLE STATUS — Aktif / Nonaktif langsung dari index
    // ----------------------------------------------------------------
    public function toggleStatus(int $id)
    {
        if ($id === 1) {
            return redirect()->route('user.index')
                ->with('error', 'Status Administrator utama tidak dapat diubah.');
        }

        $user = User::findOrFail($id);
        $user->status_aktif = $user->status_aktif === 'Aktif' ? 'Nonaktif' : 'Aktif';
        $user->save();

        $status = $user->status_aktif;
        return redirect()->route('user.index')
            ->with('success', "User {$user->nama_lengkap} berhasil di-set {$status}.");
    }
}