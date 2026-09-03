@extends('layouts.app')

@section('title', 'Tambah Barang')
@section('page-title', 'Data Barang')

@section('content')

{{-- ── Breadcrumb ── --}}
<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('barang.index') }}" class="text-decoration-none">Data Barang</a>
        </li>
        <li class="breadcrumb-item active">Tambah Barang</li>
    </ol>
</nav>

<div class="row justify-content-center">
<div class="col-lg-9">

    <div class="card">
        <div class="card-header py-3" style="background:#1565C0;">
            <h5 class="mb-0 text-white fw-semibold">
                <i class="bi bi-plus-circle me-2"></i>Tambah Barang Baru
            </h5>
        </div>

        <div class="card-body p-4">

            {{-- Validasi error --}}
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

            <form method="POST" action="{{ route('barang.store') }}">
                @csrf

                {{-- ── Informasi Dasar ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-info-circle me-1"></i>Informasi Dasar
                </p>

                <div class="row g-3 mb-4">

                    <div class="col-md-6">
                        <label class="form-label">Kategori <span class="text-danger">*</span></label>
                        <select name="kategori_id"
                                class="form-select @error('kategori_id') is-invalid @enderror">
                            <option value="">— Pilih Kategori —</option>
                            @foreach($kategoris as $kat)
                                <option value="{{ $kat->id }}"
                                    {{ old('kategori_id') == $kat->id ? 'selected' : '' }}>
                                    {{ $kat->nama_kategori }}
                                </option>
                            @endforeach
                        </select>
                        @error('kategori_id')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Kode Barang <span class="text-danger">*</span></label>
                        <input type="text" name="kode_barang"
                               class="form-control @error('kode_barang') is-invalid @enderror"
                               placeholder="Contoh: ATK-001"
                               value="{{ old('kode_barang') }}"
                               style="text-transform:uppercase;">
                        @error('kode_barang')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <div class="form-text">Kode unik untuk setiap barang.</div>
                    </div>

                    <div class="col-12">
                        <label class="form-label">Nama Barang <span class="text-danger">*</span></label>
                        <input type="text" name="nama_barang"
                               class="form-control @error('nama_barang') is-invalid @enderror"
                               placeholder="Masukkan nama barang..."
                               value="{{ old('nama_barang') }}">
                        @error('nama_barang')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                <hr class="my-4">

                {{-- ── Stok & Satuan ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-layers me-1"></i>Stok & Satuan
                </p>

                <div class="row g-3 mb-4">

                    <div class="col-md-4">
                        <label class="form-label">Stok Awal <span class="text-danger">*</span></label>
                        <input type="number" name="stok"
                               class="form-control @error('stok') is-invalid @enderror"
                               placeholder="0" min="0"
                               value="{{ old('stok', 0) }}"
                               id="inputStok">
                        @error('stok')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Stok Minimum <span class="text-danger">*</span></label>
                        <input type="number" name="stok_minimum"
                               class="form-control @error('stok_minimum') is-invalid @enderror"
                               placeholder="5" min="0"
                               value="{{ old('stok_minimum', 5) }}"
                               id="inputStokMin">
                        @error('stok_minimum')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <div class="form-text">Batas minimum sebelum status menjadi "Stok Menipis".</div>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Satuan <span class="text-danger">*</span></label>
                        <select name="satuan"
                                class="form-select @error('satuan') is-invalid @enderror">
                            <option value="">— Pilih Satuan —</option>
                            @foreach(['Unit','Buah','Rim','Kotak','Lusin','Set','Pak','Lembar','Botol','Liter'] as $sat)
                                <option value="{{ $sat }}"
                                    {{ old('satuan') == $sat ? 'selected' : '' }}>
                                    {{ $sat }}
                                </option>
                            @endforeach
                        </select>
                        @error('satuan')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                {{-- Preview status otomatis --}}
                <div class="alert py-2 mb-4" id="previewStatus" role="alert">
                    <small>
                        <i class="bi bi-info-circle me-1"></i>
                        Status barang akan otomatis dihitung saat disimpan.
                    </small>
                </div>

                <hr class="my-4">

                {{-- ── Lokasi & Deskripsi ── --}}
                <p class="fw-semibold text-muted small text-uppercase mb-3">
                    <i class="bi bi-geo-alt me-1"></i>Lokasi & Deskripsi
                </p>

                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">Lokasi Penyimpanan</label>
                        <input type="text" name="lokasi_penyimpanan"
                               class="form-control @error('lokasi_penyimpanan') is-invalid @enderror"
                               placeholder="Contoh: Gudang A - Rak 3"
                               value="{{ old('lokasi_penyimpanan') }}">
                        @error('lokasi_penyimpanan')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-12">
                        <label class="form-label">Deskripsi</label>
                        <textarea name="deskripsi" rows="3"
                                  class="form-control @error('deskripsi') is-invalid @enderror"
                                  placeholder="Deskripsi singkat mengenai barang...">{{ old('deskripsi') }}</textarea>
                        @error('deskripsi')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                </div>

                {{-- ── Tombol ── --}}
                <div class="d-flex gap-2 mt-4 pt-3 border-top">
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-save me-1"></i> Simpan Barang
                    </button>
                    <a href="{{ route('barang.index') }}" class="btn btn-outline-secondary px-4">
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
    // Preview status otomatis berdasarkan stok & stok minimum
    function updatePreviewStatus() {
        const stok    = parseInt(document.getElementById('inputStok').value)    || 0;
        const stokMin = parseInt(document.getElementById('inputStokMin').value) || 0;
        const el      = document.getElementById('previewStatus');
        let label, cls;

        if (stok <= 0) {
            label = '❌ Status akan menjadi <strong>Habis</strong>';
            cls   = 'alert-danger';
        } else if (stok <= stokMin) {
            label = '⚠️ Status akan menjadi <strong>Stok Menipis</strong>';
            cls   = 'alert-warning';
        } else {
            label = '✅ Status akan menjadi <strong>Tersedia</strong>';
            cls   = 'alert-success';
        }

        el.className = 'alert py-2 mb-4 ' + cls;
        el.innerHTML = '<small><i class="bi bi-info-circle me-1"></i>' + label + '</small>';
    }

    document.getElementById('inputStok').addEventListener('input', updatePreviewStatus);
    document.getElementById('inputStokMin').addEventListener('input', updatePreviewStatus);
    updatePreviewStatus();

    // Auto uppercase kode barang
    document.querySelector('[name="kode_barang"]').addEventListener('input', function () {
        this.value = this.value.toUpperCase();
    });
</script>
@endpush