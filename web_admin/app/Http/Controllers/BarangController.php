<?php

namespace App\Http\Controllers;

use App\Models\Barang;
use App\Models\KategoriBarang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BarangController extends Controller
{
    // ----------------------------------------------------------------
    // INDEX — Daftar seluruh barang
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $query = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'barang.*',
                'kategori_barang.nama_kategori'
            );

        // Filter pencarian
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('barang.nama_barang', 'like', "%{$search}%")
                  ->orWhere('barang.kode_barang', 'like', "%{$search}%");
            });
        }

        // Filter status
        if ($request->filled('status')) {
            $query->where('barang.status_barang', $request->status);
        }

        // Filter kategori
        if ($request->filled('kategori')) {
            $query->where('barang.kategori_id', $request->kategori);
        }

        $barang    = $query->orderBy('barang.id', 'desc')->paginate(10)->withQueryString();
        $kategoris = KategoriBarang::orderBy('nama_kategori')->get();

        return view('barang.index', compact('barang', 'kategoris'));
    }

    // ----------------------------------------------------------------
    // CREATE — Form tambah barang
    // ----------------------------------------------------------------
    public function create()
    {
        $kategoris = KategoriBarang::orderBy('nama_kategori')->get();
        return view('barang.create', compact('kategoris'));
    }

    // ----------------------------------------------------------------
    // STORE — Simpan barang baru
    // ----------------------------------------------------------------
    public function store(Request $request)
    {
        $request->validate([
            'kategori_id'       => 'required|exists:kategori_barang,id',
            'kode_barang'       => 'required|string|max:50|unique:barang,kode_barang',
            'nama_barang'       => 'required|string|max:150',
            'stok'              => 'required|integer|min:0',
            'stok_minimum'      => 'required|integer|min:0',
            'satuan'            => 'required|string|max:20',
            'lokasi_penyimpanan'=> 'nullable|string|max:100',
            'deskripsi'         => 'nullable|string',
        ], [
            'kategori_id.required'  => 'Kategori wajib dipilih.',
            'kategori_id.exists'    => 'Kategori tidak valid.',
            'kode_barang.required'  => 'Kode barang wajib diisi.',
            'kode_barang.unique'    => 'Kode barang sudah digunakan.',
            'nama_barang.required'  => 'Nama barang wajib diisi.',
            'stok.required'         => 'Stok wajib diisi.',
            'stok.min'              => 'Stok tidak boleh negatif.',
            'stok_minimum.required' => 'Stok minimum wajib diisi.',
            'satuan.required'       => 'Satuan wajib diisi.',
        ]);

        $stok        = (int) $request->stok;
        $stokMinimum = (int) $request->stok_minimum;
        $status      = Barang::hitungStatus($stok, $stokMinimum);

        DB::transaction(function () use ($request, $stok, $stokMinimum, $status) {
            $barang = Barang::create([
                'kategori_id'        => $request->kategori_id,
                'kode_barang'        => strtoupper(trim($request->kode_barang)),
                'nama_barang'        => $request->nama_barang,
                'stok'               => $stok,
                'stok_minimum'       => $stokMinimum,
                'satuan'             => $request->satuan,
                'lokasi_penyimpanan' => $request->lokasi_penyimpanan,
                'deskripsi'          => $request->deskripsi,
                'status_barang'      => $status,
            ]);

            // Catat riwayat stok awal (Masuk)
            if ($stok > 0) {
                DB::table('riwayat_stok')->insert([
                    'barang_id'        => $barang->id,
                    'jenis_transaksi'  => 'Masuk',
                    'jumlah'           => $stok,
                    'stok_sebelum'     => 0,
                    'stok_sesudah'     => $stok,
                    'keterangan'       => 'Stok awal saat penambahan barang',
                    'created_at'       => now(),
                ]);
            }
        });

        return redirect()->route('barang.index')
            ->with('success', 'Barang berhasil ditambahkan.');
    }

    // ----------------------------------------------------------------
    // SHOW — Detail barang + riwayat stok
    // ----------------------------------------------------------------
    public function show(int $id)
    {
        $barang = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select('barang.*', 'kategori_barang.nama_kategori')
            ->where('barang.id', $id)
            ->firstOrFail();

        $riwayat = DB::table('riwayat_stok')
            ->where('barang_id', $id)
            ->orderBy('id', 'desc')
            ->limit(20)
            ->get();

        return view('barang.show', compact('barang', 'riwayat'));
    }

    // ----------------------------------------------------------------
    // EDIT — Form edit barang
    // ----------------------------------------------------------------
    public function edit(int $id)
    {
        $barang    = Barang::findOrFail($id);
        $kategoris = KategoriBarang::orderBy('nama_kategori')->get();
        return view('barang.edit', compact('barang', 'kategoris'));
    }

    // ----------------------------------------------------------------
    // UPDATE — Simpan perubahan barang
    // ----------------------------------------------------------------
    public function update(Request $request, int $id)
    {
        $barang = Barang::findOrFail($id);

        $request->validate([
            'kategori_id'       => 'required|exists:kategori_barang,id',
            'kode_barang'       => 'required|string|max:50|unique:barang,kode_barang,' . $id,
            'nama_barang'       => 'required|string|max:150',
            'stok'              => 'required|integer|min:0',
            'stok_minimum'      => 'required|integer|min:0',
            'satuan'            => 'required|string|max:20',
            'lokasi_penyimpanan'=> 'nullable|string|max:100',
            'deskripsi'         => 'nullable|string',
        ], [
            'kategori_id.required'  => 'Kategori wajib dipilih.',
            'kategori_id.exists'    => 'Kategori tidak valid.',
            'kode_barang.required'  => 'Kode barang wajib diisi.',
            'kode_barang.unique'    => 'Kode barang sudah digunakan barang lain.',
            'nama_barang.required'  => 'Nama barang wajib diisi.',
            'stok.required'         => 'Stok wajib diisi.',
            'stok.min'              => 'Stok tidak boleh negatif.',
            'stok_minimum.required' => 'Stok minimum wajib diisi.',
            'satuan.required'       => 'Satuan wajib diisi.',
        ]);

        $stokLama    = (int) $barang->stok;
        $stokBaru    = (int) $request->stok;
        $stokMinimum = (int) $request->stok_minimum;
        $status      = Barang::hitungStatus($stokBaru, $stokMinimum);

        DB::transaction(function () use ($request, $barang, $stokLama, $stokBaru, $stokMinimum, $status) {
            $barang->update([
                'kategori_id'        => $request->kategori_id,
                'kode_barang'        => strtoupper(trim($request->kode_barang)),
                'nama_barang'        => $request->nama_barang,
                'stok'               => $stokBaru,
                'stok_minimum'       => $stokMinimum,
                'satuan'             => $request->satuan,
                'lokasi_penyimpanan' => $request->lokasi_penyimpanan,
                'deskripsi'          => $request->deskripsi,
                'status_barang'      => $status,
            ]);

            // Catat riwayat stok jika ada perubahan
            if ($stokBaru !== $stokLama) {
                $selisih = abs($stokBaru - $stokLama);
                DB::table('riwayat_stok')->insert([
                    'barang_id'       => $barang->id,
                    'jenis_transaksi' => $stokBaru > $stokLama ? 'Masuk' : 'Keluar',
                    'jumlah'          => $selisih,
                    'stok_sebelum'    => $stokLama,
                    'stok_sesudah'    => $stokBaru,
                    'keterangan'      => 'Penyesuaian stok oleh Admin',
                    'created_at'      => now(),
                ]);
            }
        });

        return redirect()->route('barang.index')
            ->with('success', 'Data barang berhasil diperbarui.');
    }

    // ----------------------------------------------------------------
    // DESTROY — Hapus barang
    // ----------------------------------------------------------------
    public function destroy(int $id)
    {
        $barang = Barang::findOrFail($id);

        // Cek apakah barang sedang digunakan di detail_permintaan atau distribusi
        $digunakan = DB::table('detail_permintaan')
            ->where('barang_id', $id)
            ->exists();

        if ($digunakan) {
            return redirect()->route('barang.index')
                ->with('error', 'Barang tidak dapat dihapus karena sudah terdapat dalam data permintaan.');
        }

        // Hapus riwayat stok barang ini terlebih dahulu
        DB::table('riwayat_stok')->where('barang_id', $id)->delete();

        $barang->delete();

        return redirect()->route('barang.index')
            ->with('success', 'Barang berhasil dihapus.');
    }
}