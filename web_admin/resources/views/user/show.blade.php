@extends('layouts.app')

@section('title', 'Detail User')
@section('page-title', 'Data User')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('user.index') }}" class="text-decoration-none">Data User</a>
        </li>
        <li class="breadcrumb-item active">Detail User</li>
    </ol>
</nav>

<div class="row g-4">

    {{-- ── Kolom Kiri: Profil User ── --}}
    <div class="col-lg-5">
        <div class="card">

            <div class="card-header py-3 d-flex justify-content-between align-items-center"
                 style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-person-badge me-2"></i>Profil User
                </h5>
                <a href="{{ route('user.edit', $user->id) }}"
                   class="btn btn-sm btn-light">
                    <i class="bi bi-pencil me-1"></i>Edit
                </a>
            </div>

            <div class="card-body p-4 text-center">

                {{-- Avatar besar --}}
                <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold mb-3"
                     style="width:90px;height:90px;font-size:2.2rem;
                            background:{{ $user->role_id == 1 ? '#dbeafe' : ($user->role_id == 3 ? '#f3e8ff' : '#d1fae5') }};
                            color:{{ $user->role_id == 1 ? '#1565C0' : ($user->role_id == 3 ? '#6b21a8' : '#065f46') }};">
                    {{ strtoupper(substr($user->nama_lengkap, 0, 1)) }}
                </div>

                <h5 class="fw-bold mb-1">{{ $user->nama_lengkap }}</h5>
                <code class="text-muted">@{{ $user->username }}</code>

                <div class="mt-2 mb-3">
                    {{-- Badge Role --}}
                    @if($user->role_id == 1)
                        <span class="badge px-3 py-2 rounded-pill me-1"
                              style="background:#dbeafe;color:#1565C0;">
                            <i class="bi bi-shield me-1"></i>{{ $user->role_name }}
                        </span>
                    @elseif($user->role_id == 3)
                        <span class="badge px-3 py-2 rounded-pill me-1"
                              style="background:#f3e8ff;color:#6b21a8;">
                            <i class="bi bi-star me-1"></i>{{ $user->role_name }}
                        </span>
                    @else
                        <span class="badge px-3 py-2 rounded-pill me-1"
                              style="background:#d1fae5;color:#065f46;">
                            <i class="bi bi-person me-1"></i>{{ $user->role_name }}
                        </span>
                    @endif

                    {{-- Badge Status --}}
                    <span class="badge px-3 py-2 rounded-pill
                          {{ $user->status_aktif == 'Aktif' ? 'bg-success' : 'bg-secondary' }}">
                        <i class="bi bi-circle-fill me-1" style="font-size:0.45rem;"></i>
                        {{ $user->status_aktif }}
                    </span>
                </div>

                @if($user->id == 1)
                    <div class="alert py-2 mb-0" style="background:#fef3c7;border:1px solid #fde68a;">
                        <small style="color:#92400e;">
                            <i class="bi bi-shield-fill-check me-1"></i>
                            Akun Administrator Utama Sistem
                        </small>
                    </div>
                @endif

            </div>

            <div class="card-body border-top pt-3">
                <table class="table table-borderless table-sm mb-0">
                    <tr>
                        <td class="text-muted" style="width:45%;">
                            <i class="bi bi-building me-1"></i>Bagian
                        </td>
                        <td class="fw-semibold">{{ $user->bagian ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">
                            <i class="bi bi-briefcase me-1"></i>Jabatan
                        </td>
                        <td class="fw-semibold">{{ $user->jabatan ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">
                            <i class="bi bi-envelope me-1"></i>Email
                        </td>
                        <td>{{ $user->email ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">
                            <i class="bi bi-telephone me-1"></i>No. HP
                        </td>
                        <td>{{ $user->nomor_hp ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">
                            <i class="bi bi-calendar me-1"></i>Dibuat
                        </td>
                        <td class="small">
                            {{ \Carbon\Carbon::parse($user->created_at)->format('d M Y, H:i') }}
                        </td>
                    </tr>
                    <tr>
                        <td class="text-muted">
                            <i class="bi bi-clock me-1"></i>Diperbarui
                        </td>
                        <td class="small">
                            {{ \Carbon\Carbon::parse($user->updated_at)->format('d M Y, H:i') }}
                        </td>
                    </tr>
                </table>
            </div>

            <div class="card-footer bg-white border-top pt-3 pb-3">
                <a href="{{ route('user.index') }}" class="btn btn-outline-secondary w-100">
                    <i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar
                </a>
            </div>

        </div>
    </div>

    {{-- ── Kolom Kanan: Statistik Aktivitas ── --}}
    <div class="col-lg-7">

        {{-- Statistik --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-bar-chart me-2"></i>Statistik Aktivitas
                </h5>
            </div>
            <div class="card-body">
                <div class="row g-3">

                    {{-- Permintaan (untuk role Staff) --}}
                    <div class="col-md-4">
                        <div class="p-3 rounded-3 text-center" style="background:#f0f4ff;">
                            <i class="bi bi-file-earmark-text fs-2 mb-2" style="color:#1565C0;"></i>
                            <div class="fw-bold fs-3" style="color:#1565C0;">
                                {{ $totalPermintaan }}
                            </div>
                            <div class="text-muted small">Total Permintaan</div>
                            <div class="text-muted" style="font-size:0.72rem;">
                                (sebagai Staff)
                            </div>
                        </div>
                    </div>

                    {{-- Approval (untuk role Pimpinan) --}}
                    <div class="col-md-4">
                        <div class="p-3 rounded-3 text-center" style="background:#f3e8ff;">
                            <i class="bi bi-check2-all fs-2 mb-2" style="color:#6b21a8;"></i>
                            <div class="fw-bold fs-3" style="color:#6b21a8;">
                                {{ $totalApproval }}
                            </div>
                            <div class="text-muted small">Total Approval</div>
                            <div class="text-muted" style="font-size:0.72rem;">
                                (sebagai Pimpinan)
                            </div>
                        </div>
                    </div>

                    {{-- Distribusi (untuk role Admin) --}}
                    <div class="col-md-4">
                        <div class="p-3 rounded-3 text-center" style="background:#d1fae5;">
                            <i class="bi bi-truck fs-2 mb-2" style="color:#065f46;"></i>
                            <div class="fw-bold fs-3" style="color:#065f46;">
                                {{ $totalDistribusi }}
                            </div>
                            <div class="text-muted small">Total Distribusi</div>
                            <div class="text-muted" style="font-size:0.72rem;">
                                (sebagai Admin)
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>

        {{-- Info Platform Akses --}}
        <div class="card">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-display me-2"></i>Platform Akses
                </h5>
            </div>
            <div class="card-body">

                @if($user->role_id == 1)
                    <div class="d-flex align-items-center gap-3 p-3 rounded-3 mb-2"
                         style="background:#f0f4ff;">
                        <i class="bi bi-globe fs-3" style="color:#1565C0;"></i>
                        <div>
                            <div class="fw-semibold">Web Admin (Laravel)</div>
                            <div class="text-muted small">
                                Akses penuh ke seluruh fitur manajemen inventori
                            </div>
                        </div>
                    </div>
                @elseif($user->role_id == 3)
                    <div class="d-flex align-items-center gap-3 p-3 rounded-3 mb-2"
                         style="background:#f3e8ff;">
                        <i class="bi bi-phone fs-3" style="color:#6b21a8;"></i>
                        <div>
                            <div class="fw-semibold">Mobile App — Pimpinan (Flutter)</div>
                            <div class="text-muted small">
                                Approval permintaan, riwayat approval, notifikasi
                            </div>
                        </div>
                    </div>
                @else
                    <div class="d-flex align-items-center gap-3 p-3 rounded-3 mb-2"
                         style="background:#d1fae5;">
                        <i class="bi bi-phone fs-3" style="color:#065f46;"></i>
                        <div>
                            <div class="fw-semibold">Mobile App — Staff (Flutter)</div>
                            <div class="text-muted small">
                                Ajukan permintaan barang, riwayat permintaan, notifikasi
                            </div>
                        </div>
                    </div>
                @endif

                <div class="mt-3 p-3 rounded-3" style="background:#f8f9fa;">
                    <small class="text-muted">
                        <i class="bi bi-info-circle me-1"></i>
                        Akses platform ditentukan berdasarkan role yang ditetapkan pada akun ini.
                        Perubahan role hanya dapat dilakukan oleh Administrator.
                    </small>
                </div>

            </div>
        </div>

    </div>

</div>

@endsection