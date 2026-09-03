app.blade.php lama (edit 13.17)
<!DOCTYPE html>
<html lang="id">
<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Dashboard') — Inventori Bank</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <style>

        body {
            background: #f5f7fa;
            font-family: 'Segoe UI', sans-serif;
        }

        /* ── Sidebar ── */
        .sidebar {
            width: 250px;
            min-height: 100vh;
            background: #1565C0;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 1000;
            display: flex;
            flex-direction: column;
        }

        .sidebar-brand {
            padding: 22px 20px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.15);
        }

        .sidebar-brand h5 {
            color: #fff;
            font-weight: 700;
            margin: 0;
            font-size: 1rem;
        }

        .sidebar-brand small {
            color: rgba(255,255,255,0.65);
            font-size: 0.75rem;
        }

        .sidebar-nav {
            flex: 1;
            padding: 10px 0;
        }

        .sidebar-nav a {
            display: flex;
            align-items: center;
            gap: 10px;
            color: rgba(255,255,255,0.85);
            text-decoration: none;
            padding: 11px 20px;
            font-size: 0.9rem;
            transition: background 0.15s;
        }

        .sidebar-nav a:hover,
        .sidebar-nav a.active {
            background: rgba(255,255,255,0.15);
            color: #fff;
        }

        .sidebar-nav a.active {
            border-left: 3px solid #fff;
            padding-left: 17px;
        }

        .sidebar-nav .nav-section {
            font-size: 0.7rem;
            color: rgba(255,255,255,0.45);
            text-transform: uppercase;
            letter-spacing: 0.08em;
            padding: 14px 20px 4px;
        }

        .sidebar-footer {
            padding: 14px 0;
            border-top: 1px solid rgba(255,255,255,0.15);
        }

        .sidebar-footer a {
            display: flex;
            align-items: center;
            gap: 10px;
            color: rgba(255,255,255,0.75);
            text-decoration: none;
            padding: 10px 20px;
            font-size: 0.9rem;
        }

        .sidebar-footer a:hover {
            color: #fff;
            background: rgba(255,255,255,0.1);
        }

        /* ── Main content ── */
        .main-wrapper {
            margin-left: 250px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .topbar {
            background: #fff;
            padding: 14px 28px;
            border-bottom: 1px solid #e9ecef;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .topbar-title {
            font-weight: 600;
            color: #1565C0;
            font-size: 1rem;
            margin: 0;
        }

        .topbar-user {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 0.875rem;
            color: #555;
        }

        .topbar-user .avatar {
            width: 32px;
            height: 32px;
            background: #1565C0;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            font-size: 0.8rem;
            font-weight: 700;
        }

        .content-area {
            padding: 28px;
            flex: 1;
        }

        /* ── Cards ── */
        .card-stat {
            border: none;
            border-radius: 14px;
            box-shadow: 0 3px 15px rgba(0,0,0,0.07);
        }

        .card {
            border: none;
            border-radius: 14px;
            box-shadow: 0 3px 15px rgba(0,0,0,0.07);
        }

        /* ── Badge status barang ── */
        .badge-tersedia   { background: #d1fae5; color: #065f46; }
        .badge-menipis    { background: #fef3c7; color: #92400e; }
        .badge-habis      { background: #fee2e2; color: #991b1b; }

    </style>

    @stack('styles')

</head>
<body>

{{-- ================================================================
     SIDEBAR
================================================================ --}}
<div class="sidebar">

    <div class="sidebar-brand">
        <h5><i class="bi bi-boxes me-1"></i> Inventori Bank</h5>
        <small>PT. Bank XYZ</small>
    </div>

    <nav class="sidebar-nav">

        <div class="nav-section">Menu Utama</div>

        <a href="{{ url('/dashboard') }}"
           class="{{ request()->is('dashboard') ? 'active' : '' }}">
            <i class="bi bi-grid-1x2"></i> Dashboard
        </a>

        <div class="nav-section">Manajemen</div>

        <a href="{{ route('barang.index') }}"
           class="{{ request()->is('barang*') ? 'active' : '' }}">
            <i class="bi bi-box-seam"></i> Data Barang
        </a>

        <a href="{{ route('user.index') }}"
            class="{{ request()->is('user*') ? 'active' : '' }}">
                <i class="bi bi-people"></i> Data User
        </a>

        <div class="nav-section">Operasional</div>

        <a href="{{ route('permintaan.index') }}"
           class="{{ request()->is('permintaan*') ? 'active' : '' }}">
            <i class="bi bi-file-earmark-text"></i> Permintaan
            @php
                $pendingSidebar = \Illuminate\Support\Facades\DB::table('permintaan')
                    ->where('status_permintaan','Pending')->count();
            @endphp
            @if($pendingSidebar > 0)
                <span class="nav-badge">{{ $pendingSidebar }}</span>
            @endif
        </a>

        <a href="{{ route('distribusi.index') }}"
           class="{{ request()->is('distribusi*') ? 'active' : '' }}">
            <i class="bi bi-truck"></i> Distribusi
            @php
                $approvedSidebar = \Illuminate\Support\Facades\DB::table('permintaan')
                    ->where('status_permintaan','Approved')->count();
            @endphp
            @if($approvedSidebar > 0)
                <span class="nav-badge">{{ $approvedSidebar }}</span>
            @endif
        </a>

        <div class="nav-section">Laporan</div>

        <a href="{{ route('laporan.index') }}"
           class="{{ request()->is('laporan*') ? 'active' : '' }}">
            <i class="bi bi-bar-chart-line"></i> Laporan
        </a>

    </nav>

    <div class="sidebar-footer">
        <a href="{{ url('/logout') }}">
            <i class="bi bi-box-arrow-right"></i> Logout
        </a>
    </div>

</div>

{{-- ================================================================
     MAIN WRAPPER
================================================================ --}}
<div class="main-wrapper">

    {{-- Topbar --}}
    <div class="topbar">
        <p class="topbar-title">@yield('page-title', 'Dashboard')</p>
        <div class="topbar-user">
            <div class="avatar">
                {{ strtoupper(substr(session('nama', 'A'), 0, 1)) }}
            </div>
            <span>{{ session('nama', 'Admin') }}</span>
        </div>
    </div>

    {{-- Content --}}
    <div class="content-area">

        {{-- Alert Global --}}
        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-circle me-2"></i>{{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @yield('content')

    </div>

</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/js/bootstrap.bundle.min.js"></script>
@stack('scripts')

</body>
</html>