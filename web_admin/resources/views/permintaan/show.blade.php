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

{{-- ── Timeline Status (4 tahap: Diajukan → Verifikasi Admin → Disposisi Pimpinan → Distribusi) ── --}}
@php
    $statusNow  = $permintaan->status_permintaan;
    $isReturned = in_array($statusNow, ['Rejected', 'Revision']);

    // Pada tahap mana permintaan dikembalikan? (Admin / Pimpinan)
    $tahapKembali = null;
    if ($isReturned) {
        $rowKembali   = $riwayatApproval->first(fn($r) => in_array($r->keputusan, ['Rejected', 'Revision']));
        $tahapKembali = $rowKembali->tahap ?? 'Pimpinan';
    }
    $stateKembali = $statusNow === 'Rejected' ? 'rejected' : 'revision';

    $stepAdmin = match(true) {
        $statusNow === 'Pending'                    => 'current',
        $isReturned && $tahapKembali === 'Admin'    => $stateKembali,
        default                                     => 'done',
    };
    $stepPimpinan = match(true) {
        $statusNow === 'Pending'                    => 'pending',
        $statusNow === 'Verified'                   => 'current',
        $isReturned && $tahapKembali === 'Admin'    => 'pending',
        $isReturned && $tahapKembali === 'Pimpinan' => $stateKembali,
        default                                     => 'done',
    };
    $stepDistribusi = match($statusNow) {
        'Distributed' => 'done',
        'Approved'    => 'current',
        default       => 'pending',
    };

    $subText = [
        'done' => 'Selesai', 'current' => 'Menunggu', 'pending' => '—',
        'rejected' => 'Rejected', 'revision' => 'Revision',
    ];
    $stateColor = [
        'done' => '#1565C0', 'current' => '#f59e0b', 'pending' => '#e2e8f0',
        'rejected' => '#ef4444', 'revision' => '#3b82f6',
    ];

    $steps = [
        ['label' => 'Diajukan',           'icon' => 'bi-file-earmark-text', 'state' => 'done',          'sub' => 'Pending'],
        ['label' => 'Verifikasi Admin',   'icon' => 'bi-person-check',      'state' => $stepAdmin,      'sub' => $subText[$stepAdmin]],
        ['label' => 'Disposisi Pimpinan', 'icon' => 'bi-patch-check',       'state' => $stepPimpinan,   'sub' => $subText[$stepPimpinan]],
        ['label' => 'Distribusi',         'icon' => 'bi-truck',             'state' => $stepDistribusi, 'sub' => $subText[$stepDistribusi]],
    ];
    $stateIcon = ['rejected' => 'bi-x-lg', 'revision' => 'bi-arrow-repeat'];
@endphp

