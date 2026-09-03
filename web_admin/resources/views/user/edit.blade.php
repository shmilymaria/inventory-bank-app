@extends('layouts.app')

@section('title', 'Edit User')
@section('page-title', 'Data User')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('user.index') }}" class="text-decoration-none">Data User</a>
        </li>
        <li class="breadcrumb-item active">Edit User</li>
    </ol>
</nav>

<div class="row justify-content-center">
<div class="col-lg-9">

    <div class="card">
        <div class="card-header py-3" style="background:#1565C0;">
            <h5 class="mb-0 text-white fw-semibold">
                <i class="bi bi-pencil-square me-2"></i>Edit Data User
            </h5>
        </div>

        <div class="card-body p-4">

            {{-- Info user yang diedit --}}
            <div class="alert py-2 mb-4" style="background:#f0f4ff;border:1px solid #c7d7fc;">
                <small class="text-primary">
                    <i class="bi bi-pencil me-1"></i>
                    Mengedit: <strong>{{ $user->nama_lengkap }}</strong>
                    — Username: <code>{{ $user->username }}</code>
                    @if($user->id == 1)
                        &nbsp;<span class="badge" style="background:#dbeafe;color:#1565C0;">
                            <i class="bi bi-shield-fill-check me-1"></i>Akun Utama
                        </span>
                    @endif
                </small>
            </div>

            @if($errors->any())
                <div class="alert alert-danger alert-dismissible fade show">
                    <i class="bi bi-exclamation-circle me-2"></i>
                    <strong>Terdapat kesalahan pada input:</strong>
                    <ul class="mb-0 mt-1">
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            @endif

            <form method="POST" action="{{ route('user.update', $user->id) }}">
                @csrf
                @method('PUT')

                {{-- ── Informasi Akun ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-shield me-1"></i>Informasi Akun
                </p>

                <div class="row g-3 mb-4">

                    <div class="col-md-6">
                        <label class="form-label">Role <span class="text-danger">*</span></label>
                        <select name="role_id"
                                class="form-select @error('role_id') is-invalid @enderror"
                                {{ $user->id == 1 ? 'disabled' : '' }}>
                            @foreach($roles as $role)
                                <option value="{{ $role->id }}"
                                    {{ old('role_id', $user->role_id) == $role->id ? 'selected' : '' }}>
                                    {{ $role->role_name }}
                                </option>
                            @endforeach
                        </select>
                        {{-- Jika disabled, tetap kirim value --}}
                        @if($user->id == 1)
                            <input type="hidden" name="role_id" value="{{ $user->role_id }}">
                        @endif
                        @error('role_id')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        @if($user->id == 1)
                            <div class="form-text text-warning">
                                <i class="bi bi-lock me-1"></i>Role akun utama tidak dapat diubah.
                            </div>
                        @endif
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Status Aktif <span class="text-danger">*</span></label>
                        <select name="status_aktif"
                                class="form-select @error('status_aktif') is-invalid @enderror"
                                {{ $user->id == 1 ? 'disabled' : '' }}>
                            <option value="Aktif"    {{ old('status_aktif', $user->status_aktif) == 'Aktif'    ? 'selected' : '' }}>Aktif</option>
                            <option value="Nonaktif" {{ old('status_aktif', $user->status_aktif) == 'Nonaktif' ? 'selected' : '' }}>Nonaktif</option>
                        </select>
                        @if($user->id == 1)
                            <input type="hidden" name="status_aktif" value="{{ $user->status_aktif }}">
                        @endif
                        @error('status_aktif')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Username <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-at"></i></span>
                            <input type="text" name="username"
                                   class="form-control @error('username') is-invalid @enderror"
                                   value="{{ old('username', $user->username) }}"
                                   style="text-transform:lowercase;">
                        </div>
                        @error('username')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Email</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                            <input type="email" name="email"
                                   class="form-control @error('email') is-invalid @enderror"
                                   value="{{ old('email', $user->email) }}">
                        </div>
                        @error('email')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                <hr class="my-4">

                {{-- ── Ganti Password (Opsional) ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-1">
                    <i class="bi bi-key me-1"></i>Ganti Password
                    <span class="text-muted fw-normal normal-case ms-1">(kosongkan jika tidak ingin mengubah)</span>
                </p>

                <div class="row g-3 mb-4">

                    <div class="col-md-6">
                        <label class="form-label">Password Baru</label>
                        <div class="input-group">
                            <input type="password" name="password" id="inputPassword"
                                   class="form-control @error('password') is-invalid @enderror"
                                   placeholder="Minimal 6 karakter">
                            <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                                <i class="bi bi-eye" id="iconPassword"></i>
                            </button>
                        </div>
                        @error('password')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Konfirmasi Password Baru</label>
                        <div class="input-group">
                            <input type="password" name="password_confirmation" id="inputPasswordConfirm"
                                   class="form-control"
                                   placeholder="Ulangi password baru">
                            <button class="btn btn-outline-secondary" type="button" id="togglePasswordConfirm">
                                <i class="bi bi-eye" id="iconPasswordConfirm"></i>
                            </button>
                        </div>
                    </div>

                </div>

                <hr class="my-4">

                {{-- ── Informasi Personal ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-person me-1"></i>Informasi Personal
                </p>

                <div class="row g-3">

                    <div class="col-12">
                        <label class="form-label">Nama Lengkap <span class="text-danger">*</span></label>
                        <input type="text" name="nama_lengkap"
                               class="form-control @error('nama_lengkap') is-invalid @enderror"
                               value="{{ old('nama_lengkap', $user->nama_lengkap) }}">
                        @error('nama_lengkap')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Nomor HP</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-telephone"></i></span>
                            <input type="text" name="nomor_hp"
                                   class="form-control @error('nomor_hp') is-invalid @enderror"
                                   value="{{ old('nomor_hp', $user->nomor_hp) }}">
                        </div>
                        @error('nomor_hp')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Bagian / Divisi</label>
                        <input type="text" name="bagian"
                               class="form-control @error('bagian') is-invalid @enderror"
                               value="{{ old('bagian', $user->bagian) }}">
                        @error('bagian')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Jabatan</label>
                        <input type="text" name="jabatan"
                               class="form-control @error('jabatan') is-invalid @enderror"
                               value="{{ old('jabatan', $user->jabatan) }}">
                        @error('jabatan')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                {{-- ── Tombol ── --}}
                <div class="d-flex gap-2 mt-4 pt-3 border-top">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-save me-1"></i> Simpan Perubahan
                    </button>
                    <a href="{{ route('user.index') }}" class="btn btn-outline-secondary px-4">
                        Batal
                    </a>
                    <a href="{{ route('user.show', $user->id) }}" class="btn btn-outline-info px-4 ms-auto">
                        <i class="bi bi-eye me-1"></i> Lihat Detail
                    </a>
                </div>

            </form>

        </div>
    </div>

</div>
</div>

@endsection

@push('scripts')
<script>
    function togglePass(inputId, iconId) {
        const input = document.getElementById(inputId);
        const icon  = document.getElementById(iconId);
        input.type  = input.type === 'password' ? 'text' : 'password';
        icon.className = input.type === 'password' ? 'bi bi-eye' : 'bi bi-eye-slash';
    }

    document.getElementById('togglePassword').addEventListener('click', function () {
        togglePass('inputPassword', 'iconPassword');
    });

    document.getElementById('togglePasswordConfirm').addEventListener('click', function () {
        togglePass('inputPasswordConfirm', 'iconPasswordConfirm');
    });

    document.querySelector('[name="username"]').addEventListener('input', function () {
        this.value = this.value.toLowerCase().replace(/\s/g, '');
    });
</script>
@endpush