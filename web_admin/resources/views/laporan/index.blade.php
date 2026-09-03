@extends('layouts.app')

@section('title', 'Laporan')
@section('page-title', 'Laporan')

@section('content')

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Laporan</h4>
        <small class="text-muted">Ringkasan data dan laporan sistem inventori</small>
    </div>
    <div class="text-muted small">
        <i class="bi bi-calendar3 me-1"></i>
        {{ now()->translatedFormat('d F Y') }}
    </div>
</div>

{{-- ── Kartu Navigasi Laporan ── --}}
<div class="row g-4 mb-4">

    <div class="col-md-6 col-lg-3">
        <a href="{{ route('laporan.barang') }}" class="text-decoration-none">
            <div class="card h-100" style="border-top:4px solid #1565C0;transition:transform 0.15s;"
                 onmouseover="this.style.transform='translateY(-4px)'"
                 onmouseout="this.style.transform='translateY(0)'">
                <div class="card-body p-4 text-center">
                    <div class="rounded-3 d-inline-flex align-items-center justify-content-center mb-3 p-3"
                         style="background:#dbeafe;">
                        <i class="bi bi-box-seam fs-2" style="color:#1565C0;"></i>
                    </div>
                    <h6 class="fw-bold mb-1">Laporan Barang</h6>
                    <p class="text-muted small mb-3">
                        Status stok, kategori, dan kondisi seluruh barang inventori
                    </p>
                    <div class="d-flex justify-content-center gap-3">
                        <div class="text-center">
                            <div class="fw-bold fs-5" style="color:#1565C0;">{{ $stats['total_barang'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Total Barang</div>
                        </div>
                        <div class="text-center">
                            <div class="fw-bold fs-5 text-danger">{{ $stats['barang_habis'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Habis</div>
                        </div>
                    </div>
                </div>
                <div class="card-footer bg-white border-top text-center py-2">
                    <small style="color:#1565C0;" class="fw-semibold">
                        Lihat Laporan <i class="bi bi-arrow-right ms-1"></i>
                    </small>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-6 col-lg-3">
        <a href="{{ route('laporan.permintaan') }}" class="text-decoration-none">
            <div class="card h-100" style="border-top:4px solid #f59e0b;transition:transform 0.15s;"
                 onmouseover="this.style.transform='translateY(-4px)'"
                 onmouseout="this.style.transform='translateY(0)'">
                <div class="card-body p-4 text-center">
                    <div class="rounded-3 d-inline-flex align-items-center justify-content-center mb-3 p-3"
                         style="background:#fef3c7;">
                        <i class="bi bi-file-earmark-text fs-2" style="color:#92400e;"></i>
                    </div>
                    <h6 class="fw-bold mb-1">Laporan Permintaan</h6>
                    <p class="text-muted small mb-3">
                        Rekap permintaan barang per periode dan status penyelesaian
                    </p>
                    <div class="d-flex justify-content-center gap-3">
                        <div class="text-center">
                            <div class="fw-bold fs-5" style="color:#92400e;">{{ $stats['total_permintaan'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Total</div>
                        </div>
                        <div class="text-center">
                            <div class="fw-bold fs-5 text-warning">{{ $stats['pending'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Pending</div>
                        </div>
                    </div>
                </div>
                <div class="card-footer bg-white border-top text-center py-2">
                    <small style="color:#92400e;" class="fw-semibold">
                        Lihat Laporan <i class="bi bi-arrow-right ms-1"></i>
                    </small>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-6 col-lg-3">
        <a href="{{ route('laporan.distribusi') }}" class="text-decoration-none">
            <div class="card h-100" style="border-top:4px solid #10b981;transition:transform 0.15s;"
                 onmouseover="this.style.transform='translateY(-4px)'"
                 onmouseout="this.style.transform='translateY(0)'">
                <div class="card-body p-4 text-center">
                    <div class="rounded-3 d-inline-flex align-items-center justify-content-center mb-3 p-3"
                         style="background:#d1fae5;">
                        <i class="bi bi-truck fs-2" style="color:#065f46;"></i>
                    </div>
                    <h6 class="fw-bold mb-1">Laporan Distribusi</h6>
                    <p class="text-muted small mb-3">
                        Rekap distribusi barang yang telah diproses per periode
                    </p>
                    <div class="d-flex justify-content-center gap-3">
                        <div class="text-center">
                            <div class="fw-bold fs-5" style="color:#065f46;">{{ $stats['total_distribusi'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Total</div>
                        </div>
                        <div class="text-center">
                            <div class="fw-bold fs-5 text-success">{{ $stats['dist_selesai'] }}</div>
                            <div class="text-muted" style="font-size:0.72rem;">Selesai</div>
                        </div>
                    </div>
                </div>
                <div class="card-footer bg-white border-top text-center py-2">
                    <small style="color:#065f46;" class="fw-semibold">
                        Lihat Laporan <i class="bi bi-arrow-right ms-1"></i>
                    </small>
                </div>
            </div>
        </a>
    </div>

    <div class="col-md-6 col-lg-3">
        <a href="{{ route('laporan.stok') }}" class="text-decoration-none">
            <div class="card h-100" style="border-top:4px solid #8b5cf6;transition:transform 0.15s;"
                 onmouseover="this.style.transform='translateY(-4px)'"
                 onmouseout="this.style.transform='translateY(0)'">
                <div class="card-body p-4 text-center">
                    <div class="rounded-3 d-inline-flex align-items-center justify-content-center mb-3 p-3"
                         style="background:#ede9fe;">
                        <i class="bi bi-graph-up-arrow fs-2" style="color:#5b21b6;"></i>
                    </div>
                    <h6 class="fw-bold mb-1">Laporan Riwayat Stok</h6>
                    <p class="text-muted small mb-3">
                        Seluruh pergerakan stok masuk dan keluar per barang
                    </p>
                    <div class="d-flex justify-content-center gap-3">
                        <div class="text-center">
                            <div class="fw-bold fs-5" style="color:#5b21b6;">
                                {{ number_format($stats['stok_keluar_bulan_ini']) }}
                            </div>
                            <div class="text-muted" style="font-size:0.72rem;">Keluar Bulan Ini</div>
                        </div>
                    </div>
                </div>
                <div class="card-footer bg-white border-top text-center py-2">
                    <small style="color:#5b21b6;" class="fw-semibold">
                        Lihat Laporan <i class="bi bi-arrow-right ms-1"></i>
                    </small>
                </div>
            </div>
        </a>
    </div>

</div>

{{-- ── Ringkasan Sistem ── --}}
<div class="row g-4">

    {{-- Statistik Barang --}}
    <div class="col-lg-6">
        <div class="card">
            <div class="card-header py-3" style="background:#1565C0;">
                <h6 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-box-seam me-2"></i>Kondisi Stok Barang
                </h6>
            </div>
            <div class="card-body p-4">
                <div class="row g-3 mb-3">
                    <div class="col-4 text-center">
                        <div class="p-3 rounded-3" style="background:#d1fae5;">
                            <div class="fw-bold fs-4" style="color:#065f46;">
                                {{ $stats['total_barang'] - $stats['stok_menipis'] - $stats['barang_habis'] }}
                            </div>
                            <div class="small" style="color:#065f46;">Tersedia</div>
                        </div>
                    </div>
                    <div class="col-4 text-center">
                        <div class="p-3 rounded-3" style="background:#fef3c7;">
                            <div class="fw-bold fs-4" style="color:#92400e;">{{ $stats['stok_menipis'] }}</div>
                            <div class="small" style="color:#92400e;">Stok Menipis</div>
                        </div>
                    </div>
                    <div class="col-4 text-center">
                        <div class="p-3 rounded-3" style="background:#fee2e2;">
                            <div class="fw-bold fs-4" style="color:#991b1b;">{{ $stats['barang_habis'] }}</div>
                            <div class="small" style="color:#991b1b;">Habis</div>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-between align-items-center pt-2 border-top">
                    <span class="text-muted small">Total Stok Keseluruhan</span>
                    <span class="fw-bold">{{ number_format($stats['total_stok']) }} unit</span>
                </div>
            </div>
        </div>
    </div>

    {{-- Statistik Permintaan --}}
    <div class="col-lg-6">
        <div class="card">
            <div class="card-header py-3" style="background:#1565C0;">
                <h6 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-file-earmark-text me-2"></i>Rekap Permintaan
                </h6>
            </div>
            <div class="card-body p-4">
                @php
                    $statusList = [
                        'Pending'     => ['color' => '#92400e',  'bg' => '#fef3c7'],
                        'Approved'    => ['color' => '#065f46',  'bg' => '#d1fae5'],
                        'Rejected'    => ['color' => '#991b1b',  'bg' => '#fee2e2'],
                        'Revision'    => ['color' => '#1e40af',  'bg' => '#dbeafe'],
                        'Distributed' => ['color' => '#5b21b6',  'bg' => '#ede9fe'],
                    ];
                    $total = $stats['total_permintaan'] ?: 1;
                @endphp
                @foreach($statusList as $status => $cfg)
                    @php
                        $jumlah = $stats[strtolower($status)] ?? $stats['distributed'] ?? 0;
                        if ($status === 'Distributed') $jumlah = $stats['distributed'];
                        if ($status === 'Approved')    $jumlah = $stats['approved'];
                        if ($status === 'Rejected')    $jumlah = $stats['rejected'];
                        $persen = round(($jumlah / $total) * 100);
                    @endphp
                    <div class="mb-2">
                        <div class="d-flex justify-content-between mb-1">
                            <small class="fw-semibold">{{ $status }}</small>
                            <small class="text-muted">{{ $jumlah }} ({{ $persen }}%)</small>
                        </div>
                        <div class="progress" style="height:8px;border-radius:999px;">
                            <div class="progress-bar" role="progressbar"
                                 style="width:{{ $persen }}%;background:{{ $cfg['color'] }};border-radius:999px;">
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </div>

</div>

@endsection