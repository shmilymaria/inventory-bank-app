@extends('layouts.app')

@section('title', 'Data User')
@section('page-title', 'Data User')

@section('content')

{{-- ── Header ── --}}
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Data User</h4>
        <small class="text-muted">Kelola seluruh akun pengguna sistem</small>
    </div>
    <a href="{{ route('user.create') }}" class="btn btn-primary">
        <i class="bi bi-person-plus me-1"></i> Tambah User
    </a>
</div>

{{-- ── Statistik Ringkas ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-people fs-4" style="color:#1565C0;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total User</div>
                    <div class="fw-bold fs-4">{{ $users->total() }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-person-check fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">User Aktif</div>
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('users')->where('status_aktif','Aktif')->count() }}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fee2e2;">
                    <i class="bi bi-person-x fs-4" style="color:#991b1b;"></i>
                </div>
                <div>
                    <div class="text-muted small">User Nonaktif</div>
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('users')->where('status_aktif','Nonaktif')->count() }}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#f3e8ff;">
                    <i class="bi bi-shield-check fs-4" style="color:#6b21a8;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Role</div>
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('roles')->count() }}
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ── Filter & Search ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('user.index') }}" class="row g-2 align-items-end">

            <div class="col-md-4">
                <label class="form-label small text-muted mb-1">Cari User</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                    <input type="text" name="search" class="form-control"
                           placeholder="Nama, username, atau bagian..."
                           value="{{ request('search') }}">
                </div>
            </div>

            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Role</label>
                <select name="role" class="form-select">
                    <option value="">Semua Role</option>
                    @foreach($roles as $role)
                        <option value="{{ $role->id }}"
                            {{ request('role') == $role->id ? 'selected' : '' }}>
                            {{ $role->role_name }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Status</label>
                <select name="status" class="form-select">
                    <option value="">Semua Status</option>
                    <option value="Aktif"    {{ request('status') == 'Aktif'    ? 'selected' : '' }}>Aktif</option>
                    <option value="Nonaktif" {{ request('status') == 'Nonaktif' ? 'selected' : '' }}>Nonaktif</option>
                </select>
            </div>

            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('user.index') }}" class="btn btn-outline-secondary flex-fill">
                    Reset
                </a>
            </div>

        </form>
    </div>
</div>

