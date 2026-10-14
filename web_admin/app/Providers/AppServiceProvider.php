<?php

namespace App\Providers;

use Illuminate\Pagination\Paginator;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // UI web admin memakai Bootstrap, jadi paginasi harus pakai view
        // Bootstrap (bukan Tailwind bawaan Laravel yang bikin ikon panah
        // < > tampil raksasa).
        Paginator::useBootstrapFive();
    }
}
