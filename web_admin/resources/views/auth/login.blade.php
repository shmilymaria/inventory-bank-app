<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Admin - Inventori Bank</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>

        body{
            background:#f5f7fa;
            height:100vh;
        }

        .login-container{
            min-height:100vh;
        }

        .login-card{
            border:none;
            border-radius:20px;
            box-shadow:0 5px 20px rgba(0,0,0,0.08);
        }

        .left-panel{
            background:#1565C0;
            color:white;
            border-radius:20px 0 0 20px;
            padding:50px;
        }

        .btn-login{
            background:#1565C0;
            border:none;
        }

        .btn-login:hover{
            background:#0d47a1;
        }

    </style>

</head>
<body>

<div class="container login-container d-flex align-items-center">

    <div class="row w-100 justify-content-center">

        <div class="col-lg-9">

            <div class="card login-card">

                <div class="row g-0">

                    <div class="col-md-5 left-panel d-flex flex-column justify-content-center">

                        <h2 class="fw-bold">
                            Inventory Management
                        </h2>

                        <p class="mt-3">
                            Sistem Manajemen Inventori dan Distribusi Barang PT. Bank XYZ
                        </p>

                    </div>

                    <div class="col-md-7">

                        <div class="p-5">

                            <h3 class="fw-bold mb-4">
                                Login Admin
                            </h3>

                            @if(session('error'))
                                <div class="alert alert-danger">
                                    {{ session('error') }}
                                </div>
                            @endif

                            <form method="POST" action="/login">

                                @csrf

                                <div class="mb-3">
                                    <label>Username</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        name="username"
                                        required>
                                </div>

                                <div class="mb-4">
                                    <label>Password</label>
                                    <input
                                        type="password"
                                        class="form-control"
                                        name="password"
                                        required>
                                </div>

                                <button class="btn btn-login text-white w-100">
                                    Login
                                </button>

                            </form>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </div>

</div>

</body>
</html>