@extends('layouts.app')

@section('title', 'Laporan Permintaan')
@section('page-title', 'Laporan')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('laporan.index') }}" class="text-decoration-none">Laporan</a>
        </li>
        <li class="breadcrumb-item active">Laporan Permintaan</li>
    </ol>
</nav>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Laporan Permintaan</h4>
        <small class="text-muted">Rekap permintaan barang per periode</small>
    </div>
    <button onclick="window.print()" class="btn btn-outline-primary">
        <i class="bi bi-printer me-1"></i> Cetak Laporan
    </button>
</div>

{{-- ── Filter Periode ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('laporan.permintaan') }}" class="row g-2 align-items-end">
            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Periode Bulan</label>
                <input type="month" name="bulan" class="form-control"
                       value="{{ $bulan }}">
            </div>
            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Status</label>
                <select name="status" class="form-select">
                    <option value="">Semua Status</option>
                    @foreach(['Pending','Approved','Rejected','Revision','Distributed'] as $s)
                        <option value="{{ $s }}" {{ request('status') == $s ? 'selected' : '' }}>{{ $s }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('laporan.permintaan') }}" class="btn btn-outline-secondary flex-fill">Reset</a>
            </div>
        </form>
    </div>
</div>

{{-- ── Ringkasan Status & Bagian ── --}}
<div class="row g-4 mb-4">

    {{-- Ringkasan per Status --}}
    <div class="col-lg-7">
        <div class="card h-100">
            <div class="card-header py-3" style="background:#1565C0;">
                <h6 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-pie-chart me-2"></i>Ringkasan Per Status
                    <small class="fw-normal opacity-75 ms-1">
                        ({{ \Carbon\Carbon::createFromFormat('Y-m', $bulan)->translatedFormat('F Y') }})
                    </small>
                </h6>
            </div>
            <div class="card-body">
                @php
                    $totalPeriode = collect($ringkasanStatus)->sum('total') ?: 1;
                    $cfgStatus = [
                        'Pending'     => ['bg' => '#fef3c7', 'color' => '#92400e'],
                        'Approved'    => ['bg' => '#d1fae5', 'color' => '#065f46'],
                        'Rejected'    => ['bg' => '#fee2e2', 'color' => '#991b1b'],
                        'Revision'    => ['bg' => '#dbeafe', 'color' => '#1e40af'],
                        'Distributed' => ['bg' => '#ede9fe', 'color' => '#5b21b6'],
                    ];
                @endphp
                <div class="row g-2 mb-3">
                    @foreach($cfgStatus as $status => $cfg)
                        @php $jumlah = $ringkasanStatus[$status]->total ?? 0; @endphp
                        <div class="col">
                            <div class="p-2 rounded-3 text-center"
                                 style="background:{{ $cfg['bg'] }};">
                                <div class="fw-bold fs-5" style="color:{{ $cfg['color'] }};">
                                    {{ $jumlah }}
                                </div>
                                <div style="font-size:0.72rem;color:{{ $cfg['color'] }};">
                                    {{ $status }}
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
                @foreach($cfgStatus as $status => $cfg)
                    @php
                        $jumlah = $ringkasanStatus[$status]->total ?? 0;
                        $persen = round(($jumlah / $totalPeriode) * 100);
                    @endphp
                    <div class="mb-2">
                        <div class="d-flex justify-content-between mb-1">
                            <small>{{ $status }}</small>
                            <small class="text-muted">{{ $jumlah }} ({{ $persen }}%)</small>
                        </div>
                        <div class="progress" style="height:7px;border-radius:999px;">
                            <div class="progress-bar"
                                 style="width:{{ $persen }}%;background:{{ $cfg['color'] }};border-radius:999px;">
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </div>

    {{-- Ringkasan per Bagian --}}
    <div class="col-lg-5">
        <div class="card h-100">
            <div class="card-header py-3" style="background:#1565C0;">
                <h6 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-building me-2"></i>Top 5 Bagian Pemohon
                </h6>
            </div>
            <div class="card-body">
                @php $maxBagian = $ringkasanBagian->max('total') ?: 1; @endphp
                @forelse($ringkasanBagian as $bagian)
                    <div class="mb-3">
                        <div class="d-flex justify-content-between mb-1">
                            <small class="fw-semibold">{{ $bagian->bagian ?? 'Tidak Diketahui' }}</small>
                            <small class="text-muted">{{ $bagian->total }} permintaan</small>
                        </div>
                        <div class="progress" style="height:8px;border-radius:999px;">
                            <div class="progress-bar"
                                 style="width:{{ round(($bagian->total / $maxBagian) * 100) }}%;
                                        background:#1565C0;border-radius:999px;">
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="text-center text-muted py-4">
                        Belum ada data permintaan pada periode ini.
                    </div>
                @endforelse
            </div>
        </div>
    </div>

</div>

{{-- ── Tabel Permintaan ── --}}
<div class="card">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#1565C0;">
        <h6 class="mb-0 text-white fw-semibold">
            <i class="bi bi-table me-2"></i>Detail Permintaan
        </h6>
        <span class="badge bg-white text-primary">{{ $permintaan->total() }} data</span>
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
                        <th class="text-center">Prioritas</th>
                        <th>Tanggal</th>
                        <th class="text-center pe-4">Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($permintaan as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($permintaan->currentPage() - 1) * $permintaan->perPage() + $loop->iteration }}
                            </td>
                            <td>
                                <a href="{{ route('permintaan.show', $item->id) }}"
                                   class="text-decoration-none">
                                    <code class="text-primary">
                                        {{ $item->nomor_permintaan ?? 'DRAFT-' . $item->id }}
                                    </code>
                                </a>
                            </td>
                            <td class="fw-semibold">{{ $item->nama_lengkap }}</td>
                            <td class="text-muted small">{{ $item->bagian ?? '—' }}</td>
                            <td class="text-center">
                                @if($item->prioritas == 'Mendesak')
                                    <span class="badge" style="background:#fee2e2;color:#991b1b;">Mendesak</span>
                                @elseif($item->prioritas == 'Penting')
                                    <span class="badge" style="background:#fef3c7;color:#92400e;">Penting</span>
                                @else
                                    <span class="badge" style="background:#f1f5f9;color:#64748b;">Normal</span>
                                @endif
                            </td>
                            <td class="text-muted small">
                                {{ \Carbon\Carbon::parse($item->tanggal_permintaan)->format('d M Y, H:i') }}
                            </td>
                            <td class="text-center pe-4">
                                @php
                                    $cfgMap = [
                                        'Pending'     => ['#fef3c7','#92400e'],
                                        'Approved'    => ['#d1fae5','#065f46'],
                                        'Rejected'    => ['#fee2e2','#991b1b'],
                                        'Revision'    => ['#dbeafe','#1e40af'],
                                        'Distributed' => ['#ede9fe','#5b21b6'],
                                    ];
                                    [$bg,$col] = $cfgMap[$item->status_permintaan] ?? ['#f1f5f9','#64748b'];
                                @endphp
                                <span class="badge rounded-pill px-3 py-2"
                                      style="background:{{ $bg }};color:{{ $col }};">
                                    {{ $item->status_permintaan }}
                                </span>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Tidak ada data permintaan pada periode ini.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($permintaan->hasPages())
            <div class="px-4 py-3 border-top">{{ $permintaan->links() }}</div>
        @endif
    </div>
</div>

@endsection