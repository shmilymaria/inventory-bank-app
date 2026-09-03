@extends('layouts.app')

@section('title', 'Detail Barang')
@section('page-title', 'Data Barang')

@section('content')

{{-- ── Breadcrumb ── --}}
<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('barang.index') }}" class="text-decoration-none">Data Barang</a>
        </li>
        <li class="breadcrumb-item active">Detail Barang</li>
    </ol>
</nav>

<div class="row g-4">

    {{-- ── Kolom Kiri: Detail Barang ── --}}
    <div class="col-lg-7">
        <div class="card h-100">

            <div class="card-header py-3 d-flex justify-content-between align-items-center"
                 style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-box-seam me-2"></i>Detail Barang
                </h5>
                <div class="d-flex gap-2">
                    <a href="{{ route('barang.edit', $barang->id) }}"
                       class="btn btn-sm btn-light">
                        <i class="bi bi-pencil me-1"></i>Edit
                    </a>
                </div>
            </div>

            <div class="card-body p-4">

                {{-- Kode & Status --}}
                <div class="d-flex justify-content-between align-items-start mb-4">
                    <div>
                        <code class="fs-5 text-primary">{{ $barang->kode_barang }}</code>
                        <h4 class="fw-bold mt-1 mb-0">{{ $barang->nama_barang }}</h4>
                        <small class="text-muted">{{ $barang->nama_kategori }}</small>
                    </div>
                    <div>
                        @if($barang->status_barang == 'Tersedia')
                            <span class="badge badge-tersedia px-3 py-2 rounded-pill fs-6">
                                <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Tersedia
                            </span>
                        @elseif($barang->status_barang == 'Stok Menipis')
                            <span class="badge badge-menipis px-3 py-2 rounded-pill fs-6">
                                <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Stok Menipis
                            </span>
                        @else
                            <span class="badge badge-habis px-3 py-2 rounded-pill fs-6">
                                <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Habis
                            </span>
                        @endif
                    </div>
                </div>

                {{-- Info Stok --}}
                <div class="row g-3 mb-4">
                    <div class="col-4">
                        <div class="p-3 rounded-3 text-center" style="background:#f0f4ff;">
                            <div class="text-muted small mb-1">Stok Saat Ini</div>
                            <div class="fw-bold fs-3"
                                 style="color:{{ $barang->stok <= 0 ? '#dc3545' : ($barang->stok <= $barang->stok_minimum ? '#856404' : '#1565C0') }}">
                                {{ number_format($barang->stok) }}
                            </div>
                            <div class="text-muted small">{{ $barang->satuan }}</div>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-3 rounded-3 text-center" style="background:#f8f9fa;">
                            <div class="text-muted small mb-1">Stok Minimum</div>
                            <div class="fw-bold fs-3 text-secondary">
                                {{ number_format($barang->stok_minimum) }}
                            </div>
                            <div class="text-muted small">{{ $barang->satuan }}</div>
                        </div>
                    </div>
                    <div class="col-4">
                        <div class="p-3 rounded-3 text-center" style="background:#f8f9fa;">
                            <div class="text-muted small mb-1">Satuan</div>
                            <div class="fw-bold fs-3 text-secondary">
                                {{ $barang->satuan }}
                            </div>
                            <div class="text-muted small">&nbsp;</div>
                        </div>
                    </div>
                </div>

                {{-- Informasi Lain --}}
                <table class="table table-borderless table-sm">
                    <tr>
                        <td class="text-muted" style="width:40%">Lokasi Penyimpanan</td>
                        <td class="fw-semibold">{{ $barang->lokasi_penyimpanan ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">Deskripsi</td>
                        <td>{{ $barang->deskripsi ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">Tanggal Ditambahkan</td>
                        <td>{{ \Carbon\Carbon::parse($barang->created_at)->format('d M Y, H:i') }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">Terakhir Diperbarui</td>
                        <td>{{ \Carbon\Carbon::parse($barang->updated_at)->format('d M Y, H:i') }}</td>
                    </tr>
                </table>

            </div>

            <div class="card-footer bg-white border-top pt-3 pb-3">
                <a href="{{ route('barang.index') }}" class="btn btn-outline-secondary">
                    <i class="bi bi-arrow-left me-1"></i> Kembali
                </a>
            </div>

        </div>
    </div>

    {{-- ── Kolom Kanan: Riwayat Stok ── --}}
    <div class="col-lg-5">
        <div class="card h-100">

            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-clock-history me-2"></i>Riwayat Stok
                </h5>
            </div>

            <div class="card-body p-0" style="max-height:520px;overflow-y:auto;">

                @forelse($riwayat as $r)
                    <div class="d-flex gap-3 p-3 border-bottom align-items-start">

                        <div class="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0"
                             style="width:38px;height:38px;
                                    background:{{ $r->jenis_transaksi == 'Masuk' ? '#d1fae5' : '#fee2e2' }};">
                            <i class="bi {{ $r->jenis_transaksi == 'Masuk' ? 'bi-arrow-down-circle' : 'bi-arrow-up-circle' }}"
                               style="color:{{ $r->jenis_transaksi == 'Masuk' ? '#065f46' : '#991b1b' }};"></i>
                        </div>

                        <div class="flex-grow-1">
                            <div class="d-flex justify-content-between align-items-center">
                                <span class="fw-semibold small">
                                    {{ $r->jenis_transaksi == 'Masuk' ? '+' : '-' }}{{ number_format($r->jumlah) }} {{ $barang->satuan }}
                                </span>
                                <span class="text-muted" style="font-size:0.75rem;">
                                    {{ \Carbon\Carbon::parse($r->created_at)->format('d/m/y H:i') }}
                                </span>
                            </div>
                            <div class="text-muted" style="font-size:0.8rem;">
                                {{ $r->stok_sebelum }} → {{ $r->stok_sesudah }} {{ $barang->satuan }}
                            </div>
                            @if($r->keterangan)
                                <div class="text-muted mt-1" style="font-size:0.78rem;">
                                    {{ $r->keterangan }}
                                </div>
                            @endif
                        </div>

                    </div>
                @empty
                    <div class="text-center py-5 text-muted">
                        <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                        Belum ada riwayat stok.
                    </div>
                @endforelse

            </div>

        </div>
    </div>

</div>

@endsection