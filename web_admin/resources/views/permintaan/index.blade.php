@extends('layouts.app')

@section('title', 'Kelola Permintaan')
@section('page-title', 'Kelola Permintaan')

@section('content')

{{-- ── Header ── --}}
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Kelola Permintaan</h4>
        <small class="text-muted">Pantau dan kelola seluruh permintaan barang dari Staff</small>
    </div>
</div>

{{-- ── Statistik ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-2">
        <div class="card card-stat h-100">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3">{{ $stats['total'] }}</div>
                <div class="text-muted small">Total</div>
            </div>
        </div>
    </div>

    <div class="col-md-2">
        <div class="card card-stat h-100" style="border-left:4px solid #f59e0b;">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3 text-warning">{{ $stats['pending'] }}</div>
                <div class="text-muted small">Pending</div>
            </div>
        </div>
    </div>

    <div class="col-md-2">
        <div class="card card-stat h-100" style="border-left:4px solid #10b981;">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3 text-success">{{ $stats['approved'] }}</div>
                <div class="text-muted small">Approved</div>
            </div>
        </div>
    </div>

    <div class="col-md-2">
        <div class="card card-stat h-100" style="border-left:4px solid #ef4444;">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3 text-danger">{{ $stats['rejected'] }}</div>
                <div class="text-muted small">Rejected</div>
            </div>
        </div>
    </div>

    <div class="col-md-2">
        <div class="card card-stat h-100" style="border-left:4px solid #3b82f6;">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3" style="color:#3b82f6;">{{ $stats['revision'] }}</div>
                <div class="text-muted small">Revision</div>
            </div>
        </div>
    </div>

    <div class="col-md-2">
        <div class="card card-stat h-100" style="border-left:4px solid #1565C0;">
            <div class="card-body text-center py-3">
                <div class="fw-bold fs-3" style="color:#1565C0;">{{ $stats['distributed'] }}</div>
                <div class="text-muted small">Distributed</div>
            </div>
        </div>
    </div>

</div>

{{-- ── Filter & Search ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('permintaan.index') }}" class="row g-2 align-items-end">

            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Cari Permintaan</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                    <input type="text" name="search" class="form-control"
                           placeholder="No. permintaan atau nama..."
                           value="{{ request('search') }}">
                </div>
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Status</label>
                <select name="status" class="form-select">
                    <option value="">Semua Status</option>
                    @foreach(['Pending','Approved','Rejected','Revision','Distributed'] as $s)
                        <option value="{{ $s }}" {{ request('status') == $s ? 'selected' : '' }}>
                            {{ $s }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Prioritas</label>
                <select name="prioritas" class="form-select">
                    <option value="">Semua Prioritas</option>
                    @foreach(['Normal','Penting','Mendesak'] as $p)
                        <option value="{{ $p }}" {{ request('prioritas') == $p ? 'selected' : '' }}>
                            {{ $p }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Dari Tanggal</label>
                <input type="date" name="tanggal_dari" class="form-control"
                       value="{{ request('tanggal_dari') }}">
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Sampai Tanggal</label>
                <input type="date" name="tanggal_sampai" class="form-control"
                       value="{{ request('tanggal_sampai') }}">
            </div>

            <div class="col-md-1 d-flex gap-1">
                <button type="submit" class="btn btn-primary flex-fill" title="Filter">
                    <i class="bi bi-funnel"></i>
                </button>
                <a href="{{ route('permintaan.index') }}" class="btn btn-outline-secondary flex-fill" title="Reset">
                    <i class="bi bi-arrow-counterclockwise"></i>
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
                        <th>No. Permintaan</th>
                        <th>Pemohon</th>
                        <th>Bagian</th>
                        <th class="text-center">Prioritas</th>
                        <th>Tanggal</th>
                        <th class="text-center">Status</th>
                        <th class="text-center pe-4">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($permintaan as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($permintaan->currentPage() - 1) * $permintaan->perPage() + $loop->iteration }}
                            </td>

                            <td>
                                <code class="text-primary">
                                    {{ $item->nomor_permintaan ?? 'DRAFT-' . $item->id }}
                                </code>
                            </td>

                            <td class="fw-semibold">{{ $item->nama_lengkap }}</td>

                            <td class="text-muted small">{{ $item->bagian ?? '—' }}</td>

                            {{-- Badge Prioritas --}}
                            <td class="text-center">
                                @if($item->prioritas == 'Mendesak')
                                    <span class="badge rounded-pill"
                                          style="background:#fee2e2;color:#991b1b;">
                                        <i class="bi bi-exclamation-circle me-1"></i>Mendesak
                                    </span>
                                @elseif($item->prioritas == 'Penting')
                                    <span class="badge rounded-pill"
                                          style="background:#fef3c7;color:#92400e;">
                                        <i class="bi bi-exclamation me-1"></i>Penting
                                    </span>
                                @else
                                    <span class="badge rounded-pill"
                                          style="background:#f1f5f9;color:#64748b;">
                                        Normal
                                    </span>
                                @endif
                            </td>

                            <td class="text-muted small">
                                {{ \Carbon\Carbon::parse($item->tanggal_permintaan)->format('d M Y') }}
                                <div style="font-size:0.72rem;">
                                    {{ \Carbon\Carbon::parse($item->tanggal_permintaan)->format('H:i') }}
                                </div>
                            </td>

                            {{-- Badge Status --}}
                            <td class="text-center">
                                @php
                                    $statusConfig = [
                                        'Pending'     => ['bg' => '#fef3c7', 'color' => '#92400e',  'icon' => 'bi-hourglass-split'],
                                        'Approved'    => ['bg' => '#d1fae5', 'color' => '#065f46',  'icon' => 'bi-check-circle'],
                                        'Rejected'    => ['bg' => '#fee2e2', 'color' => '#991b1b',  'icon' => 'bi-x-circle'],
                                        'Revision'    => ['bg' => '#dbeafe', 'color' => '#1e40af',  'icon' => 'bi-arrow-repeat'],
                                        'Distributed' => ['bg' => '#ede9fe', 'color' => '#5b21b6',  'icon' => 'bi-truck'],
                                    ];
                                    $cfg = $statusConfig[$item->status_permintaan] ?? ['bg' => '#f1f5f9', 'color' => '#64748b', 'icon' => 'bi-circle'];
                                @endphp
                                <span class="badge rounded-pill px-3 py-2"
                                      style="background:{{ $cfg['bg'] }};color:{{ $cfg['color'] }};">
                                    <i class="bi {{ $cfg['icon'] }} me-1"></i>
                                    {{ $item->status_permintaan }}
                                </span>
                            </td>

                            <td class="text-center pe-4">
                                <a href="{{ route('permintaan.show', $item->id) }}"
                                   class="btn btn-sm btn-outline-primary"
                                   title="Lihat Detail">
                                    <i class="bi bi-eye"></i> Detail
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Belum ada data permintaan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        @if($permintaan->hasPages())
            <div class="px-4 py-3 border-top">
                {{ $permintaan->links() }}
            </div>
        @endif

    </div>
</div>

@endsection