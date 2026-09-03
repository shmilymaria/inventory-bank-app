{{-- ============================================================
     LAPORAN DISTRIBUSI — resources/views/laporan/distribusi.blade.php
============================================================ --}}
@extends('layouts.app')

@section('title', 'Laporan Distribusi')
@section('page-title', 'Laporan')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('laporan.index') }}" class="text-decoration-none">Laporan</a>
        </li>
        <li class="breadcrumb-item active">Laporan Distribusi</li>
    </ol>
</nav>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Laporan Distribusi</h4>
        <small class="text-muted">Rekap distribusi barang per periode</small>
    </div>
    <button onclick="window.print()" class="btn btn-outline-primary">
        <i class="bi bi-printer me-1"></i> Cetak Laporan
    </button>
</div>

{{-- ── Filter ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('laporan.distribusi') }}" class="row g-2 align-items-end">
            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Periode Bulan</label>
                <input type="month" name="bulan" class="form-control" value="{{ $bulan }}">
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('laporan.distribusi') }}" class="btn btn-outline-secondary flex-fill">Reset</a>
            </div>
        </form>
    </div>
</div>

{{-- ── Statistik Periode ── --}}
<div class="row g-3 mb-4">
    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #1565C0;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-truck fs-4" style="color:#1565C0;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Distribusi</div>
                    <div class="fw-bold fs-3">{{ $distribusi->total() }}</div>
                    <div class="text-muted" style="font-size:0.72rem;">
                        {{ \Carbon\Carbon::createFromFormat('Y-m', $bulan)->translatedFormat('F Y') }}
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #10b981;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-check2-all fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Distribusi Selesai</div>
                    <div class="fw-bold fs-3 text-success">
                        {{ $distribusi->getCollection()->where('status_distribusi','Selesai')->count() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #8b5cf6;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#ede9fe;">
                    <i class="bi bi-box-arrow-up fs-4" style="color:#5b21b6;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Barang Keluar</div>
                    <div class="fw-bold fs-3" style="color:#5b21b6;">
                        {{ number_format($totalBarangKeluar) }}
                    </div>
                    <div class="text-muted" style="font-size:0.72rem;">unit</div>
                </div>
            </div>
        </div>
    </div>
</div>

{{-- ── Tabel Distribusi ── --}}
<div class="card">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#1565C0;">
        <h6 class="mb-0 text-white fw-semibold">
            <i class="bi bi-table me-2"></i>Detail Distribusi
        </h6>
        <span class="badge bg-white text-primary">{{ $distribusi->total() }} data</span>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4" style="width:45px;">No</th>
                        <th>No. Permintaan</th>
                        <th>Pemohon</th>
                        <th>Bagian</th>
                        <th>Diproses oleh</th>
                        <th>Tanggal Distribusi</th>
                        <th class="text-center pe-4">Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($distribusi as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($distribusi->currentPage() - 1) * $distribusi->perPage() + $loop->iteration }}
                            </td>
                            <td>
                                <a href="{{ route('distribusi.detail', $item->id) }}"
                                   class="text-decoration-none">
                                    <code class="text-primary">{{ $item->nomor_permintaan }}</code>
                                </a>
                            </td>
                            <td class="fw-semibold">{{ $item->nama_pemohon }}</td>
                            <td class="text-muted small">{{ $item->bagian ?? '—' }}</td>
                            <td class="text-muted small">{{ $item->nama_admin }}</td>
                            <td class="text-muted small">
                                {{ \Carbon\Carbon::parse($item->tanggal_distribusi)->format('d M Y, H:i') }}
                            </td>
                            <td class="text-center pe-4">
                                @if($item->status_distribusi == 'Selesai')
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#d1fae5;color:#065f46;">
                                        <i class="bi bi-check-circle me-1"></i>Selesai
                                    </span>
                                @else
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#dbeafe;color:#1e40af;">
                                        <i class="bi bi-truck me-1"></i>Diproses
                                    </span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Tidak ada data distribusi pada periode ini.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($distribusi->hasPages())
            <div class="px-4 py-3 border-top">{{ $distribusi->links() }}</div>
        @endif
    </div>
</div>

@endsection