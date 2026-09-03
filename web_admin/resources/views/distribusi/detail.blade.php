@extends('layouts.app')

@section('title', 'Detail Distribusi')
@section('page-title', 'Distribusi Barang')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('distribusi.index') }}" class="text-decoration-none">Distribusi Barang</a>
        </li>
        <li class="breadcrumb-item active">Detail Distribusi</li>
    </ol>
</nav>

{{-- ── Banner Status ── --}}
<div class="alert py-3 mb-4 d-flex align-items-center gap-3"
     style="background:{{ $distribusi->status_distribusi == 'Selesai' ? '#d1fae5' : '#dbeafe' }};
            border:1px solid {{ $distribusi->status_distribusi == 'Selesai' ? '#6ee7b7' : '#93c5fd' }};">
    <div class="rounded-circle d-flex align-items-center justify-content-center"
         style="width:46px;height:46px;flex-shrink:0;
                background:{{ $distribusi->status_distribusi == 'Selesai' ? '#fff' : '#fff' }};">
        <i class="bi {{ $distribusi->status_distribusi == 'Selesai' ? 'bi-check2-all' : 'bi-truck' }} fs-4"
           style="color:{{ $distribusi->status_distribusi == 'Selesai' ? '#065f46' : '#1e40af' }};"></i>
    </div>
    <div>
        <div class="fw-bold"
             style="color:{{ $distribusi->status_distribusi == 'Selesai' ? '#065f46' : '#1e40af' }};">
            Distribusi {{ $distribusi->status_distribusi }}
        </div>
        <div class="small"
             style="color:{{ $distribusi->status_distribusi == 'Selesai' ? '#065f46' : '#1e40af' }};">
            Diproses pada {{ \Carbon\Carbon::parse($distribusi->tanggal_distribusi)->format('d M Y, H:i') }}
            oleh <strong>{{ $distribusi->nama_admin }}</strong>
        </div>
    </div>
</div>

<div class="row g-4">

    {{-- ── Kolom Kiri: Rekap Distribusi ── --}}
    <div class="col-lg-8">

        {{-- Header Surat / Rekap --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-receipt me-2"></i>Rekap Distribusi
                </h5>
            </div>
            <div class="card-body p-4">
                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">No. Permintaan</div>
                        <code class="fs-5 text-primary">{{ $distribusi->nomor_permintaan }}</code>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Tanggal Distribusi</div>
                        <div class="fw-semibold">
                            {{ \Carbon\Carbon::parse($distribusi->tanggal_distribusi)->format('d M Y, H:i') }}
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Pemohon</div>
                        <div class="fw-semibold">{{ $distribusi->nama_pemohon }}</div>
                        <div class="text-muted small">
                            {{ $distribusi->bagian ?? '—' }} — {{ $distribusi->jabatan ?? '—' }}
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Admin yang Memproses</div>
                        <div class="fw-semibold">{{ $distribusi->nama_admin }}</div>
                    </div>
                    @if($distribusi->catatan_distribusi)
                        <div class="col-12">
                            <div class="text-muted small mb-1">Catatan Distribusi</div>
                            <div class="p-2 rounded-3" style="background:#f8f9fa;">
                                {{ $distribusi->catatan_distribusi }}
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        {{-- Tabel Barang Didistribusikan --}}
        <div class="card">
            <div class="card-header py-3 d-flex justify-content-between align-items-center"
                 style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-box-seam me-2"></i>Barang yang Didistribusikan
                </h5>
                <span class="badge bg-white text-primary">{{ $detailItems->count() }} item</span>
            </div>
            <div class="card-body p-0">
                <table class="table align-middle mb-0">
                    <thead style="background:#f8faff;">
                        <tr>
                            <th class="ps-4" style="width:40px;">No</th>
                            <th>Barang</th>
                            <th class="text-center">Jumlah</th>
                            <th class="text-center">Stok Sekarang</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($detailItems as $item)
                            <tr>
                                <td class="ps-4 text-muted">{{ $loop->iteration }}</td>
                                <td>
                                    <div class="fw-semibold">{{ $item->nama_barang }}</div>
                                    <div class="text-muted small">
                                        <code>{{ $item->kode_barang }}</code>
                                        &bull; {{ $item->nama_kategori }}
                                    </div>
                                    @if($item->keterangan)
                                        <div class="text-muted small fst-italic">
                                            {{ $item->keterangan }}
                                        </div>
                                    @endif
                                </td>
                                <td class="text-center">
                                    <span class="fw-bold text-primary">
                                        {{ number_format($item->jumlah) }}
                                    </span>
                                    <div class="text-muted small">{{ $item->satuan }}</div>
                                </td>
                                <td class="text-center">
                                    <span class="fw-semibold
                                        {{ $item->stok_sekarang <= 0 ? 'text-danger' : 'text-success' }}">
                                        {{ number_format($item->stok_sekarang) }}
                                    </span>
                                    <div class="text-muted small">{{ $item->satuan }}</div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    {{-- ── Kolom Kanan: Info Approval + Tombol ── --}}
    <div class="col-lg-4">

        {{-- Info Approval --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-check2-all me-2"></i>Hasil Approval
                </h5>
            </div>
            <div class="card-body p-4">
                @if($approval)
                    <div class="d-flex align-items-center gap-2 mb-3">
                        <div class="rounded-circle d-flex align-items-center justify-content-center"
                             style="width:38px;height:38px;background:#d1fae5;flex-shrink:0;">
                            <i class="bi bi-check-circle-fill text-success fs-5"></i>
                        </div>
                        <div>
                            <div class="fw-bold text-success">Approved</div>
                            <div class="text-muted small">
                                {{ \Carbon\Carbon::parse($approval->tanggal_approval)->format('d M Y, H:i') }}
                            </div>
                        </div>
                    </div>
                    <table class="table table-borderless table-sm mb-0">
                        <tr>
                            <td class="text-muted small">Pimpinan</td>
                            <td class="fw-semibold small">{{ $approval->nama_pimpinan }}</td>
                        </tr>
                        @if($approval->catatan_approval)
                            <tr>
                                <td class="text-muted small">Catatan</td>
                                <td class="small">{{ $approval->catatan_approval }}</td>
                            </tr>
                        @endif
                    </table>
                @else
                    <div class="text-muted text-center small py-3">
                        Data approval tidak tersedia.
                    </div>
                @endif
            </div>
        </div>

        {{-- Ringkasan --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-clipboard-data me-2"></i>Ringkasan
                </h5>
            </div>
            <div class="card-body p-4">
                <div class="d-flex justify-content-between py-2 border-bottom">
                    <span class="text-muted small">Total Jenis Barang</span>
                    <span class="fw-bold">{{ $detailItems->count() }} jenis</span>
                </div>
                <div class="d-flex justify-content-between py-2 border-bottom">
                    <span class="text-muted small">Total Kuantitas</span>
                    <span class="fw-bold">
                        {{ number_format($detailItems->sum('jumlah')) }} unit
                    </span>
                </div>
                <div class="d-flex justify-content-between py-2">
                    <span class="text-muted small">Prioritas</span>
                    <span class="fw-bold">{{ $distribusi->prioritas }}</span>
                </div>
            </div>
        </div>

        {{-- Tombol --}}
        <div class="d-grid gap-2">
            <a href="{{ route('distribusi.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar
            </a>
            <a href="{{ route('permintaan.show', $distribusi->permintaan_id) }}"
               class="btn btn-outline-primary">
                <i class="bi bi-file-earmark-text me-1"></i> Lihat Permintaan
            </a>
        </div>

    </div>

</div>

@endsection