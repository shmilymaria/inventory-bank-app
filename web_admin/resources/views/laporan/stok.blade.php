@extends('layouts.app')

@section('title', 'Laporan Riwayat Stok')
@section('page-title', 'Laporan')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('laporan.index') }}" class="text-decoration-none">Laporan</a>
        </li>
        <li class="breadcrumb-item active">Laporan Riwayat Stok</li>
    </ol>
</nav>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Laporan Riwayat Stok</h4>
        <small class="text-muted">Histori seluruh pergerakan stok barang (masuk & keluar)</small>
    </div>
    <button onclick="window.print()" class="btn btn-outline-primary">
        <i class="bi bi-printer me-1"></i> Cetak Laporan
    </button>
</div>

{{-- ── Statistik Ringkas ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #1565C0;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-arrow-left-right fs-4" style="color:#1565C0;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Transaksi</div>
                    <div class="fw-bold fs-3">{{ number_format($ringkasan->total_transaksi) }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #10b981;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-arrow-down-circle fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Stok Masuk</div>
                    <div class="fw-bold fs-3 text-success">
                        {{ number_format($ringkasan->total_masuk) }}
                    </div>
                    <div class="text-muted" style="font-size:0.72rem;">unit (sesuai filter)</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card card-stat" style="border-left:4px solid #ef4444;">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#fee2e2;">
                    <i class="bi bi-arrow-up-circle fs-4" style="color:#991b1b;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Stok Keluar</div>
                    <div class="fw-bold fs-3 text-danger">
                        {{ number_format($ringkasan->total_keluar) }}
                    </div>
                    <div class="text-muted" style="font-size:0.72rem;">unit (sesuai filter)</div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ── Filter ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('laporan.stok') }}" class="row g-2 align-items-end">

            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Barang</label>
                <select name="barang_id" class="form-select">
                    <option value="">Semua Barang</option>
                    @foreach($semuaBarang as $brg)
                        <option value="{{ $brg->id }}"
                            {{ request('barang_id') == $brg->id ? 'selected' : '' }}>
                            {{ $brg->nama_barang }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div class="col-md-2">
                <label class="form-label small text-muted mb-1">Jenis Transaksi</label>
                <select name="jenis" class="form-select">
                    <option value="">Semua</option>
                    <option value="Masuk"  {{ request('jenis') == 'Masuk'  ? 'selected' : '' }}>Masuk</option>
                    <option value="Keluar" {{ request('jenis') == 'Keluar' ? 'selected' : '' }}>Keluar</option>
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

            <div class="col-md-3 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('laporan.stok') }}" class="btn btn-outline-secondary flex-fill">
                    Reset
                </a>
            </div>

        </form>
    </div>
</div>

{{-- ── Tabel Riwayat Stok ── --}}
<div class="card">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#1565C0;">
        <h6 class="mb-0 text-white fw-semibold">
            <i class="bi bi-table me-2"></i>Detail Riwayat Stok
        </h6>
        <span class="badge bg-white text-primary">{{ $riwayat->total() }} transaksi</span>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4" style="width:45px;">No</th>
                        <th>Barang</th>
                        <th>Kategori</th>
                        <th class="text-center">Jenis</th>
                        <th class="text-center">Jumlah</th>
                        <th class="text-center">Stok Sebelum</th>
                        <th class="text-center">Stok Sesudah</th>
                        <th>Keterangan</th>
                        <th class="pe-4">Tanggal</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($riwayat as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($riwayat->currentPage() - 1) * $riwayat->perPage() + $loop->iteration }}
                            </td>

                            <td>
                                <div class="fw-semibold">{{ $item->nama_barang }}</div>
                                <code class="text-muted" style="font-size:0.75rem;">
                                    {{ $item->kode_barang }}
                                </code>
                            </td>

                            <td class="text-muted small">{{ $item->nama_kategori }}</td>

                            {{-- Badge Jenis Transaksi --}}
                            <td class="text-center">
                                @if($item->jenis_transaksi == 'Masuk')
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#d1fae5;color:#065f46;">
                                        <i class="bi bi-arrow-down-circle me-1"></i>Masuk
                                    </span>
                                @else
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#fee2e2;color:#991b1b;">
                                        <i class="bi bi-arrow-up-circle me-1"></i>Keluar
                                    </span>
                                @endif
                            </td>

                            {{-- Jumlah dengan tanda +/- --}}
                            <td class="text-center fw-bold
                                {{ $item->jenis_transaksi == 'Masuk' ? 'text-success' : 'text-danger' }}">
                                {{ $item->jenis_transaksi == 'Masuk' ? '+' : '-' }}{{ number_format($item->jumlah) }}
                                <div class="text-muted fw-normal small">{{ $item->satuan }}</div>
                            </td>

                            <td class="text-center text-muted">
                                {{ number_format($item->stok_sebelum) }}
                                <div class="text-muted" style="font-size:0.72rem;">{{ $item->satuan }}</div>
                            </td>

                            <td class="text-center fw-semibold">
                                {{ number_format($item->stok_sesudah) }}
                                <div class="text-muted fw-normal" style="font-size:0.72rem;">{{ $item->satuan }}</div>
                            </td>

                            <td class="text-muted small">
                                {{ $item->keterangan ?? '—' }}
                            </td>

                            <td class="text-muted small pe-4">
                                {{ \Carbon\Carbon::parse($item->created_at)->format('d M Y') }}
                                <div style="font-size:0.72rem;">
                                    {{ \Carbon\Carbon::parse($item->created_at)->format('H:i') }}
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Tidak ada data riwayat stok ditemukan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        @if($riwayat->hasPages())
            <div class="px-4 py-3 border-top">
                {{ $riwayat->links() }}
            </div>
        @endif

    </div>
</div>

@endsection