@extends('layouts.app')

@section('title', 'Distribusi Barang')
@section('page-title', 'Distribusi Barang')

@section('content')

{{-- ── Header ── --}}
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Distribusi Barang</h4>
        <small class="text-muted">Proses distribusi barang untuk permintaan yang telah disetujui</small>
    </div>
</div>

{{-- ── Statistik ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #f59e0b;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fef3c7;">
                    <i class="bi bi-clock-history fs-4" style="color:#92400e;"></i>
                </div>
                <div>
                    <div class="text-muted small">Menunggu Diproses</div>
                    <div class="fw-bold fs-3 text-warning">{{ $stats['siap'] }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #3b82f6;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-truck fs-4" style="color:#1e40af;"></i>
                </div>
                <div>
                    <div class="text-muted small">Sedang Diproses</div>
                    <div class="fw-bold fs-3" style="color:#1e40af;">{{ $stats['diproses'] }}</div>
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
                    <div class="text-muted small">Selesai Didistribusi</div>
                    <div class="fw-bold fs-3 text-success">{{ $stats['selesai'] }}</div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ══════════════════════════════════════════════════════════════
     BAGIAN 1 — Antrian Siap Distribusi
══════════════════════════════════════════════════════════════ --}}
<div class="card mb-4">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#1565C0;">
        <h5 class="mb-0 text-white fw-semibold">
            <i class="bi bi-hourglass-split me-2"></i>Antrian Siap Distribusi
        </h5>
        @if($stats['siap'] > 0)
            <span class="badge bg-warning text-dark px-3 py-2">
                {{ $stats['siap'] }} permintaan menunggu
            </span>
        @endif
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4">No. Permintaan</th>
                        <th>Pemohon</th>
                        <th>Bagian</th>
                        <th class="text-center">Prioritas</th>
                        <th>Tanggal Pengajuan</th>
                        <th class="text-center pe-4">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($siapDistribusi as $item)
                        <tr>
                            <td class="ps-4">
                                <code class="text-primary">
                                    {{ $item->nomor_permintaan ?? 'DRAFT-' . $item->id }}
                                </code>
                            </td>
                            <td class="fw-semibold">{{ $item->nama_lengkap }}</td>
                            <td class="text-muted small">{{ $item->bagian ?? '—' }}</td>

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
                                          style="background:#f1f5f9;color:#64748b;">Normal</span>
                                @endif
                            </td>

                            <td class="text-muted small">
                                {{ \Carbon\Carbon::parse($item->tanggal_permintaan)->format('d M Y, H:i') }}
                            </td>

                            <td class="text-center pe-4">
                                <a href="{{ route('distribusi.show', $item->id) }}"
                                   class="btn btn-sm btn-primary">
                                    <i class="bi bi-truck me-1"></i> Proses
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                <i class="bi bi-check2-circle fs-1 d-block mb-2 text-success"></i>
                                Tidak ada permintaan yang menunggu distribusi.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════
     BAGIAN 2 — Riwayat Distribusi
══════════════════════════════════════════════════════════════ --}}
<div class="card">
    <div class="card-header py-3" style="background:#1565C0;">
        <h5 class="mb-0 text-white fw-semibold">
            <i class="bi bi-clock-history me-2"></i>Riwayat Distribusi
        </h5>
    </div>

    {{-- Filter --}}
    <div class="card-body border-bottom py-3">
        <form method="GET" action="{{ route('distribusi.index') }}" class="row g-2 align-items-end">
            <div class="col-md-4">
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                    <input type="text" name="search" class="form-control"
                           placeholder="No. permintaan atau nama pemohon..."
                           value="{{ request('search') }}">
                </div>
            </div>
            <div class="col-md-3">
                <select name="status" class="form-select">
                    <option value="">Semua Status</option>
                    <option value="Diproses" {{ request('status') == 'Diproses' ? 'selected' : '' }}>Diproses</option>
                    <option value="Selesai"  {{ request('status') == 'Selesai'  ? 'selected' : '' }}>Selesai</option>
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('distribusi.index') }}" class="btn btn-outline-secondary flex-fill">
                    Reset
                </a>
            </div>
        </form>
    </div>

    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4" style="width:50px;">No</th>
                        <th>No. Permintaan</th>
                        <th>Pemohon</th>
                        <th>Diproses oleh</th>
                        <th>Tanggal Distribusi</th>
                        <th class="text-center">Status</th>
                        <th class="text-center pe-4">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($riwayatDistribusi as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($riwayatDistribusi->currentPage() - 1) * $riwayatDistribusi->perPage() + $loop->iteration }}
                            </td>
                            <td>
                                <code class="text-primary">
                                    {{ $item->nomor_permintaan ?? '—' }}
                                </code>
                            </td>
                            <td>
                                <div class="fw-semibold">{{ $item->nama_pemohon }}</div>
                                <div class="text-muted small">{{ $item->bagian ?? '—' }}</div>
                            </td>
                            <td class="text-muted small">{{ $item->nama_admin }}</td>
                            <td class="text-muted small">
                                {{ \Carbon\Carbon::parse($item->tanggal_distribusi)->format('d M Y, H:i') }}
                            </td>
                            <td class="text-center">
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
                            <td class="text-center pe-4">
                                <a href="{{ route('distribusi.detail', $item->id) }}"
                                   class="btn btn-sm btn-outline-primary"
                                   title="Lihat Detail">
                                    <i class="bi bi-eye"></i> Detail
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Belum ada riwayat distribusi.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($riwayatDistribusi->hasPages())
            <div class="px-4 py-3 border-top">
                {{ $riwayatDistribusi->links() }}
            </div>
        @endif

    </div>
</div>

@endsection