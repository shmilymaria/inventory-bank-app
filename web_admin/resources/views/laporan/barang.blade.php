@extends('layouts.app')

@section('title', 'Laporan Barang')
@section('page-title', 'Laporan')

@section('content')

<nav aria-label="breadcrumb" class="mb-4">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">
            <a href="{{ route('laporan.index') }}" class="text-decoration-none">Laporan</a>
        </li>
        <li class="breadcrumb-item active">Laporan Barang</li>
    </ol>
</nav>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Laporan Barang</h4>
        <small class="text-muted">Status stok dan kondisi seluruh barang inventori</small>
    </div>
    <button onclick="window.print()" class="btn btn-outline-primary">
        <i class="bi bi-printer me-1"></i> Cetak Laporan
    </button>
</div>

{{-- ── Ringkasan Per Kategori ── --}}
<div class="card mb-4">
    <div class="card-header py-3" style="background:#1565C0;">
        <h6 class="mb-0 text-white fw-semibold">
            <i class="bi bi-pie-chart me-2"></i>Ringkasan Per Kategori
        </h6>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4">Kategori</th>
                        <th class="text-center">Total Barang</th>
                        <th class="text-center">Total Stok</th>
                        <th class="text-center">Tersedia</th>
                        <th class="text-center">Stok Menipis</th>
                        <th class="text-center">Habis</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($ringkasanKategori as $kat)
                        <tr>
                            <td class="ps-4 fw-semibold">{{ $kat->nama_kategori }}</td>
                            <td class="text-center">{{ $kat->total_barang }}</td>
                            <td class="text-center fw-bold" style="color:#1565C0;">
                                {{ number_format($kat->total_stok) }}
                            </td>
                            <td class="text-center">
                                <span class="badge" style="background:#d1fae5;color:#065f46;">
                                    {{ $kat->tersedia }}
                                </span>
                            </td>
                            <td class="text-center">
                                <span class="badge" style="background:#fef3c7;color:#92400e;">
                                    {{ $kat->menipis }}
                                </span>
                            </td>
                            <td class="text-center">
                                <span class="badge" style="background:#fee2e2;color:#991b1b;">
                                    {{ $kat->habis }}
                                </span>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-4 text-muted">Belum ada data kategori.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

{{-- ── Filter ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('laporan.barang') }}" class="row g-2 align-items-end">
            <div class="col-md-4">
                <label class="form-label small text-muted mb-1">Cari Barang</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                    <input type="text" name="search" class="form-control"
                           placeholder="Nama atau kode barang..."
                           value="{{ request('search') }}">
                </div>
            </div>
            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Kategori</label>
                <select name="kategori" class="form-select">
                    <option value="">Semua Kategori</option>
                    @foreach($kategoris as $kat)
                        <option value="{{ $kat->id }}"
                            {{ request('kategori') == $kat->id ? 'selected' : '' }}>
                            {{ $kat->nama_kategori }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label small text-muted mb-1">Status</label>
                <select name="status" class="form-select">
                    <option value="">Semua Status</option>
                    <option value="Tersedia"     {{ request('status') == 'Tersedia'     ? 'selected' : '' }}>Tersedia</option>
                    <option value="Stok Menipis" {{ request('status') == 'Stok Menipis' ? 'selected' : '' }}>Stok Menipis</option>
                    <option value="Habis"        {{ request('status') == 'Habis'        ? 'selected' : '' }}>Habis</option>
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('laporan.barang') }}" class="btn btn-outline-secondary flex-fill">
                    Reset
                </a>
            </div>
        </form>
    </div>
</div>

{{-- ── Tabel Barang ── --}}
<div class="card">
    <div class="card-header py-3 d-flex justify-content-between align-items-center"
         style="background:#1565C0;">
        <h6 class="mb-0 text-white fw-semibold">
            <i class="bi bi-table me-2"></i>Daftar Barang
        </h6>
        <span class="badge bg-white text-primary">{{ $barang->total() }} barang</span>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead style="background:#f8faff;">
                    <tr>
                        <th class="ps-4" style="width:45px;">No</th>
                        <th>Kode</th>
                        <th>Nama Barang</th>
                        <th>Kategori</th>
                        <th class="text-center">Stok</th>
                        <th class="text-center">Min. Stok</th>
                        <th>Satuan</th>
                        <th>Lokasi</th>
                        <th class="text-center pe-4">Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($barang as $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($barang->currentPage() - 1) * $barang->perPage() + $loop->iteration }}
                            </td>
                            <td><code class="text-primary">{{ $item->kode_barang }}</code></td>
                            <td class="fw-semibold">{{ $item->nama_barang }}</td>
                            <td class="text-muted small">{{ $item->nama_kategori }}</td>
                            <td class="text-center fw-bold
                                {{ $item->stok <= 0 ? 'text-danger' : ($item->stok <= $item->stok_minimum ? 'text-warning' : 'text-success') }}">
                                {{ number_format($item->stok) }}
                            </td>
                            <td class="text-center text-muted">{{ number_format($item->stok_minimum) }}</td>
                            <td class="text-muted small">{{ $item->satuan }}</td>
                            <td class="text-muted small">{{ $item->lokasi_penyimpanan ?? '—' }}</td>
                            <td class="text-center pe-4">
                                @if($item->status_barang == 'Tersedia')
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#d1fae5;color:#065f46;">Tersedia</span>
                                @elseif($item->status_barang == 'Stok Menipis')
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#fef3c7;color:#92400e;">Stok Menipis</span>
                                @else
                                    <span class="badge rounded-pill px-3 py-2"
                                          style="background:#fee2e2;color:#991b1b;">Habis</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Tidak ada data barang.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($barang->hasPages())
            <div class="px-4 py-3 border-top">{{ $barang->links() }}</div>
        @endif
    </div>
</div>

@endsection