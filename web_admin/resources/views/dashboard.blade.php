@extends('layouts.app')

@section('title', 'Dashboard')
@section('page-title', 'Dashboard Admin')

@section('content')

<div class="mb-4">
    <h4 class="fw-bold mb-0">Selamat Datang, {{ session('nama') }} 👋</h4>
    <small class="text-muted">Berikut ringkasan data sistem inventori hari ini.</small>
</div>

{{-- ── Baris 1: Statistik Barang ── --}}
<div class="row g-3 mb-3">

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-box-seam fs-4" style="color:#1565C0;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Barang</div>
                    <div class="fw-bold fs-3">{{ $totalBarang }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-stack fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Stok</div>
                    <div class="fw-bold fs-3">{{ number_format($totalStok) }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fef3c7;">
                    <i class="bi bi-exclamation-triangle fs-4" style="color:#92400e;"></i>
                </div>
                <div>
                    <div class="text-muted small">Stok Menipis</div>
                    <div class="fw-bold fs-3 text-warning">{{ $stokMenipis }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fee2e2;">
                    <i class="bi bi-x-circle fs-4" style="color:#991b1b;"></i>
                </div>
                <div>
                    <div class="text-muted small">Barang Habis</div>
                    <div class="fw-bold fs-3 text-danger">{{ $barangHabis }}</div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ── Baris 2: Statistik Permintaan & Distribusi ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-4">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fef3c7;">
                    <i class="bi bi-hourglass-split fs-4" style="color:#92400e;"></i>
                </div>
                <div>
                    <div class="text-muted small">Permintaan Pending</div>
                    <div class="fw-bold fs-3 text-warning">{{ $pendingRequest }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-check2-circle fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Approval Disetujui</div>
                    <div class="fw-bold fs-3 text-success">{{ $approvalApproved }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-truck fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Distribusi Selesai</div>
                    <div class="fw-bold fs-3 text-success">{{ $distribusiSelesai }}</div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ── Tabel Permintaan Terbaru ── --}}
<div class="card">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#fff;border-bottom:2px solid #f0f4ff;">
        <h6 class="mb-0 fw-semibold">
            <i class="bi bi-clock-history me-2 text-primary"></i>Permintaan Terbaru
        </h6>
        <a href="#" class="btn btn-sm btn-outline-primary">Lihat Semua</a>
    </div>
    <div class="card-body p-0">
        <table class="table table-hover align-middle mb-0">
            <thead style="background:#f8faff;">
                <tr>
                    <th class="ps-4">No. Permintaan</th>
                    <th>Pemohon</th>
                    <th>Tanggal</th>
                    <th class="pe-4">Status</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recentRequests as $req)
                    <tr>
                        <td class="ps-4">
                            <code class="text-primary">{{ $req->nomor_permintaan ?? '—' }}</code>
                        </td>
                        <td>{{ $req->nama_lengkap }}</td>
                        <td class="text-muted">
                            {{ \Carbon\Carbon::parse($req->tanggal_permintaan)->format('d M Y, H:i') }}
                        </td>
                        <td class="pe-4">
                            @if($req->status_permintaan == 'Pending')
                                <span class="badge bg-warning text-dark">Pending</span>
                            @elseif($req->status_permintaan == 'Approved')
                                <span class="badge bg-success">Approved</span>
                            @elseif($req->status_permintaan == 'Rejected')
                                <span class="badge bg-danger">Rejected</span>
                            @elseif($req->status_permintaan == 'Revision')
                                <span class="badge bg-info text-dark">Revision</span>
                            @elseif($req->status_permintaan == 'Distributed')
                                <span class="badge bg-primary">Distributed</span>
                            @else
                                <span class="badge bg-secondary">{{ $req->status_permintaan }}</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="4" class="text-center py-5 text-muted">
                            <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                            Belum ada data permintaan.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

@endsection