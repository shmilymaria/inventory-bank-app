@extends('layouts.app')

@section('title', 'Detail Permintaan')
@section('page-title', 'Kelola Permintaan')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('permintaan.index') }}" class="text-decoration-none">Kelola Permintaan</a>
        </li>
        <li class="breadcrumb-item active">Detail Permintaan</li>
    </ol>
</nav>

{{-- ── Timeline Status ── --}}
@php
    $allStatus  = ['Pending', 'Approved', 'Distributed'];
    $statusNow  = $permintaan->status_permintaan;
    $isRejected = $statusNow === 'Rejected';
    $isRevision = $statusNow === 'Revision';

    $stepDone = match($statusNow) {
        'Pending'     => 1,
        'Approved'    => 2,
        'Revision'    => 2,
        'Rejected'    => 2,
        'Distributed' => 3,
        default       => 1,
    };
@endphp

<div class="card mb-4">
    <div class="card-body py-3">
        <div class="d-flex align-items-center justify-content-center gap-0">

            {{-- Step 1: Pending --}}
            <div class="text-center" style="min-width:120px;">
                <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold mb-1"
                     style="width:42px;height:42px;
                            background:{{ $stepDone >= 1 ? '#1565C0' : '#e2e8f0' }};
                            color:{{ $stepDone >= 1 ? '#fff' : '#94a3b8' }};">
                    <i class="bi bi-file-earmark-text"></i>
                </div>
                <div class="small fw-semibold" style="color:{{ $stepDone >= 1 ? '#1565C0' : '#94a3b8' }};">
                    Diajukan
                </div>
                <div class="text-muted" style="font-size:0.7rem;">Pending</div>
            </div>

            {{-- Garis 1 --}}
            <div class="flex-grow-1 mx-2" style="height:3px;background:{{ $stepDone >= 2 ? '#1565C0' : '#e2e8f0' }};max-width:100px;"></div>

            {{-- Step 2: Approval --}}
            <div class="text-center" style="min-width:120px;">
                <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold mb-1"
                     style="width:42px;height:42px;
                            background:{{ $stepDone >= 2 ? ($isRejected ? '#ef4444' : ($isRevision ? '#3b82f6' : '#1565C0')) : '#e2e8f0' }};
                            color:{{ $stepDone >= 2 ? '#fff' : '#94a3b8' }};">
                    @if($isRejected)
                        <i class="bi bi-x-lg"></i>
                    @elseif($isRevision)
                        <i class="bi bi-arrow-repeat"></i>
                    @else
                        <i class="bi bi-check2"></i>
                    @endif
                </div>
                <div class="small fw-semibold"
                     style="color:{{ $stepDone >= 2 ? ($isRejected ? '#ef4444' : ($isRevision ? '#3b82f6' : '#1565C0')) : '#94a3b8' }};">
                    Approval
                </div>
                <div class="text-muted" style="font-size:0.7rem;">
                    {{ $isRejected ? 'Rejected' : ($isRevision ? 'Revision' : ($stepDone >= 2 ? 'Approved' : 'Menunggu')) }}
                </div>
            </div>

            {{-- Garis 2 --}}
            <div class="flex-grow-1 mx-2" style="height:3px;background:{{ $stepDone >= 3 ? '#1565C0' : '#e2e8f0' }};max-width:100px;"></div>

            {{-- Step 3: Distribusi --}}
            <div class="text-center" style="min-width:120px;">
                <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold mb-1"
                     style="width:42px;height:42px;
                            background:{{ $stepDone >= 3 ? '#1565C0' : '#e2e8f0' }};
                            color:{{ $stepDone >= 3 ? '#fff' : '#94a3b8' }};">
                    <i class="bi bi-truck"></i>
                </div>
                <div class="small fw-semibold" style="color:{{ $stepDone >= 3 ? '#1565C0' : '#94a3b8' }};">
                    Distribusi
                </div>
                <div class="text-muted" style="font-size:0.7rem;">
                    {{ $stepDone >= 3 ? 'Selesai' : 'Menunggu' }}
                </div>
            </div>

        </div>
    </div>
