@extends('layouts.app')

@section('title', 'Proses Distribusi')
@section('page-title', 'Distribusi Barang')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('distribusi.index') }}" class="text-decoration-none">Distribusi Barang</a>
        </li>
        <li class="breadcrumb-item active">Proses Distribusi</li>
    </ol>
</nav>

{{-- ── Peringatan stok tidak cukup ── --}}
@if(!$stokCukup)
    <div class="alert alert-warning alert-dismissible fade show mb-4">
        <i class="bi bi-exclamation-triangle me-2"></i>
        <strong>Perhatian!</strong> Terdapat barang yang stoknya tidak mencukupi permintaan.
        Tinjau daftar item di bawah sebelum memproses distribusi.
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
@endif

<div class="row g-4">

    {{-- ── Kolom Kiri: Info Permintaan + Item ── --}}
    <div class="col-lg-8">

        {{-- Info Permintaan --}}
        <div class="card mb-4">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-file-earmark-text me-2"></i>Informasi Permintaan
                </h5>
            </div>
            <div class="card-body p-4">
                <div class="row g-3">
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Nomor Permintaan</div>
                        <code class="fs-5 text-primary">
                            {{ $permintaan->nomor_permintaan ?? 'DRAFT-' . $permintaan->id }}
                        </code>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Prioritas</div>
                        @if($permintaan->prioritas == 'Mendesak')
                            <span class="badge px-3 py-2" style="background:#fee2e2;color:#991b1b;">
                                <i class="bi bi-exclamation-circle me-1"></i>Mendesak
                            </span>
                        @elseif($permintaan->prioritas == 'Penting')
                            <span class="badge px-3 py-2" style="background:#fef3c7;color:#92400e;">
                                <i class="bi bi-exclamation me-1"></i>Penting
                            </span>
                        @else
                            <span class="badge px-3 py-2" style="background:#f1f5f9;color:#64748b;">Normal</span>
                        @endif
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Pemohon</div>
                        <div class="fw-semibold">{{ $permintaan->nama_lengkap }}</div>
                        <div class="text-muted small">{{ $permintaan->bagian }} — {{ $permintaan->jabatan }}</div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small mb-1">Tanggal Pengajuan</div>
                        <div class="fw-semibold">
                            {{ \Carbon\Carbon::parse($permintaan->tanggal_permintaan)->format('d M Y, H:i') }}
                        </div>
                    </div>
                    @if($permintaan->catatan)
                        <div class="col-12">
                            <div class="text-muted small mb-1">Catatan Pemohon</div>
                            <div class="p-2 rounded-3" style="background:#f8f9fa;">
                                {{ $permintaan->catatan }}
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        {{-- Daftar Item Barang --}}
        <div class="card mb-4">
            <div class="card-header py-3 d-flex justify-content-between align-items-center"
                 style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-cart3 me-2"></i>Daftar Barang yang Akan Didistribusikan
                </h5>
                <span class="badge bg-white text-primary">{{ $detailItems->count() }} item</span>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover align-middle mb-0">
                    <thead style="background:#f8faff;">
                        <tr>
                            <th class="ps-4">Barang</th>
                            <th class="text-center">Diminta</th>
                            <th class="text-center">Stok Tersedia</th>
                            <th class="text-center">Kecukupan</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($detailItems as $item)
                            @php $cukup = $item->stok_tersedia >= $item->jumlah; @endphp
                            <tr class="{{ !$cukup ? 'table-danger' : '' }}">
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
                                    <span class="fw-bold {{ $cukup ? 'text-success' : 'text-danger' }}">
                                        {{ number_format($item->stok_tersedia) }}
                                    </span>
                                    <div class="text-muted small">{{ $item->satuan }}</div>
                                </td>
                                <td class="text-center">
                                    @if($cukup)
                                        <span class="badge" style="background:#d1fae5;color:#065f46;">
                                            <i class="bi bi-check-circle me-1"></i>Cukup
                                        </span>
                                    @else
                                        <span class="badge" style="background:#fee2e2;color:#991b1b;">
                                            <i class="bi bi-x-circle me-1"></i>Kurang
                                            ({{ $item->jumlah - $item->stok_tersedia }} {{ $item->satuan }})
                                        </span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    {{-- ── Kolom Kanan: Approval + Form Distribusi ── --}}
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
                        Data approval tidak ditemukan.
                    </div>
                @endif
            </div>
        </div>

        {{-- Form Konfirmasi Distribusi --}}
        <div class="card">
            <div class="card-header py-3" style="background:#1565C0;">
                <h5 class="mb-0 text-white fw-semibold">
                    <i class="bi bi-truck me-2"></i>Konfirmasi Distribusi
                </h5>
            </div>
            <div class="card-body p-4">

                @if(!$stokCukup)
                    <div class="alert py-2 mb-3" style="background:#fee2e2;border:1px solid #fca5a5;">
                        <small style="color:#991b1b;">
                            <i class="bi bi-x-circle me-1"></i>
                            Distribusi tidak dapat diproses karena stok beberapa barang tidak mencukupi.
                        </small>
                    </div>
                @else
                    <div class="alert py-2 mb-3" style="background:#d1fae5;border:1px solid #6ee7b7;">
                        <small style="color:#065f46;">
                            <i class="bi bi-check-circle me-1"></i>
                            Semua stok mencukupi. Distribusi siap diproses.
                        </small>
                    </div>
                @endif

                <form method="POST"
                      action="{{ route('distribusi.store', $permintaan->id) }}"
                      id="formDistribusi">
                    @csrf

                    <div class="mb-3">
                        <label class="form-label">Catatan Distribusi</label>
                        <textarea name="catatan_distribusi" rows="3"
                                  class="form-control"
                                  placeholder="Catatan tambahan (opsional)...">{{ old('catatan_distribusi') }}</textarea>
                    </div>

                    <div class="mb-3 p-3 rounded-3" style="background:#f8f9fa;font-size:0.82rem;">
                        <div class="text-muted mb-1">
                            <i class="bi bi-info-circle me-1"></i>Setelah distribusi diproses:
                        </div>
                        <ul class="mb-0 ps-3 text-muted">
                            <li>Stok barang akan otomatis berkurang</li>
                            <li>Status permintaan berubah menjadi <strong>Distributed</strong></li>
                            <li>Notifikasi dikirim ke pemohon</li>
                        </ul>
                    </div>

                    <div class="d-grid gap-2">
                        <button type="button"
                                class="btn btn-primary"
                                {{ !$stokCukup ? 'disabled' : '' }}
                                data-bs-toggle="modal"
                                data-bs-target="#modalKonfirmasi">
                            <i class="bi bi-truck me-1"></i> Proses Distribusi
                        </button>
                        <a href="{{ route('distribusi.index') }}"
                           class="btn btn-outline-secondary">
                            Batal
                        </a>
                    </div>

                </form>

            </div>
        </div>

    </div>