{{-- ── Tabel ── --}}
<div class="card">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4" style="width:50px;">No</th>
                        <th>Nama Lengkap</th>
                        <th>Username</th>
                        <th>Role</th>
                        <th>Bagian / Jabatan</th>
                        <th>Email</th>
                        <th class="text-center">Status</th>
                        <th class="text-center pe-4">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($users as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($users->currentPage() - 1) * $users->perPage() + $loop->iteration }}
                            </td>

                            {{-- Nama + Avatar --}}
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <div class="rounded-circle d-flex align-items-center justify-content-center fw-bold"
                                         style="width:36px;height:36px;font-size:0.85rem;flex-shrink:0;
                                                background:{{ $item->role_id == 1 ? '#dbeafe' : ($item->role_id == 3 ? '#f3e8ff' : '#d1fae5') }};
                                                color:{{ $item->role_id == 1 ? '#1565C0' : ($item->role_id == 3 ? '#6b21a8' : '#065f46') }};">
                                        {{ strtoupper(substr($item->nama_lengkap, 0, 1)) }}
                                    </div>
                                    <div>
                                        <div class="fw-semibold">{{ $item->nama_lengkap }}</div>
                                        @if($item->id == 1)
                                            <small class="text-muted"><i class="bi bi-shield-fill-check text-primary" style="font-size:0.7rem;"></i> Akun Utama</small>
                                        @endif
                                    </div>
                                </div>
                            </td>

                            <td><code class="text-secondary">{{ $item->username }}</code></td>

                            {{-- Badge Role --}}
                            <td>
                                @if($item->role_id == 1)
                                    <span class="badge px-3 py-2 rounded-pill"
                                          style="background:#dbeafe;color:#1565C0;">
                                        <i class="bi bi-shield me-1"></i>{{ $item->role_name }}
                                    </span>
                                @elseif($item->role_id == 3)
                                    <span class="badge px-3 py-2 rounded-pill"
                                          style="background:#f3e8ff;color:#6b21a8;">
                                        <i class="bi bi-star me-1"></i>{{ $item->role_name }}
                                    </span>
                                @else
                                    <span class="badge px-3 py-2 rounded-pill"
                                          style="background:#d1fae5;color:#065f46;">
                                        <i class="bi bi-person me-1"></i>{{ $item->role_name }}
                                    </span>
                                @endif
                            </td>

                            <td>
                                <div class="small">{{ $item->bagian ?? '—' }}</div>
                                <div class="text-muted" style="font-size:0.78rem;">{{ $item->jabatan ?? '' }}</div>
                            </td>

                            <td class="text-muted small">{{ $item->email ?? '—' }}</td>

                            {{-- Toggle Status --}}
                            <td class="text-center">
                                <form method="POST"
                                      action="{{ route('user.toggleStatus', $item->id) }}"
                                      class="d-inline">
                                    @csrf
                                    @method('PATCH')
                                    <button type="submit"
                                            class="badge border-0 px-3 py-2 rounded-pill {{ $item->status_aktif == 'Aktif' ? 'bg-success' : 'bg-secondary' }}"
                                            style="cursor:pointer;font-size:0.8rem;"
                                            {{ $item->id == 1 ? 'disabled' : '' }}
                                            title="{{ $item->id == 1 ? 'Akun utama tidak dapat diubah' : 'Klik untuk toggle status' }}">
                                        <i class="bi bi-circle-fill me-1" style="font-size:0.45rem;"></i>
                                        {{ $item->status_aktif }}
                                    </button>
                                </form>
                            </td>

                            {{-- Aksi --}}
                            <td class="text-center pe-4">
                                <div class="d-flex justify-content-center gap-1">
                                    <a href="{{ route('user.show', $item->id) }}"
                                       class="btn btn-sm btn-outline-info" title="Detail">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="{{ route('user.edit', $item->id) }}"
                                       class="btn btn-sm btn-outline-primary" title="Edit">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    @if($item->id != 1)
                                        <button type="button"
                                                class="btn btn-sm btn-outline-danger"
                                                title="Hapus"
                                                data-bs-toggle="modal"
                                                data-bs-target="#modalHapus"
                                                data-id="{{ $item->id }}"
                                                data-nama="{{ $item->nama_lengkap }}">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    @else
                                        <button class="btn btn-sm btn-outline-danger" disabled title="Akun utama tidak dapat dihapus">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="text-center py-5 text-muted">
                                <i class="bi bi-people fs-1 d-block mb-2"></i>
                                Tidak ada data user ditemukan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        @if($users->hasPages())
            <div class="px-4 py-3 border-top">
                {{ $users->links() }}
            </div>
        @endif

    </div>
</div>

{{-- ── Modal Konfirmasi Hapus ── --}}
<div class="modal fade" id="modalHapus" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">Konfirmasi Hapus User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-4 text-center">
                <div class="mb-3">
                    <div class="rounded-circle d-inline-flex align-items-center justify-content-center"
                         style="width:64px;height:64px;background:#fee2e2;">
                        <i class="bi bi-person-x fs-3" style="color:#dc3545;"></i>
                    </div>
                </div>
                <p class="mb-1">Anda yakin ingin menghapus user:</p>
                <p class="fw-bold fs-5" id="namaUserHapus">—</p>
                <p class="text-muted small">
                    User yang memiliki data transaksi tidak dapat dihapus.<br>
                    Sebagai gantinya, nonaktifkan user tersebut.
                </p>
            </div>
            <div class="modal-footer border-0 pt-0 justify-content-center gap-2">
                <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
                    Batal
                </button>
                <form id="formHapus" method="POST">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-danger px-4">
                        <i class="bi bi-trash me-1"></i> Ya, Hapus
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

@endsection

@push('scripts')
<script>
    document.getElementById('modalHapus').addEventListener('show.bs.modal', function (event) {
        const btn  = event.relatedTarget;
        const id   = btn.getAttribute('data-id');
        const nama = btn.getAttribute('data-nama');
        document.getElementById('namaUserHapus').textContent = nama;
        document.getElementById('formHapus').action = '/user/' + id;
    });
</script>
@endpush