<div class="card mb-4">
    <div class="card-body py-3">
        <div class="d-flex align-items-center justify-content-center gap-0 flex-wrap">
            @foreach($steps as $i => $st)
                @php $warna = $stateColor[$st['state']]; $aktif = $st['state'] !== 'pending'; @endphp

                <div class="text-center" style="min-width:120px;">
                    <div class="rounded-circle d-inline-flex align-items-center justify-content-center fw-bold mb-1"
                         style="width:42px;height:42px;background:{{ $warna }};color:{{ $aktif ? '#fff' : '#94a3b8' }};">
                        <i class="bi {{ $stateIcon[$st['state']] ?? $st['icon'] }}"></i>
                    </div>
                    <div class="small fw-semibold" style="color:{{ $aktif ? $warna : '#94a3b8' }};">
                        {{ $st['label'] }}
                    </div>
                    <div class="text-muted" style="font-size:0.7rem;">{{ $st['sub'] }}</div>
                </div>

                @if(!$loop->last)
                    <div class="flex-grow-1 mx-2"
                         style="height:3px;max-width:80px;background:{{ $st['state'] === 'done' ? '#1565C0' : '#e2e8f0' }};"></div>
                @endif
            @endforeach
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
                            'Verified'    => ['bg' => '#cffafe', 'color' => '#155e75',  'icon' => 'bi-patch-check'],
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

        {{-- Form Verifikasi Admin (hanya saat status Pending) --}}
        @if($permintaan->status_permintaan == 'Pending')
        <div class="card mb-4" style="border:2px solid #f59e0b;">
            <div class="card-header py-3" style="background:#f59e0b;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-person-check me-2"></i>Verifikasi Admin
                </h5>
            </div>
            <div class="card-body p-4">
                <p class="small text-muted mb-3">
                    Periksa permintaan ini terlebih dahulu. Jika <strong>Approved</strong>, permintaan
                    diteruskan ke Pimpinan untuk disposisi. Jika <strong>Rejected</strong> /
                    <strong>Revision</strong>, permintaan dikembalikan ke User beserta catatan Anda.
                </p>

                <form method="POST" action="{{ route('permintaan.verifikasi', $permintaan->id) }}"
                      onsubmit="return konfirmasiVerifikasi(this);">
                    @csrf

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">Keputusan <span class="text-danger">*</span></label>
                        <div class="d-flex gap-2 flex-wrap">
                            @foreach([
                                'Approved' => ['Approved (Teruskan ke Pimpinan)', 'success'],
                                'Revision' => ['Revision (Minta Revisi)',         'primary'],
                                'Rejected' => ['Rejected (Tolak)',                'danger'],
                            ] as $val => [$lbl, $clr])
                                <input type="radio" class="btn-check" name="keputusan"
                                       id="kep_{{ $val }}" value="{{ $val }}"
                                       {{ old('keputusan') == $val ? 'checked' : '' }} required>
                                <label class="btn btn-outline-{{ $clr }} btn-sm" for="kep_{{ $val }}">{{ $lbl }}</label>
                            @endforeach
                        </div>
                        @error('keputusan') <div class="text-danger small mt-1">{{ $message }}</div> @enderror
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-semibold">
                            Catatan <span class="text-muted fw-normal">(wajib untuk Rejected / Revision)</span>
                        </label>
                        <textarea name="catatan_approval" rows="3" maxlength="500"
                                  class="form-control @error('catatan_approval') is-invalid @enderror"
                                  placeholder="Tulis alasan / hal yang perlu diperbaiki User...">{{ old('catatan_approval') }}</textarea>
                        @error('catatan_approval') <div class="invalid-feedback">{{ $message }}</div> @enderror
                    </div>

                    <button type="submit" class="btn btn-warning fw-semibold">
                        <i class="bi bi-send-check me-1"></i> Simpan Keputusan
                    </button>
                </form>
            </div>
        </div>

        <script>
            function konfirmasiVerifikasi(form) {
                const k = form.querySelector('input[name=keputusan]:checked');
                if (!k) return true; // biar validasi 'required' browser yang menangani
                const catatan = form.querySelector('textarea[name=catatan_approval]').value.trim();
                if (k.value !== 'Approved' && catatan === '') {
                    alert('Catatan wajib diisi untuk keputusan Rejected / Revision.');
                    return false;
                }
                const teks = {
                    Approved: 'Teruskan permintaan ini ke Pimpinan?',
                    Rejected: 'Tolak permintaan ini dan kembalikan ke User?',
                    Revision: 'Kembalikan permintaan ini ke User untuk direvisi?',
                }[k.value];
                return confirm(teks);
            }
        </script>
        @endif

        {{-- Riwayat Keputusan (tahap Admin & Pimpinan) --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-check2-all me-2"></i>Riwayat Keputusan
                </h5>
            </div>
            <div class="card-body p-4">
                @forelse($riwayatApproval as $apv)
                    @php
                        $apvCfg = [
                            'Approved' => ['bg' => '#d1fae5', 'color' => '#065f46', 'icon' => 'bi-check-circle-fill'],
                            'Rejected' => ['bg' => '#fee2e2', 'color' => '#991b1b', 'icon' => 'bi-x-circle-fill'],
                            'Revision' => ['bg' => '#dbeafe', 'color' => '#1e40af', 'icon' => 'bi-arrow-repeat'],
                        ][$apv->keputusan] ?? ['bg' => '#f1f5f9', 'color' => '#64748b', 'icon' => 'bi-circle'];
                    @endphp
                    <div class="d-flex gap-3 {{ $loop->last ? '' : 'pb-3 mb-3 border-bottom' }}">
                        <div class="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0"
                             style="width:42px;height:42px;background:{{ $apvCfg['bg'] }};">
                            <i class="bi {{ $apvCfg['icon'] }} fs-5" style="color:{{ $apvCfg['color'] }};"></i>
                        </div>
                        <div class="flex-grow-1">
                            <div class="d-flex justify-content-between flex-wrap gap-1">
                                <div class="fw-bold" style="color:{{ $apvCfg['color'] }};">
                                    {{ $apv->keputusan }}
                                    <span class="badge bg-light text-dark border ms-1 fw-normal">
                                        Tahap {{ $apv->tahap }}
                                    </span>
                                </div>
                                <div class="text-muted small">
                                    {{ \Carbon\Carbon::parse($apv->tanggal_approval)->format('d M Y, H:i') }}
                                </div>
                            </div>
                            <div class="small mt-1">
                                <span class="text-muted">Oleh:</span>
                                <span class="fw-semibold">{{ $apv->nama_pengambil }}</span>
                                @if($apv->jabatan_pengambil)
                                    <span class="text-muted">· {{ $apv->jabatan_pengambil }}</span>
                                @endif
                            </div>
                            <div class="small mt-1">
                                <span class="text-muted">Catatan:</span>
                                {{ $apv->catatan_approval ?: '—' }}
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="text-center py-4 text-muted">
                        <div class="rounded-circle d-inline-flex align-items-center justify-content-center mb-2"
                             style="width:52px;height:52px;background:#fef3c7;">
                            <i class="bi bi-hourglass-split fs-4" style="color:#92400e;"></i>
                        </div>
                        <div class="small">Belum ada keputusan. Menunggu verifikasi Admin.</div>
                    </div>
                @endforelse
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
                            @elseif($permintaan->status_permintaan == 'Pending')
                                Menunggu verifikasi Admin.
                            @elseif($permintaan->status_permintaan == 'Verified')
                                Menunggu persetujuan Pimpinan.
                            @else
                                Permintaan dikembalikan ke User (tidak diproses).
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