</div>

{{-- ── Modal Konfirmasi ── --}}
<div class="modal fade" id="modalKonfirmasi" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">Konfirmasi Distribusi</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-4 text-center">
                <div class="mb-3">
                    <div class="rounded-circle d-inline-flex align-items-center justify-content-center"
                         style="width:64px;height:64px;background:#dbeafe;">
                        <i class="bi bi-truck fs-3" style="color:#1565C0;"></i>
                    </div>
                </div>
                <p class="mb-1">Anda akan memproses distribusi untuk permintaan:</p>
                <p class="fw-bold fs-5">
                    {{ $permintaan->nomor_permintaan ?? 'DRAFT-' . $permintaan->id }}
                </p>
                <p class="text-muted small">
                    Stok <strong>{{ $detailItems->count() }} barang</strong> akan dikurangi secara otomatis.<br>
                    Tindakan ini tidak dapat dibatalkan.
                </p>
            </div>
            <div class="modal-footer border-0 pt-0 justify-content-center gap-2">
                <button type="button" class="btn btn-outline-secondary px-4"
                        data-bs-dismiss="modal">Batal</button>
                <button type="button" class="btn btn-primary px-4"
                        onclick="document.getElementById('formDistribusi').submit()">
                    <i class="bi bi-truck me-1"></i> Ya, Proses Sekarang
                </button>
            </div>
        </div>
    </div>
</div>

@endsection