</div>

<div class="row g-4">

    {{-- ── Kolom Kiri ── --}}
    <div class="col-lg-7">

        {{-- Info Permintaan --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-file-earmark-text me-2"></i>Informasi Permintaan
                </h5>
            </div>
            <div class="card-body p-4">

                <div class="d-flex justify-content-between align-items-start mb-3">
                    <div>
                        <div class="text-muted small mb-1">Nomor Permintaan</div>
                        <code class="fs-5 text-primary">
                            {{ $permintaan->nomor_permintaan ?? 'DRAFT-' . $permintaan->id }}
                        </code>
                    </div>
                    @php
                        $statusConfig = [
                            'Pending'     => ['bg' => '#fef3c7', 'color' => '#92400e',  'icon' => 'bi-hourglass-split'],
                            'Approved'    => ['bg' => '#d1fae5', 'color' => '#065f46',  'icon' => 'bi-check-circle'],
                            'Rejected'    => ['bg' => '#fee2e2', 'color' => '#991b1b',  'icon' => 'bi-x-circle'],
                            'Revision'    => ['bg' => '#dbeafe', 'color' => '#1e40af',  'icon' => 'bi-arrow-repeat'],
                            'Distributed' => ['bg' => '#ede9fe', 'color' => '#5b21b6',  'icon' => 'bi-truck'],
                        ];
                        $cfg = $statusConfig[$permintaan->status_permintaan] ?? ['bg' => '#f1f5f9', 'color' => '#64748b', 'icon' => 'bi-circle'];
                    @endphp
                    <span class="badge rounded-pill px-3 py-2 fs-6"
                          style="background:{{ $cfg['bg'] }};color:{{ $cfg['color'] }};">
                        <i class="bi {{ $cfg['icon'] }} me-1"></i>
                        {{ $permintaan->status_permintaan }}
                    </span>
                </div>

                <table class="table table-borderless table-sm">
                    <tr>
                        <td class="text-muted" style="width:40%">Tanggal Pengajuan</td>
                        <td class="fw-semibold">
                            {{ \Carbon\Carbon::parse($permintaan->tanggal_permintaan)->format('d M Y, H:i') }}
                        </td>
                    </tr>
                    <tr>
                        <td class="text-muted">Prioritas</td>
                        <td>
                            @if($permintaan->prioritas == 'Mendesak')
                                <span class="badge" style="background:#fee2e2;color:#991b1b;">
                                    <i class="bi bi-exclamation-circle me-1"></i>Mendesak
                                </span>
                            @elseif($permintaan->prioritas == 'Penting')
                                <span class="badge" style="background:#fef3c7;color:#92400e;">
                                    <i class="bi bi-exclamation me-1"></i>Penting
                                </span>
                            @else
                                <span class="badge" style="background:#f1f5f9;color:#64748b;">Normal</span>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <td class="text-muted">Catatan Pemohon</td>
                        <td>{{ $permintaan->catatan ?? '—' }}</td>
                    </tr>
                </table>

            </div>
        </div>

        {{-- Daftar Item Barang --}}
        <div class="card">
            <div class="card-header py-3 d-flex justify-content-between align-items-center"
                 style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-cart3 me-2"></i>Daftar Barang Diminta
                </h5>
                <span class="badge bg-white text-primary">
                    {{ $detailItems->count() }} item
                </span>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover align-middle mb-0">
                    <thead style="background:#f8faff;">
                        <tr>
                            <th class="ps-4">Barang</th>
                            <th class="text-center">Jumlah Diminta</th>
                            <th class="text-center">Stok Tersedia</th>
                            <th>Keterangan</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($detailItems as $item)
                            <tr>
                                <td class="ps-4">
                                    <div class="fw-semibold">{{ $item->nama_barang }}</div>
                                    <div class="text-muted small">
                                        <code>{{ $item->kode_barang }}</code>
                                        &bull; {{ $item->nama_kategori }}
                                    </div>
                                </td>
                                <td class="text-center fw-bold text-primary">
                                    {{ number_format($item->jumlah) }}
                                    <div class="text-muted small fw-normal">{{ $item->satuan }}</div>
                                </td>
                                <td class="text-center">
                                    <span class="fw-semibold
                                        {{ $item->stok_tersedia <= 0 ? 'text-danger' :
                                           ($item->stok_tersedia < $item->jumlah ? 'text-warning' : 'text-success') }}">
                                        {{ number_format($item->stok_tersedia) }}
                                    </span>
                                    <div class="text-muted small">{{ $item->satuan }}</div>
                                    {{-- Peringatan stok tidak cukup --}}
                                    @if($item->stok_tersedia < $item->jumlah)
                                        <div style="font-size:0.7rem;" class="text-danger">
                                            <i class="bi bi-exclamation-triangle"></i> Stok kurang
                                        </div>
                                    @endif
                                </td>
                                <td class="text-muted small">{{ $item->keterangan ?? '—' }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" class="text-center py-4 text-muted">
                                    Tidak ada item barang.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    {{-- ── Kolom Kanan ── --}}
    <div class="col-lg-5">

        {{-- Info Pemohon --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-person me-2"></i>Data Pemohon
                </h5>
            </div>
            <div class="card-body p-4">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold"
                         style="width:50px;height:50px;font-size:1.2rem;background:#d1fae5;color:#065f46;flex-shrink:0;">
                        {{ strtoupper(substr($permintaan->nama_lengkap, 0, 1)) }}
                    </div>
                    <div>
                        <div class="fw-bold">{{ $permintaan->nama_lengkap }}</div>
                        <div class="text-muted small">{{ $permintaan->jabatan ?? 'Staff' }}</div>
                    </div>
                </div>
                <table class="table table-borderless table-sm mb-0">
                    <tr>
                        <td class="text-muted" style="width:40%">Bagian</td>
                        <td class="fw-semibold">{{ $permintaan->bagian ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">Email</td>
                        <td>{{ $permintaan->email ?? '—' }}</td>
                    </tr>
                    <tr>
                        <td class="text-muted">No. HP</td>
                        <td>{{ $permintaan->nomor_hp ?? '—' }}</td>
                    </tr>
                </table>
            </div>
        </div>

        {{-- Hasil Approval --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-check2-all me-2"></i>Hasil Approval
                </h5>
            </div>
            <div class="card-body p-4">
                @if($approval)
                    <div class="d-flex align-items-center gap-2 mb-3">
                        @php
                            $apvCfg = [
                                'Approved' => ['bg' => '#d1fae5', 'color' => '#065f46', 'icon' => 'bi-check-circle-fill'],
                                'Rejected' => ['bg' => '#fee2e2', 'color' => '#991b1b', 'icon' => 'bi-x-circle-fill'],
                                'Revision' => ['bg' => '#dbeafe', 'color' => '#1e40af', 'icon' => 'bi-arrow-repeat'],
                            ][$approval->keputusan] ?? ['bg' => '#f1f5f9', 'color' => '#64748b', 'icon' => 'bi-circle'];
                        @endphp
                        <div class="rounded-circle d-flex align-items-center justify-content-center"
                             style="width:42px;height:42px;background:{{ $apvCfg['bg'] }};flex-shrink:0;">
                            <i class="bi {{ $apvCfg['icon'] }} fs-5" style="color:{{ $apvCfg['color'] }};"></i>
                        </div>
                        <div>
                            <div class="fw-bold" style="color:{{ $apvCfg['color'] }};">
                                {{ $approval->keputusan }}
                            </div>
                            <div class="text-muted small">
                                {{ \Carbon\Carbon::parse($approval->tanggal_approval)->format('d M Y, H:i') }}
                            </div>
                        </div>
                    </div>

                    <table class="table table-borderless table-sm mb-0">
                        <tr>
                            <td class="text-muted" style="width:40%">Disetujui oleh</td>
                            <td class="fw-semibold">{{ $approval->nama_pimpinan }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Jabatan</td>
                            <td>{{ $approval->jabatan_pimpinan ?? '—' }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Catatan</td>
                            <td>{{ $approval->catatan_approval ?? '—' }}</td>
                        </tr>
                    </table>
                @else
                    <div class="text-center py-4 text-muted">
                        <div class="rounded-circle d-inline-flex align-items-center justify-content-center mb-2"
                             style="width:52px;height:52px;background:#fef3c7;">
                            <i class="bi bi-hourglass-split fs-4" style="color:#92400e;"></i>
                        </div>
                        <div class="small">Menunggu keputusan Pimpinan</div>
                    </div>
                @endif
            </div>
        </div>

        {{-- Status Distribusi --}}
        <div class="card">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-truck me-2"></i>Status Distribusi
                </h5>
            </div>
            <div class="card-body p-4">
                @if($distribusi)
                    <div class="d-flex align-items-center gap-2 mb-3">
                        <div class="rounded-circle d-flex align-items-center justify-content-center"
                             style="width:42px;height:42px;
                                    background:{{ $distribusi->status_distribusi == 'Selesai' ? '#d1fae5' : '#fef3c7' }};
                                    flex-shrink:0;">
                            <i class="bi {{ $distribusi->status_distribusi == 'Selesai' ? 'bi-check-circle-fill' : 'bi-hourglass-split' }} fs-5"
                               style="color:{{ $distribusi->status_distribusi == 'Selesai' ? '#065f46' : '#92400e' }};"></i>
                        </div>
                        <div>
                            <div class="fw-bold">{{ $distribusi->status_distribusi }}</div>
                            <div class="text-muted small">
                                {{ \Carbon\Carbon::parse($distribusi->tanggal_distribusi)->format('d M Y, H:i') }}
                            </div>
                        </div>
                    </div>
                    <table class="table table-borderless table-sm mb-0">
                        <tr>
                            <td class="text-muted" style="width:40%">Diproses oleh</td>
                            <td class="fw-semibold">{{ $distribusi->nama_admin }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Catatan</td>
                            <td>{{ $distribusi->catatan_distribusi ?? '—' }}</td>
                        </tr>
                    </table>
                @else
                    <div class="text-center py-4 text-muted">
                        <div class="rounded-circle d-inline-flex align-items-center justify-content-center mb-2"
                             style="width:52px;height:52px;background:#ede9fe;">
                            <i class="bi bi-truck fs-4" style="color:#5b21b6;"></i>
                        </div>
                        <div class="small">
                            @if($permintaan->status_permintaan == 'Approved')
                                Permintaan sudah disetujui.<br>
                                <span class="text-primary fw-semibold">
                                    Proses distribusi melalui menu Distribusi.
                                </span>
                            @elseif($permintaan->status_permintaan == 'Distributed')
                                Barang telah didistribusikan.
                            @else
                                Menunggu persetujuan Pimpinan.
                            @endif
                        </div>
                    </div>
                @endif
            </div>
        </div>

    </div>
</div>

{{-- ── Tombol Bawah ── --}}
<div class="mt-4">
    <a href="{{ route('permintaan.index') }}" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left me-1"></i> Kembali ke Daftar
    </a>
    @if($permintaan->status_permintaan == 'Approved')
        <a href="{{ route('distribusi.index') }}" class="btn btn-primary ms-2">
            <i class="bi bi-truck me-1"></i> Proses Distribusi
        </a>
    @endif
</div>

@endsection