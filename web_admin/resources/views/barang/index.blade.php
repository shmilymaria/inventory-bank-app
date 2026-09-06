@extends('layouts.app')

@section('title', 'Data Barang')
@section('page-title', 'Data Barang')

@section('content')

{{-- ── Header ── --}}
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-0">Data Barang</h4>
        <small class="text-muted">Kelola seluruh data barang operasional</small>
    </div>
    <a href="{{ route('barang.create') }}" class="btn btn-primary">
        <i class="bi bi-plus-circle me-1"></i> Tambah Barang
    </a>
</div>

{{-- ── Statistik Ringkas ── --}}
<div class="row g-3 mb-4">

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#dbeafe;">
                    <i class="bi bi-box-seam fs-4" style="color:#1565C0;"></i>
                </div>
                <div>
                    <div class="text-muted small">Total Barang</div>
                    <div class="fw-bold fs-4">{{ $barang->total() }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card card-stat">
            <div class="card-body d-flex align-items-center gap-3">
                <div class="rounded-3 p-3" style="background:#d1fae5;">
                    <i class="bi bi-check-circle fs-4" style="color:#065f46;"></i>
                </div>
                <div>
                    <div class="text-muted small">Tersedia</div>
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('barang')->where('status_barang','Tersedia')->count() }}
                    </div>
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
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('barang')->where('status_barang','Stok Menipis')->count() }}
                    </div>
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
                    <div class="text-muted small">Habis</div>
                    <div class="fw-bold fs-4">
                        {{ \Illuminate\Support\Facades\DB::table('barang')->where('status_barang','Habis')->count() }}
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>

{{-- ── Filter & Search ── --}}
<div class="card mb-4">
    <div class="card-body">
        <form method="GET" action="{{ route('barang.index') }}" class="row g-2 align-items-end">

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
                    <option value="Tersedia"    {{ request('status') == 'Tersedia'    ? 'selected' : '' }}>Tersedia</option>
                    <option value="Stok Menipis"{{ request('status') == 'Stok Menipis'? 'selected' : '' }}>Stok Menipis</option>
                    <option value="Habis"       {{ request('status') == 'Habis'       ? 'selected' : '' }}>Habis</option>
                </select>
            </div>

            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-fill">
                    <i class="bi bi-funnel"></i> Filter
                </button>
                <a href="{{ route('barang.index') }}" class="btn btn-outline-secondary flex-fill">
                    Reset
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
                        <th style="width:60px;">Foto</th>
                        <th>Kode</th>
                        <th>Nama Barang</th>
                        <th>Kategori</th>
                        <th class="text-center">Stok</th>
                        <th class="text-center">Min. Stok</th>
                        <th>Satuan</th>
                        <th>Lokasi</th>
                        <th class="text-center">Status</th>
                        <th class="text-center pe-4">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($barang as $index => $item)
                        <tr>
                            <td class="ps-4 text-muted">
                                {{ ($barang->currentPage() - 1) * $barang->perPage() + $loop->iteration }}
                            </td>
                            <td>
                                <img src="{{ $item->gambar ? asset('storage/' . $item->gambar) : 'https://placehold.co/44x44/e3f2fd/1565C0?text=%20' }}"
                                     class="rounded border" style="width:44px;height:44px;object-fit:cover;">
                            </td>
                            <td>
                                <code class="text-primary">{{ $item->kode_barang }}</code>
                            </td>
                            <td class="fw-semibold">{{ $item->nama_barang }}</td>
                            <td class="text-muted">{{ $item->nama_kategori }}</td>
                            <td class="text-center">
                                <span class="fw-bold {{ $item->stok <= 0 ? 'text-danger' : ($item->stok <= $item->stok_minimum ? 'text-warning' : 'text-success') }}">
                                    {{ number_format($item->stok) }}
                                </span>
                            </td>
                            <td class="text-center text-muted">{{ number_format($item->stok_minimum) }}</td>
                            <td class="text-muted">{{ $item->satuan }}</td>
                            <td class="text-muted">{{ $item->lokasi_penyimpanan ?? '-' }}</td>
                            <td class="text-center">
                                @if($item->status_barang == 'Tersedia')
                                    <span class="badge badge-tersedia px-3 py-2 rounded-pill">
                                        <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Tersedia
                                    </span>
                                @elseif($item->status_barang == 'Stok Menipis')
                                    <span class="badge badge-menipis px-3 py-2 rounded-pill">
                                        <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Stok Menipis
                                    </span>
                                @else
                                    <span class="badge badge-habis px-3 py-2 rounded-pill">
                                        <i class="bi bi-circle-fill me-1" style="font-size:0.5rem;"></i>Habis
                                    </span>
                                @endif
                            </td>
                            <td class="text-center pe-4">
                                <div class="d-flex justify-content-center gap-1">
                                    {{-- Detail --}}
                                    <a href="{{ route('barang.show', $item->id) }}"
                                       class="btn btn-sm btn-outline-info"
                                       title="Detail">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    {{-- Edit --}}
                                    <a href="{{ route('barang.edit', $item->id) }}"
                                       class="btn btn-sm btn-outline-primary"
                                       title="Edit">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    {{-- Hapus --}}
                                    <button type="button"
                                            class="btn btn-sm btn-outline-danger"
                                            title="Hapus"
                                            data-bs-toggle="modal"
                                            data-bs-target="#modalHapus"
                                            data-id="{{ $item->id }}"
                                            data-nama="{{ $item->nama_barang }}">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="11" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                Tidak ada data barang ditemukan.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        {{-- Pagination --}}
        @if($barang->hasPages())
            <div class="px-4 py-3 border-top">
                {{ $barang->links() }}
            </div>
        @endif

    </div>
</div>

{{-- ── Modal Konfirmasi Hapus ── --}}
<div class="modal fade" id="modalHapus" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">Konfirmasi Hapus</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-4 text-center">
                <div class="mb-3">
                    <div class="rounded-circle d-inline-flex align-items-center justify-content-center"
                         style="width:64px;height:64px;background:#fee2e2;">
                        <i class="bi bi-trash3 fs-3" style="color:#dc3545;"></i>
                    </div>
                </div>
                <p class="mb-1">Anda yakin ingin menghapus barang:</p>
                <p class="fw-bold fs-5" id="namaBarangHapus">—</p>
                <p class="text-muted small">Tindakan ini tidak dapat dibatalkan.</p>
            </div>
            <div class="modal-footer border-0 pt-0 justify-content-center gap-2">
                <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
                    Batal
                </button>
                <form id="formHapus" method="POST">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-danger px-4">
                        <i class="bi bi-trash me-1"></i> Ya, Hapus
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

@endsection

@push('scripts')
<script>
    // Isi data modal hapus
    document.getElementById('modalHapus').addEventListener('show.bs.modal', function (event) {
        const btn  = event.relatedTarget;
        const id   = btn.getAttribute('data-id');
        const nama = btn.getAttribute('data-nama');
        document.getElementById('namaBarangHapus').textContent = nama;
        document.getElementById('formHapus').action = '/barang/' + id;
    });
</script>
@endpush