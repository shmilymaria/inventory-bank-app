@extends('layouts.app')

@section('title', 'Tambah User')
@section('page-title', 'Data User')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('user.index') }}" class="text-decoration-none">Data User</a>
        </li>
        <li class="breadcrumb-item active">Tambah User</li>
    </ol>
</nav>

<div class="row justify-content-center">
<div class="col-lg-9">

    <div class="card">
        <div class="card-header py-3" style="background:#1565C0;">
            <h5 class="mb-0 text-white fw-semibold">
                <i class="bi bi-person-plus me-2"></i>Tambah User Baru
            </h5>
        </div>

        <div class="card-body p-4">

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

            <form method="POST" action="{{ route('user.store') }}">
                @csrf

                {{-- ── Informasi Akun ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-shield me-1"></i>Informasi Akun
                </p>

                <div class="row g-3 mb-4">

                    <div class="col-md-6">
                        <label class="form-label">Role <span class="text-danger">*</span></label>
                        <select name="role_id" id="selectRole"
                                class="form-select @error('role_id') is-invalid @enderror">
                            <option value="">— Pilih Role —</option>
                            @foreach($roles as $role)
                                <option value="{{ $role->id }}"
                                    {{ old('role_id') == $role->id ? 'selected' : '' }}>
                                    {{ $role->role_name }}
                                </option>
                            @endforeach
                        </select>
                        @error('role_id')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Status Aktif <span class="text-danger">*</span></label>
                        <select name="status_aktif"
                                class="form-select @error('status_aktif') is-invalid @enderror">
                            <option value="Aktif"    {{ old('status_aktif', 'Aktif') == 'Aktif'    ? 'selected' : '' }}>Aktif</option>
                            <option value="Nonaktif" {{ old('status_aktif') == 'Nonaktif' ? 'selected' : '' }}>Nonaktif</option>
                        </select>
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
                                   placeholder="contoh: budi.santoso"
                                   value="{{ old('username') }}"
                                   style="text-transform:lowercase;">
                        </div>
                        @error('username')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                        <div class="form-text">Username harus unik, huruf kecil, tanpa spasi.</div>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Email</label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                            <input type="email" name="email"
                                   class="form-control @error('email') is-invalid @enderror"
                                   placeholder="contoh: budi@bankxyz.com"
                                   value="{{ old('email') }}">
                        </div>
                        @error('email')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Password <span class="text-danger">*</span></label>
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
                        <label class="form-label">Konfirmasi Password <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <input type="password" name="password_confirmation" id="inputPasswordConfirm"
                                   class="form-control"
                                   placeholder="Ulangi password">
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
                               placeholder="Masukkan nama lengkap..."
                               value="{{ old('nama_lengkap') }}">
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
                                   placeholder="contoh: 08123456789"
                                   value="{{ old('nomor_hp') }}">
                        </div>
                        @error('nomor_hp')
                            <div class="invalid-feedback d-block">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Bagian / Divisi</label>
                        <input type="text" name="bagian"
                               class="form-control @error('bagian') is-invalid @enderror"
                               placeholder="contoh: Bagian Kredit"
                               value="{{ old('bagian') }}">
                        @error('bagian')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Jabatan</label>
                        <input type="text" name="jabatan"
                               class="form-control @error('jabatan') is-invalid @enderror"
                               placeholder="contoh: Staff Administrasi"
                               value="{{ old('jabatan') }}">
                        @error('jabatan')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                {{-- ── Tombol ── --}}
                <div class="d-flex gap-2 mt-4 pt-3 border-top">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-save me-1"></i> Simpan User
                    </button>
                    <a href="{{ route('user.index') }}" class="btn btn-outline-secondary px-4">
                        Batal
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
    // Toggle show/hide password
    function togglePass(inputId, iconId) {
        const input = document.getElementById(inputId);
        const icon  = document.getElementById(iconId);
        if (input.type === 'password') {
            input.type = 'text';
            icon.className = 'bi bi-eye-slash';
        } else {
            input.type = 'password';
            icon.className = 'bi bi-eye';
        }
    }

    document.getElementById('togglePassword').addEventListener('click', function () {
        togglePass('inputPassword', 'iconPassword');
    });

    document.getElementById('togglePasswordConfirm').addEventListener('click', function () {
        togglePass('inputPasswordConfirm', 'iconPasswordConfirm');
    });

    // Auto lowercase username
    document.querySelector('[name="username"]').addEventListener('input', function () {
        this.value = this.value.toLowerCase().replace(/\s/g, '');
    });
</script>
@endpush