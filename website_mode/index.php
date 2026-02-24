<?php
// Simple single-file page that loads the JS/CSS frontend.
?>
<!doctype html>
<?php
// UangBro - Website Mode (full web app)
// This file serves a small single-page app that talks to PHP APIs under /api/
?>
<!doctype html>
<html lang="id">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>UangBro — Website Mode</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>

<body>
    <header>
        <h1>UangBro — Website Mode</h1>
        <nav id="top-nav" style="margin-top:10px"></nav>
    </header>

    <main>
        <!-- Auth pages -->
        <section id="page-login" class="page" style="display:none">
            <h2>Masuk</h2>
            <form id="form-login">
                <label>Username<input id="login-username" required></label>
                <label>Password<input id="login-password" type="password" required></label>
                <button type="submit">Masuk</button>
            </form>
            <p>Belum punya akun? <a href="#register" data-link>Daftar</a></p>
        </section>

        <section id="page-register" class="page" style="display:none">
            <h2>Daftar</h2>
            <form id="form-register">
                <label>Username<input id="reg-username" required></label>
                <label>Password<input id="reg-password" type="password" required></label>
                <button type="submit">Daftar</button>
            </form>
            <p>Sudah punya akun? <a href="#login" data-link>Masuk</a></p>
        </section>

        <!-- App dashboard -->
        <section id="page-app" class="page" style="display:none">
            <h2>Dashboard</h2>
            <div id="balances" style="margin-bottom:12px"></div>

            <div style="display:flex;gap:12px;flex-wrap:wrap">
                <form id="form-transaction" style="min-width:280px">
                    <h3>Tambah Transaksi</h3>
                    <label>Type
                        <select id="tx-type">
                            <option value="income">Pemasukan</option>
                            <option value="expense">Pengeluaran</option>
                        </select>
                    </label>
                    <label>Amount<input id="tx-amount" type="number" required min="0" step="0.01"></label>
                    <label>Category<input id="tx-category"></label>
                    <label>Description<input id="tx-description"></label>
                    <label>Date<input id="tx-date" type="date"></label>
                    <button type="submit">Simpan</button>
                </form>

                <div style="flex:1;min-width:300px">
                    <h3>Transaksi</h3>
                    <div id="tx-list">Loading…</div>
                </div>
            </div>
        </section>
    </main>

    <script src="assets/js/app.js"></script>
</body>

</html>