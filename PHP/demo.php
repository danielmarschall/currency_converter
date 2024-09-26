<?php

require_once __DIR__ . '/currency_calc.inc.php';

$x = new CurCalc('cache.json', 'YOUR API KEY HERE');
if ($x->needs_download(1*60*60)) $x->download_exchange_rates(); // refresh data every hour
$val = $x->convert_cur(100, 'EUR', 'RUB');
echo "100 EUR are $val RUB.\n";
